#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <time.h>
#include <spng.h>

void gaussian_blur_c(const unsigned char*, unsigned char*, uint64_t, uint64_t);
void gaussian_blur_asm(const unsigned char*, unsigned char*, uint64_t,
                       uint64_t);

typedef void (*blur_fn)(const unsigned char*, unsigned char*, uint64_t,
                        uint64_t);

typedef struct {
    const char* name;
    const char* description;
    blur_fn fn;
} impl_t;

static const impl_t impls[] = {
    { "c", "C", gaussian_blur_c },
    { "asm", "assembly", gaussian_blur_asm },
};
#define IMPL_COUNT ((int)(sizeof(impls) / sizeof(impls[0])))

static const impl_t* find_impl(const char* name)
{
    for (int i = 0; i < IMPL_COUNT; i++)
        if (strcmp(impls[i].name, name) == 0)
            return &impls[i];
    return NULL;
}

static double now_sec(void)
{
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return t.tv_sec + t.tv_nsec * 1e-9;
}

int load_png(const char* path, unsigned char** out_image,
                    struct spng_ihdr* out_ihdr, size_t* out_size)
{
    FILE* fp = fopen(path, "rb");
    if (!fp) {
        perror(path);
        return -1;
    }

    spng_ctx* ctx = spng_ctx_new(0);
    if (!ctx) {
        fprintf(stderr, "spng_ctx_new failed\n");
        fclose(fp);
        return -1;
    }

    size_t limit = 1024ULL * 1024 * 64;
    spng_set_chunk_limits(ctx, limit, limit);
    spng_set_png_file(ctx, fp);

    int ret = spng_get_ihdr(ctx, out_ihdr);
    if (ret) {
        fprintf(stderr, "spng_get_ihdr: %s\n", spng_strerror(ret));
        goto err;
    }

    ret = spng_decoded_image_size(ctx, SPNG_FMT_PNG, out_size);
    if (ret)
        goto err;

    *out_image = malloc(*out_size);
    if (!*out_image)
        goto err;

    ret = spng_decode_image(ctx, *out_image, *out_size, SPNG_FMT_PNG, 0);
    if (ret) {
        fprintf(stderr, "spng_decode_image: %s\n", spng_strerror(ret));
        goto err;
    }

    spng_ctx_free(ctx);
    fclose(fp);
    return 0;
err:
    spng_ctx_free(ctx);
    fclose(fp);
    return -1;
}

int save_png(const char* path, const unsigned char* image,
                    uint32_t width, uint32_t height)
{
    FILE* fp = fopen(path, "wb");
    if (!fp) {
        perror(path);
        return -1;
    }

    spng_ctx* ctx = spng_ctx_new(SPNG_CTX_ENCODER);
    if (!ctx) {
        fclose(fp);
        return -1;
    }

    spng_set_png_file(ctx, fp);

    struct spng_ihdr ihdr = {
        .width = width,
        .height = height,
        .bit_depth = 8,
        .color_type = SPNG_COLOR_TYPE_TRUECOLOR,
        .compression_method = 0,
        .filter_method = SPNG_FILTER_NONE,
        .interlace_method = SPNG_INTERLACE_NONE,
    };
    spng_set_ihdr(ctx, &ihdr);

    int ret = spng_encode_image(ctx, image, (size_t)width * height * 3,
                                SPNG_FMT_PNG, SPNG_ENCODE_FINALIZE);
    if (ret)
        fprintf(stderr, "spng_encode_image: %s\n", spng_strerror(ret));

    spng_ctx_free(ctx);
    fclose(fp);
    return ret;
}

static void usage(const char* prog)
{
    fprintf(
        stderr,
        "Usage: %s [opts] \n"
        "\n"
        "  -i, --in <file> Input file (по умолчанию: image.png)\n"
        "  -o, --out <file> Output file (по умолчанию: output.png)\n"
        "  --impl <name>   implementation (asm/c)\n"
        "  --passes <n>    blur passes\n"
        "  --bench         bench\n"
        "  --help          help\n"
        "\n",
        prog);
}

int main(int argc, char* argv[])
{
    const char* impl_name = "asm";
    int passes = 20;
    int do_bench = 0;

    const char* input_file = "image.png";
    const char* output_file = "output.png";

    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--help") == 0 || strcmp(argv[i], "-h") == 0) {
            usage(argv[0]);
            return 0;
        } else if (strcmp(argv[i], "--bench") == 0) {
            do_bench = 1;
        } else if (strcmp(argv[i], "--impl") == 0) {
            if (++i >= argc) {
                fprintf(stderr, "--impl requires an argument\n");
                return 1;
            }
            impl_name = argv[i];
        } else if (strcmp(argv[i], "--passes") == 0) {
            if (++i >= argc) {
                fprintf(stderr, "--passes requires an argument\n");
                return 1;
            }
            passes = atoi(argv[i]);
            if (passes <= 0) {
                fprintf(stderr, "passes must be > 0\n");
                return 1;
            }
        } else if (strcmp(argv[i], "--in") == 0 || strcmp(argv[i], "-i") == 0) {
            if (++i >= argc) {
                fprintf(stderr, "--in requires a filename argument\n");
                return 1;
            }
            input_file = argv[i];
        } else if (strcmp(argv[i], "--out") == 0 || strcmp(argv[i], "-o") == 0) {
            if (++i >= argc) {
                fprintf(stderr, "--out requires a filename argument\n");
                return 1;
            }
            output_file = argv[i];
        } else {
            fprintf(stderr, "Unknown arg: %s\n", argv[i]);
            usage(argv[0]);
            return 1;
        }
    }


    unsigned char* image = NULL;
    struct spng_ihdr ihdr;
    size_t image_size;

    if (load_png(input_file, &image, &ihdr, &image_size) != 0) {
        fprintf(stderr, "Could not load input file: %s\n", input_file);
        return 1;
    }

    printf("File: %s\nSize: %u×%u  bit_depth=%u  color_type=%u\n", input_file, ihdr.width,
           ihdr.height, ihdr.bit_depth, ihdr.color_type);

    unsigned char* blurred = malloc(image_size);
    if (!blurred) {
        free(image);
        return 1;
    }

    if (do_bench) {
        printf("\nBenchmark (%d times × %d passes):\n\n", 3, passes);

        for (int i = 0; i < IMPL_COUNT; i++) {
            double best = 1e9;
            for (int run = 0; run < 3; run++) {
                double t0 = now_sec();
                for (int p = 0; p < passes; p++)
                    impls[i].fn(image, blurred, ihdr.width, ihdr.height);
                double elapsed = now_sec() - t0;
                if (elapsed < best)
                    best = elapsed;
            }

            printf("  %-8s  %.3f с  (%.1f ms/pass)\n", impls[i].name, best,
                   best / passes * 1000.0);
        }
        printf("\n");
        free(image);
        free(blurred);
        return 0;
    }

    const impl_t* impl = find_impl(impl_name);
    if (!impl) {
        fprintf(stderr, "Unknown impl: \"%s\"\n", impl_name);
        free(image);
        free(blurred);
        return 1;
    }

    printf("Impl: %s (%s)\n", impl->name, impl->description);
    printf("Passes:   %d\n", passes);

    double t0 = now_sec();
    for (int i = 0; i < passes; i++)
        impl->fn(image, blurred, ihdr.width, ihdr.height);
    double elapsed = now_sec() - t0;

    printf("Time:      %.3f s  (%.1f ms/pass)\n", elapsed,
           elapsed / passes * 1000.0);

    if (save_png(output_file, blurred, ihdr.width, ihdr.height) != 0)
        fprintf(stderr, "Error saving %s\n", output_file);
    else
        printf("Saved: %s\n", output_file);

    free(image);
    free(blurred);
    return 0;
}
