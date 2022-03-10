# SALT2-Jacobian

## Goal
The typical length of time for a SALT2 surface is on the order of a few compute hours. The goal of this package is to reduce that down to seconds.

The philosphy behind this is to start with an unperturbed SALT2 surface, and perturbe the colour law and spline components of that surface based on a jacobian matrix.

The jacobian matrix itself is trained on a set of 70 perturbed SALT2 surfaces, each pertubed by a single systematic. The jacobian matrix simply records the effect of these purtubations on the colour law and spline components. When training a new SALT2 surface, this script approximates the true SALT2 training as a linear combination of the jacobian perturbations.

## Setup
If you are on midway, you need to add `module load julia` to the end of your `.bashrc` so that you have access to the julia language. Once you are able to run `julia` you should head to `$DES_USERS/parmstrong/dev/SALT2_Jacobian` and run `./scripts/SALT2_Jacobian -s Examples/Inputs/FullRunthrough`. This will do a first time install of all the packages needed, and run through each stage. Assuming all went well, you should be fine to run the jacobian script on whatever you want.

Eventually a dedicated app will be produced which can be run without julia installed on the system, but for the moment the above is required.

## Usage
If you just want to generate a set of SALT2 surfaces quickly, then you simply need to produce a `submit_batch.input` file as you normally would for SALT2, and run `./scripts/SALT2_Jacobian /path/to/your/submit_batch.input`. This will use the jacobian matrix and base surface found in `src`. If you wish to use a different jacobian matrix you can add the `-j/--jacobian /path/to/your/jacobian.tar.gz` argument, likewise if you want to use a different base (unperturbed) surface, you can add the `-b/--base /path/to/your/base_surface.tar.gz`. When using this method, the output folder will be picked from the `submit_batch.input` file. See `Examples/Inputs/QuickNDirty/` for an example `.input` file you can try this out on.

If you want to do more complex jobs (creating new jacobian matrices, comparing SALT2 surfaces, plotting, etc...) then you need to use `toml` input files.

### Global options
There are a number of global options which should be set prior to any calculations being performed. The most important of these is the `base_path` which defines a base directory which all non absolute paths are relative to. This defaults to the directory containing your `.toml` file, and can be specified either as an absolute path, or a path relative to the directory containing your `.toml` file. 

The next global option is the `output_path` which is where all the output produced by `SALT2_Jacobian`. This can be either relative to `base_path` or absolute, and defaults to `base_path / Output`

Finally you can specify whether or not to log via `logging`. This defaults to `true`, setting it to `false` will not produce a log file. The name of the log file is specified via `log_file` and defaults to `log.txt`. This will be placed in `output_path`.

```toml
# Example Global options
[ global ]
base_path = "/path/to/base"
output_path = "relative/output/path"
logging = true
log_file = "log.txt"
```

### Creating new Jacobian matrices


### Training SALT2 surfaces

### Comparing SALT2 surfaces

### Plotting SALT2 surfaces
