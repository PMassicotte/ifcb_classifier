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
    - [Input Data Organization](#input-data-organization)
      - [For Images](#for-images)
      - [For Raw IFCB Data](#for-raw-ifcb-data)
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

The project includes a convenient shell script for training models that handles conda environment activation, CUDA device configuration, and other common settings.

```bash
# Basic usage (requires specifying a training ID)
./train_cnn_model.sh -t inception_v3_my_model_id

# Show help and available options
./train_cnn_model.sh -h
```

The training script requires a training ID parameter, which identifies your training run and names the output model files. Choose a descriptive name that includes the model architecture and important training parameters.

Example training ID: `inception_v3_smhi_tangesund_b32_flipxy`

The script uses the following default settings:

- Model architecture: inception_v3
- Dataset location: training-data/
- Batch size: 32
- Data augmentation: Random flips (horizontal, vertical)
- Image normalization: Pre-calculated values for the dataset

Training results are saved to `training-output/your_training_id/`.

#### Training Notes

- The script automatically splits data into training (80%) and validation (20%) sets
- Training/validation file lists are saved as `training_images.list` and `validation_images.list`
- The model file is saved as `training-output/$TRAIN_ID/$TRAIN_ID.ptl`

Image normalization values are pre-configured in the script (0.6231432, 0.20911531). These were calculated from the training data and are automatically applied during both training and inference.

## Running Inference (making predictions)

The project includes a shell script for running inference with trained models:

```bash
# Basic usage
./run_cnn_model.sh -i INPUT_DATA_DIR -m MODEL_NAME [-t TYPE]

# Show help and available options
./run_cnn_model.sh -h
```

Required parameters:

- `-i INPUT_DATA_DIR`: Directory containing input data to classify
- `-m MODEL_NAME`: Name of the trained model (e.g., 'inception_v3_smhi_tangesund_b32_flipxy')
- `-t TYPE`: Optional input type (e.g., 'img' for image input)

Example usage:

```bash
# Run inference on a directory of raw IFCB data
./run_cnn_model.sh -i run-data/sosik_2006/ -m inception_v3_my_model_id

# Run inference on a directory of images
./run_cnn_model.sh -i run-data/png_images/ -m inception_v3_my_model_id -t img
```

The script will:

1. Check if the specified model exists
2. Create a unique run ID based on the model name and input data
3. Activate the conda environment
4. Run inference on the input data
5. Save results to `run-output/$RUN_ID/`

### Input Data Organization

#### For Images

Input directory should contain PNG images, either directly or organized in subdirectories by class:

```
input_directory/
├── class1/
│   ├── image1.png
│   ├── image2.png
├── class2/
│   ├── image3.png
...
```

#### For Raw IFCB Data

Input directory should contain .adc, .hdr, and .roi files, typically organized by date:

```
input_directory/
├── D20220522/
│   ├── D20220522T000439_IFCB134.adc
│   ├── D20220522T000439_IFCB134.hdr
│   ├── D20220522T000439_IFCB134.roi
...
```

## Advanced Usage

### GPU Acceleration

- Training and inference benefit significantly from GPU acceleration
- Ensure CUDA toolkit and GPU drivers are properly installed
- The scripts automatically configure CUDA to use device 0 by default

### Hyperparameter Tuning

You can modify the scripts to adjust various hyperparameters:

- Batch size: Modify the `BATCH_SIZE` variable in the scripts (default: 32)
- Maximum epochs: Add `--emax VALUE` to the `EXTRA_ARGS` variable (default: 100)
- Learning rate: Add `--lr VALUE` to the `EXTRA_ARGS` variable (default: 0.001)
- Validation frequency: Add `--valfreq VALUE` to the `EXTRA_ARGS` variable (default: 0.1)

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
