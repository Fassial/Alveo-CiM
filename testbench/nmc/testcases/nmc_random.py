"""
Created on August 10 19:24, 2020

@author: fassial
"""
import random
# local dep
from nmc_sim import NMC

# nmc params
N_NMC_CELL = 128
W = 32
ALU_KIND = 2    # 0: xnor, 1: mul, 2: xor
COUNT_THRES = 8
# n_req & req_file & ans_file
N_REQ = 1000
REQ_FILE = "nmc_random.req"
ANS_FILE = "nmc_random.ans"
P_WR = 0.2

def main():
    # open file
    req_file = open(REQ_FILE, "w")
    ans_file = open(ANS_FILE, "w")
    # init nmc
    nmc_inst = NMC(
        n_nmc_cell = N_NMC_CELL,
        w = W,
        alu_kind = ALU_KIND,
        count_thres = COUNT_THRES
    )
    # gen req
    for i in range(N_REQ):
        # 1: qr, 0: wr
        req_type = 1 if random.random() > P_WR else 0
        if req_type == 1:
            # qr_req
            nmc_qraddr, nmc_qr_feature = random.randint(0,N_NMC_CELL-1), random.randint(0,2**W)
            nmc_qr_req = (nmc_qraddr, nmc_qr_feature)
            # write req into req_file
            req_form = "0 000 000000000000000000 1 0%02x %08x\n"
            req_str = req_form % (nmc_qraddr, nmc_qr_feature)
            req_file.write(req_str)
            # get nmc_qr_resp
            nmc_qr_resp = nmc_inst.query(
                nmc_qr_req = nmc_qr_req
            )
            # write resp into ans_file
            ans_form = "%01x-%08x\n"
            ans_str = ans_form % (nmc_qr_resp[0], nmc_qr_resp[1])
            ans_file.write(ans_str)
        elif req_type == 0:
            # wr_req
            nmc_wraddr = random.randint(0,N_NMC_CELL-1)
            nmc_wr_id = random.randint(0,N_NMC_CELL-1)
            nmc_wr_feature = random.randint(0,2**W)
            nmc_wr_result = random.randint(0,2**W)
            nmc_wrdata = (nmc_wr_id, nmc_wr_feature, nmc_wr_result)
            nmc_wr_req = (nmc_wraddr, nmc_wrdata)
            # write req into req_file
            req_form = "1 0%02x %02x%08x%08x 0 000 00000000\n"
            req_str = req_form % (nmc_wraddr, nmc_wrdata[0], nmc_wrdata[1], nmc_wrdata[2])
            req_file.write(req_str)
            # update nmc_inst
            nmc_inst.write(
                nmc_wr_req = nmc_wr_req
            )
        else:
            print("[ERROR]: unknown req type(%i)!" % req_type)
    # close file
    req_file.close()
    ans_file.close()

if __name__ == "__main__":
    main()
