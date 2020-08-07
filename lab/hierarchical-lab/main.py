"""
Created on August 06 15:20, 2020

@author: fassial
"""
import os
import timeit
import pyflann
import numpy as np
# local dep
import utils

# file loc params
PREFIX = ".."
# dataset & testdataset
DATASET = os.path.join(PREFIX, "dataset")
PREDATASET = os.path.join(PREFIX, "predataset")
# eval dir
EVAL_DIR = os.path.join(".", "eval")
SCORE_FILE = os.path.join(EVAL_DIR, "scores.csv")
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
    print("start build_index...")
    params = flann.build_index(
        x_train,
        # algorithm = "hierarchical",
        algorithm = "lsh",
        target_precision = 0.9,
        log_level = "info"
    ); print(params)
    print("complete build_index")
    # get query result
    print("start nn_index...")
    index, dists = flann.nn_index(
        x_test,
        num_neighbors = k,
        checks = params["checks"]
    ); print(index, dists)
    print("complete nn_index")
    # calculate P & n_match
    P = 0
    n_match = np.zeros((y_test.shape[0],))
    print("start calculate p...")
    for i in range(index.shape[0]):
        label = y_train[index[i]]
        n_match[i] = np.sum(label == y_test[i])
        P += n_match[i] / k
    print("complete calculate p")
    print(n_match)
    print("start save n_match...")
    if not os.path.exists(EVAL_DIR): os.mkdir(EVAL_DIR)
    if os.path.exists(SCORE_FILE): os.remove(SCORE_FILE)
    utils.store_data(
        filename = SCORE_FILE,
        src = n_match
    )
    print("complete save n_match")
    P /= index.shape[0]
    return P

"""
main:
    main func
"""
def main():
    # set start_time
    start_time = timeit.default_timer()
    # get trainset & testset
    # x_train, y_train, x_test, y_test = utils.load_dataset(dirpath = PREDATASET)
    x_train, y_train, x_test, y_test = utils.load_dataset(dirpath = DATASET); print(x_train.shape, y_train.shape, x_test.shape, y_test.shape)
    # get ptopK
    p = ptopK(
        x_train = x_train,
        y_train = y_train,
        x_test = x_test,
        y_test = y_test,
        k = K
    )
    print("ptopK: %.2f%%" % (p*100))
    # set end_time
    end_time = timeit.default_timer()
    print("main runs for %.1fs" % (end_time-start_time))

if __name__ == "__main__":
    main()
