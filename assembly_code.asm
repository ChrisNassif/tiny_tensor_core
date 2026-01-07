reset
burst write -1 0 2 3 4 5 -4 2 3 1 2 3 1 2 -2 0 -3 -1
burst read_and_write 1 2 3 1 2 -2 0 -3 -1 2 0 2 3 4 5 -4 2 3
burst read
matrix_multiply
matrix_multiply
matrix_add
relu
burst read
burst read_and_write 0 -3 -1 2 0 2 3 4 5 -4 2 3 1 2 3 1 2 -2
matrix_add
burst read
nop