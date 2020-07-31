"""
Modified on July 29 11:14, 2020
by fassial

@author: yotamhc
@link: https://github.com/yotamhc/rene
"""
import math
import random

W = 8
H_max = 8

def brgc(value):
    return value ^ (value >> 1)

def print_binary(value):
    print(bin(value)[2:].zfill(32))

def get_ternary(value, mask):
    b = bin(value)[2:].zfill(32)
    m = bin(mask)[2:].zfill(32)
    res = ''
    for i in range(32):
        if m[i] == '1':
            res = res + '*'
        else:
            res = res + b[i]
    return res

def print_ternary(value, mask):
    print(get_ternary(value, mask))

def encodeValue(i, hmax = H_max):
    gray = brgc(i)
    word = gray >> int(math.log(hmax, 2) - 1)
    for x in range(hmax):
        if x != 0 and x != hmax/2:
            b = 1-int(math.floor((i - x) / float(hmax))) % 2
            word = (word << 1) | b
    return word

def encodeRange(s, t, hmax = H_max):
    gamma = []
    if (t - s + 1) < hmax:
        r1 = (s, s+hmax-1)
        r2 = (t-hmax+1, t)
        gamma.append(r1)
        gamma.append(r2)
    else:
        gamma.append((s, t))
        
    r_value = 0
    r_mask = (-1) & 0x0FFFF
    count = 0
    for (x,y) in gamma:
        mask = 0
        for i in range(x+1, y+1):
            mask = mask | (brgc(i) ^ brgc(i-1))
        word = brgc(s) >> int(math.log(hmax, 2) - 1)
        mask = mask >> int(math.log(hmax, 2) - 1)
        for i in range(hmax):
            if i != 0 and i != hmax/2:
                if x % hmax != i:
                    mask = (mask << 1) | 1
                    word = word << 1
                else:
                    mask = mask << 1
                    b = 1-int(math.floor((i - x) / float(hmax))) % 2
                    word = (word << 1) | b
        if count > 0:
            (r_value, r_mask) = conj((r_value, r_mask), (word, mask))
        else:
            (r_value, r_mask) = (word, mask)
        count = count + 1

    return (r_value, r_mask)

def _tcode(p, d, w, hmax, h = None):
    word = []
    bit_width = w - (int(math.log(hmax, 2) - 1)) + (hmax - 2)
    for i in range(d):
        if h == None:
            realEncode = encodeValue(p[i], hmax)
            word.append(realEncode)
        else:
            s = (p[i] - h // 2) if (p[i] - h // 2) > 0 else 0
            t = (p[i] + h // 2) if (p[i] + h // 2) < 2**w-1 else 2**w-1
            realEncode = encodeRange(s, t, hmax)
            # print(p[i], "(", s, ",", t, ")", realEncode)
            word.append(realEncode)
    return word

def tcode(p, d, w, hmax, h = None):
    word = []
    bit_width = w - (int(math.log(hmax, 2) - 1)) + (hmax - 2)
    for i in range(d):
        if h == None:
            realEncode = encodeValue(p[i], hmax)
            temp_res = []
            for j in range(bit_width):
                temp_res.append(realEncode % 2)
                realEncode >>= 1
            word.append(temp_res)
        else:
            s = (p[i] - h // 2) if (p[i] - h // 2) > 0 else 0
            t = (p[i] + h // 2) if (p[i] + h // 2) < 2**w-1 else 2**w-1
            realEncode1, realEncode2 = encodeRange(s, t, hmax)
            # if i == 588: print(p[i], "(", s, ",", t, ")")
            temp_res1, temp_res2 = [], []
            for j in range(bit_width):
                temp_res1.append(realEncode1 % 2)
                realEncode1 >>= 1
            for j in range(bit_width):
                temp_res2.append(realEncode2 % 2)
                realEncode2 >>= 1
            word.append((temp_res1, temp_res2))
    return word

def conj_bit(a, b):
    if a == b:
        return a
    if a == '*':
        return b
    if b == '*':
        return a
    else: 
        return None

def conj(r1, r2):
    t1 = get_ternary(r1[0], r1[1])
    t2 = get_ternary(r2[0], r2[1])
    value = ['0'] * 32
    mask = ['0'] * 32
    
    for i in range(len(t1)):
        res = conj_bit(t1[i], t2[i])
        if res == None:
            return None
        if res == '*':
            mask[i] = '1'
        else:
            value[i] = res
            
    return (int(''.join(value), 2), int(''.join(mask), 2))

def ternary_match(v1, m1, v2, m2):
    # print(type(v1), type(m1), type(v2), type(m2))
    # print(v1.shape, m1.shape, v2.shape, m2.shape)
    left = v1.copy()
    for i in range(left.shape[0]):
        if m1[i] == 1: left[i] = 0
        if m2[i] == 1: left[i] = 0
    right = v2.copy()
    for i in range(right.shape[0]):
        if m1[i] == 1: right[i] = 0
        if m2[i] == 1: right[i] = 0
    # print(left == right)
    # print(sum(left == right))
    return (left == right).all()

def ternaryMatch(v1, m1, v2, m2):
    return (v1 & ~m1 & ~m2) == (v2 & ~m1 & ~m2)

def test():
    # Creates random ranges and tests points in each range 
    
    for i in range(100):
        s = random.randint(0, 2**W)
        len = random.randint(2, H_max)
        e = s + len - 1
        (vr, mr) = encodeRange(s, e)
        
        for j in range(100):
            p = random.randint(0, 2**W)
            vp = encodeValue(p)
            
            if (p >= s and p <= e and not ternaryMatch(vr, mr, vp, 0)) or ((p < s or p > e) and ternaryMatch(vr, mr, vp, 0)):
                print("ERROR: TEST FAILED FOR RANGE [%d, %d] AND POINT %d:" % (s, e, p))
                print("Range encoding: ",
                print_ternary((vr, mr)))
                print("Point encoding: ",
                print_binary(vp))
                return False
            
    print("TEST SUCCEEDED!")
    return True
    
if __name__ == "__main__":
    test()

