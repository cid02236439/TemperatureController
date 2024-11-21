#include <xc.inc>

global  ADC_Setup, ADC_Read, hex_to_deci_converter     
    
psect	udata_acs   ; reserve data space in access ram
ARG1L:    ds	1
ARG1H:    ds	1
ARG2L:    ds	1
ARG2H:    ds	1
    
BRG1H:	  ds	1
BRG1M:	  ds	1
BRG1L:	  ds	1
BRG2:	  ds	1

RES0:	ds  1
RES1:	ds  1
RES2:	ds  1
RES3:	ds  1

DIGIT1:	ds  1
DIGIT2:	ds  1
DIGIT3:	ds  1
DIGIT4:	ds  1
    
    
psect	adc_code, class=CODE
ADC_Setup:
	bsf	TRISA, PORTA_RA0_POSN, A  ; pin RA0==AN0 input
	movlb	0x0f
	bsf	ANSEL0	    ; set AN0 to analog
	movlb	0x00
	movlw   0x01	    ; select AN0 for measurement
	movwf   ADCON0, A   ; and turn ADC on
	movlw   0x30	    ; Select 4.096V positive reference
	movwf   ADCON1,	A   ; 0V for -ve reference and -ve input
	movlw   0xF6	    ; Right justified output
	movwf   ADCON2, A   ; Fosc/64 clock and acquisition times
	return

ADC_Read:
	bsf	GO	    ; Start conversion by setting GO bit in ADCON0
adc_loop:
	btfsc   GO	    ; check to see if finished
	bra	adc_loop
	return

;;;	
long_16x16_multiplication:
	MOVF	ARG1L, W, A
	MULWF	ARG2L, A ; ARG1L * ARG2L-> 
		    ; PRODH:PRODL 
	MOVFF	PRODH, RES1 ; 
	MOVFF	PRODL, RES0 ; 
	; 
	MOVF	ARG1H, W, A 
	MULWF	ARG2H, A ; ARG1H * ARG2H-> 
		    ; PRODH:PRODL 
	MOVFF	PRODH, RES3 ; 
	MOVFF	PRODL, RES2 ; 
	; 
	MOVF	ARG1L, W, A 
	MULWF	ARG2H, A ; ARG1L * ARG2H-> 
		    ; PRODH:PRODL 
	MOVF	PRODL, W, A ; 
	ADDWF	RES1, 1, 0 ; Add cross 
	MOVF	PRODH, W, A ; products 
	ADDWFC	RES2, 1, 0 ; 
	CLRF	WREG, A ; 
	ADDWFC	RES3, 1, 0 ; 
			; 
	MOVF	ARG1H, W, A ; 
	MULWF	ARG2L, A ; ARG1H * ARG2L-> 
		    ; PRODH:PRODL 
	MOVF	PRODL, W, A ; 
	ADDWF	RES1, 1, 0 ; Add cross 
	MOVF	PRODH, W, A ; products 
	ADDWFC	RES2, 1, 0 ; 
	CLRF	WREG, A ; 
	ADDWFC	RES3, 1, 0 ;
	
	return

asymmetric_24x8_multiplication:
	MOVF	BRG1L, W, A
	MULWF	BRG2, A ; BRG1L * BRG2-> 
		    ; PRODH:PRODL 
	MOVFF	PRODH, RES1 ; 
	MOVFF	PRODL, RES0 ; 
	; 
	MOVF	BRG1M, W, A 
	MULWF	BRG2, A ; BRG1M * BRG2-> 
		    ; PRODH:PRODL 
		    
	MOVFF	PRODH, RES2 ;
	MOVF	PRODL, W, A ; 
	ADDWFC	RES1, 1, 0 ; Add cross ; 
	CLRF	WREG, A ; 
	ADDWFC	RES2, 1, 0 ; 
			; 
	MOVF	BRG1H, W, A ; 
	MULWF	BRG2, A ; BRG1H * BRG2-> 
		    ; PRODH:PRODL 
	MOVF	PRODL, W, A ; 
	ADDWF	RES1, 1, 0 ; Add cross 
	MOVF	PRODH, W, A ; products 
	ADDWFC	RES2, 1, 0 ; 
	CLRF	WREG, A ; 
	ADDWFC	RES3, 1, 0 ;
	
	return
    
	
hex_to_deci_converter:
	;;; First Multiplication
	MOVFF   ADRESH, ARG1H
	MOVFF   ADRESL, ARG1L

	MOVLW   0x41
	MOVWF   ARG2H, A
	MOVLW   0x8A
	MOVWF   ARG2L, A

	CALL    long_16x16_multiplication

	MOVFF   RES3, DIGIT1    ;store the most significant byte

	;;; Second Multiplication
	MOVFF   RES2, BRG1H
	MOVFF   RES1, BRG1M
	MOVFF   RES0, BRG1L

	MOVLW   0x0A
	MOVWF   BRG2, A

	CALL    asymmetric_24x8_multiplication

	MOVFF   RES3, DIGIT2

	;;; Third Multiplication
	MOVFF   RES2, BRG1H
	MOVFF   RES1, BRG1M
	MOVFF   RES0, BRG1L

	CALL    asymmetric_24x8_multiplication

	MOVFF   RES3, DIGIT3

	;;; Fourth Multiplication
	MOVFF   RES2, BRG1H
	MOVFF   RES1, BRG1M
	MOVFF   RES0, BRG1L

	CALL    asymmetric_24x8_multiplication

	MOVFF   RES3, DIGIT4

	call digit_combiner

	return
    
digit_combiner:
	;;; Higher byte
	MOVLW   0x10
	MULWF   DIGIT1, A ;most significant digit in deci
	MOVF    PRODL, W, A
	ADDWF   DIGIT2, 0, 0 ;store result on W
	MOVWF   ADRESH, A

	;;; Lower byte
	MOVLW   0x10
	MULWF   DIGIT3, A ;most significant digit in deci
	MOVF    PRODL, W, A
	ADDWF   DIGIT4, 0, 0 ;store result on W
	MOVWF   ADRESL, A
    
    return
    
end