#!/usr/bin/env bash

# ./run_cnn_model.sh -i run-data/sosik_2006/ -m inception_v3_full_model_b32_flipxy -t img

set -euo pipefail # safer script: exit on error, unset vars, and pipe failures

# === Configuration ===
CONDA_ENV="ifcbnn"
CONDA_SH="${HOME}/miniconda3/etc/profile.d/conda.sh"
CUDA_DEVICES="0"
TRAINING_OUTPUT_DIR="training-output"

# Default values
MODEL_NAME=""
TYPE_ARG=""

# === Functions ===

log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" >&2
}

usage() {
  echo "Usage: $0 -i INPUT_DATA_DIR -m MODEL_NAME [-t TYPE]" >&2
  echo "" >&2
  echo "Options:" >&2
  echo "  -i INPUT_DATA_DIR  Directory containing input data (required)" >&2
  echo "  -m MODEL_NAME      Model name (required, e.g. 'inception_v3_full_model_b32_flipxy')" >&2
  echo "  -t TYPE            Input type (e.g., 'img' for image input)" >&2
  echo "  -h                 Show this help message" >&2
  exit 1
}

# === Parse arguments ===

while getopts "i:m:t:h" opt; do
  case $opt in
  i) INPUT_DATA_DIR="$OPTARG" ;;
  m) MODEL_NAME="$OPTARG" ;;
  t) TYPE_ARG="--type $OPTARG" ;;
  h) usage ;;
  *) usage ;;
  esac
done

# Check if required parameters are provided
if [ -z "${INPUT_DATA_DIR:-}" ]; then
  echo "ERROR: Input data directory (-i) is required" >&2
  usage
fi

if [ -z "${MODEL_NAME:-}" ]; then
  echo "ERROR: Model name (-m) is required" >&2
  usage
fi

# Construct full model path
MODEL_PATH="${TRAINING_OUTPUT_DIR}/${MODEL_NAME}/${MODEL_NAME}.ptl"

# Verify the model exists
if [ ! -f "$MODEL_PATH" ]; then
  echo "ERROR: Model file not found at: $MODEL_PATH" >&2
  exit 1
fi

# Extract dataset name from input directory for use in RUN_ID
DATASET_NAME=$(basename "$INPUT_DATA_DIR" | sed 's/\/$//')
if [ -z "$DATASET_NAME" ]; then
  DATASET_NAME=$(basename "$(dirname "$INPUT_DATA_DIR")")
fi

# Create a unique RUN_ID automatically based on model name and dataset
RUN_ID="${MODEL_NAME}_${DATASET_NAME}"

# === Main ===

log "Running inference with the following configuration:"
log "  Input data: $INPUT_DATA_DIR"
log "  Model path: $MODEL_PATH"
log "  Run ID: $RUN_ID"
log "  Type argument: $TYPE_ARG"

log "Activating conda environment: $CONDA_ENV"
if [ -f "$CONDA_SH" ]; then
  source "$CONDA_SH"
else
  echo "ERROR: Cannot find conda.sh at $CONDA_SH" >&2
  exit 1
fi

conda activate "$CONDA_ENV"

export CUDA_VISIBLE_DEVICES="$CUDA_DEVICES"
log "CUDA devices set to: $CUDA_VISIBLE_DEVICES"

python neuston_net.py RUN "$INPUT_DATA_DIR" "$MODEL_PATH" "$RUN_ID" $TYPE_ARG

log "Model inference completed. Deactivating conda environment."
conda deactivate

