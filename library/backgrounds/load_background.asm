;start the process to load the background data
PrepPPUForBGLoad:
	LDA $2002
	LDA #$20
	STA $2006
	LDA #$00
	STA $2006
	LDX #$00
	RTS