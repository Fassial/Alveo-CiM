"""
Created on August 03 18:00, 2020

@author: fassial
"""
import os
import timeit
# local dep
import utils
from alsh import alsh

# dataset params
DATASET = os.path.join(".", "dataset")
N_DATASET = 5000
P_TRAIN = 0.7
# alsh params
N_HASHFUNCS = 32
K = 10

def main():
    # get dataset
    x_train, y_train, x_test, y_test = \
        utils.load_dataset(dirpath = DATASET)
    # inst alsh
    start_time = timeit.default_timer()
    alsh_inst = alsh(
        points = x_train[:int(N_DATASET*P_TRAIN)],
        labels = x_test[:int(N_DATASET*P_TRAIN)],
        n_hashfuncs = N_HASHFUNCS,
        k = K
    )
    end_time = timeit.default_timer()
    print("init alsh runs for %.1fs" % (end_time - start_time))
    # get scores
    start_time = timeit.default_timer()
    scores = alsh_inst.get_score(
        querys = x_test,
        labels = y_test,
        op = "and"
    )
    print(scores)
    end_time = timeit.default_timer()
    print("get score runs for %.1fs" % (end_time - start_time))

if __name__ == "__main__":
    main()