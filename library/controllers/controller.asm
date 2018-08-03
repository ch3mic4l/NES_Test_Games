LoadControllerState:
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

ActOnButtonPresses:
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
	LDA facingleft ; checking if mario is already facing left
	CLC
	CMP #$01
	BEQ AlreadyLeft
	JSR FaceLeft ; if mario is not facing left, then flip the sprites to be facing left
	LDA #$01
	STA facingleft ; set the variable to show mario is facing left
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
	JSR FaceRight ; if Mario is facing left, then face him looking right
	LDA #$00
	STA facingleft
AlreadyRight:
	JSR WalkingRight
	LDA $0200, x
	JSR HScrollRight

MoveRightDone:
	RTS