#include <xc.inc>

;extrn	UART_Setup, UART_Transmit_Message  ; external uart subroutines
extrn	LCD_Setup, LCD_Write_Message, LCD_Write_Hex,LCD_Send_Byte_I ; LCD subroutines
extrn	ADC_Setup, ADC_Read, hex_to_deci_converter   ; ADC subroutines
extrn	ADC_Potentiometer_Setup, ADC_Potentiometer_Read, potentiometer_hex_to_deci_converter ; Potentiometer subroutines
extrn	check, current, ref
    
psect	udata_acs   ; reserve data space in access ram
counter:    ds 1    ; reserve one byte for a counter variable
delay_count:ds 1    ; reserve one byte for counter in the delay routine
    
psect	udata_bank4 ; reserve data anywhere in RAM (here at 0x400)
myArray	EQU 0x80 ; point to the adress in the ram
myArray2    EQU	0x90 ; point to address in the ram
psect	data    
	; ******* myTable, data in programme memory, and its length *****
myTable:
	db	'0','T','e','m','p','e','r','a','t','u','r','e',':',0xa0
					; message, plus carriage return
	myTable_l   EQU	14	; length of data
	align	2


myTable2:
	db	'0','T','a','r','g','e','t',':',0xa0
	myTable_2   EQU	9
	align	2
	
psect	code, abs	
rst: 	org 0x0
 	goto	setup

	; ******* Programme FLASH read Setup Code ***********************
setup:	bcf	CFGS	; point to Flash program memory  
	bsf	EEPGD 	; access Flash program memory
	;call	UART_Setup	; setup UART
	call	LCD_Setup	; setup UART
	
	movlw	0x00	;setup port e for output
	movwf	TRISE, A
	
	goto	start
	
	; ******* Main programme ****************************************
start: 	lfsr	0, myArray	; Load FSR0 with address in RAM	
	movlw	low highword(myTable)	; address of data in PM
	movwf	TBLPTRU, A		; load upper bits to TBLPTRU
	movlw	high(myTable)	; address of data in PM
	movwf	TBLPTRH, A		; load high byte to TBLPTRH
	movlw	low(myTable)	; address of data in PM
	movwf	TBLPTRL, A		; load low byte to TBLPTRL
	movlw	myTable_l	; bytes to read
	movwf 	counter, A		; our counter register
loop: 	tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0; move data from TABLAT to (FSR0), inc FSR0	
	decfsz	counter, A		; count down to zero
	bra	loop		; keep going until finished	
	;movlw	myTable_l	; output message to UART
	;lfsr	2, myArray
	;call	UART_Transmit_Message
	movlw	0x80
	call	LCD_Send_Byte_I
	
	movlw	myTable_l-1	; output message to LCD
				; don't send the final carriage return to LCD
	lfsr	2, myArray
	call	LCD_Write_Message
	
measure_loop:
	call	ADC_Setup	; setup ADC
	call	ADC_Read
	call	hex_to_deci_converter
	movf	ADRESH, W, A
	movff	ADRESH, 0x8d, A
	call	LCD_Write_Hex
	movf	ADRESL, W, A
	movff	ADRESL, 0x8e, A
	;call	LCD_Write_Hex
	

		; goto current line in code

start2: 	lfsr	0, myArray2	; Load FSR0 with address in RAM	
	movlw	low highword(myTable2)	; address of data in PM
	movwf	TBLPTRU, A		; load upper bits to TBLPTRU
	movlw	high(myTable2)	; address of data in PM
	movwf	TBLPTRH, A		; load high byte to TBLPTRH
	movlw	low(myTable2)	; address of data in PM
	movwf	TBLPTRL, A		; load low byte to TBLPTRL
	movlw	myTable_2	; bytes to read
	movwf 	counter, A		; our counter register
loop2: 	tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0; move data from TABLAT to (FSR0), inc FSR0	
	decfsz	counter, A		; count down to zero
	bra	loop2		; keep going until finished
	
	movlw	0xc0
	call	LCD_Send_Byte_I
	
	movlw	myTable_2-1	; output message to LCD
				; don't send the final carriage return to LCD
	lfsr	2, myArray2
	call	LCD_Write_Message
	
	
	
potentiometer_loop:
	call	ADC_Potentiometer_Setup	;setup ADC for Potentiometer
	call	ADC_Potentiometer_Read
	call	potentiometer_hex_to_deci_converter
	movf	ADRESH, W, A
	movff	ADRESH, 0x9a, A
	call	LCD_Write_Hex
	movf	ADRESL, W, A
	movff	ADRESL, 0x9b, A
	;call	LCD_Write_Hex
	
	call check
;switch_on:		; switches the heater on if called
;	movlw	0x00
;	movwf	PORTE, A
	
; a delay subroutine if you need one, times around loop in delay_count
delay:	decfsz	delay_count, A	; decrement until zero
	bra	delay
	return

delay1: decfsz	0x20, A
	bra delay1
	decfsz	0x21, A
	bra delay1
	decfsz	0x22, A
	bra delay1
	return

	end	rst	
