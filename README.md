# SALT2-Jacobian

## Goal
The typical length of time for a SALT2 surface is on the order of a few compute hours. The goal of this package is to reduce that down to seconds.

The philosphy behind this is to start with an unperturbed SALT2 surface, and perturbe the colour law and spline components of that surface based on a jacobian matrix.

The jacobian matrix itself is trained on a set of 70 perturbed SALT2 surfaces, each pertubed by a single systematic. The jacobian matrix simply records the effect of these purtubations on the colour law and spline components. When training a new SALT2 surface, this script approximates the true SALT2 training as a linear combination of the jacobian perturbations.

Note that this does not currently approximate the uncertainty in the colour law and spline component, only the value. The importance of this is still being investigated.

## Setup
To use this package, you simply need to `git clone` it someone on your device, and have a working julia instance.

If you are on midway, you need to add `module load julia` to the end of your `.bashrc` so that you have access to the julia language (don't forget to `source ~/.bashrc` afterwards!). Once you are able to run `julia` you should head to `$PRODUCTS/SALT2_Jacobian` and run `./scripts/SALT2_Jacobian Examples/Inputs/FullRunthrough`. This will do a first time install of all the packages needed, and run through each stage. Assuming all went well, you should be fine to run the jacobian script on whatever you want.

### Recommended additions
In order to use the `SALT2_Jacobian` script anywhere on your system, it is recommended to add the `SALT2_Jacobian/scripts` directory to your path. On Midway this entails adding `export PATH=$PATH:"/project2/rkessler/PRODUCTS/SALT2_Jacobian/scripts"` to your `.bashrc` (and sourcing it again).

## Usage
If you just want to generate a set of SALT2 surfaces quickly, then you simply need to produce a `submit_batch.input` file as you normally would for SALT2, and run `./scripts/SALT2_Jacobian /path/to/your/submit_batch.input`. This will use the jacobian matrix and base surface found in `src`. Note that this jacobian matrix and base surface are based on SALT2_T21. If you want to use a different SALT2 version (or possibly SALT3) you'll need to generate your own suite of offsets, similar to `Examples/TrainedSurfaces/OUTPUT_TRAIN_T21_suite`.

If you wish to use a different jacobian matrix you can add the `-j/--jacobian /path/to/your/jacobian.fits` argument, likewise if you want to use a different base (unperturbed) surface, you can add the `-b/--base /path/to/your/base_surface.tar.gz`. When using this method, the output folder will be picked from the `submit_batch.input` file. See `Examples/Inputs/QuickNDirty/` for an example `.input` file you can try this out on.

If you want to do more complex jobs (creating new jacobian matrices, comparing SALT2 surfaces, plotting, etc...) then you need to use `toml` input files.

### Global options
There are a number of global options which should be set prior to any calculations being performed. The most important of these is the `base_path` which defines a base directory which all non absolute paths are relative to. This defaults to the directory containing your `.toml` file, and can be specified either as an absolute path, or a path relative to the directory containing your `.toml` file. 

The next global option is the `output_path` which is where all the output produced by `SALT2_Jacobian`. This can be either relative to `base_path` or absolute, and defaults to `base_path / Output`

Finally you can specify whether or not to log via `logging`. This defaults to `true`, setting it to `false` will not produce a log file. The name of the log file is specified via `log_file` and defaults to `log.txt`. This will be placed in `output_path`.

```toml
# Example global options
[ global ]
base_path = "/path/to/base"
output_path = "relative/output/path"
logging = true
log_file = "log.txt"
```

### Jacobian options 
You can either create a new jacobian matrix, or simply use one which already exists. See `Examples/Inputs/CreateJacobian` for a working example.

#### Create new jacobian matrix
In order to create a jacobian matrix, you must first generate a set of surfaces, each of which has had a different systematic shifted. In addition a `SUBMIT.INFO` file is required. An example can be found at `Examples/TrainedSurfaces/OUTPUT_TRAIN_T21_suite/`. Once you have these surfaces created, you simply need to specify where that directory is via `trained_surfaces`. This can either be relative to `base_path` or absolute. In addition you can specify the name of the jacobian matrix to be saved via `name`, which defaults to `jacobian`. The jacobian matrix will be saved to `output_path/name.fits`

#### Use a precreated jacobian matrix
If you just want to use a precreated jacobian matrix, such as the one in `src`, you simply need to point to it via `jacobian_path`, once again, either as a path relative to `base_path` or an absolute path.

### Training SALT2 surfaces
In order to train new surfaces you must specify both a `submit_batch` input file and a base surface. The former can be specified via `input_file` (relative to `base_path` or absolute), and the latter via `base_surface` (relative to `base_path` or absolute). See `Examples/Inputs/TrainSurfaces` for a working example.

### Comparing SALT2 surfaces
This stage will compare surfaces by calculating the median percentage difference between the pca component and colour law values of each surface. See `Examples/Inputs/CompareSurfaces` for a working example.

You can specify a set of surfaces to compare to via `comparison_path = "path/to/comparison/directory`. This can either be absolute or relative to `base_path` and should contain the `TRAINOPT***.tar.gz` files. If you trained some surfaces in the same `.toml` file, then those surfaces will be compared to the ones in `comparison_path`. Otherwise, you should also specify a `comparison_path_2`, which will instead be compared with `comparison_path`.

Rather than comparing every `TRAINOPT` you can specify `comparison_surfaces = ["TRAINOPT000.tar.gz", ...]` (and `comparison_surfaces_2`) to choose what trainopts to compare

Finally, you can use `strict_compare = true/false` to choose whether to compare one to one (i.e TRAINOPT000 to TRAINOPT000, TRAINOPT001, to TRAINOPT001, etc...) or all to all (TRAINOPT000 to TRAINOPT000, TRAINOPT000 to TRAINOPT001, etc...). There's also `summary = true/false` which specifies whether to show the median percentage difference or the percentage difference of each pca / colour law component. `summary = false` is more a debugging feature than a feature, so use sparingly.

### Plotting SALT2 surfaces
Much like the comparison stage, the plotting stage has different behaviour, depending on whether you trained new surfaces. or not. See `Examples/Inputs/PlotSurfaces` for a working example.

To specify which surfaces to plot, use `plot_path = "directory/containing/surfaces"`, which can be relative to `base_path` or absolute. If you trained new surfaces, this is automatically set to `output_path`. As with the comparison stage, you can specify specific surfaces via `plot_surfaces = ["TRAINOPT000.tar.gz", ...]`. You can change the name of the plot via `plot_name = "name.svg"`, which default to `Surfaces.svg`.

You can optionally specify a second directory of surfaces via `comparison_plot_path`. These surfaces will be compared to those specified via `plot_path` and the residual between them plotted. You can choose specific surfaces via `comparison_plot_surfaces`, and choose the name of the plot via `comparison_plot_name` which defaults to `Residual.svg`. Finally `strict_compare` acts as it does in the comparison stage, allowing you to specify whether to compare surfaces one to one or all to all.
