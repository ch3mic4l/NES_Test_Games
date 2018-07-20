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
	STA $0200, x
	STA $0400, x
	STA $0500, x
	STA $0600, x
	STA $0700, x
	LDA #$FE
	STA $0300, x
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
	CPX #$20
	BNE LoadSpritesLoop


	LDA #%10000000 ; enable NMI, sprites from Pattern Table 1
	STA $2000

	LDA #%00010000 ; enable sprites
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



	
	RTI


	.bank 1
	.org $E000
palette:
	.db $0F,$31,$32,$33,$0F,$35,$36,$37,$0F,$39,$3A,$3B,$0F,$3D,$3E,$0F
  	.db $0F,$1C,$15,$14,$0F,$02,$38,$3C,$0F,$1C,$15,$14,$0F,$02,$38,$3C

sprites:
      ;y pos tile attr x pos
	.db $80, $32, $00, $80 ; sprite 0
	.db $80, $33, $00, $88 ; sprite 1
	.db $88, $34, $00, $80 ; sprite 2
	.db $88, $35, $00, $88 ; sprite 3


  	.org $FFFA

	.dw NMI

	.dw RESET

	.dw 0

	.bank 2
	.org $0000
	.incbin "mario.chr"