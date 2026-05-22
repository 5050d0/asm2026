project('lab5', 'c')

readline_dep = dependency('readline', required: true)
libspng_dep  = dependency('spng',     required: true)

executable('lab5',
    [
        'main.c',
        'impl_c.c',
        'impl_asm.s',
    ],
    dependencies : [libspng_dep, readline_dep])
