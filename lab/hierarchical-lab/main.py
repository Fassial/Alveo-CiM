"""
Created on August 06 15:20, 2020

@author: fassial
"""
import os
import pyflann
import numpy as np
# local dep
import utils

# file loc params
PREFIX = ".."
# dataset & testdataset
DATASET = os.path.join(PREFIX, "dataset")
PREDATASET = os.path.join(PREFIX, "predataset")
# flann-hierarchical params
K = 10

"""
ptopN:
    calculate accuracy of dist-classifier based on RENE-encode
    @params:
        x_train(np.array)   : feature of trainset
        y_train(np.array)   : label of trainset
        x_test(np.array)    : feature of testset
        y_test(np.array)    : label of testset
        k(int)              : number of check
    @rets:
        P(float)            : accuracy of classifier
"""
def ptopK(x_train, y_train, x_test, y_test, k = K):
    # init flann
    flann = pyflann.FLANN()
    # set dataset
    params = flann.build_index(
        dataset = x_train,
        algorithm = "hierarchical",
        target_precision = 0.9,
        log_level = "info"
    ); print(params)
    # get query result
    result, dists = flann.nn_index(
        testset = x_test,
        num_neighbors = k,
        checks = params["checks"]
    ); print(result, dists)
    # calculate P
    P = 0
    return P

"""
main:
    main func
"""
def main():
    # get trainset & testset
    x_train, y_train, x_test, y_test = utils.load_dataset(dirpath = PREDATASET)
    # get ptopK
    p = ptopK(
        x_train = x_train,
        y_train = y_train,
        x_test = x_test,
        y_test = y_test,
        k = K
    )
    print("ptopK: %.2f%%" % (p*100))

if __name__ == "__main__":
    main()
