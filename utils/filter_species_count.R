# Filter out "rare" species and place the reminder into the training-data
# directory
library(tidyverse)
library(fs)
library(furrr)

plan(multicore(workers = availableCores() - 2L))
data_raw_path <- fs::path("data", "clean", "classified")

dirs <- list.dirs(path = data_raw_path, recursive = FALSE)

file_counts <- vapply(dirs, function(d) length(list.files(d)), integer(1L))
file_counts_df <- tibble(directory = dirs, file_count = file_counts)

training_dir <- fs::path("training-data")

if (dir_exists(training_dir)) {
  fs::dir_ls(training_dir, recurse = TRUE) |>
    fs::file_delete()
}

file_structure <- file_counts_df |>
  filter(file_count >= 100L) |>
  mutate(
    rel_path = fs::path_file(directory),
    target_dir = tolower(fs::path(training_dir, rel_path))
  )

dir_copy(file_structure[["directory"]], file_structure[["target_dir"]])

fs::dir_ls(training_dir, recurse = TRUE, glob = "*.tsv") |>
  fs::file_delete()

fs::dir_ls(training_dir, recurse = TRUE) |>
  length()
