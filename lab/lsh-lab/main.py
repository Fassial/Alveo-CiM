"""
Created on August 06 15:20, 2020

@author: fassial
"""
import os
import timeit
import numpy as np
# local dep
import utils
from lsh import lshash

# file loc params
PREFIX = ".."
# dataset & testdataset
DATASET = os.path.join(PREFIX, "dataset")
PREDATASET = os.path.join(PREFIX, "predataset")
# eval dir
EVAL_DIR = os.path.join(".", "eval")
SCORE_FILE = os.path.join(EVAL_DIR, "scores.csv")
# lsh params
W = 8
DISTANCE_FUNCS = ["hamming", "euclidean", "true_euclidean", \
    "centred_euclidean", "cosine", "l1norm"]
# ptopK params
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
    # init lsh
    lsh_inst = lshash.LSHash(
        hash_size = W,
        input_dim = x_train.shape[1]
    )
    # set dataset
    print("start build_index...")
    for i in range(x_train.shape[0]):
        lsh_inst.index(
            input_point = x_train[i],
            extra_data = str(int(y_train[i]))
        )
    print("complete build_index")
    # get query result
    print("start nn_index...")
    buckets = []
    for i in range(x_test.shape[0]):
        bucket = lsh_inst.query(
            query_point = x_test[i]
        )# ; print(bucket[0][0][1])
        buckets.append([int(point[0][1]) for point in bucket])
    buckets = np.array(buckets)
    print("complete nn_index")
    # calculate P & n_match
    P = 0
    n_match = np.zeros((y_test.shape[0],))
    print("start calculate p...")
    for i in range(buckets.shape[0]):
        label = y_train[buckets[i]]
        n_match[i] = np.sum(label == y_test[i])
        # P += 1 if n_match[i] > 0 else 0 
        P += n_match[i] / label.shape[0]
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
    P /= buckets.shape[0]
    return P

"""
main:
    main func
"""
def main():
    # set start_time
    start_time = timeit.default_timer()
    # get trainset & testset
    # x_train, y_train, x_test, y_test = utils.load_dataset(dirpath = PREDATASET); print(x_train.shape, y_train.shape, x_test.shape, y_test.shape)
    x_train, y_train, x_test, y_test = utils.load_dataset(dirpath = DATASET); print(x_train.shape, y_train.shape, x_test.shape, y_test.shape)
    # remap x_train, x_test
    x_train_max, x_test_max = np.max(x_train), np.max(x_test)
    x_max = max(x_train_max, x_test_max)
    x_train_remap = utils.remap(x_train, (0, 2**W-1), x_max).astype(np.uint8); print(x_train_remap.shape, x_train_remap.dtype)
    x_test_remap = utils.remap(x_test, (0, 2**W-1), x_max).astype(np.uint8); print(x_test_remap.shape, x_test_remap.dtype)
    # get ptopK
    p = ptopK(
        x_train = x_train_remap,
        y_train = y_train,
        x_test = x_test_remap,
        y_test = y_test,
        k = K
    )
    print("ptopK: %.2f%%" % (p*100))
    # set end_time
    end_time = timeit.default_timer()
    print("main runs for %.1fs" % (end_time-start_time))

if __name__ == "__main__":
    main()
