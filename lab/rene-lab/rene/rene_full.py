"""
Created on July 31 13:04, 2020

@author: fassial
"""
import math
import random
import numpy as np

# encode params
W = 32
HMAX = 32

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

"""
_get_realvalue:
    get the real value of binary-encode
    @params:
        value(np.array) : binary-encode with shape(w, )
    @rets:
        res(int)        : the real value of binary-encode
"""
def _get_realvalue(value):
    res = 0
    for i in reversed(range(value.shape[0])):
        res <<= 1
        res += value[i]
    return res

"""
brgc:
    get the brgc encode of binary-encode
    @params:
        value(np.array) : binary encode with shape(w, )
    @rets:
        res(np.array)   : corresponding brgc encode with shape(w, )
"""
def brgc(value):
    res = value.copy()
    for i in range(res.shape[0] - 1):
        # xor
        if res[i] == value[i + 1]: res[i] = 0
        else: res[i] = 1
    return res

"""
get_ternary:
    get ternary encode of (value, mask)
    @params:
        value(np.array) : value with shape(w, )
        mask(np.array)  : mask with shape(w, )
    @rets:
        res(str)        : ternary encode of (value, mask) with len(w)
"""
def get_ternary(value, mask):
    res = ''
    for i in range(1, value.shape[0] + 1):
        if mask[-i] == 1: res += "*"
        else: res += str(value[-i])
    return res

"""
encodeValue:
    get RENE-encode of value
    @params:
        value(np.array) : value with shape(w, )
        hmax(int)       : max side length we consider
    @rets:
        word(np.array)  : RENE-encode of value with shape(w-log2(hmax)+hmax-1, )
"""
def encodeValue(value, hmax = HMAX):
    # get gray(w, )
    gray = brgc(value)
    gray = gray[int(math.log(hmax, 2) - 1):].tolist() 
    # init word
    word = []
    for x in range(hmax):
        if x != 0 and x != hmax / 2:
            b = 1 - int(math.floor((_get_realvalue(value) - x) / float(hmax))) % 2
            word.append(b)
    word.reverse()
    word.extend(gray)
    return np.array(word)

"""
_conj_bit:
    conj bit
    @params:
        a(char)     : ternary bit
        b(char)     : ternary bit
    @rets:
        res(char)   : conj res
"""
def _conj_bit(a, b):
    if a == b: return a
    if a == '*': return b
    if b == '*': return a
    else: return None

"""
_conj:
    conj 2 range
    @params:
        r1(np.array)    : range1 with shape(2, w)
        r2(np.array)    : range2 with shape(2, w)
    @rets:
        r12(np.array)   : conj res with shape(2, w)
"""
def _conj(r1, r2):
    t1 = get_ternary(r1[0], r1[1])
    t2 = get_ternary(r2[0], r2[1])
    # value & mask with shape(w, )
    value = np.zeros(r1[0].shape)
    mask = np.zeros(r1[1].shape)

    for i in range(len(t1)):
        res = _conj_bit(t1[i], t2[i])
        if res == None: return None
        if res == '*': mask[i] = 1
        else: value[i] = int(res, 2)

    r12 = (value, mask)
    return np.array(r12)

"""
_xor:
    xor np.array
    @params:
        a(np.array) : xor op1 with shape(w, )
        b(np.array) : xor op2 with shape(w, )
    @rets:
        c(np.array) : xor res with shape(w, )
"""
def _xor(a, b):
    c = a.copy()
    for i in range(c.shape[0]):
        if b[i] == 1: c[i] = 0 if c[i] == 1 else 1
    return c

"""
_or:
    or np.array
    @params:
        a(np.array) : or op1 with shape(w, )
        b(np.array) : or op2 with shape(w, )
    @rets:
        c(np.array) : or res with shape(w, )
"""
def _or(a, b):
    c = a.copy()
    for i in range(c.shape[0]):
        if b[i] == 1: c[i] = 1
    return c

"""
encodeRange:
    get RENE-encode of range
    @params:
        s(np.array)     : left bound of range with shape(w, )
        t(np.array)     : right bound of range with shape(w, )
        hmax(int)       : max side length we consider
    @rets:
        res(np.array)   : RENE-encode of range with shape(2, w-log2(hmax)+hmax-1)
"""
def encodeRange(s, t, hmax = HMAX):
    # get realvalue
    s_value, t_value = _get_realvalue(s), _get_realvalue(t)
    # init gamma
    gamma = []
    if (t_value - s_value + 1) < hmax:
        r1 = (s_value, s_value+hmax-1)
        r2 = (t_value-hmax+1, t_value)
        gamma.append(r1)
        gamma.append(r2)
    else:
        gamma.append((s_value, t_value))
    # for loop
    count = 0
    r_value, r_mask = None, None
    for (x, y) in gamma:
        mask = np.zeros(s.shape)
        for i in range(x+1, y+1):
            mask = _or(
                a = mask,
                b = _xor(
                    a = brgc(_get_binaryencode(
                        value = i,
                        w = s.shape[0]
                    )),
                    b = brgc(_get_binaryencode(
                        value = i - 1,
                        w = s.shape[0]
                    ))
                )
            )
        # get gray prefix
        word = brgc(s)[int(math.log(hmax, 2) - 1):].tolist()
        mask = mask[int(math.log(hmax, 2) - 1):].tolist()
        # get word_ext, mask_ext
        word_ext, mask_ext = [], []
        for i in range(hmax):
            if i != 0 and i != hmax/2:
                if x % hmax != i:
                    mask_ext.append(1)
                    word_ext.append(0)
                else:
                    mask_ext.append(0)
                    b = 1-int(math.floor((i - x) / float(hmax))) % 2
                    word_ext.append(int(b))
        # get word, mask
        word_ext.reverse(); word_ext.extend(word)
        mask_ext.reverse(); mask_ext.extend(mask)
        # print(word_ext.extend(word), mask_ext.extend(mask))
        word = np.array(word_ext)
        mask = np.array(mask_ext)
        # print(word, mask, word_ext, mask_ext)
        # conj
        if count > 0:
            (r_value, r_mask) = _conj((r_value, r_mask), (word, mask))
        else:
            (r_value, r_mask) = (word, mask)
        # print(r_value, r_mask, word, mask)
        count = count + 1

    res = (r_value, r_mask)
    return np.array(res)
