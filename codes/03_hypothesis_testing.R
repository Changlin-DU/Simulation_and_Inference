# ============================================================
# Part 3: Hypothesis testing through simulation
#
# H0: population mean = 10
# HA: population mean is not equal to 10
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
# 2. Install and load ggplot2
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
# 4. Set the hypothesis-test design
# ------------------------------------------------------------

null_mean <- 10
observed_population_mean <- 11
population_standard_deviation <- 4

sample_size <- 50
significance_level <- 0.05
number_of_null_simulations <- 20000

observed_sample_seed <- 6400
null_simulation_seed <- 8640


# ------------------------------------------------------------
# 5. Generate the observed sample
# ------------------------------------------------------------

set.seed(observed_sample_seed)

observed_values <- stats::rnorm(
  n = sample_size,
  mean = observed_population_mean,
  sd = population_standard_deviation
)

observed_sample <- data.frame(
  observation = seq_len(sample_size),
  value = observed_values
)

observed_sample_mean <- mean(
  observed_values
)

observed_sample_sd <- stats::sd(
  observed_values
)

observed_standard_error <- (
  observed_sample_sd / sqrt(sample_size)
)

observed_t_statistic <- (
  observed_sample_mean - null_mean
) / observed_standard_error


# ------------------------------------------------------------
# 6. Generate the null distribution
#
# Every simulated sample is generated under H0:
# population mean = 10.
# ------------------------------------------------------------

set.seed(null_simulation_seed)

null_samples <- matrix(
  stats::rnorm(
    n = number_of_null_simulations * sample_size,
    mean = null_mean,
    sd = population_standard_deviation
  ),
  nrow = number_of_null_simulations,
  ncol = sample_size
)

null_sample_means <- rowMeans(
  null_samples
)

null_sample_sds <- apply(
  null_samples,
  MARGIN = 1,
  FUN = stats::sd
)

null_standard_errors <- (
  null_sample_sds / sqrt(sample_size)
)

null_t_statistics <- (
  null_sample_means - null_mean
) / null_standard_errors

rm(null_samples)

invisible(gc())


# ------------------------------------------------------------
# 7. Calculate the rejection-region boundaries
# ------------------------------------------------------------

critical_values <- stats::quantile(
  x = null_t_statistics,
  probs = c(
    significance_level / 2,
    1 - significance_level / 2
  ),
  names = FALSE,
  type = 7
)

lower_critical_value <- critical_values[1]
upper_critical_value <- critical_values[2]


# ------------------------------------------------------------
# 8. Calculate the two-sided simulation p-value
# ------------------------------------------------------------

extreme_null_statistics <- (
  abs(null_t_statistics) >=
    abs(observed_t_statistic)
)

number_as_or_more_extreme <- sum(
  extreme_null_statistics
)

simulated_p_value <- (
  number_as_or_more_extreme + 1
) / (
  number_of_null_simulations + 1
)


# ------------------------------------------------------------
# 9. Make the statistical decision
# ------------------------------------------------------------

reject_null <- (
  simulated_p_value < significance_level
)

test_decision <- if (
  reject_null
) {
  "Reject H0"
} else {
  "Do not reject H0"
}


# ------------------------------------------------------------
# 10. Save the generated data
# ------------------------------------------------------------

null_distribution <- data.frame(
  simulation = seq_len(number_of_null_simulations),
  sample_mean = null_sample_means,
  sample_standard_deviation = null_sample_sds,
  standard_error = null_standard_errors,
  t_statistic = null_t_statistics,
  in_rejection_region = (
    null_t_statistics <= lower_critical_value |
      null_t_statistics >= upper_critical_value
  ),
  as_or_more_extreme_than_observed = extreme_null_statistics
)

utils::write.csv(
  observed_sample,
  file = "data/generated/hypothesis_observed_sample.csv",
  row.names = FALSE
)

utils::write.csv(
  null_distribution,
  file = "data/generated/null_distribution.csv",
  row.names = FALSE
)


# ------------------------------------------------------------
# 11. Save the hypothesis-test summary
# ------------------------------------------------------------

hypothesis_test_summary <- data.frame(
  null_hypothesis = "Population mean = 10",
  alternative_hypothesis = "Population mean is not equal to 10",
  test_type = "Two-sided simulated t-test",
  null_mean = null_mean,
  observed_sample_seed = observed_sample_seed,
  observed_sample_size = sample_size,
  observed_sample_mean = observed_sample_mean,
  observed_sample_sd = observed_sample_sd,
  observed_standard_error = observed_standard_error,
  observed_t_statistic = observed_t_statistic,
  null_simulation_seed = null_simulation_seed,
  number_of_null_simulations = number_of_null_simulations,
  significance_level = significance_level,
  lower_critical_value = lower_critical_value,
  upper_critical_value = upper_critical_value,
  number_as_or_more_extreme = number_as_or_more_extreme,
  simulated_p_value = simulated_p_value,
  decision = test_decision
)

utils::write.csv(
  hypothesis_test_summary,
  file = "results/tables/hypothesis_test_summary.csv",
  row.names = FALSE
)


# ------------------------------------------------------------
# 12. Build histogram data
# ------------------------------------------------------------

null_histogram <- hist(
  null_t_statistics,
  breaks = 80,
  plot = FALSE
)

histogram_data <- data.frame(
  midpoint = null_histogram$mids,
  density = null_histogram$density
)

histogram_data$region <- ifelse(
  abs(histogram_data$midpoint) >=
    abs(observed_t_statistic),
  "At least as extreme as observed",
  ifelse(
    histogram_data$midpoint <= lower_critical_value |
      histogram_data$midpoint >= upper_critical_value,
    "5% rejection region",
    "Non-rejection region"
  )
)

histogram_data$region <- factor(
  histogram_data$region,
  levels = c(
    "Non-rejection region",
    "5% rejection region",
    "At least as extreme as observed"
  )
)

histogram_bin_width <- diff(
  null_histogram$breaks
)[1]

maximum_density <- max(
  histogram_data$density
)


# ------------------------------------------------------------
# 13. Create the null-distribution visualization
# ------------------------------------------------------------

null_distribution_figure <- ggplot(
  histogram_data,
  aes(
    x = midpoint,
    y = density,
    fill = region
  )
) +
  geom_col(
    width = histogram_bin_width,
    color = "white",
    linewidth = 0.15,
    alpha = 0.92
  ) +
  geom_density(
    data = null_distribution,
    aes(x = t_statistic),
    inherit.aes = FALSE,
    color = "#173F5F",
    linewidth = 1
  ) +
  geom_vline(
    xintercept = c(
      lower_critical_value,
      upper_critical_value
    ),
    color = "#C0392B",
    linetype = "dashed",
    linewidth = 1
  ) +
  geom_vline(
    xintercept = -abs(observed_t_statistic),
    color = "#E67E22",
    linetype = "dotdash",
    linewidth = 1
  ) +
  geom_vline(
    xintercept = observed_t_statistic,
    color = "#222222",
    linetype = "solid",
    linewidth = 1.15
  ) +
  annotate(
    geom = "label",
    x = observed_t_statistic,
    y = maximum_density * 0.92,
    label = paste0(
      "Observed t = ",
      round(observed_t_statistic, 2)
    ),
    hjust = 1.08,
    size = 3.7,
    fontface = "bold",
    color = "#222222",
    fill = "white",
    linewidth = 0
  ) +
  scale_fill_manual(
    name = NULL,
    values = c(
      "Non-rejection region" = "#8ECAE6",
      "5% rejection region" = "#E76F51",
      "At least as extreme as observed" = "#F4A261"
    )
  ) +
  coord_cartesian(
    xlim = c(-4.5, 4.5),
    expand = FALSE
  ) +
  labs(
    title = "Hypothesis Testing Through Simulation",
    subtitle = paste0(
      "H0: mean = ",
      null_mean,
      " versus HA: mean is not ",
      null_mean,
      "  |  simulated p-value = ",
      format(
        round(simulated_p_value, 4),
        nsmall = 4
      )
    ),
    x = "t-statistic under the null hypothesis",
    y = "Density",
    caption = paste0(
      "The red dashed lines mark the 5% rejection boundaries. ",
      "The black line is the observed statistic.\n",
      "The p-value is the proportion of simulated null statistics ",
      "at least as extreme as the observed statistic in either direction."
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
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
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

print(null_distribution_figure)


# ------------------------------------------------------------
# 14. Save the figure
# ------------------------------------------------------------

ggplot2::ggsave(
  filename = "results/figures/null_distribution_hypothesis_test.png",
  plot = null_distribution_figure,
  width = 9,
  height = 6.5,
  units = "in",
  dpi = 300,
  bg = "white"
)


# ------------------------------------------------------------
# 15. Verify all required outputs
# ------------------------------------------------------------

expected_outputs <- c(
  "data/generated/hypothesis_observed_sample.csv",
  "data/generated/null_distribution.csv",
  "results/tables/hypothesis_test_summary.csv",
  "results/figures/null_distribution_hypothesis_test.png"
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
# 16. Print the verified result
# ------------------------------------------------------------

cat(
  "\n",
  "============================================================\n",
  "PART 3 COMPLETE: HYPOTHESIS TESTING THROUGH SIMULATION\n",
  "============================================================\n",
  "Null hypothesis: population mean = ",
  null_mean, "\n",
  "Alternative hypothesis: population mean is not ",
  null_mean, "\n",
  "Test type: Two-sided\n",
  "Significance level: ",
  significance_level, "\n\n",
  "Observed sample size: ",
  sample_size, "\n",
  "Observed sample mean: ",
  round(observed_sample_mean, 3), "\n",
  "Observed sample standard deviation: ",
  round(observed_sample_sd, 3), "\n",
  "Observed t-statistic: ",
  round(observed_t_statistic, 3), "\n\n",
  "Number of null simulations: ",
  format(number_of_null_simulations, big.mark = ","), "\n",
  "Lower rejection boundary: ",
  round(lower_critical_value, 3), "\n",
  "Upper rejection boundary: ",
  round(upper_critical_value, 3), "\n",
  "Null statistics at least as extreme as observed: ",
  number_as_or_more_extreme, "\n",
  "Simulation-based p-value: ",
  format(
    round(simulated_p_value, 4),
    nsmall = 4
  ),
  "\n",
  "Decision: ",
  test_decision, "\n\n",
  "Interpretation:\n",
  "If the null hypothesis were true, only about ",
  round(simulated_p_value * 100, 2),
  "% of simulated test statistics would be at least as extreme ",
  "as the observed statistic.\n",
  "Because the p-value is below ",
  significance_level,
  ", we reject H0.\n\n",
  "Saved outputs:\n",
  paste(expected_outputs, collapse = "\n"),
  "\n============================================================\n",
  sep = ""
)
