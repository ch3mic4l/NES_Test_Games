PPUCleanUp:
	LDA #%10010000
	STA $2000
	LDA #%00011110
	STA $2001
	LDA #$00 ; tell the ppu there is no background scrolling
	STA $2005
	STA $2005
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