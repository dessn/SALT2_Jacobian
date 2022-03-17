# Autogenerated wrapper script for isoband_jll for x86_64-apple-darwin14-cxx11
export libisoband

## Global variables
PATH = ""
LIBPATH = ""
LIBPATH_env = "DYLD_FALLBACK_LIBRARY_PATH"
LIBPATH_default = "~/lib:/usr/local/lib:/lib:/usr/lib"

# Relative path to `libisoband`
const libisoband_splitpath = ["lib", "libisoband.dylib"]

# This will be filled out by __init__() for all products, as it must be done at runtime
libisoband_path = ""

# libisoband-specific global declaration
# This will be filled out by __init__()
libisoband_handle = C_NULL

# This must be `const` so that we can use it with `ccall()`
const libisoband = "@rpath/libisoband.dylib"


"""
Open all libraries
"""
function __init__()
    global artifact_dir = abspath(artifact"isoband")

    # Initialize PATH and LIBPATH environment variable listings
    global PATH_list, LIBPATH_list
    global libisoband_path = normpath(joinpath(artifact_dir, libisoband_splitpath...))

    # Manually `dlopen()` this right now so that future invocations
    # of `ccall` with its `SONAME` will find this path immediately.
    global libisoband_handle = dlopen(libisoband_path)
    push!(LIBPATH_list, dirname(libisoband_path))

    # Filter out duplicate and empty entries in our PATH and LIBPATH entries
    filter!(!isempty, unique!(PATH_list))
    filter!(!isempty, unique!(LIBPATH_list))
    global PATH = join(PATH_list, ':')
    global LIBPATH = join(vcat(LIBPATH_list, [joinpath(Sys.BINDIR, Base.LIBDIR, "julia"), joinpath(Sys.BINDIR, Base.LIBDIR)]), ':')

    
end  # __init__()
