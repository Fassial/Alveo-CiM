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
# remap params
W = 8
# lsh params
HASH_SIZE = 64
N_HASHTABLES = 16
DISTANCE_FUNCS = ["hamming", "euclidean", "true_euclidean", \
    "centred_euclidean", "cosine", "l1norm"]
# test params
K = 10

"""
ptopN:
    calculate accuracy of dist-classifier based on RENE-encode
    @params:
        x_train(np.array)   : feature of trainset
        y_train(np.array)   : label of trainset
        x_test(np.array)    : feature of testset
        y_test(np.array)    : label of testset
        k(int)              : the number of top
        _ord(int)           : use `L(_ord)`-distance to measure relation
    @rets:
        P(float)            : accuracy of classifier
"""
def ptopK(x_train, y_train, x_test, y_test, k = K, n_hashtables = N_HASHTABLES, hash_size = HASH_SIZE, _ord = 2):
    # init lsh
    lsh_inst = lshash.LSHash(
        hash_size = hash_size,
        input_dim = x_train.shape[1],
        num_hashtables = n_hashtables
    )
    # set dataset
    # print("start build_index...")
    lsh_inst.index(
        input_point = x_train
    )
    lsh_buckets = lsh_inst.get_buckets(); print("lsh_buckets:", lsh_buckets)
    # print("complete build_index")
    # get query result
    # print("start nn_index...")
    buckets, bucket_size = [], []
    for i in range(x_test.shape[0]):
        # if i % 100 == 0: print("cycle:", i)
        bucket = lsh_inst.query(
            query_point = x_test[i]
        )
        buckets.append(bucket); bucket_size.append(len(bucket))
    buckets = np.array(buckets)
    utils.store_data(
        filename = "bucket-size.csv",
        src = bucket_size
    )
    # print("complete nn_index")
    # calculate P & n_match
    P = 0
    n_match = np.zeros((y_test.shape[0],))
    # print("start calculate p...")
    for i in range(buckets.shape[0]):
        # if i % 100 == 0: print("cycle:", i)
        index = list(buckets[i])# ; print(len(index))
        feature, label = x_train[index], y_train[index]
        if label.shape[0] > k:
            # get dist
            dist = np.zeros((label.shape[0], ))
            for j in range(dist.shape[0]):
                dist[j] = np.linalg.norm(
                    x_test[i] - feature[j],
                    ord = _ord
                )
            # sort dist
            k_index = np.argsort(dist)[:k]
            index = np.array(index)[k_index].tolist()
            # get corresponding label
            label = y_train[index]
            n_match[i] = np.sum(label == y_test[i])
            P += 1 if n_match[i] >= 1 else 0
        elif label.shape[0] > 0:
            n_match[i] = np.sum(label == y_test[i])
            P += 1 if n_match[i] >= 1 else 0
    # print("complete calculate p")
    print(n_match)
    # print("start save n_match...")
    if not os.path.exists(EVAL_DIR): os.mkdir(EVAL_DIR)
    if os.path.exists(SCORE_FILE): os.remove(SCORE_FILE)
    utils.store_data(
        filename = SCORE_FILE,
        src = n_match
    )
    # print("complete save n_match")
    P /= buckets.shape[0]
    print(n_hashtables, hash_size, P, np.mean(bucket_size))
    return P

"""
main:
    main func
"""
def main():
    # set start_time
    start_time = timeit.default_timer()
    # get trainset & testset
    x_train, y_train, x_test, y_test = utils.load_dataset(dirpath = PREDATASET); print(x_train.shape, y_train.shape, x_test.shape, y_test.shape)
    # x_train, y_train, x_test, y_test = utils.load_dataset(dirpath = DATASET); print(x_train.shape, y_train.shape, x_test.shape, y_test.shape)
    # remap x_train, x_test
    x_train_max, x_test_max = np.max(x_train), np.max(x_test)
    x_max = max(x_train_max, x_test_max)
    # x_train_remap = utils.remap(x_train, (0, 2**W-1), x_max).astype(np.uint8); print(x_train_remap.shape, x_train_remap.dtype)
    # x_test_remap = utils.remap(x_test, (0, 2**W-1), x_max).astype(np.uint8); print(x_test_remap.shape, x_test_remap.dtype)
    x_train_remap = x_train
    x_test_remap = x_test
    n_hashtables_lst = [N_HASHTABLES]# [2,4,6,8,10,12,14,16]
    hash_size_lst = [HASH_SIZE]# [56,64,72,80,88,96,104,112,120,128]
    for n_hashtables in n_hashtables_lst:
        for hash_size in hash_size_lst:
            # get ptopK
            p = ptopK(
                x_train = x_train_remap,
                y_train = y_train,
                x_test = x_test_remap,
                y_test = y_test,
                k = K,
                n_hashtables = n_hashtables,
                hash_size = hash_size
            )
    # print("ptopK: %.2f%%" % (p*100))
    # set end_time
    end_time = timeit.default_timer()
    print("main runs for %.1fs" % (end_time-start_time))

if __name__ == "__main__":
    main()
