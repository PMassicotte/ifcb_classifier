#!/usr/bin/env bash

set -euo pipefail # safer script: exit on error, unset vars, and pipe failures

# === Configuration ===
CONDA_ENV="ifcbnn"
CONDA_SH="${HOME}/miniconda3/etc/profile.d/conda.sh"
CUDA_DEVICES="0"
MODEL="inception_v3"
# INPUT_DATA_DIR="data/data_roi/data"
INPUT_DATA_DIR="run-data/"
MODEL_PATH="training-output/inception_v3_smhi_tangesund_b32_flipxy/inception_v3_smhi_tangesund_b32_flipxy.ptl"
RUN_ID="inception_v3_icecamp_ge2015"

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

python neuston_net.py RUN "$INPUT_DATA_DIR" "$MODEL_PATH" "$RUN_ID" --type img

log "Model inference completed. Deactivating conda environment."
conda deactivate
