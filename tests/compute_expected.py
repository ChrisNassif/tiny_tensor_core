#!/usr/bin/env python3
"""Compute expected outputs for updated tests (multiply-only)."""

def wrap16(val):
    return ((val + 32768) % 65536) - 32768

def trunc8(m_flat):
    return [((v + 128) % 256) - 128 for v in m_flat]

def mat_mul(m1_flat, m2_flat):
    m1 = [m1_flat[i:i+3] for i in range(0, 9, 3)]
    m2 = [m2_flat[i:i+3] for i in range(0, 9, 3)]
    res = []
    for i in range(3):
        for j in range(3):
            val = sum(m1[i][k] * m2[k][j] for k in range(3))
            res.append(wrap16(val))
    return res

def fmt(m):
    return ' '.join(map(str, m))

# test_basic_ops: load 0 1, mul -> 2
m0 = [1,2,3,4,5,6,7,8,9]
m1 = [9,8,7,6,5,4,3,2,1]
mul_res = mat_mul(m0, m1)
print('=== test_basic_ops ===')
for r in [m0, m1, mul_res]:
    print(fmt(r))

# test_chained_ops: load 0 1, mul -> 2, load 2 1, mul -> 3
m0 = [2]*9
m1 = [3]*9
mul1 = mat_mul(m0, m1)
# Now load mul1 (truncated to 8-bit) and m1 into registers
mul1_trunc = trunc8(mul1)
m1_trunc = trunc8(m1)
mul2 = mat_mul(mul1_trunc, m1_trunc)
print('=== test_chained_ops ===')
for r in [m0, m1, mul1, mul2]:
    print(fmt(r))

# test_saturation: unchanged
m0 = [127]*9
m1 = [127]*9
mul_res = mat_mul(m0, m1)
print('=== test_saturation ===')
for r in [m0, m1, mul_res]:
    print(fmt(r))

# test_identity: unchanged  
m0 = [1,0,0,0,1,0,0,0,1]
m1 = [1,2,3,4,5,6,7,8,9]
mul_res = mat_mul(m0, m1)
print('=== test_identity ===')
for r in [m0, m1, mul_res]:
    print(fmt(r))

# test_zero_matrix: unchanged
m0 = [0]*9
m1 = [42,-13,-20,-31,22,26,26,1,-35]
mul_res = mat_mul(m0, m1)
print('=== test_zero_matrix ===')
for r in [m0, m1, mul_res]:
    print(fmt(r))
