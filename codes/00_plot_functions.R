# ============================================================
# Reusable plotting functions
# ============================================================


plot_bootstrap_distribution <- function(
    bootstrap_data,
    sample_mean,
    true_mean,
    ci_lower,
    ci_upper,
    confidence_level,
    bootstrap_repetitions
) {
  reference_lines <- data.frame(
    value = c(
      ci_lower,
      ci_upper,
      sample_mean,
      true_mean
    ),
    reference = factor(
      c(
        "Confidence interval bounds",
        "Confidence interval bounds",
        "Observed sample mean",
        "True population mean"
      ),
      levels = c(
        "Observed sample mean",
        "True population mean",
        "Confidence interval bounds"
      )
    )
  )
  
  ggplot2::ggplot(
    bootstrap_data,
    ggplot2::aes(x = bootstrap_mean)
  ) +
    ggplot2::geom_histogram(
      ggplot2::aes(y = ggplot2::after_stat(density)),
      bins = 40,
      fill = "#7DB7D8",
      color = "white",
      linewidth = 0.25,
      alpha = 0.90
    ) +
    ggplot2::geom_density(
      color = "#174A6E",
      fill = "#174A6E",
      linewidth = 1,
      alpha = 0.12
    ) +
    ggplot2::geom_vline(
      data = reference_lines,
      ggplot2::aes(
        xintercept = value,
        color = reference,
        linetype = reference
      ),
      linewidth = 1
    ) +
    ggplot2::scale_color_manual(
      name = NULL,
      values = c(
        "Observed sample mean" = "#222222",
        "True population mean" = "#009E73",
        "Confidence interval bounds" = "#D55E00"
      )
    ) +
    ggplot2::scale_linetype_manual(
      name = NULL,
      values = c(
        "Observed sample mean" = "solid",
        "True population mean" = "dotdash",
        "Confidence interval bounds" = "dashed"
      )
    ) +
    ggplot2::labs(
      title = "Constructing a Bootstrap Confidence Interval",
      subtitle = paste0(
        format(
          bootstrap_repetitions,
          big.mark = ","
        ),
        " resamples from one observed sample"
      ),
      x = "Bootstrap sample mean",
      y = "Density",
      caption = paste0(
        round(confidence_level * 100),
        "% percentile bootstrap interval: [",
        format(round(ci_lower, 3), nsmall = 3),
        ", ",
        format(round(ci_upper, 3), nsmall = 3),
        "]"
      )
    ) +
    ggplot2::theme_minimal(
      base_size = 13
    ) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(
        face = "bold",
        size = 17,
        color = "#17324D"
      ),
      plot.subtitle = ggplot2::element_text(
        size = 12,
        color = "#4D5D6C"
      ),
      plot.caption = ggplot2::element_text(
        size = 10,
        color = "#4D5D6C",
        hjust = 0
      ),
      legend.position = "bottom",
      legend.box = "vertical",
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major.x = ggplot2::element_blank(),
      axis.title = ggplot2::element_text(
        face = "bold"
      )
    ) +
    ggplot2::guides(
      color = ggplot2::guide_legend(
        override.aes = list(linewidth = 1.2)
      )
    )
}