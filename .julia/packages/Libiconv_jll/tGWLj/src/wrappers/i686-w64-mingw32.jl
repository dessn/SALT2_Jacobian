# Autogenerated wrapper script for Libiconv_jll for i686-w64-mingw32
export libcharset, libiconv

JLLWrappers.@generate_wrapper_header("Libiconv")
JLLWrappers.@declare_library_product(libcharset, "libcharset-1.dll")
JLLWrappers.@declare_library_product(libiconv, "libiconv-2.dll")
function __init__()
    JLLWrappers.@generate_init_header()
    JLLWrappers.@init_library_product(
        libcharset,
        "bin\\libcharset-1.dll",
        RTLD_LAZY | RTLD_DEEPBIND,
    )

    JLLWrappers.@init_library_product(
        libiconv,
        "bin\\libiconv-2.dll",
        RTLD_LAZY | RTLD_DEEPBIND,
    )

    JLLWrappers.@generate_init_footer()
end  # __init__()