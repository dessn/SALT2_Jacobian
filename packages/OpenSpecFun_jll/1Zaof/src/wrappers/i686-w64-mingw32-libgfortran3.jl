# Autogenerated wrapper script for OpenSpecFun_jll for i686-w64-mingw32-libgfortran3
export libopenspecfun

using CompilerSupportLibraries_jll
JLLWrappers.@generate_wrapper_header("OpenSpecFun")
JLLWrappers.@declare_library_product(libopenspecfun, "libopenspecfun.dll")
function __init__()
    JLLWrappers.@generate_init_header(CompilerSupportLibraries_jll)
    JLLWrappers.@init_library_product(
        libopenspecfun,
        "bin\\libopenspecfun.dll",
        RTLD_LAZY | RTLD_DEEPBIND,
    )

    JLLWrappers.@generate_init_footer()
end  # __init__()
