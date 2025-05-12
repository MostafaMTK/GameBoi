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

    AREA MOLECODE, CODE, READONLY
	
    IMPORT MoleGame
    IMPORT MoleScore
    IMPORT EmptyHole
    IMPORT MoleHole
    IMPORT MoleHit
	IMPORT WrongHole
    IMPORT YouWin
    IMPORT YouLose
    IMPORT STARTTT
    IMPORT ClickToStart
		
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
BACKGROUND 	EQU		0x7FA7


;Coordinates
Box1X       EQU     0x006E	; Box2 (110 , 100)
Box1Y       EQU     0x0064	; 
Box2X       EQU     0x00D7	; Box6 (215 , 205)
Box2Y       EQU     0x00CD	; 
Box3X       EQU     0x006E  ; Box8 (110 , 310)
Box3Y       EQU     0x0136	;
Box4X       EQU     0x0005	; Box4 (5 , 205)
Box4Y       EQU     0x00CD	; 
Box5X       EQU     0x006E	; Box5 (110 , 205)
Box5Y       EQU     0x00CD	;

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
DELAY_QUARTER    EQU     0x145855  ; 1,333,333 in hex (0.25s at 16MHz)
DELAY_HALF   	 EQU     0x28B0AB  ; 2,666,667 in hex (0.5s at 16MHz)
DELAY_ONE  		 EQU     0x516156  ; 5,333,334 in hex (1s at 16MHz)
	
__main FUNCTION

    BL STM_Configure_Ports
	
	MOV R1,#0
	MOV R2,#350
	MOV R3,#0
	MOV R4,#500
	LDR R5,=WHITE
	BL TFT_DrawRect

	MOV R1,#35
	MOV R2,#165
	LDR R3, =STARTTT
	BL TFT_DrawImage

	MOV R1,#116
	MOV R2,#315
	LDR R3,=ClickToStart
	BL TFT_DrawImage

	B STARTFUNC

STARTGAME

	LDR R11,=0xC719CBF5
	MOV R10,#60
	MOV R9,#0
	MOV R8,#1
	MOV R7,#0
	BL MOLE_DrawStartingScreen
	
MAIN_LOOP	
GAME_LOOP
	BL MOLES_INPUT    ;;;;;;;;;;;;;TO BE CHANGED;;;;;;;;;
	BL MOLES_GAMELOGIC
	SUB R10,R10,#1
	CMP R10,#0
	BEQ END_GAME
	B GAME_LOOP
END_GAME	
	BL CHECK_WIN
	B MAIN_LOOP
	
loop
    B loop
    ENDFUNC
	b skippool1
	LTORG
skippool1
; ************************************************************* ;
; 						WHACKAMOLE INPUT 					    ;
; ************************************************************* ;
MOLES_INPUT
	PUSH{R0-R2,R11,R12,LR}
	LDR R11 , =DELAY_QUARTER
START
	SUB R11 , R11 , #17
	LDR R0,=GPIOB_BASE + GPIO_IDR
	LDR R1,[R0]        ;;;;;R1 HAS INPUT DATA

 ; Add hardware debouncing by checking multiple times
    PUSH {R2}
    MOV R2, #0            ; Button state confirmation counter
    
CONFIRM_INPUT1
    LDR R0,=GPIOB_BASE + GPIO_IDR
    LDR R12,[R0]           ; Read input again
    CMP R1, R12            ; Compare with previous reading
    BNE RESET_INPUT1     ; If not the same, reset counter
    ADD R2, R2, #1        ; Increment confirmation counter
    CMP R2, #5            ; Need 5 consistent readings
    BLT CONFIRM_INPUT1
    B PROCESS_INPUT1
    
RESET_INPUT1
    MOV R1, R12            ; Update our reading
    MOV R2, #0            ; Reset counter
    B CONFIRM_INPUT1
    
PROCESS_INPUT1
    POP {R2}
	
;R7 HAS THE INPUT (FIRST 3 BITS ) AND FIFTH BIT TO CHECK (CLICK TO START)
;FIRST CHECK (CLICK TO START)
	MOV R2,#0x10
	AND R2,R2,R1
	CMP R2,#0x10
	BNE CHECKUP
	MOV R7,#0x10
	B INPUT_SET
CHECKUP
	MOV R2,#0xF
	AND R2,R2,R1
	CMP R2,#1 	;UP
	BNE CHECKDOWN 
	MOV R7,#0			;000
	B INPUT_SET
CHECKDOWN
	CMP R2,#2	;DOWN
	BNE CHECKRIGHT 
	MOV R7,#2			;010
	B INPUT_SET
CHECKRIGHT
	CMP R2,#4	;RIGHT
	BNE CHECKLEFT 
	MOV R7,#1			;001
	B INPUT_SET
CHECKLEFT
	CMP R2,#8	;LEFT
	BNE CHECKNOINPUT
	MOV R7,#3			;011
	B INPUT_SET
CHECKNOINPUT
	MOV R7,#4			;100

INPUT_SET
;NOW WAIT FOR A QUARTER OF A SECOND
delay_loop_INPUT
    SUB R11,R11,#1
	CMP R11,#0
    BLT INPUTFINISH
	CMP R7,#4
	BEQ START
	B delay_loop_INPUT
INPUTFINISH
	POP{R0-R2,R11,R12,LR}
	BX LR


STARTFUNC
WAIT_RESET_START
	BL MOLES_INPUT
	AND R0,R7,#0X4
	CMP R0,#0
	BNE WAIT_RESET_START
	B STARTGAME
; =============================================================	;
; 					WHACKAMOLE DRAW FUNCTIONS                   ;
; =============================================================	;

;R11 Random Reg
;R10 counter 
;R7 input location (first 3 bits) if no input third bit will be 1 
;R6 Score

; ******************************************* ;
; 			Draw Starting Screen 	          ;
; ******************************************* ;
MOLE_DrawStartingScreen
	PUSH{R0-R5, LR}
	
	;Draw Background Color
	MOV R1, #0
	MOV R2, #350
	MOV R3, #0
	MOV R4, #500
	LDR R5,=BACKGROUND
	BL TFT_DrawRect
	
	
	MOV R1, #88
	MOV R2, #0
	LDR R3, =MoleGame ; 154 x 93
	BL TFT_DrawImage
	
	
	; Draw Game Holes
	; Box1
	LDR R1, =Box1X
	LDR R2, =Box1Y
	LDR R3, =EmptyHole
	BL TFT_DrawImage
	; Box2
	LDR R1, =Box2X
	LDR R2, =Box2Y
	LDR R3, =EmptyHole
	BL TFT_DrawImage
	; Box3
	LDR R1, =Box3X
	LDR R2, =Box3Y
	LDR R3, =EmptyHole
	BL TFT_DrawImage
	; Box4
	LDR R1, =Box4X
	LDR R2, =Box4Y
	LDR R3, =EmptyHole
	BL TFT_DrawImage
	; Box5
	
	
	POP{R0-R5, LR}
	BX LR

; ******************************************* ;
; 			 Draw Current Mole 	              ;
; ******************************************* ;
MOLE_DrawCurrentMole
	PUSH{LR}
	
	BL ClearOldMole
	BL DrawNewMole
	
	POP{LR}
	BX LR
	
	
ClearOldMole
	PUSH{R1-R3, LR}
; Draw normal hole in the previous location (R8 first 2 bits)
;R8 prev location (first 2 bits)
;00 --> 1
;01 --> 2
;10 --> 3
;11 --> 4

	LDR R3, =EmptyHole ; Load the image
	
	CMP R8,#0
	BNE SKIP_Box1
	LDR R1, =Box1X
	LDR R2, =Box1Y
	BL TFT_DrawImage
	B SKIP_Box4
	
SKIP_Box1
	CMP R8,#1
	BNE SKIP_Box2
	LDR R1, =Box2X
	LDR R2, =Box2Y
	BL TFT_DrawImage
	B SKIP_Box4
	
SKIP_Box2
	CMP R8,#2
	BNE SKIP_Box3
	LDR R1, =Box3X
	LDR R2, =Box3Y
	BL TFT_DrawImage
	B SKIP_Box4
	
SKIP_Box3
	CMP R8,#3
	BNE SKIP_Box4
	LDR R1, =Box4X
	LDR R2, =Box4Y
	BL TFT_DrawImage
	
SKIP_Box4
	
	POP{R1-R3, LR}
	BX LR

DrawNewMole
	PUSH{R1-R3,LR}
	; Check for new mole location then draw it in the current location (R9 first 2 bits)
	;R9 current location (first 2 bits)
	
	LDR R3, =MoleHole ; Load mole image
	
	CMP R9,#0
	BNE SKIP_NewOne
	LDR R1, =Box1X
	LDR R2, =Box1Y
	BL TFT_DrawImage
	B SKIP_NewFour

SKIP_NewOne
	CMP R9,#1
	BNE SKIP_NewTwo
	LDR R1, =Box2X
	LDR R2, =Box2Y
	BL TFT_DrawImage
	B SKIP_NewFour
	
SKIP_NewTwo
	CMP R9,#2
	BNE SKIP_NewThree
	LDR R1, =Box3X
	LDR R2, =Box3Y
	BL TFT_DrawImage
	B SKIP_NewFour
	
SKIP_NewThree
	CMP R9,#3
	BNE SKIP_NewFour
	LDR R1, =Box4X
	LDR R2, =Box4Y
	BL TFT_DrawImage
	
SKIP_NewFour
	
	POP{R1-R3, LR}	
	BX LR

; ******************************************* ;
; 			 	Draw You Win 	              ;
; ******************************************* ;
MOLE_DrawYouWin
	PUSH{R1-R5, LR}
	;YouWin  97 x 91
	;MoleGame from 88 --> 154 x 93
	;LeftSky from 0 --> 88 x 64
	;RightSky from 242
	
	;1- Clear Mole Game (From X = 88 to X = 242)
	MOV R1, #88
	MOV R2, #242
	MOV R3, #0
	MOV R4, #93
	LDR R5, =BACKGROUND
	BL TFT_DrawRect
	
	;2- Draw You Win
	MOV R1, #116
	MOV R2, #0
	LDR R3, =YouWin
	BL TFT_DrawImage
	
	
	POP{R1-R5, LR}
	BX LR
	
; ******************************************* ;
; 			 	Draw You Lose 	              ;
; ******************************************* ;
MOLE_DrawYouLose
	PUSH{R1-R5, LR}
	;YouLose 96 x 84
	;MoleGame 154 x 93
	
	;1- Clear Mole Game (From X = 88 to X = 242)
	MOV R1, #88
	MOV R2, #242
	MOV R3, #0
	MOV R4, #93
	LDR R5, =BACKGROUND
	BL TFT_DrawRect
	
	;2- Draw You Lose
	MOV R1, #117
	MOV R2, #0
	LDR R3, =YouLose
	BL TFT_DrawImage
	
	POP{R1-R5, LR}
	BX LR
	
; ******************************************* ;
; 			 	Draw Wrong Mole 	          ;
; ******************************************* ;
MOLE_DrawWrongMole
	PUSH{LR}
	
	BL DrawWrongMole
	BL delay
	BL delay
	BL delay
	BL DrawEmptyHole
	
	POP{LR}
	BX LR
	
DrawWrongMole
	PUSH{R0-R3,R7,LR}
	
	MOV R0, #0x3
	AND R7, R7, R0
	
	LDR R3, =WrongHole ; Load mole image
	
	CMP R7,#0
	BNE SKIP_WrongOne
	LDR R1, =Box1X
	LDR R2, =Box1Y
	BL TFT_DrawImage
	B SKIP_WrongFour

SKIP_WrongOne
	CMP R7,#1
	BNE SKIP_WrongTwo
	LDR R1, =Box2X
	LDR R2, =Box2Y
	BL TFT_DrawImage
	B SKIP_WrongFour
	
SKIP_WrongTwo
	CMP R7,#2
	BNE SKIP_WrongThree
	LDR R1, =Box3X
	LDR R2, =Box3Y
	BL TFT_DrawImage
	B SKIP_WrongFour
	
SKIP_WrongThree
	CMP R7,#3
	BNE SKIP_WrongFour
	LDR R1, =Box4X
	LDR R2, =Box4Y
	BL TFT_DrawImage
	
SKIP_WrongFour
	
	POP{R0-R3,R7,LR}
	BX LR
	
DrawEmptyHole
	PUSH{R0-R3, R7, LR}
	
	MOV R0, #0x3
	AND R7, R7, R0

	LDR R3, =EmptyHole ; Load the image
	
	CMP R7,#0
	BNE SKIP_Box12
	LDR R1, =Box1X
	LDR R2, =Box1Y
	BL TFT_DrawImage
	B SKIP_Box42
	
SKIP_Box12
	CMP R7,#1
	BNE SKIP_Box22
	LDR R1, =Box2X
	LDR R2, =Box2Y
	BL TFT_DrawImage
	B SKIP_Box42
	
SKIP_Box22
	CMP R7,#2
	BNE SKIP_Box32
	LDR R1, =Box3X
	LDR R2, =Box3Y
	BL TFT_DrawImage
	B SKIP_Box42
	
SKIP_Box32
	CMP R7,#3
	BNE SKIP_Box42
	LDR R1, =Box4X
	LDR R2, =Box4Y
	BL TFT_DrawImage
	
SKIP_Box42
	
	POP{R0-R3, R7, LR}
	BX LR
	
	b skippool2
	LTORG
skippool2

; ******************************************* ;
; 			 	Draw Hit Mole 	              ;
; ******************************************* ;
MOLE_DrawHitMole
	PUSH{R0-R3,R7,LR}
	
	MOV R0, #0x3
	AND R7, R7, R0
	
	LDR R3, =MoleHit ; Load mole image
	
	CMP R7,#0
	BNE SKIP_HitOne
	LDR R1, =Box1X
	LDR R2, =Box1Y
	BL TFT_DrawImage
	B SKIP_HitFour

SKIP_HitOne
	CMP R7,#1
	BNE SKIP_HitTwo
	LDR R1, =Box2X
	LDR R2, =Box2Y
	BL TFT_DrawImage
	B SKIP_HitFour
	
SKIP_HitTwo
	CMP R7,#2
	BNE SKIP_HitThree
	LDR R1, =Box3X
	LDR R2, =Box3Y
	BL TFT_DrawImage
	B SKIP_HitFour
	
SKIP_HitThree
	CMP R7,#3
	BNE SKIP_HitFour
	LDR R1, =Box4X
	LDR R2, =Box4Y
	BL TFT_DrawImage

SKIP_HitFour
	
	POP{R0-R3,R7,LR}
	BX LR


; ******************************************* ;
; 			 		Draw Score		 	      ;
; ******************************************* ;
MOLE_DrawScore
    PUSH {R1-R4,R5,R6,R7, LR}

    ; Inputs:
    ; R6 = Score (1-12)

    ; Check if score is 0 (nothing to draw)
	MOV R5, #5
	UDIV R7, R6, R5
	MUL R7,R7,R5
	SUBS R7,R6,R7
    BNE EndFunction
	
	UDIV R6,R6,R5
    ; Calculate X position for the latest score
    MOV R1, R6
    SUB R1, R1, #1         ; Convert to 0-based index: R1 = R6 - 1
    MOV R2, #26
    MUL R1, R1, R2         ; R1 = (R6 - 1) * 26
    ADD R1, R1, #7         ; Final X = 7 + (R6 - 1)*26

    ; Set Y position
    MOV R2, #440           ; Y = 440

    ; Set image address
    LDR R3, =MoleScore         ; Image address in R3

    ; Call image drawing function
    BL TFT_DrawImage

EndFunction
    POP {R1-R4,R5,R6,R7, LR}
    BX LR
	b skippool3
	LTORG
skippool3
; ************************************************************* ;
; 						WHACKAMOLE LOGIC 					    ;
; ************************************************************* ;
MOLES_GAMELOGIC
	PUSH {R0-R5,R7,R10,R12,LR}
	
	AND R0,R7,#0X4
	CMP R0,#0
	BNE LOGIC_EXIT
	AND R0,R7,#0X3
	CMP R0,#0        ;;;;;;;;;;;CHECK FOR UP 
	BNE CHECK_RIGHT
	AND R9,R9,#0X3
	CMP R9,R0
	BNE WRONG_TRY
	BL MOLE_DrawHitMole   ;;;;;;;;;;;;;;;;;
	ADD R6,R6,#1
	BL MOLE_DrawScore
	B LOGIC_EXIT
	
CHECK_RIGHT
	AND R0,R7,#0X3
	CMP R0,#1        ;;;;;;;;;;;CHECK FOR RIGHT
	BNE CHECK_DOWN
	AND R9,R9,#0X3
	CMP R9,R0
	BNE WRONG_TRY
	BL MOLE_DrawHitMole   ;;;;;;;;;;;;;;;;;
	ADD R6,R6,#1
	BL MOLE_DrawScore
	B LOGIC_EXIT
CHECK_DOWN
	AND R0,R7,#0X3
	CMP R0,#2        ;;;;;;;;;;;CHECK FOR DOWN
	BNE CHECK_LEFT
	AND R9,R9,#0X3
	CMP R9,R0
	BNE WRONG_TRY
	BL MOLE_DrawHitMole   ;;;;;;;;;;;;;;;;;
	ADD R6,R6,#1
	BL MOLE_DrawScore
	B LOGIC_EXIT
	
CHECK_LEFT
	AND R0,R7,#0X3
	CMP R0,#3        ;;;;;;;;;;;CHECK FOR LEFT
	BNE LOGIC_EXIT
	AND R9,R9,#0X3
	CMP R9,R0
	BNE WRONG_TRY
	BL MOLE_DrawHitMole   ;;;;;;;;;;;;;;;;;
	ADD R6,R6,#1
	BL MOLE_DrawScore
	B LOGIC_EXIT

WRONG_TRY
	BL MOLE_DrawWrongMole

LOGIC_EXIT
	MOV R8,R9
	AND R0,R11,#0X3
	MOV R9,R0
	ROR R11,R11,#1
	LDR R12,=0x726F49C4
	EOR R11,R11,R12
	BL delay_4
	BL MOLE_DrawCurrentMole
	POP {R0-R5,R7,R10,R12,LR}
	BX LR
	
	
CHECK_WIN
	PUSH{R0-R5,R7-R9,R11,LR}
	AND R6,R6,#0X3F
	CMP R6,#30
	BLT MOLE_LOSE 	
	BL MOLE_DrawYouWin
	B CHECK_EXIT      
MOLE_LOSE
	BL MOLE_DrawYouLose
CHECK_EXIT
	MOV R10,#60
	MOV R6,#0
WAIT_RESET
	BL MOLES_INPUT
	AND R0,R7,#0X4
	CMP R0,#0
	BNE WAIT_RESET
	BL MOLE_DrawStartingScreen
	POP {R0-R5,R7-R9,R11,LR}
	BX LR	
	b skippool4
	LTORG
skippool4

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
	
delay_4
    PUSH {R0, LR}
    LDR R0, =DELAY_QUARTER
delay_loop_4
    SUBS R0, R0, #1
    BNE delay_loop_4
    POP {R0, LR}
    BX LR

delay_5
    PUSH {R0, LR}
    LDR R0, =DELAY_HALF
delay_loop_5
    SUBS R0, R0, #1
    BNE delay_loop_5
    POP {R0, LR}
    BX LR

    END