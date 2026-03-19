;============================================
; ODYSSEY 2026 - main.asm (THE ULTIMATE MEMORY MAP)
; Assembler: ACME
;============================================
!cpu 6502

; --- Hardware ---
CIA1PA      = $DC00
CIA1DDR     = $DC02
CIA1PB      = $DC01
POTX        = $D419
POTY        = $D41A
RASTER      = $D012
VICBKGD     = $D021
VICBORD     = $D020
VICCR1      = $D011
VICCR2      = $D016
VIC_SPREN   = $D015
SCRN        = $0400
COLRAM      = $D800

; --- Indirizzi moduli ---
LOGO_ADDR    = $2000
MENU_ADDR    = $2800
TENNIS_ADDR  = $4000    
BREAKOUT_ADDR= $5000    
FLIPPER_ADDR = $7000    
HANDBALL_ADDR= $9000    
HOCKEY_ADDR  = $A000    
FOOTBALL_ADDR= $B000    

; --- Zero Page ---
ZP_PTR      = $FB
PRINT_SRC   = $FD
ZP2_PTR     = $60
POT1X       = $02
POT1Y       = $03
POT2X       = $04
POT2Y       = $05
FIRE1X      = $06
FIRE1Y      = $07
FIRE2X      = $08
FIRE2Y      = $09
GAME_ID     = $0A
GAME_VAR    = $0B
GAME_STATE  = $0C
SCORE1_LO   = $0D
SCORE1_HI   = $0E
SCORE2_LO   = $0F
SCORE2_HI   = $10
KEY_PRESSED = $11
FLAG_F1     = $12
FLAG_F3     = $13
FLAG_F5     = $14
FLAG_F7     = $15
RESTART_VEC     = $16
VARIANT_MIN_VAL = $18
VARIANT_MAX_VAL = $19

; --- Keyboard buffer KERNAL ---
KBD_COUNT   = $C6
KBD_BUF     = $0277

;--------------------------------------------
; 1. BASIC Stub: 10 SYS 2061 ($0801)
;--------------------------------------------
* = $0801
!byte $0B,$08,$0A,$00,$9E,$32,$30,$36,$31,$00,$00,$00

;--------------------------------------------
; 2. ENTRY POINT ($080D) - SOLO BOOT
;--------------------------------------------
* = $080D
EntryPoint:
            sei
            jsr $FF81
            lda #1
            sta $CC
            lda #0
            sta KBD_COUNT
            cli
            jmp LOGO_ADDR

;--------------------------------------------
; 3. MUSICA SID ($1000 - $1FFF)
;--------------------------------------------
* = $1000
!bin "assets/fastidio.bin" 

;--------------------------------------------
; 4. LOGO SCREEN ($2000 - $27FF)
;--------------------------------------------
* = $2000
!src "menu/logo_screen.asm"

;--------------------------------------------
; 5. MENU SELECT ($2800 - $2FFF)
;--------------------------------------------
* = $2800
!src "menu/menu_select.asm"

;--------------------------------------------
; 6. ASSETS GRAFICI DEL MENU ($3000 - $3FFF)
;--------------------------------------------
* = $3000
!binary "assets/menu_screen.bin"

* = $3400
!binary "assets/menu_colram.bin"

* = $3800
!binary "assets/odyssey_charset.bin", 2048, 0

;--------------------------------------------
; 7. GIOCHI (Da $4000 in poi)
;--------------------------------------------
* = $4000
!src "games/game_tennis.asm"

* = $5000
!src "games/game_breakout.asm"

* = $7000
!src "games/game_flipper.asm"

* = $9000
!src "games/game_handball.asm"

* = $A000
!src "games/game_hockey.asm"

* = $B000
!src "games/game_football.asm"

;--------------------------------------------
; 8. SHARED KERNEL ROUTINES ($C000)
; Spostate qui per non schiantarsi sulla musica SID!
;--------------------------------------------
* = $C000
!src "kernel/paddle_read.asm"
!src "kernel/input.asm"
!src "kernel/screen.asm"
!src "kernel/sprite.asm"
!src "kernel/sound_fx.asm"
!src "kernel/hud.asm"
!src "kernel/explosion.asm"
!src "kernel/winscreen.asm"
!src "menu/sound_test.asm"