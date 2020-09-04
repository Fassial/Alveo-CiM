"""
Created on September 04 18:18, 2020

@author: fassial
"""
import numpy as np
# local dep
from . import cdboost_predict

"""
apply_cdboost:
    apply cdboost
    @params:
        models(list)                : list of models
        feature(np.array)           : feature matrix
    @rets:
        feature_encode(np.array)    : feature encode matrix
"""
def apply_cdboost(models, feature):
    # get n_feature & n_bit
    n_bit = len(models)
    n_feature = feature.shape[0]
    # init feature_encode
    feature_encode = np.zeros((n_feature, n_bit))
    # set bit
    for i in range(n_bit):
        # get model
        model = models[i]
        # predict
        pred_res = cdboost_predict.cdboost_predict(
            model = model,
            feature = feature,
            display = False     # (i == 1)
        )
        feature_encode_bit = (pred_res["predict_labels"] > 0).astype(np.int8)
        feature_encode[:, i] = feature_encode_bit
    return feature_encode