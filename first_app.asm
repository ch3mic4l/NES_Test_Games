HEADER:
	.inesprg 1   ; 1x 16KB bank of PRG code
 	.ineschr 1   ; 1x 8KB bank of CHR data
 	.inesmap 0   ; mapper 0 = NROM, no bank swapping
 	.inesmir 1   ; background mirroring (ignore for now)

	.bank 0
	.org $C000

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

NMI:
	LDA #$00
	STA $2003
	LDA #$02
	STA $4014

LatchController:
	LDA #$01
	STA $4016
	LDA #$00
	STA $4016

ControllerReadA:
	LDA $4016
	AND #%00000001
	BEQ ControllerReadADone ; If A is not pressed, skip ahead

ControllerReadADone:

ControllerReadB:
	LDA $4016
	AND #%00000001
	BEQ ControllerReadBDone
ControllerReadBDone:

ControllerReadSelect:
	LDA $4016
	AND #%00000001
	BEQ ControllerReadSelectDone
ControllerReadSelectDone:

ControllerReadStart:
	LDA $4016
	AND #%00000001
	BEQ ControllerReadStartDone
ControllerReadStartDone:

ControllerReadUp:
	LDA $4016
	AND #%00000001
	BEQ ControllerReadUpDone
	LDX #$00
MoveCHRUp:
	LDA $0200, x
	SEC
	SBC #$02
	STA $0200, x
	STX $0300
	LDY $0300
	INX ; The sprites y location is every 4 bytes
	INX
	INX
	INX
	CPY #$0C ; The last sprites y pos is stored at memory location $020C
	BNE MoveCHRUp
ControllerReadUpDone:

ControllerReadDown:
	LDA $4016
	AND #%00000001
	BEQ ControllerReadDownDone
	LDX #$00
MoveCHRDown:
	LDA $0200, x
	CLC
	ADC #$02
	STA $0200, x
	STX $0300
	LDY $0300
	INX ; The sprites y location is every 4 bytes
	INX
	INX
	INX
	CPY #$0C ; The last sprites y pos is stored at memory location $020C
	BNE MoveCHRDown
ControllerReadDownDone:

ControllerReadLeft:
	LDA $4016
	AND #%00000001
	BEQ ControllerReadLeftDone
	LDX #$03
MoveCHRLeft:
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
	BNE MoveCHRLeft
ControllerReadLeftDone:

ControllerReadRight:
	LDA $4016
	AND #%00000001
	BEQ ControllerReadRightDone ; If A is not pressed, skip ahead
	; loop to move the sprites as one
	LDX #$03
MoveCHRRight:
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
	BNE MoveCHRRight
ControllerReadRightDone:

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
	.db $80, $32, $01, $80 ; sprite 0
	.db $80, $33, $01, $88 ; sprite 1
	.db $88, $34, $01, $80 ; sprite 2
	.db $88, $35, $01, $88 ; sprite 3

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