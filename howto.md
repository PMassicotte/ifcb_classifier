# How to use the IFCB Neural Network model

```bash
~/anaconda3/bin/conda init zsh
```

## Installation

```bash
conda env create -f requirements/env.dev.yml
conda activate ifcbnn # or whatever name is defined in the YAML
```

```bash
conda create --name ifcbnn --file requirements/pkgs.dev.txt
git clone https://github.com/joefutrelle/pyifcb
cd pyifcb
pip install -e .
```

If `pyifcb` is not installed due to mismatch in version number, you can install it with the following command:

```bash
git clone https://github.com/joefutrelle/pyifcb

pip install --no-deps git+https://github.com/joefutrelle/pyifcb.git
cd pyifcb
pip install -e .
```

## Train the model

On computer without CUDA, you can run the following command before training the model:

```bash
export CUDA_VISIBLE_DEVICES=0
```

```bash
## PARAMS ##
MODEL=inception_v3
DATASET=data/classified/
TRAIN_ID=TestTrainingID
```

Here I reduce the batch size to 8 it was not working on my job computer

```bash
python ./neuston_net.py --batch 8 TRAIN "$DATASET" "$MODEL" "$TRAIN_ID" --flip xy
```

Reduce the maximum number of epochs to 1 for testing purposes:

```bash
python ./neuston_net.py --batch 8 TRAIN "$DATASET" "$MODEL" "$TRAIN_ID" --flip xy --emax 1
```

- There is no need to provide the training/validation split, as the script will automatically split the dataset into training and validation sets.

- The default split is 80% for training and 20% for validation.

- By default, the main validation results file is called results.mat, but you can customize the name and contents using the `--results` argument.

- `training_images.list` (list of training image paths)

- `validation_images.list` (list of validation image paths)

## Run the model to predict on images

We have to specify the training ID and the model file to use for prediction. `RUN_ID` is the ID of the run, will create a directory with this name in the `training-output` directory (`default="run-output/{RUN_ID}/v3/{MODEL_ID}"
`).

```bash
RUN_ID=TestRunID
python3 neuston_net.py RUN data/data_roi/png/Alexandrium_pseudogonyaulax_050/D20220712T210855_IFCB134_00042.png training-output/TestTrainingID/TestTrainingID.ptl "$TestRunID" --type img
```

For a directory of images, you can run the following command:

```bash
RUN_ID=TestRunID
python3 neuston_net.py RUN data/data_roi/png/ training-output/TestTrainingID/TestTrainingID.ptl "$TestRunID" --type img
```

### Test on raw IFCB data

The test data used in this example is a small subset of raw IFCB data, which can be found in the `data/data_roi` directory. The data have been downloaded using the R script `download_ifcb_test_data.R` from this repository.

```bash
python3 neuston_net.py RUN data/data_roi/data training-output/ExampleTrainingID/ExampleTrainingID.ptl ddd
```

## TODOs

- [ ] Add more documentation on how to use the model.
- [ ] Train the model on a larger dataset with more epochs.
- [ ] Use CUDA to speed up the training process.
- [ ] uv?
