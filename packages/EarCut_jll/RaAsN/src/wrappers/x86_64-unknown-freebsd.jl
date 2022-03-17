# Autogenerated wrapper script for EarCut_jll for x86_64-unknown-freebsd
export libearcut

JLLWrappers.@generate_wrapper_header("EarCut")
JLLWrappers.@declare_library_product(libearcut, "libearcut.so")
function __init__()
    JLLWrappers.@generate_init_header()
    JLLWrappers.@init_library_product(
        libearcut,
        "lib/libearcut.so",
        RTLD_LAZY | RTLD_DEEPBIND,
    )

    JLLWrappers.@generate_init_footer()
end  # __init__()
