ORG 00H		;Starting address
SJMP MAIN		;Jumps to the MAIN function

ORG 003H		; Starting address for the ISR(INT0)
ACALL ISR		; Calls the ISR (interrupt service routine)
RETI		; Retutn from the interrput
 
MAIN:
;Setting the external interrupt0
SETB TCON.0		; Interrupt generated by a falling edge signal at INT0 (pin12)
SETB IE.0		; Enables the external interrupt0 INT0
SETB IE.7		; Enables the global interrupt control
MOV R7,#00H		; Flag to control the movement of the motor (control flag)

; Initializing push button switches as input device at P0.0, P0.1, P0.2 (0000 0111b) (1->input), (0->output)

SETB P0.0  ;FULL STEP
SETB P0.1 ;HALF STEP
SETB P0.2 ;KEYPAD

READ_PORT0:                              ;READP0
	JB P0.0,HALF_STEP                ;IF BIT =1 GO HALF STEP
/*******************************************************************************************
*					SWITCHES
********************************************************************************************/

FS_SWITCH:		                 ; If FS_SWITCH is pressed (Full step sequence)//FS_SWITCH
	CJNE R7,#00H,AGAIN		 ; Check the control flag value
	                               ; While the control flag is zero:
	ACALL DELAY
	
	MOV R1,#03H
	MOV P2,R1
	ACALL DELAY

	MOV R1,#09H
	MOV P2,R1
	ACALL DELAY
	
	MOV R1,#0CH
	MOV P2,R1
	ACALL DELAY
	
	MOV R1,#06H
	MOV P2,R1
	SJMP FS_SWITCH
	
	    
AGAIN:		                           ; Make the control flag zero again after the interrupt happens and reread P0 again
	MOV R7,#00H	
        SJMP READ_PORT0		           ; Re read port value again.
    
    
HALF_STEP:		                  ; If FS_SWITCH is not pressed:	                     
	JB P0.1,GET_FROM_KEY              ;IF BIT =1 GO KEYPAD
	
HS_SWITCH:		                  ; If switch 2 is pressed (Full step sequence) ;HS_SWITCH
	CJNE R7,#00H,AGAIN		  ;Checking the value of the control flag
	                                  ; While the control flag is zero:
	ACALL DELAY
	
	MOV R1,#02H
	MOV P2,R1
	ACALL DELAY
	
	MOV R1,#03H		
	MOV P2,R1
	ACALL DELAY
	
	MOV R1,#01H
	MOV P2,R1
	ACALL DELAY
	
	MOV R1,#09H
	MOV P2,R1
	ACALL DELAY
	
	MOV R1,#08H
	MOV P2,R1
	ACALL DELAY

        MOV R1,#0CH
	MOV P2,R1
	ACALL DELAY
	
	MOV R1,#04H
	MOV P2,R1
	ACALL DELAY
	
	MOV R1,#06H
	MOV P2,R1
	
	SJMP HS_SWITCH
	
	
GET_FROM_KEY:	                 ; If FS_SWITCH is not pressed
	JB P0.2,READ_PORT0		 
	 
KEYPAD:		; Rotate the stepper motor with a given angle from the keypad
	MOV R1,#0D		          ;Initializing the least significant byte of the angle with zero
	MOV R2,#0D		         ; Initializing the most significant byte of the angle with zero
	ACALL INTERFACING_KEYPAD	; Getting the key from keypad	
/*******************************************************************************************
*				To work on keypad
********************************************************************************************/
CHECK:
	CJNE A,#10D,FORMNUM		 ;If the key value is (10 --> '*') rotate to the given angle, if not form the angle value
	
ANGLE0:	
	CJNE R1,#0D,ANGLE45		; if (R1 == 0 && R2 == 0) rotate to angle 0, else jumb to ANGLE45
	CJNE R2,#0H,ANGLE45
	MOV P2,#06H
	SJMP READ_PORT0
ANGLE45:
        CJNE R1,#45D,ANGLE90		; if (R1 == 45 && R2 == 0) rotate to angle 45, else jumb to ANGLE90
	CJNE R2,#0H,ANGLE90
	MOV P2,#02H
	AJMP READ_PORT0	
ANGLE90:
        CJNE R1,#90D,ANGLE135		; if (R1 == 90 && R2 == 0) rotate to angle 90, else jumb to ANGLE135
	CJNE R2,#0H,ANGLE135
	MOV P2,#03H
	AJMP READ_PORT0
ANGLE135:
        CJNE R1,#135D,ANGLE180		; if (R1 == 135 && R2 == 0) rotate to angle 135, else jumb to ANGLE180
	CJNE R2,#0H,ANGLE180
	MOV P2,#01H
	AJMP READ_PORT0
ANGLE180:
        CJNE R1,#180D,ANGLE225		;if (R1 == 180 && R2 == 0) rotate to angle 180, else jumb to ANGLE225
	CJNE R2,#0H,ANGLE225
	MOV P2,#09H
	AJMP READ_PORT0
ANGLE225:
    	CJNE R1,#225D,ANGLE270		; if (R1 == 225 && R2 == 0) rotate to angle 225, else jumb to ANGLE270
	CJNE R2,#0H,ANGLE270
	MOV P2,#08H
	AJMP READ_PORT0		
ANGLE270:
        CJNE R1,#0EH,ANGLE315		; if (R1 == 0EH && R2 == 01H) rotate to angle 270, else jumb to ANGLE315
	CJNE R2,#01H,ANGLE315
	MOV P2,#0CH
	AJMP READ_PORT0
ANGLE315:
        CJNE R1,#3BH,ABOVE		       ; if (R1 == 3BH && R2 == 01H) rotate to angle 315, else jumb to ABOVE
	CJNE R2,#1H,ABOVE
	MOV P2,#04H
	AJMP READ_PORT0
ABOVE:		                      ; If angle is >= 360 degree, subtract 360 and repeat again
        MOV A,R1
	CLR PSW.7		     ; Clear Carry flag (no SUB) // A=A-68-0
	SUBB A,#68H		     ; As (360D --> 0168H), subtract 68H from the least significant byte of the angle value (R1 - 68H) //A=A-C-IMMEDIATE
	MOV R1,A		    ; Store the result in R1
	MOV A,R2		
	SUBB A,#01H		  ; subtract 01H from the most significant byte of the angle value (R2 - 01H)
	MOV R2,A		  ; Store the result in R2
	SJMP ANGLE0		 ; Check Angle value again
	
;To Form the angle value (digits) 
;((R2->R1) * 10) + NEW KEY //R1=R2=0 in first A is input 

FORMNUM:    	    	;ASSUME we enter 315 first A=3 then A=1 then A=5			
	MOV R0,A     	;1- R0=A=3,1,5        		   
	MOV A,R1     	;2- A=R1=0,3,31							
	MOV B,#10D   	;3- B=10D	 			
	MUL AB	     	;4- A*B,A=0B=0,A=30,B=0, A=36H,B=1H			
	MOV R1,A	;5- R1=A=0,30,36H			
	MOV R3,B	;6- R3=B=0,0,1H			
	MOV A,R2	;7- A=R2=0,0,0
	MOV B,#10D	;8- B=10			
	MUL AB      	;9- A*B=0,0,0			
	ADD A,R3	;10-A=A+R3=0,0,1H			
	MOV R2,A	;11-R2=A=0,0,1H			
    	MOV A,R1	;12-A=R1=0,30,36H			
	ADD A,R0	;13-A=A+R0=3,31,3B			
	MOV R1,A	;14-R1=A=3,31,3B			
	MOV A,R2	;15-A=R2=0,0,1H			
	ADDC A,#0D	;16-A=A+C+0=0,0,1H			
	MOV R2,A	;17-R2=A=0,0,1H			
	
	ACALL INTERFACING_KEYPAD
	AJMP CHECK
/*******************************************************************************************
*			INTERFACING KEYPAD
********************************************************************************************/	
;Function to get the key from 3*4 keypad
INTERFACING_KEYPAD:
/* each time only one of the column pins will be output
   and the rest will be input pins include the row pins */
   
MOV P1,#11111111B               ; loads P1 with all 1's
COLUMN0:
        SETB P1.6		; Make the last column as input pin
        CLR P1.4		; Make column 1 as output
	MOV R0,#0D		; Store column number
	MOV R5,#1D		; Load R5 with the next column number
	SJMP ROWS 		; Scan the rows to get the key

COLUMN1:
	SETB P1.4
        CLR P1.5 
	MOV R0,#1D
	MOV R5,#2D
	SJMP ROWS 
		
COLUMN2:
	SETB P1.5
        CLR P1.6
	MOV R0,#2D
	MOV R5,#0D
	SJMP ROWS 		
ROWS:
	 ROW0:
		 JB P1.0,ROW1		    ; Checks whether ROW 0 is LOW (If key is pressed) and if not(P1.0 is 1) jump to ROW 1
		 MOV R2,#0D		   ; Store ROW number
		 SJMP CAPTURE		 ; Jump to CAPTURE to get the key value

	 ROW1:
		 JB P1.1,ROW2
		 MOV R2,#1D
		 SJMP CAPTURE

	 ROW2:
		 JB P1.2,ROW3
		 MOV R2,#2D
		 SJMP CAPTURE

	 ROW3:
		 JB P1.3,NEXT		; If ROW 3 is HIGH (If key is not pressed) Jumb to NEXT to get the next column
		 MOV R2,#3D
		 SJMP CAPTURE
	 
NEXT:		                       ; Continuing to the next column (last column number is stored in R5)
	 CLM0:
		 CJNE R5,#0D,CLM1     ;Jumb to Column 0 if the last column was column 2
		 SJMP COLUMN0
         CLM1:
		 CJNE R5,#1D,CLM2
		 SJMP COLUMN1
	 CLM2:
		 SJMP COLUMN2
CAPTURE:		;Getting the key value
	ACALL KEY_VALUE 
	RET            ;RETURN OF FUNCTION INTERFACING_KEYPAD
	  
KEY_VALUE:	     ; key value = ((row*N_col) + col + 1) = ((R2*3) + R0 +1)
	 MOV A,R2        
	 MOV B,#3D       ;N_COL 
	 MUL AB          ;A= LOWER BYTE , B=HIGHER BYTE 
	 MOV R2,A		 
	 MOV A,R0	     
	 ADD A,#1D      
	 ADD A,R2        
ZERO: 
	CJNE A,#11D,RETURN      ; If the key value is 11 return zero
	MOV A,#0D
RETURN:
        ACALL DELAY		; Wait 0.5 s 
	RET

/*******************************************************************************************
                                        OTHER FUNCTIONS
*******************************************************************************************/

/*
Assume the processor is clocked by a 12MHz crystal.
That means, the timer clock input will be 12MHz/12 = 1MHz
That means, the time taken for the timer to make one increment = 1/1MHz = 1uS 
2^16 = 65536 is the maximim number of counts possible for a 16 bit timer.
Let TH be the value value that has to be loaded to TH registed and TL be the value that has to be loaded to TL register.
Then, THTL =  Hexadecimal equivalent of (65536-X) where (65536-X) is considered in decimal.
*********

Let the required delay be 50000uS (ie; 50mS).
That means X = 50000
65536 – X =  65536 – 50000 = 15536.
64536 is considered in decimal and converting it t0 hexadecimal gives 3CB0
That means THTL = 3C
Therefore TH=FC and TL=B0
Program for generating 50mS delay using 8051 timer.
*/


DELAY:		                 ;DELAY(Timer) function of 0.5 sec
	MOV R4,#10D		     ; Counter of 10 as 10 * 50ms = 0.5 sec  
	BACK:
		MOV TMOD ,#01H	        ; Timer0 in mode 1 (over flow)	
	        MOV TH0 ,#03CH		;Initial value of timer0 (15536 decimal to count 50ms)  
		MOV TL0 ,#0B0H		;15536D = 3CB0
		SETB TCON.4		; Set TR0 in reg TCON(Timer Control Register) to start the timer
		L1:JNB TCON.5,L1        ; Wait untill the timer over flow flag is set (Jump if bit is not set)
		CLR TCON.4	        ; Clear TR0 in reg TCON to stop the timer
		CLR TCON.5		; Clear the timer over flow flag
		DJNZ R4 ,BACK         ; Decrement R4 and jump if not zero
	RET ;Return from DELAY
	
	
ISR:		// Interrupt service routine
	MOV R7,#01H		// Stopping the stepper motor
	RET		        // Jumps to RETI

END
