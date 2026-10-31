# ============================================================
# Part 4A: Animated bootstrap demonstration
#
# This script creates a GIF showing how the bootstrap
# distribution and its 95% confidence interval develop as
# the number of resamples increases.
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
# 2. Install and load required packages
# ------------------------------------------------------------

required_packages <- c(
  "ggplot2",
  "gganimate",
  "gifski"
)

packages_to_install <- required_packages[
  !vapply(
    required_packages,
    requireNamespace,
    quietly = TRUE,
    FUN.VALUE = logical(1)
  )
]

if (length(packages_to_install) > 0) {
  install.packages(
    packages_to_install,
    repos = "https://cloud.r-project.org"
  )
}

library(ggplot2)
library(gganimate)


# ------------------------------------------------------------
# 3. Confirm required Part 1 files
# ------------------------------------------------------------

required_input_files <- c(
  "data/generated/observed_sample.csv",
  "data/generated/bootstrap_distribution.csv",
  "results/tables/bootstrap_summary.csv"
)

missing_input_files <- required_input_files[
  !file.exists(required_input_files)
]

if (length(missing_input_files) > 0) {
  stop(
    paste0(
      "The following Part 1 files are missing:\n",
      paste(missing_input_files, collapse = "\n"),
      "\n\nRun codes/01_bootstrap_ci.R first."
    )
  )
}


# ------------------------------------------------------------
# 4. Confirm output directories
# ------------------------------------------------------------

required_directories <- c(
  "data/generated",
  "results/animation"
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
# 5. Read the verified Part 1 results
# ------------------------------------------------------------

observed_sample <- utils::read.csv(
  "data/generated/observed_sample.csv"
)

bootstrap_distribution <- utils::read.csv(
  "data/generated/bootstrap_distribution.csv"
)

bootstrap_summary <- utils::read.csv(
  "results/tables/bootstrap_summary.csv"
)

sample_mean <- mean(
  observed_sample$value
)

true_population_mean <- bootstrap_summary$true_population_mean[1]

confidence_level <- bootstrap_summary$confidence_level[1]

total_bootstrap_repetitions <- nrow(
  bootstrap_distribution
)


# ------------------------------------------------------------
# 6. Validate the input data
# ------------------------------------------------------------

if (
  !"bootstrap_mean" %in%
  names(bootstrap_distribution)
) {
  stop(
    "bootstrap_distribution.csv does not contain bootstrap_mean."
  )
}

if (total_bootstrap_repetitions < 100) {
  stop(
    "At least 100 bootstrap estimates are required."
  )
}


# ------------------------------------------------------------
# 7. Define the animation frames
#
# Each frame uses all bootstrap estimates accumulated up to
# the displayed number of resamples.
# ------------------------------------------------------------

number_of_frames <- 30

frame_steps <- unique(
  round(
    seq(
      from = 100,
      to = total_bootstrap_repetitions,
      length.out = number_of_frames
    )
  )
)

number_of_frames <- length(
  frame_steps
)


# ------------------------------------------------------------
# 8. Create cumulative data for each animation frame
# ------------------------------------------------------------

animation_data_list <- vector(
  mode = "list",
  length = number_of_frames
)

frame_summary_list <- vector(
  mode = "list",
  length = number_of_frames
)

for (frame_index in seq_along(frame_steps)) {
  
  current_number <- frame_steps[frame_index]
  
  current_estimates <- bootstrap_distribution$bootstrap_mean[
    seq_len(current_number)
  ]
  
  current_interval <- stats::quantile(
    x = current_estimates,
    probs = c(
      (1 - confidence_level) / 2,
      1 - (1 - confidence_level) / 2
    ),
    names = FALSE,
    type = 7
  )
  
  animation_data_list[[frame_index]] <- data.frame(
    bootstrap_mean = current_estimates,
    animation_frame = current_number
  )
  
  frame_summary_list[[frame_index]] <- data.frame(
    animation_frame = current_number,
    number_of_resamples = current_number,
    bootstrap_mean = mean(current_estimates),
    ci_lower = current_interval[1],
    ci_upper = current_interval[2]
  )
}

animation_data <- do.call(
  rbind,
  animation_data_list
)

animation_frame_summary <- do.call(
  rbind,
  frame_summary_list
)


# ------------------------------------------------------------
# 9. Set ordered animation-frame values
# ------------------------------------------------------------

animation_data$animation_frame <- factor(
  animation_data$animation_frame,
  levels = frame_steps,
  ordered = TRUE
)

animation_frame_summary$animation_frame <- factor(
  animation_frame_summary$animation_frame,
  levels = frame_steps,
  ordered = TRUE
)


# ------------------------------------------------------------
# 10. Save the animation-frame summaries
# ------------------------------------------------------------

utils::write.csv(
  animation_frame_summary,
  file = "data/generated/bootstrap_animation_frames.csv",
  row.names = FALSE
)


# ------------------------------------------------------------
# 11. Prepare dynamic confidence-interval lines
# ------------------------------------------------------------

animation_ci_lines <- rbind(
  data.frame(
    animation_frame =
      animation_frame_summary$animation_frame,
    value = animation_frame_summary$ci_lower,
    reference = "95% CI bounds"
  ),
  data.frame(
    animation_frame =
      animation_frame_summary$animation_frame,
    value = animation_frame_summary$ci_upper,
    reference = "95% CI bounds"
  )
)

animation_ci_lines$reference <- factor(
  animation_ci_lines$reference,
  levels = "95% CI bounds"
)


# ------------------------------------------------------------
# 12. Define fixed histogram boundaries
#
# Using the same bin width and x-axis limits in every frame
# prevents the graph from visually jumping between frames.
# ------------------------------------------------------------

bootstrap_minimum <- min(
  bootstrap_distribution$bootstrap_mean
)

bootstrap_maximum <- max(
  bootstrap_distribution$bootstrap_mean
)

bootstrap_range <- (
  bootstrap_maximum - bootstrap_minimum
)

x_axis_minimum <- min(
  bootstrap_minimum - 0.05 * bootstrap_range,
  true_population_mean - 0.05 * bootstrap_range
)

x_axis_maximum <- max(
  bootstrap_maximum + 0.05 * bootstrap_range,
  true_population_mean + 0.05 * bootstrap_range
)

histogram_bin_width <- bootstrap_range / 35

histogram_boundary <- floor(
  bootstrap_minimum / histogram_bin_width
) * histogram_bin_width


# ------------------------------------------------------------
# 13. Create the animated plot
# ------------------------------------------------------------

animated_bootstrap_plot <- ggplot(
  animation_data,
  aes(
    x = bootstrap_mean,
    group = animation_frame
  )
) +
  geom_histogram(
    aes(
      y = after_stat(density)
    ),
    binwidth = histogram_bin_width,
    boundary = histogram_boundary,
    fill = "#7DB7D8",
    color = "white",
    linewidth = 0.25,
    alpha = 0.90
  ) +
  geom_density(
    color = "#174A6E",
    fill = "#174A6E",
    linewidth = 1,
    alpha = 0.10,
    adjust = 1
  ) +
  geom_vline(
    xintercept = sample_mean,
    color = "#222222",
    linetype = "solid",
    linewidth = 1
  ) +
  geom_vline(
    xintercept = true_population_mean,
    color = "#009E73",
    linetype = "dotdash",
    linewidth = 1
  ) +
  geom_vline(
    data = animation_ci_lines,
    aes(
      xintercept = value,
      group = animation_frame
    ),
    inherit.aes = FALSE,
    color = "#D55E00",
    linetype = "dashed",
    linewidth = 1
  ) +
  annotate(
    geom = "label",
    x = sample_mean,
    y = Inf,
    label = paste0(
      "Observed mean = ",
      round(sample_mean, 2)
    ),
    hjust = 1.05,
    vjust = 1.35,
    size = 3.2,
    fontface = "bold",
    color = "#222222",
    fill = "white",
    linewidth = 0
  ) +
  coord_cartesian(
    xlim = c(
      x_axis_minimum,
      x_axis_maximum
    ),
    clip = "off"
  ) +
  labs(
    title = "{current_frame} bootstrap resamples",
    subtitle = paste0(
      "The bootstrap distribution stabilizes as ",
      "more resamples accumulate"
    ),
    x = "Bootstrap sample mean",
    y = "Density",
    caption = paste0(
      "Black: observed sample mean  |  ",
      "Green: true population mean  |  ",
      "Orange: evolving 95% bootstrap interval"
    )
  ) +
  theme_minimal(
    base_size = 13
  ) +
  theme(
    plot.title = element_text(
      face = "bold",
      size = 19,
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
      hjust = 0
    ),
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    axis.title = element_text(
      face = "bold"
    ),
    plot.margin = margin(
      t = 14,
      r = 16,
      b = 14,
      l = 14
    )
  ) +
  transition_manual(
    animation_frame
  )


# ------------------------------------------------------------
# 14. Render and save the GIF
# ------------------------------------------------------------

gif_output_path <- file.path(
  "results",
  "animation",
  "bootstrap_distribution_builds.gif"
)

message(
  "Rendering ",
  number_of_frames,
  " animation frames..."
)

bootstrap_animation <- gganimate::animate(
  plot = animated_bootstrap_plot,
  nframes = number_of_frames,
  fps = 4,
  width = 900,
  height = 600,
  res = 110,
  start_pause = 4,
  end_pause = 10,
  renderer = gganimate::gifski_renderer(
    file = gif_output_path,
    loop = TRUE
  )
)


# ------------------------------------------------------------
# 15. Verify the generated GIF
# ------------------------------------------------------------

expected_outputs <- c(
  "data/generated/bootstrap_animation_frames.csv",
  gif_output_path
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

gif_size_bytes <- file.info(
  gif_output_path
)$size

gif_size_megabytes <- (
  gif_size_bytes / 1024^2
)


# ------------------------------------------------------------
# 16. Print the verified result
# ------------------------------------------------------------

cat(
  "\n",
  "============================================================\n",
  "PART 4A COMPLETE: ANIMATED BOOTSTRAP DEMONSTRATION\n",
  "============================================================\n",
  "Total bootstrap resamples represented: ",
  format(total_bootstrap_repetitions, big.mark = ","), "\n",
  "Number of animation frames: ",
  number_of_frames, "\n",
  "Frame rate: 4 frames per second\n",
  "Observed sample mean: ",
  round(sample_mean, 3), "\n",
  "True population mean: ",
  round(true_population_mean, 3), "\n",
  "Final 95% bootstrap interval: [",
  round(
    tail(
      animation_frame_summary$ci_lower,
      1
    ),
    3
  ),
  ", ",
  round(
    tail(
      animation_frame_summary$ci_upper,
      1
    ),
    3
  ),
  "]\n",
  "GIF size: ",
  round(gif_size_megabytes, 2),
  " MB\n\n",
  "Saved outputs:\n",
  paste(expected_outputs, collapse = "\n"),
  "\n============================================================\n",
  sep = ""
)