reset
tensor_core_load 0 3
tensor_core_load 1 1
tensor_core_load 2 -5
tensor_core_load 3 1
tensor_core_load 4 5
tensor_core_load 5 -2
tensor_core_load 6 2
tensor_core_load 7 1
tensor_core_load 8 1
tensor_core_load 9 -1
tensor_core_load 10 -4
tensor_core_load 11 1
tensor_core_load 12 4
tensor_core_load 13 -5
tensor_core_load 14 0
tensor_core_load 15 2
tensor_core_load 16 1
tensor_core_load 17 3
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
nop
nop
nop
nop
tensor_core_to_cpu 0 0
tensor_core_to_cpu 1 1
tensor_core_to_cpu 2 2
tensor_core_to_cpu 3 3
tensor_core_to_cpu 4 4
tensor_core_to_cpu 5 5
tensor_core_to_cpu 6 6
tensor_core_to_cpu 7 7
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
tensor_core_read 0
tensor_core_read 1
tensor_core_read 2
tensor_core_read 3
tensor_core_read 4
tensor_core_read 5
tensor_core_read 6
tensor_core_read 7
tensor_core_read 8
tensor_core_read 9
tensor_core_read 10
tensor_core_read 11
tensor_core_read 12
tensor_core_read 13
tensor_core_read 14
tensor_core_read 15
tensor_core_read 16
tensor_core_read 17
cpu_read 0
cpu_read 1
cpu_read 2
cpu_read 3
cpu_read 4
cpu_read 5
cpu_read 6
cpu_read 7
tensor_core_operate add
tensor_core_operate add
tensor_core_operate relu