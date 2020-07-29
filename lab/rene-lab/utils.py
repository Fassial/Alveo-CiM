"""
Created on July 29 10:52, 2020

@author: fassial
"""
import os
import math
import numpy as np
# local dep
import rene

# file loc params
PREFIX = "."
DATASET = os.path.join(PREFIX, "dataset")
FEATURE_FILE = os.path.join(DATASET, "feature.csv")
LABEL_FILE   = os.path.join(DATASET, "label.csv")
FEATURE_ENCODE_FILE = os.path.join(DATASET, "feature_encode.csv")
POSTFIX = ".csv"
# ecode params
W = 8
HMAX = 8
# train & test params
MAX_ROW = 2000

"""
load_data:
    load data from file
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
    store data into file
    @params:
        filename(str)   : file name
        src(np.array)   : np matrix to store
    @rets:
        None
"""
def store_data(filename, src):
    np.savetxt(
        filename,
        src,
        delimiter = ','
    )

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

"""
encode:
    RENE encode
    @params:
        p(np.array)     : feature vector
        d(int)          : number of dimension to consider
        w(int)          : bit width of gray code
        hmax(int)       : max range len we consider
    @rets:
        res(np.array)   : RENE-encode vector
"""
def encode(p, d, w = W, hmax = HMAX):
    # init res
    res = []
    for i in range(p.shape[0]):
        if i % 100 == 0: print("curr: ", str(i))
        res.append(rene.tcode(p[i, :], d, w, hmax))
    return np.array(res).astype(np.int32)

"""
main:
    main func
"""
def main():
    pass

if __name__ == "__main__":
    main()

