; This code is written for STM32F401RCT6
; Important Note: Backlight should have 5V (in hardware)

; Pin Connection 
;
;   +--------- TFT ---------+
;   |      D0   =  PA0      |
;   |      D1   =  PA1      |
;   |      D2   =  PA2      |
;   |      D3   =  PA3      |
;   |      D4   =  PA4      |
;   |      D5   =  PA5      |
;   |      D6   =  PA6      |
;   |      D7   =  PA7      |
;   |-----------------------|
;   |      RST  =  PA8      |
;   |      BCK  =  PA9      |
;   |      RD   =  PA10     |
;   |      WR   =  PA11     |
;   |      RS   =  PA12     |
;   |      CS   =  PA15     |
;   +-----------------------+
	AREA MYDATA, DATA , READWRITE
	;Variables
Current_Pointer 	DCD     0x0010
XO_Grid             DCD     0x0200
XO_Player1          DCD     0x0000 
XO_Player2          DCD     0x0000
PONG_BALLX 			DCD 	0x00A0
PONG_BALLY 			DCD 	0x00C8
PONG_BALLDIR 		DCD 	0x0000
PONG_P1 			DCD 	0x0078
PONG_P2 			DCD 	0x0078

    AREA RESET, CODE, READONLY
		
	IMPORT Ximg
	IMPORT Oimg
	IMPORT P1Wins
	IMPORT P2Wins
    IMPORT Draw
	IMPORT Score_P1_XO
    IMPORT Score_P2_XO
    IMPORT Point 
    IMPORT Pong_P1Wins
    IMPORT Pong_P2Wins
    IMPORT Pong_Score
    IMPORT Pong_Point
	IMPORT XO_ICON
    IMPORT PONG_ICON
    IMPORT VSAI
    IMPORT TwoPlayers
    IMPORT TIC_TAC_TOE
    IMPORT PongStart
    IMPORT PongPhOTO

		
    EXPORT __main

;Colors
BLACK       EQU     0x0000
NAVY        EQU     0x000F
DARKGREEN   EQU     0x03E0
PURPLE      EQU     0x780F
OLIVE       EQU     0x7BE0
LIGHTGREY   EQU     0xC618
DARKGREY    EQU     0x7BEF
BLUE        EQU     0x001F
GREEN       EQU     0x07E0
CYAN        EQU     0x07FF
RED         EQU     0xF800
MAGENTA     EQU     0xF81F
YELLOW      EQU     0xFFE0
WHITE       EQU     0xFFFF
ORANGE      EQU     0xFD20
;Pong Colors
BACKGROUND 	EQU		0x1025
PAD1_COLOR	EQU		0xF7E9
PAD2_COLOR	EQU		0xF1EB
BALL_COLOR  EQU		0xDB88
SCOREBACKGROUND	EQU 0x00C7	

;Coordinates
Box1X       EQU     0x0000 	; Box1 (0 , 0)
Box1Y       EQU     0x0000	; 
Box2X       EQU     0x0069	; Box2 (105 , 0)
Box2Y       EQU     0x0000	; 
Box3X       EQU     0x00D2	; Box3 (210 , 0)
Box3Y       EQU     0x0000	; 
Box4X       EQU     0x0000	; Box4 (0 , 125)
Box4Y       EQU     0x007D	; 
Box5X       EQU     0x0069	; Box5 (105 , 125)
Box5Y       EQU     0x007D	;
Box6X       EQU     0x00D2	; Box6 (210 , 125)
Box6Y       EQU     0x007D	; 
Box7X       EQU     0x0000	; Box7 (0 , 250)
Box7Y       EQU     0x00FA	;
Box8X       EQU     0x0069  ; Box8 (105 , 250)
Box8Y       EQU     0x00FA	;
Box9X       EQU     0x00D2	; Box9 (210 , 250)
Box9Y       EQU     0x00FA	;

; Define register base addresses
RCC_BASE        EQU     0x40023800
GPIOA_BASE      EQU     0x40020000
GPIOB_BASE      EQU     0x40020400

; Define register offsets
RCC_AHB1ENR     EQU     0x30
GPIO_MODER      EQU     0x00
GPIO_OTYPER     EQU     0x04
GPIO_OSPEEDR    EQU     0x08
GPIO_PUPDR      EQU     0x0C
GPIO_IDR        EQU     0x10
GPIO_ODR        EQU     0x14

; Control Pins on Port A (TFT)
TFT_RST         EQU     (1 << 8)
TFT_RD          EQU     (1 << 10)
TFT_WR          EQU     (1 << 11)
TFT_DC          EQU     (1 << 12)
TFT_CS          EQU     (1 << 15)

DELAY_INTERVAL  EQU     0x18604  
DELAY_INTERVAL2  EQU    0x186004  ;1 sec

__main FUNCTION

    BL STM_Configure_Ports
	
	MOV R1,#0
	MOV R2,#320
	MOV R3,#0
	MOV	R4,#480
	LDR R5,=BLACK
	BL TFT_DrawRect
	
		B SKIPpool9
	LTORG
SKIPpool9
	
	B MAIN_MENU
loop
    B loop
    ENDFUNC

; ************************************************************* ;
; 						STM CONFIGURATION 					    ;
; ************************************************************* ;
STM_Configure_Ports
    PUSH{LR}

    ; Enable clocks for GPIOA & GPIOB
    LDR R0, =RCC_BASE + RCC_AHB1ENR
    LDR R1, [R0]
    ORR R1, R1, #0x3 
    STR R1, [R0]

    ; Configure GPIOA as General Purpose Output Mode
    LDR R0, =GPIOA_BASE + GPIO_MODER
    LDR R1, =0x55555555  
    STR R1, [R0]

    ; Configure output speed for GPIOA (High Speed)
    LDR R0, =GPIOA_BASE + GPIO_OSPEEDR
    LDR R1, =0xFFFFFFFF  
    STR R1, [R0]

    ; Configure GPIOB as General Purpose Input Mode
    LDR R0, =GPIOB_BASE + GPIO_MODER
    LDR R1, =0x00000000  
    STR R1, [R0]

    ; Configure input speed for GPIOB (High Speed)
    LDR R0, =GPIOB_BASE + GPIO_OSPEEDR
    LDR R1, =0x55555555  
    STR R1, [R0]

    ; Configure PUPDR for GPIOB
    LDR R0, = GPIOB_BASE + GPIO_PUPDR
    LDR R1,=0xAAAAAAAA
    STR R1, [R0]

    ; Initialize TFT
    BL TFT_Init

    POP{LR}
    BX LR
; ************************************************************* ;
; 						MAIN LOOPS					           	;
; *************************************************************	;
MAIN_MENU

	MOV R1,#0
	MOV R2,#320
	MOV R3,#0
	MOV	R4,#480
	LDR R5,=BLACK
	BL TFT_DrawRect

	MOV R1,#30
	MOV R2,#190
	LDR R3,=XO_ICON
	BL TFT_DrawImage
	
	MOV R1,#190
	MOV R2,#190
	LDR R3,=PONG_ICON
	BL TFT_DrawImage

	MOV R12,#0
	BL DRAW_MENU_POINTER

MAIN_MENU_LOOP
	BL MENU_INPUT
	BL DRAW_MENU_POINTER

	B SKIPpool_MAIN_MENU
	LTORG
SKIPpool_MAIN_MENU

	TST R12,#0x0010
	BNE CHOOSE_GAME
	B MAIN_MENU_LOOP

CHOOSE_GAME
	TST R12,#1
	BEQ XO_MENU
	B PONG_MAIN

XO_MENU

	MOV R1,#0
	MOV R2,#320
	MOV R3,#0
	MOV	R4,#480
	LDR R5,=BLACK
	BL TFT_DrawRect

	MOV R1,#30
	MOV R2,#190
	LDR R3,=TwoPlayers
	BL TFT_DrawImage
	
	MOV R1,#190
	MOV R2,#190
	LDR R3,=VSAI
	BL TFT_DrawImage

	MOV R12,#0
	BL DRAW_MENU_POINTER

XO_MENU_LOOP
	BL MENU_INPUT
	BL DRAW_MENU_POINTER

	B SKIPpool_XO_MENU
	LTORG
SKIPpool_XO_MENU

	TST R12,#0x0020
	BNE MAIN_MENU
	TST R12,#0x0010
	BNE CHOOSE_MODE
	B XO_MENU_LOOP

CHOOSE_MODE
	TST R12,#1
	BEQ XO_Main1V1
	B XO_MainAI

XO_Main1V1
	MOV R1,#0
	MOV R2,#320
	MOV R3,#0
	MOV	R4,#480
	LDR R5,=BLACK
	BL TFT_DrawRect

	MOV R9, #0x0000
	MOV R10, #0
	MOV R11, #0
	MOV R12, #0x0010

	LDR R0, =Current_Pointer
	STR R12, [R0]
	LDR R0, =XO_Grid
	STR R9, [R0]
	LDR R0, =XO_Player1
	STR R10, [R0]
	LDR R0, =XO_Player2
	STR R11, [R0]

	B SKIPpool_XO_Main1V1
	LTORG
SKIPpool_XO_Main1V1

    BL XO_ResetScreen
XO_MainLoop
	BL XO_INPUT
    BL XO_DrawPointer
    BL XO_GameLogic
    B XO_MainLoop

XO_MainAI
	MOV R1,#0
	MOV R2,#320
	MOV R3,#0
	MOV	R4,#480
	LDR R5,=BLACK
	BL TFT_DrawRect

	MOV R9, #0x0000
	MOV R10, #0
	MOV R11, #0
	MOV R12, #0x0010

	LDR R0, =Current_Pointer
	STR R12, [R0]
	LDR R0, =XO_Grid
	STR R9, [R0]
	LDR R0, =XO_Player1
	STR R10, [R0]
	LDR R0, =XO_Player2
	STR R11, [R0]

	B SKIPpool_XO_MainAI
	LTORG
SKIPpool_XO_MainAI

    BL XO_ResetScreen
XO_AIMainLoop
	BL XO_INPUT
    BL XO_DrawPointer
    BL vsComputer
    B XO_AIMainLoop
	
PONG_MAIN

	MOV R1,#0
	MOV R2,#320
	MOV R3,#0
	MOV	R4,#480
	LDR R5,=BLACK
	BL TFT_DrawRect

	MOV R8,#0X00000178
	MOV R7,#0X00000078
	MOV R9,#3
	MOV R11,#160
	MOV R10,#200
	MOV R12,#0 
	
	LDR R0,=PONG_P1
	STR R8,[R0]
	LDR R0,=PONG_P2
	STR R7,[R0]
	LDR R0,=PONG_BALLDIR
	STR R9,[R0]
	LDR R0,=PONG_BALLX
	STR R11,[R0]
	LDR R0,=PONG_BALLY
	STR R10,[R0]

	B SKIPpool_PONG_MAIN
	LTORG
SKIPpool_PONG_MAIN

	MOV R1 , #100
	MOV R2 , #165
	LDR R3 , =PongStart
	BL TFT_DrawImage
	
PONG_MainLoop  
    BL PONG_INPUT
	BL delay
    BL PONG_LOGIC
    B PONG_MainLoop

; ************************************************************* ;
; 						    MENU					           	;
; *************************************************************	;
MENU_INPUT
	PUSH{LR}
	LDR R0,=GPIOB_BASE + GPIO_IDR
	LDR R1,[R0]       
	
 ; Add hardware debouncing by checking multiple times
    PUSH {R2}
    MOV R2, #0            ; Button state confirmation counter
    
CONFIRM_INPUT_MENU
    LDR R0,=GPIOB_BASE + GPIO_IDR
    LDR R6,[R0]           ; Read input again
    CMP R1, R6            ; Compare with previous reading
    BNE RESET_INPUT_MENU       ; If not the same, reset counter
    ADD R2, R2, #1        ; Increment confirmation counter
    CMP R2, #3            ; Need 3 consistent readings
    BLT CONFIRM_INPUT_MENU
	POP{R2}
	B INPUT_FINISH_MENU

RESET_INPUT_MENU
    MOV R1, R6            ; Update our reading
    MOV R2, #0            ; Reset counter
    B CONFIRM_INPUT_MENU

INPUT_FINISH_MENU
    ; Now proceed with normal logic
	AND R3,R1,#0xC          ; GET BITS 1 ,0 
	
	CMP R3,#0x8            ; IF BIT 0 CHOOSEN GAME XO 
	BNE CHECK_OTHER_GAME
	BIC R12,R12,#0x1
	B CHECK_PLAY_BACK
	
CHECK_OTHER_GAME	
	CMP R3,#0x4	 	        ;IF BIT 1 CHOOSEN GAME PONG
	BNE CHECK_PLAY_BACK
	ORR R12,R12,#0x1
	
	
CHECK_PLAY_BACK
	AND R3,R1,#0x10			;SET PLAY BIT
	ORR R12,R12,R3
	
	MOV  R3, R1, LSR #5  
	AND R3,R3,#0x1
	CMP R3,#0x1
	BNE NOTBACKMENU
	BL Wait_Input_Finish_MENU
    POP{LR}
    B MAIN_MENU
NOTBACKMENU	
	BL Wait_Input_Finish_MENU
	POP{LR}
	BX LR 

Wait_Input_Finish_MENU
    PUSH {R0-R3,LR}
    
    ; First wait for button release
    MOV R3, #0            ; Counter for stable readings
WAIT_RELEASE_MENU
    LDR R0,=GPIOB_BASE + GPIO_IDR
    LDR R1,[R0]
    CMP R1, #0
    BNE RESET_COUNTER_MENU     ; Button still pressed
    
    ADD R3, R3, #1        ; Increment stability counter
    CMP R3, #200          ; Need many stable readings
    BLT.W WAIT_RELEASE
    B WAIT_DONE_MENU
    
RESET_COUNTER_MENU
    MOV R3, #0            ; Reset counter
    B WAIT_RELEASE_MENU
    
WAIT_DONE_MENU
    ; Add a fixed delay for debouncing
    LDR R2,=0x30000
DEBOUNCE_DELAY_MENU
    SUBS R2,R2,#1
    BNE DEBOUNCE_DELAY_MENU
    
    POP {R0-R3,LR}
    BX LR


DRAW_MENU_POINTER
	PUSH{R1-R7,R12,LR}
	TST R12,#1
	BEQ DRAW_LEFT

	MOV R1,#25
	MOV R3,#185
	LDR R5,=BLACK
	; Draw top horizontal line
	ADD R2, R1, #110	; X2 = X1 + 2*Thickness(5) + Width(100)
	ADD R4, R3, #5		; Y2 = Y1 + Thickness(5)
	BL TFT_DrawRect
	
	; Draw left vertical line (R1 & R3 Unchanged)
	ADD R2, R1, #5		; X2 = X1 + Thickness(5)
	ADD R4, R3, #110	; Y2 = Y1 + 2*Thicnkess(5) + Height(100)
	BL TFT_DrawRect
	
	; Draw bottom horizontal line (R1 & R3 Unchanged)
	MOV R6, R1			; Save Pointer X (Could Neglect This Line)
	MOV R7, R3			; Save Pointer Y
	ADD R2, R1, #110	; X2 = X1 + 2*Thickness(5) + Width(100)
	ADD R3, R7, #105	; Y1 = Y1(Old) + Thickness(5) + Height(100)
	ADD R4, R3, #5		; Y2 = Y1 + Thickness(5)
	BL TFT_DrawRect
	
	; Draw right vertical line
	ADD R1, R6, #105	; X1 = Pointer X + Thickness(5) + Width(100)
	ADD R2, R1, #5		; X2 = X1 + Thickness(5)
	MOV R3, R7			; Y1 = Pointer Y
	ADD R4, R3, #110	; Y2 = Y1 + 2*Thickness(5) + Height(100)
	BL TFT_DrawRect

	MOV R1,#185
	MOV R3,#185
	LDR R5,=RED
	; Draw top horizontal line
	ADD R2, R1, #110	; X2 = X1 + 2*Thickness(5) + Width(100)
	ADD R4, R3, #5		; Y2 = Y1 + Thickness(5)
	BL TFT_DrawRect
	
	; Draw left vertical line (R1 & R3 Unchanged)
	ADD R2, R1, #5		; X2 = X1 + Thickness(5)
	ADD R4, R3, #110	; Y2 = Y1 + 2*Thicnkess(5) + Height(100)
	BL TFT_DrawRect
	
	; Draw bottom horizontal line (R1 & R3 Unchanged)
	MOV R6, R1			; Save Pointer X (Could Neglect This Line)
	MOV R7, R3			; Save Pointer Y
	ADD R2, R1, #110	; X2 = X1 + 2*Thickness(5) + Width(100)
	ADD R3, R7, #105	; Y1 = Y1(Old) + Thickness(5) + Height(100)
	ADD R4, R3, #5		; Y2 = Y1 + Thickness(5)
	BL TFT_DrawRect
	
	; Draw right vertical line
	ADD R1, R6, #105	; X1 = Pointer X + Thickness(5) + Width(100)
	ADD R2, R1, #5		; X2 = X1 + Thickness(5)
	MOV R3, R7			; Y1 = Pointer Y
	ADD R4, R3, #110	; Y2 = Y1 + 2*Thickness(5) + Height(100)
	BL TFT_DrawRect
	
	B EXIT_MENU_POINTER

DRAW_LEFT

	MOV R1,#185
	MOV R3,#185
	LDR R5,=BLACK
	; Draw top horizontal line
	ADD R2, R1, #110	; X2 = X1 + 2*Thickness(5) + Width(100)
	ADD R4, R3, #5		; Y2 = Y1 + Thickness(5)
	BL TFT_DrawRect
	
	; Draw left vertical line (R1 & R3 Unchanged)
	ADD R2, R1, #5		; X2 = X1 + Thickness(5)
	ADD R4, R3, #110	; Y2 = Y1 + 2*Thicnkess(5) + Height(100)
	BL TFT_DrawRect
	
	; Draw bottom horizontal line (R1 & R3 Unchanged)
	MOV R6, R1			; Save Pointer X (Could Neglect This Line)
	MOV R7, R3			; Save Pointer Y
	ADD R2, R1, #110	; X2 = X1 + 2*Thickness(5) + Width(100)
	ADD R3, R7, #105	; Y1 = Y1(Old) + Thickness(5) + Height(100)
	ADD R4, R3, #5		; Y2 = Y1 + Thickness(5)
	BL TFT_DrawRect
	
	; Draw right vertical line
	ADD R1, R6, #105	; X1 = Pointer X + Thickness(5) + Width(100)
	ADD R2, R1, #5		; X2 = X1 + Thickness(5)
	MOV R3, R7			; Y1 = Pointer Y
	ADD R4, R3, #110	; Y2 = Y1 + 2*Thickness(5) + Height(100)
	BL TFT_DrawRect

	MOV R1,#25
	MOV R3,#185
	LDR R5,=RED
	; Draw top horizontal line
	ADD R2, R1, #110	; X2 = X1 + 2*Thickness(5) + Width(100)
	ADD R4, R3, #5		; Y2 = Y1 + Thickness(5)
	BL TFT_DrawRect
	
	; Draw left vertical line (R1 & R3 Unchanged)
	ADD R2, R1, #5		; X2 = X1 + Thickness(5)
	ADD R4, R3, #110	; Y2 = Y1 + 2*Thicnkess(5) + Height(100)
	BL TFT_DrawRect
	
	; Draw bottom horizontal line (R1 & R3 Unchanged)
	MOV R6, R1			; Save Pointer X (Could Neglect This Line)
	MOV R7, R3			; Save Pointer Y
	ADD R2, R1, #110	; X2 = X1 + 2*Thickness(5) + Width(100)
	ADD R3, R7, #105	; Y1 = Y1(Old) + Thickness(5) + Height(100)
	ADD R4, R3, #5		; Y2 = Y1 + Thickness(5)
	BL TFT_DrawRect
	
	; Draw right vertical line
	ADD R1, R6, #105	; X1 = Pointer X + Thickness(5) + Width(100)
	ADD R2, R1, #5		; X2 = X1 + Thickness(5)
	MOV R3, R7			; Y1 = Pointer Y
	ADD R4, R3, #110	; Y2 = Y1 + 2*Thickness(5) + Height(100)
	BL TFT_DrawRect

EXIT_MENU_POINTER
	POP{R1-R7,R12,LR}
	BX LR
; ************************************************************* ;
; 						PONG_INPUT					           	;
; *************************************************************	;
 
PONG_INPUT
	PUSH {R0,R1,R2,R3,LR}
	LDR R0,=PONG_P1
	LDR R8,[R0]
	LDR R0,=PONG_P2
	LDR R7,[R0]

	LDR R0,=GPIOB_BASE + GPIO_IDR
	LDR R1,[R0]       
	
 ; Add hardware debouncing by checking multiple times
    PUSH {R2}
    MOV R2, #0            ; Button state confirmation counter
    
CONFIRM_INPUT_PONG
    LDR R0,=GPIOB_BASE + GPIO_IDR
    LDR R6,[R0]           ; Read input again
    CMP R1, R6            ; Compare with previous reading
    BNE RESET_INPUT_PONG       ; If not the same, reset counter
    ADD R2, R2, #1        ; Increment confirmation counter
    CMP R2, #3            ; Need 3 consistent readings
    BLT CONFIRM_INPUT_PONG
    B Continue_Input


RESET_INPUT_PONG
    MOV R1, R6            ; Update our reading
    MOV R2, #0            ; Reset counter
    B CONFIRM_INPUT_PONG

Continue_Input   
	POP{R2}
	;CHECK IF THE USER WANT TO RETURN BACK TO THE MAIN MENU
	MOV  R3, R1, LSR #5  
	AND R3,R3,#0x1
	CMP R3,#0x1
	BNE NOTBACK
    POP{R0,R1,R2,R3,LR}
    B MAIN_MENU
NOTBACK 


;CHECK IF THE USER WANTS TO RESET THE GAME 
	MOV  R3, R1, LSR #4  
	AND R3,R3,#0x1
	CMP R3,#0x1
	BNE SKIP_RESET
	MOV R12,#0x1
    B PONG_INPUT_FINISH

SKIP_RESET 

	AND R4, R8, #0X00000100
	CMP R4,#0X00000100
	BEQ PONG_INPUT_FINISH
	AND R4, R7,#0X00000100
	CMP R4,#0X00000100
	BEQ PONG_INPUT_FINISH
	
SET_PLAYER1_X
	MOV R3,R1,LSR #2
	AND R3,R3,#0x3          ; GET BITS 1 ,0 
	CMP R3,#0x1             ; IF BIT 0 ,MOVE UP
	BEQ MOVE_UP_P1
	CMP R3,#0x2	 	        ;IF BIT 1 ,MOVE DOWN
	BEQ MOVE_DOWN_P1
	B SET_PLAYER2_X 		;ELSE GO CHECK THE OTHER PLAYER
	
MOVE_UP_P1
	MOV R2,R8
	AND R2,R2,#0xFF
	ADD R2,#0x14 	 ;ADD 20 PIXELS EACH TIME
	CMP R2,#0xEB     ;TEST THATS THE END OF THE GRID (315 SO THE X WILL BE IN 235=EB IN HEXA)
	BGT UPBoundry
	ADD R8,R8,#0x14
    BL PONG_DrawPaddle1
	B   SET_PLAYER2_X
UPBoundry
    BIC R8,#0x00FF
    ADD R8,R8,#235
    BL PONG_DrawPaddle1
    B SET_PLAYER2_X

MOVE_DOWN_P1
	MOV R2,R8
	AND R2,R2,#0xFF
	SUB R2,#0x14 	 ;SUB 20 PIXELS EACH TIME
	CMP R2,#0x5      ;TEST THATS THE END OF THE GRID (5 SO THE X WILL BE IN 5 THIS TIME)
	BLT DOWNBoundry
	SUB R8,R8,#0x14
    BL PONG_DrawPaddle1
	B   SET_PLAYER2_X
DOWNBoundry
    BIC R8,#0x00FF
    ADD R8,R8,#5
    BL PONG_DrawPaddle1
    B SET_PLAYER2_X

SET_PLAYER2_X
	MOV  R3, R1, LSR #6  ; GET BITS 6,7
    AND  R3, R3, #0x3    ;MASK THEM TO MAKE SURE
	CMP R3,#0x2          ; IF BIT 0(6) ,MOVE UP
	BEQ MOVE_UP_P2
	CMP R3,#0x1	 	     ;IF BIT 1(7),MOVE DOWN
	BEQ MOVE_DOWN_P2
	B PONG_INPUT_FINISH 		     ;ELSE DO NOTHING AND RETURN 
	
MOVE_UP_P2
	MOV R2,R7
	AND R2,R2,#0xFF
	ADD R2,#0x14 	;ADD 20 PIXELS EACH TIME
	CMP R2,#0xEB     ;TEST THATS THE END OF THE GRID (315 SO THE X WILL BE IN 235=EB IN HEXA)
	BGT UPBoundry2
	ADD R7,R7,#0x14
    BL PONG_DrawPaddle2
	B PONG_INPUT_FINISH
UPBoundry2
    BIC R7,#0x00FF
    ADD R7,R7,#235
    BL PONG_DrawPaddle2
    B PONG_INPUT_FINISH

MOVE_DOWN_P2
	MOV R2,R7
	AND R2,R2,#0xFF
	SUB R2,#0x14 	;SUB 20 PIXELS EACH TIME
	CMP R2,#0x5      ;TEST THATS THE END OF THE GRID (5 SO THE X WILL BE IN 5 THIS TIME)
	BLT DOWNBoundry2
	SUB R7,R7,#0x14
    BL PONG_DrawPaddle2
	B PONG_INPUT_FINISH
DOWNBoundry2
    BIC R7,#0x00FF
    ADD R7,R7,#5
    BL PONG_DrawPaddle2
PONG_INPUT_FINISH	
	B SKIPpool12
	LTORG
SKIPpool12
	BL delay
	LDR R0,=PONG_P1
	STR R8,[R0]
	LDR R0,=PONG_P2
	STR R7,[R0]
	POP {R0,R1,R2,R3,LR}
    BX LR


; =============================================================	;
; 						PONG LOGIC FUNCTION                     ;
; =============================================================	;
PONG_LOGIC
	push{R0-R6,LR}
	;;;;;;;;;;;;;; CHECK WINNING "RESET" ;;;;;;;;;;;;;;;;;;;;;
	LDR R0,=PONG_P1
	LDR R8,[R0]
	LDR R0,=PONG_P2
	LDR R7,[R0]
	LDR R0,=PONG_BALLDIR
	LDR R9,[R0]
	LDR R0,=PONG_BALLX
	LDR R11,[R0]
	LDR R0,=PONG_BALLY
	LDR R10,[R0]

PONG_CHECK_WINNING
	AND R4, R8, #0X00000100
	CMP R4,#0X00000100
	BEQ.W CHECK_R12
	AND R4, R7,#0X00000100
	CMP R4,#0X00000100
	BEQ.W CHECK_R12

	;;;; CHECK THE BALL DIRECTION 
CHECK_UP_RIGHT   ;;; FOR P2(PLAYER ON THE LEFT)
	MOV R5,#0X000000FF
	CMP R9,#0    ;;; UP RIGHT 
	BNE CHECK_UP_LEFT
	MOV R0,#0X000001FF
	AND R1,R11,R0    ;;; R1 HAS LAST X POS
	LSL R11,#9
	AND R2,R10,R0    ;;; R2 HAS LAST Y POS
	LSL R10,#9
	ADD R1,R1,#10
	ADD R2,R2,#10
	CMP R1,#308
	BLGE UPPER_BORDER
	CMP R2,#376      ;;; CHECK THAT Y IS IN THE RANGE OF MOTION OF PADDLE(395-7-12=376)
	BLT.W SKIP_lOGIC 
	AND R6,R5,R8
    SUB R6,R6,#2    
	CMP R1,R6       ;;; CHECKS THE X OF THE PADDLE WITH THE POS OF THE BALL
	BLT.W P2_WIN    ;;; WILL BE CHANGED;;;;;;;;;;;;;;;;;;;;
	ADD R3,R6,#84  ;;; R3 HAS UPPER X OF THE PADDLE
	CMP R1,R3
	BGT.W P2_WIN    ;;; WILL BE CHANGED;;;;;;;;;;;;;;;;;;;;
	MOV R2,#375
	ORR R10,R10,R2
	ORR R11,R11,R1
	BL PONG_DrawBall       ;;; WILL BE CHANGED;;;;;;;;;;;;;;;;;;;;
	EOR R9,#0X00000001   ;;; CHANGE DIR TO UP LEFT
	AND R1,R11,R0    ;;; R1 HAS LAST X POS
	LSL R11,#9
	AND R2,R10,R0    ;;; R2 HAS LAST Y POS
	LSL R10,#9
	ADD R1,R1,#10
	SUB R2,R2,#15
	
	B SKIP_lOGIC
	
CHECK_UP_LEFT	;;; FOR P1(PLAYER ON THE RIGHT)
	MOV R5,#0X000000FF
	CMP R9,#1    ;;;UP LEFT 
	BNE CHECK_DOWN_RIGHT
	MOV R0,#0X000001FF
	AND R1,R11,R0    ;;; R1 HAS LAST X POS
	LSL R11,#9
	AND R2,R10,R0    ;;; R2 HAS LAST Y POS
	LSL R10,#9
	ADD R1,R1,#10
	SUB R2,R2,#10
	CMP R1,#308
	BLGE UPPER_BORDER
	CMP R2,#24 ;;; CHECK THAT Y IS IN THE RANGE OF MOTION OF PADDLE(12+5+7=24)
	BGT.W SKIP_lOGIC
	AND R6,R5,R7
	SUB R6,R6,#2
	CMP R1,R6    
	BLT.W P1_WIN    ;;; WILL BE CHANGED;;;;;;;;;;;;;;;;;;;;
	ADD R3,R6,#84  ;;; R3 HAS UPPER X OF THE PADDLE
	CMP R1,R3
	BGT.W P1_WIN    ;;; WILL BE CHANGED;;;;;;;;;;;;;;;;;;;;
	MOV R2,#25
	ORR R10,R10,R2
	ORR R11,R11,R1
	BL PONG_DrawBall       ;;; WILL BE CHANGED;;;;;;;;;;;;;;;;;;;;
	EOR R9,#0X00000001   ;;; CHANGE DIR TO UP RIGHT 
	AND R1,R11,R0    ;;; R1 HAS LAST X POS
	LSL R11,#9
	AND R2,R10,R0    ;;; R2 HAS LAST Y POS
	LSL R10,#9
	ADD R1,R1,#10
	ADD R2,R2,#15
	
	B SKIP_lOGIC
	
	
UPPER_BORDER	   ;;; BALL HAS REACHED THE X=308 
    push {R0, R2-R8, R10-R12, LR}
	MOV R1,#307
	EOR R9,R9,#0X00000002     ;; DIR IS CHANGED TO DOWN (RIGHT OR LEFT)   
	pop {R0, R2-R8, R10-R12, LR}
	BX LR
	
CHECK_DOWN_RIGHT  ;;; FOR P2(PLAYER ON THE LEFT)
	CMP R9,#2    ;;;UP LEFT 
	BNE CHECK_DOWN_LEFT
	MOV R0,#0X000001FF
	AND R1,R11,R0    ;;; R1 HAS LAST X POS
	LSL R11,#9
	AND R2,R10,R0    ;;; R2 HAS LAST Y POS
	LSL R10,#9
	SUB R1,R1,#10
	ADD R2,R2,#10
	CMP R1, #12
	BLLE LOWER_BORDER
	CMP R2,#376  ;;; CHECK THAT Y IS IN THE RANGE OF MOTION OF PADDLE(395-7-12=376)
	BLT SKIP_lOGIC 
	AND R6,R5,R8
	SUB R6,R6,#2
	CMP R1,R6    
	BLT.W P2_WIN    ;;; WILL BE CHANGED;;;;;;;;;;;;;;;;;;;;
	ADD R3,R6,#84  ;;; R3 HAS UPPER X OF THE PADDLE
	CMP R1,R3
	BGT.W P2_WIN    ;;; WILL BE CHANGED;;;;;;;;;;;;;;;;;;;;
	MOV R2,#375
	ORR R10,R10,R2
	ORR R11,R11,R1
	BL PONG_DrawBall     ;;; WILL BE CHANGED;;;;;;;;;;;;;;;;;;;;
	EOR R9,#0X00000001  ;;; CHANGE DIR TO DOWN LEFT 
	AND R1,R11,R0       ;;; R1 HAS LAST X POS
	LSL R11,#9
	AND R2,R10,R0       ;;; R2 HAS LAST Y POS
	LSL R10,#9
	SUB R1,R1,#10
	SUB R2,R2,#15
	
	B SKIP_lOGIC
	
	
CHECK_DOWN_LEFT  ;;; FOR P1(PLAYER ON THE RIGHT)
	MOV R0,#0X000001FF
	AND R1,R11,R0    ;;; R1 HAS LAST X POS
	LSL R11,#9
	AND R2,R10,R0    ;;; R2 HAS LAST Y POS
	LSL R10,#9
	SUB R1,R1,#10
	SUB R2,R2,#10
	;CMP R1, #14
	CMP R1,#12
	BLLE LOWER_BORDER
	CMP R2,#24   ;;; CHECK THAT Y IS IN THE RANGE OF MOTION OF PADDLE(5+7+12=24)
	BGT SKIP_lOGIC  
	AND R6,R5,R7
	SUB R6,R6,#2
	CMP R1,R6    
	BLT P1_WIN    ;;; WILL BE CHANGED;;;;;;;;;;;;;;;;;;;;
	ADD R3,R6,#84  ;;; R3 HAS UPPER X OF THE PADDLE
	CMP R1,R3
	BGT P1_WIN    ;;; WILL BE CHANGED;;;;;;;;;;;;;;;;;;;;
	MOV R2,#25
	ORR R10,R10,R2
	ORR R11,R11,R1
	BL PONG_DrawBall       ;;; WILL BE CHANGED;;;;;;;;;;;;;;;;;;;;
	EOR R9,#0X00000001  ;;; CHANGE DIR TO DOWN RIGHT 
	AND R1,R11,R0       ;;; R1 HAS LAST X POS
	LSL R11,#9
	AND R2,R10,R0       ;;; R2 HAS LAST Y POS
	LSL R10,#9
	SUB R1,R1,#10
	ADD R2,R2,#15
	B SKIP_lOGIC
	
LOWER_BORDER	   ;;; BALL HAS REACHED THE X=308
    push {R0, R2-R8, R10-R12, LR}
	MOV R1,#13
	EOR R9,R9,#0X00000002     ;; DIR IS CHANGED TO DOWN (RIGHT OR LEFT)
	pop {R0, R2-R8, R10-R12, LR}
	BX LR
	
SKIP_lOGIC
	ORR R10,R10,R2
	ORR R11,R11,R1
	BL PONG_DrawBall 	;;; call The drawing func here;;;;;;;;;;;;;;;;;;;;;;
PONG_EXIT
	B SKIPpool11
	LTORG
SKIPpool11
	LDR R0,=PONG_P1
	STR R8,[R0]
	LDR R0,=PONG_P2
	STR R7,[R0]
	LDR R0,=PONG_BALLDIR
	STR R9,[R0]
	LDR R0,=PONG_BALLX
	STR R11,[R0]
	LDR R0,=PONG_BALLY
	STR R10,[R0]

	POP{R0-R6,PC}
	
	
P1_WIN     ;;; WILL BE CHANGED;;;;;;;;;;;;;;;;;;;;
    ORR R10,R10,R2
	ORR R11,R11,R1
    BL PONG_DrawBall
	ADD R8,#0X00000200
	AND R5,R8,#0X00000E00
    BL PONG_P1DrawScore
	MOV R3, #0
	CMP R5,#0X00000A00
	BNE PONG_Reset
	ORR R8,#0X00000100
	BL PONG_OneWins
	B SKIP_lOGIC
P2_WIN     ;;; WILL BE CHANGED;;;;;;;;;;;;;;;;;;;;
    ORR R10,R10,R2
	ORR R11,R11,R1
    BL PONG_DrawBall
	ADD R7,#0X00000200
	AND R6,R7,#0X00000E00
    BL PONG_P2DrawScore
	MOV R3, #1
	CMP R6,#0X00000A00
	BNE PONG_Reset
	ORR R7,#0X00000100
	BL PONG_TwoWins
	B SKIP_lOGIC

	
RESET_FINAL	   
	MOV R8,#0X00000078
	MOV R7,#0X00000078
	MOV R11,#160
	MOV R10,#200
	MOV R12,#0
	BL PONG_NewGame
	B PONG_EXIT

PONG_Reset
	AND R8,#0X00000F00
	ORR R8,#0X00000078
	AND R7,#0X00000F00
	ORR R7,#0X00000078
	MOV R11,#160
	MOV R10,#26
	EOR R9,#0X00000001
	CMP R3,#1
	BNE P2_RESET
	MOV R10,#374
	BL PONG_NewRound
	B PONG_EXIT

P2_RESET
	BL PONG_NewRound
	B PONG_EXIT

CHECK_R12
	CMP R12,#0X00000001
	BEQ RESET_FINAL
	B PONG_EXIT
	
; =============================================================	;
; 						PONG DRAWING FUNCTIONS                  ;
; =============================================================	;
; ******************************************* ;
; 				 Draw Paddle1 	              ;
; ******************************************* ;
PONG_DrawPaddle1
	; Get current position from R8
    PUSH{R1-R6,R8, LR}
    
    MOV R1,#5
    MOV R2,#315
    ; Draw black rectangle to erase previous position
    MOV R3, #383          ; y1 = 5 (top of screen)
    MOV R4, #394          ; y2 = 25 (height of paddle)
    LDR R5, =BACKGROUND   ; Color = BLACK (for erasing)
    BL TFT_DrawRect       ; Erase with black rectangle
    
    ; Draw the paddle in white
    MOV R1, R8            ; x1 = paddle position
    ADD R2, R1, #80       ; x2 = x1 + 80 (width of paddle)
    MOV R3, #383          ; y1 = 5 (top of screen)
    MOV R4, #394          ; y2 = 25 (height of paddle)
    LDR R5, =PAD1_COLOR   ; Color = WHITE (for paddle)
    BL TFT_DrawRect       ; Draw white rectangle (paddle)
    
    POP{R1-R6,R8, PC}


; ******************************************* ;
; 				 Draw Paddle2 	              ;
; ******************************************* ;
PONG_DrawPaddle2
	; Get current position from R7
    PUSH{R1-R7, LR}

    ; Calculate boundaries for erasing
    MOV R1,#5
    MOV R2,#315
    ; Draw black rectangle to erase previous position
    MOV R3, #6            ; y1 = 5 (top of screen)
    MOV R4, #17           ; y2 = 25 (height of paddle)
	LDR R5, =BACKGROUND   ; Color = BACKGROUND (for erasing)
    BL TFT_DrawRect       ; Erase with black rectangle
    
    ; Draw the paddle in white
    MOV R1, R7            ; x1 = paddle position
    ADD R2, R1, #80       ; x2 = x1 + 80 (width of paddle)
    MOV R3, #6            ; y1 = 5 (top of screen)
    MOV R4, #17           ; y2 = 25 (height of paddle)
    LDR R5, =PAD2_COLOR   ; Color = YELLOW (for paddle)
    BL TFT_DrawRect       ; Draw white rectangle (paddle)
    
    POP{R1-R7, PC}

; === Solves Error Literal Pool === ;
	B SKIPpool4
	LTORG
SKIPpool4

; ******************************************* ;
; 				 	Draw Ball 	              ;
; ******************************************* ;
PONG_DrawBall
	;R11 = X Center (0b0000....0 | 000000000 | 000000000) (14 Unused Bits , 9 Old X , 9 New X)
	;R10 = Y Center (0b0000....0 | 000000000 | 000000000) (14 Unused Bits , 9 Old Y , 9 New Y)
	PUSH{LR}
	
	BL ClearOldBall
	BL DrawNewBall
	
	POP{LR}
	BX LR
 
	
ClearOldBall
	PUSH {R1-R7, R12, LR}
    
    ; Extract Old X from R11 (higher 9 bits)
    LSR R6, R11, #9
	MOV R12, #0x1FF
    AND R6, R6, R12      ; Mask to keep only lower 9 bits (New X)
    
    ; Extract Old Y from R10 (higher 9 bits)
    LSR R7, R10, #9
    AND R7, R7, R12      ; Mask to keep only lower 9 bits (New Y)
	
    ; Load Color
    LDR R5,	=BACKGROUND
	
	; Draw Vertically
	SUB R1, R6, #4
	ADD R2, R6, #4
	SUB R3, R7, #4
	ADD R4, R7, #4
	BL TFT_DrawRect
	
	ADD R1, R1, #1
	SUB R2, R2, #1
	SUB R3, R3, #1
	ADD R4, R4, #1
	BL TFT_DrawRect
	
	ADD R1, R1, #1
	SUB R2, R2, #1
	SUB R3, R3, #1
	ADD R4, R4, #1
	BL TFT_DrawRect
	
	ADD R1, R1, #1
	SUB R2, R2, #1
	SUB R3, R3, #1
	ADD R4, R4, #1
	BL TFT_DrawRect
	
	;Draw Horizontally
	SUB R1, R6, #5
	ADD R2, R6, #5
	SUB R3, R7, #3
	ADD R4, R7, #3
	BL TFT_DrawRect
	
	SUB R1, R1, #1
	ADD R2, R2, #1
	ADD R3, R3, #1
	SUB R4, R4, #1
	BL TFT_DrawRect
	
	SUB R1, R1, #1
	ADD R2, R2, #1
	ADD R3, R3, #1
	SUB R4, R4, #1
    BL TFT_DrawRect
    
	; Check if X <= 5 + 7 (DownBoundary) , Make X = 5 + 7
	CMP R6, #12
	BLT BranchDownBoundary
	; Check if X >= 315 - 7 (UpBoundary) , Make X = 315 - 7
	CMP R6, #308
	BGT BranchUpBoundary
	B SkipRedrawBoundary
	
BranchDownBoundary
	MOV R1, #0
	MOV R2, #4
	SUB R3, R7, #10
	ADD R4, R7, #10
	LDR R5, =WHITE
	BL TFT_DrawRect
	B SkipRedrawBoundary
BranchUpBoundary
	MOV R1, #315
	MOV R2, #319
	SUB R3, R7, #10
	ADD R4, R7, #10
	LDR R5, =WHITE
	BL TFT_DrawRect
	MOV R1,#314
	MOV R2,#315
	LDR R5, =BACKGROUND
	BL TFT_DrawRect

SkipRedrawBoundary
	
    POP {R1-R7, R12, LR}
    BX LR	
	
DrawNewBall
	PUSH {R1-R7, R12, LR}
    
    ; Extract New X from R11 (lower 9 bits)
    MOV R6, R11
	MOV R12, #0x1FF
    AND R6, R6, R12      ; Mask to keep only lower 9 bits (New X)
    
    ; Extract New Y from R10 (lower 9 bits)
    MOV R7, R10
    AND R7, R7, R12      ; Mask to keep only lower 9 bits (New Y)
    
    ; Load Color
    LDR R5,	=ORANGE
	
	; Draw Vertically
	SUB R1, R6, #4
	ADD R2, R6, #4
	SUB R3, R7, #4
	ADD R4, R7, #4
	BL TFT_DrawRect
	
	ADD R1, R1, #1
	SUB R2, R2, #1
	SUB R3, R3, #1
	ADD R4, R4, #1
	BL TFT_DrawRect
	
	ADD R1, R1, #1
	SUB R2, R2, #1
	SUB R3, R3, #1
	ADD R4, R4, #1
	BL TFT_DrawRect
	
	ADD R1, R1, #1
	SUB R2, R2, #1
	SUB R3, R3, #1
	ADD R4, R4, #1
	BL TFT_DrawRect
	
	;Draw Horizontally
	SUB R1, R6, #5
	ADD R2, R6, #5
	SUB R3, R7, #3
	ADD R4, R7, #3
	BL TFT_DrawRect
	
	SUB R1, R1, #1
	ADD R2, R2, #1
	ADD R3, R3, #1
	SUB R4, R4, #1
	BL TFT_DrawRect
	
	SUB R1, R1, #1
	ADD R2, R2, #1
	ADD R3, R3, #1
	SUB R4, R4, #1
    BL TFT_DrawRect
    
    POP {R1-R7, R12, LR}
    BX LR	

; ******************************************* ;
; 				 Draw P1 Wins 	              ;
; ******************************************* ;
PONG_OneWins
	PUSH{R1-R3, LR}
	
	MOV R1 , #0
	MOV R2 , #60
	MOV R3 , #400
	MOV R4 , #480
	LDR R5 , =SCOREBACKGROUND
	BL TFT_DrawRect

	MOV R1, #4
	MOV R2,	#408
	LDR R3, =Pong_P1Wins
	BL TFT_DrawImage

	POP{R1-R3, LR}
	BX LR
	
	
; ******************************************* ;
; 				 Draw P2 Wins 	              ;
; ******************************************* ;
PONG_TwoWins
	PUSH{R1-R3, LR}
	
	MOV R1 , #0
	MOV R2 , #60
	MOV R3 , #400
	MOV R4 , #480
	LDR R5 , =SCOREBACKGROUND
	BL TFT_DrawRect

	MOV R1, #4
	MOV R2,	#408
	LDR R3, =Pong_P2Wins
	BL TFT_DrawImage

	POP{R1-R3, LR}
	BX LR

; ******************************************* ;
; 				 Draw Boundaries 	      	  ;
; ******************************************* ;
;Take the color 
;TFT_DrawRect from 0 to 319 in X && from 0 to 4 at Y (left)
;TFT_DrawRect from 0 to 4 in X && from 0 to 399 at Y (bottom)
;TFT_DrawRect from 314 to 319 in X && from 0 to 399 at Y (top)
;TFT_DrawRect from 0 to 319 in X && from 394 to 399 at Y (right)

PONG_DrawBoundaries
    PUSH{R1-R5, LR}
    
    ; Draw top boundary
    MOV R1, #0            ; x1 = 0
    MOV R2, #319          ; x2 = 319
    MOV R3, #0            ; y1 = 0
    MOV R4, #4            ; y2 = 4
    LDR R5, =WHITE        ; Color = WHITE
    BL TFT_DrawRect
    
    ; Draw left boundary
    MOV R1, #0            ; x1 = 0
    MOV R2, #4            ; x2 = 4
    MOV R3, #0            ; y1 = 0
    MOV R4, #399         ; y2 = 399
    BL TFT_DrawRect
    
    ; Draw right boundary
    MOV R1, #315          ; x1 = 314
    MOV R2, #319          ; x2 = 319
    MOV R3, #0            ; y1 = 0
    MOV R4, #399          ; y2 = 399
    BL TFT_DrawRect
    
    ; Draw bottom boundary
    MOV R1, #0            ; x1 = 0
    MOV R2, #319          ; x2 = 319
    MOV R3, #394          ; y1 = 394
    MOV R4, #399          ; y2 = 399
    BL TFT_DrawRect
    
    POP{R1-R5,PC}


; ******************************************* ;
; 				 Draw P1 Score 	              ;
; ******************************************* ;
PONG_P1DrawScore
	PUSH{R1-R3, R8, LR}
	
    ; R8 = Player 1 ( Score Bits | 1 Check Bit | 8 Position Bits )
    LSR R8, #9
    SUB R8, R8, #1
	MOV R1, #25		; Distance between the start of two scores
    MUL R8, R8, R1	; Calculate the new position shift for the score
	MOV R1, #268	; Screen Width - "P1" Height = 273 - 15 pixel starting offset = 268
    SUB R1, R1, R8	; Add the offset to draw the score below "P1"
    MOV R2, #409	; Screen Height (400 + Offset 9)
    LDR R3, =Pong_Point
    BL TFT_DrawImage

	POP{R1-R3, R8, LR}
	BX LR
	
	
; ******************************************* ;
; 				 Draw P2 Score 	              ;
; ******************************************* ;
PONG_P2DrawScore
	PUSH{R1-R3, R7, LR}
	
    ; R7 = Player 2 ( Score Bits | 1 Check Bit | 8 Position Bits )
    LSR R7, #9
    SUB R7, R7, #1
	MOV R1, #25		; Distance between the start of two scores
    MUL R7, R7, R1	; Calculate the new position shift for the score
	MOV R1, #268	; Screen Width - "P2" Height = 273 - 15 starting offset = 268
    SUB R1, R1, R7	; Add the offset to draw the score below "P2"
    MOV R2, #449	; Screen Height (400 + Offset 49)
    LDR R3, =Pong_Point
    BL TFT_DrawImage

	POP{R1-R3, R7, LR}
	BX LR


; ******************************************* ;
; 				 New Round 	          	      ;
; ******************************************* ;
PONG_NewRound
	PUSH{R1-R5, LR}
	
;R7 = Paddle1 
;R8 = Paddle2
;R11 = X Center 
;R10 = Y Center 
	
	;Clear Playing Screen
	MOV R1,#6
	MOV R2,#315
	MOV R3,#6
	MOV	R4,#395
	LDR R5,=BACKGROUND
	BL TFT_DrawRect
	
	;Draw Paddles
	BL PONG_DrawPaddle1
	BL PONG_DrawPaddle2
	
	;Draw Ball
	BL PONG_DrawBall
	
	
	POP{R1-R5, LR}
	BX LR
; ******************************************* ;
; 				 	New Game 	          	  ;
; ******************************************* ;
PONG_NewGame
	PUSH{R1-R5, LR}
	
;R7 = Paddle1 
;R8 = Paddle2
;R11 = X Center 
;R10 = Y Center 
	
	;Clear Whole Screen
	MOV R1,#0
	MOV R2,#320
	MOV R3,#0
	MOV	R4,#480
	LDR R5,=BACKGROUND
	BL TFT_DrawRect
	
	;Draw Boundaries
	BL PONG_DrawBoundaries
	
	;Draw Paddles
	BL PONG_DrawPaddle1
	BL PONG_DrawPaddle2
	
	;Draw Ball
	BL PONG_DrawBall
	
	;Pong Scoreboard Background Color
	MOV R1,#0
	MOV R2,#320
	MOV R3,#400
	MOV R4,#480
	LDR R5, =SCOREBACKGROUND
	BL TFT_DrawRect
	
	;Draw Scoreboard : 20 x 75
	MOV R1,#295
	MOV R2,#403
	LDR R3,=Pong_Score
	BL TFT_DrawImage
	
	MOV R1,#0
	MOV R2,#400
	LDR R3,=PongPhOTO
	BL TFT_DrawImage
	
	BL PONG_DrawBoundaries

	POP{R1-R5, LR}
	BX LR

; =============================================================	;
; 						XO input FUNCTIONS                      ;
; =============================================================	;
XO_INPUT 
	push{R0-R11,LR}
	
START


	LDR R4,=Current_Pointer
	LDR R12,[R4]
	MOV R5,#0x000001FF
	AND R3,R12,R5         ;;;R3 HAS THE PREVIUS LOCATION WITH OUT THE "A"BIT  	

	LDR R0,=GPIOB_BASE + GPIO_IDR
	LDR R1,[R0]        ;;;;;R1 HAS INPUT DATA


 ; Add hardware debouncing by checking multiple times
    PUSH {R2}
    MOV R2, #0            ; Button state confirmation counter
    
CONFIRM_INPUT
    LDR R0,=GPIOB_BASE + GPIO_IDR
    LDR R6,[R0]           ; Read input again
    CMP R1, R6            ; Compare with previous reading
    BNE RESET_INPUT       ; If not the same, reset counter
    ADD R2, R2, #1        ; Increment confirmation counter
    CMP R2, #5            ; Need 5 consistent readings
    BLT CONFIRM_INPUT
    B PROCESS_INPUT
    
RESET_INPUT
    MOV R1, R6            ; Update our reading
    MOV R2, #0            ; Reset counter
    B CONFIRM_INPUT
    
PROCESS_INPUT
    POP {R2}
    
    ; Add a check for multiple buttons pressed - accept only single button presses
    MOV R6, R1            ; Copy input data
    AND R6, #0x3F         ; Mask to just our 5 buttons (4 directional + play)
    
    ; Count set bits (1-hot encoding check)
    MOV R7, #0            ; Bit counter
    MOV R8, #6            ; Check 5 bits
COUNT_BITS
    TST R6, #1
    ADDEQ R7, R7, #0
    ADDNE R7, R7, #1
    LSR R6, R6, #1
    SUBS R8, R8, #1
    BNE COUNT_BITS
    
    CMP R7, #1            ; Only proceed if exactly one button is pressed
    BNE IDEAL_STATE             ; Skip if multiple buttons or no buttons

	MOV  R3, R1, LSR #5  
	AND R3,R3,#0x1
	CMP R3,#0x1
	BNE NOTBACKXO
	BL Wait_Input_Finish
	STR R12,[R4]
    POP{R0-R11,LR}
    B XO_MENU
NOTBACKXO
	MOV R3 ,#0x01FF
	AND R3,R12,R3
	;;;;;;;;;;;;;;;;;;; CHECK FOR UP;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	TST R1,#0x0001
	BEQ SKIP_THIS_LINE_1
	BL Wait_Input_Finish 

	MOV R12,R3,LSR #3      ;;; R12 HAS THE CURRENT LOCATION WITH OUT THE "A"BIT
	AND R12,R12,R5
	CMP R12,#0           ;;; CHECK IF WE ARE IN THE UPPER LOCATIONS
	BEQ IDEAL_STATE
	STR R12 , [R4]
	B FINISH
	
;;;;;;;;;;;;;;;;;;; CHECK FOR DOWN ;;;;;;;;;;;;;;;;
SKIP_THIS_LINE_1

	TST R1,#0x0002	
    BEQ SKIP_THIS_LINE_2
	BL Wait_Input_Finish 

	MOV R12,R3,LSL #3     ;;; R12 HAS THE CURRENT LOCATION WITH OUT THE "A"BIT
	AND R12,R12,R5
	CMP R12,#0           ;;; CHECK IF WE ARE IN THE UPPER LOCATIONS
	BEQ IDEAL_STATE
	STR R12 , [R4]
	B FINISH
		
;;;;;;;;;;;;;;;;;; CHECK FOR RIGHT;;;;;;;;;;;;;;;;;;
SKIP_THIS_LINE_2

	TST R1,#0x0004	
    BEQ SKIP_THIS_LINE_3
	BL Wait_Input_Finish 
 	
	MOV R12,R3,LSL #1  ;;; R12 HAS THE CURRENT LOCATION WITH OUT THE "A"BIT
	AND R12,R12,R5
	CMP R12,#0         ;;; CHECK IF WE ARE IN THE UPPER LOCATIONS
	BEQ IDEAL_STATE
	STR R12 , [R4]
	B FINISH

	
	
;;;;;;;;;;;;;;;;;; CHECK FOR LEFT;;;;;;;;;;;;;;;;;;;;;
SKIP_THIS_LINE_3
	TST R1,#0x0008	
    BEQ SKIP_THIS_LINE_4
	BL Wait_Input_Finish 

	MOV R12,R3,LSR #1  ;;; R12 HAS THE CURRENT LOCATION WITH OUT THE "A"BIT
	AND R12,R12,R5
	CMP R12,#0         ;;; CHECK IF WE ARE IN THE UPPER LOCATIONS
	BEQ IDEAL_STATE
	STR R12 , [R4]
	B FINISH
	
	
;;;;;;;;;;;;;;;;;; CHECK FOR PLAY;;;;;;;;;;;;;;;;;;;;;
SKIP_THIS_LINE_4
	TST R1,#0x0010	
    BEQ IDEAL_STATE
	BL Wait_Input_Finish 
	MOV R2 , #1
    ORR R12 ,R12,R2,LSL #9
	STR R12 , [R4]
	B FINISH

	
;;;;;;;;;;;;;;;;;;;;THE STATE OF NO INPUT OR TRYING TO BE OUT OF BOARDS;;;;;;;;;	
IDEAL_STATE
    ORR R12,R12,R3	;;;BOTH PREVIUS AND CURRENT ARE THE SAME "DIDNOT MOVE"
	B START
	B SKIPpool10
	LTORG
SKIPpool10
FINISH	
	pop {R0-R11,LR}
    BX LR

Wait_Input_Finish
    PUSH {R0-R3,LR}
    
    ; First wait for button release
    MOV R3, #0            ; Counter for stable readings
WAIT_RELEASE
    LDR R0,=GPIOB_BASE + GPIO_IDR
    LDR R1,[R0]
    CMP R1, #0
    BNE RESET_COUNTER     ; Button still pressed
    
    ADD R3, R3, #1        ; Increment stability counter
    CMP R3, #200          ; Need many stable readings
    BLT WAIT_RELEASE
    B WAIT_DONE
    
RESET_COUNTER
    MOV R3, #0            ; Reset counter
    B WAIT_RELEASE
    
WAIT_DONE
    ; Add a fixed delay for debouncing
    LDR R2,=0x30000
DEBOUNCE_DELAY
    SUBS R2,R2,#1
    BNE DEBOUNCE_DELAY
    
    POP {R0-R3,LR}
    BX LR
	
; =============================================================	;
; 						XO DRAW FUNCTIONS                       ;
; =============================================================	;

; ******************************************* ;
; 				 Draw Grid 	                  ;
; ******************************************* ;

XO_DrawGrid

    PUSH{R0-R5,LR}

    ;Draw Vertical Lines
    LDR R1 , =Box1X
    ADD R2 , R1, #5
    MOV R3 , #0
    MOV R4 , #380
    LDR R5 , =WHITE
    BL TFT_DrawRect

    LDR R1 , =Box2X
    ADD R2 , R1, #5
    MOV R3 , #0
    MOV R4 , #380
    LDR R5 , =WHITE
    BL TFT_DrawRect

    LDR R1 , =Box3X
    ADD R2 , R1, #5
    MOV R3 , #0
    MOV R4 , #380
    LDR R5 , =WHITE
    BL TFT_DrawRect

    MOV R1 , #315
    ADD R2 , R1, #5
    MOV R3 , #0
    MOV R4 , #380
    LDR R5 , =WHITE
    BL TFT_DrawRect

    ;Draw Horizontal Lines
    MOV R1 , #0
    MOV R2 , #320
    LDR R3 , =Box1Y
    ADD R4 , R3 , #5
    LDR R5 , =WHITE
    BL TFT_DrawRect

    MOV R1 , #0
    MOV R2 , #320
    LDR R3 , =Box4Y
    ADD R4 , R3 , #5
    LDR R5 , =WHITE
    BL TFT_DrawRect

    MOV R1 , #0
    MOV R2 , #320
    LDR R3 , =Box7Y
    ADD R4 , R3 , #5
    LDR R5 , =WHITE
    BL TFT_DrawRect

    MOV R1 , #0
    MOV R2 , #320
    MOV R3 , #375
    ADD R4 , R3 , #5
    LDR R5 , =WHITE
    BL TFT_DrawRect

	B SKIPpool_XO_DrawGrid
	LTORG
SKIPpool_XO_DrawGrid


    POP{R0-R5,LR}
    BX LR

; ******************************************* ;
; 				 Reset Grid 	              ;
; ******************************************* ;

XO_ResetGrid

    PUSH{R1,R2,R3,R10,R11,LR}
	;First Redraw the Background
    MOV R1 , #0
    MOV R2 , #319
    MOV R3 , #0
    MOV R4 , #380
    LDR R5 , =BLACK
    BL TFT_DrawRect

	MOV R1 , #0
    MOV R2 , #319
    MOV R3 , #430
    MOV R4 , #479
    LDR R5 , =BLACK
    BL TFT_DrawRect

	MOV R1 , #78
	MOV R2 , #430
	LDR R3 , =TIC_TAC_TOE
	BL TFT_DrawImage

    BL XO_DrawGrid

	MOV R12, #0x0010
	LDR R0, =Current_Pointer
	STR R12, [R0]
	BL XO_DrawPointer
    
    MOV R1 , #0
    MOV R2 , #319
    MOV R3 , #430
    MOV R4 , #479

	B SKIPpool_XO_ResetGrid
	LTORG
SKIPpool_XO_ResetGrid

    POP{R1,R2,R3,R10,R11,LR}
    BX LR

XO_ResetScreen
	PUSH{R1,R2,R3,R4,R5,R10,R11,LR}

	BL  XO_ResetGrid

	MOV R1,#0
	MOV R2,#320
	MOV R3,#380
	MOV R4,#430
	LDR R5,=0x116A
	BL TFT_DrawRect


	MOV R1,#3
	MOV R2,#394
	LDR R3,=Score_P1_XO
	BL TFT_DrawImage

	MOV R1,#160
	MOV R2,#394
	LDR R3,=Score_P2_XO
	BL TFT_DrawImage

	MOV R1 , #78
	MOV R2 , #430
	LDR R3 , =TIC_TAC_TOE
	BL TFT_DrawImage

	B SKIPpool_XO_ResetScreen
	LTORG
SKIPpool_XO_ResetScreen

	POP{R1,R2,R3,R4,R5,R10,R11,LR}
    BX LR
; === Solves Error Literal Pool === ;
	B SKIPpool
	LTORG
SKIPpool
; ******************************************* ;
; 			Draw Player 1 Wins 	              ;
; ******************************************* ;

XO_OneWins
    PUSH{R1,R2,R3,R10,LR}

    MOV R1,#0
    MOV R2,#319
    MOV R3,#430
    MOV R4,#479
    LDR R5,=BLACK
    BL TFT_DrawRect

    MOV R1 , #100
    MOV R2 , #430
    LDR R3 , =P1Wins
    BL TFT_DrawImage

    ;Draw score
    LSR R10, #10  ; get the score of player 1
	AND R10,R10,#7
    SUB R10, R10, #1
	MOV R1, #20
    MUL R10, R10, R1
    ADD R1, R10, #60
    MOV R2, #380
    LDR R3, =Point
    BL TFT_DrawImage

    POP{R1,R2,R3,R10,LR}
    BX LR

; ******************************************* ;
; 			Draw Player 2 Wins 	              ;
; ******************************************* ;

XO_TwoWins
    PUSH{R1,R2,R3,R11,LR}


    MOV R1,#0
    MOV R2,#319
    MOV R3,#430
    MOV R4,#479
    LDR R5,=BLACK
    BL TFT_DrawRect


    MOV R1 , #100
    MOV R2 , #430
    LDR R3 , =P2Wins
    BL TFT_DrawImage

    ;Draw score
    LSR R11, #10  ; get the score of player 2
    SUB R11, R11, #1
    MOV R1, #20
    MUL R11, R11, R1
    ADD R1, R11, #220
    MOV R2, #380
    LDR R3, =Point
    BL TFT_DrawImage

    POP{R1,R2,R3,R11,LR}
    BX LR

; ******************************************* ;
; 				 Draw "DRAW" 	              ;
; ******************************************* ;

XO_DrawDraw
    PUSH{R1-R3,LR}

    MOV R1,#0
    MOV R2,#319
    MOV R3,#430
    MOV R4,#479
    LDR R5,=BLACK
    BL TFT_DrawRect

    MOV R1 , #100
    MOV R2 , #430
    LDR R3 , =Draw
    BL TFT_DrawImage

    POP{R1-R3,LR}
    BX LR

; ******************************************* ;
; 				 Draw Pointer 	              ;
; ******************************************* ;

XO_DrawPointer
	PUSH{R0-R12, LR}
	
	BL XO_DrawGrid
	
DrawNewPointer
	; Draw new position with yellow borders
	LDR R1,=Current_Pointer
	LDR R6,[R1]
	;MOV R6 , R12
	MOV R8, #0x01FF         ; First part of our mask (255)
	AND R6, R6, R8          ; Mask to keep only 9 bits
	LDR R5, =YELLOW         ; Set color to yellow
	BL GetBoxCoordinates    ; Returns coordinates in R1(x), R3(y)
	BL DrawBoxOutline       ; Draw yellow outline around new position

	POP{R0-R12, LR}
	BX LR
	
; *************************************************************	;
; GetBoxCoordinates: Converts box number (1-9) to coordinates   ;
; Input: R6 - Box number (1-9)                                  ;
; Output: R1 - X coordinate, R3 - Y coordinate                  ;
; *************************************************************	;
GetBoxCoordinates
	PUSH{R0,R2,R4-R9, LR}
	
	; Check which bit is set in the 9-bit value
	MOV R8, #1              ; Start with bit 0
	MOV R9, #1              ; Box counter
	
CheckBit
	TST R6, R8              ; Test if this bit is set
	BNE FoundBox            ; If set, we found our box
	LSL R8, R8, #1          ; Shift to next bit
	ADD R9, R9, #1          ; Increment box counter
	CMP R9, #10             ; Check if we've gone past box 9
	BLT CheckBit            ; BLT : Branch Less Than ==> Continue Loop
	
	; Default to box 1 if no bit is set
	MOV R9, #5 	; Question : There's Always a Bit Set ??
	
FoundBox
	; Get coordinates based on box number
	CMP R9, #1
	BNE Skip_Box_One
	LDR R1, =Box1X
	LDR R3, =Box1Y
	B GetCoordinatesDone
Skip_Box_One
	CMP R9, #2
	BNE Skip_Box_Two
	LDR R1, =Box2X
	LDR R3, =Box2Y
	B GetCoordinatesDone
Skip_Box_Two
	CMP R9, #3
	BNE Skip_Box_Three
	LDR R1, =Box3X
	LDR R3, =Box3Y
	B GetCoordinatesDone
Skip_Box_Three
	CMP R9, #4
	BNE	Skip_Box_Four
	LDR R1, =Box4X
	LDR R3, =Box4Y
	B GetCoordinatesDone
Skip_Box_Four
	CMP R9, #5
	BNE Skip_Box_Five
	LDR R1, =Box5X
	LDR R3, =Box5Y
	B GetCoordinatesDone
Skip_Box_Five
	CMP R9, #6
	BNE	Skip_Box_Six
	LDR R1, =Box6X
	LDR R3, =Box6Y
	B GetCoordinatesDone
Skip_Box_Six
	CMP R9, #7
	BNE Skip_Box_Seven
	LDR R1, =Box7X
	LDR R3, =Box7Y
	B GetCoordinatesDone
Skip_Box_Seven
	CMP R9, #8
	BNE	Skip_Box_Eight
	LDR R1, =Box8X
	LDR R3, =Box8Y
	B GetCoordinatesDone
Skip_Box_Eight
	CMP R9, #9
	BNE Skip_Box_Nine	; Correct ???
	LDR R1, =Box9X
	LDR R3, =Box9Y
Skip_Box_Nine
	
GetCoordinatesDone
	POP{R0,R2,R4-R9, LR}
	BX LR
	
; *************************************************************	;
; DrawBoxOutline: Draws a box outline at specified coordinates  ;
; Input: R1 - X coordinate, R3 - Y coordinate, R5 - Color       ;
; *************************************************************	;
DrawBoxOutline
	PUSH{R0-R7, LR}
	
	; Draw top horizontal line
	ADD R2, R1, #110	; X2 = X1 + 2*Thickness(5) + Width(100)
	ADD R4, R3, #5		; Y2 = Y1 + Thickness(5)
	BL TFT_DrawRect
	
	; Draw left vertical line (R1 & R3 Unchanged)
	ADD R2, R1, #5		; X2 = X1 + Thickness(5)
	ADD R4, R3, #130	; Y2 = Y1 + 2*Thicnkess(5) + Height(120)
	BL TFT_DrawRect
	
	; Draw bottom horizontal line (R1 & R3 Unchanged)
	MOV R6, R1			; Save Pointer X (Could Neglect This Line)
	MOV R7, R3			; Save Pointer Y
	ADD R2, R1, #110	; X2 = X1 + 2*Thickness(5) + Width(100)
	ADD R3, R7, #125	; Y1 = Y1(Old) + Thickness(5) + Height(120)
	ADD R4, R3, #5		; Y2 = Y1 + Thickness(5)
	BL TFT_DrawRect
	
	; Draw right vertical line
	ADD R1, R6, #105	; X1 = Pointer X + Thickness(5) + Width(100)
	ADD R2, R1, #5		; X2 = X1 + Thickness(5)
	MOV R3, R7			; Y1 = Pointer Y
	ADD R4, R3, #130	; Y2 = Y1 + 2*Thickness(5) + Height(120)
	BL TFT_DrawRect
	
	POP{R0-R7, LR}
	BX LR


; === Solves Error Literal Pool === ;
	B SKIP
	LTORG
SKIP
; ================================= ;

; ******************************************* ;
; 				  Draw X		              ;
; ******************************************* ;
XO_DrawX
	; Input R12 : (13 Unused Bits | 9 Old Pointer Bits | 1 Skip Bit | 9 New Pointer Bits)
	PUSH{R1-R3,R6,R8,R12,LR}

	LDR R1,=Current_Pointer
	LDR R6,[R1]    
	;MOV R6 , R12
	MOV R8, #0x01FF         ; First part of our mask (255)
	AND R6, R6, R8          ; Mask to keep only 9 bits
	
	; Place Input From R12 into R6 (DONE)
	; Call GetBoxCoordinates : Output: R1 - X coordinate, R3 - Y coordinate
	; Make Necessary Shifts
	; Call DrawImage : Input : R1 - Start X , R2 - Start Y
	BL GetBoxCoordinates ; now R1 - X coordinate, R3 - Y coordinate
	ADD R1,R1,#12
	ADD R2,R3,#21
	LDR R3, =Ximg	;R3 = Img Address
	BL TFT_DrawImage
	POP{R1-R3,R6,R8,R12,LR}
    BX LR
; ******************************************* ;
; 				  Draw O		              ;
; ******************************************* ;
XO_DrawO
	; Input R12 : (13 Unused Bits | 9 Old Pointer Bits | 1 Skip Bit | 9 New Pointer Bits)
	PUSH{R1-R3,R6,R8,R12,LR}

	LDR R1,=Current_Pointer
	LDR R6,[R1]    
	;MOV R6,R12
	MOV R8, #0x01FF         ; First part of our mask (255)
	AND R6, R6, R8          ; Mask to keep only 9 bits
	
	; Place Input From R12 into R6 (DONE)
	; Call GetBoxCoordinates : Output: R1 - X coordinate, R3 - Y coordinate
	; Make Necessary Shifts
	; Call DrawImage : Input : R1 - Start X , R2 - Start Y
	BL GetBoxCoordinates ; now R1 - X coordinate, R3 - Y coordinate
	ADD R1,R1,#18
	ADD R2,R3,#20
	LDR R3, =Oimg	;R3 = Img Address
	BL TFT_DrawImage	

	POP{R1-R3,R6,R8,R12,LR}
    BX LR

; ************************************************************* ;
;		                   Game Logic		            		;
; *************************************************************	;
XO_GameLogic
    ; R9 FOR THE GRID , R10 FOR X PLAYER , R11 FOR O PLAYER
	
	PUSH{R0,R3,R4,R5,R12, LR}
	
	; GET IF A BUTTON IS PRESSED IF NOT EXIT 
	LDR R0, =Current_Pointer
	LDR R12, [R0]
	LDR R0 , =XO_Grid
	LDR R9 , [R0]
	LDR R0 , =XO_Player1
	LDR R10 , [R0]
	LDR R0 , =XO_Player2
	LDR R11 , [R0]
	MOV R3 ,#0x00000200
	AND R3,R3,R12
	CMP R3 ,#0
	BEQ.W EXIT 
	
	;CHECK IF ANY PLAYER WON IF SO RESET 
	MOV R3 ,#0x00000200
	AND R3,R3,R10
	CMP R3 ,#0
	BNE Reset
	MOV R3 ,#0x00000200
	AND R3,R3,R11
	CMP R3 ,#0
	BNE Reset
	
	;CHECK IF ITS A DRAW IF SO RESET
	MOV R3 ,#0x000001FF
	AND R3 ,R3 ,R9
	LDR R5,=0x000001FF
	CMP R3 ,R5
	BEQ Reset

	
	
	; CHECK IF THIS POSITION IS AVAILABLE 
	MOV R3 ,#0x000001FF
	AND R3 ,R3 ,R12
	AND R3, R3 ,R9
	CMP R3,#0
	BNE.W EXIT
	
	;GET PLAYER TURN 
	MOV R3 ,#0x00000200
	AND R3,R3,R9
	CMP R3,#0
	BEQ MOVE_PLAYER_1
	B MOVE_PLAYER_2
	


 ;PLAYER 1 --> X
MOVE_PLAYER_1
	; SET X IN X REG [R10] AND GRID REG [R9]
	MOV R3 ,#0x000001FF
	AND R3 ,R3 ,R12
	ORR R9 , R9 , R3
	ORR R10 , R10 , R3 
	ORR R9,R9,#0x00000200	;TO CHANGE TO THE OTHER PLAYER TURN 
	
	;=============== DRAW X FUNCTION ==============
	BL XO_DrawX
	;CHECK IF WON AND THEN SET THE  10 TH BIT 
	MOV R3 ,#0x000001FF
	AND R3 ,R3 ,R10
	BL CHECK_WINNING
	ORR R10,R10,R3
	
	;IF WON INCREASE THE SCORE 
	CMP R3, #0x00000200
	BNE EXIT
	ADD R10,R10,#0x00000400	  ;INCREMENT THE SCORE
    BL XO_OneWins 
	B EXIT 

	; PLAYER 2 --> O
MOVE_PLAYER_2
	; SET O IN 0 REG [R11] AND GRID REG [R9]
	MOV R3 ,#0x000001FF
	AND R3 ,R3 ,R12
	ORR R9 , R9 , R3
	ORR R11 , R11 , R3 
	BIC R9,R9,#0x00000200	;TO CHANGE TO THE OTHER PLAYER TURN 
	
	;=============== DRAW O FUNCTION ==============
	BL XO_DrawO
	;CHECK IF WON AND THEN SET THE  10 TH BIT 
	MOV R3 ,#0x000001FF
	AND R3 ,R3 ,R11
	BL CHECK_WINNING
	ORR R11,R11,R3
	
	;IF WON INCREASE THE SCORE 
	CMP R3, #0x00000200
	BNE EXIT
	ADD R11,R11,#0x00000400	  ;INCREMENT THE SCORE 
    BL XO_TwoWins
	B EXIT 

Reset
    LDR R5, =0x01FF
    BIC R9, R9, R5
    LDR R5, =0x03FF
    BIC R10, R10, R5
    BIC R11, R11, R5
	LDR R5, =0x1400
	CMP R10,R5
	BEQ ResetALL
	CMP R11,R5
	BEQ ResetALL
    BL XO_ResetGrid
    B EXIT
ResetALL
	MOV R10,#0
	MOV R11,#0
	BL XO_ResetScreen
	B EXIT

CHECK_WINNING
	PUSH {LR}
	; CHECK WINNING
	MOV R5 ,#0x0111  
	AND R4, R3 , R5    ; 1 5 9
    CMP R4 , R5 
	BEQ WINNING
	
	MOV R5 ,#0x0054
	AND R4, R3 , #0x0054      ; 3 5 7
	CMP R4 , R5 
	BEQ WINNING
	
	MOV R5 ,#0x0007
	AND R4, R3 , R5      ; 1 2 3
	CMP R4 , R5 
	BEQ WINNING
	
	MOV R5 ,#0x0038
	AND R4, R3 , R5      ; 4 5 6
	CMP R4 , R5 
	BEQ WINNING
	
	MOV R5 ,#0x01C0
	AND R4, R3 , R5      ; 7 8 9
	CMP R4 , R5 
	BEQ WINNING
	
	MOV R5 ,#0x0049
	AND R4, R3 , R5      ; 1 4 7
	CMP R4 , R5 
	BEQ WINNING
	
	MOV R5 ,#0x0092
	AND R4, R3 , R5      ; 2 5 8
	CMP R4 , R5 
	BEQ WINNING
	
	MOV R5 ,#0x0124
	AND R4, R3 , R5     ; 3 6 9
	CMP R4 , R5 
	BEQ WINNING

	MOV R4 ,#0x000001FF
	AND R4 ,R4 ,R9
	LDR R5,=0x000001FF
	CMP R4 ,R5
	BLEQ  XO_DrawDraw 
	POP {PC}
		
WINNING
	MOV R3,#0x00000200
	POP {LR}
    BX LR
	
EXIT
	LDR R0 , =XO_Grid
	STR R9 , [R0]
	LDR R0 , =XO_Player1
	STR R10 , [R0]
	LDR R0 , =XO_Player2
	STR R11 , [R0]
	POP{R0,R3,R4 ,R5,R12, LR}
    BX LR


	B SKIPpool1
	LTORG
SKIPpool1

; ************************************************************* ;
;		                   vs Computer		            		;
; *************************************************************	;
vsComputer
    ; R9 FOR THE GRID, R10 FOR X PLAYER, R11 FOR COMPUTER
    
    PUSH{R0-R5,R12, LR}
    
    ; GET IF A BUTTON IS PRESSED IF NOT EXIT 
	LDR R0, =Current_Pointer
	LDR R12, [R0]
	LDR R0 , =XO_Grid
	LDR R9 , [R0]
	LDR R0 , =XO_Player1
	LDR R10 , [R0]
	LDR R0 , =XO_Player2
	LDR R11 , [R0]

    MOV R3, #0x00000200
    AND R3, R3, R12
    CMP R3, #0
    BEQ.W EXIT_VS_COMPUTER
    
    ;CHECK IF ANY PLAYER WON IF SO RESET 
    MOV R3, #0x00000200
    AND R3, R3, R10
    CMP R3, #0
    BNE RESET_VS_COMPUTER
    MOV R3, #0x00000200
    AND R3, R3, R11
    CMP R3, #0
    BNE RESET_VS_COMPUTER
    
    ;CHECK IF ITS A DRAW IF SO RESET
    MOV R3, #0x000001FF
    AND R3, R3, R9
    LDR R5, =0x000001FF
    CMP R3, R5
    BEQ RESET_VS_COMPUTER

    ; CHECK IF THIS POSITION IS AVAILABLE 
    MOV R3, #0x000001FF
    AND R3, R3, R12
    AND R3, R3, R9
    CMP R3, #0
    BNE.W EXIT_VS_COMPUTER
    
    ; MOVE PLAYER 1
    ; SET X IN X REG [R10] AND GRID REG [R9]
    MOV R3, #0x000001FF
    AND R3, R3, R12
    ORR R9, R9, R3
    ORR R10, R10, R3 
    ORR R9, R9, #0x00000200    ; TO CHANGE TO THE COMPUTER'S TURN
    
    ; DRAW X FUNCTION
    BL XO_DrawX
    
    ; CHECK IF PLAYER WON
    MOV R3, #0x000001FF
    AND R3, R3, R10
    BL CHECK_WINNING
    ORR R10, R10, R3
    
    ; IF PLAYER WON, INCREASE SCORE
    CMP R3, #0x00000200
    BEQ PLAYER_WON
    
    ; CHECK DRAW --> GRID IS FULL
    MOV R3, #0x000001FF
    AND R3, R3, R9
    LDR R5, =0x000001FF
    CMP R3, R5
    BEQ DRAW_VS_COMPUTER
    
    ; COMPUTER'S TURN
    BL MOVE_COMPUTER
    B EXIT_VS_COMPUTER

PLAYER_WON
    ADD R10, R10, #0x00000400    ; INCREMENT SCORE
	ORR R10 , R10 , #0x00010000  ; SET 17TH BIT AS INDICATOR TO WINNING 
    BL XO_OneWins
    B EXIT_VS_COMPUTER

DRAW_VS_COMPUTER
    BL XO_DrawDraw
    B EXIT_VS_COMPUTER

RESET_VS_COMPUTER
    LDR R5, =0x01FF
    BIC R9, R9, R5
    LDR R5, =0x03FF
    BIC R10, R10, R5
    BIC R11, R11, R5
	LDR R5, =0x1C00
	AND R6,R10,R5
	LDR R5 ,=0x1400
	CMP R6,R5
	BEQ RESETALL_VSCOMPUTER
	CMP R11,R5
	BEQ RESETALL_VSCOMPUTER
    BL XO_ResetGrid
	TST R10 , #0x00010000	
	BLNE MOVE_COMPUTER
	BIC R10 , #0x00010000	
    B EXIT_VS_COMPUTER
RESETALL_VSCOMPUTER
	LDR R5,=0x1C00
	BIC R10,R5
	MOV R11,#0
	BL XO_ResetScreen
	TST R10 , #0x00010000	
	BLNE MOVE_COMPUTER
	BIC R10 , #0x00010000	
	B EXIT_VS_COMPUTER


EXIT_VS_COMPUTER

	LDR R0, =Current_Pointer
	STR R12, [R0]
	LDR R0 , =XO_Grid
	STR R9 , [R0]
	LDR R0 , =XO_Player1
	STR R10 , [R0]
	LDR R0 , =XO_Player2
	STR R11 , [R0]
    POP{R0-R5,R12, LR}
    BX LR

	; COMPUTER --> O
MOVE_COMPUTER
    PUSH {R0-R5, LR}
    BL COMPUTER_PLAY_LOGIC
    
    LDR R0, =Current_Pointer
    LDR R12, [R0]
    
	BL XO_DrawPointer
    ; SET O IN O REG [R11] AND GRID REG [R9]
    MOV R3, #0x000001FF
    AND R3, R3, R12
    ORR R9, R9, R3
    ORR R11, R11, R3 
    BIC R9, R9, #0x00000200    ; TO PLAYER'S TURN [ X TURN ]
	
    ; DRAW 'O' OF COMPUTET TURN
    BL XO_DrawO
    
    ; CHECK IF COMPUTER WON
    MOV R3, #0x000001FF
    AND R3, R3, R11
    BL CHECK_WINNING
    ORR R11, R11, R3
    
    ; IF COMPUTER WON, INCREASE THE SCORE
    CMP R3, #0x00000200
    BNE COMPUTER_MOVE_DONE
    ADD R11, R11, #0x00000400    ; INCREMENT THE SCORE
    BL XO_TwoWins
    
COMPUTER_MOVE_DONE
    POP {R0-R5, PC}
	
	
COMPUTER_PLAY_LOGIC
CHECK_WINNING_MOVE
    PUSH {R0-R7, LR}
    
    ; 1. Try to win
    ; 2. Block X
    ; 3. Center
    ; 4. Corners
    ; 5. Any free move
	
	MOV R4, #0               ; R4 FOR POSITION
	LDR R5, =0x01FF          ; ONLY FIRST 9 BITS
	AND R5, R5, R9           ; GET POSITION BITS
	LDR R6, =0x01FF          
	EOR R5, R5, R6           ; Invert -> Available places


    ; CHECK IF COMPUTER CAN WIN AT THIS TURN
    MOV R4, R11             
    
    ; LOOP TO GET FIRST AVAILABLE POSITION
    MOV R6, #0x0001          
    MOV R7, #1               ; COUNTER
    
CHECK_WIN_LOOP
    TST R5, R6               
    BEQ NEXT_WIN_POS         ; TRY NEW POSITION
    
    ; AN AVAILABLE POSITION
    ORR R0, R4, R6           
    PUSH {R3, R4, R5}        
    MOV R3, R0               ; R3 FOR CHECK WINNING
    BL CHECK_WINNING         
    CMP R3, #0x00000200      
    POP {R3, R4, R5}         
    BEQ FOUND_WINNING_MOVE   ; IF A WINNING MOVE , PLAY IT 
    
NEXT_WIN_POS
    LSL R6, R6, #1           
    ADD R7, R7, #1           
    CMP R7, #10              ; CHECK ON ALL POSITIONS
    BLT CHECK_WIN_LOOP       ; IF ALL POSITIONS NOT REACHED , CONTINUE
    
    ; IF NO WINNING MOVE , TRY TO BLOCK THE [ X ] WINNING MOVE 
    MOV R4, R10              ; POSITION OF PLAYER 1 [ X ]
    
    
    MOV R6, #0x0001          
    MOV R7, #1               
    
CHECK_BLOCK_LOOP
    TST R5, R6               
    BEQ NEXT_BLOCK_POS       ; TRY NEW POSITION
    
    
    ORR R0, R4, R6           
    PUSH {R3, R4, R5}        
    MOV R3, R0               ; R3 FOR CHECK_WINNING
    BL CHECK_WINNING         
    CMP R3, #0x00000200      
    POP {R3, R4, R5}         
    BEQ FOUND_WINNING_MOVE   ; IF A WINNING MOVE , BLOCK IT 
    
NEXT_BLOCK_POS
    LSL R6, R6, #1           
    ADD R7, R7, #1           
    CMP R7, #10              
    BLT CHECK_BLOCK_LOOP     
    
    ; CHECK CENTER IF NO BLOCKING OR WINNING MOVES
    MOV R6, #0x0010          ; 0 0001 0000 --> POSITION OF THE CENTER
    TST R5, R6               ; CHECK IF CENTER IS AVAILABLE 
    BNE FOUND_WINNING_MOVE   ; IF AVAILABLE , THIS IS THE MOVE OF COMPUTER
    
    ; CHECK ON CORNERS IF CENTER ISN'T AVAILABLE 
    MOV R6, #0x0001          ; TOP LEFT CORNER : 0 0000 0001
    TST R5, R6               
    BNE FOUND_WINNING_MOVE   
    
    MOV R6, #0x0004          ; TOP RIGHT CORNER : 0 0000 0100
    TST R5, R6               
    BNE FOUND_WINNING_MOVE   
    
    MOV R6, #0x0040          ; BOTTOM LEFT CORNER : 0 0100 0000
    TST R5, R6               
    BNE FOUND_WINNING_MOVE   
    
    MOV R6, #0x0100          ; BOTTOM RIGHT CORNER : 0001 0000 0000
    TST R5, R6              
    BNE FOUND_WINNING_MOVE   
    
    ; REMAINING AVAILABLE POSITIONS
    MOV R6, #0x0001          ; START AT POS #1
    
FIND_ANY_POS
    TST R5, R6               
    BNE FOUND_WINNING_MOVE   ; IF AVAILABLE , THIS IS THE MOVE OF COMPUTER
    LSL R6, R6, #1           ; NEXT POSITION
    CMP R6, #0x0200          ; TO NOT EXCEED 9 POSITIONS 
    BLT FIND_ANY_POS         ; IF NOT EXCEEDED , CONTINUE
    
    
FOUND_WINNING_MOVE
    ; POINTER TO POINTS TO THE POSITION THE COMPUTER WILL PLAY IN IT 
    MOV R12, R6              
    LDR R0, =Current_Pointer
    STR R12, [R0]            ; UPDATE POINTER
    
    POP {R0-R7, PC}

	B SKIPpool2
	LTORG
SKIPpool2
; ************************************************************* ;
;			 TFT Write Command (R0 = command)					;
; *************************************************************	;
TFT_WriteCommand
    PUSH {R1-R2, LR}

    ; Set CS low
    LDR R1, =GPIOA_BASE + GPIO_ODR
    LDR R2, [R1]
    BIC R2, R2, #TFT_CS
    STR R2, [R1]

    ; Set DC (RS) low for command
    BIC R2, R2, #TFT_DC
    STR R2, [R1]

    ; Set RD high (not used in write operation)
    ORR R2, R2, #TFT_RD
    STR R2, [R1]

    ; Send command (R0 contains command)
    BIC R2, R2, #0xFF   ; Clear data bits PE0-PE7
    AND R0, R0, #0xFF   ; Ensure only 8 bits
    ORR R2, R2, R0      ; Combine with control bits
    STR R2, [R1]

    ; Generate WR pulse (low > high)
    BIC R2, R2, #TFT_WR
    STR R2, [R1]
    ORR R2, R2, #TFT_WR
    STR R2, [R1]

    ; Set CS high
    ORR R2, R2, #TFT_CS
    STR R2, [R1]

    POP {R1-R2, LR}
    BX LR

; *************************************************************	;
; 				TFT Write Data (R0 = data)						;
; *************************************************************	;
TFT_WriteData
    PUSH {R1-R2, LR}

    ; Set CS low
    LDR R1, =GPIOA_BASE + GPIO_ODR
    LDR R2, [R1]
    BIC R2, R2, #TFT_CS
    STR R2, [R1]

    ; Set DC (RS) high for data
    ORR R2, R2, #TFT_DC
    STR R2, [R1]

    ; Set RD high (not used in write operation)
    ORR R2, R2, #TFT_RD
    STR R2, [R1]

    ; Send data (R0 contains data)
    BIC R2, R2, #0xFF   ; Clear data bits PE0-PE7
    AND R0, R0, #0xFF   ; Ensure only 8 bits
    ORR R2, R2, R0      ; Combine with control bits
    STR R2, [R1]

    ; Generate WR pulse
    BIC R2, R2, #TFT_WR
    STR R2, [R1]
    ORR R2, R2, #TFT_WR
    STR R2, [R1]

    ; Set CS high
    ORR R2, R2, #TFT_CS
    STR R2, [R1]

    POP {R1-R2, LR}
    BX LR

; *************************************************************	;
; 					TFT Initialization						   	;
; *************************************************************	;
TFT_Init
    PUSH {R0-R2, LR}

; ======= HARDWARE RESET ======= ;

    LDR R1, =GPIOA_BASE + GPIO_ODR
    LDR R2, [R1]
    
    ; Reset HIGH
    ORR R2, R2, #TFT_RST
    STR R2, [R1]
    BL delay

    ; Reset LOW
    BIC R2, R2, #TFT_RST
    STR R2, [R1]
    BL delay
    
    ; Reset HIGH
    ORR R2, R2, #TFT_RST
    STR R2, [R1]
    BL delay
    
	
; ======= SOFTWARE RESET ======= ;
	
    ; CS HIGH
    ORR R2,	R2, #TFT_CS
    STR R2,	[R1]

    ; WR & RD  HIGH
    ORR R2, R2, #TFT_WR
    ORR R2, R2, #TFT_RD
    STR R2, [R1]

    ;CS LOW
    BIC R2, R2, #TFT_CS
    STR R2, [R1]


; ======= VCOM Control (Color Contrast) ======= ;

    MOV R0, #0xC5		; DataSheet Page 244
	BL TFT_WriteCommand
	
	MOV R0, #0x54		; VCOM H 1111111 
	BL TFT_WriteData
	
	MOV R0, #0x00		; VCOM L 0000000
	BL TFT_WriteData	


; ======= Pixel Format Set ======= ;

    MOV R0, #0x3A		; DataSheet Page 200
    BL TFT_WriteCommand
	
    MOV R0, #0x55		; 16 Bit RGB and MCU
    BL TFT_WriteData


; ======= Memory Access Control (MADCTL) ======= ;

	MOV R0, #0x36		; DataSheet Page 193
	BL TFT_WriteCommand
	
	;Start from Top-Left Corner as the Origin Point
	MOV R0, #0x48
	BL TFT_WriteData
	

; ======= Sleep OUT ======= ; (Turns off sleep mode)

    MOV R0, #0x11		; DataSheet Page 170
    BL TFT_WriteCommand
    BL delay

; ======= Display ON ======= ;

    MOV R0, #0x29		; DataSheet Page 176
    BL TFT_WriteCommand
	
; ======= Color Inversion OFF ======= ;

    MOV R0, #0x20		; DataSheet Page 173-174
    BL TFT_WriteCommand

    POP {R0-R2, LR}
    BX LR

; *************************************************************	;
;	  						Address Set							;
; *************************************************************	;
Address_Set
    PUSH{R0-R4, LR}
	
	; COORDINATES :
	;	R1 = X1
	;	R2 = X2
	;	R3 = Y1
	;	R4 = Y2

; ======= Column Address Set ======= ;

	MOV R0, #0x2A		; DataSheet Page 177
	BL TFT_WriteCommand

	;Higher 8 Bits of Starting COLUMN (X1)
	MOV R0, R1, LSR #8 
	BL TFT_WriteData

	;Lower 8 Bits of Starting COLUMN (X1)
	AND R0, R1 , #0xFF
	BL TFT_WriteData

	;Higher 8 Bits of Ending COLUMN (X2)
	MOV R0, R2, LSR #8 
	BL TFT_WriteData

	;Lower 8 Bits of Ending COLUMN (X2)
	AND R0, R2, #0xFF
	BL TFT_WriteData

; ======= Page Address Set ======= ;

	MOV R0, #0x2B		; DataSheet Page 179
	BL TFT_WriteCommand

	;Higher 8 Bits of Starting PAGE (Y1)
	MOV R0, R3, LSR #8 
	BL TFT_WriteData

	;Lower 8 Bits of Starting PAGE (Y1)
	AND R0, R3, #0xFF
	BL TFT_WriteData

	;Higher 8 Bits of Ending PAGE (Y2)
	MOV R0, R4, LSR #8 
	BL TFT_WriteData

	;Lower 8 Bits of Ending PAGE (Y2)
	AND R0, R4,#0xFF
	BL TFT_WriteData

    ;Memory Write (sebhom e7tyate)
    ;MOV R0, #0x2C
    ;BL TFT_WriteCommand

    POP{R0-R4, LR}
    BX LR


; *************************************************************	;
; 						TFT Draw Rect							;
; *************************************************************	;
TFT_DrawRect
    PUSH {R0-R8, LR}
	
	; COORDINATES :
	;	R1 = X1
	;	R2 = X2
	;	R3 = Y1
	;	R4 = Y2
	;	R5 = Color

	; Set Address (R1, R2, R3, R4)
    BL Address_Set

    ; Memory Write
    MOV R0, #0x2C
    BL TFT_WriteCommand

    ; Prepare color bytes
    MOV R6, R5, LSR #8     ; High byte
    AND R5, R5, #0xFF      ; Low byte

    ; Fill RECT with color (AREA = [(X2-X1)+1] * [(Y2-Y1)+1] pixels)
    SUB R7, R2, R1
    ADD R7, R7, #1
    SUB R8, R4, R3
    ADD R8, R8, #1
    MUL R7, R7, R8

FillLoop
    ; Write high byte
    MOV R0, R6
    BL TFT_WriteData
    
    ; Write low byte
    MOV R0, R5
    BL TFT_WriteData
    
    SUBS R7, R7, #1
    BNE FillLoop

    POP {R0-R8, LR}
    BX LR

; *************************************************************	;
; 						TFT Draw Image							;
; *************************************************************	;
TFT_DrawImage
    PUSH {R0-R8, LR}
    
    ; COORDINATES :
    ;   R1 = Start X (X1)
    ;   R2 = Start Y (Y1)
    ;   R3 = Img Address
    
    MOV R5,R3
    ; Load image width and height
    LDR R6, [R5], #4     ; Load width
    LDR R7, [R5], #4     ; Load height
    MUL R8, R6, R7

    ; Calculate end coordinates
    MOV R3, R2           ; Y1 = Start Y
    ADD R2, R1, R6       ; X2 = X1 + Width
    SUB R2, R2, #1       ; Adjust to actual end point
    
    ADD R4, R3, R7       ; Y2 = Y1 + Height
    SUB R4, R4, #1       ; Adjust to actual end point
    
    ; Now R1=X1, R2=X2, R3=Y1, R4=Y2
    BL Address_Set
    
    ; Start Memory Write
    MOV R0, #0x2C
    BL TFT_WriteCommand
    
    
    ; Loop through all pixels
TFT_ImageLoop
    LDRH R0, [R5], #2    ; Load one pixel (16-bit BGR565)
    MOV R1, R0, LSR #8   ; Extract high byte
    AND R2, R0, #0xFF    ; Extract low byte
    
    MOV R0, R1           ; Send High Byte first
    BL TFT_WriteData
    MOV R0, R2           ; Send Low Byte second
    BL TFT_WriteData
    
    SUBS R8, R8, #1
    BGT TFT_ImageLoop
    
    POP {R0-R8, LR}
    BX LR


	B SKIPpool3
	LTORG
SKIPpool3
; *************************************************************	;
; 						Delay Functions							;
; *************************************************************	;
delay
    PUSH {R0, LR}
    LDR R0, =DELAY_INTERVAL
delay_loop
    SUBS R0, R0, #1
    BNE delay_loop
    POP {R0, LR}
    BX LR

    END