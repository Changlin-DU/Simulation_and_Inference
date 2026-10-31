# ============================================================
# Master replication script
#
# Running this file from the project root reproduces:
# 1. Bootstrap confidence-interval results
# 2. Confidence-interval coverage results
# 3. Hypothesis-testing results
# 4. Animated GIF
# 5. Standalone interactive HTML
# 6. Output manifest and R session information
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
  !dir.exists(".git") ||
  !dir.exists("codes") ||
  !dir.exists("data") ||
  !dir.exists("results")
) {
  stop(
    paste0(
      "The project root was not detected correctly.\n",
      "Current working directory:\n",
      project_root,
      "\n\nOpen the Git-connected RStudio project and run Source again."
    )
  )
}

message("Project root confirmed: ", project_root)


# ------------------------------------------------------------
# 2. Confirm all required source files
# ------------------------------------------------------------

pipeline_scripts <- c(
  "codes/01_bootstrap_ci.R",
  "codes/02_coverage_simulation.R",
  "codes/03_hypothesis_testing.R",
  "codes/04_create_animation.R",
  "codes/05_create_interactive.R"
)

supporting_files <- c(
  "codes/00_simulation_functions.R",
  "codes/00_plot_functions.R"
)

required_code_files <- c(
  supporting_files,
  pipeline_scripts
)

missing_code_files <- required_code_files[
  !file.exists(required_code_files)
]

if (length(missing_code_files) > 0) {
  stop(
    paste0(
      "The following required code files are missing:\n",
      paste(missing_code_files, collapse = "\n")
    )
  )
}


# ------------------------------------------------------------
# 3. Confirm output directories
# ------------------------------------------------------------

required_directories <- c(
  "data/generated",
  "results/figures",
  "results/tables",
  "results/animation",
  "results/interactive"
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
# 4. Start the replication timer
# ------------------------------------------------------------

pipeline_start_time <- Sys.time()

cat(
  "\n",
  "============================================================\n",
  "STARTING COMPLETE PROJECT REPLICATION\n",
  "============================================================\n",
  "Project root: ",
  project_root,
  "\n",
  "Start time: ",
  format(
    pipeline_start_time,
    "%Y-%m-%d %H:%M:%S"
  ),
  "\n",
  "Number of analysis scripts: ",
  length(pipeline_scripts),
  "\n",
  "============================================================\n",
  sep = ""
)


# ------------------------------------------------------------
# 5. Run each analysis script in order
# ------------------------------------------------------------

pipeline_log <- data.frame(
  order = seq_along(pipeline_scripts),
  script = pipeline_scripts,
  status = rep(
    "Not started",
    length(pipeline_scripts)
  ),
  start_time = rep(
    NA_character_,
    length(pipeline_scripts)
  ),
  end_time = rep(
    NA_character_,
    length(pipeline_scripts)
  ),
  elapsed_seconds = rep(
    NA_real_,
    length(pipeline_scripts)
  ),
  stringsAsFactors = FALSE
)

for (script_index in seq_along(pipeline_scripts)) {
  
  current_script <- pipeline_scripts[script_index]
  script_start_time <- Sys.time()
  
  pipeline_log$start_time[script_index] <- format(
    script_start_time,
    "%Y-%m-%d %H:%M:%S"
  )
  
  cat(
    "\n",
    "------------------------------------------------------------\n",
    "RUNNING ",
    script_index,
    " OF ",
    length(pipeline_scripts),
    ": ",
    current_script,
    "\n",
    "------------------------------------------------------------\n",
    sep = ""
  )
  
  script_result <- tryCatch(
    {
      source(
        file = current_script,
        echo = FALSE,
        chdir = FALSE
      )
      
      list(
        success = TRUE,
        error_message = NULL
      )
    },
    error = function(error_condition) {
      list(
        success = FALSE,
        error_message = conditionMessage(
          error_condition
        )
      )
    }
  )
  
  script_end_time <- Sys.time()
  
  script_elapsed_seconds <- as.numeric(
    difftime(
      script_end_time,
      script_start_time,
      units = "secs"
    )
  )
  
  pipeline_log$end_time[script_index] <- format(
    script_end_time,
    "%Y-%m-%d %H:%M:%S"
  )
  
  pipeline_log$elapsed_seconds[script_index] <- round(
    script_elapsed_seconds,
    2
  )
  
  if (script_result$success) {
    pipeline_log$status[script_index] <- "Complete"
    
    cat(
      "\nCompleted: ",
      current_script,
      "\nElapsed time: ",
      round(script_elapsed_seconds, 2),
      " seconds\n",
      sep = ""
    )
  } else {
    pipeline_log$status[script_index] <- "Failed"
    
    utils::write.csv(
      pipeline_log,
      file = "results/tables/replication_log.csv",
      row.names = FALSE
    )
    
    stop(
      paste0(
        "\nReplication stopped in:\n",
        current_script,
        "\n\nError:\n",
        script_result$error_message,
        "\n\nEarlier completed outputs were preserved."
      )
    )
  }
}


# ------------------------------------------------------------
# 6. Save the replication log
# ------------------------------------------------------------

utils::write.csv(
  pipeline_log,
  file = "results/tables/replication_log.csv",
  row.names = FALSE
)


# ------------------------------------------------------------
# 7. Define every required final output
# ------------------------------------------------------------

required_outputs <- c(
  # Part 1 data
  "data/generated/observed_sample.csv",
  "data/generated/bootstrap_distribution.csv",
  
  # Part 2 data
  "data/generated/coverage_simulation.csv",
  
  # Part 3 data
  "data/generated/hypothesis_observed_sample.csv",
  "data/generated/null_distribution.csv",
  
  # Part 4 data
  "data/generated/bootstrap_animation_frames.csv",
  "data/generated/interactive_default_settings.csv",
  
  # Numerical summaries
  "results/tables/bootstrap_summary.csv",
  "results/tables/coverage_summary.csv",
  "results/tables/hypothesis_test_summary.csv",
  "results/tables/replication_log.csv",
  
  # Static figures
  "results/figures/bootstrap_distribution.png",
  "results/figures/confidence_interval_coverage.png",
  "results/figures/null_distribution_hypothesis_test.png",
  
  # Animation
  "results/animation/bootstrap_distribution_builds.gif",
  
  # Interactive demonstration
  "results/interactive/bootstrap_explorer.html"
)


# ------------------------------------------------------------
# 8. Verify every required final output
# ------------------------------------------------------------

missing_outputs <- required_outputs[
  !file.exists(required_outputs)
]

if (length(missing_outputs) > 0) {
  stop(
    paste0(
      "Replication finished, but these required outputs are missing:\n",
      paste(missing_outputs, collapse = "\n")
    )
  )
}


# ------------------------------------------------------------
# 9. Save R session information
# ------------------------------------------------------------

session_information <- capture.output(
  sessionInfo()
)

writeLines(
  text = c(
    "Simulation and Inference",
    "R Session Information",
    "========================================",
    "",
    paste0(
      "Generated: ",
      format(
        Sys.time(),
        "%Y-%m-%d %H:%M:%S %Z"
      )
    ),
    paste0(
      "Project root: ",
      project_root
    ),
    "",
    session_information
  ),
  con = "results/tables/session_info.txt",
  useBytes = TRUE
)


# ------------------------------------------------------------
# 10. Create a complete output manifest
# ------------------------------------------------------------

manifest_files <- c(
  required_outputs,
  "results/tables/session_info.txt"
)

manifest_information <- file.info(
  manifest_files
)

output_manifest <- data.frame(
  file = manifest_files,
  category = ifelse(
    grepl("^data/", manifest_files),
    "Generated data",
    ifelse(
      grepl("^results/figures/", manifest_files),
      "Static figure",
      ifelse(
        grepl("^results/tables/", manifest_files),
        "Table or documentation",
        ifelse(
          grepl("^results/animation/", manifest_files),
          "Animation",
          "Interactive output"
        )
      )
    )
  ),
  size_bytes = manifest_information$size,
  size_kilobytes = round(
    manifest_information$size / 1024,
    2
  ),
  modified_time = format(
    manifest_information$mtime,
    "%Y-%m-%d %H:%M:%S"
  ),
  stringsAsFactors = FALSE
)

utils::write.csv(
  output_manifest,
  file = "results/tables/output_manifest.csv",
  row.names = FALSE
)


# ------------------------------------------------------------
# 11. Perform final statistical checks
# ------------------------------------------------------------

bootstrap_summary <- utils::read.csv(
  "results/tables/bootstrap_summary.csv"
)

coverage_summary <- utils::read.csv(
  "results/tables/coverage_summary.csv"
)

hypothesis_summary <- utils::read.csv(
  "results/tables/hypothesis_test_summary.csv"
)

bootstrap_check <- isTRUE(
  bootstrap_summary$interval_contains_true_mean[1]
)

coverage_rate <- coverage_summary$empirical_coverage_rate[1]

coverage_check <- (
  coverage_rate >= 0.90 &&
    coverage_rate <= 0.99
)

p_value <- hypothesis_summary$simulated_p_value[1]

hypothesis_check <- (
  p_value < 0.05 &&
    hypothesis_summary$decision[1] == "Reject H0"
)

if (!bootstrap_check) {
  stop(
    "Final check failed: the introductory bootstrap interval does not contain the true mean."
  )
}

if (!coverage_check) {
  stop(
    paste0(
      "Final check failed: empirical coverage was ",
      round(coverage_rate * 100, 1),
      "%."
    )
  )
}

if (!hypothesis_check) {
  stop(
    "Final check failed: the hypothesis-test result is inconsistent."
  )
}


# ------------------------------------------------------------
# 12. Finish the replication timer
# ------------------------------------------------------------

pipeline_end_time <- Sys.time()

total_elapsed_seconds <- as.numeric(
  difftime(
    pipeline_end_time,
    pipeline_start_time,
    units = "secs"
  )
)


# ------------------------------------------------------------
# 13. Print the final verified result
# ------------------------------------------------------------

cat(
  "\n",
  "============================================================\n",
  "COMPLETE PROJECT REPLICATION SUCCESSFUL\n",
  "============================================================\n",
  "End time: ",
  format(
    pipeline_end_time,
    "%Y-%m-%d %H:%M:%S"
  ),
  "\n",
  "Total elapsed time: ",
  round(total_elapsed_seconds, 2),
  " seconds\n\n",
  "Statistical verification:\n",
  "- Introductory bootstrap CI contains true mean: ",
  bootstrap_check,
  "\n",
  "- Empirical 95% CI coverage: ",
  round(coverage_rate * 100, 1),
  "%\n",
  "- Simulated hypothesis-test p-value: ",
  format(
    round(p_value, 4),
    nsmall = 4
  ),
  "\n",
  "- Hypothesis-test decision: ",
  hypothesis_summary$decision[1],
  "\n\n",
  "Verified outputs: ",
  length(required_outputs),
  "\n",
  "Output manifest:\n",
  "results/tables/output_manifest.csv\n",
  "Replication log:\n",
  "results/tables/replication_log.csv\n",
  "Session information:\n",
  "results/tables/session_info.txt\n\n",
  "All code, generated data, and results are reproducible.\n",
  "============================================================\n",
  sep = ""
)