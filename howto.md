# IFCB Neural Network Classifier Guide

<!--toc:start-->

- [IFCB Neural Network Classifier Guide](#ifcb-neural-network-classifier-guide)
  - [Setup and Installation](#setup-and-installation)
    - [1. Environment Setup](#1-environment-setup)
    - [2. Install pyifcb Dependency](#2-install-pyifcb-dependency)
  - [Using the Classifier](#using-the-classifier)
    - [1. Download Training data](#1-download-training-data)
    - [2. Training a Model](#2-training-a-model)
      - [Training Notes](#training-notes)
  - [Running Inference (making predictions)](#running-inference-making-predictions)
    - [Download Test Data](#download-test-data)
    - [Single Image](#single-image)
    - [Directory of Images](#directory-of-images)
    - [Raw IFCB Data](#raw-ifcb-data)
  - [Advanced Usage](#advanced-usage)
    - [GPU Acceleration](#gpu-acceleration)
    - [Hyperparameter Tuning](#hyperparameter-tuning)
  - [Troubleshooting](#troubleshooting)
    - [Memory Issues](#memory-issues)
    - [CUDA Errors](#cuda-errors)
  - [Future Improvements](#future-improvements)
  <!--toc:end-->

This guide explains how to set up and use the IFCB Neural Network classifier for plankton image classification.

## Setup and Installation

### 1. Environment Setup

Initialize conda with your shell (if not already done):

```bash
conda init bash # or conda init zsh if using zsh
```

Create and activate the conda environment:

```bash
# Option 1: Using environment YAML (recommended)
conda env create -f requirements/env.dev.yml
conda activate ifcbnn

# Option 2: Using package list
conda create --name ifcbnn --file requirements/pkgs.dev.txt
conda activate ifcbnn
```

### 2. Install pyifcb Dependency

```bash
# Method 1: Clone and install in development mode
git clone https://github.com/joefutrelle/pyifcb
cd pyifcb
pip install -e .
cd ..

# Method 2: Direct install (if version mismatch issues occur)
pip install --no-deps git+https://github.com/joefutrelle/pyifcb.git
```

## Using the Classifier

### 1. Download Training data

The data used here to train the model was downloaded from [figshare](https://figshare.scilifelab.se/articles/dataset/Manually_annotated_IFCB_plankton_images_from_the_Skagerrak_Kattegat_and_Baltic_Proper_by_SMHI/25883455?file=50176155) and are from the SMHI Tangesund project (`smhi_ifcb_tangesund_annotated_images.zip`).

Once unzipped, the data should be organized in a directory structure like this:

The data in `data/classified/` should be organized as follows, i.e. each subdirectory contains images of a specific class:

```bash
data/classified
├── Alexandrium_pseudogonyaulax
├── Asterionellopsis_glacialis
├── Blixaea_quinquecornis
├── Cerataulina_pelagica
├── Chaetoceros_spp
├── Ciliophora
├── Cryptomonadales
├── Dictyocha_fibula
├── Dictyochales
```

### 2. Training a Model

Set up environment variables and parameters:

```bash
# Set CUDA device (if needed, ie on a computer without a CUDA-capable GPU)
export CUDA_VISIBLE_DEVICES=0

# Define training parameters
MODEL=inception_v3       # Model architecture to use
DATASET=data/classified/ # Path to classified data
TRAIN_ID=MyTrainingRun   # Unique ID for this training run
```

Run the training:

```bash
# Basic training command
python neuston_net.py TRAIN "$DATASET" "$MODEL" "$TRAIN_ID" --flip xy

# With customized batch size (for lower memory systems)
python neuston_net.py --batch 8 TRAIN "$DATASET" "$MODEL" "$TRAIN_ID" --flip xy

# Quick test run with single epoch
python neuston_net.py --batch 8 TRAIN "$DATASET" "$MODEL" "$TRAIN_ID" --flip xy --emax 1
```

#### Training Notes

- The script automatically splits data into training (80%) and validation (20%) sets
- Training/validation file lists are saved as `training_images.list` and `validation_images.list`
- Results are saved to `training-output/$TRAIN_ID/`
- The model file will be saved as `training-output/$TRAIN_ID/$TRAIN_ID.ptl`
- Use `--results` to customize validation results output (default: `results.mat`)

## Running Inference (making predictions)

### Download Test Data

You can download a small subset of test data using the provided R script:

```bash
Rscript download_ifcb_test_data.R
```

This will download test data to `data/data_roi/`.

Define run parameters:

```bash
# Unique ID for this inference run
RUN_ID=MyInferenceRun

# Path to trained model
MODEL_PATH=training-output/MyTrainingRun/MyTrainingRun.ptl
```

Run inference on:

### Single Image

```bash
python neuston_net.py RUN \
  data/data_roi/png/Alexandrium_pseudogonyaulax_050/D20220712T210855_IFCB134_00042.png \
  "$MODEL_PATH" "$RUN_ID" --type img
```

### Directory of Images

Here, we assume the directory contains images in PNG format:

```bash
data/data_roi/png
├── Alexandrium_pseudogonyaulax_050
├── Amphidnium-like_051
├── Chaetoceros_spp_chain_018
├── Chaetoceros_spp_single_cell_019
├── Ciliophora_092
├── Cryptomonadales_011
├── Cylindrotheca_Nitzschia_longissima_020
├── Dactyliosolen_fragilissimus_021
├── Dinobryon_spp_002
```

```bash
python neuston_net.py RUN \
  data/data_roi/png/ \
  "$MODEL_PATH" "$RUN_ID" --type img
```

### Raw IFCB Data

`data/data_roi` should contain raw IFCB data files, organized as follows:

```
data/data_roi/data
├── 2022
│   ├── D20220522
│   │   ├── D20220522T000439_IFCB134.adc
│   │   ├── D20220522T000439_IFCB134.hdr
│   │   ├── D20220522T000439_IFCB134.roi
│   │   ├── D20220522T003051_IFCB134.adc
│   │   ├── D20220522T003051_IFCB134.hdr
│   │   └── D20220522T003051_IFCB134.roi
│   └── D20220712
│       ├── D20220712T210855_IFCB134.adc
│       ├── D20220712T210855_IFCB134.hdr
│       ├── D20220712T210855_IFCB134.roi
│       ├── D20220712T222710_IFCB134.adc
│       ├── D20220712T222710_IFCB134.hdr
│       └── D20220712T222710_IFCB134.roi
└── 2023
    ├── D20230314
    │   ├── D20230314T001205_IFCB134.adc
    │   ├── D20230314T001205_IFCB134.hdr
    │   ├── D20230314T001205_IFCB134.roi
    │   ├── D20230314T003836_IFCB134.adc
    │   ├── D20230314T003836_IFCB134.hdr
    │   └── D20230314T003836_IFCB134.roi
    ├── D20230810
    │   ├── D20230810T113059_IFCB134.adc
    │   ├── D20230810T113059_IFCB134.hdr
    │   └── D20230810T113059_IFCB134.roi
    └── D20230915
        ├── D20230915T091133_IFCB134.adc
        ├── D20230915T091133_IFCB134.hdr
        ├── D20230915T091133_IFCB134.roi
        ├── D20230915T093804_IFCB134.adc
        ├── D20230915T093804_IFCB134.hdr
        └── D20230915T093804_IFCB134.roi
```

```bash
python neuston_net.py RUN \
  data/data_roi/data \
  "$MODEL_PATH" "$RUN_ID"
```

Results will be saved to `run-output/$RUN_ID/`.

## Advanced Usage

### GPU Acceleration

- Training and inference benefit significantly from GPU acceleration
- Ensure CUDA toolkit and GPU drivers are properly installed

### Hyperparameter Tuning

- Adjust batch size with `--batch` (default: 32)
- Set maximum epochs with `--emax` (default: 100)
- Control learning rate with `--lr` (default: 0.001)
- Manage validation frequency with `--valfreq` (default: 0.1)

## Troubleshooting

### Memory Issues

- Reduce batch size with `--batch 4` or `--batch 8`

### CUDA Errors

- Check CUDA/PyTorch compatibility
- Ensure your GPU has enough memory

## Future Improvements

- [ ] Documentation expansion with specific usage examples
- [ ] Performance optimization for larger datasets
- [ ] Multi-GPU training support
- [ ] Hyperparameter optimization tools
- [ ] Try to deploy on the [Digital Research Alliance](https://alliancecan.ca/en) infrastructure
