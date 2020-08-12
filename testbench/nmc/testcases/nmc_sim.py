"""
Created on August 10 17:29, 2020

@author: fassial
"""
# local dep
import utils

# nmc params
N_NMC_CELL = 128
W = 32
ALU_KIND = 2    # 0: xnor, 1: mul, 2: xor
COUNT_THRES = 8

class NMC:

    def __init__(self, n_nmc_cell = N_NMC_CELL, w = W, alu_kind = ALU_KIND, count_thres = COUNT_THRES):
        # init params
        self.n_nmc_cell = n_nmc_cell
        self.w = w
        self.alu_kind = alu_kind
        self.count_thres = count_thres
        # set nmc content
        self._id     = [0 for _ in range(self.n_nmc_cell)]
        self.feature = [0 for _ in range(self.n_nmc_cell)]
        self.result  = [0 for _ in range(self.n_nmc_cell)]

    def write(self, nmc_wr_req):
        # get wr_req
        nmc_wraddr, nmc_wrdata = nmc_wr_req[0], nmc_wr_req[1]
        # write nmc
        self._id[nmc_wraddr]     = nmc_wrdata[0]
        self.feature[nmc_wraddr] = nmc_wrdata[1]
        self.result[nmc_wraddr]  = nmc_wrdata[2]

    def query(self, nmc_qr_req):
        # init nmc_qr_resp
        nmc_qr_resp = [0, 0]
        # get qr_req
        nmc_qraddr, nmc_qr_feature = nmc_qr_req[0], nmc_qr_req[1]
        # get ori_id
        ori_id = curr_id = self._id[nmc_qraddr]
        # init addr
        addr = nmc_qraddr
        # start query
        while curr_id == ori_id:
            # get feature
            curr_feature = self.feature[addr]
            # get count
            curr_count = utils.count_bit(
                data_i = utils.alu(
                    a_i = nmc_qr_feature,
                    b_i = curr_feature,
                    w = self.w,
                    alu_kind = self.alu_kind
                ),
                w = self.w
            )
            # check whether < count_thres
            if (curr_count < self.count_thres):
                nmc_qr_resp[0] = 1
                nmc_qr_resp[1] = self.result[addr]
                break
            # check whether reach the end
            if addr == self.n_nmc_cell - 1:
                nmc_qr_resp[0] = 0
                nmc_qr_resp[1] = 0
                break
            # get next entry
            addr += 1
            curr_id = self._id[addr]
        # return resp
        return nmc_qr_resp
