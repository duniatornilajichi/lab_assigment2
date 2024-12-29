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
; 	k 			=>	*AR3
; 	k_minus_1 	=> 	T2
; 	k_minus_2	=>	T3
;
; 	s[-1] 		=>	*AR5
; 	s[-2]		=>  *AR7
_anf:

		PSH  mmap(ST0_55)	; Store original status register values on stack
		PSH  mmap(ST1_55)
		PSH  mmap(ST2_55)

		mov   #0,mmap(ST0_55)      		; Clear all fields (OVx, C, TCx)
		or    #4100h, mmap(ST1_55)  	; Set CPL (bit 14), SXMD (bit 8);
		and   #07940h, mmap(ST1_55)     ; Clear BRAF, M40, SATD, C16, 54CM, ASM
		bclr ARMS                      	; Disable ARMS bit 15 in ST2_55

		; add your implementation here:
		;INIT 0):  pointers k
		MOV 	*AR3, T1			; T1 = *index
		MOV     *AR3, T2			;
		ASUB	#2, T1				; check if index > 2 by subtrancting 2 and comparing
		XCC		T1>#0
		AMOV	#0, T2
		AMOV	T2, T1
		MOV		T2, *AR3

		ASUB	#1, T1				; L21: T1 = k-1
		AMOV	T1, T2				; if (k-1) < 0 -> T2 = 2 else T2 = k-1
		XCC		T1<#0				; T2 = k-1 from 0-2
		AMOV	#2, T2

		AMOV	T2, T1				; L22: T1 = k-1 from 0-2
		ASUB	#1, T1				; T1 = T2-1
		AMOV	T1, T3				; if(T2-1) < 0 -> T3 = 2 else T3 = T2 -> (k-1 from 0-2) -1
		XCC		T1<#0
		AMOV	#2, T3				; T3 = k-2 from 0-2

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
		MOV		AC0, *AR2			; rho[0] = AC0

		;STEP 2): calculate new s and insert in circular buffer
		ADD		#1, AC0				; AC0 += 1

		SFTS	AC0, #-1			; L36: AC0>>1

		SFTS	AC0, #16			; L37: Shift for multiplication (check Mneumonic Instructions)
		MPYM	*AR1, AC0, AC1		; AC1 = a_i*HI(AC0) -> a_i * (rho[0]>>1)

		ADD 	#32768, AC1			; L38: AC1 = AC1 + #32768

		;SFTS	AC1, #-16			; L39: AC1>>16

		AADD	T2, AR0				; s-1
		MOV		*AR0, AC2			; L40: AR5 = s_circ[-1]
		ASUB	T2, AR0
		MOV		AC2, *AR5
		SFTS	AC2, #16
		;SFTS	AC1, #16			; Shift for multiplication (check Mneumonic Instructions)
		MPY		AC2, AC1			; AC1 = AC1 * AR5 -> AC1 * s_circ[-1]

		MOV 	T0, AC0				; L42: AC0 = y
		SFTS	AC0, #9				; ACO << 9

		ADD		AC1, AC0 			; L43: AC0 = AC0 + AC1

		MOV		*AR2, AC2			; L45: T1 = rho[0]
		MOV 	*AR2, AC1			; AC1 = T1 -> rho[0]
		SFTS	AC1, #16			; Shift for multiplication (check Mneumonic Instructions)
		SFTS	AC2, #16
		MPY		AC2, AC1			; AC1 = AC1 * rho[0] -> rho[0] * rho[0]

		ADD		#65535, AC1			; L46: AC1 = AC1 + 32768
		ADD		#65535, AC1
		ADD		#2, AC1

		SFTS	AC1, #-18			; L47: AC1>>18

		AADD	T3, AR0
		MOV		*AR0, AC3			; L48: AR6 = s_circ[-2]
		ASUB	T3, AR0
		MOV		AC3, *AR7
		MOV		*AR7, AC2	;AND HERE
		SFTS	AC3, #16
		SFTS	AC1, #16			; Shift for multiplication (check Mneumonic Instructions)
		MPY		AC3, AC1			; AC1 = AR6*HI(AC1)

		SUB		AC1, AC0			; L50: AC0 = AC0 - AC1
		ADD		#2048, AC0 			; L51: AC0 = AC0 + 2048

		SFTS	AC0, #-12			; L53: AC0>>12
		MOV		*AR3, AC1
		ADD		AC1, AR0
		MOV		AC0, *AR0			; s[0] = s_circ[0]
		SUB		AC1, AR0

		;STEP 3): update e
		MOV		*AR1, AC1			; L56: AC0 = *a
		SFTS	AC1, #16			; Shift for multiplication (check Mneumonic Instructions)
		MPYM	*AR5, AC1			; AC0 = AR5*AC0 -> s_circ[-1]*a

		MOV		*AR7, AC2	;HERE!		; L57: AC2 = s_circ[-2]
		MOV		*AR3, T1
		AADD	T1, AR0
		MOV 	*AR0, AC0			; AC3 = s[0]
		ASUB	T1, AR0
		SFTS	AC2, #14			; AC2<<12
		SFTS	AC0, #14			; AC3<<12
		ADD		AC2, AC0			; AC2 += AC3 -> s[0]
		SUB		AC1, AC0			; AC2-= AC0

		ADD		#1024, AC0			; L58: AC2+= 256

		SFTS	AC0, #-11			; L59: AC2 -> AC0 >> 11
		MOV		AC0, T0				; e = AC0

		;STEP 4): update a
		AMOV 	#2<<13, T1			; L62
		MOV		#200, AC0
		SFTS	AC0, #16
		MPY		T1, AC0

		ADD		#8192, AC0			; L63

		SFTS	AC0, #-14			; L64

		MOV		*AR5, AC1			; L66
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

		ADD 	#1, *AR3
		;End of code

		POP mmap(ST2_55)			; Restore status registers
		POP	mmap(ST1_55)
		POP	mmap(ST0_55)

		RET							; Exit function call
