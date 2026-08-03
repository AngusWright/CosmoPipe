# CosmoPipe

**CosmoPipe is a modular, configuration-driven pipeline for cosmic-shear data analysis and cosmological inference.** It supports the path from survey catalogues through calibration, tomographic measurements, covariance modelling, and likelihood sampling with [CosmoSIS](https://cosmosis.info/).

Originally developed for KiDS cosmology analyses, CosmoPipe provides reusable processing functions and reference configurations for analyses including KiDS-1000 and Euclid-style data products.

> [!WARNING]
> Cosmic-shear inference is sensitive to analysis choices. Review, validate, and document all configuration values, external inputs, and processing steps for your science case before interpreting results.

## Capabilities

- Ingest, select, split, merge, and calibrate galaxy catalogues.
- Construct and validate redshift distributions, including SOM-based calibration workflows.
- Create tomographic samples and measure shear statistics with TreeCorr.
- Produce two-point correlation functions, COSEBIs, band powers, and E/B-mode diagnostic statistics.
- Build and combine covariance components, including Gaussian, non-Gaussian, and super-sample covariance contributions.
- Model systematics such as shear calibration, redshift uncertainty, and intrinsic alignments.
- Construct CosmoSIS configurations and run Bayesian inference with supported samplers.
- Generate diagnostic plots and posterior summaries.

## How it works

CosmoPipe expresses an analysis as an ordered pipeline of **processing functions**. Each function has:

- a master script at `scripts/<function>.sh`;
- an interface and usage contract at `man/<function>.man.sh`; and
- declared inputs, outputs, and required runtime variables.

At configuration time, CosmoPipe copies the source scripts, manuals, and configuration files into a dedicated runtime directory and resolves the appropriate paths and static variables. Pipeline construction then creates an executable, ordered pipeline script.

Processing functions exchange products through a persistent **data block**. `DATAHEAD` denotes the current target data product; for example, `tomography` reads the catalogue at `DATAHEAD` and replaces it with one catalogue per tomographic bin. Processing-function source scripts may contain runtime block-variable placeholders (`@BV:<VARIABLE>@`) and data-block placeholders (`@DB:<DATASET>@` or `@DB:DATAHEAD@`); these are resolved while the generated pipeline executes.

Do not edit or run individual steps from a generated pipeline script independently: their correctness depends on the declared data flow and generated runtime context.

## Repository layout

| Path | Purpose |
| --- | --- |
| `scripts/` | Processing-function implementations and pipeline construction tools |
| `man/` | Per-function interface documentation and housekeeping logic |
| `config/` | Default variables, inference settings, and example pipeline definitions |
| `pipelines/` | Additional ready-made pipeline definitions |
| `data/` | Packaged reference data products |
| `kcap/` | KiDS cosmology analysis components and utilities |
| `ia_models/` | Intrinsic-alignment model implementations |
| `manual/` | Source for the project manual |

## Installation

CosmoPipe is developed for Linux and macOS and uses Conda to provision its scientific software environment. The installer creates an environment named `cosmopipe`, installs required R packages, and obtains several external scientific dependencies.

```bash
git clone git@github.com:AngusWright/CosmoPipe.git
cd CosmoPipe
bash COSMOPIPE_MASTER_INSTALL.sh --runroot /path/to/cosmopipe-run
```

The installer infers `PACKROOT` from the current directory. For non-standard systems, pass the required paths and executable names explicitly:

```bash
bash COSMOPIPE_MASTER_INSTALL.sh \
  --packroot "$(pwd)" \
  --runroot /path/to/cosmopipe-run \
  --user "$(whoami)" \
  --machine Linux_64 \
  --p_rscript Rscript \
  --p_sed_inplace 'sed -i '
```

Activate the environment before configuring or running a pipeline:

```bash
conda activate cosmopipe
```

See `COSMOPIPE_MASTER_INSTALL.sh` and `man/COSMOPIPE_MASTER_INSTALL.man.sh` for the installer’s supported options and platform-specific behavior.

## Configure and run an analysis

The source checkout and a configured analysis run are intentionally separate. After installation:

1. Review the generated `variables.sh` in the run root. Set survey-specific paths, catalogue column names, tomography limits, calibration inputs, and inference options.
2. Select and adapt a pipeline definition. The reference `config/pipeline.ini` includes examples such as `AsgariDemo` and `Asgari_minipipe`; additional definitions are in `pipelines/`.
3. Configure and construct the pipeline from the run root:

   ```bash
   bash configure.sh <pipeline-name>
   ```

   Configuration creates a `RUNTIME_<pipeline-name>/` directory with resolved scripts, manuals, configuration files, and logs, then writes `<pipeline-name>_pipeline.sh`.
4. Configure the CosmoSIS standard library if required by the selected workflow, then run the generated pipeline:

   ```bash
   source INSTALL/cosmosis-standard-library/cosmosis-configure
   bash <pipeline-name>_pipeline.sh
   ```

   The equivalent command without activating the environment is:

   ```bash
   conda run -n cosmopipe --no-capture-output bash <pipeline-name>_pipeline.sh
   ```

Generated logs are stored beneath `RUNTIME_<pipeline-name>/logs/`; analysis products and data-block state are stored beneath `work_<pipeline-name>/` by default.

## Building a pipeline

Start from a reference pipeline and compose it from documented processing functions. Read a function’s corresponding manual before adding it. For example:

```bash
source man/tomography.man.sh
_description
```

Processing functions must declare their data inputs and outputs accurately. This enables CosmoPipe to construct the execution order, populate each function’s data-block placeholders, and detect invalid data-flow combinations before science products are generated.

## Dependencies

The Conda environment specifications are provided in `environment.yml` (Linux) and `environment_darwin.yml` (macOS). The workflow relies on the broader cosmology ecosystem, including CosmoSIS, CAMB, TreeCorr, OneCovariance, Python, and R. The installer downloads and configures additional external repositories; network access and compilers are therefore required for a full installation.

## Contributing

Contributions that improve processing functions, configurations, documentation, and reproducibility are welcome. When adding or modifying a processing function:

1. Keep `scripts/<function>.sh` and `man/<function>.man.sh` in sync.
2. Document required variables and data-block inputs and outputs.
3. Preserve `@BV:...@`, `@DB:...@`, and `@DB:DATAHEAD@` templating semantics.
4. Validate the function within a configured pipeline rather than by editing generated runtime files.

## License

CosmoPipe is distributed under the [GNU General Public License v3.0](LICENSE).
