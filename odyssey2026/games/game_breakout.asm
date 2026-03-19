; ==========================================
; game_breakout.asm - V119 (Clean Compile Fix)
; FIX: Aggiunte dichiarazioni WIN_COL_* in cima per risolvere i Warning ACME.
; FIX: Dati di Sprite e Livelli inclusi integralmente per risolvere gli Errori.
; ==========================================
* = $5000

; --- Variabili per Winscreen (Risolve i Warning) ---
WIN_COL_S   = $98   
WIN_COL_E   = $99   
WIN_COL_ON  = $9A   
WIN_COL_OFF = $9B 

; --- PARAMETRI DI GIOCO MODIFICABILI ---
PWR_DURATION    = 15   
BUMPER_COOLDOWN = 5    
BUMPER_LIFESPAN = 7    

BR_RND_TABLE:
    !byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    !byte 1,1,1,1,1,1,1,1,1
    !byte 2,2
    !byte 3
    !byte 4

_X_ = 0   
_R_ = 2   
_O_ = 8   
_Y_ = 7   
_G_ = 5   
_E_ = 15  
_B_ = 6   

BR_SYS_STATE = $4A   
BR_SYS_TIME  = $4B   
BR_SYS_FRAME = $4C   
BR_RND_IDX   = $4D   
BR_WALL_ACT  = $4E   
BR_SUPER_BAL = $4F   
BR_BALL_X_L = $50 : BR_BALL_X_H = $51
BR_BALL_Y   = $52 : BR_BALL_DX  = $53 : BR_BALL_DY = $54
BR_SCORE1_L = $55 : BR_SCORE1_H = $56
BR_SCORE2_L = $57 : BR_SCORE2_H = $58
BR_LIVES_P1 = $59 : BR_LIVES_P2 = $5A
BR_TARGETS_L= $5B 
BR_HITS     = $5C
BR_CUR_SPD  = $5D : BR_VARIANT  = $5E
BR_RESTART  = $5F 
BR_PAD_H    = $60 
BR_PAD_LIM  = $61
BR_START_S  = $62
BR_MAX_S    = $63
BR_PAD_MY   = $64
BR_MOV_Y    = $65 : BR_MOV_DY   = $66
BR_LAST_P   = $67
BR_TEMP     = $68 
BR_ROW      = $69 
BR_COL      = $6A 
BR_TARGETS_H= $6B   
BR_LVL_PTR  = $6C   
BR_CUR_LEVEL= $6E   
BR_SCORE1_E1 = $6F : BR_SCORE1_E2 = $70
BR_SCORE2_E1 = $71 : BR_SCORE2_E2 = $72
BR_RLE_CNT  = $73   
BR_RLE_COL  = $74   
BR_GRID_CD  = $75   
BR_BUMP_TMR = $76   
BR_BUMP_IDX = $77   
BR_KEY_LOCK = $78   
BR_KEY_MAT  = $79   
BR_SFX_TMR  = $7A   

EXP_INIT_XL   = $92
EXP_INIT_XH   = $93
EXP_INIT_Y    = $94
EXP_SFX       = $95
EXP_SPENA_AF  = $96
EXP_PTR4_AF   = $97
EXP_DIR       = $98 

BR_SP2_X = $D004 : BR_SP2_Y = $D005
BR_SP3_X = $D006 : BR_SP3_Y = $D007
BR_SP4_X = $D008 : BR_SP4_Y = $D009
BR_SP5_X = $D00A : BR_SP5_Y = $D00B
BR_SP6_X = $D00C : BR_SP6_Y = $D00D
BR_SP7_X = $D00E : BR_SP7_Y = $D00F
BR_MSB_X = $D010 : BR_SPENA = $D015
BR_PTR2  = $07FA : BR_PTR3  = $07FB : BR_PTR4 = $07FC : BR_PTR5 = $07FD
BR_PTR6  = $07FE : BR_PTR7  = $07FF

BR_PAD_BLK  = 13
BR_BALL_BLK = 14
BR_PAD_W    = %11110000

BR_INITIAL_LIVES = 5  
BR_SPEED_STEPS   = 5    

Breakout:
    lda #0 : sta BR_VARIANT : sta BR_KEY_LOCK

BR_restart_trampoline:
    lda #0 : sta BR_SCORE1_L : sta BR_SCORE1_H : sta BR_SCORE1_E1 : sta BR_SCORE1_E2
    sta BR_SCORE2_L : sta BR_SCORE2_H : sta BR_SCORE2_E1 : sta BR_SCORE2_E2
    sta BR_RESTART : sta BR_SUPER_BAL : sta BR_WALL_ACT 
    lda #BR_INITIAL_LIVES : sta BR_LIVES_P1 : sta BR_LIVES_P2
    lda #150 : sta BR_MOV_Y : lda #1 : sta BR_MOV_DY
    lda #1   : sta BR_CUR_LEVEL

    jsr BR_InitGame
    lda BR_RESTART : cmp #1 : beq BR_restart_trampoline
BR_end_breakout:
    rts

!zone game_breakout {
BR_InitGame:
    lda #0 : sta BR_SFX_TMR

    lda #<SPRITE_DATA : sta ZP_PTR
    lda #>SPRITE_DATA : sta ZP_PTR+1
    lda #$80 : sta PRINT_SRC     
    lda #$2C : sta PRINT_SRC+1  
    ldx #0 : ldy #0
.cp_sp_lp: 
    lda (ZP_PTR),y : sta (PRINT_SRC),y
    iny : bne .cp_sp_lp
    inc ZP_PTR+1 : inc PRINT_SRC+1
    inx : cpx #2 : bne .cp_sp_lp  

    lda #28 : sta BR_PAD_H : lda #42 : sta BR_PAD_LIM
    lda #2  : sta BR_START_S : sta BR_CUR_SPD
    lda #9  : sta BR_MAX_S   
    lda #242 : sec : sbc BR_PAD_H : sta BR_PAD_MY

    lda #$1E : sta $D018

    jsr .draw_paddle

    ldx #0 : lda #0
.cl_ball: sta $0380,x : inx : cpx #63 : bne .cl_ball
    lda #$FF : sta $0380 : sta $0383 : sta $0386 : sta $0389

    lda $D011 : and #$EF : sta $D011
    lda #14 : sta $D021 : sta $D020
    lda #14 : jsr FillColorRAM : jsr ClearScreen

    jsr BR_draw_boundary
    jsr BR_draw_scores
    jsr BR_draw_level
    jsr BR_update_lives
    jsr BR_draw_speed_hud

    lda #BR_PAD_BLK  : sta BR_PTR2 : sta BR_PTR3
    lda #BR_BALL_BLK : sta BR_PTR4

    lda #1 : sta BR_SYS_STATE
    lda #3 : sta BR_SYS_TIME
    lda #50 : sta BR_SYS_FRAME
    jsr .hide_bumper

    lda #7 : sta $D029 : lda #3 : sta $D02A : lda #1 : sta $D02B

    lda BR_VARIANT : beq .init_sp_1
    lda #84 : sta BR_SP3_X : lda #146 : sta BR_SP3_Y
    lda BR_MSB_X : ora #%00001000 : sta BR_MSB_X
    lda #%00111100 : jmp .init_sp_s   
.init_sp_1:
    lda BR_MSB_X : and #%11110111 : sta BR_MSB_X
    lda #%00110100                     
.init_sp_s:
    sta BR_SPENA

    lda #%00001100 : sta $D017
    lda #0 : sta $D01D : sta $D01C 
    lda #1 : sta $CC
    lda $D011 : ora #$10 : sta $D011

    jsr BR_countdown
    lda BR_RESTART : beq .no_brk_pre
    rts 
.no_brk_pre:
    lda BR_VARIANT : beq .ply_sp_1
    lda #%00111100 : jmp .ply_sp_s
.ply_sp_1:
    lda #%00110100
.ply_sp_s:
    sta BR_SPENA

    jsr BR_gen_grid
    jsr .reset_ball

.g_loop:
.wt_rst1: lda RASTER : cmp #$F0 : bne .wt_rst1
.wt_rst2: lda RASTER : cmp #$F0 : beq .wt_rst2

    lda BR_SFX_TMR
    beq .skip_sfx
    dec BR_SFX_TMR
    bne .skip_sfx
    jsr BR_kill_sfx
.skip_sfx:

    inc BR_RND_IDX 

    jsr .handle_timer
    jsr .paddle_read
    jsr .move_bumper
    jsr .move_ball
    jsr .check_paddle_col
    jsr .check_bumper_col

    lda BR_GRID_CD
    beq .do_grid
    dec BR_GRID_CD
    jmp .skip_grid
.do_grid:
    jsr .check_grid_col
.skip_grid:

    lda BR_BALL_X_L : sta BR_SP4_X : lda BR_BALL_Y : sta BR_SP4_Y
    lda BR_MSB_X : and #%11101111 : ldx BR_BALL_X_H : beq .upd_msb : ora #%00010000
.upd_msb: sta BR_MSB_X

    sei
    lda #$FF : sta $DC02 
    lda #$00 : sta $DC03 
    lda #$FE : sta $DC00 
    lda $DC01 : sta BR_KEY_MAT
    lda #$00 : sta $DC00 
    cli

    lda BR_KEY_MAT
    and #$78
    cmp #$78
    beq .keys_released

    lda BR_KEY_LOCK
    bne .chk_win

    lda #1 : sta BR_KEY_LOCK

    lda BR_KEY_MAT : and #$10 : beq .do_res_f1
    lda BR_KEY_MAT : and #$08 : beq .do_exit_f7
    lda BR_KEY_MAT : and #$20 : beq .do_f3
    lda BR_KEY_MAT : and #$40 : beq .do_f5
    jmp .chk_win

.keys_released:
    lda #0 : sta BR_KEY_LOCK
    jmp .chk_win

.do_f3:
    inc BR_VARIANT : lda BR_VARIANT : cmp #3 : bcc .do_res_f1
    lda #0 : sta BR_VARIANT : jmp .do_res_f1

.do_f5:
    dec BR_VARIANT : bpl .do_res_f1
    lda #2 : sta BR_VARIANT : jmp .do_res_f1

.do_res_f1:
    lda #1 : sta BR_RESTART : rts

.do_exit_f7:
    lda #$FF : sta BR_RESTART : jsr .br_cleanup : rts

.chk_win:
    lda BR_TARGETS_L : ora BR_TARGETS_H : bne .chk_lives
    inc BR_CUR_LEVEL         
    jsr BR_draw_level        
    lda #0 : sta BR_SPENA    
    
    jsr BR_countdown
    
    lda BR_RESTART : bne .gl_abort 
    lda BR_VARIANT : beq .r_sp_1p
    lda #%00111100 : jmp .r_sp_set
.r_sp_1p: lda #%00110100
.r_sp_set: sta BR_SPENA      
    jsr BR_gen_grid          
    jsr .reset_ball          
    jmp .g_loop              

.gl_abort: rts

.chk_lives:
    lda BR_LIVES_P1 : bne .cl_p1_ok
    jmp .do_game_over
.cl_p1_ok:
    lda BR_VARIANT : bne .chk_lives_p2
    jmp .g_loop
.chk_lives_p2:
    lda BR_LIVES_P2 : bne .cl_p2_ok
    jmp .do_game_over
.cl_p2_ok:
    jmp .g_loop

.handle_timer:
    dec BR_SYS_FRAME
    beq .ht_tick
    rts
.ht_tick:
    lda #50 : sta BR_SYS_FRAME
    dec BR_SYS_TIME
    
    lda BR_SYS_TIME
    beq .ht_transition
    rts
    
.ht_transition:
    lda BR_SYS_STATE
    cmp #0 : beq .from_visible
    cmp #1 : beq .from_cooldown
    jmp .from_powerup         
    
.from_visible:
    lda #1 : sta BR_SYS_STATE
    lda #BUMPER_COOLDOWN : sta BR_SYS_TIME
    jsr .hide_bumper
    rts
    
.from_cooldown:
    lda #0 : sta BR_SYS_STATE
    lda #BUMPER_LIFESPAN : sta BR_SYS_TIME
    jsr .spawn_bumper
    rts
    
.from_powerup:
    jsr .revert_powerups
    lda #1 : sta BR_SYS_STATE
    lda #BUMPER_COOLDOWN : sta BR_SYS_TIME
    jsr .hide_bumper
    rts

.spawn_bumper:
    lda BR_RND_IDX : and #$1F : tax    
    lda BR_RND_TABLE,x : sta BR_BUMP_IDX
    tax
    lda BR_bump_colors,x : sta $D02C
    lda BR_bump_sprites,x : sta BR_PTR5
    lda #150 : sta BR_MOV_Y 
    rts

.hide_bumper:
    lda #0 : sta BR_SP5_X : sta BR_SP5_Y : rts

.revert_powerups:
    lda #28 : sta BR_PAD_H : lda #42 : sta BR_PAD_LIM
    lda #242 : sec : sbc BR_PAD_H : sta BR_PAD_MY
    jsr .draw_paddle
    lda #0 : sta BR_WALL_ACT
    jsr .clear_safety_wall
    lda #0 : sta BR_SUPER_BAL
    lda BR_CUR_SPD : cmp BR_MAX_S : bcs +
    lda #1 : sta $D02B 
+   rts

.br_cleanup:
    lda #0 : sta BR_SPENA : sta $D010
    lda $D011 : and #$EF : sta $D011
    sei
    lda #$FF : sta $DC02   
    lda #$00 : sta $DC03   
    lda #$00 : sta $DC00   
    cli
    lda #0   : sta $C6     
    rts

.do_game_over:
    lda #1  : sta WIN_COL_ON : lda #14 : sta WIN_COL_OFF
    lda BR_VARIANT : beq .go_1p
    lda BR_LIVES_P1 : beq .go_blink_p2
    
    lda #2  : sta WIN_COL_S : lda #19 : sta WIN_COL_E   
    jmp .go_call
    
.go_blink_p2:
    lda #22 : sta WIN_COL_S : lda #38 : sta WIN_COL_E   
    jmp .go_call
    
.go_1p:
    lda #22 : sta WIN_COL_S : lda #38 : sta WIN_COL_E   
    
.go_call:
    jsr DoWinScreen   
    
    cmp #$85 : bne .go_f3
    lda #1 : sta BR_RESTART : rts
.go_f3: cmp #$86 : bne .go_f5
    dec BR_VARIANT : bpl .gof3_ok
    lda #2 : sta BR_VARIANT
.gof3_ok: lda #1 : sta BR_RESTART : rts
.go_f5: cmp #$87 : bne .go_f7
    inc BR_VARIANT : lda BR_VARIANT : cmp #3 : bcc .gof5_ok
    lda #0 : sta BR_VARIANT
.gof5_ok: lda #1 : sta BR_RESTART : rts
.go_f7: cmp #$88 : bne .go_replay
    lda #$FF : sta BR_RESTART : jsr .br_cleanup : rts
.go_replay:
    lda #1 : sta BR_RESTART : rts

BR_draw_level:
    lda BR_CUR_LEVEL : ldx #0
.lvl_100: cmp #100 : bcc .lvl_10
    sbc #100 : inx : jmp .lvl_100
.lvl_10: pha : txa : clc : adc #$80 : sta SCRN+59 : lda #1 : sta COLRAM+59
    pla : ldx #0
.lvl_10_loop: cmp #10 : bcc .lvl_1
    sbc #10 : inx : jmp .lvl_10_loop
.lvl_1: pha : txa : clc : adc #$80 : sta SCRN+60 : lda #1 : sta COLRAM+60
    pla : clc : adc #$80 : sta SCRN+61 : lda #1 : sta COLRAM+61 : rts

BR_draw_speed_hud:
    lda #$8A : sta SCRN+24*40+19  
    lda #1   : sta COLRAM+24*40+19
    lda BR_CUR_SPD : clc : adc #$80 : sta SCRN+24*40+20
    lda #1   : sta COLRAM+24*40+20 : rts

.draw_paddle:
    ldx #0 : lda #0
.cl_sp_d: sta $0340,x : inx : cpx #64 : bne .cl_sp_d
    ldx #0
.dr_pad_d: lda #BR_PAD_W : sta $0340,x : inx : inx : inx : cpx BR_PAD_LIM : bcc .dr_pad_d
    rts

BR_countdown:
    lda #1
    jsr $1000               
    lda #$0F : sta $D418    

    lda #1 : ldx #1
.cc_lp:
    sta COLRAM+10*40,x : sta COLRAM+11*40,x : sta COLRAM+12*40,x
    sta COLRAM+13*40,x : sta COLRAM+14*40,x
    sta COLRAM+18*40,x : sta COLRAM+19*40,x : sta COLRAM+20*40,x
    sta COLRAM+21*40,x : sta COLRAM+22*40,x
    inx : cpx #39 : bne .cc_lp

    lda #10 : ldx #12 : ldy #10 : jsr .draw_digit
    lda #11 : ldx #16 : ldy #10 : jsr .draw_digit
    lda #12 : ldx #20 : ldy #10 : jsr .draw_digit
    lda BR_VARIANT : ldx #25 : ldy #10 : jsr .draw_digit

    lda #3 : sta BR_TEMP
.cnt_lp:
    jsr .clr_count
    lda BR_TEMP : ldx #19 : ldy #18 : jsr .draw_digit
    jsr .wait_1sec
    lda BR_RESTART : bne .cd_exit 
    dec BR_TEMP : bne .cnt_lp

    jsr .clr_count
    lda #14 : ldx #15 : ldy #18 : jsr .draw_digit
    lda #0  : ldx #19 : ldy #18 : jsr .draw_digit
    lda #15 : ldx #23 : ldy #18 : jsr .draw_digit
    jsr .wait_1sec
    lda BR_RESTART : bne .cd_exit
    jsr .clr_text
.cd_exit:
    jsr $1003               
    
    lda #0 : ldx #0
.cl_sid_brk:
    sta $D400,x
    inx : cpx #25 : bne .cl_sid_brk
    lda #$0F : sta $D418    
    rts

.clr_text:
    lda #32 : ldx #1
.ct_lp1:
    sta SCRN+10*40,x : sta SCRN+11*40,x : sta SCRN+12*40,x
    sta SCRN+13*40,x : sta SCRN+14*40,x
    sta SCRN+18*40,x : sta SCRN+19*40,x : sta SCRN+20*40,x
    sta SCRN+21*40,x : sta SCRN+22*40,x
    inx : cpx #39 : bne .ct_lp1
    lda #14 : ldx #1
.ct_lp2:
    sta COLRAM+10*40,x : sta COLRAM+11*40,x : sta COLRAM+12*40,x
    sta COLRAM+13*40,x : sta COLRAM+14*40,x
    sta COLRAM+18*40,x : sta COLRAM+19*40,x : sta COLRAM+20*40,x
    sta COLRAM+21*40,x : sta COLRAM+22*40,x
    inx : cpx #39 : bne .ct_lp2
    rts

.clr_count:
    lda #32 : ldx #1
.ccnt_lp:
    sta SCRN+18*40,x : sta SCRN+19*40,x : sta SCRN+20*40,x
    sta SCRN+21*40,x : sta SCRN+22*40,x
    inx : cpx #39 : bne .ccnt_lp : rts

.wait_1sec:
    lda #50
.wt_frame: 
    pha
.w_r1: lda RASTER : cmp #$F0 : bne .w_r1
.w_r2: lda RASTER : cmp #$F0 : beq .w_r2

    jsr $1006               
    
    sei
    lda #$FF : sta $DC02 
    lda #$00 : sta $DC03 
    lda #$FE : sta $DC00 
    lda $DC01 : sta BR_KEY_MAT
    lda #$00 : sta $DC00 
    cli
    
    lda BR_KEY_MAT
    and #$78
    cmp #$78
    beq .wt_released

    lda BR_KEY_LOCK
    bne .wt_next

    lda #1 : sta BR_KEY_LOCK

    lda BR_KEY_MAT : and #$10 : beq .wda       
    lda BR_KEY_MAT : and #$08 : beq .w_f7      
    lda BR_KEY_MAT : and #$20 : beq .w_f3      
    lda BR_KEY_MAT : and #$40 : beq .w_f5      
    jmp .wt_next

.wt_released:
    lda #0 : sta BR_KEY_LOCK
    jmp .wt_next

.w_f3:
    inc BR_VARIANT : lda BR_VARIANT : cmp #3 : bcc .wda : lda #0 : sta BR_VARIANT : jmp .wda

.w_f5:
    dec BR_VARIANT : bpl .wda : lda #2 : sta BR_VARIANT : jmp .wda

.w_f7:
    lda #$FF : sta BR_RESTART : jsr .br_cleanup : pla : rts                               

.wda: 
    lda #1 : sta BR_RESTART : pla : rts                        

.wt_next:
    pla 
    sec : sbc #1 : beq .wt_done
    jmp .wt_frame
.wt_done:
    rts

BR_update_lives:
    lda BR_LIVES_P1 
    cmp #11 
    bcc .set_temp1 
    lda #10 
.set_temp1: 
    sta BR_TEMP
    ldx #1
.ul_p1:
    txa 
    cmp BR_TEMP 
    beq .w1_s 
    bcc .w1_s
    lda #$40 
    jmp .s1
.w1_s: 
    lda #$53
.s1: 
    sta SCRN+24*40,x
    inx 
    cpx #11 
    bcc .ul_p1
    lda BR_VARIANT 
    bne .do_p2_lives 
    rts 
.do_p2_lives:
    lda BR_LIVES_P2 
    cmp #11 
    bcc .set_temp2 
    lda #10 
.set_temp2: 
    sta BR_TEMP
    ldx #38 
    ldy #1
.ul_p2:
    tya 
    cmp BR_TEMP 
    beq .w2_s 
    bcc .w2_s
    lda #$40 
    jmp .s2
.w2_s: 
    lda #$53
.s2: 
    sta SCRN+24*40,x
    iny 
    dex 
    cpx #28 
    bne .ul_p2
    rts

BR_draw_boundary:
    ldx #38
.drb_lp:
    lda #$40 : sta SCRN+0*40,x  : sta SCRN+24*40,x
    lda #1   : sta COLRAM+0*40,x : sta COLRAM+24*40,x
    dex : bpl .drb_lp
    lda BR_VARIANT : bne .right_wall_2p
    ldx #1
.drc_lp:
    lda ROW_TABLE_LO,x : clc : adc #39 : sta ZP_PTR
    lda ROW_TABLE_HI,x : adc #0 : sta ZP_PTR+1
    ldy #0 : lda #$5D : sta (ZP_PTR),y
    lda ZP_PTR+1 : clc : adc #$D4 : sta PRINT_SRC+1 : lda ZP_PTR : sta PRINT_SRC
    lda #1 : sta (PRINT_SRC),y
    inx : cpx #24 : bcc .drc_lp
    lda #$6E : sta SCRN+0*40+39 : lda #1 : sta COLRAM+0*40+39
    lda #$7D : sta SCRN+24*40+39 : lda #1 : sta COLRAM+24*40+39
    rts
.right_wall_2p:
    lda #$40 : sta SCRN+0*40+39 : sta SCRN+24*40+39
    lda #1 : sta COLRAM+0*40+39 : sta COLRAM+24*40+39
    rts

BR_draw_scores:
    lda BR_VARIANT : bne .ds_2p
    lda BR_SCORE1_H : lsr : lsr : lsr : lsr : ldx #24 : ldy #1 : jsr .draw_digit
    lda BR_SCORE1_H : and #$0F : ldx #28 : ldy #1 : jsr .draw_digit
    lda BR_SCORE1_L : lsr : lsr : lsr : lsr : ldx #32 : ldy #1 : jsr .draw_digit
    lda BR_SCORE1_L : and #$0F : ldx #36 : ldy #1 : jsr .draw_digit
    ldx BR_SCORE1_E1 : lda BR_SCORE1_E2 : ldy #221 
    jsr .draw_prog_digits
    jmp .color_score

.ds_2p:
    lda BR_SCORE1_H : lsr : lsr : lsr : lsr : ldx #2  : ldy #1 : jsr .draw_digit
    lda BR_SCORE1_H : and #$0F : ldx #6  : ldy #1 : jsr .draw_digit
    lda BR_SCORE1_L : lsr : lsr : lsr : lsr : ldx #10 : ldy #1 : jsr .draw_digit
    lda BR_SCORE1_L : and #$0F : ldx #14 : ldy #1 : jsr .draw_digit
    ldx BR_SCORE1_E1 : lda BR_SCORE1_E2 : ldy #217  
    jsr .draw_prog_digits

    lda BR_SCORE2_H : lsr : lsr : lsr : lsr : ldx #24 : ldy #1 : jsr .draw_digit
    lda BR_SCORE2_H : and #$0F : ldx #28 : ldy #1 : jsr .draw_digit
    lda BR_SCORE2_L : lsr : lsr : lsr : lsr : ldx #32 : ldy #1 : jsr .draw_digit
    lda BR_SCORE2_L : and #$0F : ldx #36 : ldy #1 : jsr .draw_digit
    ldx BR_SCORE2_E1 : lda BR_SCORE2_E2 : ldy #221 
    jsr .draw_prog_digits

.color_score:
    lda #1 : ldx #1
.csc_lp:
    sta COLRAM+1*40,x : sta COLRAM+2*40,x : sta COLRAM+3*40,x
    sta COLRAM+4*40,x : sta COLRAM+5*40,x
    inx : cpx #39 : bne .csc_lp
    rts

.draw_prog_digits:
    sta BR_TEMP : stx BR_TEMP+1  
    lda BR_TEMP : and #$0F : beq .dp_m_blank
    clc : adc #$80 : jmp .dp_m_draw
.dp_m_blank: lda #$20
.dp_m_draw: sta SCRN,y : lda #1 : sta COLRAM,y
    iny
    lda BR_TEMP : bne .dp_ht_show
    lda BR_TEMP+1 : cmp #$10 : bcc .dp_ht_blank
.dp_ht_show: lda BR_TEMP+1 : lsr : lsr : lsr : lsr : clc : adc #$80 : jmp .dp_ht_draw
.dp_ht_blank: lda #$20
.dp_ht_draw: sta SCRN,y : lda #1 : sta COLRAM,y
    iny
    lda BR_TEMP : bne .dp_tt_show
    lda BR_TEMP+1 : bne .dp_tt_show
.dp_tt_blank: lda #$20 : jmp .dp_tt_draw
.dp_tt_show: lda BR_TEMP+1 : and #$0F : clc : adc #$80
.dp_tt_draw: sta SCRN,y : lda #1 : sta COLRAM,y
    rts

BR_gen_grid:
    lda #0 : sta BR_TARGETS_L : sta BR_TARGETS_H
    sta BR_RLE_CNT            
    lda BR_CUR_LEVEL : sec : sbc #1      
.mod_loop:            
    cmp #4 : bcc .lvl_ok
    sec : sbc #4 : jmp .mod_loop
.lvl_ok:
    tax
    lda BR_lvl_ptrs_lo,x : sta BR_LVL_PTR
    lda BR_lvl_ptrs_hi,x : sta BR_LVL_PTR+1
    lda #7 : sta BR_ROW : lda #8 : sta BR_COL       
.draw_loop:
    lda BR_RLE_CNT : bne .place_brick          
    ldy #0 : lda (BR_LVL_PTR),y : inc BR_LVL_PTR : bne .drl_skp
    inc BR_LVL_PTR+1
.drl_skp:   
    pha : lsr : lsr : lsr : lsr : clc : adc #1 : sta BR_RLE_CNT 
    pla : and #$0F : sta BR_RLE_COL 
.place_brick:
    ldx BR_ROW : lda ROW_TABLE_LO,x : clc : adc BR_COL : sta ZP_PTR
    lda ROW_TABLE_HI,x : adc #0 : sta ZP_PTR+1
    ldy #0 : lda BR_RLE_COL : beq .empty_brick          
    pha
    lda #$61 : sta (ZP_PTR),y 
    lda ZP_PTR : sta PRINT_SRC : lda ZP_PTR+1 : clc : adc #$D4 : sta PRINT_SRC+1
    pla : sta (PRINT_SRC),y         
    cmp #_B_ : beq .next_brick
    inc BR_TARGETS_L : bne .next_brick
    inc BR_TARGETS_H : jmp .next_brick
.empty_brick:
    lda #$20 : sta (ZP_PTR),y 
.next_brick:
    dec BR_RLE_CNT : inc BR_COL : lda BR_COL : cmp #32 : bcc .draw_loop
    lda #8 : sta BR_COL : inc BR_ROW : lda BR_ROW : cmp #19 : bcc .draw_loop
    rts

.paddle_read:
    lda $02 : sta $08  
    lda $03 : sta $09  
    sei : lda #%01000000 : sta $DC00 : ldy #$60
.pr_lp: dey : bne .pr_lp
    lda $D419 : sta $02 
    
    lda $033C                  ; Variabile GLOBAL_PAD_CFG
    bne .read_port2

.read_port1_y:
    lda $D41A : sta $03        
    jmp .pr_hw_end

.read_port2:
    lda #%10000000 : sta $DC00 
    ldy #$C0                   ; FIX JITTER
.pr_lp2: 
    dey : bne .pr_lp2
    lda $D419 : sta $03        

.pr_hw_end:
    lda #$FF : sta $DC02 
    lda #$00 : sta $DC00 
    cli
    
    lda #24 : sta BR_SP2_X
    lda $02 : jsr .cl_y : sta BR_SP2_Y
    lda BR_VARIANT : beq .pr_end
    lda #84 : sta BR_SP3_X
    lda BR_MSB_X : ora #%00001000 : sta BR_MSB_X
    lda BR_VARIANT : cmp #2 : beq .ai_p2
.human_p2: lda $03 : jsr .cl_y : sta BR_SP3_Y : rts
.ai_p2:
    lda BR_SP3_Y : clc : adc #21 : cmp BR_BALL_Y
    beq .ai_done : bcc .ai_down
.ai_up: lda BR_SP3_Y : sec : sbc #3 : jmp .ai_apply
.ai_down: lda BR_SP3_Y : clc : adc #3
.ai_apply: jsr .cl_y : sta BR_SP3_Y
.ai_done:
.pr_end: rts

.cl_y:
    cmp #54 : bcs .c1 : lda #54
.c1 cmp BR_PAD_MY : bcc .c2 : lda BR_PAD_MY
.c2 rts

.move_bumper:
    lda BR_SYS_STATE : bne .mb_hide 
    lda BR_MOV_Y : clc : adc BR_MOV_DY : sta BR_MOV_Y
    cmp #90 : bcs .mb_bot
    lda #1 : sta BR_MOV_DY : lda #90 : sta BR_MOV_Y : jmp .mb_done
.mb_bot:
    cmp #230 : bcc .mb_done
    lda #$FF : sta BR_MOV_DY : lda #230 : sta BR_MOV_Y
.mb_done:
    lda BR_MOV_Y : sta BR_SP5_Y : lda #176 : sta BR_SP5_X : rts

.mb_hide:
    lda #0 : sta BR_SP5_X : sta BR_SP5_Y : rts

.inc_wall_bounce:
    jsr BR_play_wall
    rts

BR_bump_colors:  !byte 5, 6, 15, 1, 2      
BR_bump_sprites: !byte 179, 180, 181, 182, 183  

.move_ball:
    lda BR_BALL_X_L : clc : adc BR_BALL_DX : sta BR_BALL_X_L
    lda BR_BALL_DX  : bmi .neg_dx
    lda BR_BALL_X_H : adc #0   : sta BR_BALL_X_H : jmp .chk_bounds
.neg_dx:
    lda BR_BALL_X_H : adc #$FF : sta BR_BALL_X_H

.chk_bounds:
    lda BR_BALL_X_H
    bpl .cb_check_sx    
    jmp .off_left       
    
.cb_check_sx:
    bne .chk_right      
    lda BR_BALL_X_L 
    cmp #16 
    bcs .cb_safe_sx     
    jmp .off_left       
.cb_safe_sx:
    jmp .move_y         

.chk_right:
    lda BR_BALL_X_L 
    cmp #80 
    bcs .cb_check_dx    
    jmp .move_y         
.cb_check_dx:
    jmp .chk_right2

.chk_right2:
    lda BR_VARIANT : beq .bounce_right
    lda BR_WALL_ACT : beq .cb_miss_p2
    dec BR_WALL_ACT : beq .sw_last_bounce_p2 
    jmp .sw_bounce_p2                        

.cb_miss_p2:
    jmp .sw_miss_p2

.sw_last_bounce_p2:
    jsr .clear_safety_wall                   
.sw_bounce_p2:
    lda #79 : sta BR_BALL_X_L
    lda #1 : sta BR_BALL_X_H           
    lda #0 : sec : sbc BR_CUR_SPD : sta BR_BALL_DX
    jsr .inc_wall_bounce
    jmp .move_y

; --- P2 MISS ---
.sw_miss_p2:
    dec BR_LIVES_P2 : jsr BR_update_lives
    
    lda #79 : sta EXP_INIT_XL : lda #1 : sta EXP_INIT_XH
    lda BR_BALL_Y : sta EXP_INIT_Y
    lda #SFX_LOST : sta EXP_SFX
    lda $D015 : and #%00111111 : sta EXP_SPENA_AF
    lda #BR_BALL_BLK : sta EXP_PTR4_AF
    lda #1 : sta EXP_DIR
    
    lda $D015 : and #%00101111 : sta $D015
    jsr DoVectrexExplosion
    lda EXP_SPENA_AF : sta $D015
    
    jsr .reset_ball : rts

.bounce_right:
    lda #80 : sta BR_BALL_X_L 
    lda #1 : sta BR_BALL_X_H           
    jsr .inc_wall_bounce        
    lda #0 : sec : sbc BR_CUR_SPD : sta BR_BALL_DX : jmp .move_y

.off_left:
    lda BR_WALL_ACT : beq .sw_miss_p1
    dec BR_WALL_ACT : beq .sw_last_bounce_p1 
    jmp .sw_bounce_p1                        

.sw_last_bounce_p1:
    jsr .clear_safety_wall                   
.sw_bounce_p1:
    lda #17 : sta BR_BALL_X_L       
    lda #0 : sta BR_BALL_X_H        
    lda BR_CUR_SPD : sta BR_BALL_DX 
    jsr .inc_wall_bounce
    jmp .move_y                     

; --- P1 MISS ---
.sw_miss_p1:
    dec BR_LIVES_P1 : jsr BR_update_lives
    
    lda #17 : sta EXP_INIT_XL : lda #0 : sta EXP_INIT_XH
    lda BR_BALL_Y : sta EXP_INIT_Y
    lda #SFX_LOST : sta EXP_SFX
    lda $D015 : and #%00111111 : sta EXP_SPENA_AF
    lda #BR_BALL_BLK : sta EXP_PTR4_AF
    lda #0 : sta EXP_DIR
    
    lda $D015 : and #%00101111 : sta $D015
    jsr DoVectrexExplosion
    lda EXP_SPENA_AF : sta $D015
    
    jsr .reset_ball : rts

.move_y:
    lda BR_BALL_Y : clc : adc BR_BALL_DY : sta BR_BALL_Y
    cmp #54  : bcs .nt
    jsr .inc_wall_bounce        
    lda BR_CUR_SPD : sta BR_BALL_DY : lda #54 : sta BR_BALL_Y : rts
.nt cmp #240 : bcc .em
    jsr .inc_wall_bounce        
    lda #0 : sec : sbc BR_CUR_SPD : sta BR_BALL_DY : lda #240 : sta BR_BALL_Y
.em rts

.reset_ball:
    lda #0   : sta BR_HITS : sta BR_GRID_CD 
    lda #1   : sta $D02B : sta BR_LAST_P 
    lda #0   : sta BR_BALL_X_H : sta BR_BUMP_TMR
    lda #40  : sta BR_BALL_X_L
    lda #170 : sta BR_BALL_Y
    
    jsr .revert_powerups
    
    lda #1 : sta BR_SYS_STATE
    lda #BUMPER_COOLDOWN : sta BR_SYS_TIME
    jsr .hide_bumper

    lda BR_START_S : sta BR_CUR_SPD
    lda BR_CUR_SPD : sta BR_BALL_DX : sta BR_BALL_DY
    jsr BR_draw_speed_hud
    rts

.check_paddle_col:
    lda BR_BALL_X_H : bne .c_dx
    lda BR_BALL_DX  : bpl .c_dx        
    lda BR_BALL_X_L : cmp #8 : bcc .c_dx : cmp #30 : bcs .c_dx
    lda BR_BALL_Y : clc : adc #20 : cmp BR_SP2_Y : bcc .c_dx          
    lda BR_BALL_Y : sec : sbc BR_PAD_H : sec : sbc #4 : cmp BR_SP2_Y : bcs .c_dx          
    
    lda #29 : sta BR_BALL_X_L          
    lda $08 : sta BR_TEMP+1         
    lda BR_SP2_Y : sta BR_TEMP      
    jsr .apply_english_arcade       
    
    lda #1 : sta BR_LAST_P : jsr .inc_hits  
    rts

.c_dx:
    lda BR_VARIANT : beq .ex_c
    lda BR_BALL_X_H : beq .ex_c
    lda BR_BALL_DX  : bmi .ex_c        
    lda BR_BALL_X_L : cmp #75 : bcc .ex_c : cmp #105 : bcs .ex_c
    lda BR_BALL_Y : clc : adc #20 : cmp BR_SP3_Y : bcc .ex_c          
    lda BR_BALL_Y : sec : sbc BR_PAD_H : sec : sbc #4 : cmp BR_SP3_Y : bcs .ex_c          
    
    lda #75 : sta BR_BALL_X_L          
    lda $09 : sta BR_TEMP+1         
    lda BR_SP3_Y : sta BR_TEMP      
    jsr .apply_english_arcade       
    
    lda #2 : sta BR_LAST_P : jsr .inc_hits
    
    lda BR_BALL_DX : eor #$FF : clc : adc #1 : sta BR_BALL_DX
.ex_c: rts

.inc_hits:
    inc BR_HITS
    lda BR_HITS : cmp #BR_SPEED_STEPS : bcc .ih_pad_sfx
    lda #0 : sta BR_HITS
    lda BR_CUR_SPD : cmp BR_MAX_S : bcs .ih_pad_sfx
    clc : adc #1 : sta BR_CUR_SPD
    cmp BR_MAX_S : bcc .ih_upd
    lda BR_SUPER_BAL : bne .ih_upd  
    lda #2 : sta $D02B
.ih_upd:
    jsr BR_draw_speed_hud
    jsr BR_play_power
    rts
.ih_pad_sfx:
    jsr BR_play_pad 
    rts

.apply_english_arcade:
    lda BR_CUR_SPD : sta BR_BALL_DX
    
    lda BR_TEMP       
    sec : sbc BR_TEMP+1 
    sta $FC           
    
    lda BR_PAD_H : lsr : clc : adc BR_TEMP : sta $FB  
    lda BR_BALL_Y : clc : adc #10
    
    cmp $FB 
    bcs .hit_lower_half

.hit_upper_half:
    lda $FB : sec : sbc BR_BALL_Y : sec : sbc #10
    cmp #7 : bcc .ang_up
    jmp .smash_up

.hit_lower_half:
    sec : sbc $FB
    cmp #7 : bcc .ang_down
    jmp .smash_down

.ang_up:
    lda #$FF : sta BR_BALL_DY : jmp .apply_inertia
.ang_down:
    lda #1 : sta BR_BALL_DY : jmp .apply_inertia
    
.smash_up:
    lda BR_CUR_SPD : clc : adc #1 : sta BR_BALL_DX 
    lda BR_CUR_SPD : lsr : clc : adc #1 : eor #$FF : clc : adc #1 : sta BR_BALL_DY
    jmp .apply_inertia

.smash_down:
    lda BR_CUR_SPD : clc : adc #1 : sta BR_BALL_DX 
    lda BR_CUR_SPD : lsr : clc : adc #1 : sta BR_BALL_DY
    
.apply_inertia:
    lda $FC : beq .done_inertia 
    bmi .spin_up
.spin_down:
    lda BR_BALL_DY : clc : adc #1
    beq .done_inertia 
    sta BR_BALL_DY : jmp .done_inertia
.spin_up:
    lda BR_BALL_DY : sec : sbc #1
    beq .done_inertia 
    sta BR_BALL_DY
.done_inertia:
    rts

.check_bumper_col:
    lda BR_SYS_STATE : bne .cbc_end  
    lda BR_GRID_CD : beq .cbc_go 
    rts
.cbc_go:
    lda BR_BALL_X_H : bne .cbc_end
    lda BR_BALL_X_L : clc : adc #12 : cmp #176 : bcc .cbc_end
    lda #176+24 : cmp BR_BALL_X_L : bcc .cbc_end
    lda BR_BALL_Y : clc : adc #12 : cmp BR_MOV_Y : bcc .cbc_end
    lda BR_MOV_Y : clc : adc #21 : cmp BR_BALL_Y : bcc .cbc_end

    lda #6 : sta BR_GRID_CD
    lda BR_BALL_Y : clc : adc #6 
    cmp BR_MOV_Y : bcc .bounce_y_up  
    lda BR_MOV_Y : clc : adc #21 
    cmp BR_BALL_Y : bcc .bounce_y_down 

.bounce_x:
    lda BR_BALL_DX : eor #$FF : clc : adc #1 : sta BR_BALL_DX
    jmp .apply_bonus
.bounce_y_up:
    lda BR_BALL_DY : bmi .apply_bonus 
    lda BR_BALL_DY : eor #$FF : clc : adc #1 : sta BR_BALL_DY
    jmp .apply_bonus
.bounce_y_down:
    lda BR_BALL_DY : bpl .apply_bonus 
    lda BR_BALL_DY : eor #$FF : clc : adc #1 : sta BR_BALL_DY
    jmp .apply_bonus 

.cbc_end:
    rts

.apply_bonus:
    jsr BR_play_power
    jsr .inc_bonus_score
    
    lda BR_BUMP_IDX
    cmp #3
    beq .apply_instant

    lda #2 : sta BR_SYS_STATE
    lda #PWR_DURATION : sta BR_SYS_TIME
    lda #50 : sta BR_SYS_FRAME
    jsr .hide_bumper
    
    lda BR_BUMP_IDX
    cmp #0 : beq .do_slow
    cmp #1 : beq .do_large
    cmp #2 : beq .do_wall
    jmp .do_killer

.apply_instant:
    lda #1 : sta BR_SYS_STATE
    lda #BUMPER_COOLDOWN : sta BR_SYS_TIME
    lda #50 : sta BR_SYS_FRAME
    jsr .hide_bumper
    jmp .do_life

.do_slow:
    lda BR_START_S : sta BR_CUR_SPD : lda #0 : sta BR_HITS : lda #1 : sta $D02B  
    jsr BR_draw_speed_hud : rts
    
.do_large:
    lda #42 : sta BR_PAD_H : lda #63 : sta BR_PAD_LIM
    lda #242 : sec : sbc BR_PAD_H : sta BR_PAD_MY
    jsr .draw_paddle : rts

.do_wall:
    lda #4 : sta BR_WALL_ACT 
    ldx #1 
.dw_lp:
    lda ROW_TABLE_LO,x : sta ZP_PTR
    lda ROW_TABLE_HI,x : sta ZP_PTR+1
    lda ZP_PTR : sta PRINT_SRC : lda ZP_PTR+1 : clc : adc #$D4 : sta PRINT_SRC+1
    ldy #0
    lda #$61 : sta (ZP_PTR),y 
    lda #_E_ : sta (PRINT_SRC),y
    lda BR_VARIANT : beq .dw_skp
    ldy #39
    lda #$61 : sta (ZP_PTR),y
    lda #_E_ : sta (PRINT_SRC),y
.dw_skp:
    inx : cpx #24 : bcc .dw_lp 
    rts

.clear_safety_wall:
    ldx #1
.cw_lp:
    lda ROW_TABLE_LO,x : sta ZP_PTR
    lda ROW_TABLE_HI,x : sta ZP_PTR+1
    ldy #0
    lda #$20 : sta (ZP_PTR),y 
    lda BR_VARIANT : beq .cw_skp
    ldy #39
    lda #$20 : sta (ZP_PTR),y
.cw_skp:
    inx : cpx #24 : bcc .cw_lp
    rts

.do_life:
    lda BR_LAST_P : cmp #2 : beq .dl_p2
    inc BR_LIVES_P1 : jmp .dl_upd
.dl_p2:
    inc BR_LIVES_P2
.dl_upd:
    jsr BR_update_lives : rts

.do_killer:
    lda #1 : sta BR_SUPER_BAL : lda #4 : sta $D02B : rts

.inc_score_and_spd:
    sed
    lda BR_LAST_P : cmp #2 : beq .score_p2
    lda BR_SCORE1_L : clc : adc #$05 : sta BR_SCORE1_L
    lda BR_SCORE1_H : adc #0 : sta BR_SCORE1_H
    lda BR_SCORE1_E1: adc #0 : sta BR_SCORE1_E1
    lda BR_SCORE1_E2: adc #0 : sta BR_SCORE1_E2
    jmp .add_done
.score_p2:
    lda BR_SCORE2_L : clc : adc #$05 : sta BR_SCORE2_L
    lda BR_SCORE2_H : adc #0 : sta BR_SCORE2_H
    lda BR_SCORE2_E1: adc #0 : sta BR_SCORE2_E1
    lda BR_SCORE2_E2: adc #0 : sta BR_SCORE2_E2
.add_done:
    cld : jsr BR_draw_scores : rts

.inc_bonus_score:
    sed
    lda BR_LAST_P : cmp #2 : beq .ib_p2
    lda BR_SCORE1_L : clc : adc #$50 : sta BR_SCORE1_L
    lda BR_SCORE1_H : adc #0 : sta BR_SCORE1_H
    lda BR_SCORE1_E1: adc #0 : sta BR_SCORE1_E1
    lda BR_SCORE1_E2: adc #0 : sta BR_SCORE1_E2
    jmp .ib_done
.ib_p2:
    lda BR_SCORE2_L : clc : adc #$50 : sta BR_SCORE2_L
    lda BR_SCORE2_H : adc #0 : sta BR_SCORE2_H
    lda BR_SCORE2_E1: adc #0 : sta BR_SCORE2_E1
    lda BR_SCORE2_E2: adc #0 : sta BR_SCORE2_E2
.ib_done:
    cld : jsr BR_draw_scores : rts

.check_grid_col:
    lda BR_BALL_Y : ldx BR_BALL_DY : bmi .sy_up
.sy_down: sec : sbc #47 : jmp .sy_div
.sy_up:   sec : sbc #49
.sy_div:  lsr : lsr : lsr : sta BR_ROW
    
    lda BR_BALL_X_L : sec : sbc #20 : sta BR_COL : lda BR_BALL_X_H : sbc #0
    lsr : lda BR_COL : ror : lsr : lsr : sta BR_COL

    lda BR_ROW : cmp #7 : bcc .skip_y : cmp #19 : bcs .skip_y
    lda BR_COL : cmp #8 : bcc .skip_y : cmp #32 : bcs .skip_y

    ldx BR_ROW : lda ROW_TABLE_LO,x : clc : adc BR_COL : sta ZP_PTR
    lda ROW_TABLE_HI,x : adc #0 : sta ZP_PTR+1
    ldy #0 : lda (ZP_PTR),y : cmp #$61 : bne .skip_y  

    jsr BR_process_hit
    lda BR_SUPER_BAL : bne .sby_skip
    lda BR_BALL_DY : eor #$FF : clc : adc #1 : sta BR_BALL_DY
    lda #4 : sta BR_GRID_CD 
.sby_skip:
    rts

.skip_y:
    lda BR_BALL_X_L : ldx BR_BALL_DX : bmi .sx_left
.sx_right: sec : sbc #17 : jmp .sx_div
.sx_left:  sec : sbc #24
.sx_div:   sta BR_COL : lda BR_BALL_X_H : sbc #0
    lsr : lda BR_COL : ror : lsr : lsr : sta BR_COL

    lda BR_BALL_Y : sec : sbc #48 : lsr : lsr : lsr : sta BR_ROW

    lda BR_ROW : cmp #7 : bcc .skip_x : cmp #19 : bcs .skip_x
    lda BR_COL : cmp #8 : bcc .skip_x : cmp #32 : bcs .skip_x

    ldx BR_ROW : lda ROW_TABLE_LO,x : clc : adc BR_COL : sta ZP_PTR
    lda ROW_TABLE_HI,x : adc #0 : sta ZP_PTR+1
    ldy #0 : lda (ZP_PTR),y : cmp #$61 : bne .skip_x

    jsr BR_process_hit
    lda BR_SUPER_BAL : bne .sbx_skip
    lda BR_BALL_DX : eor #$FF : clc : adc #1 : sta BR_BALL_DX
    lda #4 : sta BR_GRID_CD 
.sbx_skip:
.skip_x:
    rts

BR_process_hit:
    lda ZP_PTR : sta PRINT_SRC 
    lda ZP_PTR+1 : clc : adc #$D4 : sta PRINT_SRC+1
    lda (PRINT_SRC),y : and #$0F           
    
    ldx BR_SUPER_BAL : bne .ph_super_kill

    cmp #_B_ : beq .ph_indestructible
    cmp #_E_ : beq .ph_grey
.ph_normal:
    lda #$20 : sta (ZP_PTR),y  
    lda BR_TARGETS_L : bne .phn_skip
    dec BR_TARGETS_H 
.phn_skip:
    dec BR_TARGETS_L
    jsr BR_play_brick : jsr .inc_score_and_spd : rts

.ph_grey:
    lda #_Y_ : sta (PRINT_SRC),y : jsr BR_play_metal : rts

.ph_indestructible:
    jsr BR_play_metal : rts

.ph_super_kill:
    lda #$20 : sta (ZP_PTR),y  
    lda BR_TARGETS_L : bne .phsk_skip
    dec BR_TARGETS_H 
.phsk_skip:
    dec BR_TARGETS_L
    jsr BR_play_brick : jsr .inc_score_and_spd : rts

; ==========================================
; MOTORE AUDIO LOCALE BREAKOUT (Hardware Kill)
; ==========================================
BR_kill_sfx:
    lda #0 : sta $D412 : sta $D413 : sta $D414 
    rts

BR_play_brick:
    jsr BR_kill_sfx
    lda #$05 : sta $D413       
    lda #$00 : sta $D40E       
    lda #$20 : sta $D40F       
    lda #15  : sta $D418       
    lda #$81 : sta $D412       
    lda #6   : sta BR_SFX_TMR
    rts

BR_play_metal:
    jsr BR_kill_sfx
    lda #$08 : sta $D411       
    lda #$08 : sta $D413       
    lda #$00 : sta $D40E       
    lda #$80 : sta $D40F       
    lda #15  : sta $D418
    lda #$41 : sta $D412       
    lda #8   : sta BR_SFX_TMR
    rts

BR_play_pad:
    jsr BR_kill_sfx
    lda #$05 : sta $D413       
    lda #$40 : sta $D40E       
    lda #$10 : sta $D40F       
    lda #15  : sta $D418
    lda #$11 : sta $D412       
    lda #6   : sta BR_SFX_TMR
    rts

BR_play_wall:
    jsr BR_kill_sfx
    lda #$04 : sta $D413       
    lda #$80 : sta $D40E       
    lda #$25 : sta $D40F       
    lda #15  : sta $D418
    lda #$11 : sta $D412       
    lda #5   : sta BR_SFX_TMR
    rts

BR_play_power:
    jsr BR_kill_sfx
    lda #$09 : sta $D413       
    lda #$00 : sta $D40E
    lda #$40 : sta $D40F
    lda #15  : sta $D418
    lda #$11 : sta $D412       
    lda #12  : sta BR_SFX_TMR
    rts
; ==========================================

.draw_digit:
    sta PRINT_SRC : lda #0 : sta ZP_PTR+1 : sta ZP_PTR         
    tya : beq .add_x
.mul40: clc : lda ZP_PTR : adc #40 : sta ZP_PTR : bcc .m_ok : inc ZP_PTR+1
.m_ok:  dey : bne .mul40
.add_x: txa : clc : adc ZP_PTR : sta ZP_PTR : bcc .a_ok : inc ZP_PTR+1
.a_ok:  clc : lda ZP_PTR+1 : adc #$04 : sta ZP_PTR+1
    lda PRINT_SRC : asl : asl : asl : asl : tax : ldy #0
.yl: lda BR_big_num,x : sta (ZP_PTR),y : inx : iny
    lda BR_big_num,x : sta (ZP_PTR),y : inx : iny
    lda BR_big_num,x : sta (ZP_PTR),y : inx
    lda ZP_PTR : clc : adc #40 : sta ZP_PTR : bcc .y_ok : inc ZP_PTR+1
.y_ok:  ldy #0 : txa : and #$0F : cmp #15 : bcc .yl : rts

BR_big_num:
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

; === SPRITE DATA ===
SPRITE_DATA:
    ; 50 (Inutilizzato/Fallback)
    !byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    ; 51 (S)
    !byte $FF,$FF,$FF,$FF,$83,$FF,$FF,$BF,$FF,$FF,$BF,$FF,$FF,$83,$FF,$FF,$FB,$FF,$FF,$83,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    ; 52 (L)
    !byte $FF,$FF,$FF,$FF,$BF,$FF,$FF,$BF,$FF,$FF,$BF,$FF,$FF,$BF,$FF,$FF,$BF,$FF,$FF,$83,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    ; 53 (W)
    !byte $FF,$FF,$FF,$FF,$BB,$FF,$FF,$BB,$FF,$FF,$AB,$FF,$FF,$AB,$FF,$FF,$AB,$FF,$FF,$93,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    ; 54 (B)
    !byte $FF,$FF,$FF,$FF,$87,$FF,$FF,$BB,$FF,$FF,$BB,$FF,$FF,$87,$FF,$FF,$BB,$FF,$FF,$83,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    ; 55 (KILLER)
    !byte $FF,$FF,$FF,$F6,$DB,$BF,$F6,$DB,$BF,$F1,$DB,$BF,$F6,$DB,$BF,$F6,$DB,$BF,$F6,$D8,$8F,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

BR_lvl_ptrs_lo:
    !byte <LEVEL_1, <LEVEL_2, <LEVEL_3, <LEVEL_4
BR_lvl_ptrs_hi:
    !byte >LEVEL_1, >LEVEL_2, >LEVEL_3, >LEVEL_4

LEVEL_1:
    !byte $FF,$FF,$FF,$F2,$F2,$F2,$F8,$F8,$F8,$F7,$F7,$F7,$F5,$F5,$F5,$F0,$F0,$F0
LEVEL_2:
    !byte $FF,$FF,$FF,$FF,$F0,$90,$E8,$20,$F5,$95,$E0,$25,$F0,$90,$F6,$76,$10,$EF,$9F,$F0,$F0,$F0
LEVEL_3:
    !byte $16,$F2,$62,$16,$16,$F2,$62,$16,$16,$20,$28,$20,$28,$40,$28,$20,$28,$20,$16,$16,$20,$28
    !byte $20,$28,$40,$28,$20,$28,$20,$16,$16,$40,$27,$20,$47,$20,$27,$40,$16
LEVEL_4:
    !byte $32,$00,$32,$10,$02,$00,$22,$00,$22,$00,$02,$00,$12,$10,$02,$00,$02,$10,$02,$10,$02,$00
    !byte $02,$20,$02,$20,$02,$00,$12,$10,$02,$00,$02,$10,$02,$10,$02,$00,$02,$20,$02,$20,$02,$00
    !byte $02,$05,$10,$05,$00,$05,$10,$05,$10,$05,$00,$05,$20,$05,$20,$05,$00,$15,$10,$05,$00,$05
    !byte $10,$05,$10,$05,$00,$25,$00,$25,$00,$35,$10,$05,$00,$05,$10,$05,$10,$05,$00,$25,$00,$25
    !byte $00,$25,$07,$10,$07,$00,$07,$10,$07,$10,$07,$20,$07,$00,$07,$30,$07,$00,$07,$00,$17,$00
    !byte $17,$00,$07,$10,$07,$20,$07,$00,$07,$30,$07,$00,$07,$00,$17,$00,$17,$00,$07,$00,$17,$20
    !byte $07,$00,$07,$30,$07,$00,$02,$00,$12,$00,$12,$00,$02,$00,$12,$20,$02,$00,$02,$30,$02,$00
    !byte $32,$00,$32,$00,$12,$00,$22,$00,$22,$10,$02,$00,$32,$00,$32,$00,$12,$00,$22,$00,$22,$10,$02,$00

} ; --- FINE FILE ---