# Autogenerated wrapper script for LAMMPS_jll for armv7l-linux-gnueabihf-libgfortran4-cxx03-mpi+mpitrampoline
export liblammps, lmp

using CompilerSupportLibraries_jll
using Preferences
using MPItrampoline_jll
JLLWrappers.@generate_wrapper_header("LAMMPS")
JLLWrappers.@declare_library_product(liblammps, "liblammps.so.0")
JLLWrappers.@declare_executable_product(lmp)
function __init__()
    JLLWrappers.@generate_init_header(CompilerSupportLibraries_jll, Preferences, MPItrampoline_jll)
    JLLWrappers.@init_library_product(
        liblammps,
        "lib/liblammps.so",
        RTLD_LAZY | RTLD_DEEPBIND,
    )

    JLLWrappers.@init_executable_product(
        lmp,
        "bin/lmp",
    )

    JLLWrappers.@generate_init_footer()
end  # __init__()