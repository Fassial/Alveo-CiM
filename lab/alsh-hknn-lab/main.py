"""
Created on August 03 18:00, 2020

@author: fassial
"""
import os
# local dep
import utils
from alsh import alsh

# dataset params
DATASET = os.path.join(".", "dataset")
N_DATASET = 1000
P_TRAIN = 0.7
# alsh params
N_HASHFUNCS = 4
K = 10

def main():
    x_train, y_train, x_test, y_test = \
        utils.load_dataset(dirpath = DATASET)
    # inst alsh
    alsh_inst = alsh(
        points = x_train[:int(N_DATASET*P_TRAIN)],
        labels = x_test[:int(N_DATASET*P_TRAIN)],
        n_hashfuncs = N_HASHFUNCS,
        k = K
    )

if __name__ == "__main__":
    main()
