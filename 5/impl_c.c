#include <stdint.h>

void gaussian_blur_c(const unsigned char* src, unsigned char* dst,
                     uint64_t width, uint64_t height)
{
    static const int mat[5][5] = {
        { 1, 4, 6, 4, 1 },    { 4, 16, 24, 16, 4 }, { 6, 24, 36, 24, 6 },
        { 4, 16, 24, 16, 4 }, { 1, 4, 6, 4, 1 },
    };
    static const int div = 256;

    const uint64_t stride = width * 3;

    for (uint64_t i = 0; i < height * stride; i++)
        dst[i] = src[i];

    for (uint64_t y = 2; y < height - 2; y++) {
        for (uint64_t x = 2; x < width - 2; x++) {
            int acc[3] = { 0, 0, 0 };

            for (int my = -2; my <= 2; my++) {
                for (int mx = -2; mx <= 2; mx++) {
                    int w = mat[my + 2][mx + 2];
                    const unsigned char* px =
                        src + (y + my) * stride + (x + mx) * 3;
                    acc[0] += px[0] * w;
                    acc[1] += px[1] * w;
                    acc[2] += px[2] * w;
                }
            }

            unsigned char* out = dst + y * stride + x * 3;
            out[0] = acc[0] / div;
            out[1] = acc[1] / div;
            out[2] = acc[2] / div;
        }
    }
}
