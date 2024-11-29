#include <xc.inc>

;extrn	UART_Setup, UART_Transmit_Message  ; external uart subroutines
extrn	LCD_Setup, LCD_Write_Message, LCD_Write_Hex,LCD_Send_Byte_I ; external LCD subroutines
extrn	ADC_Setup, ADC_Read, hex_to_deci_converter   ; external ADC subroutines
extrn	ADC_Potentiometer_Setup, ADC_Potentiometer_Read, potentiometer_hex_to_deci_converter
extrn	delay
    
psect	udata_acs   ; reserve data space in access ram
;counter:    ds 1    ; reserve one byte for a counter variable
current_temp_H:	ds  1
current_temp_L:	ds  1
set_temp_H:	ds  1
set_temp_L:	ds  1
    
psect	udata_bank4 ; reserve data anywhere in RAM (here at 0x400)
myArray	    EQU 0x81 ; point to the adress in the ram
myArray2    EQU	0x91 ; point to address in the ram
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
	
	goto	start
	
	; ******* Define Helpful Subroutine ****************************************
;;; 1. Tempearture Reading/Writing Subroutines	
read_current_temp:
	;;;
	; Read current temperature from the sensor
	;;;
	call	ADC_Setup	; setup ADC
	call	ADC_Read
	call	hex_to_deci_converter
	movff	ADRESH, current_temp_H, A
	movff	ADRESL, current_temp_L, A
	return
	
write_current_temp:
	;;;
	; Display the current temperature on the LCD screen
	;;;
	movff	current_temp_H, 0x8d, A
	call	LCD_Write_Hex
	
	movff	current_temp_L, 0x8e, A
	call	LCD_Write_Hex
	return
	
read_set_temp:
	;;;
	; Read set temperature from the potentiometer
	;;;
	call	ADC_Potentiometer_Setup	; setup ADC
	call	ADC_Potentiometer_Setup
	call	potentiometer_hex_to_deci_converter
	movff	ADRESH, set_temp_H, A
	movff	ADRESL, set_temp_L, A
	return
	
write_set_temp:
	;;;
	; Display the set temperature on the LCD screen
	;;;
	movff	set_temp_H, 0x9a, A
	call	LCD_Write_Hex
	
	movff	set_temp_L, 0x9b, A
	call	LCD_Write_Hex
	return
	
	
	; ******* Main programme ****************************************
start: 	
write_first_line:
	movlw	0x80
	call	LCD_Send_Byte_I
	
	movlw	myTable_l-1	; output message to LCD
				; don't send the final carriage return to LCD
	lfsr	2, myArray
	call	LCD_Write_Message
	
	call	read_current_temp
	call	write_current_temp
	
	
write_second_line:
	movlw	0xc0
	call	LCD_Send_Byte_I
	
	movlw	myTable_2-1	; output message to LCD
				; don't send the final carriage return to LCD
	lfsr	2, myArray2
	call	LCD_Write_Message
		
	call	read_set_temp
	call	write_set_temp
	
	end	rst

	
