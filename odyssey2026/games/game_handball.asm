; ==========================================
; game_handball.asm - Handball (Foosball Edition) V15
; FIX: Aggiunto reset registri VIC-II ($D017, $D01D, $D01C) nel cleanup
;      per evitare la corruzione grafica dei profili paddle nel menu.
; ==========================================
* = $9000

!src "assets/odyssey_charset_map.asm"

; --- Variabili per Winscreen ---
WIN_COL_S   = $98   
WIN_COL_E   = $99   
WIN_COL_ON  = $9A   
WIN_COL_OFF = $9B   

; --- ZP Handball ($28-$41) SAFE ---
HB_SCORE_P1 = $28 : HB_SCORE_P2 = $29
HB_TEMP     = $2A : HB_VARIANT  = $2B
HB_RESTART  = $2C : HB_PAD_H    = $2D
HB_PAD_LIM  = $2E : HB_PAD_MY   = $2F
HB_BALL_XL  = $30 : HB_BALL_XH  = $31
HB_BALL_Y   = $32 : HB_BALL_DX  = $33
HB_BALL_DY  = $34 : HB_HITS     = $35
HB_CUR_SPD  = $36 : HB_START_S  = $37
HB_MAX_S    = $38 : HB_LAST_WIN = $39
HB_RND      = $3A : HB_AI_OFFSET= $3B

; Variabili Deadlock Breaker
HB_CUR_PAD_ID = $3C
HB_LAST_PAD   = $3D
HB_LLAST_PAD  = $3E
HB_DEADLOCK   = $3F

; --- Variabili Tastiera Bare Metal ---
HB_KEY_LOCK = $40
HB_KEY_MAT  = $41

; COSTANTI POSIZIONI BILIARDINO
HB_P1_G_X = 40
HB_P2_F_X = 96
HB_P1_M_X = 152
HB_P2_M_X = 208
HB_P1_F_X = 8    
HB_P2_G_X = 64   

; --- Sprite map Hardware ---
HB_SP0_X=$D000:HB_P1_G_Y=$D001 
HB_SP1_X=$D002:HB_P1_M_Y=$D003 
HB_SP2_X=$D004:HB_P1_F_Y=$D005 
HB_SP3_X=$D006:HB_P2_F_Y=$D007 
HB_SP4_X=$D008:HB_P2_M_Y=$D009 
HB_SP5_X=$D00A:HB_P2_G_Y=$D00B 
HB_SP6_X=$D00C:HB_SP6_Y =$D00D 

HB_MSB_X=$D010 : HB_SPENA=$D015

HB_PTR0=$07F8 : HB_PTR1=$07F9 : HB_PTR2=$07FA 
HB_PTR3=$07FB : HB_PTR4=$07FC : HB_PTR5=$07FD
HB_PTR6=$07FE 

HB_PAD_BLK  = 13
HB_BALL_BLK = 14

HB_SPEED_STEPS = 5

HB_tab_start: !byte 2, 3
HB_tab_max:   !byte 9, 9

; Variabili KERNEL Esplosione
EXP_INIT_XL   = $92
EXP_INIT_XH   = $93
EXP_INIT_Y    = $94
EXP_SFX       = $95
EXP_SPENA_AF  = $96
EXP_PTR4_AF   = $97
EXP_DIR       = $98 

; ==========================================
Handball:
    lda #0 : sta HB_VARIANT : sta HB_KEY_LOCK

HB_restart_trampoline:
    lda #0 : sta HB_SCORE_P1 : sta HB_SCORE_P2 : sta HB_RESTART
    lda #0 : sta HB_LAST_WIN
    lda #42 : sta HB_PAD_H
    lda #63 : sta HB_PAD_LIM
    lda #244 : sec : sbc HB_PAD_H : sta HB_PAD_MY
    lda #0   : sta HB_RND
    
    ldx HB_VARIANT
    lda HB_tab_start,x : sta HB_START_S
    lda HB_tab_max,x   : sta HB_MAX_S
    
    jsr HB_InitGame
    lda HB_RESTART : cmp #1 : beq HB_restart_trampoline
    rts

!zone game_handball {

HB_InitGame:
    ldx #0 : lda #0
.cl_pad: sta $0340,x : inx : cpx #64 : bne .cl_pad
    ldx #0
.dr_pad: lda #%11110000 : sta $0340,x : inx : inx : inx : cpx HB_PAD_LIM : bcc .dr_pad

    ldx #0 : lda #0
.cl_ball: sta $0380,x : inx : cpx #63 : bne .cl_ball
    lda #$FF : sta $0380+0 : sta $0380+3 : sta $0380+6 : sta $0380+9

    lda $D011 : and #$EF : sta $D011
    lda #5 : sta $D021 : sta $D020 : lda #$1E : sta $D018               
    lda #1 : jsr FillColorRAM : jsr ClearScreen 
    lda #0 : sta KBD_COUNT : lda #1 : sta $CC
    lda $D011 : ora #$10 : sta $D011

    jsr HB_draw_boundary : jsr HB_draw_scores : jsr HB_draw_speed_hud

    lda #HB_PAD_BLK 
    sta HB_PTR0 : sta HB_PTR1 : sta HB_PTR2 : sta HB_PTR3 : sta HB_PTR4 : sta HB_PTR5
    lda #HB_BALL_BLK : sta HB_PTR6

    lda #0 : sta $D01C : lda #%01111111 : sta $D017  
    lda #2 : sta $D027 : sta $D028 : sta $D029 : lda #6 : sta $D02A : sta $D02B : sta $D02C 
    lda #1 : sta $D02D : lda #HB_P1_G_X : sta HB_SP0_X : lda #HB_P1_M_X : sta HB_SP1_X  
    lda #HB_P1_F_X : sta HB_SP2_X : lda #HB_P2_F_X : sta HB_SP3_X : lda #HB_P2_M_X : sta HB_SP4_X  
    lda #HB_P2_G_X : sta HB_SP5_X : lda #%00100100 : sta HB_MSB_X : sta $D010 

    lda #129 : sta HB_P1_G_Y : sta HB_P1_M_Y : sta HB_P1_F_Y
               sta HB_P2_G_Y : sta HB_P2_M_Y : sta HB_P2_F_Y

    lda #%01111111 : sta HB_SPENA : sta $D015
    jsr InitSFX : jsr .reset_ball : jsr .countdown
    lda HB_RESTART : beq .start_game
    rts 

.start_game:
    lda #%01111111 : sta HB_SPENA : sta $D015
    jmp .g_loop

.g_loop:
.wt1: lda RASTER : cmp #$F0 : bne .wt1
.wt2: lda RASTER : cmp #$F0 : beq .wt2
    inc HB_RND : jsr HB_paddle_read : jsr .move_ball
    lda HB_RESTART : beq .cont_loop
    rts 
.cont_loop:
    jsr UpdateSFX : lda HB_BALL_XL : sta HB_SP6_X : lda HB_BALL_Y : sta HB_SP6_Y
    lda HB_BALL_XH : beq .msb_clr : lda HB_MSB_X : ora #%01000000 : sta HB_MSB_X : jmp .msb_done
.msb_clr: lda HB_MSB_X : and #%10111111 : sta HB_MSB_X
.msb_done: lda HB_MSB_X : sta $D010 
    
    lda HB_SCORE_P1 : cmp #10 : bcc .np1
    jmp .do_game_over
.np1:
    lda HB_SCORE_P2 : cmp #10 : bcc .np2
    jmp .do_game_over
.np2:

    sei
    lda #$FF : sta $DC02 
    lda #$00 : sta $DC03 
    lda #$FE : sta $DC00 
    lda $DC01 : sta HB_KEY_MAT
    lda #$00 : sta $DC00 
    cli

    lda HB_KEY_MAT
    and #$78
    cmp #$78
    beq .keys_released

    lda HB_KEY_LOCK
    bne .no_key

    lda #1 : sta HB_KEY_LOCK

    lda HB_KEY_MAT : and #$10 : beq .do_res
    lda HB_KEY_MAT : and #$08 : beq .do_ext
    lda HB_KEY_MAT : and #$20 : beq .do_var
    lda HB_KEY_MAT : and #$40 : beq .do_var
    jmp .no_key

.keys_released:
    lda #0 : sta HB_KEY_LOCK
.no_key: 
    jmp .g_loop

.do_res: lda #1 : sta HB_RESTART : rts
.do_var: lda HB_VARIANT : eor #1 : sta HB_VARIANT : lda #1 : sta HB_RESTART : rts
.do_ext: lda #$FF : sta HB_RESTART : jsr .hb_cleanup : rts 

; ==========================================
; PULIZIA E RESTORE KERNAL
; ==========================================
.hb_cleanup:
    ; FIX: Resettiamo anche i modificatori Sprite (D017, D01D, D01C)
    lda #0 : sta HB_SPENA : sta $D010 : sta $D017 : sta $D01D : sta $D01C
    lda $D011 : and #$EF : sta $D011 
    sei
    lda #$FF : sta $DC02   
    lda #$00 : sta $DC03   
    lda #$00 : sta $DC00   
    cli
    lda #0   : sta $C6     
    rts

.do_game_over:
    lda #1 : sta <WIN_COL_ON : lda #5 : sta <WIN_COL_OFF
    lda HB_LAST_WIN : bne .go_p2
    lda #8 : sta <WIN_COL_S : lda #16 : sta <WIN_COL_E : jmp .go_call
.go_p2: lda #25 : sta <WIN_COL_S : lda #33 : sta <WIN_COL_E   
.go_call: jsr DoWinScreen   
    cmp #$85 : beq .go_res : cmp #$87 : beq .go_res : cmp #$86 : beq .go_var
    cmp #$88 : beq .go_ext : jmp .go_res
.go_res: lda #1 : sta HB_RESTART : rts 
.go_var: lda HB_VARIANT : eor #1 : sta HB_VARIANT : lda #1 : sta HB_RESTART : rts 
.go_ext: lda #$FF : sta HB_RESTART : jsr .hb_cleanup : rts

HB_draw_speed_hud:
    lda #$8A : sta SCRN+24*40+19 : lda #1 : sta COLRAM+24*40+19
    lda HB_CUR_SPD : clc : adc #$80 : sta SCRN+24*40+20 : lda #1 : sta COLRAM+24*40+20 : rts

HB_paddle_read:
    lda $02 : sta $08 : lda $03 : sta $09 : sei : lda #%01000000 : sta $DC00 : ldy #$60
.pr_lp: dey : bne .pr_lp
    lda $D419 : sta $02 
    
    lda $033C                  ; Variabile MENU (GLOBAL_PAD_CFG)
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
    lda #$FF : sta $DC02 : lda #$00 : sta $DC00 : cli
    lda $02 : jsr .cl_y : sta HB_P1_G_Y : sta HB_P1_F_Y : jsr .inv_y : sta HB_P1_M_Y                   
    lda HB_VARIANT : beq .human_p2
.ai_p2: lda HB_BALL_Y : sec : sbc HB_AI_OFFSET : bcs + : lda #0         
+   sta HB_TEMP : lda HB_P2_G_Y : cmp HB_TEMP : beq .ai_done : bcc .ai_down
    lda HB_P2_G_Y : sec : sbc HB_TEMP : cmp #6 : bcc .ai_snap : lda HB_P2_G_Y : sec : sbc #6 : jmp .ai_apply 
.ai_down: lda HB_TEMP : sec : sbc HB_P2_G_Y : cmp #6 : bcc .ai_snap : lda HB_P2_G_Y : clc : adc #6 : jmp .ai_apply              
.ai_snap: lda HB_TEMP         
.ai_apply: jsr .cl_y : sta HB_P2_G_Y : sta HB_P2_F_Y : jsr .inv_y : sta HB_P2_M_Y                   
.ai_done: rts
.human_p2: lda $03 : jsr .cl_y : sta HB_P2_G_Y : sta HB_P2_F_Y : jsr .inv_y : sta HB_P2_M_Y : rts
.cl_y: cmp #54 : bcs .cy1 : lda #54    
.cy1: cmp HB_PAD_MY : bcc .cy2 : lda HB_PAD_MY  
.cy2: rts
.inv_y: sta HB_TEMP : lda #54 : clc : adc HB_PAD_MY : sec : sbc HB_TEMP : rts
.roll_ai_target: lda $D012 : and #1 : beq .ai_t_up : lda HB_PAD_H : sec : sbc #4 : sta HB_AI_OFFSET : rts 
.ai_t_up: lda #4 : sta HB_AI_OFFSET : rts   

.move_ball:
    lda HB_BALL_XL : clc : adc HB_BALL_DX : sta HB_BALL_XL
    lda HB_BALL_DX : bmi .neg_dx : lda HB_BALL_XH : adc #0 : sta HB_BALL_XH : jmp .chk_goal_dx
.neg_dx: lda HB_BALL_XH : adc #$FF : sta HB_BALL_XH
.chk_goal_sx: lda HB_BALL_XH : bne .chk_goal_dx : lda HB_BALL_DX : bpl .chk_goal_dx
    lda HB_BALL_XL : cmp #24 : bcs .chk_goal_dx : lda HB_BALL_Y : cmp #106 : bcc .wall_sx : cmp #178 : bcs .wall_sx
    inc HB_SCORE_P2 : lda #1 : sta HB_LAST_WIN : lda #24 : sta EXP_INIT_XL : lda #0 : sta EXP_INIT_XH : jmp .do_goal
.wall_sx: lda #SFX_WALL : jsr PlaySFX : lda HB_BALL_DX : eor #$FF : clc : adc #1 : sta HB_BALL_DX : lda #24 : sta HB_BALL_XL : lda #0 : sta HB_BALL_XH : jmp .move_y
.chk_goal_dx: lda HB_BALL_XH : beq .move_y : lda HB_BALL_DX : bmi .move_y : lda HB_BALL_XL : cmp #80 : bcc .move_y   
    lda HB_BALL_Y : cmp #106 : bcc .wall_dx : cmp #178 : bcs .wall_dx
    inc HB_SCORE_P1 : lda #0 : sta HB_LAST_WIN : lda #80 : sta EXP_INIT_XL : lda #1 : sta EXP_INIT_XH : jmp .do_goal
.wall_dx: lda #SFX_WALL : jsr PlaySFX : lda HB_BALL_DX : eor #$FF : clc : adc #1 : sta HB_BALL_DX : lda #80 : sta HB_BALL_XL : lda #1 : sta HB_BALL_XH
.move_y: lda HB_BALL_Y : clc : adc HB_BALL_DY : sta HB_BALL_Y : cmp #54 : bcs .chk_bot
    lda #SFX_WALL : jsr PlaySFX : lda #2 : sta HB_BALL_DY : lda #54 : sta HB_BALL_Y : rts
.chk_bot: cmp #240 : bcc .mb_done : lda #SFX_WALL : jsr PlaySFX : lda #$FE : sta HB_BALL_DY : lda #240 : sta HB_BALL_Y
.mb_done: jsr .check_paddles : rts

.do_goal: jsr HB_draw_scores : lda HB_SCORE_P1 : cmp #10 : bcs + : lda HB_SCORE_P2 : cmp #10 : bcs +
    lda HB_BALL_Y : sta EXP_INIT_Y : lda #SFX_GOAL : sta EXP_SFX : lda #%01111111 : sta EXP_SPENA_AF   
    lda #HB_PAD_BLK : sta EXP_PTR4_AF : lda HB_LAST_WIN : eor #1 : sta EXP_DIR
    lda #%00001100 : sta HB_SPENA : sta $D015 : jsr DoVectrexExplosion
    lda #HB_PAD_BLK : sta HB_PTR0 : sta HB_PTR1 : sta HB_PTR2 : sta HB_PTR3 : sta HB_PTR4 : sta HB_PTR5
    lda #HB_BALL_BLK : sta HB_PTR6 : lda #%00100100 : sta HB_MSB_X : sta $D010 : lda #%01111111 : sta HB_SPENA : sta $D015 : jsr .reset_ball
+   rts

.reset_ball: lda #0 : sta HB_HITS : sta HB_LAST_PAD : sta HB_LLAST_PAD : sta HB_DEADLOCK
    lda HB_START_S : sta HB_CUR_SPD : lda #146 : sta HB_BALL_Y : lda #1 : sta $D02D 
    jsr .roll_ai_target : lda HB_LAST_WIN : bne .rb_p2 : lda #0 : sta HB_BALL_XH : lda #72 : sta HB_BALL_XL : lda HB_CUR_SPD : sta HB_BALL_DX : jmp .rb_dy
.rb_p2: lda #1 : sta HB_BALL_XH : lda #16 : sta HB_BALL_XL : lda #0 : sec : sbc HB_CUR_SPD : sta HB_BALL_DX
.rb_dy: lda #2 : sta HB_BALL_DY : lda HB_BALL_XL : sta HB_SP6_X : lda HB_BALL_Y : sta HB_SP6_Y
    lda HB_BALL_XH : beq .r_msb_clr : lda HB_MSB_X : ora #%01000000 : sta HB_MSB_X : jmp .r_msb_done
.r_msb_clr: lda HB_MSB_X : and #%10111111 : sta HB_MSB_X
.r_msb_done: lda HB_MSB_X : sta $D010 : jsr HB_draw_speed_hud : rts

.check_paddles: lda HB_BALL_XH : beq .cp_low_x : jmp .cp_high_x
.cp_low_x: lda HB_BALL_DX : bmi .cp_moving_left
.cp_moving_right: lda HB_BALL_XL : cmp #86 : bcc .cpmr_1 : cmp #102 : bcs .cpmr_1
    lda HB_P2_F_Y : jsr .hb_hit_y : bcc .cpmr_1 : lda $09 : sta $FA : lda HB_P2_F_Y : sta HB_TEMP : lda #4 : sta HB_CUR_PAD_ID : jmp .hit_p2_pow
.cpmr_1: lda HB_BALL_XL : cmp #142 : bcc .cpmr_2 : cmp #158 : bcs .cpmr_2
    lda HB_P1_M_Y : jsr .hb_hit_y : bcc .cpmr_2 : lda $08 : sta $FA : lda HB_P1_M_Y : sta HB_TEMP : lda #2 : sta HB_CUR_PAD_ID : jmp .hit_p1_pow
.cpmr_2: lda HB_BALL_XL : cmp #198 : bcc .cpmr_end : cmp #214 : bcs .cpmr_end
    lda HB_P2_M_Y : jsr .hb_hit_y : bcc .cpmr_end : lda $09 : sta $FA : lda HB_P2_M_Y : sta HB_TEMP : lda #5 : sta HB_CUR_PAD_ID : jmp .hit_p2_pow
.cpmr_end: rts
.cp_moving_left: lda HB_BALL_XL : cmp #36 : bcc .cpml_1 : cmp #52 : bcs .cpml_1
    lda HB_P1_G_Y : jsr .hb_hit_y : bcc .cpml_1 : lda $08 : sta $FA : lda HB_P1_G_Y : sta HB_TEMP : lda #1 : sta HB_CUR_PAD_ID : jsr .apply_english_arcade : jsr .inc_spd : lda #(HB_P1_G_X + 8) : sta HB_BALL_XL : jsr .roll_ai_target : jmp .bounce_right
.cpml_1: lda HB_BALL_XL : cmp #92 : bcc .cpml_2 : cmp #108 : bcs .cpml_2
    lda HB_P2_F_Y : jsr .hb_hit_y : bcc .cpml_2 : lda $09 : sta $FA : lda HB_P2_F_Y : sta HB_TEMP : lda #4 : sta HB_CUR_PAD_ID : jmp .hit_p2_pow
.cpml_2: lda HB_BALL_XL : cmp #148 : bcc .cpml_3 : cmp #164 : bcs .cpml_3
    lda HB_P1_M_Y : jsr .hb_hit_y : bcc .cpml_3 : lda $08 : sta $FA : lda HB_P1_M_Y : sta HB_TEMP : lda #2 : sta HB_CUR_PAD_ID : jmp .hit_p1_pow
.cpml_3: lda HB_BALL_XL : cmp #204 : bcc .cpml_end : cmp #220 : bcs .cpml_end
    lda HB_P2_M_Y : jsr .hb_hit_y : bcc .cpml_end : lda $09 : sta $FA : lda HB_P2_M_Y : sta HB_TEMP : lda #5 : sta HB_CUR_PAD_ID : jmp .hit_p2_pow
.cpml_end: rts
.cp_high_x: lda HB_BALL_DX : bmi .cph_moving_left
.cph_moving_right: lda HB_BALL_XL : cmp #14 : bcs .cphr_1 : lda HB_P1_F_Y : jsr .hb_hit_y : bcc .cphr_1 : lda $08 : sta $FA : lda HB_P1_F_Y : sta HB_TEMP : lda #3 : sta HB_CUR_PAD_ID : jmp .hit_p1_pow_msb
.cphr_1: lda HB_BALL_XL : cmp #54 : bcc .cphr_end : cmp #70 : bcs .cphr_end : lda HB_P2_G_Y : jsr .hb_hit_y : bcc .cphr_end : lda $09 : sta $FA : lda HB_P2_G_Y : sta HB_TEMP : lda #6 : sta HB_CUR_PAD_ID : jsr .apply_english_arcade : jsr .inc_spd : lda #(HB_P2_G_X - 8) : sta HB_BALL_XL : jsr .roll_ai_target : jmp .bounce_left
.cphr_end: rts
.cph_moving_left: lda HB_BALL_XL : cmp #4 : bcc .cphl_1 : cmp #20 : bcs .cphl_1 : lda HB_P1_F_Y : jsr .hb_hit_y : bcc .cphl_1 : lda $08 : sta $FA : lda HB_P1_F_Y : sta HB_TEMP : lda #3 : sta HB_CUR_PAD_ID : jmp .hit_p1_pow_msb
.cphl_1: rts
.hit_p1_pow: jsr .apply_english_arcade : jsr .inc_spd : lda HB_BALL_DX : bmi + : lda HB_BALL_XL : clc : adc #12 : sta HB_BALL_XL  
+   lda HB_CUR_SPD : sta HB_BALL_DX : jsr .roll_ai_target : rts
.hit_p1_pow_msb: jsr .apply_english_arcade : jsr .inc_spd : lda HB_BALL_DX : bmi + : lda HB_BALL_XL : clc : adc #12 : sta HB_BALL_XL
+   lda HB_CUR_SPD : sta HB_BALL_DX : jsr .roll_ai_target : rts
.hit_p2_pow: jsr .apply_english_arcade : jsr .inc_spd : lda HB_BALL_DX : bpl + : lda HB_BALL_XL : sec : sbc #12 : sta HB_BALL_XL  
+   lda HB_CUR_SPD : eor #$FF : clc : adc #1 : sta HB_BALL_DX : rts
.bounce_left: lda #0 : sec : sbc HB_CUR_SPD : sta HB_BALL_DX : rts
.bounce_right: lda HB_CUR_SPD : sta HB_BALL_DX : rts
.hb_hit_y: sta $FC : lda HB_BALL_Y : clc : adc #20 : cmp $FC : bcc .ca_no : lda HB_BALL_Y : sec : sbc HB_PAD_H : sec : sbc #4 : cmp $FC : bcs .ca_no : sec : rts
.ca_no: clc : rts

.apply_english_arcade:
    lda HB_CUR_PAD_ID : cmp HB_LAST_PAD : beq .is_deadlock : cmp HB_LLAST_PAD : beq .is_deadlock : lda #0 : sta HB_DEADLOCK : jmp .update_history
.is_deadlock: inc HB_DEADLOCK : lda HB_DEADLOCK : cmp #3 : bcc .update_history : lda #0 : sta HB_DEADLOCK : lda HB_LAST_PAD : sta HB_LLAST_PAD : lda HB_CUR_PAD_ID : sta HB_LAST_PAD : jmp .drastic_angle     
.update_history: lda HB_LAST_PAD : sta HB_LLAST_PAD : lda HB_CUR_PAD_ID : sta HB_LAST_PAD : lda HB_CUR_SPD : sta HB_BALL_DX : lda HB_TEMP : sec : sbc $FA : sta $FC : lda HB_PAD_H : lsr : clc : adc HB_TEMP : sta $FB : lda HB_BALL_Y : clc : adc #10 : cmp $FB : bcs .hit_lower_half
.hit_upper_half: lda $FB : sec : sbc HB_BALL_Y : sec : sbc #10 : cmp #7 : bcc .ang_up : lda HB_CUR_SPD : clc : adc #1 : sta HB_BALL_DX : lda HB_CUR_SPD : lsr : clc : adc #1 : eor #$FF : clc : adc #1 : sta HB_BALL_DY : jmp .apply_inertia
.hit_lower_half: sec : sbc $FB : cmp #7 : bcc .ang_down : lda HB_CUR_SPD : clc : adc #1 : sta HB_BALL_DX : lda HB_CUR_SPD : lsr : clc : adc #1 : sta HB_BALL_DY : jmp .apply_inertia
.ang_up: lda #$FF : sta HB_BALL_DY : jmp .apply_inertia
.ang_down: lda #1 : sta HB_BALL_DY : jmp .apply_inertia
.apply_inertia: lda $FC : beq .done_inertia : bmi .spin_up
.spin_down: lda HB_BALL_DY : clc : adc #1 : beq .done_inertia : sta HB_BALL_DY : jmp .done_inertia
.spin_up: lda HB_BALL_DY : sec : sbc #1 : beq .done_inertia : sta HB_BALL_DY
.done_inertia: rts
.drastic_angle: lda HB_CUR_SPD : clc : adc #1 : sta HB_BALL_DX : lda HB_BALL_Y : cmp #146 : bcc .ang_sharp_down_drastic : lda HB_CUR_SPD : lsr : clc : adc #1 : eor #$FF : clc : adc #1 : sta HB_BALL_DY : rts
.ang_sharp_down_drastic: lda HB_CUR_SPD : lsr : clc : adc #1 : sta HB_BALL_DY : rts

.inc_spd: inc HB_HITS : lda HB_HITS : cmp #HB_SPEED_STEPS : bcc .is_skip : lda #0 : sta HB_HITS
    lda HB_CUR_SPD : cmp HB_MAX_S : bcs .is_skip : clc : adc #1 : sta HB_CUR_SPD : cmp HB_MAX_S : bcc .is_upd : lda #2 : sta $D02D 
.is_upd: jsr HB_draw_speed_hud : lda #SFX_POWERUP : jsr PlaySFX : rts
.is_skip: lda #SFX_PAD : jsr PlaySFX : rts

.countdown:
    lda #1 : jsr $1000 : lda #$0F : sta $D418
    jsr .hb_set_bg : jsr .hb_clr_center
    lda #10 : ldx #12 : ldy #8 : jsr .draw_digit   
    lda #11 : ldx #16 : ldy #8 : jsr .draw_digit   
    lda #12 : ldx #20 : ldy #8 : jsr .draw_digit   
    lda HB_VARIANT : ldx #25 : ldy #8 : jsr .draw_digit
    lda #3 : sta HB_TEMP
.cnt_lp: jsr .hb_clr_count : lda HB_TEMP : ldx #19 : ldy #16 : jsr .draw_digit : jsr .wait_1sec : lda HB_RESTART : bne .cd_exit : dec HB_TEMP : bne .cnt_lp
    jsr .hb_clr_count : lda #14 : ldx #15 : ldy #16 : jsr .draw_digit : lda #0 : ldx #19 : ldy #16 : jsr .draw_digit : lda #15 : ldx #23 : ldy #16 : jsr .draw_digit : jsr .wait_1sec : lda HB_RESTART : bne .cd_exit : jsr .hb_clr_center
.cd_exit: jsr $1003 : lda #0 : ldx #0
.cl_sid_hb: sta $D400,x : inx : cpx #25 : bne .cl_sid_hb
    lda #$0F : sta $D418 : jsr InitSFX : rts

.hb_set_bg: lda #1 : ldx #0   
.hb_sw_lp: sta COLRAM+8*40,x : sta COLRAM+9*40,x : sta COLRAM+10*40,x : sta COLRAM+11*40,x : sta COLRAM+12*40,x : sta COLRAM+13*40,x : sta COLRAM+14*40,x : sta COLRAM+15*40,x : sta COLRAM+16*40,x : sta COLRAM+17*40,x : sta COLRAM+18*40,x : sta COLRAM+19*40,x : sta COLRAM+20*40,x : inx : cpx #40 : bne .hb_sw_lp : rts
.hb_clr_center: lda #32 : ldx #1
.fb_cc1: sta SCRN+8*40,x : sta SCRN+9*40,x : sta SCRN+10*40,x : sta SCRN+11*40,x : sta SCRN+12*40,x : sta SCRN+13*40,x : sta SCRN+14*40,x : sta SCRN+15*40,x : sta SCRN+16*40,x : sta SCRN+17*40,x : sta SCRN+18*40,x : sta SCRN+19*40,x : sta SCRN+20*40,x : inx : cpx #39 : bne .fb_cc1 : rts
.hb_clr_count: lda #32 : ldx #1
.hb_cco: sta SCRN+16*40,x : sta SCRN+17*40,x : sta SCRN+18*40,x : sta SCRN+19*40,x : sta SCRN+20*40,x : inx : cpx #39 : bne .hb_cco : rts

.wait_1sec: lda #50
.hb_wt: pha
.w_r1: lda RASTER : cmp #$F0 : bne .w_r1
.w_r2: lda RASTER : cmp #$F0 : beq .w_r2
    jsr $1006 
    
    sei
    lda #$FF : sta $DC02 
    lda #$00 : sta $DC03 
    lda #$FE : sta $DC00 
    lda $DC01 : sta HB_KEY_MAT
    lda #$00 : sta $DC00 
    cli

    lda HB_KEY_MAT
    and #$78
    cmp #$78
    beq .hb_wt_rel

    lda HB_KEY_LOCK
    bne .hb_nk

    lda #1 : sta HB_KEY_LOCK

    lda HB_KEY_MAT : and #$10 : beq .hb_do_res
    lda HB_KEY_MAT : and #$08 : beq .hb_do_ext
    lda HB_KEY_MAT : and #$20 : beq .hb_do_var
    lda HB_KEY_MAT : and #$40 : beq .hb_do_var
    jmp .hb_nk

.hb_wt_rel:
    lda #0 : sta HB_KEY_LOCK
    jmp .hb_nk

.hb_do_res: lda #1 : sta HB_RESTART : pla : rts
.hb_do_var: lda HB_VARIANT : eor #1 : sta HB_VARIANT : lda #1 : sta HB_RESTART : pla : rts
.hb_do_ext: lda #$FF : sta HB_RESTART : jsr .hb_cleanup : pla : rts 

.hb_nk: pla : sec : sbc #1 : bne .hb_wt : rts

HB_draw_boundary: ldx #38
.drb_lp: lda #BRD_HLINE : sta SCRN+0*40,x : sta SCRN+24*40,x : lda #1 : sta COLRAM+0*40,x : sta COLRAM+24*40,x : dex : bpl .drb_lp
    lda #BRD_TR : sta SCRN+0*40+39 : lda #1 : sta COLRAM+0*40+39 : lda #BRD_BR : sta SCRN+24*40+39 : lda #1 : sta COLRAM+24*40+39 : lda #BRD_BL : sta SCRN+0*40+0 : lda #1 : sta COLRAM+0*40+0 : lda #BRD_TL : sta SCRN+24*40+0 : lda #1 : sta COLRAM+24*40+0
    ldx #1
.bl_lp: cpx #7 : bcc .bl_draw : cpx #17 : bcs .bl_draw : jmp .bl_next             
.bl_draw: lda ROW_TABLE_LO,x : sta $FB : lda ROW_TABLE_HI,x : sta $FC : ldy #0 : lda #BRD_VLINE : sta ($FB),y : ldy #39 : lda #BRD_VLINE : sta ($FB),y : lda $FC : clc : adc #$D4 : sta $FE : lda $FB : sta $FD : ldy #0 : lda #1 : sta ($FD),y : ldy #39 : lda #1 : sta ($FD),y
.bl_next: inx : cpx #24 : bcc .bl_lp : rts

HB_draw_scores: lda HB_SCORE_P1 : jsr .bin_bcd : pha : lda HB_TEMP : ldx #8 : ldy #1 : jsr .draw_digit : pla : ldx #12 : ldy #1 : jsr .draw_digit
    lda HB_SCORE_P2 : jsr .bin_bcd : pha : lda HB_TEMP : ldx #25 : ldy #1 : jsr .draw_digit : pla : ldx #29 : ldy #1 : jsr .draw_digit
    ldx #4
.col_sc: lda #1 : sta COLRAM+1*40+8,x : sta COLRAM+2*40+8,x : sta COLRAM+3*40+8,x : sta COLRAM+4*40+8,x : sta COLRAM+5*40+8,x : sta COLRAM+1*40+12,x : sta COLRAM+2*40+12,x : sta COLRAM+3*40+12,x : sta COLRAM+4*40+12,x : sta COLRAM+5*40+12,x : sta COLRAM+1*40+25,x : sta COLRAM+2*40+25,x : sta COLRAM+3*40+25,x : sta COLRAM+4*40+25,x : sta COLRAM+5*40+25,x : sta COLRAM+1*40+29,x : sta COLRAM+2*40+29,x : sta COLRAM+3*40+29,x : sta COLRAM+4*40+29,x : sta COLRAM+5*40+29,x : dex : bpl .col_sc : rts
.bin_bcd: ldx #0 : stx HB_TEMP
- cmp #10 : bcc + : sbc #10 : inc HB_TEMP : jmp -
+ rts
.draw_digit: sta $FD : lda #0 : sta $FC : sta $FB : tya : beq .add_x
.mul40: clc : lda $FB : adc #40 : sta $FB : bcc .m_ok : inc $FC
.m_ok: dey : bne .mul40
.add_x: txa : clc : adc $FB : sta $FB : bcc .a_ok : inc $FC
.a_ok: clc : lda $FC : adc #$04 : sta $FC : lda $FD : asl : asl : asl : asl : tax : ldy #0
.yl: lda HB_big_num,x : sta ($FB),y : inx : iny : lda HB_big_num,x : sta ($FB),y : inx : iny : lda HB_big_num,x : sta ($FB),y : inx : lda $FB : clc : adc #40 : sta $FB : bcc .y_ok : inc $FC
.y_ok: ldy #0 : txa : and #15 : cmp #15 : bcc .yl : rts

HB_big_num:
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