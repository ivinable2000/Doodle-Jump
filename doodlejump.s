.data 
#put some variables
skyColor: .word 0x99ccff
baseAddress: .word 0x10008000
.text 
main:
	#continuous loop that searches for keyboard input
	lw $t1, skyColor
	lw $t0, baseAddress
	li $t2, 0
	
RENDER_SCREEN:
	#loop through screen and color background blue
	beq $t2, 4096, TERMINATE
	sw $t1, 0($t0)
	add $t2, $t2, 4
	add $t0, $t0, 4
	j RENDER_SCREEN
	
TERMINATE:
	li $v0, 10
	syscall 
	