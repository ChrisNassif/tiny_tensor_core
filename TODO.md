the logic tensor_core_output in tensor_core.sv currently infers a latch. Fix that by making the tensor core output directly to the register file once it is done with a batch


make the relu and matrix addition operations faster by having higher batch counts. I think we could make them single clock cycle

add an opcode to load to matrix1 or matrix2 individually and only read from matrix1 or matrix2 individually for burst read/ write


make sure to investigate if there are any single clock cycle gains to be had in the tensor core operate or burst read/write state machines


Make a tiling script to convert any matrix multiplication into code that the tensor core can execute
With this tiling script, do a bunch of verification on extremely large matrix multiplications