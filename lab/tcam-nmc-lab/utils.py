"""
Created on August 03 17:54, 2020

@author: fassial
"""
import os
import numpy as np

"""
load_data:
    load data from file.
    @params:
        filename(str)   : file name
    @rets:
        res(np.array)   : np matrix from csv
"""
def load_data(filename):
    return np.loadtxt(
        filename,
        comments = '#',
        delimiter = ','
    )

"""
store_data:
    store data into file.
    @params:
        filename(str)   : file name
        src(np.array)   : np matrix to store
    @rets:
        None
"""
def store_data(filename, src, fmt):
    np.savetxt(
        filename,
        src,
        delimiter = ',',
        fmt = fmt
    )

"""
load_dataset:
    load dataset from dir.
    @params:
        dirpath(str)        : dir path
    @rets:
        x_train(np.array)   : feature matrix of train set
        y_train(np.array)   : label vector of train set
        x_test(np.array)    : feature matrix of test set
        y_test(np.array)    : label vector of test set
"""
def load_dataset(dirpath):
    # get set path
    train_set_path = os.path.join(dirpath, "train")
    test_set_path = os.path.join(dirpath, "test")
    # get dataset
    print("loading dataset...")
    x_train = load_data(
        filename = os.path.join(train_set_path, "feature.csv")
    )
    y_train = load_data(
        filename = os.path.join(train_set_path, "label.csv")
    )
    x_test = load_data(
        filename = os.path.join(test_set_path, "feature.csv")
    )
    y_test = load_data(
        filename = os.path.join(test_set_path, "label.csv")
    )
    print("dataset loaded")
    return (x_train, y_train, x_test, y_test)

"""
remap:
    remap src(matrix) to range
    @params:
        src(np.array)   : source matrix
        _range(tuple)   : range to remap
        src_max(int)    : normailization param
    @rets:
        dst(np.array)   : dest matrix
"""
def remap(src, _range, src_max = None):
    if src_max == None: src_max = np.max(src)
    _range_len = _range[1] - _range[0]
    dst = src * _range_len / src_max
    dst += _range[0]
    return np.round(dst).astype(np.int32)
