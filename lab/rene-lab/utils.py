"""
Created on July 29 10:52, 2020

@author: fassial
"""
import os
import numpy as np

# file loc params
PREFIX = "."
DATASET = os.path.join(PREFIX, "dataset")
FEATURE_FILE = os.path.join(DATASET, "feature.csv")
LABEL_FILE   = os.path.join(DATASET, "label.csv")
# ecode params
W = 8
HMAX = 8

def get_data(filename):
    return np.loadtxt(
        filename,
        comments = '#',
        delimiter = ','
    )

def remap(src, _range):
    src_max = np.max(src)
    _range_len = _range[1] - _range[0]
    dst = src * _range_len / src_max
    dst += _range[0]
    return np.round(dst)

def encode(p, d, hmax = HMAX):
    res = np.zeros((p.shape[0]))
    for i in range(res.shape[0]):
        res[i] = rene.tcode(p[i, :], d, hmax)
    return res

if __name__ == "__main__":
    feature = get_data(FEATURE_FILE)[:, 1:]
    label = get_data(LABEL_FILE)[:, 1:].reshape(-1, 1)
    print(feature.shape, feature)
    print(label.shape, label)
    feature_remap = remap(feature, (0, 2**W-1))
    print(feature_remap.shape, feature_remap)
    feature_encode = encode(feature_remap, feature_remap[0].shape[0], HMAX)
    print(feature_encode)
