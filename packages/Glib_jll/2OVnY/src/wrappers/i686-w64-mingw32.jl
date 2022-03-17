# Autogenerated wrapper script for Glib_jll for i686-w64-mingw32
export libgio, libglib, libgmodule, libgobject, libgthread

using Libiconv_jll
using Libffi_jll
using Gettext_jll
using PCRE_jll
using Zlib_jll
JLLWrappers.@generate_wrapper_header("Glib")
JLLWrappers.@declare_library_product(libgio, "libgio-2.0-0.dll")
JLLWrappers.@declare_library_product(libglib, "libglib-2.0-0.dll")
JLLWrappers.@declare_library_product(libgmodule, "libgmodule-2.0-0.dll")
JLLWrappers.@declare_library_product(libgobject, "libgobject-2.0-0.dll")
JLLWrappers.@declare_library_product(libgthread, "libgthread-2.0-0.dll")
function __init__()
    JLLWrappers.@generate_init_header(Libiconv_jll, Libffi_jll, Gettext_jll, PCRE_jll, Zlib_jll)
    JLLWrappers.@init_library_product(
        libgio,
        "bin\\libgio-2.0-0.dll",
        RTLD_LAZY | RTLD_DEEPBIND,
    )

    JLLWrappers.@init_library_product(
        libglib,
        "bin\\libglib-2.0-0.dll",
        RTLD_LAZY | RTLD_DEEPBIND,
    )

    JLLWrappers.@init_library_product(
        libgmodule,
        "bin\\libgmodule-2.0-0.dll",
        RTLD_LAZY | RTLD_DEEPBIND,
    )

    JLLWrappers.@init_library_product(
        libgobject,
        "bin\\libgobject-2.0-0.dll",
        RTLD_LAZY | RTLD_DEEPBIND,
    )

    JLLWrappers.@init_library_product(
        libgthread,
        "bin\\libgthread-2.0-0.dll",
        RTLD_LAZY | RTLD_DEEPBIND,
    )

    JLLWrappers.@generate_init_footer()
end  # __init__()
