"""
Created on September 04 18:34, 2020

@author: fassial
"""
import numpy as np

"""
cdboost_predict:
    cdboost predict
    @params:
        model(dict)         : dict of model
        feature(np.array)   : feature matrix
    @rets:
        res(np.array)       : pred res matrix
"""
def cdboost_predict(model, feature, display):
    # get model attr
    w = model["w"]
    tree_models = model["tree_models"]
    sel_feat_idxes = model["sel_feat_idxes"]
    # get n_iter & n_feature
    n_iter = w.shape[0]
    n_feature = feature.shape[0]
    # get sel_feat_idxes feature
    if sel_feat_idxes.shape[0] != 0: feature = feature[:, sel_feat_idxes.tolist()]

    # init res
    res = dict()
    predict_scores = np.zeros((n_feature,))
    # iter tree_models
    for i in range(n_iter):
        tree_model = tree_models[i]
        h_feature = _apply_wl_bit(
            tree_model = tree_model,
            feature = feature,
            debug = display
        )
        scores_bit = h_feature * w[i]
        predict_scores += scores_bit
    predict_labels = (predict_scores >= 0).astype(np.int8)
    predict_labels[predict_labels==0] = -1
    # set res
    res["predict_scores"] = predict_scores
    res["predict_labels"] = predict_labels
    return res

"""
_apply_wl_bit:
    apply_wl_bit
    @params:
        tree_model(dict)    : dict of tree_model
        feature(np.array)   : feature matrix
    @rets:
        h_feature(np.array) : h_feature
"""
def _apply_wl_bit(tree_model, feature, debug):
    sel_feat_idxes = tree_model["sel_feat_idxes"]
    if sel_feat_idxes.shape[0] != 0: feature = feature[:, sel_feat_idxes.tolist()]
    # get h_feature
    h_feature = _binary_tree_apply(tree_model, feature, debug)
    # nonzerosign
    h_feature = (h_feature >= 0).astype(np.int8)
    h_feature[h_feature==0] = -1
    return h_feature

"""
_binary_tree_apply:
    binary tree apply
    @params:
        tree_model(dict)    : learned tree classification model
        feature(np.array)   : [NxF] N length F feature vectors
        max_depth(int)      : maximum depth of tree
        min_weight(int)     : minimum sample weigth to allow split
        n_thread(int)       : max number of computational threads to use
    @rets:
        hs(np.array)        : hs
"""
def _binary_tree_apply(tree_model, feature, debug, max_depth = 0, min_weight = 0, n_thread = 1e5):
    # set tree
    if (max_depth > 0): tree_model["child"][tree_model["depth"] >= max_depth] = 0
    if (min_weight > 0): tree_model["child"][tree_model["weights"] <= min_weight] = 0
    hs = tree_model["hs"][_forest_inds(
        tree_model = tree_model,
        feature = feature,
        n_thread = n_thread
    )]
    if debug: print(hs.tolist(), _forest_inds(
        tree_model = tree_model,
        feature = feature,
        n_thread = n_thread
    ))
    return hs

"""
_forest_inds:
    forest inds
    @params:
        tree_model(dict)    : learned tree classification model
        feature(np.array)   : [NxF] N length F feature vectors
        n_thread(int)       : max number of computational threads to use
    @rets:
        inds(list)          : inds
"""
def _forest_inds(tree_model, feature, n_thread = 1e5):
    # get tree_model attr
    child = tree_model["child"].astype(np.int32)
    fids = tree_model["fids"].astype(np.int32)
    thrs = tree_model["thrs"].astype(np.int32)
    # get n_feature
    n_feature = feature.shape[0]
    # init inds
    inds = [0 for _ in range(n_feature)]
    for i in range(n_feature):
        k = 0
        while (child[k]):
            if (feature[i, fids[k]] < thrs[k]):
                k = child[k]-1
            else:
                k = child[k]
        inds[i] = k
    return inds
