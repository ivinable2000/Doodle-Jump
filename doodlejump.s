.data 
#put some variables
backgroundColor: .word 0xFFDC71
blueColor: .word 0x99ccff
baseAddress: .word 0x10008000
doodlerColor: .word 0xff0000

#t0 = base address
#t3 = doodler position
#s1 = platform #1 position
#s2 = platform #2 position
#s3 = platform #3 position
#t6 = user input
.text 
main:
	lw $t0, baseAddress 	# load baseaddress
	lw $t1, backgroundColor	#load background color
	lw $t5, blueColor	#load background color
	lw $t4, doodlerColor	#load doodler color
	li $t2, 0		# set counter to 0
	jal RENDER_SCREEN
	lw $t0, baseAddress 	# load baseaddress
	addi $t3, $t0, 3508	# initial position for doodler
	jal RENDER_DOODLER
	
	# Random horizontal offset position for platform #1
	jal RANDOM_POSITION
	lw $s1, 0($sp) 		# pop platform #1 offset from stack
	addi $sp, $sp, 4 	
	
	# Random horizontal offset position for platform #2
	jal RANDOM_POSITION
	lw $s2, 0($sp) 		# pop platform #2 offset from stack
	addi $sp, $sp, 4 	
	
	addi $s2, $s2, 1280	# vertical offset for platform #2 position
	
	# Random horizontal offset position for platform #3
	jal RANDOM_POSITION
	lw $s3, 0($sp) 		# pop platform #3 offset from stack
	addi $sp, $sp, 4 	
	
	addi $s3, $s3, 2560	# vertical offset for platform #3 position
	
	li $t2, 0		# set counter to 0	
	addi $sp, $sp, -4 
	sw $s1, 0($sp) 		# store platform #1 in stack
	addi $sp, $sp, -4 
	sw $s2, 0($sp) 		# store platform #2 in stack
	addi $sp, $sp, -4 
	sw $s3, 0($sp) 		# store platform #2 in stack
	jal RENDER_PLATFORMS
	
	j WAIT_FOR_START
	

WAIT_FOR_START:
	lw $t6, 0xffff0000	# check for user input
	beq $t6, 1, start_input	#If user input go to start_input
	#TODO: sleep?
	j WAIT_FOR_START
	start_input:
		lw $t6, 0xffff0004 # Check input
		
		#TODO: make doodler jump before moving to PLAY_GAME
		
		beq $t6, 0x73, PLAY_GAME # if input is "s", start game
		#TODO: sleep?
		j WAIT_FOR_START
		
PLAY_GAME:
	#jal CHECK_INPUT
	li $v0, 1
	li $a0, 69
	syscall 
	
	j TERMINATE
	
	
CHECK_INPUT:
	lw $t6, 0xffff0000
	beq $t6, 1, keyboard_input
	jr $ra
	keyboard_input:
		lw $t6, 0xffff0004 
		#TODO: double check hex for "j" and "k"
		beq $t6, 0x6A, move_left  # if input is "j" move left, Make sure that hex is right
		beq $t6, 0x6B, move_right # if input is "k" move left,Make sure that hex is right
		beq $t6, 0x73, main 	  #if input is "s" restart the game
		jr $ra
	#TODO: handle edge cases
	move_left:
		#move doodler one unit to the left
		addi $t3, $t3, -4
		jr $ra
	move_right:
		#move doodler one unit to the left
		addi $t3, $t3, 4
		jr $ra
	
RENDER_SCREEN:
	#loop through screen and color background blue
	beq $t2, 4096, RETURN
	
	sw $t1, 0($t0)
	addi $t2, $t2, 4
	addi $t0, $t0, 4
	j RENDER_SCREEN
	
RENDER_DOODLER:
	sw $t4, 0($t3)
	sw $t4, 4($t3)
	sw $t4, 8($t3)
	sw $t4, 12($t3)
	sw $t4, 128($t3)
	sw $t5, 132($t3)
	sw $t5, 136($t3)
	sw $t4, 140($t3)
	sw $t4, 256($t3)
	sw $t4, 260($t3)
	sw $t4, 264($t3)
	sw $t4, 268($t3)
	sw $t4, 384($t3)
	sw $t4, 388($t3)
	sw $t4, 392($t3)
	sw $t4, 396($t3)
	sw $t4, 512($t3)
	sw $t4, 524($t3)
	j RETURN
	
RENDER_PLATFORMS:
	beq $t2, 32, RETURN
	lw $a3, 0($sp) 		# pop platform #3 from stack
	addi $sp, $sp, 4 
	lw $a2, 0($sp) 		# pop platform #2 from stack
	addi $sp, $sp, 4 
	lw $a1, 0($sp) 		# pop platform #1 from stack
	addi $sp, $sp, 4 	
	
	#Draw one unit in each platform
	sw $t5, 0($a1)
	sw $t5, 0($a2)
	sw $t5, 0($a3)
	
	addi $t2, $t2, 4		# update counter
	# move platform positions by one 
	addi $a1, $a1, 4	
	addi $a2, $a2, 4
	addi $a3, $a3, 4
	
	addi $sp, $sp, -4 	
	sw $a1, 0($sp) 		# store platform #1 position in stack
	addi $sp, $sp, -4
	sw $a2, 0($sp) 		# store platform #2 position in stack
	addi $sp, $sp, -4
	sw $a3, 0($sp) 		# store platform #3 position in stack

	j RENDER_PLATFORMS
	
RANDOM_POSITION:
	li $v0, 42
	li $a0, 0
	li $a1, 24
	syscall 
	
	li $a1, 4
	mult $a0, $a1
	mflo $a0
	add $a0, $a0, $t0 	# Add base Address to horizontal offset
	addi $sp, $sp, -4 	# make space in stack for answer
	sw $a0, 0($sp) 		# push in stack
	
	j RETURN
	
RETURN:
	jr $ra
	
TERMINATE:
	li $v0, 10
	syscall 
	
