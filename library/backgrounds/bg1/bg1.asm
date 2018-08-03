; The Background will have to be loaded in 4 sections
LoadBG1:
	LDX #$00
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
	RTS

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

LoadAttribute2:
	LDA $2002
	LDA #$27
	STA $2006
	LDA #$C0
	STA $2006
	LDX #$00

LoadAttributeLoop2:
	LDA attribute, x
	STA $2007
	INX
	CPX #$40
	BNE LoadAttributeLoop2
	RTS