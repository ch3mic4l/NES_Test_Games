PPUCleanUp:
	JSR EnableNMI
	JSR EnableSprites
	RTS

WaitForVBlank: 	 ; First wait for vblank to make sure PPU is ready
	BIT $2002
	BPL WaitForVBlank
	RTS

EnableNMI:
	LDA #%10010000 ; enable NMI, sprites from Pattern Table 1
	STA $2000
	RTS
	
EnableSprites:
	LDA #%00011110 ; enable sprites
	STA $2001
	RTS

CleanUpPPURegisters:
	LDA #$00
	STA $2006
	STA $2006
	RTS

HScrollRight:
	INC scroll
	LDA scroll
	STA $2005

	LDA #$00
	STA $2005
	RTS
	