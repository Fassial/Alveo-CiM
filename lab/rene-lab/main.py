"""
Created on July 29 11:59, 2020

@author: fassial
"""
import os
import math
import shutil
import numpy as np
from collections import Counter
# local dep
import utils

# file loc params
PREFIX = "."
DATASET = os.path.join(PREFIX, "dataset")
FEATURE_FILE = os.path.join(DATASET, "feature.csv")
LABEL_FILE   = os.path.join(DATASET, "label.csv")
FEATURE_ENCODE_FILE = os.path.join(DATASET, "feature_encode.csv")
# train set
TRAINSET = os.path.join(DATASET, "train")
TRAINSET_FEATUREENCODE = os.path.join(TRAINSET, "feature_encode")
TRAINSET_LABEL = os.path.join(TRAINSET, "label")
# test set
TESTSET = os.path.join(DATASET, "test")
TESTSET_FEATUREENCODE = os.path.join(TESTSET, "feature_encode")
TESTSET_LABEL = os.path.join(TESTSET, "label")
# eval dir
EVALDIR = os.path.join(DATASET, "eval")
# ecode params
W = 8
HMAX = 8
# train & test params
P_TRAIN = 0.7
N_TOP = 20
MAX_ROW = 2000
# eval params
H = [2**i for i in range(1, 5)]     # [2, 4, 8, 16]

"""
_split_dataset:
    split the dataset into trainset and testset
    @params:
        x_all(np.array) : feature of dataset
        y_all(np.array) : label of dataset
        ptrain(float)   : P of trainset
    @rets:
        x_train(np.array)   : feature of trainset
        y_train(np.array)   : label of trainset
        x_test(np.array)    : feature of testset
        y_test(np.array)    : label of testset
"""
def _split_dataset(x_all, y_all, ptrain = P_TRAIN):
    # init res
    x_train, y_train, x_test, y_test = [], [], [], []
    # get conter
    y_all_counter = Counter(y_all)
    for label in set(y_all):
        n_train = int(y_all_counter[label] * ptrain)
        n_test = y_all_counter[label] - n_train
        # get label_train
        index = 0
        while n_train > 0:
            if y_all[index] == label:
                x_train.append(x_all[index])
                y_train.append(y_all[index])
                n_train -= 1
            index += 1
        # get label_test
        while n_test > 0:
            if y_all[index] == label:
                x_test.append(x_all[index])
                y_test.append(y_all[index])
                n_test -= 1
            index += 1
    return np.array(x_train), np.array(y_train), np.array(x_test), np.array(y_test)

"""
split_dataset:
    split the dataset into trainset and testset, save on disk
    @params:
        None
    @rets:
        None
"""
def split_dataset():
    # get feature & label
    feature = utils.load_data(FEATURE_FILE)[:, 1:].astype(np.float64)
    label = utils.load_data(LABEL_FILE)[:, 1].astype(np.int32)
    # get train_set & test_set
    x_train, y_train, x_test, y_test = _split_dataset(
        x_all = feature,
        y_all = label
    )
    # check whether dir exists
    if os.path.exists(TRAINSET): shutil.rmtree(TRAINSET)
    if os.path.exists(TESTSET): shutil.rmtree(TESTSET)
    os.mkdir(TRAINSET)
    os.mkdir(TESTSET)
    # save raw data
    utils.store_data(
        os.path.join(TRAINSET, "feature.csv"),
        x_train
    )
    utils.store_data(
        os.path.join(TRAINSET, "label.csv"),
        y_train
    )
    utils.store_data(
        os.path.join(TESTSET, "feature.csv"),
        x_test
    )
    utils.store_data(
        os.path.join(TESTSET, "label.csv"),
        y_test
    )

"""
save_encodeset:
    save the RENE-encode of trainset & testset
    @params:
        None
    @rets:
        None
"""
def save_encodeset():
    # get raw dataset
    feature = utils.load_data(FEATURE_FILE)[:, 1:]
    feature_max = np.max(feature)
    # get trainset
    train_feature = utils.load_data(
        os.path.join(TRAINSET, "feature.csv")
    )
    train_label = utils.load_data(
        os.path.join(TRAINSET, "label.csv")
    )[:].reshape(-1, 1)
    # remap trainset to Z
    feature_remap = utils.remap(train_feature, (0, 2**W-1), feature_max)
    # check trainset dir
    if os.path.exists(TRAINSET_FEATUREENCODE): os.removedirs(TRAINSET_FEATUREENCODE)
    if os.path.exists(TRAINSET_LABEL): os.removedirs(TRAINSET_LABEL)
    os.mkdir(TRAINSET_FEATUREENCODE)
    os.mkdir(TRAINSET_LABEL)
    # check testset dir
    if os.path.exists(TESTSET_FEATUREENCODE): shutil.rmtree(TESTSET_FEATUREENCODE)
    if os.path.exists(TESTSET_LABEL): shutil.rmtree(TESTSET_LABEL)
    os.mkdir(TESTSET_FEATUREENCODE)
    os.mkdir(TESTSET_LABEL)
    # save x_train & y_train
    for i in range(feature_remap.shape[0] // MAX_ROW):
        feature_encode = utils.encode(feature_remap[(i*MAX_ROW):(i+1)*MAX_ROW, :], feature_remap[0].shape[0], W, HMAX)
        feature_encode = feature_encode.reshape(feature_encode.shape[0], -1)
        utils.store_data(
            os.path.join(TRAINSET_FEATUREENCODE, "feature_encode_" + str(i*MAX_ROW) + "_" + str((i+1)*MAX_ROW) + ".csv"),
            feature_encode
        )
        utils.store_data(
            os.path.join(TRAINSET_LABEL, "label_" + str(i*MAX_ROW) + "_" + str((i+1)*MAX_ROW) + ".csv"),
            train_label[(i*MAX_ROW):((i+1)*MAX_ROW)]
        )
    if feature_remap.shape[0] % MAX_ROW != 0:
        feature_encode = utils.encode(feature_remap[((feature_remap.shape[0] // MAX_ROW)*MAX_ROW):feature_remap.shape[0], :], feature_remap[0].shape[0], W, HMAX)
        feature_encode = feature_encode.reshape(feature_encode.shape[0], -1)
        utils.store_data(
            os.path.join(TRAINSET_FEATUREENCODE, "feature_encode_" + str((feature_remap.shape[0] // MAX_ROW)*MAX_ROW) + "_" + str(feature_remap.shape[0]) + ".csv"),
            feature_encode
        )
        utils.store_data(
            os.path.join(TRAINSET_LABEL, "label_" + str((feature_remap.shape[0] // MAX_ROW)*MAX_ROW) + "_" + str(feature_remap.shape[0]) + ".csv"),
            train_label[((feature_remap.shape[0] // MAX_ROW)*MAX_ROW):feature_remap.shape[0]]
        )
    # get testset
    test_feature = utils.load_data(
        os.path.join(TESTSET, "feature.csv")
    )
    test_label = utils.load_data(
        os.path.join(TESTSET, "label.csv")
    )[:].reshape(-1, 1)
    # remap testset to Z
    feature_remap = utils.remap(test_feature, (0, 2**W-1), feature_max)
    # save x_test & y_test
    for i in range(feature_remap.shape[0] // MAX_ROW):
        feature_encode = utils.encode(feature_remap[(i*MAX_ROW):(i+1)*MAX_ROW, :], feature_remap[0].shape[0], W, HMAX)
        feature_encode = feature_encode.reshape(feature_encode.shape[0], -1)
        utils.store_data(
            os.path.join(TESTSET_FEATUREENCODE, "feature_encode_" + str(i*MAX_ROW) + "_" + str((i+1)*MAX_ROW) + ".csv"),
            feature_encode
        )
        utils.store_data(
            os.path.join(TESTSET_LABEL, "label_" + str(i*MAX_ROW) + "_" + str((i+1)*MAX_ROW) + ".csv"),
            test_label[(i*MAX_ROW):((i+1)*MAX_ROW)]
        )
    if feature_remap.shape[0] % MAX_ROW != 0:
        feature_encode = utils.encode(feature_remap[((feature_remap.shape[0] // MAX_ROW)*MAX_ROW):feature_remap.shape[0], :], feature_remap[0].shape[0], W, HMAX)
        feature_encode = feature_encode.reshape(feature_encode.shape[0], -1)
        utils.store_data(
            os.path.join(TESTSET_FEATUREENCODE, "feature_encode_" + str((feature_remap.shape[0] // MAX_ROW)*MAX_ROW) + "_" + str(feature_remap.shape[0]) + ".csv"),
            feature_encode
        )
        utils.store_data(
            os.path.join(TESTSET_LABEL, "label_" + str((feature_remap.shape[0] // MAX_ROW)*MAX_ROW) + "_" + str(feature_remap.shape[0]) + ".csv"),
            test_label[((feature_remap.shape[0] // MAX_ROW)*MAX_ROW):feature_remap.shape[0]]
        )

"""
_ternaryMatch:
    ternary match
    @params:
        _point(np.array)    : point with shape(n_feature, )
        _range(np.array)    : range with shape(n_feature, 2)
    @rets:
        flag(bool)          : whether _point & _range ternary math
"""
def _ternaryMatch(_point, _range):
    if _point.shape[0] != _range.shape[0]: return False
    for i in range(_point.shape[0]):
        if not rene.ternaryMatch(_range[i, 0], _range[i, 1], _point[i], 0): return False
    return True

"""
_get_cubes:
    get cubes from (points, h)
    @params:
        points(np.array)    : feature matrix with shape(n_point, n_feature)
        h(int)              : side length of cube
    @rets:
        cubes(np.array)     : cubes of (points, h) with shape(n_point, n_feature, 2)
"""
def _get_cubes(points, h):
    cubes = []
    for i in range(points.shape[0]):
        cube = rene._tcode(
            p = points[i],
            d = points[i].shape[0],
            w = W,
            hmax = HMAX,
            h = h
        )
        cubes.append(cube)
    return np.array(cubes).astype(np.int32)

"""
_get_nmatch:
    get the number of match(query point & points' cubes)
    @params:
        points(np.array)    : dataset with shape(n_points, n_feature) to build cubes
        querys(np.array)    : queryset with shape(n_querys, n_feature) to query cubes
        h(int)              : side length of cube
    @rets:
        nmatch(np.array)    : the number of match(query point & points' cubes) with shape(n_querys,)
"""
def _get_nmatch(points, querys, h = 32):
    # init nmatch
    nmatch = []
    # get cubes
    cubes = _get_cubes(
        points = points,
        h = h
    )
    # set nmatch
    for i in range(points.shape[0]):
        count = 0
        for j in range(cubes.shape[0]):
            if _ternaryMatch(points[i], cubes[j]): count += 1
        nmatch.append(count)
    return np.array(nmatch)

def get_nmatch():
    # set params
    h = 32
    # get x_train & x_test
    # get raw dataset
    feature = utils.load_data(FEATURE_FILE)[:, 1:]
    feature_max = np.max(feature)
    # get trainset
    train_feature = utils.load_data(
        os.path.join(TRAINSET, "feature.csv")
    )
    # remap trainset to Z
    train_feature_remap = utils.remap(train_feature, (0, 2**W-1), feature_max)
    # get RENE-encode
    train_feature_encode = utils.encode(train_feature_remap, train_feature_remap[0].shape[0], W, HMAX)
    # get testset
    test_feature = utils.load_data(
        os.path.join(TESTSET, "feature.csv")
    )
    # remap testset to Z
    test_feature_remap = utils.remap(test_feature, (0, 2**W-1), feature_max)
    # get RENE-encode
    test_feature_encode = utils.encode(test_feature_remap, test_feature_remap[0].shape[0], W, HMAX)
    # get nmatch
    nmatch = _get_nmatch(
        points = train_feature_encode,
        querys = test_feature_encode,
        h = h
    )
    # check eval_dir
    if os.path.exists(EVALDIR): shutil.rmtree(EVALDIR)
    os.mkdir(EVALDIR)
    # store nmatch
    utils.store_data(
        os.path.join(EVALDIR, "nmatch_" + str(h) + ".csv"),
        nmatch
    )
    # get pmatch
    pmatch = sum(nmatch > 0) / nmatch.shape[0]
    print("pmatch:", pmatch)

"""
ptopN:
    calculate accuracy of dist-classifier based on RENE-encode
    @params:
        x_train(np.array)   : feature of trainset
        y_train(np.array)   : label of trainset
        x_test(np.array)    : feature of testset
        y_test(np.array)    : label of testset
        n_top(int)          : number of check
    @rets:
        P(float)            : accuracy of classifier
"""
def ptopN(x_train, y_train, x_test, y_test, n_top = N_TOP):
    P = 0
    n_test = y_test.shape[0]
    # get sim(n_test, n_train)
    sim = x_test.dot(x_train.T)
    order = np.argsort(-sim)
    # get accu
    for i in range(n_test):
        if i % 100 == 0: print("cycle:", i)
        correct = 0
        for j in range(n_top):
            if y_test[i, 0] == y_train[order[i, j], 0]: correct += 1
        P += correct / n_top
    P /= n_test
    return P

"""
main:
    main func
"""
def main():
    # split_dataset()
    # save_encodeset()
    get_nmatch()
    """
    P = ptopN(
        x_train = x_train,
        y_train = y_train.reshape(-1, 1),
        x_test = x_test,
        y_test = y_test.reshape(-1, 1)
    )
    print("P@top" + str(N_TOP) + ":", str(P))
    """

if __name__ == "__main__":
    main()
