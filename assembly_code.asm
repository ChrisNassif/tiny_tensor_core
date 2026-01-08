reset
burst write 0 1
burst read_and_write 2 3 4
burst read 5
matrix_multiply
matrix_multiply
matrix_add
relu
burst read 6
burst read_and_write 7 8 9
matrix_add
burst read 10
burst read_and_write 11 12 13
matrix_multiply
burst read_and_write 14 15 16
matrix_multiply
burst read_and_write 17 18 19
matrix_multiply
burst read 20
nop