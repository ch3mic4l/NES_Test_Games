HEADER:
	.inesprg 1   ; 1x 16KB bank of PRG code
 	.ineschr 1   ; 1x 8KB bank of CHR data
 	.inesmap 0   ; mapper 0 = NROM, no bank swapping
 	.inesmir 1   ; background mirroring (ignore for now)

	.bank 0
	.org $C000

; Setup Variables
	.rsset $0000
controller1state .rs 1 ; Holds the state of the controller (aka which buttons are pressed)
walking .rs 1
facingleft .rs 0

RESET:
	SEI          ; disable IRQs
    CLD          ; disable decimal mode
    LDX #$40
    STX $4017    ; disable APU frame IRQ
    LDX #$FF
    TXS          ; Set up stack
    INX          ; now X = 0
    STX $2000    ; disable NMI
    STX $2001    ; disable rendering
    STX $4010    ; disable DMC IRQs

WaitForVBlank: 	 ; First wait for vblank to make sure PPU is ready
	BIT $2002
	BPL WaitForVBlank

CLRMem:          ; Clear the RAM
	LDA #$00
	STA $0000, x
	STA $0100, x
	STA $0300, x
	STA $0400, x
	STA $0500, x
	STA $0600, x
	STA $0700, x
	LDA #$FE
	STA $0200, x
	INX
	BNE CLRMem

WaitForVBlank2:  ; Second wait for vblank, PPU is ready after this
	BIT $2002
	BPL WaitForVBlank2

LoadPalettes:
	LDA $2002
	LDA #$3F
	STA $2006
	LDA #$00
	STA $2006
	LDX #$00

LoadPalettesLoop:
	LDA palette, x
	STA $2007
	INX
	CPX #$20
	BNE LoadPalettesLoop

LoadSprites:
	LDX #$00

LoadSpritesLoop:
	LDA sprites, x
	STA $0200, x
	INX
	CPX #$10
	BNE LoadSpritesLoop

LoadBackground:
	LDA $2002
	LDA #$20
	STA $2006
	LDA #$00
	STA $2006
	LDX #$00

; The Background will have to be loaded in 4 sections
LoadBackgroundTop:
	LDA BackgroundTop, x
	STA $2007
	INX
	CPX #$00
	BNE LoadBackgroundTop
	LDX #$00

LoadBackgroundTopMid:
	LDA BackgroundTopMid, x
	STA $2007
	INX
	CPX #$00
	BNE LoadBackgroundTopMid
	LDX #$00

LoadBackgroundBottomMid:
	LDA BackgroundBottomMid, x
	STA $2007
	INX
	CPX #$00
	BNE LoadBackgroundBottomMid
	LDX #$00

LoadBackgroundBottom:
	LDA BackgroundBottom, x
	STA $2007
	INX
	CPX #$C0
	BNE LoadBackgroundBottom

LoadAttribute:
	LDA $2002
	LDA #$23
	STA $2006
	LDA #$C0
	STA $2006
	LDX #$00

LoadAttributeLoop:
	LDA attribute, x
	STA $2007
	INX
	CPX #$40
	BNE LoadAttributeLoop


	LDA #%10010000 ; enable NMI, sprites from Pattern Table 1
	STA $2000

	LDA #%00011110 ; enable sprites
	STA $2001

Forever:
	JMP Forever

;; Subrutines Here, this code is never reached normally
SetStandingRight:
	LDA #$3B
	STA $0209
	LDA #$3C
	STA $020D
	RTS

SetStandingLeft:
	LDA #$3C
	STA $0209
	LDA #$3B
	STA $020D
	RTS

CheckStandingDirection:
	LDA facingleft
	CLC
	CMP #$00 ; 0 means facing right
	BEQ SetStandingRight
	CLC
	CMP #$01 ; 1 means facing left
	BEQ SetStandingLeft


FaceLeft:
	LDA #$3B
	STA $020D ; swap tiles for legs
	LDA #$3C
	STA $0209 ; swap tiles for legs
	LDA #$32
	STA $0205 ; swap tiles for head
	LDA #$33
	STA $0201 ; swap tiles for head
	LDA $0203 ; adjust head x cordinate to line up with the body
	CLC
	ADC #$04
	STA $0203
	CLC
	LDA $0207
	ADC #$04
	STA $0207
	LDA #$41  ; horizontal flip
	STA $020A
	STA $0202
	STA $0206
	STA $020E
	RTS

FaceRight:
	LDA #$3B
	STA $0209 ; Make sure tiles are back into place
	LDA #$3C
	STA $020D ; Make sure tiles are back into place
	LDA #$33
	STA $0205 ; Make sure tiles are back into place
	LDA #$32
	STA $0201 ; Make sure tiles are back into place
	LDA $0203 ; adjust head x cordinate to line up with the body
	SEC
	SBC #$04
	STA $0203
	LDA $0207
	SEC
	SBC #$04
	STA $0207
	LDA #$01 ; Make sure the tiles are not horizontally flipped
	STA $020A
	STA $020E
	STA $0202
	STA $0206
	RTS

CheckStanding:
	LDX controller1state
	CPX #$00
	BEQ CheckStandingDirection
	RTS

WalkingRight:
	LDA #$38
	STA $0209
	LDA #$39
	STA $020D
	RTS

WalkingLeft:
	LDA #$38
	STA $020D
	LDA #$39
	STA $0209
	RTS

;; END SUBRUTINES
NMI:
	LDA #$00
	STA $2003
	LDA #$02
	STA $4014

ReadController:
	LDA #$01
	STA $4016
	LDA #$00
	STA $4016
	LDX #$08

ReadControllerLoop:
	LDA $4016
	LSR A
	ROL controller1state
	DEX
	BNE ReadControllerLoop

ControllerA:
	LDA controller1state
	AND #%10000000
	BEQ ControllerADone ; If A is not pressed, skip ahead

ControllerADone:

ControllerB:
	LDA controller1state
	AND #%01000000
	BEQ ControllerBDone
ControllerBDone:

ControllerReadSelect:
	LDA controller1state
	AND #%00100000
	BEQ ControllerReadSelectDone
ControllerReadSelectDone:

ControllerStart:
	LDA controller1state
	AND #%00010000
	BEQ ControllerStartDone
ControllerStartDone:

ControllerMoveUp:
	LDA controller1state
	AND #%00001000
	BEQ ControllerUpDone
ControllerUpDone:

ControllerMoveDown:
	LDA controller1state
	AND #%00000100
	BEQ ControllerDownDone
ControllerDownDone:

ControllerMoveLeft:
	LDA controller1state
	AND #%00000010
	BEQ ControllerLeftDone
	LDX #$03
MoveLeft:
	LDA facingleft
	CLC
	CMP #$01
	BEQ AlreadyLeft
	JSR FaceLeft
	LDA #$01
	STA facingleft
AlreadyLeft:
	JSR WalkingLeft
	LDA $0200, x
	SEC
	SBC #$02
	STA $0200, x
	STX $0300
	LDY $0300
	INX
	INX
	INX
	INX
	CPY #$0F
	BNE AlreadyLeft
ControllerLeftDone:

ControllerMoveRight:
	LDA controller1state
	AND #%00000001
	BEQ MoveRightDone
	LDX #$03
MoveRight:
	LDA facingleft
	CLC
	CMP #$00
	BEQ AlreadyRight
	JSR FaceRight
	LDA #$00
	STA facingleft
AlreadyRight:
	JSR WalkingRight
	LDA $0200, x
	CLC
	ADC #$02
	STA $0200, x
	STX $0300
	LDY $0300
	INX ; The sprites x location is every 4 bytes
	INX
	INX
	INX
	CPY #$0F ; The sprite is last location in memory is $020F
	BNE AlreadyRight

MoveRightDone:

	
	JSR CheckStanding


PPUCleanUp:
	LDA #%10010000
	STA $2000
	LDA #%00011110
	STA $2001
	LDA #$00 ; tell the ppu there is no background scrolling
	STA $2005
	STA $2005


	RTI


	.bank 1
	.org $E000
palette:
	.db $22,$29,$1A,$0F,  $22,$36,$17,$0F,  $22,$30,$21,$0F,  $22,$27,$17,$0F   ;background palette
    .db $22,$1C,$15,$14,  $0F,$05,$26,$02,  $22,$1C,$15,$14,  $22,$02,$38,$3C   ;sprite palette

sprites:
      ;y pos tile attr x pos
	.db $AF, $32, $01, $14 ; sprite 0
	.db $AF, $33, $01, $1C ; sprite 1
	.db $B7, $3B, $01, $16 ; sprite 2
	.db $B7, $3C, $01, $1E ; sprite 3

BackgroundTop:
    .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
	.db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
	.db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
	.db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
	.db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
	.db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
	.db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
	.db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24

BackgroundTopMid:
    .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
	.db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
	.db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
	.db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
	.db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
	.db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
	.db $24,$24,$24,$24,$53,$54,$24,$24,$24,$24,$24,$24,$45,$45,$53,$54,$45,$45,$53,$54,$45,$45,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
	.db $24,$24,$24,$24,$55,$56,$24,$24,$24,$24,$24,$24,$47,$47,$55,$56,$47,$47,$55,$56,$47,$47,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24

BackgroundBottomMid:
	.db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
	.db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
	.db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
	.db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
	.db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$60,$61,$62,$63,$24,$24
	.db $24,$24,$24,$24,$24,$24,$31,$32,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$64,$65,$66,$67,$24,$24
	.db $24,$24,$24,$24,$24,$30,$26,$34,$33,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$36,$37,$24,$24,$24,$24,$24,$68,$69,$26,$6a,$24,$24
	.db $38,$24,$24,$24,$30,$26,$26,$26,$26,$33,$24,$24,$24,$24,$24,$24,$24,$24,$35,$25,$25,$38,$24,$24,$24,$24,$68,$69,$26,$6a,$24,$24

BackgroundBottom:
    .db $b4,$b5,$b4,$b5,$b4,$b5,$b4,$b5,$b4,$b5,$b4,$b5,$b4,$b5,$b4,$b5,$b4,$b5,$b4,$b5,$b4,$b5,$b4,$b5,$b4,$b5,$b4,$b5,$b4,$b5,$b4,$b5
	.db $b6,$b7,$b6,$b7,$b6,$b7,$b6,$b7,$b6,$b7,$b6,$b7,$b6,$b7,$b6,$b7,$b6,$b7,$b6,$b7,$b6,$b7,$b6,$b7,$b6,$b7,$b6,$b7,$b6,$b7,$b6,$b7
	.db $b4,$b5,$b4,$b5,$b4,$b5,$b4,$b5,$b4,$b5,$b4,$b5,$b4,$b5,$b4,$b5,$b4,$b5,$b4,$b5,$b4,$b5,$b4,$b5,$b4,$b5,$b4,$b5,$b4,$b5,$b4,$b5
	.db $b6,$b7,$b6,$b7,$b6,$b7,$b6,$b7,$b6,$b7,$b6,$b7,$b6,$b7,$b6,$b7,$b6,$b7,$b6,$b7,$b6,$b7,$b6,$b7,$b6,$b7,$b6,$b7,$b6,$b7,$b6,$b7
	.db $b4,$b5,$b4,$b5,$b4,$b5,$b4,$b5,$b4,$b5,$b4,$b5,$b4,$b5,$b4,$b5,$b4,$b5,$b4,$b5,$b4,$b5,$b4,$b5,$b4,$b5,$b4,$b5,$b4,$b5,$b4,$b5
	.db $b6,$b7,$b6,$b7,$b6,$b7,$b6,$b7,$b6,$b7,$b6,$b7,$b6,$b7,$b6,$b7,$b6,$b7,$b6,$b7,$b6,$b7,$b6,$b7,$b6,$b7,$b6,$b7,$b6,$b7,$b6,$b7

attribute:
    .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000 
    .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000 
    .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000 
    .db %00000000, %00110000, %00000000, %11110000, %11110000, %00110000, %00000000, %00000000 
    .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000 
    .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
    .db %11111111, %11111111, %11111111, %11111111, %11111111, %11111111, %11111111, %11111111
    .db %11111111, %11111111, %11111111, %11111111, %11111111, %11111111, %11111111, %11111111     


  	.org $FFFA

	.dw NMI

	.dw RESET

	.dw 0

	.bank 2
	.org $0000
	.incbin "mario.chr"