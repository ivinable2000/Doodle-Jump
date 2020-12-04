.data 
#put some variables
backgroundColor: .word 0xFFDC71
blueColor: .word 0x99ccff
baseAddress: .word 0x10008000
doodlerColor: .word 0xff0000

#t0 = base address
#t3 = doodler position
#t6 = user input
#t7 = score
#s1 = platform #1 position
#s2 = platform #2 position
#s3 = platform #3 position
#s4 = direction (1 = up, 0 = down)
#s5 = spring position
#s6 = jump height

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
	li $t7, 0		# set score to 0
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

	jal DRAW_SCORE
	# Calculate sleep
	jal SLEEP_TIME
	lw $a0, 0($sp) 		# pop sleep time from stack
	addi $sp, $sp, 4
	
	li $v0, 32		# Make program sleep
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
			addi $t7, $t7, 1 # Increase score
			
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
			addi $t7, $t7, 1 # Increase score
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
			addi $t7, $t7, 1 # Increase score
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
		
SLEEP_TIME:
	li $a0, 10
	li $a1, 400
	
	mult $t7, $a0
	mflo $a0
	
	bgt $a1, $a0, decrement_sleep
	
	addi $sp, $sp, -4 
	sw $zero, 0($sp) 		
	jr $ra
	
	
	decrement_sleep:
		sub $a0, $a1, $a0
		addi $sp, $sp, -4 
		sw $a0, 0($sp) 
		
		jr $ra
	
	
		
DRAW_SCORE:
	li $a2, 10
	div $t7, $a2
	
	mflo $a3
	
	addi $sp, $sp, -4 	# make space in stack for return address
	sw $ra, 0($sp)
	
	
	addi $sp, $sp, -4 	# make space in stack for first digit
	sw $a3, 0($sp)
	
	li $a2, 176
	add $a2, $a2, $t0	# location of first digit

	addi $sp, $sp, -4 	# make space in stack for first digit position
	sw $a2, 0($sp)
	
	jal DRAW_NUMBER
	
	mfhi $a3
	
	addi $sp, $sp, -4 	# make space in stack for second digit
	sw $a3, 0($sp)
	
	li $a2, 192
	add $a2, $a2, $t0	# location of second digit

	addi $sp, $sp, -4 	# make space in stack for second digit position
	sw $a2, 0($sp)
	
	jal DRAW_NUMBER
	
	lw $ra, 0($sp) 		# pop return address from stack
	addi $sp, $sp, 4
	
	jr $ra
	
	
DRAW_NUMBER:
	lw $a3, 0($sp) 		# pop digit position from stack
	addi $sp, $sp, 4
	
	lw $v0, 0($sp) 		# pop digit from stack
	addi $sp, $sp, 4
	
	li $a2, 9
	
	beq $v0, $a2, draw_nine
	addi $a2, $a2, -1
	beq $v0, $a2, draw_eight
	addi $a2, $a2, -1
	beq $v0, $a2, draw_seven
	addi $a2, $a2, -1
	beq $v0, $a2, draw_six
	addi $a2, $a2, -1
	beq $v0, $a2, draw_five
	addi $a2, $a2, -1
	beq $v0, $a2, draw_four
	addi $a2, $a2, -1
	beq $v0, $a2, draw_three
	addi $a2, $a2, -1
	beq $v0, $a2, draw_two
	addi $a2, $a2, -1
	beq $v0, $a2, draw_one
	addi $a2, $a2, -1
	beq $v0, $a2, draw_zero
	jr $ra
	
	draw_nine:
		sw $t4, 0($a3)
		sw $t4, 4($a3)
		sw $t4, 8($a3)
		sw $t4, 128($a3)
		sw $t4, 136($a3)
		sw $t4, 256($a3)
		sw $t4, 260($a3)
		sw $t4, 264($a3)
		sw $t4, 392($a3)
		sw $t4, 520($a3)
		jr $ra
	draw_eight:
		sw $t4, 0($a3)
		sw $t4, 4($a3)
		sw $t4, 8($a3)
		sw $t4, 128($a3)
		sw $t4, 136($a3)
		sw $t4, 256($a3)
		sw $t4, 260($a3)
		sw $t4, 264($a3)
		sw $t4, 384($a3)
		sw $t4, 392($a3)
		sw $t4, 512($a3)
		sw $t4, 516($a3)
		sw $t4, 520($a3)
		jr $ra
	draw_seven:
		sw $t4, 0($a3)
		sw $t4, 4($a3)
		sw $t4, 8($a3)
		sw $t4, 136($a3)
		sw $t4, 264($a3)
		sw $t4, 392($a3)
		sw $t4, 520($a3)
		jr $ra
	draw_six:
		sw $t4, 0($a3)
		sw $t4, 4($a3)
		sw $t4, 8($a3)
		sw $t4, 128($a3)
		sw $t4, 256($a3)
		sw $t4, 260($a3)
		sw $t4, 264($a3)
		sw $t4, 384($a3)
		sw $t4, 392($a3)
		sw $t4, 512($a3)
		sw $t4, 516($a3)
		sw $t4, 520($a3)
		jr $ra
	draw_five:
		sw $t4, 0($a3)
		sw $t4, 4($a3)
		sw $t4, 8($a3)
		sw $t4, 128($a3)
		sw $t4, 256($a3)
		sw $t4, 260($a3)
		sw $t4, 264($a3)
		sw $t4, 392($a3)
		sw $t4, 512($a3)
		sw $t4, 516($a3)
		sw $t4, 520($a3)
		jr $ra
	draw_four:
		sw $t4, 0($a3)
		sw $t4, 8($a3)
		sw $t4, 128($a3)
		sw $t4, 136($a3)
		sw $t4, 256($a3)
		sw $t4, 260($a3)
		sw $t4, 264($a3)
		sw $t4, 392($a3)
		sw $t4, 520($a3)
		jr $ra
	draw_three:
		sw $t4, 0($a3)
		sw $t4, 4($a3)
		sw $t4, 8($a3)
		sw $t4, 136($a3)
		sw $t4, 256($a3)
		sw $t4, 260($a3)
		sw $t4, 264($a3)
		sw $t4, 392($a3)
		sw $t4, 512($a3)
		sw $t4, 516($a3)
		sw $t4, 520($a3)
		jr $ra
	draw_two:
		sw $t4, 0($a3)
		sw $t4, 4($a3)
		sw $t4, 8($a3)
		sw $t4, 136($a3)
		sw $t4, 256($a3)
		sw $t4, 260($a3)
		sw $t4, 264($a3)
		sw $t4, 384($a3)
		sw $t4, 512($a3)
		sw $t4, 516($a3)
		sw $t4, 520($a3)
		jr $ra
	draw_one:
		sw $t4, 8($a3)
		sw $t4, 136($a3)
		sw $t4, 264($a3)
		sw $t4, 392($a3)
		sw $t4, 520($a3)
		jr $ra
	draw_zero:
		sw $t4, 0($a3)
		sw $t4, 4($a3)
		sw $t4, 8($a3)
		sw $t4, 128($a3)
		sw $t4, 136($a3)
		sw $t4, 256($a3)
		sw $t4, 264($a3)
		sw $t4, 384($a3)
		sw $t4, 392($a3)
		sw $t4, 512($a3)
		sw $t4, 516($a3)
		sw $t4, 520($a3)
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
	lw $a3, 0($sp) 		# pop platform #3 from stack
	addi $sp, $sp, 4 
	lw $a2, 0($sp) 		# pop platform #2 from stack
	addi $sp, $sp, 4 
	lw $a1, 0($sp) 		# pop platform #1 from stack
	addi $sp, $sp, 4 
	
	beq $t2, 32, RETURN	
	
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
	
