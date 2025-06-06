#!/usr/bin/env bash

set -euo pipefail # safer script: exit on error, unset vars, and pipe failures

# === Configuration ===
CONDA_ENV="ifcbnn"
CONDA_SH="${HOME}/miniconda3/etc/profile.d/conda.sh"
CUDA_DEVICES="0"
MODEL="inception_v3"
DATASET="training-data/"
TRAIN_ID="inception_v3_smhi_tangesund_b32_flipxy"
BATCH_SIZE=32
# This is used to randomly flip images horizontally and vertically, this can
# help the model to generalize better
EXTRA_ARGS="--flip xy+V"
# FNAME="results.json"

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

python neuston_net.py --batch "$BATCH_SIZE" TRAIN "$DATASET" "$MODEL" "$TRAIN_ID" $EXTRA_ARGS

log "Training completed. Deactivating conda environment."
conda deactivate
