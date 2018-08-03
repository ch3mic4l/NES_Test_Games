HEADER: ; Used for emulation only
	.inesprg 1   ; 1x 16KB bank of PRG code
 	.ineschr 1   ; 1x 8KB bank of CHR data
 	.inesmap 0   ; mapper 0 = NROM, no bank swapping
 	.inesmir 1   ; background mirroring (ignore for now)

	.bank 0
	.org $C000

	; Load controller library
	.include "library\controllers\controller.asm"

	; Load Graphics libraries

	; Load Sprite libraries
	.include "graphics\load_sprites.asm"
	.include "graphics\sprite_animations.asm"

	; Load Background libraries
	.include "library\backgrounds\load_background.asm"
	.include "library\backgrounds\bg1\bg1.asm"
	.include "library\backgrounds\bg2\bg2.asm"
	.include "library\backgrounds\fillbothtables.asm"

	; Load Color Attributes
	.include "library\backgrounds\load_palletes.asm"

	; Load PPU library
	.include "library\ppu\ppu.asm"

; Setup Variables
	.rsset $0000
controller1state .rs 1 ; Holds the state of the controller (aka which buttons are pressed)
walking .rs 1 ; Is Mario walking? 0 = no, 1 = yes
facingleft .rs 1 ; Which direction is Marion facing? 0 = right 1 = left
scroll .rs 1 ; hosizontal scroll count

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

    JSR WaitForVBlank

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

	JSR WaitForVBlank  ; Second wait for vblank, PPU is ready after this

	JSR LoadPalettes ; Load the color palettes

	JSR LoadSprites ; Load the mario sprites

	JSR PrepPPUForBGLoad ; Prep the PPU to load the first BG(BackGround)

	JSR FillBothTablesLoop ; Load the initial BG

	JSR LoadAttribute ; Apply color to the BG


	JSR EnableNMI 
	JSR EnableSprites

Forever:
	JMP Forever ; Loop here until NMI is triggered

NMI:
	LDA #$00
	STA $2003
	LDA #$02
	STA $4014

	JSR LoadControllerState ; Load the state of the controller into controller1state variable
	JSR ActOnButtonPresses ; Do the action of what button is pressed, right now just moves mario left or right

	JSR CheckStanding ; Check if mario is standing or moving


	JSR PPUCleanUp ; Clean up PPU to draw the next frame


	RTI ; Return back to Forever loop until NMI is triggered again


	.bank 1
	.org $E000

	; Load Graphics Data Libraries

	; Load Background Tile Libraries
	.include "library\backgrounds\bg1\bg1_tiles.asm"
	.include "library\backgrounds\bg2\bg2_tiles.asm"

	; Load Color Libraries
	.include "library\backgrounds\bg1\bg1_color_data.asm"

	; Load Sprite Data Libraries
	.include "graphics\mario_sprite_data.asm"

palette:
	.db $22,$29,$1A,$0F,  $22,$36,$17,$0F,  $22,$30,$21,$0F,  $22,$27,$17,$0F   ;background palette
    .db $22,$1C,$15,$14,  $0F,$05,$26,$02,  $22,$1C,$15,$14,  $22,$02,$38,$3C   ;sprite palette


  	.org $FFFA

	.dw NMI

	.dw RESET

	.dw 0

	.bank 2
	.org $0000
	.incbin "graphics\mario.chr"