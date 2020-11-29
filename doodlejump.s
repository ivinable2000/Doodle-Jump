.data 
#put some variables
backgroundColor: .word 0xFFDC71
blueColor: .word 0x99ccff
baseAddress: .word 0x10008000
doodlerColor: .word 0xff0000

#t0 = base address
#t3 = doodler position
#t6 = user input
#s1 = platform #1 position
#s2 = platform #2 position
#s3 = platform #3 position
#s4 = direction (1 = up, 0 = down)
#s5 = jump height (10 rows max)

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
	
	li $s4, 1		# set movement direction to up
	li $s6, 0		# set jump height
	j WAIT_FOR_START
	

WAIT_FOR_START:
	lw $t6, 0xffff0000		# check for user input
	beq $t6, 1, start_input		#If user input go to start_input
	j WAIT_FOR_START
	start_input:
		lw $t6, 0xffff0004 	# Check input
		beq $t6, 0x73, PLAY_GAME # if input is "s", start game
		j WAIT_FOR_START
		
PLAY_GAME:
	jal CHECK_INPUT
	
	jal VERTICAL_MOVE
	
	jal CHECK_COLLISION
	
	jal CHECK_PLATFORM
	
	lw $t0, baseAddress 
	li $t2, 0
	jal RENDER_SCREEN
	
	li $t2, 0		# set counter to 0	
	addi $sp, $sp, -4 
	sw $s1, 0($sp) 		# store platform #1 in stack
	addi $sp, $sp, -4 
	sw $s2, 0($sp) 		# store platform #2 in stack
	addi $sp, $sp, -4 
	sw $s3, 0($sp) 		# store platform #2 in stack
	jal RENDER_PLATFORMS
	
		
	lw $t0, baseAddress
	jal RENDER_DOODLER
	
	# Sleep for half a second
	li $v0, 32
	li $a0, 250
	syscall
	
	j PLAY_GAME
	
	
CHECK_INPUT:
	lw $t6, 0xffff0000
	beq $t6, 1, keyboard_input
	jr $ra
	keyboard_input:
		lw $t6, 0xffff0004 
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
		
VERTICAL_MOVE:
	beq $s4, 1, move_up
	move_down:
		addi $t3, $t3, 128 	# move doodler down
		jr $ra
		
	move_up:
		#if doodler is below or on 17th line, move doodler up, o/w scroll background down
		li $a0, 2176
		add $a0, $a0, $t0
		bge  $t3, $a0, doodler_up
		scroll_background:
			addi $s1, $s1, 128
			addi $s2, $s2, 128
			addi $s3, $s3, 128
			j increment_jump_counter
		doodler_up:
			addi $t3, $t3, -128
			j increment_jump_counter
		
		#in a jump you can only move up 10 units
		increment_jump_counter:
			li $a0, 12
			bge $s6, $a0, change_direction
			addi $s6, $s6, 1 # else increment jump counter
			jr $ra
			change_direction:
				li $s6, 0	# reset jump height
				li $s4, 0	# set movement direction to down
				jr $ra
			
CHECK_COLLISION:
	#If doodler reaches bottom (dies), end game
	li $a0, 3584 
	add $a0, $a0, $t0
	bgt $t3,  $a0, TERMINATE
	
	addi $a0, $t3, 512	# Doodlers left foot
	
	bne $s4, $zero, RETURN 	# If doodler is moving up then do not look for collision
	
	addi $sp, $sp, -4 
	sw $ra, 0($sp) 		# store return address in stack
	jal FIRST_PLATFORM_COLLISION
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
FIRST_PLATFORM_COLLISION:
	addi $a1, $s1, 32
	blt $a0, $a1, first_platform_left_side
	
	j check_second_platform

	first_platform_left_side:
		subi $a1, $a1, 44
		bge  $a0, $a1, first_platform_collision
		j check_second_platform
		first_platform_collision:
			subi $t3, $t3, 128
			li $s4, 1	# set movement direction to up
			jr $ra
	check_second_platform:
		addi $sp, $sp, -4 
		sw $ra, 0($sp) 		# store return address in stack
		jal SECOND_PLATFORM_COLLISION
		
		lw $ra, 0($sp)
		addi $sp, $sp, 4
		
		jr $ra
		
SECOND_PLATFORM_COLLISION:
	addi $a1, $s2, 32
	blt $a0, $a1, second_platform_left_side
	
	j check_third_platform

	second_platform_left_side:
		subi $a1, $a1, 44
		bge  $a0, $a1, second_platform_collision
		j check_third_platform
		second_platform_collision:
			subi $t3, $t3, 128
			li $s4, 1	# set movement direction to up
			jr $ra
	check_third_platform:
		addi $sp, $sp, -4 
		sw $ra, 0($sp) 		# store return address in stack
		jal THIRD_PLATFORM_COLLISION
		
		lw $ra, 0($sp)
		addi $sp, $sp, 4
		
		jr $ra
		
THIRD_PLATFORM_COLLISION:
	addi $a1, $s3, 32
	blt $a0, $a1, third_platform_left_side
	
	jr $ra

	third_platform_left_side:
		subi $a1, $a1, 44
		bge  $a0, $a1, third_platform_collision
		jr $ra
		third_platform_collision:
			subi $t3, $t3, 128
			li $s4, 1	# set movement direction to up
			jr $ra
			
CHECK_PLATFORM:
	li $a2, 4096
	add $a2, $a2, $t0
	addi $sp, $sp, -4 	# make space in stack for return address
	sw $ra, 0($sp)
	
	bge $s1, $a2, new_s1_platform
	bge $s2, $a2, new_s2_platform
	bge $s3, $a2, new_s3_platform
	
	addi $sp, $sp, 4
	jr $ra
	
	new_s1_platform:
		jal RANDOM_POSITION
		lw $s1, 0($sp) 		# pop platform #1 offset from stack
		addi $sp, $sp, 4
		lw $ra, 0($sp) 		# pop return address from stack
		addi $sp, $sp, 4
		jr $ra
	new_s2_platform:
		jal RANDOM_POSITION
		lw $s2, 0($sp) 		# pop platform #2 offset from stack
		addi $sp, $sp, 4
		lw $ra, 0($sp) 		# pop return address from stack
		addi $sp, $sp, 4
		jr $ra
	new_s3_platform:
		jal RANDOM_POSITION
		lw $s3, 0($sp) 		# pop platform #3 offset from stack
		addi $sp, $sp, 4
		lw $ra, 0($sp) 		# pop return address from stack
		addi $sp, $sp, 4
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
	sw $t4, 512($t3)	#left foot
	sw $t4, 524($t3)	#right foot
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
	
