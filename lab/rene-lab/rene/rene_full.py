"""
Created on July 31 13:04, 2020

@author: fassial
"""
import math
import random
import numpy as np

# encode params
W = 8
HMAX = 8

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

def print_binary(value, w = W):
    return _get_binaryencode(value, w)

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

def print_ternary(value, mask):
    return get_ternary(value, mask)

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
    # print(gray, word)
    word.reverse(); word.extend(gray)
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

    value, mask = value.tolist(), mask.tolist()
    value.reverse(); mask.reverse()
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

"""
ternary_match:
    ternary match
    @params:
        v1(np.array)    : value1 with shape(bit_width, )
        m1(np.array)    : mask1 with shape(bit_width, )
        v2(np.array)    : value2 with shape(bit_width, )
        m2(np.array)    : mask2 with shape(bit_width, )
    @rets:
        flag(bool)      : whether match
"""
def ternary_match(v1, m1, v2, m2):
    left = v1.copy()
    for i in range(left.shape[0]):
        if m1[i] == 1: left[i] = 0
        if m2[i] == 1: left[i] = 0
    right = v2.copy()
    for i in range(right.shape[0]):
        if m1[i] == 1: right[i] = 0
        if m2[i] == 1: right[i] = 0
    return (left == right).all()

"""
tcode:
    tcode of p
    @params:
        p(np.array)     : point with shape(n_feature, )
        d(int)          : dimission to consider
        w(int)          : w
        hmax(int)       : hmax
        h(int)          : side length of cube
    @rets:
        word(np.array)  : tcode of p
"""
def tcode(p, d, w, hmax, h = None):
    word = []
    bit_width = w - (int(math.log(hmax, 2) - 1)) + (hmax - 2)
    for i in range(d):
        if h == None:
            realEncode = encodeValue(
                _get_binaryencode(
                    value = p[i],
                    w = w
                ),
                hmax
            )
            word.append(realEncode)
        else:
            s = (p[i] - h // 2) if (p[i] - h // 2) > 0 else 0
            t = (p[i] + h // 2) if (p[i] + h // 2) < 2**w-1 else 2**w-1
            realEncode = encodeRange(
                _get_binaryencode(
                    value = s,
                    w = w
                ),
                _get_binaryencode(
                    value = t,
                    w = w
                ),
                hmax
            )
            # if i == 6: print(p[i], "(", s, ",", t, ")", realEncode)
            word.append(realEncode)
    return np.array(word)

def test():
    # Creates random ranges and tests points in each range 
    
    for i in range(100):
        s = random.randint(0, 2**W-2)
        len = random.randint(1, (2**W-s-1))
        e = s + len
        # print("(", s, ",", e, ")", len)
        (vr, mr) = encodeRange(
            s = _get_binaryencode(
                value = s,
                w = W
            ),
            t = _get_binaryencode(
                value = e,
                w = W
            ),
            hmax = HMAX
        )

        for j in range(10):
            p = s + 1# random.randint(0, 2**W)
            vp = encodeValue(
                value = _get_binaryencode(
                    value = p,
                    w = W
                ),
                hmax = HMAX
            )

            # if (p >= s and p <= e): print(p, "(", s, ",", e, ")")
            if (p >= s and p <= e and not ternary_match(vr, mr, vp, np.zeros(vp.shape))) or ((p < s or p > e) and ternary_match(vr, mr, vp, np.zeros(vp.shape))):
                print("ERROR: TEST FAILED FOR RANGE [%d, %d] AND POINT %d:" % (s, e, p))
                print("Range encoding: ",
                    # print_ternary((vr, mr))
                    (vr, mr)
                )
                print("Point encoding: ",
                    # print_binary(vp)
                    vp
                )
                return False
            
    print("TEST SUCCEEDED!")
    return True

if __name__ == "__main__":
    test()
