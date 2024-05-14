.global __start

.text
.align 4

__start:

#input data to t0 reg
la t0, Input_data
#output data to t1 reg
la t1, Output_data

#a2 = loop index 1(~31)
li a2, 0
#a3 = loop index 2(~31-a2)
li a3, 0

## define temp registers
# temp2 for loop index 1 exit out_loop
li t2, 31
# temp3 for loop index 2 exit in_loop
li t3, 0
# temp4 for loop index 2 exit in_loop
li t4, 31

# load 1st value of input data to a0 register 
lw a0, 0(t0)
# load 2nd value of input data to a1 register
lw a1, 4(t0)

# outer loop(0 ~ 31)
# for(a2 = 0, a2 < 31(t2), a2++)
out_loop:
	
	## call 'in_loop' function until t2 < 0
	blt a2, t2, in_loop

	## call 'copy' function if a2 = t2
	beq a2, t2, copy

	#increment loop index1(a2) by 1
	addi a2, a2, 1

j out_loop

# inner loop(0 ~ (31 - a2))
# for(a3 = 0, a3 < (31 - a2), a3++)
in_loop:

	# calculate(31 - a2)
	sub t3, t4, a2   
	## if a3 < t3(31-a2) go 'main' function
	blt a3, t3, main 

	#increment loop index2(a3) by 1
	addi a3, a3, 1

j in_loop

# main function
## if a0 > a1 swap  
main:

	## if a1 is bigger or equal a1, run 'no_swap' function
	bge a1, a0, no_swap

	## else swap variables
	## t4 = temp value for swap	
	# store a0 to temp value  
	mv t4, a0
	# store a1 to a0 reg
	mv a0, a1
	# store temp to a1 reg
	mv a1, t4

	# load next word( to a0
	addi a0, a0, 4
	# load next word to a0
	addi a1, a1, 4

	# call out_loop 
	jal ra, out_loop

j main

# function no_swap
no_swap:

	# just load next word 
	addi a0, a0, 4
	addi a1, a1, 4

	# call out_loop
	jal ra, out_loop

j no_swap

# data copy from Input_data to Output_data
copy:
	
	# copy word from t0 to t1
	mv t1, t0

	jal ra, exit

j copy

exit:

.data
#data section
.align 4
#4 byte align

Input_data:
#label
.word 2, 0, -7, -1, 3, 8, -4, 10
#word 4byte(32bit)
 .word -9, -16, 15, 13, 1, 4, -3, 14
 .word -8, -10, -15, 6, -13, -5, 9, 12
 .word -11, -14, -6, 11, 5, 7, -2, -12
 
Output_data: 
 .word 0, 0, 0, 0, 0, 0, 0, 0
 .word 0, 0, 0, 0, 0, 0, 0, 0
 .word 0, 0, 0, 0, 0, 0, 0, 0
 .word 0, 0, 0, 0, 0, 0, 0, 0