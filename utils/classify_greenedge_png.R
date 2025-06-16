library(tidyverse)
library(fs)

classified_img_list_tsv <- read_tsv(
  fs::path("data", "raw", "greenedge", "ecotaxa_export__GreenEdge2016IC.tsv")
) |>
  select(object_id, object_annotation_category) |>
  mutate(object_annotation_category = tolower(object_annotation_category)) |>
  mutate(
    object_annotation_category = str_replace_all(
      object_annotation_category,
      "[><  -]",
      "_"
    )
  ) |>
  mutate(
    object_annotation_category = str_replace_all(
      object_annotation_category,
      "chaetoceros_mediophyceae",
      "chaetoceros_spp"
    )
  )

species_to_keep <- classified_img_list_tsv |>
  count(object_annotation_category, sort = TRUE) |>
  filter(!str_detect(object_annotation_category, fixed("other"))) |>
  pull(object_annotation_category)

classified_img_list_tsv <- classified_img_list_tsv |>
  filter(object_annotation_category %in% species_to_keep)

# Classify images in their species folder. Images were classified on ecotaxa.
img <- dir_ls(
  fs::path("data", "raw", "greenedge", "IFCB"),
  glob = "*.png",
  recurse = TRUE
)

length(img)

# From the image list, extract the object_id
img_df <- img |>
  enframe(name = NULL, value = "src_path") |>
  mutate(
    object_id = str_extract(
      src_path,
      "D[0-9]{8}T[0-9]{6}_IFCB[0-9]{3}_\\d{5}"
    )
  )

img_df

# png images without entries in the tsv file
img_df |>
  anti_join(classified_img_list_tsv, by = join_by(object_id))

# listed images without entries in the png folder
classified_img_list_tsv |>
  anti_join(img_df, by = join_by(object_id))

#TODO: Group walk to copy each image in their "species" folder

destdir <- fs::path("data", "clean", "classified")

classified_img_list_tsv_merged <- classified_img_list_tsv |>
  inner_join(img_df, by = join_by(object_id))

classified_img_list_tsv_merged |>
  count(object_annotation_category, sort = TRUE) |>
  print(n = 100L)

classified_img_list_tsv |>
  inner_join(img_df, by = join_by(object_id)) |>
  group_by(object_annotation_category) |>
  group_walk(
    ~ {
      # Create destination directory if it doesn't exist
      dest_dir <- path(destdir, .y$object_annotation_category)
      if (!dir_exists(dest_dir)) {
        dir_create(dest_dir)
      }
      # Copy files
      file_copy(.x$src_path, dest_dir, overwrite = TRUE)
    }
  )
