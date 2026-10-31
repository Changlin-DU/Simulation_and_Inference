# ============================================================
# Reusable simulation functions
# ============================================================


# Generate a sample from a right-skewed lognormal population.
#
# The meanlog parameter is chosen so that the population mean
# is exactly equal to true_mean.
generate_population_sample <- function(
    n,
    true_mean,
    log_sd = 0.60
) {
  if (n < 2) {
    stop("n must be at least 2.")
  }
  
  if (true_mean <= 0) {
    stop("true_mean must be positive.")
  }
  
  if (log_sd <= 0) {
    stop("log_sd must be positive.")
  }
  
  population_meanlog <- log(true_mean) - 0.5 * log_sd^2
  
  stats::rlnorm(
    n = n,
    meanlog = population_meanlog,
    sdlog = log_sd
  )
}


# Generate a bootstrap distribution of sample means.
bootstrap_sample_means <- function(
    sample_values,
    bootstrap_repetitions
) {
  if (!is.numeric(sample_values)) {
    stop("sample_values must be numeric.")
  }
  
  if (length(sample_values) < 2) {
    stop("sample_values must contain at least two observations.")
  }
  
  if (bootstrap_repetitions < 100) {
    stop("bootstrap_repetitions must be at least 100.")
  }
  
  sample_size <- length(sample_values)
  
  replicate(
    n = bootstrap_repetitions,
    expr = mean(
      sample(
        x = sample_values,
        size = sample_size,
        replace = TRUE
      )
    )
  )
}


# Calculate a percentile bootstrap confidence interval.
calculate_percentile_interval <- function(
    bootstrap_estimates,
    confidence_level = 0.95
) {
  if (!is.numeric(bootstrap_estimates)) {
    stop("bootstrap_estimates must be numeric.")
  }
  
  if (
    confidence_level <= 0 ||
    confidence_level >= 1
  ) {
    stop("confidence_level must be between 0 and 1.")
  }
  
  alpha <- 1 - confidence_level
  
  interval <- stats::quantile(
    x = bootstrap_estimates,
    probs = c(alpha / 2, 1 - alpha / 2),
    names = FALSE,
    type = 7
  )
  
  names(interval) <- c("lower", "upper")
  
  interval
}