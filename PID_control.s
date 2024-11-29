#include <xc.inc>
    
; global
    
psect	udata_acs  
ref:	    ds  1
K_p:	    ds  1
    
current:    ds	1
err:	    ds  1
    
proportional:	ds  1
integral:	ds  1
derivative:	ds  1
    
output:	    ds	1
	
psect	PID_code, class=CODE
;;; 1. Initialise constans
ref_signal_setup:
    ;;;
    ; A subroutine to take the target temperture from WREG and store it into ref
    ;;;
    MOVWF   ref, A
    RETURN
    
tuning_control_setup:
    ;;;
    ; A subroutine to set the proportional control coefficient
    ;;;
    MOVLW   0x0A
    MOVWF   K_p, A
    RETURN
   

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; 2. Define some handy subroutines
error_signal_calculation:
    MOVWF   current, A
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
    MOVWF   proportional, A
total:
    ADDLW   0x00
    ADDWF   proportional, 0, 0
    MOVWF   output, A
    RETURN

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; 3. PID sequence
PID_control_run:
    ;;;
    ; Require current value input via WREG
    ;;;
    call    error_signal_calculation
    call    error_sign_checking
    RETURN

    
    


