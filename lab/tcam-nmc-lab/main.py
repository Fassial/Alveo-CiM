"""
Created on August 13 19:01, 2020

@author: fassial
"""
import os
import math
import random
import pickle
import numpy as np
from collections import Counter
# local dep
import utils
import tcam
import nmc

# params
N_FEATURE = 1024
N_RESULT = 8
CYCLE_L2 = 15   # include fetch data (15*n+2)
P_C = 0.3
POWER = -0.8
FIFO_DEPTH = 10
CYCLE_NMC_BUS = 91
CYCLE_TCAM = 52
# params for file
DATASET = os.path.join(".", "dataset")
TCAM_KEY_FILE = os.path.join(DATASET, "simple_aggregation_code_hw.csv")
TCAM_VALUE_FILE = os.path.join(DATASET, "simple_aggregation_label_hw.csv")
TCAM_QUERY_FILE = os.path.join(DATASET, "simple_test_code_hw.csv")
NMC_DATASET = os.path.join(DATASET, "data")
NMC_MEM_FILE = os.path.join(NMC_DATASET, "database", "database_hw.pkl")
NMC_QUERY_FILE = os.path.join(NMC_DATASET, "querybase")
QUERY_LABEL_FILE = os.path.join(NMC_QUERY_FILE, "simple_test_label_hw.csv")
NMC_QUERY_FEATURE_FILE = os.path.join(NMC_QUERY_FILE, "simple_query_feat_hw.csv")

def powerlaw_dist(tcam_qr_key, nmc_qr_feature, qr_label, power = -0.8):
    qr_label_array = qr_label.tolist()
    qr_label_counter = Counter(qr_label_array)
    qr_label_mc = qr_label_counter.most_common()
    # get max label number
    n_max = qr_label_mc[0][1]
    c = int(math.ceil(n_max * P_C))
    # init new key & feature
    tcam_qr_key_new, nmc_qr_feature_new = None, None
    # fill key & feature
    for i in range(len(qr_label_mc)):
        n_qr = math.ceil(c * ((i+1)**power))
        # get index
        index = np.argwhere(qr_label == qr_label_mc[i][0]).reshape((-1,))# ; print(index)
        if n_qr < len(index):
            # random sample
            index_idx = random.sample(range(0,len(index)), n_qr)
            index = np.array(index)[index_idx].tolist()# ; print("after:", index)
        tcam_qr_key_new = np.r_[tcam_qr_key_new, tcam_qr_key[index].reshape((-1,tcam_qr_key.shape[1]))] \
            if tcam_qr_key_new is not None else tcam_qr_key[index].reshape((-1,tcam_qr_key.shape[1]))
        nmc_qr_feature_new = np.r_[nmc_qr_feature_new, nmc_qr_feature[index].reshape((-1,nmc_qr_feature.shape[1]))] \
            if nmc_qr_feature_new is not None else nmc_qr_feature[index].reshape((-1,nmc_qr_feature.shape[1]))
    return (tcam_qr_key_new, nmc_qr_feature_new)

def get_dataset(power = -0.8):
    # get all data
    tcam_key = utils.load_data(TCAM_KEY_FILE); print(tcam_key.shape)
    tcam_value = utils.load_data(TCAM_VALUE_FILE); print(tcam_value.shape)
    tcam_qr_key = utils.load_data(TCAM_QUERY_FILE); print(tcam_qr_key.shape)
    qr_label = utils.load_data(QUERY_LABEL_FILE); print(qr_label.shape)
    nmc_qr_feature = utils.load_data(NMC_QUERY_FEATURE_FILE); print(nmc_qr_feature.shape)
    # get new query
    tcam_qr_key, nmc_qr_feature = powerlaw_dist(
        tcam_qr_key = tcam_qr_key,
        nmc_qr_feature = nmc_qr_feature,
        qr_label = qr_label,
        power = power
    ); print(tcam_qr_key.shape, nmc_qr_feature.shape)
    for i in range(nmc_qr_feature.shape[0]-1):
        for j in range(i+1, nmc_qr_feature.shape[0]):
            if (nmc_qr_feature[i] == nmc_qr_feature[j]).all(): print("Fail!"); break
    with open(NMC_MEM_FILE, "rb+") as f:
        nmc_mem = pickle.load(f)
    nmc_mem_id, nmc_mem_feature, nmc_mem_result = None, None, None
    for key in nmc_mem.keys():
        if np.array(nmc_mem[key]).shape[0] == 0: continue
        nmc_mem_id = np.r_[nmc_mem_id, np.full((nmc_mem[key].shape[0],), key)] if nmc_mem_id is not None else np.full((nmc_mem[key].shape[0],), key)
        nmc_mem_feature = np.r_[nmc_mem_feature, nmc_mem[key][:, 0:N_FEATURE]] if nmc_mem_feature is not None else nmc_mem[key][:, 0:N_FEATURE]
        nmc_mem_result = np.r_[nmc_mem_result, nmc_mem[key][:, N_FEATURE:N_FEATURE+N_RESULT]] if nmc_mem_result is not None else nmc_mem[key][:, N_FEATURE:N_FEATURE+N_RESULT]
    print(nmc_mem_id.shape, nmc_mem_feature.shape, nmc_mem_result.shape)
    return (tcam_key, tcam_value, tcam_qr_key, nmc_qr_feature, nmc_mem_id, nmc_mem_feature, nmc_mem_result)

def split_nmc_mem(nmc_mem_id, start_idx, target_len):
    split_idxs = []
    if target_len >= nmc_mem_id.shape[0]: return [start_idx+nmc_mem_id.shape[0]-1]
    curr_idx = target_len
    ori_id = nmc_mem_id[curr_idx]
    while nmc_mem_id[curr_idx] == ori_id:
        curr_idx -= 1
    # find the end
    split_idxs.append(curr_idx+start_idx)
    split_idxs.extend(split_nmc_mem(
        nmc_mem_id = nmc_mem_id[curr_idx:],
        start_idx = start_idx+curr_idx,
        target_len = target_len
    ))
    return split_idxs

def test_multimatch(prior = 2, power = POWER, n_nmc = 2):
    # get dataset
    tcam_key, tcam_value, tcam_qr_key, nmc_qr_feature, nmc_mem_id, nmc_mem_feature, nmc_mem_result = get_dataset(power = power)
    # get split indexes
    split_idxs = split_nmc_mem(
        nmc_mem_id = nmc_mem_id,
        start_idx = 0,
        target_len = nmc_mem_id.shape[0] // n_nmc
    ); print(split_idxs)
    split_idxs_plus1 = [(split_idxs[i]+1) for i in range(len(split_idxs)-1)]
    print(nmc_mem_id[split_idxs], nmc_mem_id[split_idxs_plus1])
    nmc_label = [0]; nmc_label.extend(nmc_mem_id[split_idxs_plus1].tolist()); print(nmc_label)
    # inst nmc & tcam
    tcam_inst = tcam.TCAM(
        words = tcam_key,
        mems = tcam_value,
        prior = prior
    )
    nmc_insts = []
    for i in range(len(split_idxs)):
        if i == 0: start_idx = 0
        else: start_idx = split_idxs[i-1]
        end_idx = split_idxs[i]
        nmc_inst = nmc.NMC(
            ids = nmc_mem_id[start_idx:end_idx],
            features = nmc_mem_feature[start_idx:end_idx],
            results = nmc_mem_result[start_idx:end_idx]
        ); nmc_insts.append(nmc_inst)
    # test tcam
    # test_tm = tcam_inst._ternary_match(np.array([1,1,1,1,0,0,0,0]), np.array([1,1,1,0,-1,-1,-1,-1])); print("test_tm:", test_tm)
    # init cycle
    n_cycle = 0; n_cycle += 28; n_cycle += 1; cycle_nmc = [[0,0] for _ in range(len(nmc_insts))]
    n_hit = 0; cycle_hit = 0; n_miss = 0
    # issue query
    cycle_qr = [0 for _ in range(tcam_qr_key.shape[0])]
    cycle_wait = [0 for _ in range(tcam_qr_key.shape[0])]
    for i in range(tcam_qr_key.shape[0]):
        # if i % 100 == 0: print("cycle:", i)
        # get buffer
        buffer = tcam_inst.query(
            word = tcam_qr_key[i]
        )
        if buffer.shape[0] == 0:
            n_miss += 1
            if n_miss >= 16: print("n_miss:", n_miss)
            continue
        # hit
        n_hit += 1; n_miss = 0
        # get cycle_wait
        start_idx = i-FIFO_DEPTH+1
        if start_idx < 0: start_idx = 0
        for j in range(start_idx, i):
            cycle_wait[i] += cycle_qr[j]
        # issue buffer
        for j in range(buffer.shape[0]):
            # get corresponding idx
            _id = buffer[j]
            nmc_inst_idx = 0
            if len(nmc_label) > 1:
                while _id >= nmc_label[nmc_inst_idx+1]:
                    nmc_inst_idx += 1
                    if nmc_inst_idx == len(nmc_label)-1: break
            # get results
            res = nmc_insts[nmc_inst_idx].query(
                _id = buffer[j],
                feature = nmc_qr_feature[i]
            )
            # n_cycle += CYCLE_L2*res[2] + CYCLE_NMC_BUS + 2
            # cycle_hit += CYCLE_L2*res[2] + CYCLE_NMC_BUS + 2
            cycle_qr[i] += CYCLE_L2*res[2] + CYCLE_NMC_BUS + 2
            cycle_nmc[nmc_inst_idx][0] += CYCLE_NMC_BUS
            cycle_nmc[nmc_inst_idx][1] += CYCLE_L2*res[2] + 2
            if res[0] == 1: break
    cycle_nmc_sum = [(nmc_inst_cycle[0]+(nmc_inst_cycle[1])) for nmc_inst_cycle in cycle_nmc]; cycle_nmc_max_idx = np.argmax(cycle_nmc_sum)
    n_io, n_process = cycle_nmc[cycle_nmc_max_idx]
    return n_cycle, n_hit, cycle_hit, n_io, n_process

def convert():
    res = utils.load_data(
        filename = "result.csv"
    ).T# ; print(res)
    expr_label = res[:2, :]# ; print(expr_label)
    n_req = res[3, :]
    cycle_req_nmc = res[4, :]
    cycle_avg_nmc = cycle_req_nmc / n_req
    cycle_req_nmc_mod = (cycle_avg_nmc + 90) * n_req; print(n_req, cycle_req_nmc_mod)
    cycle_throughoutput = cycle_req_nmc_mod / n_req
    cycle_latency = cycle_req_nmc_mod * (2*FIFO_DEPTH-1) / n_req + CYCLE_TCAM
    print(cycle_req_nmc_mod, cycle_latency)
    res = np.r_[expr_label, cycle_req_nmc_mod.reshape((-1,expr_label.shape[1])), cycle_throughoutput.reshape((-1,expr_label.shape[1])), cycle_latency.reshape((-1,expr_label.shape[1]))]
    utils.store_data(
        filename = "convert.csv",
        src = res.T.astype(np.float32),
        fmt = "%.2f"
    )

def main():
    # power_lst = [0, -0.1, -0.2, -0.3, -0.4, -0.5, -0.6, -0.7, -0.8, -0.9]
    power_lst = [0]
    n_nmc_lst = [1]
    prior_lst = [1, 2, 3, 4, 5]
    for prior in prior_lst:
        for n_nmc in n_nmc_lst:
            for power in power_lst:
                n_cycle, n_hit, cycle_hit, n_io, n_process = test_multimatch(
                    prior = prior,
                    power = power,
                    n_nmc = n_nmc
                ); print(n_nmc, power, prior, n_cycle, n_hit, cycle_hit, n_io, n_process)

if __name__ == "__main__":
    main()
    # convert()
