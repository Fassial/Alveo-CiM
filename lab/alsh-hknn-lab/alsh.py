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
    OP = ["or", "and"]

    def __init__(self, points, labels, n_hashfuncs, k, _ord = 2):
        """
        Init paramas of alsh.
        Parameters:
        -----------
        points : :py.class`ndarray <numpy.ndarray>` of shape `(n_points, n_features)`
            the data set to query
        labels : :py.class`ndarray <numpy.ndarray>` of shape `(n_points, )`
            the labels of the data set to query
        n_hashfuncs: int
            the number of hash funcs in the same hash family
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
        self.labels = labels
        # set alsh params
        self.k = k
        self._ord = _ord
        # set matrix params
        self.n_features = self.points.shape[1]
        self.n_hashfuncs = n_hashfuncs
        self.a = np.random.rand(self.n_hashfuncs, self.n_features)
        self.b = np.random.rand(self.n_hashfuncs)
        # get adaptive params
        self.c = self._get_c()
        self.r = self._get_r()
        # get buckets (<becket_id> -> [idxs of points])
        self.buckets = self._get_buckets()

    def update_ab(self, a, b):
        """
        Update a & b paramas of alsh.
        Parameters:
        -----------
        a : :py.class`ndarray <numpy.ndarray>` of shape `(n_hashfuncs, n_features)`
            the weights of hashfunc
        b : :py.class`ndarray <numpy.ndarray>` of shape `(n_hashfuncs, )`
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
        # method of minimize
        # - 'Nelder-Mead' :ref:`(see here) <optimize.minimize-neldermead>`
        # - 'Powell'      :ref:`(see here) <optimize.minimize-powell>`
        # - 'CG'          :ref:`(see here) <optimize.minimize-cg>`
        # - 'BFGS'        :ref:`(see here) <optimize.minimize-bfgs>`
        # - 'Newton-CG'   :ref:`(see here) <optimize.minimize-newtoncg>`
        # - 'L-BFGS-B'    :ref:`(see here) <optimize.minimize-lbfgsb>`
        # - 'TNC'         :ref:`(see here) <optimize.minimize-tnc>`
        # - 'COBYLA'      :ref:`(see here) <optimize.minimize-cobyla>`
        # - 'SLSQP'       :ref:`(see here) <optimize.minimize-slsqp>`
        # - 'trust-constr':ref:`(see here) <optimize.minimize-trustconstr>`
        # - 'dogleg'      :ref:`(see here) <optimize.minimize-dogleg>`
        # - 'trust-ncg'   :ref:`(see here) <optimize.minimize-trustncg>`
        # - 'trust-exact' :ref:`(see here) <optimize.minimize-trustexact>`
        # - 'trust-krylov':ref:`(see here) <optimize.minimize-trustkrylov>`
        # - custom - a callable object (added in version 0.14.0)
        res = minimize(
            fun = self._rho_r,
            x0 = r0
        )
        # get corresponding r
        r = res.x[0]; print("r:", r)
        return r

    def forward(self, query):
        """
        Get the bucket(np.array) of query point.
        Parameters:
        -----------
        query : :py.class`ndarray <numpy.ndarray>` of shape `(n_features, )`
            query point
        Returns:
        --------
        bucket : :py.class`ndarray <numpy.ndarray>` of shape `(n_hashfuncs, )`
            the bucket of query point
        """
        # get h_v
        h_v = np.floor((self.a.dot(query) + self.b) / self.r)
        return h_v.astype(np.int32)

    def _get_key(self, bucket, mask):
        """
        Get the key(str) of bucket & mask.
        Parameters:
        -----------
        bucket : :py.class`ndarray <numpy.ndarray>` of shape `(n_hashfuncs, )`
            the encode of bucket
        mask : :py.class`ndarray <numpy.ndarray>` of shape `(n_hashfuncs, )`
            the mask of bucket with zeros and ones
        Returns:
        --------
        key : str
            the key(str) of bucket & mask
        """
        key = ""
        for i in range(bucket.shape[0]):
            if mask[i] != 0: key += str(bucket[i])
            else: key += "*"
            if i != bucket.shape[0]-1: key += "-"
        return key

    def _get_buckets(self):
        """
        Get the buckets of hashtable(temp only one table).
        Buckets are orginized like:
            {
                "0-0": [0],
                "0-1": [1],
                "1-0": [2],
                "1-1": [3],
                "*-0": [0, 2],
                "*-1": [1, 3],
                "0-*": [0, 1],
                "1-*": [2, 3],
                "*-*": [0, 1, 2, 3],
                ...
            }
        Remember: key is not limited in [0, 1], N
        Parameters:
        -----------
        None
        Returns:
        --------
        buckets : dict
            the buckets of hashtable
        """
        buckets = dict()
        for i in range(self.points.shape[0]):
            if i % 100 == 0: print("processing", str(i), "th points")
            # get the original bucket
            ori_bucket = self.forward(
                query = self.points[i]
            )
            # update buckets
            # for _and
            mask = np.ones(ori_bucket.shape)
            key = self._get_key(ori_bucket, mask)
            # insert into buckets
            if buckets.__contains__(key): buckets[key].append(i)
            else: buckets[key] = [i]
            # for _or
            mask = np.zeros(ori_bucket.shape)
            for j in range(mask.shape[0]):
                mask[j] = 1
                key = self._get_key(ori_bucket, mask)
                # insert into buckets
                if buckets.__contains__(key): buckets[key].append(i)
                else: buckets[key] = [i]
                mask[j] = 0
        print(buckets.keys())
        return buckets

    def predict(self, query, op = "or"):
        """
        Get the bucket(np.array) of query point.
        Parameters:
        -----------
        query : :py.class`ndarray <numpy.ndarray>` of shape `(n_features, )`
            query point
        op : str, {`or`, `and`}
            query op
        Returns:
        --------
        bucket : list
            the bucket(list) of query point
        """
        bucket = []
        if op not in alsh.OP: return bucket
        # get original bucket
        ori_bucket = self.forward(
            query = query
        )
        # update buckets
        # for _and
        mask = np.ones(ori_bucket.shape)
        key = self._get_key(ori_bucket, mask)
        # extend bucket
        if self.buckets.__contains__(key): bucket.extend(self.buckets[key])
        # end _and
        if op == "and": return set(bucket)
        # for _or
        mask = np.zeros(ori_bucket.shape)
        for j in range(mask.shape[0]):
            mask[j] = 1
            key = self._get_key(ori_bucket, mask)
            # insert into buckets
            if self.buckets.__contains__(key): bucket.extend(self.buckets[key])
            mask[j] = 0
        if op == "or": return set(bucket)
        return []

# test params
N_POINTS = 100
N_FEATURES = 5
N_HASHFUNCS = 4
# alsh params
K = 10

def test():
    # init points & a & b
    points = np.array([[i]*N_FEATURES for i in range(N_POINTS)])
    labels = np.array([(i//10) for i in range(N_POINTS)])
    # inst alsh
    alsh_inst = alsh(
        points = points,
        labels = labels,
        n_hashfuncs = N_HASHFUNCS,
        k = K
    )
    # init query
    query = np.array([100]*N_FEATURES)
    res = alsh_inst.predict(query)
    print(res)

if __name__ == "__main__":
    test()
