reset
nop
burst write 17 19
matrix_add
burst read 19
burst write 16 13
matrix_multiply
burst read 15
burst write 14 8
matrix_add
burst read_and_write 16 15 7
nop
matrix_add
burst read_and_write 7 8 10
matrix_multiply
burst read 4
burst write 7 12
matrix_multiply
burst read 13
burst write 13 10
matrix_multiply
burst read 13
burst write 12 18
nop
matrix_add
relu
burst read 12
burst write 15 0
nop
matrix_add
burst read 13
burst write 17 17
matrix_add
burst read_and_write 7 8 13
matrix_add
relu
burst read 12
burst write 5 14
matrix_add
relu
burst read 0
burst write 12 18
nop
matrix_add
relu
burst read_and_write 13 4 14
nop
matrix_add
burst read_and_write 6 14 10
matrix_add
burst read_and_write 13 8 2
matrix_multiply
burst read 11
burst write 7 2
matrix_multiply
burst read 7
burst write 6 0
nop
matrix_add
burst read_and_write 3 18 6
nop
matrix_add
burst read 5
burst write 19 19
matrix_multiply
burst read_and_write 9 3 18
matrix_add
relu
burst read 12
burst write 12 6
matrix_add
relu
burst read 7
burst write 3 9
matrix_multiply
burst read 18
burst write 1 11
matrix_multiply
burst read 16
burst write 10 0
matrix_multiply
burst read 13
burst write 11 14
matrix_add
relu
burst read 16
burst write 8 19
matrix_add
burst read_and_write 14 13 18
matrix_multiply
burst read 8
burst write 14 7
matrix_add
relu
burst read_and_write 12 10 0
matrix_add
burst read_and_write 6 11 8
matrix_add
relu
burst read 8
burst write 17 0
nop
matrix_multiply
burst read 13
burst write 15 17
matrix_add
relu
burst read_and_write 15 14 0
nop
matrix_add
relu
burst read_and_write 7 9 18
matrix_add
burst read_and_write 13 17 10
matrix_add
burst read 8
burst write 7 3
matrix_add
relu
burst read_and_write 17 5 6
matrix_add
relu
burst read_and_write 18 16 19
nop
matrix_multiply
burst read_and_write 9 7 11
nop
matrix_add
relu
burst read 4
burst write 8 1
matrix_add
relu
burst read 4
burst write 15 3
matrix_add
burst read_and_write 15 14 10
nop
matrix_add
burst read_and_write 3 2 12
matrix_add
relu
burst read 1
burst write 4 4
matrix_multiply
burst read 7
burst write 3 17
matrix_add
relu
burst read_and_write 7 16 12
matrix_add
relu
burst read 13
burst write 9 18
matrix_add
relu
burst read_and_write 3 6 6
nop
matrix_multiply
burst read_and_write 5 17 2
matrix_add
relu
burst read 19
