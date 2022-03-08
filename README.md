# SALT2-Jacobian

## Goal
The typical length of time for a SALT2 surface is on the order of a few compute hours. The goal of this package is to reduce that down to seconds.

The philosphy behind this is to start with an unperturbed SALT2 surface, and perturbe the colour law and spline components of that surface based on a jacobian matrix.

The jacobian matrix itself is trained on a set of 70 perturbed SALT2 surfaces, each pertubed by a single systematic. The jacobian matrix simply records the effect of these purtubations on the colour law and spline components. When training a new SALT2 surface, this script approximates the true SALT2 training as a linear combination of the jacobian perturbations.

## Usage

If you just want to generate a set of SALT2 surfaces quickly, then you simply need to produce a `submit_batch.input` file as you normally would for SALT2, and run `./scripts/SALT2_Jacobian /path/to/your/submit_batch.input`. This will use the jacobian matrix and base surface found in `src`. If you wish to use a different jacobian matrix you can add the `-j/--jacobian /path/to/your/jacobian.tar.gz` argument, likewise if you want to use a different base (unperturbed) surface, you can add the `-b/--base /path/to/your/base_surface.tar.gz`. When using this method, the output folder will be picked from the `submit_batch.input` file. See `Examples/Inputs/QuickNDirty/` for an example `.input` file you can try this out on.

If you want to do more complex jobs (creating new jacobian matrices, comparing SALT2 surfaces, plotting, etc...) then you need to use `toml` input files.

### Creating new Jacobian matrices

### Training SALT2 surfaces

### Comparing SALT2 surfaces

### Plotting SALT2 surfaces
