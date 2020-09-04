"""
Created on August 13 14:50, 2020

@author: fassial
"""
import numpy as np

class NMC:

    def __init__(self, ids, features, results, thres = 10):
        self.ids = ids
        self.features = features
        self.results = results
        self.thres = thres

    def query(self, _id, feature, _ord = 2):
        # get start index
        index = 0; count = 0
        for i in range(self.ids.shape[0]):
            if self.ids[i] == _id: break
            index += 1
        while index < self.ids.shape[0] and self.ids[index] == _id:
            # calculate dist_2
            dist = np.linalg.norm(
                self.features[index] - feature,
                ord = _ord
            ); count += 1
            if dist <= self.thres:
                res = (1, self.results[index], count)
                return res
            # update index
            index += 1
        return (0, 0, count)
