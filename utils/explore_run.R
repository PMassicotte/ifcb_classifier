library(tidyverse)
library(rhdf5)
library(fs)
library(furrr)

plan(multisession(workers = availableCores() - 2L))

id_from_bin_file <- function(file, roi_number) {
  paste0(
    str_match(file, "(D\\w+_\\w+)_class\\.h5$")[, 2L], #nolint
    "_",
    str_pad(roi_number, pad = "0", side = "left", width = 5L)
  )
}

extract_h5_classification <- function(h5_file_path) {
  if (!file_exists(h5_file_path)) {
    cli::cli_abort("File does not exist: ", h5_file_path)
  }

  # h5ls(h5_file_path)

  class_labels <- h5read(h5_file_path, "class_labels")

  # WARN: Is it 0 based index?
  output_classes <- h5read(h5_file_path, "output_classes") + 1L
  predicted_classes <- class_labels[output_classes]

  output_scores <- h5read(h5_file_path, "output_scores")
  max_scores <- apply(output_scores, 2L, max)

  # TODO: Add + 1? After exploring on the dashboard, it seems ok like this
  roi_number <- h5read(h5_file_path, "roi_numbers")

  n_classes <- nrow(output_scores)
  n_images <- length(output_classes)

  tibble::tibble(
    id = rep(id_from_bin_file(h5_file_path, roi_number), each = n_classes),
    bin_file = rep(h5_file_path, n_images * n_classes),
    image = rep(seq_along(output_classes), each = n_classes),
    roi_number = rep(as.vector(roi_number), each = n_classes),
    class_index = rep(1L:n_classes, n_images),
    class_label = rep(class_labels, n_images),
    score = as.vector(output_scores)
  )
}

process_and_save_h5 <- function(h5_file_path) {
  results <- extract_h5_classification(h5_file_path)

  csv_filename <- fs::path(
    results_dir,
    str_replace(path_file(h5_file_path), "\\.h5$", ".csv")
  )

  write_csv(results, csv_filename)
}

run_name <- "inception_v3_2025_07_09_with_img_norm_tara_ifcb_leg_01_lorient_tromso"

# Create results directory
results_dir <- fs::path("results", run_name)
dir_create(results_dir)

files <- dir_ls(
  fs::path("run-output", run_name),
  recurse = TRUE,
  glob = "*.h5"
)

# Process all files
future_walk(files, process_and_save_h5, .progress = TRUE)
