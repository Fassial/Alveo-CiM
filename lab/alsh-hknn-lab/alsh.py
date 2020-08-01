"""
Created on August 01 12:10, 2020

@author: fassial
"""
import math
import numpy as np
from scipy.stats import norm
from scipy.optimize import minimize

class alsh:
    """
    Adaptive LSH proposed in FoggyCache, MobiCom
    """

    def __init__(self, points, a, b, k, _ord = 2):
        """
        Init paramas of alsh.
        Parameters:
        -----------
        points : :py.class`ndarray <numpy.ndarray>` of shape `(n_point, n_feature)`
            the data set to query
        a : :py.class`ndarray <numpy.ndarray>` of shape `(n_hashfunc, n_feature)`
            the weights of hashfunc
        b : :py.class`ndarray <numpy.ndarray>` of shape `(n_hashfunc, )`
            the biases of hashfunc
        k : int
            the length of neighborhoodList
        _ord : int, default 2
            use `L(_ord)`-distance to measure relation
        Returns:
        --------
        None
        """
        # set dataset
        self.points = points
        # set alsh params
        self.a = a
        self.b = b
        self.k = k
        self._ord = _ord
        # get adaptive params
        self.c = self._get_c()
        self.r = self._get_r()

    def update_ab(self, a, b):
        """
        Update a & b paramas of alsh.
        Parameters:
        -----------
        a : :py.class`ndarray <numpy.ndarray>` of shape `(n_hashfunc, n_feature)`
            the weights of hashfunc
        b : :py.class`ndarray <numpy.ndarray>` of shape `(n_hashfunc, )`
            the biases of hashfunc
        Returns:
        --------
        None
        """
        # set alsh params
        self.a = a
        self.b = b

    def _get_meanDk(self, query):
        """
        Get the mean distance of query point's k nearest neighborhood list. 
        Actually, we choose [1:self.k+1] nearest neighbor for query point is 
        in self.points.
        Parameters:
        -----------
        query : :py.class`ndarray <numpy.ndarray>` of shape `(n_feature, )`
            query point
        Returns:
        --------
        meanDk :float
            the k'(k' < k) nearest neighborhood index of query point
        """
        # get the dist between points and query point
        dist = np.zeros((self.points.shape[0], ))
        for i in range(dist.shape[0]):
            dist[i] = np.linalg.norm(
                query - self.points[i],
                ord = self._ord
            )
        # sort dist, ignore itself
        k_index = np.argsort(dist)[1:self.k+1]
        # get mean(D_k), then get kNNI
        meanDk = np.float(np.mean(dist[k_index]))
        return meanDk

    def _get_c(self):
        """
        Get the adaptive param c of alsh.
        Parameters:
        -----------
        None
        Returns:
        --------
        c :float
            the adaptive param c of alsh
        """
        # get meanDks
        meanDks = []
        for i in range(self.points.shape[0]):
            meanDks.append(self._get_meanDk(
                query = self.points[i]
            ))
        # sort meanDks
        list.sort(meanDks)
        # c = min(5 * mean(meanDks), 95%th meanDk)
        c = min(5 * np.mean(meanDks), meanDks[int(len(meanDks)*0.95)])
        return c

    def _p_r(self, r):
        """
        Get the p(r) value of r.
        Parameters:
        -----------
        r : float
            r param of p(r)
        Returns:
        --------
        pr : float
            the p(r) value of r
        """
        # set c
        c = self.c
        # get pr
        pr = 1 - 2*norm.cdf(-r/c) - (2/(math.sqrt(2*math.pi)*r/c))*(1-pow(math.e, -(r**2/(2*(c**2)))))
        return pr

    def _rho_r(self, r):
        """
        Get the rho(r) value of r.
        Parameters:
        -----------
        r : float
            r param of rho(r)
        Returns:
        --------
        rhor : float
            the rho(r) value of r
        """
        rhor = math.log(
            # x
            self._p_r(
                r = r
            ),
            # base
            self._p_r(
                r = 1
            )
        )
        return rhor

    def _get_r(self, r0 = 10):
        """
        Get the adaptive param r of alsh.
        Parameters:
        -----------
        None
        Returns:
        --------
        r :float
            the adaptive param r of alsh
        """
        # minimize target func
        res = minimize(
            fun = self._rho_r,
            x0 = r0,
            method='SLSQP'
        )
        # get corresponding r
        r = res.x[0]
        return r

    def predict(self, query):
        """
        Predict the bucket of query point.
        Parameters:
        -----------
        query : :py.class`ndarray <numpy.ndarray>` of shape `(n_feature, )`
            query point
        Returns:
        --------
        bucket : :py.class`ndarray <numpy.ndarray>` of shape `(n_hashfunc, )`
            the bucket of query point
        """
        # get h_v
        h_v = np.floor((self.a.dot(query) + self.b) / self.r)
        return h_v.astype(np.int32)

# test params
N_POINT = 100
N_FEATURE = 5
N_HASHFUNC = 4
# alsh params
K = 10

def test():
    # init points & a & b
    points = np.array([[i]*N_FEATURE for i in range(N_POINT)])
    a = np.array([[i*N_FEATURE+j for j in range(N_FEATURE)] for i in range(N_HASHFUNC)])
    b = np.array([-i for i in range(N_HASHFUNC)])
    # inst alsh
    alsh_inst = alsh(
        points = points,
        a = a,
        b = b,
        k = K
    )
    # init query
    query = np.array([14]*N_FEATURE)
    res = alsh_inst.predict(query)
    print(res)

if __name__ == "__main__":
    test()
