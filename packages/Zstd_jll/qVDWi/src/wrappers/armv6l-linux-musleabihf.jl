# Autogenerated wrapper script for Zstd_jll for armv6l-linux-musleabihf
export libzstd, zstd, zstdmt

JLLWrappers.@generate_wrapper_header("Zstd")
JLLWrappers.@declare_library_product(libzstd, "libzstd.so.1")
JLLWrappers.@declare_executable_product(zstd)
JLLWrappers.@declare_executable_product(zstdmt)
function __init__()
    JLLWrappers.@generate_init_header()
    JLLWrappers.@init_library_product(
        libzstd,
        "lib/libzstd.so",
        RTLD_LAZY | RTLD_DEEPBIND,
    )

    JLLWrappers.@init_executable_product(
        zstd,
        "bin/zstd",
    )

    JLLWrappers.@init_executable_product(
        zstdmt,
        "bin/zstdmt",
    )

    JLLWrappers.@generate_init_footer()
end  # __init__()
