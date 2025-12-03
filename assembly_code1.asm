cpu_load 1 10
cpu_load 2 5
add 3 1 2
sub 4 2 1
cpu_load 5 20
cpu_load 6 20
eql 7 5 6
cpu_load 8 25
cpu_load 9 15
grt 10 8 9
cpu_load 11 127
cpu_load 15 3
cpu_mov 12 15
cpu_to_tensor_core 2 1
cpu_to_tensor_core 1 3
tensor_core_mov 0 2
tensor_core_to_cpu 12 2
cpu_read 15
tensor_core_read 2
tensor_core_load_matrix1 3 10
tensor_core_load_matrix1 4 5
tensor_core_load_matrix1 5 8
tensor_core_load_matrix1 6 2
tensor_core_load_matrix1 7 1
tensor_core_load_matrix1 8 1
tensor_core_load_matrix1 9 0
tensor_core_load_matrix1 10 1
tensor_core_load_matrix1 11 0
tensor_core_load_matrix1 12 1
tensor_core_load_matrix1 13 0
tensor_core_load_matrix1 14 1
tensor_core_load_matrix1 15 0
tensor_core_load_matrix2 0 2
tensor_core_load_matrix2 1 0
tensor_core_load_matrix2 2 2
tensor_core_load_matrix2 3 0
tensor_core_load_matrix2 4 2
tensor_core_load_matrix2 5 0
tensor_core_load_matrix2 6 2
tensor_core_load_matrix2 7 0
tensor_core_load_matrix2 8 2
tensor_core_load_matrix2 9 0
tensor_core_load_matrix2 10 2
tensor_core_load_matrix2 11 0
tensor_core_load_matrix2 12 2
tensor_core_load_matrix2 13 0
tensor_core_load_matrix2 14 2
tensor_core_load_matrix2 15 0
tensor_core_operate mul
nop
nop
nop
nop
nop
nop
nop
nop
nop
tensor_core_to_cpu 18 0
tensor_core_to_cpu 19 1
tensor_core_to_cpu 20 2
tensor_core_to_cpu 21 3
cpu_read 11
cpu_read 10
cpu_read 9
cpu_read 8
reset
nop
cpu_read 1
cpu_read 12
tensor_core_read 0
tensor_core_read 15
tensor_core_read 31