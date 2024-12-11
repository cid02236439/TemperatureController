#include <xc.inc>
    
global check, current_deci, ref_deci, PID_control_run, output, err, current, ref
    
psect	udata_acs  
ref:	    ds  1
K_p:	    ds  1
    
current:    ds	1
err:	    ds  1
    
proportional:	ds  1
integral:	ds  1
derivative:	ds  1
    
output:	    ds	1
    
current_deci:	ds  1
ref_deci:   ds	1
	
psect	PID_code, class=CODE
;;; 1. Initialise constans    
tuning_control_setup:
    ;;;
    ; A subroutine to set the proportional control coefficient
    ;;;
    MOVLW   0x05
    MOVWF   K_p, A
    RETURN
   

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; 2. Define some handy subroutines
error_signal_calculation:
    MOVF    current, W, A
    SUBWF   ref, 0, 0 ;Store err = (current-ref) in WREG
    MOVWF   err, A
    RETURN
    
error_sign_checking:
    BN	negative_err_handling
    BNN	positive_err_handling
    RETURN
negative_err_handling:
    ;;;
    ; Turn off heating element if ref < current
    ;;;
    MOVLW   0x00
    MOVWF   output, A
    RETURN
positive_err_handling:
    ;;;
    ; Calculate an output voltage if ref < current
    ;;;
    CALL    output_voltage_calculation
    RETURN
    
    
output_voltage_calculation:
propotional_term:
    MOVF    K_p, W, A
    MULWF   err, A ;K_p * err
    MOVFF   PRODL, proportional, A
total:
    ADDLW   0x00
    ADDWF   proportional, 0, 0
    MOVWF   output, A
    movwf   PORTE, A
    RETURN
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; 3. PID sequence
PID_control_run:
    ;;;
    ; Require current value input via WREG
    ;;;
    call    tuning_control_setup
    call    error_signal_calculation
    call    error_sign_checking
    MOVFF   output, PORTE, A
    RETURN

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
check:			; checks if the current tmeperature > target temperature  
	movf	current_deci, W, A	;current temperature
	cpfslt	ref_deci, A	;compare if target temp (F) < current (W) and skip next line if true
	bra switch_on
	bra switch_off
	
switch_on:		; switches the heater on if called
	movlw	0x80
	movwf	PORTE, A
	return
	
switch_off: ;switches heater off if called
	movlw	0x00
	movwf	PORTE, A
	return    
    
end

