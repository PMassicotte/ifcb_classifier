# Filter out "rare" species and place the reminder into the training-data
# directory
library(tidyverse)
library(fs)
library(furrr)

plan(multicore(workers = availableCores() - 2L))
data_raw_path <- fs::path("data", "data_raw", "classified")


dirs <- list.dirs(path = data_raw_path, recursive = FALSE)

file_counts <- vapply(dirs, function(d) length(list.files(d)), integer(1L))
file_counts_df <- tibble(directory = dirs, file_count = file_counts)

training_dir <- fs::path("training-data")

fs::dir_ls(training_dir, recurse = TRUE) |>
  fs::file_delete()

file_counts_df |>
  filter(file_count >= 100L) |>
  pull(directory) |>
  future_walk(
    dir_copy,
    new_path = training_dir,
    overwrite = TRUE,
    .progress = TRUE
  )

fs::dir_ls(training_dir, recurse = TRUE, glob = "*.tsv") |>
  fs::file_delete()


fs::dir_ls(training_dir, recurse = TRUE) |>
  length()
