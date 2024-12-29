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
;		  int *s,				=> AR0 	;s [t, t-1, t-2, t-3]
;		  int *a,				=> AR1
; 		  int *rho,				=> AR2	;rho[0,1]
;	      unsigned int* index	=> AR3
;		 );						=> T0
;
; 		circular buffer 		=> AR4 ;s_circ[0, +1, +2, +3] = s_circ[0, -3, -2, -1]
_anf:

		PSH  mmap(ST0_55)	; Store original status register values on stack
		PSH  mmap(ST1_55)
		PSH  mmap(ST2_55)

		mov   #0,mmap(ST0_55)      		; Clear all fields (OVx, C, TCx)
		or    #4100h, mmap(ST1_55)  	; Set CPL (bit 14), SXMD (bit 8);
		and   #07940h, mmap(ST1_55)     ; Clear BRAF, M40, SATD, C16, 54CM, ASM
		bclr ARMS                      	; Disable ARMS bit 15 in ST2_55

		; add your implementation here:
		;INIT 0):  pointer AR4
		MOV 	*AR3, T1			; T1 = *index
		MOV     T1, AR4				; AR4 = T1 -> (index from 0 to 3)

		MOV 	T1, T2			; T2 = *index -1
		SUB		#1, T2
		XCC		AR4==#0
		MOV		#2, T2

		MOV 	T1, T3			; T2 = *index -2
		ADD		#1, T3
		SUB		#2, AR4
		XCC		AR4>=#0
		MOV		#0, T3

		ADD		#1, T1			; update iddex
		XCC		AR4==#0
		MOV		#0, T1
		ADD		#2, AR4
		MOV  	T1, *AR3

		;STEP 1): update rho
		MOV 	*AR2, AC0			; L28: T1 = rho[0] in T1 and then increase pointer -> rho[1]
		SFTS	AC0, #16			; Shift for multiplication (check Mneumonic Instructions)
		MPYK 	#32440, AC0			; ACO = rho[0]*lmbd

		MOV		*AR2(+1), AC1 		; L29: T1 = rho[1] and then decrease pointer -> rho[0]
		SFTS	AC1, #16			; Shift for multiplication (check Mneumonic Instructions)
		MPYK	#327 ,AC1			; AC1 = (32767-lmbd)*rho[1]

		ADD 	AC1, AC0 			; L30: ACO = AC0 + AC1
		ADD 	#16384, AC0 		; L31: ACO = ACO + 16384 2^(14)

		SFTS	AC0, #-15			; L32: ACO>>15
		MOV		AC0, T1
		MOV		T1, *AR2			; rho[0] = AC0
		SFTS	AC0, #15			; ACO<<15 back to original

		;STEP 2): calculate new s and insert in circular buffer
		MOV		*AR2, AC0			; L35: AC0 = rho[0]
		ADD		#1, AC0				; AC0 += 1

		SFTS	AC0, #-1			; L36: AC0>>1

		SFTS	AC0, #16			; L37: Shift for multiplication (check Mneumonic Instructions)
		MPYM	*AR1, AC0, AC1		; AC1 = AR7*HI(AC0) -> a_i * (rho[0]>>1)

		ADD 	#32768, AC1			; L38: AC1 = AC1 + #32768

		SFTS	AC1, #-16			; L39: AC1>>16

		ADD		T2, AR0				; s-1
		MOV		*AR0, AR5			; L40: AR5 = s_circ[-1]
		SUB		T2, AR0
		SFTS	AC1, #16			; Shift for multiplication (check Mneumonic Instructions)
		MPY		AR5, AC1			; AC1 = AC1 * AR5 -> AC1 * s_circ[-1]

		MOV 	T0, AC0				; L42: AC0 = y
		SFTS	AC0, #9				; ACO << 9

		ADD		AC1, AC0 			; L43: AC0 = AC0 + AC1

		MOV		*AR2, T1			; L45: T1 = rho[0]
		MOV 	T1, AC1				; AC1 = T1 -> rho[0]
		SFTS	AC1, #16			; Shift for multiplication (check Mneumonic Instructions)
		MPY		T1, AC1				; AC1 = AC1 * rho[0] -> rho[0] * rho[0]

		ADD		#65535, AC1			; L46: AC1 = AC1 + 32768
		ADD		#65535, AC1
		ADD		#2, AC1

		SFTS	AC1, #-18			; L47: AC1>>18

		ADD		T3, AR0
		MOV		*AR0, AR6			; L48: AR6 = s_circ[-2]
		SUB		T3, AR0
		SFTS	AC1, #16			; Shift for multiplication (check Mneumonic Instructions)
		MPY		AR6, AC1			; AC1 = AR6*HI(AC1)

		SUB		AC1, AC0			; L50: AC0 = AC0 - AC1
		ADD		#2048, AC0 			; L51: AC0 = AC0 + 2048

		SFTS	AC0, #-12			; L53: AC0>>12
		ADD		AR4, AR0
		MOV		AC0, *AR0			; s[0] = s_circ[0]
		SUB		AR4, AR0


		;STEP 3): update e
		MOV		*AR1, AC0			; L56: AC0 = *a
		SFTS	AC0, #16			; Shift for multiplication (check Mneumonic Instructions)
		MPY		AR5, AC0			; AC0 = AR5*AC0 -> s_circ[-1]*a

		MOV		AR6, AC2			; L57: AC2 = s_circ[-2]
		ADD		AR4, AR0
		MOV 	*AR0, AC3			; AC3 = s[0]
		SUB		AR4, AR0
		SFTS	AC2, #14			; AC2<<12
		SFTS	AC3, #14			; AC3<<12
		ADD		AC3, AC2			; AC2 += AC3 -> s[0]
		SUB		AC0, AC2			; AC2-= AC0

		ADD		#1024, AC2			; L58: AC2+= 256

		SFTS	AC2, #-11			; L59: AC2 -> AC0 >> 9
		MOV		AC2, T0				; e = AC0

		;STEP 4): update a
		MOV 	#2<<13, T1			; L62
		MOV		#200, AC0
		SFTS	AC0, #16
		MPY		T1, AC0

		ADD		#8192, AC0			; L63

		SFTS	AC0, #-14			; L64

		MOV		AR5, AC1			; L66
		SFTS	AC1, #16
		MPY		T0,  AC1

		ADD		#4096, AC1			; L67

		SFTS	AC1, #-13			; L68

		SFTS	AC0, #16			; L69
		SFTS	AC1, #16
		MPY		AC0, AC1

		ADD		#8192, AC1

		SFTS	AC1, #-14

		ADD		*AR1, AC1
		MOV		AC1, *AR1
		;End of code

		POP mmap(ST2_55)				; Restore status registers
		POP	mmap(ST1_55)
		POP	mmap(ST0_55)

		RET								; Exit function call

