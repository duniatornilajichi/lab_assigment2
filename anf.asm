;******************************************************************************
;* FILENAME                                                                   *
;*   anf.asm      				                                              *
;*                                                                            *
;*----------------------------------------------------------------------------*
;*                                                                            *
;*  The rate of convergence of the filter is determined by parameter MU       *
;*                                                                            * 
;******************************************************************************
;/*
	.mmregs

; Functions callable from C code

	.sect	".text"
	.global	_anf

;*******************************************************************************
;* FUNCTION DEFINITION: _anf_asm		                                       *
;*******************************************************************************
; int anf(int y,				=> T0
;		  int *s,				=> AR0 ;x[t, t-1, t-2]
;		  int *a,				=> AR1
; 		  int *rho,				=> AR2
;	      unsigned int* index	=> AR3
;		 );						=> T0
;

_anf:

		PSH  mmap(ST0_55)	; Store original status register values on stack
		PSH  mmap(ST1_55)
		PSH  mmap(ST2_55)

		mov   #0,mmap(ST0_55)      		; Clear all fields (OVx, C, TCx)
		or    #4100h, mmap(ST1_55)  	; Set CPL (bit 14), SXMD (bit 8);
		and   #07940h, mmap(ST1_55)     ; Clear BRAF, M40, SATD, C16, 54CM, ASM
		bclr  ARMS                      ; Disable ARMS bit 15 in ST2_55

		; add your implementation here:

		;INIT 0): circular buffer
		MOV 	#4, BK47		; size of circular buffer
		BSET 	AR4LC				; set as circular
		MOV 	#0, BSA45			; define start address as 0 TO CHECK
		;load AR4 with val from 0-2 based on index at the end make sure to increment AR4
		AND     #3, *AR3			; & (buffer_size-1)
		MOV     *AR3, AR4			; update circular buffer index with value (0 - buffer_size-1) -> (0-3)

		;STEP 1): update rho
		MOV 	*AR2+, AC2
		MOV 	#32440, T3
		SFTL 	AC2, #16
		MPY 	T3, AC2, AC0

		MOV		*AR2-, AC1
		SFTL 	AC1, #-16
		MOV 	#32767, AC3
		SUB		#32440, AC3
		SFTL	AC3, #16
		SFTL	AC2, #16
		MPY		AC3, AC1

		ADD 	AC1, AC0 ;
		ADD 	#16384, AC0 ;

		SFTL	AC0, #-15
		MOV		AC0,*AR2

		;STEP 2): calculate new s and insert in circular buffer
		MOV		*AR1, AR7

		MOV 	*AR2, AC1
		SFTL	AC1, #15
		MPY		AR7, AC1

		ADD 	#32768, AC1	;

		MOV.CR	*-AR4, AR5
		SFTL	AC1, #16
		MPY		AR5, AC1 ;TO CHECK back to <<16 after multiplication?

		MOV 	T0, AC0
		SFTL	AC0, #9

		ADD		AC1, AC0 ;

		MOV		*AR2, T1
		MOV 	T1, AC1
		MPY		T1, AC1

		ADD		#65535, AC1
		ADD		#65535, AC1

		SFTL	AC1, #-18

		MOV.CR	*-AR4, AR6

		SFTL	AC1, #16
		MPY		AR6, AC1

		SUB		AC1, AC0

		ADD		#2048, AC0 ;

		ADD		#2, AR4
		SFTL	AC0, #-12
		MOV.CR 	AC0, *AR4
		;TO CHECK if Q factors remain the same or need shifting.
		;TO CHECK how the fuck did the signed and unsigned thing work in Asembly
		;TO CHECK ADD and SUB  for non AC and AC operations
		;TO CHECK MOV to different sizes

		;STEP 3): update e
		MPY		AR7, AR5, AC0

		MOV		AR6, AC2
		MOV 	AR5, AC3
		ADD		AC3, AC2
		SUB		AC2, AC0

		ADD		#1024, AC0

		SFTL	AC0, #-11
		MOV		AC0, T0

		;STEP 4): update a
		MOV 	#2<<13, T1

		MOV		#200, AC0
		MPY		T1, AC0

		ADD		#8192, AC0

		SFTL	AC0, #-14

		MOV		AR5, AC1
		MPY		T0,AC1

		ADD		#4096, AC1
		SFTL	AC1, #-13

		MPY		AC0, AC1

		ADD		#8192, AC1

		SFTL	AC1, #-14
		ADD		AC1, AR7
		MOV		AR7, *AR1

		;End of code

		POP mmap(ST2_55)				; Restore status registers
		POP	mmap(ST1_55)
		POP	mmap(ST0_55)
                               
		RET								; Exit function call
    

;*******************************************************************************
;* End of anf.asm                                              				   *
;*******************************************************************************
