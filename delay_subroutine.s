#include <xc.inc>
    
global delay
    
psect	udata_acs   ; reserve data space in access ram
delay_count:ds 1    ; reserve one byte for counter in the delay routine
    
psect	PID_code, class=CODE
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


