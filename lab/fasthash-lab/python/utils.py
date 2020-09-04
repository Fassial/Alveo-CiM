"""
Created on September 04 16:54, 2020

@author: fassial
"""
import os
import warnings
import numpy as np

# loc params
PREFIX = ".."
DATASET_PATH = os.path.join(PREFIX, "dataset")
ENCODE_PATH = os.path.join(PREFIX, "encode")
MODEL_PATH = os.path.join(PREFIX, "model")

"""
load_data:
    load data from file.
    @params:
        filename(str)   : file name
    @rets:
        res(np.array)   : np matrix from csv
"""
def load_data(filename):
    with warnings.catch_warnings():
        warnings.simplefilter("ignore")
        res = np.loadtxt(
            filename,
            comments = '#',
            delimiter = ','
        )
    return res

"""
store_data:
    store data into file.
    @params:
        filename(str)   : file name
        src(np.array)   : np matrix to store
        fmt(str)        : format to write
    @rets:
        None
"""
def store_data(filename, src, fmt):
    np.savetxt(
        filename,
        src,
        fmt = fmt,
        delimiter = ','
    )

"""
_load_dataset:
    load dataset from dir.
    @params:
        dirpath(str)        : dir path
    @rets:
        dataset(dict)       : dataset of db & train & test
"""
def _load_dataset(dirpath):
    # init dataset
    dataset = dict()
    # get db_data
    db_feature = load_data(
        filename = os.path.join(dirpath, "db_feature.csv")
    )
    db_label = load_data(
        filename = os.path.join(dirpath, "db_label.csv")
    )
    # get train_data
    train_feature = load_data(
        filename = os.path.join(dirpath, "train_feature.csv")
    )
    train_label = load_data(
        filename = os.path.join(dirpath, "train_label.csv")
    )
    # get test_data
    test_feature = load_data(
        filename = os.path.join(dirpath, "test_feature.csv")
    )
    test_label = load_data(
        filename = os.path.join(dirpath, "test_label.csv")
    )
    # set dataset
    dataset["db_data"] = {
        "feature": db_feature,
        "label": db_label
    }
    dataset["train_data"] = {
        "feature": train_feature,
        "label": train_label
    }
    dataset["test_data"] = {
        "feature": test_feature,
        "label": test_label
    }
    return dataset

"""
load_dataset:
    load dataset from dir.
    @params:
        dirpath(str)        : dir path
    @rets:
        dataset(dict)       : dataset of raw & preprocess
"""
def load_dataset(dirpath):
    # init dataset
    dataset = dict()
    # get set path
    raw_set_path = os.path.join(dirpath, "raw")
    preprocess_set_path = os.path.join(dirpath, "preprocess")
    # get dataset
    print("loading dataset...")
    dataset["raw"] = _load_dataset(raw_set_path)
    dataset["preprocess"] = _load_dataset(preprocess_set_path)
    print("dataset loaded")
    return dataset

"""
_load_tree_model:
    load tree model trained by matlab
    @params:
        dirpath(str)        : dir path
    @rets:
        tree_model(dict)    : dict of tree model
"""
def _load_tree_model(dirpath):
    # init tree_model
    tree_model = dict()
    # get tree model attr
    for file in os.listdir(dirpath):
        key = os.path.splitext(file)[0]
        tree_model[key] = load_data(
            filename = os.path.join(dirpath, file)
        )
    return tree_model

"""
_load_model:
    load model trained by matlab
    @params:
        dirpath(str)        : dir path
    @rets:
        model(dict)         : dict of model
"""
def _load_model(dirpath):
    # init model
    model = dict()
    # get model attr
    # get w & sel_feat_idxes
    w = load_data(
        filename = os.path.join(dirpath, "w.csv")
    )
    sel_feat_idxes = load_data(
        filename = os.path.join(dirpath, "sel_feat_idxes.csv")
    )
    # tree_models
    tree_models = list()
    tree_models_path = os.path.join(dirpath, "tree_models")
    for i in range(len(os.listdir(tree_models_path))):
        subdir = os.path.join(tree_models_path, str(i+1))
        # ignore file
        if os.path.isfile(subdir): continue
        # load tree model
        tree_models.append(_load_tree_model(
            dirpath = subdir
        ))
    # set model
    model["w"] = w
    model["sel_feat_idxes"] = sel_feat_idxes
    model["tree_models"] = tree_models
    return model

"""
load_models:
    load models trained by matlab
    @params:
        dirpath(str)        : dir path
    @rets:
        models(list)        : list of models
"""
def load_models(dirpath):
    # init models
    models = list()
    # load models
    print("loading models...")
    for i in range(len(os.listdir(dirpath))):
        subdir = os.path.join(dirpath, "tree"+str(i+1))
        # ignore file
        if os.path.isfile(subdir): continue
        # load sub model
        models.append(_load_model(
            dirpath = subdir
        ))
    print("models loaded")
    return models

"""
test_load_dataset:
    test load_dataset
    @params:
        None
    @rets:
        None
"""
def test_load_dataset():
    # get dataset
    dataset = load_dataset(
        dirpath = DATASET_PATH
    )
    # check dataset
    print("dataset.keys():", dataset.keys())
    # check raw dataset
    raw_dataset = dataset["raw"]
    print("raw_dataset.keys():", raw_dataset.keys())
    for key in raw_dataset.keys():
        print(key, ":")
        print("\tfeature:", raw_dataset[key]["feature"].shape)
        print("\tlabel:", raw_dataset[key]["label"].shape)
    # check preprocess dataset
    prep_dataset = dataset["preprocess"]
    print("prep_dataset.keys():", prep_dataset.keys())
    for key in prep_dataset.keys():
        print(key, ":")
        print("\tfeature:", prep_dataset[key]["feature"].shape)
        print("\tlabel:", prep_dataset[key]["label"].shape)

"""
test_load_models:
    test load_models
    @params:
        None
    @rets:
        None
"""
def test_load_models():
    # get models
    models = load_models(
        dirpath = MODEL_PATH
    )
    # check models
    print("len(models):", len(models))
    # check model
    for i in range(len(models)):
        print("checking model", str(i), "...")
        model = models[i]
        # get attr
        w, tree_models, sel_feat_idxes = model["w"], model["tree_models"], model["sel_feat_idxes"]
        # check w & sel_feat_idxes
        print("\tw:", w.shape)
        print("\tsel_feat_idxes:", sel_feat_idxes.shape)
        # check tree_models
        for j in range(len(tree_models)):
            print("\tchecking tree model", str(j), "...")
            tree_model = tree_models[j]
            print("\ttree_model.keys():", tree_model.keys())
            for key in tree_model.keys():
                print("\t\t" + key + ":", tree_model[key].shape)

"""
main:
    main func
    @params:
        None
    @rets:
        None
"""
def main():
    # test_load_dataset()
    test_load_models()

if __name__ == "__main__":
    main()
