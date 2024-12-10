#include <xc.inc>

global  ADC_Potentiometer_Setup, ADC_Potentiometer_Read, potentiometer_hex_to_deci_converter
    
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
    
temp_DIGIT: ds	1
    
    
psect	adc_code, class=CODE
ADC_Potentiometer_Setup:
	bsf	TRISA, PORTA_RA1_POSN, A  ; pin RA1==AN1 input
	movlb	0x0f
	bsf	ANSEL1	    ; set AN0 to analog
	movlb	0x00
	movlw   0x05	    ; select AN0 for measurement
	movwf   ADCON0, A   ; and turn ADC on
	movlw   0x30	    ; Select 4.096V positive reference
	movwf   ADCON1,	A   ; 0V for -ve reference and -ve input
	movlw   0xF6	    ; Right justified output
	movwf   ADCON2, A   ; Fosc/64 clock and acquisition times
	return

ADC_Potentiometer_Read:
	bsf	GO	    ; Start conversion by setting GO bit in ADCON0
adc_loop:
	btfsc   GO	    ; check to see if finished
	bra	adc_loop
	CALL reading_shift
	return

;;;	
potentiometer_hex_to_deci_converter:
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
	
	CALL digit_shift
;	call digit_shift
	call digit_combiner

	return
	
long_16x16_multiplication:
    
	;movlw	0x04
	;movwf	ARG1H, a
	;movlw	0xd2
	;movwf	ARG1L, a
	;movlw	0x41
	;movwf	ARG2H, a
	;movlw	0x8a
	;movwf	ARG2L, a
    
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
	
	;MOVFF	RES3, ADRESH, A ;TESTING
	;MOVFF	RES2, ADRESL, A	;TESTING
	
	return

asymmetric_24x8_multiplication:
	
	;MOVLW	0x3b
	;movwf	BRG1H, A
	;MOVLW	0xEB
	;;movwf	BRG1M, A
	;MOVLW	0x34
	;movwf	BRG1L, A
	;MOVLW	0x0A
	;movwf	BRG2, A
	
	;LOW * 10
	MOVF	BRG1L, W, A
	MULWF	BRG2, A ; BRG1L * BRG2-> PRODH:PRODL 
	MOVFF	PRODH, RES1 ; 
	MOVFF	PRODL, RES0 ; 
	
	;MIDDLE * 10
	MOVF	BRG1M, W, A 
	MULWF	BRG2, A ; BRG1M * BRG2-> PRODH:PRODL 
	MOVFF	PRODH, RES2 ;
	MOVF	PRODL, W, A ; 
	ADDWF	RES1, 1, 0 ; Add cross ; 
	CLRF	WREG, A ; 
	ADDWFC	RES2, 1, 0 ; 
			; 
	;HIGH * 10
	MOVF	BRG1H, W, A ; 
	MULWF	BRG2, A ; BRG1H * BRG2-> PRODH:PRODL 
	
	;MOVFF	PRODH, RES3
	;MOVF	PRODL, W, A
	;ADDWFC	RES2, 1, 0
	;CLRF	WREG, A
	;ADDWFC	RES3,1,0
	
	MOVFF	PRODH, RES3 ;
	MOVF	PRODL, W, A ; 
	ADDWF	RES2, 1, 0 ; Add cross 
	CLRF	WREG, A ; 
	ADDWFC	RES3, 1, 0 ;
	
	;MOVFF	RES3, ADRESH, A
	;MOVFF	RES2, ADRESL, A
	
	return

    
digit_combiner:
	;;; Higher byte
	;movlw	0x05
	;movwf	DIGIT1, a
	;movlw	0x02
	;movwf	DIGIT2, a
	;movlw	0x03
	;movwf	DIGIT3, a
	;movlw	0x04
	;movwf	DIGIT4, a
	
	MOVLW   0x10
	MULWF   DIGIT2, A ;most significant digit in deci
	MOVF    PRODL, W, A
	ADDWF   DIGIT3, 0, 0 ;store result on W
	MOVWF   ADRESH, A

;	;; Lower byte
;	MOVLW   0x10
;	MULWF   DIGIT3, A ;most significant digit in deci
;	MOVF    PRODL, W, A
;	ADDWF   DIGIT4, 0, 0 ;store result on W
;	MOVWF   ADRESL, A
    
	return
    
reading_shift:
	MOVLW	0x08 ;shift potentiometer reading by 10
	;ADDWF	ADRESL, 1, 0 ;store result on ADRESHL
	;CLRF	WREG, A
	;ADDWFC	ADRESH
	ADDWF	ADRESH, A
	RETURN
	
digit_shift:
	MOVF	DIGIT1, W, A
	MOVFF	DIGIT2,	temp_DIGIT, A
	MOVWF	DIGIT2, A
	
	MOVFF	DIGIT3,	DIGIT4, A
	MOVFF	temp_DIGIT, DIGIT3, A
	
	MOVLW	0x00
	MOVWF	DIGIT1, A
	RETURN
end





