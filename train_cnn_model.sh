#!/usr/bin/env bash

set -euo pipefail # safer script: exit on error, unset vars, and pipe failures

# === Usage ===
show_usage() {
  echo "Usage: $0 [OPTIONS]"
  echo "Options:"
  echo "  -t, --train-id ID    Training ID (required)"
  echo "  -h, --help           Show this help message"
  exit 1
}

# === Configuration ===
CONDA_ENV="ifcbnn"
CONDA_SH="${HOME}/miniconda3/etc/profile.d/conda.sh"
CUDA_DEVICES="0"
MODEL="inception_v3"
DATASET="training-data/"
TRAIN_ID="" # Will be set by command line argument
BATCH_SIZE=32
# This is used to randomly flip images horizontally and vertically, this can
# help the model to generalize better
EXTRA_ARGS="--flip xy+V"
IMG_NORM="--img-norm 0.6231432 0.20911531"

# === Parse command line arguments ===
while [[ $# -gt 0 ]]; do
  case $1 in
  -t | --train-id)
    TRAIN_ID="$2"
    shift 2
    ;;
  -h | --help)
    show_usage
    ;;
  *)
    echo "Unknown option: $1"
    show_usage
    ;;
  esac
done

# Check if TRAIN_ID is provided
if [ -z "$TRAIN_ID" ]; then
  echo "ERROR: Training ID is required. Use -t or --train-id to specify it." >&2
  show_usage
fi

# === Functions ===

log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" >&2
}

# === Main ===

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

log "Starting training with model: $MODEL, dataset: $DATASET, ID: $TRAIN_ID, with $(find "$DATASET" -type f | wc -l)" images

python neuston_net.py --batch "$BATCH_SIZE" TRAIN "$DATASET" "$MODEL" "$TRAIN_ID" $EXTRA_ARGS $IMG_NORM

log "Training completed. Deactivating conda environment."
conda deactivate
