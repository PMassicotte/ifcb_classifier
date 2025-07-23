CREATE OR REPLACE TABLE img_results AS
SELECT
  *
FROM
  read_json_auto(
    'run-output/inception_v3_2025_07_21_img_norm_no_bad_foccus_02_Greenedge_Cruise_2016/v3/inception_v3_2025_07_21_img_norm_no_bad_foccus/img_results.json',
    maximum_object_size = 1000000000
  );


DESCRIBE img_results;


SELECT
  *
FROM
  img_results;


SELECT
  unnest(input_images) AS input_image,
  unnest(output_classes) AS output_class,
  unnest(output_scores) AS output_score,
FROM
  img_results;


-- Flatten the 2D scores array
SELECT
  version,
  model_id,
  timestamp,
  UNNEST(output_scores, recursive := TRUE) AS individual_score
FROM
  img_results;


COPY (
  WITH
    base_unnested AS (
      SELECT
        version,
        model_id,
        timestamp,
        class_labels,
        UNNEST(output_classes) AS output_class,
        UNNEST(input_images) AS input_image,
        UNNEST(output_scores) AS score_array,
        GENERATE_SUBSCRIPTS(output_scores, 1) AS image_idx
      FROM
        img_results
    ),
    final_unnested AS (
      SELECT
        version,
        model_id,
        timestamp,
        class_labels,
        output_class,
        input_image,
        image_idx,
        UNNEST(score_array) AS individual_score,
        GENERATE_SUBSCRIPTS(score_array, 1) AS class_idx
      FROM
        base_unnested
    )
  SELECT
    version,
    model_id,
    timestamp,
    class_labels[class_idx] AS class_label,
    output_class + 1 AS output_class, -- Adjusting for 1-based index in python
    input_image,
    individual_score
  FROM
    final_unnested
  ORDER BY
    image_idx,
    class_idx
) TO 'results/flattened_results_greenedge_2016.csv' (HEADER, DELIMITER ',');
