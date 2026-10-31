# ============================================================
# Part 2: Confidence-interval coverage
#
# This script:
# 1. Draws 2,000 independent samples
# 2. Constructs a 95% bootstrap CI for every sample
# 3. Calculates the empirical coverage rate
# 4. Displays 95 covering and 5 non-covering intervals
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
# 3. Load reusable functions
# ------------------------------------------------------------

source("codes/00_simulation_functions.R")


# ------------------------------------------------------------
# 4. Confirm output directories
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
# 5. Set the repeated-simulation design
# ------------------------------------------------------------

true_population_mean <- 10
population_standard_deviation <- 4

sample_size <- 50
confidence_level <- 0.95

number_of_simulations <- 2000
bootstrap_repetitions <- 800

coverage_seed <- 6400


# ------------------------------------------------------------
# 6. Prepare result storage
# ------------------------------------------------------------

simulation_id <- seq_len(
  number_of_simulations
)

sample_means <- numeric(
  number_of_simulations
)

bootstrap_standard_errors <- numeric(
  number_of_simulations
)

ci_lower_values <- numeric(
  number_of_simulations
)

ci_upper_values <- numeric(
  number_of_simulations
)

coverage_indicators <- logical(
  number_of_simulations
)


# ------------------------------------------------------------
# 7. Run the repeated bootstrap simulation
# ------------------------------------------------------------

set.seed(coverage_seed)

for (simulation in simulation_id) {
  
  current_sample <- stats::rnorm(
    n = sample_size,
    mean = true_population_mean,
    sd = population_standard_deviation
  )
  
  current_sample_mean <- mean(
    current_sample
  )
  
  current_bootstrap_means <- bootstrap_sample_means(
    sample_values = current_sample,
    bootstrap_repetitions = bootstrap_repetitions
  )
  
  current_interval <- calculate_percentile_interval(
    bootstrap_estimates = current_bootstrap_means,
    confidence_level = confidence_level
  )
  
  current_lower <- unname(
    current_interval["lower"]
  )
  
  current_upper <- unname(
    current_interval["upper"]
  )
  
  current_covers_truth <- (
    current_lower <= true_population_mean &&
      current_upper >= true_population_mean
  )
  
  sample_means[simulation] <- current_sample_mean
  
  bootstrap_standard_errors[simulation] <- stats::sd(
    current_bootstrap_means
  )
  
  ci_lower_values[simulation] <- current_lower
  ci_upper_values[simulation] <- current_upper
  coverage_indicators[simulation] <- current_covers_truth
  
  if (simulation %% 250 == 0) {
    message(
      "Completed ",
      simulation,
      " of ",
      number_of_simulations,
      " simulations."
    )
  }
}


# ------------------------------------------------------------
# 8. Combine the complete simulation results
# ------------------------------------------------------------

coverage_results <- data.frame(
  simulation = simulation_id,
  sample_mean = sample_means,
  bootstrap_standard_error = bootstrap_standard_errors,
  ci_lower = ci_lower_values,
  ci_upper = ci_upper_values,
  covers_true_mean = coverage_indicators
)

empirical_coverage_rate <- mean(
  coverage_results$covers_true_mean
)

number_covering <- sum(
  coverage_results$covers_true_mean
)

number_missing <- sum(
  !coverage_results$covers_true_mean
)


# ------------------------------------------------------------
# 9. Create the numerical summary
# ------------------------------------------------------------

coverage_summary <- data.frame(
  population_distribution = "Normal",
  true_population_mean = true_population_mean,
  population_standard_deviation = population_standard_deviation,
  sample_size = sample_size,
  confidence_level = confidence_level,
  confidence_interval_method = "Percentile bootstrap",
  number_of_simulations = number_of_simulations,
  bootstrap_repetitions_per_simulation = bootstrap_repetitions,
  simulation_seed = coverage_seed,
  intervals_covering_true_mean = number_covering,
  intervals_missing_true_mean = number_missing,
  empirical_coverage_rate = empirical_coverage_rate
)


# ------------------------------------------------------------
# 10. Save the complete results
# ------------------------------------------------------------

utils::write.csv(
  coverage_results,
  file = "data/generated/coverage_simulation.csv",
  row.names = FALSE
)

utils::write.csv(
  coverage_summary,
  file = "results/tables/coverage_summary.csv",
  row.names = FALSE
)


# ------------------------------------------------------------
# 11. Helper for selecting evenly spaced observations
# ------------------------------------------------------------

select_evenly <- function(indices, number_to_select) {
  if (length(indices) < number_to_select) {
    stop(
      "There are not enough observations for the requested display."
    )
  }
  
  selected_positions <- unique(
    round(
      seq(
        from = 1,
        to = length(indices),
        length.out = number_to_select
      )
    )
  )
  
  indices[selected_positions]
}


# ------------------------------------------------------------
# 12. Select an educational set of 100 intervals
#
# The display contains:
# - 95 intervals that cover the true mean
# - 5 intervals that miss the true mean
#
# The overall empirical rate is calculated from all 2,000
# simulations, not from this illustrative subset.
# ------------------------------------------------------------

covering_indices <- which(
  coverage_results$covers_true_mean
)

missing_indices <- which(
  !coverage_results$covers_true_mean
)

covering_indices <- covering_indices[
  order(
    coverage_results$sample_mean[
      covering_indices
    ]
  )
]

selected_covering_indices <- select_evenly(
  indices = covering_indices,
  number_to_select = 95
)

missing_indices <- missing_indices[
  order(
    coverage_results$sample_mean[
      missing_indices
    ]
  )
]

selected_missing_indices <- c(
  head(missing_indices, 3),
  tail(missing_indices, 2)
)

selected_indices <- c(
  selected_covering_indices,
  selected_missing_indices
)

coverage_plot_data <- coverage_results[
  selected_indices,
]

coverage_plot_data <- coverage_plot_data[
  order(coverage_plot_data$sample_mean),
]

coverage_plot_data$display_order <- seq_len(
  nrow(coverage_plot_data)
)

coverage_plot_data$coverage_status <- ifelse(
  coverage_plot_data$covers_true_mean,
  "Covers true mean",
  "Misses true mean"
)

coverage_plot_data$coverage_status <- factor(
  coverage_plot_data$coverage_status,
  levels = c(
    "Covers true mean",
    "Misses true mean"
  )
)


# ------------------------------------------------------------
# 13. Verify the illustrative subset
# ------------------------------------------------------------

displayed_covering <- sum(
  coverage_plot_data$covers_true_mean
)

displayed_missing <- sum(
  !coverage_plot_data$covers_true_mean
)

if (
  displayed_covering != 95 ||
  displayed_missing != 5
) {
  stop(
    "The illustrative subset does not contain 95 covers and 5 misses."
  )
}


# ------------------------------------------------------------
# 14. Create the optimized coverage figure
# ------------------------------------------------------------

coverage_figure <- ggplot(
  coverage_plot_data,
  aes(
    y = display_order,
    color = coverage_status
  )
) +
  geom_segment(
    aes(
      x = ci_lower,
      xend = ci_upper,
      yend = display_order
    ),
    linewidth = 0.9,
    alpha = 0.95,
    lineend = "round"
  ) +
  geom_point(
    aes(x = sample_mean),
    size = 2.2,
    alpha = 1
  ) +
  geom_vline(
    xintercept = true_population_mean,
    color = "#222222",
    linetype = "dashed",
    linewidth = 1
  ) +
  annotate(
    geom = "label",
    x = true_population_mean,
    y = 104,
    label = paste0(
      "True population mean = ",
      true_population_mean
    ),
    size = 3.8,
    fontface = "bold",
    color = "#222222",
    fill = "white",
    linewidth = 0
  ) +
  scale_color_manual(
    name = NULL,
    values = c(
      "Covers true mean" = "#277DA1",
      "Misses true mean" = "#F3722C"
    )
  ) +
  scale_y_continuous(
    breaks = NULL,
    limits = c(1, 105),
    expand = expansion(
      mult = c(0.01, 0.01)
    )
  ) +
  labs(
    title = "What Does 95% Confidence Mean?",
    subtitle = paste0(
      "Across ",
      format(number_of_simulations, big.mark = ","),
      " repeated samples, ",
      round(empirical_coverage_rate * 100, 1),
      "% of the intervals captured the true mean"
    ),
    x = "95% bootstrap confidence interval for the population mean",
    y = "100 illustrative intervals",
    caption = paste0(
      "Each horizontal line is one 95% bootstrap confidence interval; ",
      "the dot is its sample mean.\n",
      "The dashed line marks the true mean. ",
      "The display contains 95 covering intervals and 5 misses."
    )
  ) +
  theme_minimal(
    base_size = 13
  ) +
  theme(
    plot.title = element_text(
      face = "bold",
      size = 17,
      color = "#17324D"
    ),
    plot.subtitle = element_text(
      size = 12,
      color = "#4D5D6C",
      margin = margin(
        b = 10
      )
    ),
    plot.caption = element_text(
      size = 9.5,
      color = "#4D5D6C",
      hjust = 0,
      lineheight = 1.2
    ),
    legend.position = "bottom",
    panel.grid.major.y = element_blank(),
    panel.grid.minor = element_blank(),
    axis.title = element_text(
      face = "bold"
    ),
    plot.margin = margin(
      t = 12,
      r = 18,
      b = 12,
      l = 12
    )
  )

print(coverage_figure)


# ------------------------------------------------------------
# 15. Save the optimized figure
# ------------------------------------------------------------

ggplot2::ggsave(
  filename = "results/figures/confidence_interval_coverage.png",
  plot = coverage_figure,
  width = 9,
  height = 6.5,
  units = "in",
  dpi = 300,
  bg = "white"
)


# ------------------------------------------------------------
# 16. Verify all required outputs
# ------------------------------------------------------------

expected_outputs <- c(
  "data/generated/coverage_simulation.csv",
  "results/tables/coverage_summary.csv",
  "results/figures/confidence_interval_coverage.png"
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
# 17. Print the verified result
# ------------------------------------------------------------

cat(
  "\n",
  "============================================================\n",
  "PART 2 COMPLETE: CONFIDENCE-INTERVAL COVERAGE\n",
  "============================================================\n",
  "Population distribution: Normal\n",
  "True population mean: ",
  true_population_mean, "\n",
  "Population standard deviation: ",
  population_standard_deviation, "\n",
  "Sample size per simulation: ",
  sample_size, "\n",
  "Number of repeated simulations: ",
  format(number_of_simulations, big.mark = ","), "\n",
  "Bootstrap resamples per simulation: ",
  format(bootstrap_repetitions, big.mark = ","), "\n",
  "Confidence level: ",
  round(confidence_level * 100), "%\n",
  "Intervals covering the true mean: ",
  number_covering, "\n",
  "Intervals missing the true mean: ",
  number_missing, "\n",
  "Empirical coverage rate: ",
  round(empirical_coverage_rate * 100, 1), "%\n\n",
  "Illustrative figure:\n",
  displayed_covering,
  " intervals cover the true mean.\n",
  displayed_missing,
  " intervals miss the true mean.\n\n",
  "Interpretation:\n",
  "A 95% confidence level describes the long-run performance ",
  "of the procedure.\nIt does not guarantee that every individual ",
  "interval contains the true parameter.\n\n",
  "Saved outputs:\n",
  paste(expected_outputs, collapse = "\n"),
  "\n============================================================\n",
  sep = ""
)