# Simulation and Inference

This repository contains the R work for Blog Post 8. I use simulated data to construct a bootstrap confidence interval, check its coverage across repeated samples, and build a null distribution for a two-sided hypothesis test. The blog post itself is kept separately in my `my-website` repository.

No external dataset is used. All samples and results are generated with fixed random seeds.

## Repository structure

| Folder | What is inside |
|---|---|
| `codes/` | Functions and numbered scripts for the analysis |
| `data/generated/` | Samples and simulation data created by the scripts |
| `results/figures/` | Bootstrap, coverage, and hypothesis-testing figures |
| `results/tables/` | Result summaries, replication log, and session information |
| `results/animation/` | Animated bootstrap demonstration |
| `results/interactive/` | Standalone interactive bootstrap explorer |

## Code files

The numbered files are meant to be read and run in order.

| File | What it does |
|---|---|
| `00_simulation_functions.R` | Stores the sampling and bootstrap functions |
| `00_plot_functions.R` | Stores the shared plotting function |
| `01_bootstrap_ci.R` | Constructs one bootstrap distribution and 95% confidence interval |
| `02_coverage_simulation.R` | Checks confidence-interval coverage over 2,000 samples |
| `03_hypothesis_testing.R` | Simulates the null distribution, rejection regions, and p-value |
| `04_create_animation.R` | Creates the bootstrap GIF |
| `05_create_interactive.R` | Creates the interactive HTML demonstration |
| `06_run_all.R` | Runs the full project and checks the saved outputs |

## Reproducing the results

Open `blogpost8_Simulation_and_Inference.Rproj` in RStudio. Install the required packages if they are not already available:

```r
install.packages(c("ggplot2", "gganimate", "gifski"))
```

Then run the master script from the project root:

```r
source("codes/06_run_all.R")
```

This rebuilds the generated data, tables, figures, GIF, and interactive HTML. It also saves a replication log and the R session information in `results/tables/`.

## Results to view

- `results/figures/bootstrap_distribution.png`
- `results/figures/confidence_interval_coverage.png`
- `results/figures/null_distribution_hypothesis_test.png`
- `results/animation/bootstrap_distribution_builds.gif`
- `results/interactive/bootstrap_explorer.html`

The interactive HTML can be downloaded and opened directly in a browser. It does not require Shiny or an R server.

In the repeated-sampling experiment, the 95% bootstrap intervals covered the true mean 94.8% of the time. The simulated two-sided hypothesis test produced a p-value of 0.0162.