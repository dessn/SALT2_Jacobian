# Autogenerated wrapper script for FriBidi_jll for aarch64-linux-gnu
export fribidi, libfribidi

JLLWrappers.@generate_wrapper_header("FriBidi")
JLLWrappers.@declare_executable_product(fribidi)
JLLWrappers.@declare_library_product(libfribidi, "libfribidi.so.0")
function __init__()
    JLLWrappers.@generate_init_header()
    JLLWrappers.@init_executable_product(
        fribidi,
        "bin/fribidi",
    )

    JLLWrappers.@init_library_product(
        libfribidi,
        "lib/libfribidi.so",
        RTLD_LAZY | RTLD_DEEPBIND,
    )

    JLLWrappers.@generate_init_footer()
end  # __init__()
