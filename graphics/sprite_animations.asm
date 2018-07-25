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
	LDA $0203 ; adjust head x coordinate to line up with the body
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
	LDA $0203 ; adjust head x coordinate to line up with the body
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