"""
Created on September 04 20:40, 2020

@author: fassial
"""
import os
import numpy as np
# local dep
import utils
import fasthash_encode

# loc params
PREFIX = ".."
DATASET_PATH = os.path.join(PREFIX, "dataset")
ENCODE_PATH = os.path.join(PREFIX, "encode")
MODEL_PATH = os.path.join(PREFIX, "model")

"""
main:
    main func
    @params:
        None
    @rets:
        None
"""
def main():
    # get dataset
    dataset = utils.load_dataset(
        dirpath = DATASET_PATH
    )
    prep_dataset = dataset["preprocess"]
    # get models
    models = utils.load_models(
        dirpath = MODEL_PATH
    )
    # get encode
    # get db_encode
    # get train_encode
    # get test_encode
    test_encode = fasthash_encode.fasthash_encode(
        models = models,
        feature = prep_dataset["test_data"]["feature"]
    ); print(test_encode.shape);
    # save test_encode
    encode_python_path = os.path.join(ENCODE_PATH, "python")
    if not os.path.exists(encode_python_path): os.mkdir(encode_python_path)
    utils.store_data(
        filename = os.path.join(encode_python_path, "test_encode.csv"),
        src = test_encode,
        fmt = "%d"
    )
    # get test_encode_mat
    test_encode_mat = utils.load_data(
        filename = os.path.join(ENCODE_PATH, "matlab", "test_encode.csv")
    ); print((test_encode == test_encode_mat).all())

if __name__ == "__main__":
    main()
