# Autogenerated wrapper script for Xorg_libXrender_jll for armv7l-linux-musleabihf
export libXrender

using Xorg_libX11_jll
JLLWrappers.@generate_wrapper_header("Xorg_libXrender")
JLLWrappers.@declare_library_product(libXrender, "libXrender.so.1")
function __init__()
    JLLWrappers.@generate_init_header(Xorg_libX11_jll)
    JLLWrappers.@init_library_product(
        libXrender,
        "lib/libXrender.so",
        RTLD_LAZY | RTLD_DEEPBIND,
    )

    JLLWrappers.@generate_init_footer()
end  # __init__()
