# Autogenerated wrapper script for Pixman_jll for aarch64-apple-darwin
export libpixman

JLLWrappers.@generate_wrapper_header("Pixman")
JLLWrappers.@declare_library_product(libpixman, "@rpath/libpixman-1.0.dylib")
function __init__()
    JLLWrappers.@generate_init_header()
    JLLWrappers.@init_library_product(
        libpixman,
        "lib/libpixman-1.0.40.0.dylib",
        RTLD_LAZY | RTLD_DEEPBIND,
    )

    JLLWrappers.@generate_init_footer()
end  # __init__()