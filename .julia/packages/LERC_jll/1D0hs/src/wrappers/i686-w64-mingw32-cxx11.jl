# Autogenerated wrapper script for LERC_jll for i686-w64-mingw32-cxx11
export libLerc

JLLWrappers.@generate_wrapper_header("LERC")
JLLWrappers.@declare_library_product(libLerc, "libLerc.dll")
function __init__()
    JLLWrappers.@generate_init_header()
    JLLWrappers.@init_library_product(
        libLerc,
        "bin\\libLerc.dll",
        RTLD_LAZY | RTLD_DEEPBIND,
    )

    JLLWrappers.@generate_init_footer()
end  # __init__()