import math
import random
import numpy as np
# local dep
import rene
import rene_full

W = 16
HMAX = 16
# test params
MAX_CYCLE = 10

"""
_get_binaryencode:
    get the corresponding binary-encode
    @params:
        value(int)      : real number
        w(int)          : bit width
    @rets:
        res(np.array)   : binary encode with shape(w,) of value
"""
def _get_binaryencode(value, w = W):
    # init res
    res = []
    for i in range(w):
        res.append(value % 2)
        value >>= 1
    return np.array(res)

def test_brgc():
    # get value & value_be
    value = random.randint(0, 2**W)
    value_be = _get_binaryencode(value, w = W)
    # test brgc
    # print(_get_binaryencode(value = rene.brgc(value), w = W), rene_full.brgc(value_be))
    res = (_get_binaryencode(
        value = rene.brgc(value),
        w = W
    ) == rene_full.brgc(value_be))
    return res.all()

def test_get_ternary():
    # get value & value_be
    value, mask = random.randint(0, 2**W), random.randint(0, 2**W)
    value_be, mask_be = _get_binaryencode(value, w = W), _get_binaryencode(mask, w = W)
    # test get_ternary
    # print(rene.get_ternary(value, mask)[-value_be.shape[0]:], rene_full.get_ternary(value_be, mask_be))
    res = (rene.get_ternary(value, mask)[-value_be.shape[0]:] == rene_full.get_ternary(value_be, mask_be))
    return res

def test_encodeValue():
    # init hmax & reneW
    hmax = HMAX
    reneW = W - int(math.log(hmax, 2)) + hmax - 1
    # get value & value_be
    value = random.randint(0, 2**W)
    value_be = _get_binaryencode(value, w = W)
    # test encodeValue
    # print(_get_binaryencode(value = rene.encodeValue(value, hmax), w = reneW), rene_full.encodeValue(value_be, hmax))
    res = (_get_binaryencode(
        value = rene.encodeValue(value, hmax),
        w = reneW
    ) == rene_full.encodeValue(value_be, hmax))
    return res.all()

def test_encodeRange():
    # init hmax & reneW
    hmax = HMAX
    reneW = W - int(math.log(hmax, 2)) + hmax - 1
    # get value & value_be
    s_value = random.randint(0, 2**W - 1)
    t_value = random.randint(s_value + 1, 2**W)
    s_value_be = _get_binaryencode(s_value, w = W)
    t_value_be = _get_binaryencode(t_value, w = W)
    # test encodeRange
    # print(_get_binaryencode(
    #     value = rene.encodeRange(s_value, t_value, hmax)[0],
    #     w = reneW
    # ), rene_full.encodeRange(s_value_be, t_value_be, hmax)[0])
    # print(_get_binaryencode(
    #     value = rene.encodeRange(s_value, t_value, hmax)[1],
    #     w = reneW
    # ), rene_full.encodeRange(s_value_be, t_value_be, hmax)[1])
    res_0 = (_get_binaryencode(
        value = rene.encodeRange(s_value, t_value, hmax)[0],
        w = reneW
    ) == rene_full.encodeRange(s_value_be, t_value_be, hmax)[0])
    res_1 = (_get_binaryencode(
        value = rene.encodeRange(s_value, t_value, hmax)[1],
        w = reneW
    ) == rene_full.encodeRange(s_value_be, t_value_be, hmax)[1])
    return res_0.all() and res_1.all()

def test():
    flag = True
    for i in range(MAX_CYCLE):
        # test brgc
        res = test_brgc()
        if not res: print("test brgc fail!"); flag = False; break
        # test get_ternary
        res = test_get_ternary()
        if not res: print("test get_ternary fail!"); flag = False; break
        # test encodeValue
        res = test_encodeValue()
        if not res: print("test encodeValue fail!"); flag = False; break
        # test encodeRange
        res = test_encodeRange()
        if not res: print("test encodeRange fail!"); flag = False; break
    if flag: print("test pass!")

if __name__ == "__main__":
    test()