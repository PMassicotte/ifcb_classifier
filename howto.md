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
  - [Extra data](#extra-data)
  - [Data Requirements](#data-requirements)
  - [Notes on autoclass (ifcb dash board)](#notes-on-autoclass-ifcb-dash-board)
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

# Option 2: Using package list (for me this works better since the file has the correct versions)
conda create --name ifcbnn --file requirements/pkgs.dev.txt
conda activate ifcbnn
```

On Apple Silicon (M1/M2) systems, you may need to change the environment YAML file:

```yml
name: ifcbnn
channels:
  - conda-forge
  - pytorch
dependencies:
  - python>=3.8
  - pytorch::pytorch
  - pytorch::torchvision
  - pytorch-lightning=1.3.8=pyhd8ed1ab_0
  - onnxruntime
  - scikit-learn
  - pandas
  - numpy
  - h5py
  - pip
  - pip:
      - git+https://github.com/joefutrelle/pyifcb.git
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

The data in `training-data` should be organized as follows, i.e. each subdirectory contains images of a specific class:

```bash
training-data
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

Charlotte also provided some classified phytoplankton images.

### 2. Training a Model

Set up environment variables and parameters:

```bash
# Set CUDA device (change if want to use more gpus)
export CUDA_VISIBLE_DEVICES=0

# Define training parameters
MODEL=inception_v3     # Model architecture to use
DATASET=training-data/ # Path to classified data
TRAIN_ID=MyTrainingRun # Unique ID for this training run
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

On my system, the training command can looks like this (using CUDA device 0):

```bash
export CUDA_VISIBLE_DEVICES=0

# Define training parameters
MODEL=inception_v3
DATASET=training-data/
TRAIN_ID=inception_v3_smhi_tangesund_b32_flipxy

# Change the batch size if you have a higher/lower memory system
python neuston_net.py --batch 32 TRAIN "$DATASET" "$MODEL" "$TRAIN_ID" --flip xy
```

#### Training Notes

- The script automatically splits data into training (80%) and validation (20%) sets
- Training/validation file lists are saved as `training_images.list` and `validation_images.list`
- Results are saved to `training-output/$TRAIN_ID/`
- The model file will be saved as `training-output/$TRAIN_ID/$TRAIN_ID.ptl`
- Use `--results` to customize validation results output (default: `results.mat`)

Images can be normalized:

```bash
python neuston_net.py TRAIN [SRC] [MODEL] [TRAIN_ID] --img-norm "0.6231432, 0.20911531"
```

Values were calculated from the training data using the following:

```bash
python3 neuston_util.py CALC_IMG_NORM training-data/
```

Not needed when doing inference, as the model will handle normalization automatically.

> This includes the original normalization parameters, which are then used automatically to preprocess inference images. You can see this in action when the model creates the dataset for inference (line 311-312) where it passes along the classifier.hparams.img_norm values. So the answer is: No, you don't need to re-specify the normalization parameters during inference - the values are automatically used from your trained model.

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

## Extra data

[Tara Oceans Polar Circle](https://misclab.umeoce.maine.edu/ftp/experiments/Tara/TaraArctic/TaraOceansPolarCircle_allData/)

Not sure if this data is useful, but it contains a lot of images and metadata.

## Data Requirements

For CNN training, you generally need at least 50-100 images per class for basic training. Classes with very few samples (like those with under 30 images) might lead to poor performance or overfitting. Consider:

- Keep classes with 100+ images
- Consider merging related classes with few samples
- For classes with 30-100 images, use data augmentation techniques
- Remove classes with fewer than 10-15 images
- Classes with just 1-5 samples are likely insufficient even with augmentation.

## Notes on autoclass (ifcb dash board)

Based on my understanding, the "autoclass" link found in the dashboard works as follows:

1. The classification uses a CNN model (found in the IFCB-CNN directory), likely based on architectures like `ResNet50/152`, `InceptionV3`, or `VGG16`.
2. Classification results are stored in the AutoclassScore model (in `ifcb_datasets/models.py`) which links to:

   - The phytoplankton image (via pid)
   - The confidence score
   - Species classification
   - Bin (collection of images)

3. The image URLs are constructed in the API (in api/views.py) following this pattern:
   `{public_url}/{dataset_id_name}/{image_name}.png`
4. A confidence threshold (autoclass_threshold in the TargetSpecies model) determines which classifications are considered valid.

The classification pipeline ingests IFCB images, processes them through the CNN model, stores scores, and makes them accessible through both API endpoints and UI elements.

## Future Improvements

- Filter species without enough observations (~50?, ~100?)
- Documentation expansion with specific usage examples
- Performance optimization for larger datasets?
- Try to deploy on the [Digital Research Alliance](https://alliancecan.ca/en) infrastructure
- R code to format the results for the training and inference steps. Maybe use a database to store the results?
  - The results of the predictions should be pivoted wider. The first column should be the ID with the ROI, e.g. `D20220819T055747_IFCB145_001` with `D20220819T055747_IFCB145` the id and the `001` the roi number. All other columns should be the species with the confidence score as the value.
