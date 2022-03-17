# Autogenerated wrapper script for HarfBuzz_jll for x86_64-apple-darwin
export libharfbuzz, libharfbuzz_gobject, libharfbuzz_subset

using Cairo_jll
using Fontconfig_jll
using FreeType2_jll
using Glib_jll
using Graphite2_jll
using Libffi_jll
JLLWrappers.@generate_wrapper_header("HarfBuzz")
JLLWrappers.@declare_library_product(libharfbuzz, "@rpath/libharfbuzz.0.dylib")
JLLWrappers.@declare_library_product(libharfbuzz_gobject, "@rpath/libharfbuzz-gobject.0.dylib")
JLLWrappers.@declare_library_product(libharfbuzz_subset, "@rpath/libharfbuzz-subset.0.dylib")
function __init__()
    JLLWrappers.@generate_init_header(Cairo_jll, Fontconfig_jll, FreeType2_jll, Glib_jll, Graphite2_jll, Libffi_jll)
    JLLWrappers.@init_library_product(
        libharfbuzz,
        "lib/libharfbuzz.0.dylib",
        RTLD_LAZY | RTLD_DEEPBIND,
    )

    JLLWrappers.@init_library_product(
        libharfbuzz_gobject,
        "lib/libharfbuzz-gobject.0.dylib",
        RTLD_LAZY | RTLD_DEEPBIND,
    )

    JLLWrappers.@init_library_product(
        libharfbuzz_subset,
        "lib/libharfbuzz-subset.0.dylib",
        RTLD_LAZY | RTLD_DEEPBIND,
    )

    JLLWrappers.@generate_init_footer()
end  # __init__()
