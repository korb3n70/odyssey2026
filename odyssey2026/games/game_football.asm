; ==========================================
; game_football.asm - V37 (Bare Metal Debounce & Warning Fix)
; FIX: Risolto "Target out of range" su .do_game_over (usato JMP).
; FIX: Aggiunto prefisso '<' per forzare Zero Page e rimuovere i warning.
; FIX: Tastiera convertita in Bare Metal ($DC00) con debounce perfetto (maschera $78).
; ==========================================
* = $B000

!src "assets/odyssey_charset_map.asm"

; --- Variabili per Winscreen (Risolve Warning Oversized Addressing) ---
WIN_COL_S   = $98 
WIN_COL_E   = $99 
WIN_COL_ON  = $9A 
WIN_COL_OFF = $9B 

; --- ZP Football ($7C-$92) ---
FB_SCORE_P1 = $7C : FB_SCORE_P2 = $7D
FB_TEMP     = $7E : FB_VARIANT  = $7F
FB_RESTART  = $80 : FB_PAD_H    = $81
FB_PAD_LIM  = $82 : FB_PAD_MY   = $83
FB_MOV_Y    = $84 : FB_MOV_DY   = $85
FB_MOV_TMR  = $86
FB_BALL_XL  = $87 : FB_BALL_XH  = $88
FB_BALL_Y   = $89 : FB_BALL_DX  = $8A
FB_BALL_DY  = $8B
FB_HITS     = $8C : FB_CUR_SPD  = $8D
FB_START_S  = $8E : FB_MAX_S    = $8F
FB_LAST_WIN = $90 : FB_RND      = $91
FB_AI_OFFSET= $92

; --- Variabili Tastiera Bare Metal ---
FB_KEY_LOCK = $7A
FB_KEY_MAT  = $7B

; --- Sprite map Hardware ---
FB_SP1_X=$D000:FB_SP1_Y=$D001 
FB_SP2_X=$D002:FB_SP2_Y=$D003 
FB_SP3_X=$D004:FB_SP3_Y=$D005 
FB_SP4_X=$D006:FB_SP4_Y=$D007 
FB_SP5_X=$D008:FB_SP5_Y=$D009 
FB_SP6_X=$D00A:FB_SP6_Y=$D00B 
FB_SP7_X=$D00C:FB_SP7_Y=$D00D 

FB_MSB_X=$D010 : FB_SPENA=$D015
FB_PTR1=$07F8 : FB_PTR2=$07F9 : FB_PTR3=$07FA : FB_PTR4=$07FB
FB_PTR5=$07FC : FB_PTR6=$07FD : FB_PTR7=$07FE 

FB_PAD_BLK  = 13
FB_MOV_BLK  = 51
FB_BALL_BLK = 14

FB_MATT_STEP = 50
FB_SPEED_STEPS = 5

FB_tab_start: !byte 2, 3
FB_tab_max:   !byte 9, 9

; Variabili KERNEL Esplosione
EXP_INIT_XL   = $92
EXP_INIT_XH   = $93
EXP_INIT_Y    = $94
EXP_SFX       = $95
EXP_SPENA_AF  = $96
EXP_PTR4_AF   = $97
EXP_DIR       = $98 

; ==========================================
Football:
    ; Init KEY_LOCK solo all'ingresso globale
    lda #0 : sta FB_VARIANT : sta FB_KEY_LOCK

FB_restart_trampoline:
    lda #0 : sta FB_SCORE_P1 : sta FB_SCORE_P2 : sta FB_RESTART
    lda #0 : sta FB_LAST_WIN
    lda #42 : sta FB_PAD_H
    lda #63 : sta FB_PAD_LIM
    lda #244 : sec : sbc FB_PAD_H : sta FB_PAD_MY
    lda #74  : sta FB_MOV_Y   
    lda #1   : sta FB_MOV_DY
    lda #0   : sta FB_RND
    
    ldx FB_VARIANT
    lda FB_tab_start,x : sta FB_START_S
    lda FB_tab_max,x   : sta FB_MAX_S
    
    jsr FB_InitGame
    lda FB_RESTART : cmp #1 : beq FB_restart_trampoline
    rts

!zone game_football {

; ==========================================
FB_InitGame:
    ldx #0 : lda #0
.cl_pad: sta $0340,x : inx : cpx #64 : bne .cl_pad
    ldx #0
.dr_pad: lda #%11110000 : sta $0340,x : inx : inx : inx
    cpx FB_PAD_LIM : bcc .dr_pad

    ldx #0 : lda #0
.cl_ball: sta $0380,x : inx : cpx #63 : bne .cl_ball
    lda #$FF : sta $0380+0 : sta $0380+3 : sta $0380+6 : sta $0380+9

    ldx #0
.dr_mov:
    lda #$FF : sta $0CC0,x : inx
    lda #$00 : sta $0CC0,x : inx
    lda #$00 : sta $0CC0,x : inx
    cpx #42 : bcc .dr_mov
    lda #0
.cl_mov: sta $0CC0,x : inx : cpx #64 : bcc .cl_mov

    lda $D011 : and #$EF : sta $D011
    lda #5 : sta $D021 : sta $D020
    lda #$1E : sta $D018               
    lda #5 : jsr FillColorRAM : jsr ClearScreen
    lda #0 : sta KBD_COUNT : lda #1 : sta $CC
    lda $D011 : ora #$10 : sta $D011

    jsr FB_draw_boundary
    jsr FB_draw_scores
    jsr FB_draw_speed_hud

    lda #FB_MOV_BLK  : sta FB_PTR1 : sta FB_PTR2
    lda #FB_PAD_BLK  : sta FB_PTR3 : sta FB_PTR4
    lda #FB_MOV_BLK  : sta FB_PTR5 : sta FB_PTR6
    lda #FB_BALL_BLK : sta FB_PTR7

    lda #0 : sta $D01C
    lda #%00001100 : sta $D017 
    
    lda #7 : sta $D027 : sta $D028   
    lda #1 : sta $D029               
    lda #7 : sta $D02A               
    lda #1 : sta $D02B : sta $D02C   
    lda #1 : sta $D02D               

    lda #40  : sta FB_SP3_X             
    lda #64  : sta FB_SP4_X             
    lda #112 : sta FB_SP5_X : sta FB_SP6_X 
    lda #232 : sta FB_SP1_X : sta FB_SP2_X 
    
    lda #%00001000 : sta FB_MSB_X : sta $D010 

    lda #129 : sta FB_SP3_Y : sta FB_SP4_Y
    lda FB_MOV_Y : sta FB_SP5_Y : sta FB_SP1_Y
    clc : adc #FB_MATT_STEP : sta FB_SP6_Y : sta FB_SP2_Y

    lda #%01001100 : sta FB_SPENA : sta $D015

    jsr InitSFX
    jsr .reset_ball

    jsr .countdown
    lda FB_RESTART : beq .start_game
    rts 

.start_game:
    lda #%01111111 : sta FB_SPENA : sta $D015
    jmp .g_loop

; ==========================================
; GAME LOOP
; ==========================================
.g_loop:
.wt1: lda RASTER : cmp #$F0 : bne .wt1
.wt2: lda RASTER : cmp #$F0 : beq .wt2

    inc FB_RND

    lda FB_MOV_DY : bpl .go_down
    lda FB_MOV_Y : sec : sbc #1 : sta FB_MOV_Y
    cmp #54 : bcs .set_y
    lda #54 : sta FB_MOV_Y : lda #1 : sta FB_MOV_DY : jmp .set_y
.go_down:
    lda FB_MOV_Y : clc : adc #1 : sta FB_MOV_Y
    cmp #185 : bcc .set_y  
    lda #185 : sta FB_MOV_Y
    lda #$FF : sta FB_MOV_DY
.set_y:
    lda FB_MOV_Y : sta FB_SP5_Y : sta FB_SP1_Y
    clc : adc #FB_MATT_STEP : sta FB_SP6_Y : sta FB_SP2_Y

    jsr .move_ball
    
    lda FB_RESTART : beq .cont_loop
    rts 
.cont_loop:

    jsr FB_paddle_read 
    jsr UpdateSFX

    lda FB_BALL_XL : sta FB_SP7_X
    lda FB_BALL_Y  : sta FB_SP7_Y
    lda FB_BALL_XH : beq .msb_clr
    lda FB_MSB_X : ora #%01000000 : sta FB_MSB_X : jmp .ms_d
.msb_clr:
    lda FB_MSB_X : and #%10111111 : sta FB_MSB_X
.ms_d:
    lda FB_MSB_X : sta $D010 

    ; === FIX ERROR OUT OF RANGE ===
    lda FB_SCORE_P1 : cmp #10 : bcc .np1
    jmp .do_game_over
.np1:
    lda FB_SCORE_P2 : cmp #10 : bcc .np2
    jmp .do_game_over
.np2:

    ; ==========================================
    ; TASTIERA BARE METAL CON DEBOUNCE BLINDATO
    ; ==========================================
    sei
    lda #$FF : sta $DC02 
    lda #$00 : sta $DC03 
    lda #$FE : sta $DC00 
    lda $DC01 : sta FB_KEY_MAT
    lda #$00 : sta $DC00 
    cli

    ; Controlla se c'è ALMENO UN tasto F premuto (Maschera $78)
    lda FB_KEY_MAT
    and #$78
    cmp #$78
    beq .keys_released

    ; Tasto premuto. È bloccato?
    lda FB_KEY_LOCK
    bne .no_key

    ; Non è bloccato: blocchiamo e processiamo!
    lda #1 : sta FB_KEY_LOCK

    lda FB_KEY_MAT : and #$10 : beq .do_res_f1
    lda FB_KEY_MAT : and #$08 : beq .do_exit_f7
    lda FB_KEY_MAT : and #$20 : beq .do_f3
    lda FB_KEY_MAT : and #$40 : beq .do_f5
    jmp .no_key

.keys_released:
    lda #0 : sta FB_KEY_LOCK
.no_key:
    jmp .g_loop

.do_res_f1:
    lda #1 : sta FB_RESTART : rts
.do_f3:
.do_f5:
    lda FB_VARIANT : eor #1 : sta FB_VARIANT
    lda #1 : sta FB_RESTART : rts
.do_exit_f7:
    lda #$FF : sta FB_RESTART : jsr .fb_cleanup : rts

; ==========================================
; PULIZIA E RESTORE KERNAL
; ==========================================
.fb_cleanup:
    lda #0 : sta FB_SPENA : sta $D010
    lda $D011 : and #$EF : sta $D011
    
    ; Restore assoluto CIA e Buffer
    sei
    lda #$FF : sta $DC02   
    lda #$00 : sta $DC03   
    lda #$00 : sta $DC00   
    cli
    lda #0   : sta $C6     
    rts

; ==========================================
; WINSCREEN INTEGRATION
; ==========================================
.do_game_over:
    lda #1 : sta <WIN_COL_ON
    lda #5 : sta <WIN_COL_OFF
    lda FB_LAST_WIN : bne .go_p2
    
    lda #8 : sta <WIN_COL_S : lda #16 : sta <WIN_COL_E   
    jmp .go_call
.go_p2:
    lda #25 : sta <WIN_COL_S : lda #33 : sta <WIN_COL_E   
    
.go_call:
    jsr DoWinScreen   
    
    cmp #$85 : bne .go_f5
    lda #1 : sta FB_RESTART : rts
.go_f5: 
    cmp #$86 : bne .go_f7
    lda FB_VARIANT : eor #1 : sta FB_VARIANT
    lda #1 : sta FB_RESTART : rts
.go_f7: 
    cmp #$88 : bne .go_replay
    lda #$FF : sta FB_RESTART : jsr .fb_cleanup : rts 
.go_replay:
    lda #1 : sta FB_RESTART : rts

; ==========================================
; SPEED HUD E DISEGNO GRAFICA
; ==========================================
FB_draw_speed_hud:
    lda #$8A : sta SCRN+24*40+19  
    lda #1   : sta COLRAM+24*40+19
    lda FB_CUR_SPD
    clc : adc #$80                
    sta SCRN+24*40+20
    lda #1   : sta COLRAM+24*40+20
    rts

FB_draw_boundary:
    ldx #38
.drb_lp:
    lda #BRD_HLINE : sta SCRN+0*40,x  : sta SCRN+24*40,x
    lda #1   : sta COLRAM+0*40,x : sta COLRAM+24*40,x
    dex : bpl .drb_lp
    
    lda #BRD_TR : sta SCRN+0*40+39  : lda #1 : sta COLRAM+0*40+39
    lda #BRD_BR : sta SCRN+24*40+39 : lda #1 : sta COLRAM+24*40+39
    lda #BRD_BL : sta SCRN+0*40+0   : lda #1 : sta COLRAM+0*40+0
    lda #BRD_TL : sta SCRN+24*40+0  : lda #1 : sta COLRAM+24*40+0
    
    ldx #1
.bl_lp:
    cpx #7  : bcc .bl_draw   
    cpx #17 : bcs .bl_draw   
    jmp .bl_next             
.bl_draw:
    lda ROW_TABLE_LO,x : sta $FB
    lda ROW_TABLE_HI,x : sta $FC
    ldy #0  : lda #BRD_VLINE : sta ($FB),y
    ldy #39 : lda #BRD_VLINE : sta ($FB),y
    lda $FC : clc : adc #$D4 : sta $FE : lda $FB : sta $FD
    ldy #0  : lda #1 : sta ($FD),y
    ldy #39 : lda #1 : sta ($FD),y
.bl_next:
    inx : cpx #24 : bcc .bl_lp
    rts

FB_draw_scores:
    lda FB_SCORE_P1 : jsr .bin_bcd
    pha : lda FB_TEMP : ldx #8  : ldy #1 : jsr .draw_digit
    pla :               ldx #12 : ldy #1 : jsr .draw_digit
    
    lda FB_SCORE_P2 : jsr .bin_bcd
    pha : lda FB_TEMP : ldx #25 : ldy #1 : jsr .draw_digit
    pla :               ldx #29 : ldy #1 : jsr .draw_digit
    
    ldx #4
.col_sc:
    lda #1
    sta COLRAM+1*40+8,x : sta COLRAM+2*40+8,x : sta COLRAM+3*40+8,x : sta COLRAM+4*40+8,x : sta COLRAM+5*40+8,x
    sta COLRAM+1*40+12,x : sta COLRAM+2*40+12,x : sta COLRAM+3*40+12,x : sta COLRAM+4*40+12,x : sta COLRAM+5*40+12,x
    sta COLRAM+1*40+25,x : sta COLRAM+2*40+25,x : sta COLRAM+3*40+25,x : sta COLRAM+4*40+25,x : sta COLRAM+5*40+25,x
    sta COLRAM+1*40+29,x : sta COLRAM+2*40+29,x : sta COLRAM+3*40+29,x : sta COLRAM+4*40+29,x : sta COLRAM+5*40+29,x
    dex : bpl .col_sc
    rts

.bin_bcd:
    ldx #0 : stx FB_TEMP
.bcd_lp: cmp #10 : bcc .bcd_done : sbc #10 : inc FB_TEMP : jmp .bcd_lp
.bcd_done: rts

; ==========================================
; PADDLE READ E IA WOBBLE 
; ==========================================
FB_paddle_read:
    lda $02 : sta $08 
    lda $03 : sta $09 
    sei : lda #%01000000 : sta $DC00 : ldy #$60
.pr_lp: dey : bne .pr_lp
    lda $D419 : sta $02 
    
    lda $033C                  ; Variabile GLOBAL_PAD_CFG
    bne .read_port2

.read_port1_y:
    lda $D41A : sta $03        
    jmp .pr_end

.read_port2:
    lda #%10000000 : sta $DC00 
    ldy #$C0                   ; FIX JITTER
.pr_lp2: 
    dey : bne .pr_lp2
    lda $D419 : sta $03        

.pr_end:
    lda #$FF : sta $DC02 
    lda #$00 : sta $DC00 
    cli
    
    lda $02 : jsr .cl_y : sta FB_SP3_Y
    
    lda FB_VARIANT : bne .human_p2

.ai_p2:
    lda FB_BALL_Y
    sec : sbc FB_AI_OFFSET
    bcs +
    lda #0         
+   sta FB_TEMP
    
    lda FB_SP4_Y
    cmp FB_TEMP
    beq .ai_done
    bcc .ai_down
.ai_up:
    lda FB_SP4_Y : sec : sbc FB_TEMP
    cmp #6 : bcc .ai_snap   
    lda FB_SP4_Y : sec : sbc #6 : jmp .ai_apply 
.ai_down:
    lda FB_TEMP : sec : sbc FB_SP4_Y
    cmp #6 : bcc .ai_snap   
    lda FB_SP4_Y : clc : adc #6 : jmp .ai_apply              
.ai_snap:
    lda FB_TEMP         
.ai_apply:
    jsr .cl_y : sta FB_SP4_Y
.ai_done:
    rts

.human_p2:
    lda $03 : jsr .cl_y : sta FB_SP4_Y
    rts

.cl_y:
    cmp #54 : bcs .cy1 : lda #54    
.cy1: cmp FB_PAD_MY : bcc .cy2 : lda FB_PAD_MY  
.cy2: rts

.roll_ai_target:
    lda $D012       
    and #$01        
    beq .ai_t_up
.ai_t_down:
    lda FB_PAD_H : sec : sbc #4 : sta FB_AI_OFFSET : rts 
.ai_t_up:
    lda #4 : sta FB_AI_OFFSET : rts   

; ==========================================
; MOVE BALL E LOGICA GOAL
; ==========================================
.move_ball:
    lda FB_BALL_XL : clc : adc FB_BALL_DX : sta FB_BALL_XL
    lda FB_BALL_DX : bmi .neg_dx
    lda FB_BALL_XH : adc #0   : sta FB_BALL_XH : jmp .chk_goal_dx
.neg_dx:
    lda FB_BALL_XH : adc #$FF : sta FB_BALL_XH

.chk_goal_sx:
    lda FB_BALL_XH : bne .chk_goal_dx
    lda FB_BALL_DX : bpl .chk_goal_dx
    lda FB_BALL_XL : cmp #24 : bcs .chk_goal_dx
    
    lda FB_BALL_Y : cmp #106 : bcc .wall_sx
    cmp #186 : bcs .wall_sx
    
    inc FB_SCORE_P2 : lda #1 : sta FB_LAST_WIN
    lda #24 : sta EXP_INIT_XL : lda #0 : sta EXP_INIT_XH
    jmp .do_goal
.wall_sx:
    lda #SFX_WALL : jsr PlaySFX
    lda FB_BALL_DX : eor #$FF : clc : adc #1 : sta FB_BALL_DX
    lda #24 : sta FB_BALL_XL : lda #0 : sta FB_BALL_XH
    jmp .move_y

.chk_goal_dx:
    lda FB_BALL_XH : beq .move_y
    lda FB_BALL_DX : bmi .move_y
    lda FB_BALL_XL : cmp #80 : bcc .move_y   
    
    lda FB_BALL_Y : cmp #106 : bcc .wall_dx
    cmp #186 : bcs .wall_dx
    
    inc FB_SCORE_P1 : lda #0 : sta FB_LAST_WIN
    lda #80 : sta EXP_INIT_XL : lda #1 : sta EXP_INIT_XH
    jmp .do_goal
.wall_dx:
    lda #SFX_WALL : jsr PlaySFX
    lda FB_BALL_DX : eor #$FF : clc : adc #1 : sta FB_BALL_DX
    lda #80 : sta FB_BALL_XL : lda #1 : sta FB_BALL_XH

.move_y:
    lda FB_BALL_Y : clc : adc FB_BALL_DY : sta FB_BALL_Y
    cmp #54 : bcs .chk_bot
    lda #SFX_WALL : jsr PlaySFX
    lda #2   : sta FB_BALL_DY : lda #54 : sta FB_BALL_Y : rts
.chk_bot:
    cmp #240 : bcc .mb_done
    lda #SFX_WALL : jsr PlaySFX
    lda #$FE : sta FB_BALL_DY : lda #240 : sta FB_BALL_Y
.mb_done:
    jsr .check_paddle
    jsr .check_matt
    rts

.do_goal:
    jsr FB_draw_scores
    lda FB_SCORE_P1 : cmp #10 : bcs .go_jmp 
    lda FB_SCORE_P2 : cmp #10 : bcs .go_jmp 
    jmp .do_exp
.go_jmp: 
    rts 

.do_exp:
    lda FB_BALL_Y   : sta EXP_INIT_Y
    lda #SFX_GOAL   : sta EXP_SFX
    lda #%01111111  : sta EXP_SPENA_AF   
    lda #FB_MOV_BLK : sta EXP_PTR4_AF    
    
    lda FB_LAST_WIN : eor #1 : sta EXP_DIR
    
    lda #%00001100 : sta FB_SPENA : sta $D015 
    jsr DoVectrexExplosion
    
    lda #FB_MOV_BLK  : sta FB_PTR5 : sta FB_PTR6
    lda #FB_BALL_BLK : sta FB_PTR7
    lda #%00001000 : sta FB_MSB_X : sta $D010
    lda #%01111111 : sta FB_SPENA : sta $D015
    
    jsr .reset_ball
    rts

; ==========================================
; RESET BALL
; ==========================================
.reset_ball:
    lda #0 : sta FB_HITS
    lda FB_START_S : sta FB_CUR_SPD
    lda #1 : sta $D02D   
    lda #146 : sta FB_BALL_Y
    
    jsr .roll_ai_target

    lda FB_LAST_WIN : bne .rb_p2
    lda #0  : sta FB_BALL_XH
    lda #72 : sta FB_BALL_XL
    lda FB_CUR_SPD : sta FB_BALL_DX
    jmp .rb_dy
.rb_p2:
    lda #1  : sta FB_BALL_XH
    lda #16 : sta FB_BALL_XL 
    lda #0 : sec : sbc FB_CUR_SPD : sta FB_BALL_DX
.rb_dy:
    lda #2 : sta FB_BALL_DY
    
    lda FB_BALL_XL : sta FB_SP7_X
    lda FB_BALL_Y  : sta FB_SP7_Y
    lda FB_BALL_XH : beq .r_msb_clr
    lda FB_MSB_X : ora #%01000000 : sta FB_MSB_X : jmp .r_msb_done
.r_msb_clr:
    lda FB_MSB_X : and #%10111111 : sta FB_MSB_X
.r_msb_done:
    lda FB_MSB_X : sta $D010
    jsr FB_draw_speed_hud
    rts

; ==========================================
; COLLISIONI PADDLE E IA WOBBLE
; ==========================================
.check_paddle:
    lda FB_BALL_XH : bne .cp_p2
    lda FB_BALL_DX : bpl .cp_p2
    
    lda FB_BALL_XL : cmp #32 : bcc .cp_p2 : cmp #54 : bcs .cp_p2
    lda FB_BALL_Y : clc : adc #20 : cmp FB_SP3_Y : bcc .cp_p2
    lda FB_BALL_Y : sec : sbc FB_PAD_H : sec : sbc #4 : cmp FB_SP3_Y : bcs .cp_p2
    
    lda #44 : sta FB_BALL_XL
    lda $08 : sta $FA         
    lda FB_SP3_Y : sta FB_TEMP
    jsr .apply_english_arcade
    jsr .inc_spd
    jsr .roll_ai_target
    lda #SFX_PAD : jsr PlaySFX : rts
    
.cp_p2:
    lda FB_BALL_XH : beq .cp_end
    lda FB_BALL_DX : bmi .cp_end
    
    lda FB_BALL_XL : cmp #52 : bcc .cp_end : cmp #74 : bcs .cp_end 
    lda FB_BALL_Y : clc : adc #20 : cmp FB_SP4_Y : bcc .cp_end
    lda FB_BALL_Y : sec : sbc FB_PAD_H : sec : sbc #4 : cmp FB_SP4_Y : bcs .cp_end
    
    lda #56 : sta FB_BALL_XL
    lda $09 : sta $FA         
    lda FB_SP4_Y : sta FB_TEMP
    jsr .apply_english_arcade
    jsr .inc_spd
    
    lda FB_BALL_DX : eor #$FF : clc : adc #1 : sta FB_BALL_DX
    lda #SFX_PAD : jsr PlaySFX
.cp_end: rts

.apply_english_arcade:
    lda FB_CUR_SPD : sta FB_BALL_DX
    
    lda FB_TEMP       
    sec : sbc $FA 
    sta $FC           
    
    lda FB_PAD_H : lsr : clc : adc FB_TEMP : sta $FB  
    lda FB_BALL_Y : clc : adc #10
    
    cmp $FB 
    bcs .hit_lower_half

.hit_upper_half:
    lda $FB : sec : sbc FB_BALL_Y : sec : sbc #10
    cmp #7 : bcc .ang_up
    jmp .smash_up

.hit_lower_half:
    sec : sbc $FB
    cmp #7 : bcc .ang_down
    jmp .smash_down

.ang_up:
    lda #$FF : sta FB_BALL_DY : jmp .apply_inertia
.ang_down:
    lda #1 : sta FB_BALL_DY : jmp .apply_inertia
    
.smash_up:
    lda FB_CUR_SPD : clc : adc #1 : sta FB_BALL_DX 
    lda FB_CUR_SPD : lsr : clc : adc #1 : eor #$FF : clc : adc #1 : sta FB_BALL_DY
    jmp .apply_inertia

.smash_down:
    lda FB_CUR_SPD : clc : adc #1 : sta FB_BALL_DX 
    lda FB_CUR_SPD : lsr : clc : adc #1 : sta FB_BALL_DY
    
.apply_inertia:
    lda $FC : beq .done_inertia 
    bmi .spin_up
.spin_down:
    lda FB_BALL_DY : clc : adc #1
    beq .done_inertia 
    sta FB_BALL_DY : jmp .done_inertia
.spin_up:
    lda FB_BALL_DY : sec : sbc #1
    beq .done_inertia 
    sta FB_BALL_DY
.done_inertia:
    rts

; ==========================================
; COLLISIONI MATTONCINI MOBILI
; ==========================================
.check_matt:
    lda FB_BALL_XH : beq .cm_do
    rts 
.cm_do:
    lda FB_BALL_DX : bmi .cm_left_moving

.cm_right_moving:
    lda FB_BALL_XL : cmp #210 : bcc .crm_chk_left : cmp #244 : bcs .crm_chk_left
    lda FB_SP1_Y : jsr .cm_hit_y : bcs .hit_right_front
    lda FB_SP2_Y : jsr .cm_hit_y : bcs .hit_right_front
.crm_chk_left:
    lda FB_BALL_XL : cmp #90 : bcc .cm_end : cmp #126 : bcs .cm_end
    lda FB_SP5_Y : jsr .cm_hit_y : bcs .hit_left_back
    lda FB_SP6_Y : jsr .cm_hit_y : bcs .hit_left_back
    rts

.cm_left_moving:
    lda FB_BALL_XL : cmp #90 : bcc .clm_chk_right : cmp #126 : bcs .clm_chk_right
    lda FB_SP5_Y : jsr .cm_hit_y : bcs .hit_left_front
    lda FB_SP6_Y : jsr .cm_hit_y : bcs .hit_left_front
.clm_chk_right:
    lda FB_BALL_XL : cmp #210 : bcc .cm_end : cmp #244 : bcs .cm_end
    lda FB_SP1_Y : jsr .cm_hit_y : bcs .hit_right_back
    lda FB_SP2_Y : jsr .cm_hit_y : bcs .hit_right_back
.cm_end:
    rts

.hit_right_front:
    lda #SFX_WALL : jsr PlaySFX
    lda FB_BALL_DX : eor #$FF : clc : adc #1 : sta FB_BALL_DX
    lda #216 : sta FB_BALL_XL : rts

.hit_left_back:
    lda #SFX_POWERUP : jsr PlaySFX
    lda FB_CUR_SPD : sta FB_BALL_DX : jsr .cm_rand_dy : rts 

.hit_left_front:
    lda #SFX_WALL : jsr PlaySFX
    lda FB_BALL_DX : eor #$FF : clc : adc #1 : sta FB_BALL_DX
    lda #124 : sta FB_BALL_XL : rts

.hit_right_back:
    lda #SFX_POWERUP : jsr PlaySFX
    lda FB_CUR_SPD : eor #$FF : clc : adc #1 : sta FB_BALL_DX : jsr .cm_rand_dy : rts 

.cm_hit_y:
    sta FB_TEMP
    lda FB_BALL_Y : clc : adc #8 : cmp FB_TEMP : bcc .cm_no
    lda FB_TEMP : clc : adc #18  : cmp FB_BALL_Y : bcc .cm_no
    sec : rts
.cm_no: clc : rts

.cm_rand_dy:
    lda RASTER : and #%00000111 : tax
    lda .dy_tab,x : sta FB_BALL_DY
    rts
.dy_tab: !byte $FD,$FE,$FF,$FF,$01,$01,$02,$03

.inc_spd:
    inc FB_HITS : lda FB_HITS : cmp #FB_SPEED_STEPS : bcc .is_skip
    lda #0 : sta FB_HITS
    
    lda FB_CUR_SPD : cmp FB_MAX_S : bcs .is_skip  
    
    clc : adc #1 : sta FB_CUR_SPD                 
    cmp FB_MAX_S : bcc .is_upd                    
    
    lda #2 : sta $D02D                            
.is_upd: 
    jsr FB_draw_speed_hud
.is_skip: 
    rts

; ==========================================
; COUNTDOWN (FANFARA STEP 1) E WAIT CON DEBOUNCE
; ==========================================
.countdown:
    lda #1
    jsr $1000               
    lda #$0F : sta $D418    

    jsr .fb_set_white : jsr .fb_clr_center
    lda #10 : ldx #12 : ldy #8  : jsr .draw_digit   
    lda #11 : ldx #16 : ldy #8  : jsr .draw_digit   
    lda #12 : ldx #20 : ldy #8  : jsr .draw_digit   
    lda FB_VARIANT : ldx #25 : ldy #8 : jsr .draw_digit
    
    lda #3 : sta FB_TEMP
.cnt_lp:
    jsr .fb_clr_count
    lda FB_TEMP : ldx #19 : ldy #16 : jsr .draw_digit
    jsr .wait_1sec
    lda FB_RESTART : bne .cd_exit
    dec FB_TEMP : bne .cnt_lp
    
    jsr .fb_clr_count
    lda #14 : ldx #15 : ldy #16 : jsr .draw_digit
    lda #0  : ldx #19 : ldy #16 : jsr .draw_digit
    lda #15 : ldx #23 : ldy #16 : jsr .draw_digit
    jsr .wait_1sec
    lda FB_RESTART : bne .cd_exit
    jsr .fb_clr_center

.cd_exit:
    jsr $1003               
    
    lda #0 : ldx #0
.cl_sid_fb:
    sta $D400,x
    inx : cpx #25 : bne .cl_sid_fb

    lda #$0F : sta $D418
    jsr InitSFX             
    rts

.fb_set_white:
    lda #1 : ldx #0
.fb_sw_lp:
    sta COLRAM+8*40,x  : sta COLRAM+9*40,x  : sta COLRAM+10*40,x
    sta COLRAM+11*40,x : sta COLRAM+12*40,x
    sta COLRAM+13*40,x : sta COLRAM+14*40,x : sta COLRAM+15*40,x
    sta COLRAM+16*40,x : sta COLRAM+17*40,x : sta COLRAM+18*40,x
    sta COLRAM+19*40,x : sta COLRAM+20*40,x
    inx : cpx #40 : bne .fb_sw_lp : rts

.fb_clr_center:
    lda #32 : ldx #1
.fb_cc1: sta SCRN+8*40,x  : sta SCRN+9*40,x  : sta SCRN+10*40,x
         sta SCRN+11*40,x : sta SCRN+12*40,x
         sta SCRN+13*40,x : sta SCRN+14*40,x : sta SCRN+15*40,x
         sta SCRN+16*40,x : sta SCRN+17*40,x : sta SCRN+18*40,x
         sta SCRN+19*40,x : sta SCRN+20*40,x
    inx : cpx #39 : bne .fb_cc1
    rts

.fb_clr_count:
    lda #32 : ldx #1
.fb_cco: sta SCRN+16*40,x : sta SCRN+17*40,x : sta SCRN+18*40,x
         sta SCRN+19*40,x : sta SCRN+20*40,x
    inx : cpx #39 : bne .fb_cco : rts

.wait_1sec:
    lda #50
.fb_wt: pha

.w_r1: lda RASTER : cmp #$F0 : bne .w_r1
.w_r2: lda RASTER : cmp #$F0 : beq .w_r2

    jsr $1006               

    sei
    lda #$FF : sta $DC02 
    lda #$00 : sta $DC03 
    lda #$FE : sta $DC00 
    lda $DC01 : sta FB_KEY_MAT
    lda #$00 : sta $DC00 
    cli

    lda FB_KEY_MAT
    and #$78
    cmp #$78
    beq .wt_released

    lda FB_KEY_LOCK
    bne .fb_nk

    lda #1 : sta FB_KEY_LOCK

    lda FB_KEY_MAT : and #$10 : beq .fb_do_res
    lda FB_KEY_MAT : and #$08 : beq .fb_do_exit
    lda FB_KEY_MAT : and #$20 : beq .fb_do_var
    lda FB_KEY_MAT : and #$40 : beq .fb_do_var
    jmp .fb_nk

.wt_released:
    lda #0 : sta FB_KEY_LOCK
    jmp .fb_nk

.fb_do_res:
    lda #1 : sta FB_RESTART : pla : rts
.fb_do_var:
    lda FB_VARIANT : eor #1 : sta FB_VARIANT 
    lda #1 : sta FB_RESTART : pla : rts
.fb_do_exit:
    lda #$FF : sta FB_RESTART : jsr .fb_cleanup : pla : rts 

.fb_nk:
    pla : sec : sbc #1 : bne .fb_wt
    rts

.draw_digit:
    sta $FD : lda #0 : sta $FC : sta $FB
    tya : beq .add_x
.mul40: clc : lda $FB : adc #40 : sta $FB : bcc .m_ok : inc $FC
.m_ok:  dey : bne .mul40
.add_x: txa : clc : adc $FB : sta $FB : bcc .a_ok : inc $FC
.a_ok:  clc : lda $FC : adc #$04 : sta $FC
    lda $FD : asl : asl : asl : asl : tax : ldy #0
.yl: lda FB_big_num,x : sta ($FB),y : inx : iny
    lda FB_big_num,x : sta ($FB),y : inx : iny
    lda FB_big_num,x : sta ($FB),y : inx
    lda $FB : clc : adc #40 : sta $FB : bcc .y_ok : inc $FC
.y_ok: ldy #0 : txa : and #$0F : cmp #15 : bcc .yl : rts

FB_big_num:
!byte 127,127,127, 127, 32,127, 127, 32,127, 127, 32,127, 127,127,127, 0
!byte  32,127, 32, 127,127, 32,  32,127, 32,  32,127, 32, 127,127,127, 0
!byte 127,127,127,  32, 32,127, 127,127,127, 127, 32, 32, 127,127,127, 0
!byte 127,127,127,  32, 32,127, 127,127,127,  32, 32,127, 127,127,127, 0
!byte 127, 32,127, 127, 32,127, 127,127,127,  32, 32,127,  32, 32,127, 0
!byte 127,127,127, 127, 32, 32, 127,127,127,  32, 32,127, 127,127,127, 0
!byte 127,127,127, 127, 32, 32, 127,127,127, 127, 32,127, 127,127,127, 0
!byte 127,127,127,  32, 32,127,  32,127, 32,  32,127, 32,  32,127, 32, 0
!byte 127,127,127, 127, 32,127, 127,127,127, 127, 32,127, 127,127,127, 0
!byte 127,127,127, 127, 32,127, 127,127,127,  32, 32,127, 127,127,127, 0
!byte 127, 32,127, 127, 32,127, 127, 32,127, 127, 32,127,  32,127, 32, 0
!byte  32,127, 32, 127, 32,127, 127,127,127, 127, 32,127, 127, 32,127, 0
!byte 127,127, 32, 127, 32,127, 127,127, 32, 127, 32,127, 127, 32,127, 0
!byte  32, 32, 32,  32, 32, 32,  32, 32, 32,  32, 32, 32,  32, 32, 32, 0
!byte  32,127,127, 127, 32, 32, 127, 32,127, 127, 32,127,  32,127,127, 0
!byte  32,127, 32,  32,127, 32,  32,127, 32,  32, 32, 32,  32,127, 32, 0

} ; --- FINE FILE ---