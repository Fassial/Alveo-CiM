"""
Created on September 04 18:01, 2020

@author: fassial
"""
import numpy as np
# local dep
from cdboost import apply_cdboost

"""
fasthash_encode:
    fasthash encode
    @params:
        models(list)                : list of models
        feature(np.array)           : feature matrix
        n_bit(int)                  : limit of models
    @rets:
        feature_encode(np.array)    : feature encode matrix
"""
def fasthash_encode(models, feature, n_bit = -1):
    # set models
    if n_bit > 0: models = models[:n_bit]
    # get feature_encode
    feature_encode = _apply_hash_learner(
        models = models,
        feature = feature
    )
    feature_encode = (feature_encode > 0).astype(np.int8)
    return feature_encode

"""
_apply_hash_learner:
    apply hash learner
    @params:
        models(list)                : list of models
        feature(np.array)           : feature matrix
    @rets:
        feature_encode(np.array)    : feature encode matrix
"""
def _apply_hash_learner(models, feature):
    # temp support cdboost only
    feature_encode = apply_cdboost.apply_cdboost(
        models = models,
        feature = feature
    )
    return feature_encode
