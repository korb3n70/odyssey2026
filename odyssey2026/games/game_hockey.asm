; ==========================================
; game_hockey.asm - Hockey V20 (Top Collider Fix)
; FIX: Ripristinato il limite superiore della pallina a Y=54. Ora tocca 
;      esattamente il bordo visivo superiore in perfetta sincronia con i paddle.
; ==========================================
* = $A000

!src "assets/odyssey_charset_map.asm"

; --- Variabili per Winscreen ---
WIN_COL_S   = $98   
WIN_COL_E   = $99   
WIN_COL_ON  = $9A   
WIN_COL_OFF = $9B   

HK_P1_GOALIE_X = 40
HK_P1_ATTACK_X = 120   
HK_P2_GOALIE_X = 64    
HK_P2_ATTACK_X = 240   

; --- ZP Hockey ($40-$52) SAFE ---
HK_SCORE_P1 = $40 : HK_SCORE_P2 = $41
HK_TEMP     = $42 : HK_VARIANT  = $43
HK_RESTART  = $44 : HK_PAD_H    = $45
HK_PAD_LIM  = $46 : HK_PAD_MY   = $47
HK_BALL_XL  = $48 : HK_BALL_XH  = $49 
HK_BALL_Y   = $4A : HK_BALL_DX  = $4B
HK_BALL_DY  = $4C : HK_HITS     = $4D
HK_CUR_SPD  = $4E : HK_START_S  = $4F
HK_MAX_S    = $75 : HK_LAST_WIN = $76
HK_RND      = $77 : HK_AI_OFFSET= $78

; --- Variabili Tastiera Bare Metal ---
HK_KEY_LOCK = $7A
HK_KEY_MAT  = $7B

; --- Sprite map Hardware ---
HK_SP1_X=$D000:HK_SP1_Y=$D001 
HK_SP2_X=$D002:HK_SP2_Y=$D003 
HK_SP3_X=$D004:HK_SP3_Y=$D005 
HK_SP4_X=$D006:HK_SP4_Y=$D007 
HK_SP7_X=$D00C:HK_SP7_Y=$D00D 

HK_MSB_X=$D010 : HK_SPENA=$D015

HK_PTR1=$07F8 : HK_PTR2=$07F9 : HK_PTR3=$07FA : HK_PTR4=$07FB
HK_PTR5=$07FC : HK_PTR6=$07FD : HK_PTR7=$07FE 

HK_PAD_BLK  = 13
HK_BALL_BLK = 14

HK_SPEED_STEPS = 5

HK_tab_start: !byte 2, 3
HK_tab_max:   !byte 9, 9

; Variabili KERNEL Esplosione
EXP_COLOR     = $91
EXP_INIT_XL   = $92
EXP_INIT_XH   = $93
EXP_INIT_Y    = $94
EXP_SFX       = $95
EXP_SPENA_AF  = $96
EXP_PTR4_AF   = $97
EXP_DIR       = $98 

; ==========================================
Hockey:
    lda #0 : sta HK_VARIANT : sta HK_KEY_LOCK

HK_restart_trampoline:
    lda #0 : sta HK_SCORE_P1 : sta HK_SCORE_P2 : sta HK_RESTART
    lda #0 : sta HK_LAST_WIN
    lda #42 : sta HK_PAD_H
    lda #63 : sta HK_PAD_LIM
    lda #244 : sec : sbc HK_PAD_H : sta HK_PAD_MY
    lda #0   : sta HK_RND
    
    ldx HK_VARIANT
    lda HK_tab_start,x : sta HK_START_S
    lda HK_tab_max,x   : sta HK_MAX_S
    
    jsr HK_InitGame
    
    lda HK_RESTART : cmp #1 : beq HK_restart_trampoline
    rts

!zone game_hockey {

; ==========================================
HK_InitGame:
    ldx #0 : lda #0
.cl_pad: sta $0340,x : inx : cpx #64 : bne .cl_pad
    ldx #0
.dr_pad: lda #%11110000 : sta $0340,x : inx : inx : inx
    cpx HK_PAD_LIM : bcc .dr_pad

    ldx #0 : lda #0
.cl_ball: sta $0380,x : inx : cpx #63 : bne .cl_ball
    lda #$FF : sta $0380+0 : sta $0380+3 : sta $0380+6 : sta $0380+9

    lda $D011 : and #$EF : sta $D011
    lda #1 : sta $D021 : sta $D020
    lda #$1E : sta $D018               
    lda #6 : jsr FillColorRAM : jsr ClearScreen 
    lda #0 : sta KBD_COUNT : lda #1 : sta $CC
    lda $D011 : ora #$10 : sta $D011

    jsr HK_draw_boundary
    jsr HK_draw_scores
    jsr HK_draw_speed_hud

    lda #HK_PAD_BLK  : sta HK_PTR1 : sta HK_PTR2 : sta HK_PTR3 : sta HK_PTR4
    lda #HK_BALL_BLK : sta HK_PTR7

    lda #0 : sta $D01C
    lda #%01001111 : sta $D017  
    
    lda #2 : sta $D027 : sta $D029   
    lda #5 : sta $D028 : sta $D02A   
    lda #0 : sta $D02D               

    lda #HK_P1_ATTACK_X : sta HK_SP1_X     
    lda #HK_P2_ATTACK_X : sta HK_SP2_X     
    lda #HK_P1_GOALIE_X : sta HK_SP3_X     
    lda #HK_P2_GOALIE_X : sta HK_SP4_X     
    
    lda #%00001000 : sta HK_MSB_X : sta $D010 

    lda #146 : sta HK_SP1_Y : sta HK_SP2_Y : sta HK_SP3_Y : sta HK_SP4_Y

    lda #%01001100 : sta HK_SPENA : sta $D015
    jsr InitSFX

    jsr .reset_ball
    jsr .countdown
    
    lda HK_RESTART : beq .start_game
    rts 

.start_game:
    lda #%01001111 : sta HK_SPENA : sta $D015
    jmp .g_loop

; ==========================================
; GAME LOOP
; ==========================================
.g_loop:
.wt1: lda RASTER : cmp #$F0 : bne .wt1
.wt2: lda RASTER : cmp #$F0 : beq .wt2

    inc HK_RND

    jsr HK_paddle_read 
    jsr .move_ball
    
    lda HK_RESTART : beq .cont_loop
    rts 
.cont_loop:

    jsr UpdateSFX

    lda HK_BALL_XL : sta HK_SP7_X
    lda HK_BALL_Y  : sta HK_SP7_Y
    lda HK_BALL_XH : beq .msb_clr
    lda HK_MSB_X : ora #%01000000 : sta HK_MSB_X : jmp .msb_l_done
.msb_clr:
    lda HK_MSB_X : and #%10111111 : sta HK_MSB_X
.msb_l_done:
    lda HK_MSB_X : sta $D010 

    lda HK_SCORE_P1 : cmp #10 : bcc .np1
    jmp .do_game_over
.np1:
    lda HK_SCORE_P2 : cmp #10 : bcc .np2
    jmp .do_game_over
.np2:

    ; ==========================================
    ; TASTIERA BARE METAL CON DEBOUNCE BLINDATO
    ; ==========================================
    sei
    lda #$FF : sta $DC02 
    lda #$00 : sta $DC03 
    lda #$FE : sta $DC00 
    lda $DC01 : sta HK_KEY_MAT
    lda #$00 : sta $DC00 
    cli

    lda HK_KEY_MAT
    and #$78
    cmp #$78
    beq .keys_released

    lda HK_KEY_LOCK
    bne .no_key

    lda #1 : sta HK_KEY_LOCK

    lda HK_KEY_MAT : and #$10 : beq .do_res
    lda HK_KEY_MAT : and #$08 : beq .do_ext
    lda HK_KEY_MAT : and #$20 : beq .do_var
    lda HK_KEY_MAT : and #$40 : beq .do_var
    jmp .no_key

.keys_released:
    lda #0 : sta HK_KEY_LOCK
.no_key:
    jmp .g_loop

.do_res:
    lda #1 : sta HK_RESTART : rts
.do_var:
    lda HK_VARIANT : eor #1 : sta HK_VARIANT
    lda #1 : sta HK_RESTART : rts
.do_ext:
    lda #$FF : sta HK_RESTART : jsr .hk_cleanup : rts

; ==========================================
; PULIZIA E RESTORE KERNAL
; ==========================================
.hk_cleanup:
    lda #0 : sta HK_SPENA : sta $D010 : sta $D017 : sta $D01D : sta $D01C
    lda $D011 : and #$EF : sta $D011
    
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
    lda #6 : sta <WIN_COL_ON   
    lda #1 : sta <WIN_COL_OFF  
    lda HK_LAST_WIN : bne .go_p2
    
    lda #8 : sta <WIN_COL_S : lda #16 : sta <WIN_COL_E   
    jmp .go_call
.go_p2:
    lda #25 : sta <WIN_COL_S : lda #33 : sta <WIN_COL_E   
    
.go_call:
    jsr DoWinScreen   
    
    cmp #$85 : beq .go_res
    cmp #$87 : beq .go_res
    cmp #$86 : beq .go_var
    cmp #$88 : beq .go_ext
    jmp .go_res  

.go_res:
    lda #1 : sta HK_RESTART : rts 
.go_var:
    lda HK_VARIANT : eor #1 : sta HK_VARIANT
    lda #1 : sta HK_RESTART : rts 
.go_ext:
    lda #$FF : sta HK_RESTART : jsr .hk_cleanup : rts

; ==========================================
; PADDLE READ (DUAL CONFIGURATION & ANTI-JITTER)
; ==========================================
HK_paddle_read:
    lda HK_SP3_Y : sta $08  
    lda HK_SP4_Y : sta $09  

    sei 
    lda #%01000000 : sta $DC00 
    ldy #$80                   
.pr_lp1: 
    dey : bne .pr_lp1
    lda $D419 : sta $02        
    
    lda $033C                  
    bne .read_port2            

.read_port1_y:
    lda $D41A : sta $03        
    jmp .pr_end

.read_port2:
    lda #%10000000 : sta $DC00 
    ldy #$C0                   
.pr_lp2: 
    dey : bne .pr_lp2
    lda $D419 : sta $03        

.pr_end:
    lda #$FF : sta $DC02 
    lda #$00 : sta $DC00 
    cli
    
    lda $02 : jsr .cl_y : sta HK_SP3_Y : sta HK_SP1_Y
    
    lda HK_VARIANT : beq .human_p2

.ai_p2:
    lda HK_BALL_Y
    sec : sbc HK_AI_OFFSET
    bcs +
    lda #0         
+   sta HK_TEMP
    
    lda HK_SP4_Y
    cmp HK_TEMP
    beq .ai_done
    bcc .ai_down
.ai_up:
    lda HK_SP4_Y : sec : sbc HK_TEMP
    cmp #6 : bcc .ai_snap   
    lda HK_SP4_Y : sec : sbc #6 : jmp .ai_apply 
.ai_down:
    lda HK_TEMP : sec : sbc HK_SP4_Y
    cmp #6 : bcc .ai_snap   
    lda HK_SP4_Y : clc : adc #6 : jmp .ai_apply              
.ai_snap:
    lda HK_TEMP         
.ai_apply:
    jsr .cl_y : sta HK_SP4_Y : sta HK_SP2_Y
.ai_done:
    rts

.human_p2:
    lda $03 : jsr .cl_y : sta HK_SP4_Y : sta HK_SP2_Y
    rts

.cl_y:
    cmp #54 : bcs .cy1 : lda #54    
.cy1: cmp HK_PAD_MY : bcc .cy2 : lda HK_PAD_MY  
.cy2: rts

.roll_ai_target:
    lda $D012       
    and #$01        
    beq .ai_t_up
.ai_t_down:
    lda HK_PAD_H : sec : sbc #4 : sta HK_AI_OFFSET : rts 
.ai_t_up:
    lda #4 : sta HK_AI_OFFSET : rts   

; ==========================================
; MOVE BALL E LOGICA GOAL
; ==========================================
.move_ball:
    lda HK_BALL_XL : clc : adc HK_BALL_DX : sta HK_BALL_XL
    lda HK_BALL_DX : bmi .neg_dx
    lda HK_BALL_XH : adc #0   : sta HK_BALL_XH : jmp .chk_goal_dx
.neg_dx:
    lda HK_BALL_XH : adc #$FF : sta HK_BALL_XH

.chk_goal_sx:
    lda HK_BALL_XH : bne .chk_goal_dx
    lda HK_BALL_DX : bpl .chk_goal_dx
    lda HK_BALL_XL : cmp #24 : bcs .chk_goal_dx
    
    lda HK_BALL_Y : cmp #106 : bcc .wall_sx
    cmp #178 : bcs .wall_sx
    
    inc HK_SCORE_P2 : lda #1 : sta HK_LAST_WIN
    lda #24 : sta <EXP_INIT_XL : lda #0 : sta <EXP_INIT_XH
    jmp .do_goal
.wall_sx:
    lda #SFX_WALL : jsr PlaySFX
    lda HK_BALL_DX : eor #$FF : clc : adc #1 : sta HK_BALL_DX
    lda #24 : sta HK_BALL_XL : lda #0 : sta HK_BALL_XH
    jmp .move_y

.chk_goal_dx:
    lda HK_BALL_XH : beq .move_y
    lda HK_BALL_DX : bmi .move_y
    lda HK_BALL_XL : cmp #80 : bcc .move_y   
    
    lda HK_BALL_Y : cmp #106 : bcc .wall_dx
    cmp #178 : bcs .wall_dx
    
    inc HK_SCORE_P1 : lda #0 : sta HK_LAST_WIN
    lda #80 : sta <EXP_INIT_XL : lda #1 : sta <EXP_INIT_XH
    jmp .do_goal
.wall_dx:
    lda #SFX_WALL : jsr PlaySFX
    lda HK_BALL_DX : eor #$FF : clc : adc #1 : sta HK_BALL_DX
    lda #80 : sta HK_BALL_XL : lda #1 : sta HK_BALL_XH

.move_y:
    lda HK_BALL_Y : clc : adc HK_BALL_DY : sta HK_BALL_Y
    ; --- COLLIDER SUPERIORE PALLA RIPRISTINATO A Y=54 ---
    cmp #54 : bcs .chk_bot
    lda #SFX_WALL : jsr PlaySFX
    lda #2   : sta HK_BALL_DY : lda #54 : sta HK_BALL_Y : rts
.chk_bot:
    cmp #240 : bcc .mb_done
    lda #SFX_WALL : jsr PlaySFX
    lda #$FE : sta HK_BALL_DY : lda #240 : sta HK_BALL_Y
.mb_done:
    jsr .check_goalies
    jsr .check_attackers
    rts

.do_goal:
    jsr HK_draw_scores
    lda HK_SCORE_P1 : cmp #10 : bcs .go_jmp 
    lda HK_SCORE_P2 : cmp #10 : bcs .go_jmp 
    jmp .do_exp
.go_jmp: 
    rts 

.do_exp:
    lda HK_BALL_Y   : sta <EXP_INIT_Y
    lda #SFX_GOAL   : sta <EXP_SFX
    lda #%01001111  : sta <EXP_SPENA_AF   
    lda #HK_PAD_BLK : sta <EXP_PTR4_AF    
    
    lda HK_LAST_WIN : eor #1 : sta <EXP_DIR
    lda #6 : sta <EXP_COLOR
    
    lda #%00001100 : sta HK_SPENA : sta $D015 
    jsr DoVectrexExplosion
    
    lda #HK_PAD_BLK  : sta HK_PTR5 : sta HK_PTR6
    lda #HK_BALL_BLK : sta HK_PTR7
    lda #%00001000 : sta HK_MSB_X : sta $D010
    lda #%01001111 : sta HK_SPENA : sta $D015
    
    jsr .reset_ball
    rts

; ==========================================
; RESET BALL E SPEED HUD
; ==========================================
.reset_ball:
    lda #0 : sta HK_HITS
    lda HK_START_S : sta HK_CUR_SPD
    lda #0 : sta $D02D   
    lda #146 : sta HK_BALL_Y
    
    jsr .roll_ai_target
    
    lda HK_LAST_WIN : bne .rb_p2
    lda #0  : sta HK_BALL_XH
    lda #72 : sta HK_BALL_XL
    lda HK_CUR_SPD : sta HK_BALL_DX
    jmp .rb_dy
.rb_p2:
    lda #1  : sta HK_BALL_XH
    lda #16 : sta HK_BALL_XL 
    lda #0 : sec : sbc HK_CUR_SPD : sta HK_BALL_DX
.rb_dy:
    lda #2 : sta HK_BALL_DY
    
    lda HK_BALL_XL : sta HK_SP7_X
    lda HK_BALL_Y  : sta HK_SP7_Y
    lda HK_BALL_XH : beq .r_msb_clr
    lda HK_MSB_X : ora #%01000000 : sta HK_MSB_X : jmp .r_msb_done
.r_msb_clr:
    lda HK_MSB_X : and #%11111111 : sta HK_MSB_X
.r_msb_done:
    lda HK_MSB_X : sta $D010
    jsr HK_draw_speed_hud
    rts

HK_draw_speed_hud:
    lda #$8A : sta SCRN+24*40+19  
    lda #6   : sta COLRAM+24*40+19
    lda HK_CUR_SPD
    clc : adc #$80                
    sta SCRN+24*40+20
    lda #6   : sta COLRAM+24*40+20
    rts

; ==========================================
; COLLISIONI PORTIERI (Con Delta $FA)
; ==========================================
.check_goalies:
    lda HK_BALL_XH : bne .cg_p2
    lda HK_BALL_DX : bpl .cg_p2
    
    lda HK_BALL_XL : cmp #32 : bcc .cg_p2 : cmp #54 : bcs .cg_p2
    
    lda HK_BALL_Y : clc : adc #20 : cmp HK_SP3_Y : bcc .cg_p2
    lda HK_BALL_Y : sec : sbc HK_PAD_H : sec : sbc #4 : cmp HK_SP3_Y : bcs .cg_p2
    
    lda #(HK_P1_GOALIE_X + 4) : sta HK_BALL_XL
    lda $08 : sta $FA 
    lda HK_SP3_Y : sta HK_TEMP : jsr .apply_english_arcade : jsr .inc_spd
    jsr .roll_ai_target
    lda HK_CUR_SPD : sta HK_BALL_DX
    lda #SFX_PAD : jsr PlaySFX : rts
    
.cg_p2:
    lda HK_BALL_XH : beq .cg_end
    lda HK_BALL_DX : bmi .cg_end
    
    lda HK_BALL_XL : cmp #50 : bcc .cg_end : cmp #72 : bcs .cg_end 
    
    lda HK_BALL_Y : clc : adc #20 : cmp HK_SP4_Y : bcc .cg_end
    lda HK_BALL_Y : sec : sbc HK_PAD_H : sec : sbc #4 : cmp HK_SP4_Y : bcs .cg_end
    
    lda #(HK_P2_GOALIE_X - 8) : sta HK_BALL_XL
    lda $09 : sta $FA 
    lda HK_SP4_Y : sta HK_TEMP : jsr .apply_english_arcade : jsr .inc_spd
    lda #0 : sec : sbc HK_CUR_SPD : sta HK_BALL_DX
    lda #SFX_PAD : jsr PlaySFX
.cg_end: rts

; ==========================================
; COLLISIONI ATTACCANTI (Con Delta $FA)
; ==========================================
.check_attackers:
    lda HK_BALL_XH : beq .ca_do
    rts 
.ca_do:
    lda HK_BALL_DX : bmi .ca_moving_left

.ca_moving_right:
    lda HK_BALL_XL : cmp #110 : bcc .ca_mr_chk_p2 : cmp #132 : bcs .ca_mr_chk_p2
    lda HK_SP1_Y : jsr .ca_hit_y : bcs .hit_p1_back_pow
.ca_mr_chk_p2:
    lda HK_BALL_XL : cmp #230 : bcc .ca_end : cmp #252 : bcs .ca_end
    lda HK_SP2_Y : jsr .ca_hit_y : bcs .hit_p2_front_bnc
    rts

.ca_moving_left:
    lda HK_BALL_XL : cmp #230 : bcc .ca_ml_chk_p1 : cmp #252 : bcs .ca_ml_chk_p1
    lda HK_SP2_Y : jsr .ca_hit_y : bcs .hit_p2_back_pow
.ca_ml_chk_p1:
    lda HK_BALL_XL : cmp #110 : bcc .ca_end : cmp #132 : bcs .ca_end
    lda HK_SP1_Y : jsr .ca_hit_y : bcs .hit_p1_front_bnc
.ca_end:
    rts

.hit_p1_back_pow:
    lda $08 : sta $FA
    lda HK_SP1_Y : sta HK_TEMP : jsr .apply_english_arcade : jsr .inc_spd
    jsr .roll_ai_target
    lda HK_CUR_SPD : sta HK_BALL_DX 
    lda #(HK_P1_ATTACK_X + 12) : sta HK_BALL_XL  
    lda #SFX_POWERUP : jsr PlaySFX : rts
    
.hit_p2_front_bnc:
    lda $09 : sta $FA
    lda HK_SP2_Y : sta HK_TEMP : jsr .apply_english_arcade : jsr .inc_spd
    lda #0 : sec : sbc HK_CUR_SPD : sta HK_BALL_DX
    lda #(HK_P2_ATTACK_X - 12) : sta HK_BALL_XL : lda #SFX_WALL : jsr PlaySFX : rts

.hit_p2_back_pow:
    lda $09 : sta $FA
    lda HK_SP2_Y : sta HK_TEMP : jsr .apply_english_arcade : jsr .inc_spd
    lda #0 : sec : sbc HK_CUR_SPD : sta HK_BALL_DX 
    lda #(HK_P2_ATTACK_X - 12) : sta HK_BALL_XL  
    lda #SFX_POWERUP : jsr PlaySFX : rts
    
.hit_p1_front_bnc:
    lda $08 : sta $FA
    lda HK_SP1_Y : sta HK_TEMP : jsr .apply_english_arcade : jsr .inc_spd
    jsr .roll_ai_target
    lda HK_CUR_SPD : sta HK_BALL_DX
    lda #(HK_P1_ATTACK_X + 8) : sta HK_BALL_XL : lda #SFX_WALL : jsr PlaySFX : rts

.ca_hit_y:
    sta $FC
    lda HK_BALL_Y : clc : adc #20 : cmp $FC : bcc .ca_no
    lda HK_BALL_Y : sec : sbc HK_PAD_H : sec : sbc #4 : cmp $FC : bcs .ca_no  
    sec : rts
.ca_no: clc : rts

; ==========================================
; ENGLISH DYNAMICO ARCADE E INC SPEED
; ==========================================
.apply_english_arcade:
    lda HK_CUR_SPD : sta HK_BALL_DX
    
    lda HK_TEMP       
    sec : sbc $FA 
    sta $FC           
    
    lda HK_PAD_H : lsr : clc : adc HK_TEMP : sta $FB  
    lda HK_BALL_Y : clc : adc #10
    
    cmp $FB 
    bcs .hit_lower_half

.hit_upper_half:
    lda $FB : sec : sbc HK_BALL_Y : sec : sbc #10
    cmp #7 : bcc .ang_up
    jmp .smash_up

.hit_lower_half:
    sec : sbc $FB
    cmp #7 : bcc .ang_down
    jmp .smash_down

.ang_up:
    lda #$FF : sta HK_BALL_DY : jmp .apply_inertia
.ang_down:
    lda #1 : sta HK_BALL_DY : jmp .apply_inertia
    
.smash_up:
    lda HK_CUR_SPD : clc : adc #1 : sta HK_BALL_DX 
    lda HK_CUR_SPD : lsr : clc : adc #1 : eor #$FF : clc : adc #1 : sta HK_BALL_DY
    jmp .apply_inertia

.smash_down:
    lda HK_CUR_SPD : clc : adc #1 : sta HK_BALL_DX 
    lda HK_CUR_SPD : lsr : clc : adc #1 : sta HK_BALL_DY
    
.apply_inertia:
    lda $FC : beq .done_inertia 
    bmi .spin_up
.spin_down:
    lda HK_BALL_DY : clc : adc #1
    beq .done_inertia 
    sta HK_BALL_DY : jmp .done_inertia
.spin_up:
    lda HK_BALL_DY : sec : sbc #1
    beq .done_inertia 
    sta HK_BALL_DY
.done_inertia:
    rts

.inc_spd:
    inc HK_HITS : lda HK_HITS : cmp #HK_SPEED_STEPS : bcc .is_skip
    lda #0 : sta HK_HITS
    
    lda HK_CUR_SPD : cmp HK_MAX_S : bcs .is_skip
    
    clc : adc #1 : sta HK_CUR_SPD
    cmp HK_MAX_S : bcc .is_upd
    
    lda #2 : sta $D02D 
.is_upd: 
    jsr HK_draw_speed_hud
    lda #SFX_POWERUP : jsr PlaySFX : rts
.is_skip: 
    lda #SFX_PAD : jsr PlaySFX : rts

; ==========================================
; COUNTDOWN FANFARA (SYNC 50Hz) E FONT
; ==========================================
.countdown:
    lda #1 : jsr $1000               
    lda #$0F : sta $D418             

    jsr .hk_set_bg : jsr .hk_clr_center

    lda #10 : ldx #12 : ldy #8  : jsr .draw_digit   
    lda #11 : ldx #16 : ldy #8  : jsr .draw_digit   
    lda #12 : ldx #20 : ldy #8  : jsr .draw_digit   
    lda HK_VARIANT : ldx #25 : ldy #8 : jsr .draw_digit

    lda #3 : sta HK_TEMP
.cnt_lp:
    jsr .hk_clr_count
    lda HK_TEMP : ldx #19 : ldy #16 : jsr .draw_digit
    jsr .wait_1sec
    lda HK_RESTART : bne .cd_exit
    dec HK_TEMP : bne .cnt_lp

    jsr .hk_clr_count
    lda #14 : ldx #15 : ldy #16 : jsr .draw_digit
    lda #0  : ldx #19 : ldy #16 : jsr .draw_digit
    lda #15 : ldx #23 : ldy #16 : jsr .draw_digit
    jsr .wait_1sec
    lda HK_RESTART : bne .cd_exit
    jsr .hk_clr_center
.cd_exit:
    jsr $1003                        
    
    lda #0 : ldx #0
.cl_sid_hk:
    sta $D400,x
    inx : cpx #25 : bne .cl_sid_hk

    lda #$0F : sta $D418
    jsr InitSFX                      
    rts

.hk_set_bg:
    lda #6 : ldx #0   
.hk_sw_lp:
    sta COLRAM+8*40,x  : sta COLRAM+9*40,x  : sta COLRAM+10*40,x
    sta COLRAM+11*40,x : sta COLRAM+12*40,x
    sta COLRAM+13*40,x : sta COLRAM+14*40,x : sta COLRAM+15*40,x
    sta COLRAM+16*40,x : sta COLRAM+17*40,x : sta COLRAM+18*40,x
    sta COLRAM+19*40,x : sta COLRAM+20*40,x
    inx : cpx #40 : bne .hk_sw_lp : rts

.hk_clr_center:
    lda #32 : ldx #1
.hk_cc1: sta SCRN+8*40,x  : sta SCRN+9*40,x  : sta SCRN+10*40,x
         sta SCRN+11*40,x : sta SCRN+12*40,x
         sta SCRN+13*40,x : sta SCRN+14*40,x : sta SCRN+15*40,x
         sta SCRN+16*40,x : sta SCRN+17*40,x : sta SCRN+18*40,x
         sta SCRN+19*40,x : sta SCRN+20*40,x
    inx : cpx #39 : bne .hk_cc1
    rts

.hk_clr_count:
    lda #32 : ldx #1
.hk_cco: sta SCRN+16*40,x : sta SCRN+17*40,x : sta SCRN+18*40,x
         sta SCRN+19*40,x : sta SCRN+20*40,x
    inx : cpx #39 : bne .hk_cco : rts

.wait_1sec:
    lda #50
.hk_wt: pha
.w_r1: lda RASTER : cmp #$F0 : bne .w_r1
.w_r2: lda RASTER : cmp #$F0 : beq .w_r2
    
    jsr $1006      

    sei
    lda #$FF : sta $DC02 
    lda #$00 : sta $DC03 
    lda #$FE : sta $DC00 
    lda $DC01 : sta HK_KEY_MAT
    lda #$00 : sta $DC00 
    cli

    lda HK_KEY_MAT
    and #$78
    cmp #$78
    beq .hk_wt_rel

    lda HK_KEY_LOCK
    bne .hk_nk

    lda #1 : sta HK_KEY_LOCK

    lda HK_KEY_MAT : and #$10 : beq .hk_do_res  
    lda HK_KEY_MAT : and #$08 : beq .hk_do_ext  
    lda HK_KEY_MAT : and #$20 : beq .hk_do_var  
    lda HK_KEY_MAT : and #$40 : beq .hk_do_var  
    jmp .hk_nk

.hk_wt_rel:
    lda #0 : sta HK_KEY_LOCK
    jmp .hk_nk
    
.hk_do_res: lda #1 : sta HK_RESTART : pla : rts
.hk_do_var: lda HK_VARIANT : eor #1 : sta HK_VARIANT : lda #1 : sta HK_RESTART : pla : rts
.hk_do_ext: lda #$FF : sta HK_RESTART : jsr .hk_cleanup : pla : rts

.hk_nk:
    pla : sec : sbc #1 : bne .hk_wt
    rts

; ==========================================
; DISEGNO GRAFICA E MURI BLU
; ==========================================
HK_draw_boundary:
    ldx #38
.drb_lp:
    lda #BRD_HLINE : sta SCRN+0*40,x  : sta SCRN+24*40,x
    lda #6   : sta COLRAM+0*40,x : sta COLRAM+24*40,x
    dex : bpl .drb_lp
    
    lda #BRD_TR : sta SCRN+0*40+39  : lda #6 : sta COLRAM+0*40+39
    lda #BRD_BR : sta SCRN+24*40+39 : lda #6 : sta COLRAM+24*40+39
    lda #BRD_BL : sta SCRN+0*40+0   : lda #6 : sta COLRAM+0*40+0
    lda #BRD_TL : sta SCRN+24*40+0  : lda #6 : sta COLRAM+24*40+0
    
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
    ldy #0  : lda #6 : sta ($FD),y
    ldy #39 : lda #6 : sta ($FD),y
.bl_next:
    inx : cpx #24 : bcc .bl_lp
    rts

HK_draw_scores:
    lda HK_SCORE_P1 : jsr .bin_bcd
    pha : lda HK_TEMP : ldx #8  : ldy #1 : jsr .draw_digit
    pla :               ldx #12 : ldy #1 : jsr .draw_digit
    
    lda HK_SCORE_P2 : jsr .bin_bcd
    pha : lda HK_TEMP : ldx #25 : ldy #1 : jsr .draw_digit
    pla :               ldx #29 : ldy #1 : jsr .draw_digit
    
    ldx #4
.col_sc:
    lda #6
    sta COLRAM+1*40+8,x : sta COLRAM+2*40+8,x : sta COLRAM+3*40+8,x : sta COLRAM+4*40+8,x : sta COLRAM+5*40+8,x
    sta COLRAM+1*40+12,x : sta COLRAM+2*40+12,x : sta COLRAM+3*40+12,x : sta COLRAM+4*40+12,x : sta COLRAM+5*40+12,x
    sta COLRAM+1*40+25,x : sta COLRAM+2*40+25,x : sta COLRAM+3*40+25,x : sta COLRAM+4*40+25,x : sta COLRAM+5*40+25,x
    sta COLRAM+1*40+29,x : sta COLRAM+2*40+29,x : sta COLRAM+3*40+29,x : sta COLRAM+4*40+29,x : sta COLRAM+5*40+29,x
    dex : bpl .col_sc
    rts

.bin_bcd:
    ldx #0 : stx HK_TEMP
.bcd_lp: cmp #10 : bcc .bcd_done : sbc #10 : inc HK_TEMP : jmp .bcd_lp
.bcd_done: rts

.draw_digit:
    sta $FD : lda #0 : sta $FC : sta $FB
    tya : beq .add_x
.mul40: clc : lda $FB : adc #40 : sta $FB : bcc .m_ok : inc $FC
.m_ok:  dey : bne .mul40
.add_x: txa : clc : adc $FB : sta $FB : bcc .a_ok : inc $FC
.a_ok:  clc : lda $FC : adc #$04 : sta $FC
    lda $FD : asl : asl : asl : asl : tax : ldy #0
.yl: lda HK_big_num,x : sta ($FB),y : inx : iny
    lda HK_big_num,x : sta ($FB),y : inx : iny
    lda HK_big_num,x : sta ($FB),y : inx
    lda $FB : clc : adc #40 : sta $FB : bcc .y_ok : inc $FC
.y_ok: ldy #0 : txa : and #$0F : cmp #15 : bcc .yl : rts

HK_big_num:
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