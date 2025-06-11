library(tidyverse)
library(rhdf5)
library(fs)

id_from_bin_file <- function(file) {
  paste0(
    str_match(file, "(D\\w+_\\w+)_class\\.h5$")[, 2L],
    "_",
    str_pad(roi_number, pad = "0", side = "left", width = 5L)
  )
}

extract_h5_classification <- function(h5_file_path) {
  if (!file_exists(h5_file_path)) {
    cli::cli_abort("File does not exist: ", h5_file_path)
  }

  h5ls(h5_file_path)

  class_labels <- h5read(h5_file_path, "class_labels")

  # WARN: Is it 0 based index?
  output_classes <- h5read(h5_file_path, "output_classes") + 1L
  predicted_classes <- class_labels[output_classes]

  output_scores <- h5read(h5_file_path, "output_scores")
  max_scores <- apply(output_scores, 2L, max)

  # TODO: Add + 1? After exploring on the dashboard, it seems ok like this
  roi_number <- h5read(h5_file_path, "roi_numbers")

  tibble::tibble(
    id = id_from_bin_file(h5_file_path),
    bin_file = h5_file_path,
    image = seq_along(output_classes),
    roi_number = as.vector(roi_number),
    class_index = as.vector(output_classes),
    class_label = as.vector(class_labels[output_classes]),
    score = max_scores
  )
}

# Example usage
file_path <- fs::path(
  "run-output",
  "inception_v3_smhi_tangesund_b32_flipxy",
  "v3",
  "inception_v3_smhi_tangesund_b32_flipxy",
  "D2022",
  "D20220819",
  "D20220819T055747_IFCB145_class.h5"
)

results <- extract_h5_classification(file_path)

results |>
  count(class_label, sort = TRUE)

url <- paste0(
  "https://",
  "habon-ifcb.whoi.edu/",
  "arctic/",
  "D20220819T055747_IFCB145_class_scores.csv"
)

res <- read_csv(url) |>
  pivot_longer(-pid, names_to = "species", values_to = "score") |>
  filter(score == max(score), .by = pid) |>
  rename_with(.fn = ~ paste0(.x, "_autoclass"), everything()) |>
  full_join(results, by = join_by("pid_autoclass" == "id")) |>
  select(-bin_file)

res |>
  count(class_label)

res |>
  write_csv("~/Desktop/classification_scores.csv")
