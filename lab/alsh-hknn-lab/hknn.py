"""
Created on August 01 10:02, 2020

@author: fassial
"""
import math
import numpy as np
from collections import Counter

class hknn:
    """
    Homogenized kNN proposed in FoggyCache, MobiCom
    """

    def __init__(self, points, values, k, theta0):
        """
        Init paramas of hknn.
        Parameters:
        -----------
        points : :py.class`ndarray <numpy.ndarray>` of shape `(n_point, n_feature)`
            the data set to query
        values : :py.class`ndarray <numpy.ndarray>` of shape `(n_point, n_value)`
            the value of the data set
        k : int
            the length of neighborhoodList
        theta0 : float
            the threshold of theta
        Returns:
        --------
        None
        """
        # set dataset
        self.points = points
        self.values = values
        # set hknn params
        self.k = k
        self.theta0 = theta0

    def _get_kNNL(self, query, _ord = 2):
        """
        Get the k nearest neighborhood list of query point. Actually, 
        k is smaller than self.k, because we remove the outliers from 
        the k records initially chosen.
        Parameters:
        -----------
        query : :py.class`ndarray <numpy.ndarray>` of shape `(n_feature, )`
            query point
        _ord : int, default 2
            use `L(_ord)`-distance to measure relation
        Returns:
        --------
        kNNI : :py.class`ndarray <numpy.ndarray>` of shape `(k', )`
            the k'(k' < k) nearest neighborhood index of query point
        """
        # get the dist between points and query point
        dist = np.zeros((self.points.shape[0], ))
        for i in range(dist.shape[0]):
            dist[i] = np.linalg.norm(
                query - self.points[i],
                ord = _ord
            )
        # sort dist
        k_index = np.argsort(dist)[:self.k]
        # get mean(D_k), then get kNNI
        kNNI = k_index[dist[k_index] < np.mean(dist[k_index])]
        return kNNI

    def _get_Nmax(self, kNNI):
        """
        Get the value of Nmax.
        Parameters:
        -----------
        kNNI : :py.class`ndarray <numpy.ndarray>` of shape `(k', )`
            the k'(k' < k) nearest neighborhood index of query point
        Returns:
        --------
        Nmax : :py.class`ndarray <numpy.ndarray>` of shape `(n_value, )`
            the value of Nmax
        """
        # get tuple list
        kNNV = self.values[kNNI]
        _kNNV = kNNV.tolist()
        for i in range(len(_kNNV)):
            _kNNV[i] = tuple(_kNNV[i])
        N = Counter(_kNNV)
        Nmax = N.most_common(1)[0]
        # get theta
        theta = Nmax[1] / math.sqrt(sum(np.array(list(N.values()))**2))
        if theta > self.theta0:
            # get Nmax index
            NmaxII = []
            for i in range(kNNV.shape[0]): NmaxII.append((kNNV[i] == Nmax[0]).all())
            NmaxII = np.array(NmaxII)
            NmaxI = kNNI[NmaxII]
            return self.values[NmaxI[0]]
        else:
            return None

    def predict(self, query, _ord = 2):
        """
        Predict the value of query point.
        Parameters:
        -----------
        query : :py.class`ndarray <numpy.ndarray>` of shape `(n_feature, )`
            query point
        _ord : int, default 2
            use `L(_ord)`-distance to measure relation
        Returns:
        --------
        value : :py.class`ndarray <numpy.ndarray>` of shape `(n_value, )`
            the predict value of query point
        """
        # get kNNI
        kNNI = self._get_kNNL(
            query = query,
            _ord = _ord
        )
        # get value of Nmax
        return self._get_Nmax(
            kNNI = kNNI
        )

# test params
N_POINT = 100
N_FEATURE = 5
N_VALUE = 4
N_CLUSTER = 15
# hknn params
K = 10
THETA0 = 0.8

def test():
    # init points & values
    points = np.array([[i]*N_FEATURE for i in range(N_POINT)])
    values = np.array([[i // N_CLUSTER]*N_VALUE for i in range(N_POINT)])
    # get hknn
    hknn_inst = hknn(
        points = points,
        values = values,
        k = K,
        theta0 = THETA0
    )
    # init query
    query = np.array([14]*N_FEATURE)
    res = hknn_inst.predict(query)
    print(res)

if __name__ == "__main__":
    test()
