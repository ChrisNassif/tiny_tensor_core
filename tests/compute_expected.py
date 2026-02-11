#!/usr/bin/env python3
"""Compute expected outputs matching actual hardware behavior:
- mat_mul: 16-bit signed wrapping (dot product truncated to 16 bits)
- mat_add: no wrapping (9-bit result fits in 16-bit data memory)
- relu: standard (negative -> 0)
"""

def wrap16(val):
    return ((val + 32768) % 65536) - 32768

def mat_mul(m1_flat, m2_flat):
    m1 = [m1_flat[i:i+3] for i in range(0, 9, 3)]
    m2 = [m2_flat[i:i+3] for i in range(0, 9, 3)]
    res = []
    for i in range(3):
        for j in range(3):
            val = 0
            for k in range(3):
                val += m1[i][k] * m2[k][j]
            res.append(wrap16(val))
    return res

def mat_add(m1_flat, m2_flat):
    return [m1_flat[i] + m2_flat[i] for i in range(9)]

def mat_relu(m_flat):
    return [x if x > 0 else 0 for x in m_flat]

def fmt(m):
    return ' '.join(map(str, m))

# test_basic_ops
m0 = [1,2,3,4,5,6,7,8,9]
m1 = [9,8,7,6,5,4,3,2,1]
mul_res = mat_mul(m0, m1)
add_res = mat_add(m0, m1)
relu_res = mat_relu(add_res)
print('=== test_basic_ops ===')
for r in [m0, m1, mul_res, add_res, relu_res]:
    print(fmt(r))

# test_saturation
m0 = [127]*9
m1 = [127]*9
mul_res = mat_mul(m0, m1)
print('=== test_saturation ===')
for r in [m0, m1, mul_res]:
    print(fmt(r))

# test_boundary_values
m0 = [127, -128, 0, 127, -128, 0, 127, -128, 0]
m1 = [1, -1, 1, -1, 1, -1, 1, -1, 1]
add_res = mat_add(m0, m1)
print('=== test_boundary_values ===')
for r in [m0, m1, add_res]:
    print(fmt(r))

# test_relu
m0 = [10, -10, 50, -50, 0, 1, -1, 127, -128]
m1 = [0]*9
add_res = mat_add(m0, m1)
relu_res = mat_relu(add_res)
print('=== test_relu ===')
for r in [m0, m1, relu_res]:
    print(fmt(r))

# test_chained_ops
m0 = [2]*9
m1 = [3]*9
m2 = [1]*9
mul_res = mat_mul(m0, m1)
add_res = mat_add(mul_res, m2)
print('=== test_chained_ops ===')
for r in [m0, m1, m2, mul_res, add_res]:
    print(fmt(r))

# test_identity
m0 = [1,0,0,0,1,0,0,0,1]
m1 = [1,2,3,4,5,6,7,8,9]
mul_res = mat_mul(m0, m1)
print('=== test_identity ===')
for r in [m0, m1, mul_res]:
    print(fmt(r))

# test_memory_ops
m0 = [10,20,30,40,50,60,70,80,90]
m1 = [0]*9
add_res = mat_add(m0, m1)
print('=== test_memory_ops ===')
for r in [m0, m1, add_res]:
    print(fmt(r))

# test_register_mapping
m0 = [1]*9
m1 = [2]*9
add_res = mat_add(m0, m1)
print('=== test_register_mapping ===')
for r in [m0, m1, add_res]:
    print(fmt(r))

# test_zero_matrix
m0 = [0]*9
m1 = [42,-13,-20,-31,22,26,26,1,-35]
mul_res = mat_mul(m0, m1)
print('=== test_zero_matrix ===')
for r in [m0, m1, mul_res]:
    print(fmt(r))
