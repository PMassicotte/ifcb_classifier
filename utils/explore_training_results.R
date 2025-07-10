library(tidyverse)
library(R.matlab)

file <- fs::path("training-output", "inception_v3_2025_06_18", "results.mat")
res <- R.matlab::readMat(file)

str(res)


# Get the confusion matrix and add row/column names
conf_mat <- res$confusion.matrix
rownames(conf_mat) <- unlist(res$class.labels)
colnames(conf_mat) <- unlist(res$class.labels)

# Convert to long format using tidyverse
df_conf <- as.data.frame(conf_mat) |>
  rownames_to_column(var = "true") |>
  pivot_longer(
    cols = -true,
    names_to = "Predicted",
    values_to = "Count"
  )

ggplot(df_conf, aes(x = Predicted, y = true, fill = Count)) +
  geom_tile(color = "white") +
  scale_fill_gradient(low = "white", high = "steelblue") +
  theme_minimal() +
  labs(
    title = "Confusion Matrix",
    x = "Predicted Label",
    y = "True Label"
  ) +
  coord_fixed() +
  theme(
    axis.text.x = element_text(angle = 90L)
  )

f1_perclass <- as.numeric(res$f1.perclass)
class_labels <- unlist(res$class.labels)

f1_df <- tibble(Class = class_labels, F1 = f1_perclass)

ggplot(f1_df, aes(x = reorder(Class, -F1), y = F1)) +
  geom_bar(stat = "identity", fill = "forestgreen") +
  ylim(0L, 1L) +
  coord_flip() +
  labs(title = "Per-Class F1 Scores", x = "Class", y = "F1 Score") +
  theme_minimal()

# Accuracy
true_classes <- as.integer(res$input.classes)
pred_classes <- as.integer(res$output.classes)

accuracy <- mean(pred_classes == true_classes)
cat("Correct Accuracy:", accuracy, "\n")

n_classes <- nrow(conf_mat)

# Initialize vectors to store precision and recall
precision <- numeric(n_classes)
recall <- numeric(n_classes)

for (i in 1L:n_classes) {
  TP <- conf_mat[i, i] # True Positive: diagonal element
  FP <- sum(conf_mat[, i]) - TP # False Positive: sum of column minus TP
  FN <- sum(conf_mat[i, ]) - TP # False Negative: sum of row minus TP

  precision[i] <- ifelse((TP + FP) == 0L, NA, TP / (TP + FP))
  recall[i] <- ifelse((TP + FN) == 0L, NA, TP / (TP + FN))
}

# Not bad
precision
recall

tibble(class_labels, precision, recall) |>
  pivot_longer(-class_labels, names_to = "metric", values_to = "value") |>
  ggplot(aes(x = value, y = class_labels, fill = metric)) +
  geom_col(position = "dodge") +
  scale_x_continuous(labels = scales::label_percent())

ggsave(
  fs::path("graphs", "precision_recall.pdf"),
  device = cairo_pdf,
  width = 8L,
  heigh = 6L
)
