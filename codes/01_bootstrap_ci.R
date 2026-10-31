# ============================================================
# Part 1: Bootstrap confidence interval
#
# This script:
# 1. Draws one sample from a known population
# 2. Resamples from it with replacement
# 3. Constructs the bootstrap distribution
# 4. Calculates a 95% percentile bootstrap interval
# 5. Saves the code-generated data, summary, and figure
# ============================================================


# ------------------------------------------------------------
# 1. Confirm the project location
# ------------------------------------------------------------

project_root <- normalizePath(
  getwd(),
  winslash = "/",
  mustWork = TRUE
)

rproj_files <- list.files(
  path = ".",
  pattern = "\\.Rproj$"
)

if (
  length(rproj_files) == 0 ||
  !dir.exists("codes") ||
  !dir.exists("data") ||
  !dir.exists("results")
) {
  stop(
    paste0(
      "The project root was not detected correctly.\n",
      "Current working directory:\n",
      project_root,
      "\n\nOpen the correct RStudio project and run Source again."
    )
  )
}

message("Project root confirmed: ", project_root)


# ------------------------------------------------------------
# 2. Install and load the required package
# ------------------------------------------------------------

if (!requireNamespace("ggplot2", quietly = TRUE)) {
  install.packages(
    "ggplot2",
    repos = "https://cloud.r-project.org"
  )
}

library(ggplot2)


# ------------------------------------------------------------
# 3. Confirm output directories
# ------------------------------------------------------------

required_directories <- c(
  "data/generated",
  "results/figures",
  "results/tables"
)

for (directory in required_directories) {
  if (!dir.exists(directory)) {
    dir.create(
      directory,
      recursive = TRUE,
      showWarnings = FALSE
    )
  }
}


# ------------------------------------------------------------
# 4. Load the reusable functions
# ------------------------------------------------------------

source("codes/00_simulation_functions.R")
source("codes/00_plot_functions.R")


# ------------------------------------------------------------
# 5. Set the simulation design
# ------------------------------------------------------------

true_population_mean <- 10
population_log_sd <- 0.60

sample_size <- 50
bootstrap_repetitions <- 5000
confidence_level <- 0.95

# A fixed seed is used for full reproducibility.
# This seed produces a typical sample for the introductory example.
sample_seed <- 6400
bootstrap_seed <- 8640


# ------------------------------------------------------------
# 6. Draw one observed sample
# ------------------------------------------------------------

set.seed(sample_seed)

observed_values <- generate_population_sample(
  n = sample_size,
  true_mean = true_population_mean,
  log_sd = population_log_sd
)

observed_sample <- data.frame(
  observation = seq_len(sample_size),
  value = observed_values
)

observed_sample_mean <- mean(observed_values)


# ------------------------------------------------------------
# 7. Generate the bootstrap distribution
# ------------------------------------------------------------

set.seed(bootstrap_seed)

bootstrap_estimates <- bootstrap_sample_means(
  sample_values = observed_values,
  bootstrap_repetitions = bootstrap_repetitions
)

bootstrap_distribution <- data.frame(
  bootstrap_iteration = seq_len(bootstrap_repetitions),
  bootstrap_mean = bootstrap_estimates
)


# ------------------------------------------------------------
# 8. Construct the 95% percentile bootstrap interval
# ------------------------------------------------------------

bootstrap_interval <- calculate_percentile_interval(
  bootstrap_estimates = bootstrap_estimates,
  confidence_level = confidence_level
)

ci_lower <- unname(
  bootstrap_interval["lower"]
)

ci_upper <- unname(
  bootstrap_interval["upper"]
)

interval_contains_truth <- (
  ci_lower <= true_population_mean &&
    ci_upper >= true_population_mean
)


# ------------------------------------------------------------
# 9. Create the numerical summary
# ------------------------------------------------------------

bootstrap_summary <- data.frame(
  population_distribution = "Lognormal",
  true_population_mean = true_population_mean,
  population_log_sd = population_log_sd,
  sample_seed = sample_seed,
  sample_size = sample_size,
  observed_sample_mean = observed_sample_mean,
  bootstrap_seed = bootstrap_seed,
  bootstrap_repetitions = bootstrap_repetitions,
  bootstrap_mean = mean(bootstrap_estimates),
  bootstrap_standard_error = stats::sd(bootstrap_estimates),
  confidence_level = confidence_level,
  confidence_interval_method = "Percentile bootstrap",
  ci_lower = ci_lower,
  ci_upper = ci_upper,
  interval_contains_true_mean = interval_contains_truth
)


# ------------------------------------------------------------
# 10. Save all generated data
# ------------------------------------------------------------

utils::write.csv(
  observed_sample,
  file = "data/generated/observed_sample.csv",
  row.names = FALSE
)

utils::write.csv(
  bootstrap_distribution,
  file = "data/generated/bootstrap_distribution.csv",
  row.names = FALSE
)

utils::write.csv(
  bootstrap_summary,
  file = "results/tables/bootstrap_summary.csv",
  row.names = FALSE
)


# ------------------------------------------------------------
# 11. Create and save the figure
# ------------------------------------------------------------

bootstrap_figure <- plot_bootstrap_distribution(
  bootstrap_data = bootstrap_distribution,
  sample_mean = observed_sample_mean,
  true_mean = true_population_mean,
  ci_lower = ci_lower,
  ci_upper = ci_upper,
  confidence_level = confidence_level,
  bootstrap_repetitions = bootstrap_repetitions
)

print(bootstrap_figure)

ggplot2::ggsave(
  filename = "results/figures/bootstrap_distribution.png",
  plot = bootstrap_figure,
  width = 9,
  height = 6,
  units = "in",
  dpi = 300,
  bg = "white"
)


# ------------------------------------------------------------
# 12. Verify every required output
# ------------------------------------------------------------

expected_outputs <- c(
  "data/generated/observed_sample.csv",
  "data/generated/bootstrap_distribution.csv",
  "results/tables/bootstrap_summary.csv",
  "results/figures/bootstrap_distribution.png"
)

missing_outputs <- expected_outputs[
  !file.exists(expected_outputs)
]

if (length(missing_outputs) > 0) {
  stop(
    paste0(
      "The following outputs were not created:\n",
      paste(missing_outputs, collapse = "\n")
    )
  )
}


# ------------------------------------------------------------
# 13. Print the verified result
# ------------------------------------------------------------

cat(
  "\n",
  "============================================================\n",
  "PART 1 COMPLETE: BOOTSTRAP CONFIDENCE INTERVAL\n",
  "============================================================\n",
  "Population distribution: Lognormal\n",
  "True population mean: ", true_population_mean, "\n",
  "Sample size: ", sample_size, "\n",
  "Observed sample mean: ",
  round(observed_sample_mean, 3), "\n",
  "Bootstrap resamples: ",
  format(bootstrap_repetitions, big.mark = ","), "\n",
  "Bootstrap mean: ",
  round(mean(bootstrap_estimates), 3), "\n",
  "Bootstrap standard error: ",
  round(stats::sd(bootstrap_estimates), 3), "\n",
  round(confidence_level * 100),
  "% bootstrap confidence interval: [",
  round(ci_lower, 3), ", ",
  round(ci_upper, 3), "]\n",
  "Interval contains the true mean: ",
  interval_contains_truth, "\n\n",
  "Saved outputs:\n",
  paste(expected_outputs, collapse = "\n"),
  "\n============================================================\n",
  sep = ""
)