"""
Created on August 10 17:36, 2020

@author: fassial
"""

# macro
W = 32
ALU_KIND = 2    # 0: xnor, 1: mul, 2: xor

def alu(a_i, b_i, w = W, alu_kind = ALU_KIND):
    c_o = 0
    if alu_kind == 0: c_o = ~(a_i ^ b_i) % (2**w)
    elif alu_kind == 1: c_o = (a_i * b_i) % (2**w)
    elif alu_kind == 2: c_o = (a_i ^ b_i) % (2**w)
    return c_o

def count_bit(data_i, w = W):
    count_o = 0
    for i in range(w):
        if data_i % 2 == 1: count_o += 1
        data_i >>= 1
    return count_o
