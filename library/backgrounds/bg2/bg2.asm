LoadNewBG:
	BIT $2002
	BPL LoadNewBG
	LDX #$00
	STX $2000    ; disable NMI
    STX $2001    ; disable rendering
    STX $4010    ; disable DMC IRQs
    LDA $2002
	LDA #$20
	STA $2006
	LDA #$00
	STA $2006
	LDX #$00

LoadNewBGTop:
	LDA NewBGTop, x
	STA $2007
	INX
	CPX #$00
	BNE LoadNewBGTop
	LDX #$00

LoadNewBGTopMid:
	LDA NewBGTopMid, x
	STA $2007
	INX
	CPX #$00
	BNE LoadNewBGTopMid
	LDX #$00

LoadNewBGBottomMid:
	LDA NewBGBottomMid, x
	STA $2007
	INX
	CPX #$00
	BNE LoadNewBGBottomMid
	LDX #$00

LoadNewBGBottom:
	LDA NewBGBottom, x
	STA $2007
	INX
	CPX #$C0
	BNE LoadNewBGBottom

	LDA #$15
	STA $0203
	LDA #$1D
	STA $0207
	LDA #$16
	STA $020B
	LDA #$1E
	STA $020F

	LDA #%10010000 ; enable NMI, sprites from Pattern Table 1
	STA $2000

	LDA #%00011110 ; enable sprites
	STA $2001
	RTS