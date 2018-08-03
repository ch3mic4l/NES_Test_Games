LoadBG2:
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
	CPX #$00
	BNE LoadNewBGBottom
	RTS