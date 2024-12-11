#include <xc.inc>

;extrn	UART_Setup, UART_Transmit_Message  ; external uart subroutines
extrn	LCD_Setup, LCD_Write_Message, LCD_Write_Hex,LCD_Send_Byte_I ; LCD subroutines
extrn	ADC_Setup, ADC_Read, hex_to_deci_converter   ; ADC subroutines
extrn	ADC_Potentiometer_Setup, ADC_Potentiometer_Read, potentiometer_hex_to_deci_converter ; Potentiometer subroutines
extrn	check, current_deci, ref_deci, PID_control_run, output, current, ref
extrn	UART_Setup, UART_Transmit_Message
    
global	tempH, tempL
    
psect	udata_acs   ; reserve data space in access ram
counter:    ds 1    ; reserve one byte for a counter variable
delay_count:	ds 1    ; reserve one byte for counter in the delay routine
    
tempH:	ds  1
tempL:	ds  1
    
psect	udata_bank4 ; reserve data anywhere in RAM (here at 0x400)
myArray	   EQU 0x80 ; point to the adress in the ram
myArray2    EQU	0x90 ; point to address in the ram
;message_length   EQU	0x02
   
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
	call	UART_Setup	; setup UART
	call	LCD_Setup	; setup UART
	
	movlw	0x00	;setup port e for output
	movwf	TRISE, A
	
	goto	start
	
	; ******* Main programme ****************************************
start: 	
write_first_line:
	lfsr	0, myArray	; Load FSR0 with address in RAM	
	movlw	low highword(myTable)	; address of data in PM
	movwf	TBLPTRU, A		; load upper bits to TBLPTRU
	movlw	high(myTable)	; address of data in PM
	movwf	TBLPTRH, A		; load high byte to TBLPTRH
	movlw	low(myTable)	; address of data in PM
	movwf	TBLPTRL, A		; load low byte to TBLPTRL
	movlw	myTable_l	; bytes to read
	movwf 	counter, A		; our counter register
loop: 	
	tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0; move data from TABLAT to (FSR0), inc FSR0	
	decfsz	counter, A		; count down to zero
	bra	loop		; keep going until finished	
    
;	movlw	myTable_l	; output message to UART
;	lfsr	2, myArray
;	call	UART_Transmit_Message
	
	;;; 1.1 Print out "Temperature:"
	movlw	0x80
	call	LCD_Send_Byte_I
	movlw	myTable_l-1	; output message to LCD
				; don't send the final carriage return to LCD
	lfsr	2, myArray
	call	LCD_Write_Message
	
current_temp:
	;;; 1.2 Print out current temperature
	call	ADC_Setup	; setup ADC
	call	ADC_Read
	
	call	hex_to_deci_converter
	movf	ADRESH, W, A
	movff	ADRESH, current_deci, A
	call	LCD_Write_Hex
;	movf	ADRESL, W, A
;	movff	ADRESL, 0x8e, A
;	;call	LCD_Write_Hex
	
	
	
write_second_line:	
	lfsr	0, myArray2	; Load FSR0 with address in RAM	
	movlw	low highword(myTable2)	; address of data in PM
	movwf	TBLPTRU, A		; load upper bits to TBLPTRU
	movlw	high(myTable2)	; address of data in PM
	movwf	TBLPTRH, A		; load high byte to TBLPTRH
	movlw	low(myTable2)	; address of data in PM
	movwf	TBLPTRL, A		; load low byte to TBLPTRL
	movlw	myTable_2	; bytes to read
	movwf 	counter, A		; our counter register
loop2: 	
	tblrd*+			; one byte from PM to TABLAT, increment TBLPRT
	movff	TABLAT, POSTINC0; move data from TABLAT to (FSR0), inc FSR0	
	decfsz	counter, A		; count down to zero
	bra	loop2		; keep going until finished
	
	;;; 2.1 Print out "Target:"
	movlw	0xc0
	call	LCD_Send_Byte_I
	
	movlw	myTable_2-1	; output message to LCD
				; don't send the final carriage return to LCD
	lfsr	2, myArray2
	call	LCD_Write_Message
	
target_temp:
	;;; 2.2 Print out set temperature
	call	ADC_Potentiometer_Setup	;setup ADC for Potentiometer
	call	ADC_Potentiometer_Read
	
	call	potentiometer_hex_to_deci_converter
	movf	ADRESH, W, A
	movff	ADRESH, ref_deci, A
	call	LCD_Write_Hex
;	movf	ADRESL, W, A
;	movff	ADRESL, 0x9b, A
	;call	LCD_Write_Hex
	
;export_current_temp:
;	movlw	0x02
;	lfsr	2,  current_deci
;	call	UART_Transmit_Message
	
control:
	;;; Convert current from deci to hex
	movlw	0x0F
	andwf	current_deci, 0, 0
	movwf	tempL, A
	
	swapf	current_deci, 0, 0
	andlw	0x0F
	mullw	0x0A
	movff	PRODL, tempH, a
	
	movf	tempH, W
	addwf	tempL, 0, 0
	movwf	current
    
	;;; Convert ref from deci to hex
	movlw	0x0F
	andwf	ref_deci, 0, 0
	movwf	tempL, A
	
	swapf	ref_deci, 0, 0
	andlw	0x0F
	mullw	0x0A
	movff	PRODL, tempH, a
	
	movf	tempH, W
	addwf	tempL, 0, 0
	movwf	ref
	
;	call check
	call PID_control_run
	
	
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
