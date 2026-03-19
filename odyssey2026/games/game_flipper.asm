; ==========================================
; game_flipper.asm - "Circus / Clowns" (V81 - Inverted Paddle Axis)
; FIX: Invertito l'asse di lettura del Paddle (eor #$FF) per rendere
;      il movimento a schermo coerente con la rotazione fisica.
; ==========================================
* = $7000

!src "assets/odyssey_charset_map.asm"

FP_LIFE_CHAR  = $FE  
FP_LIFE_COLOR = 1    

; --- ZP Flipper (SAFE RANGE $28-$7F) ---
FP_SCORE_L    = $28 : FP_SCORE_H    = $29
FP_SCORE_E1   = $2A : FP_SCORE_E2   = $2B 
FP_LIVES      = $2C : FP_RESTART    = $2D
FP_TEMP       = $2E : FP_SCORE_TMP  = $2F 

FP_PAD_X      = $30 : FP_PAD_X_H    = $31

FP_B1_X       = $33 : FP_B1_X_H     = $34
FP_B1_Y       = $35 : FP_B1_DX      = $36
FP_B1_DY      = $37 : FP_B1_DY_SUB  = $38

FP_STATE      = $3F ; 0=Wall, 1=Bonus
FP_LEVEL      = $40 
FP_TARG_L     = $41 : FP_TARG_H     = $42 
FP_BUMP_X     = $43 : FP_BUMP_Y     = $44 : FP_BUMP_DX = $45 

FP_RLE_CNT    = $46 : FP_RLE_COL    = $47
FP_ROW        = $48 : FP_COL        = $49
FP_LVL_PTR    = $4A

FP_LAST_PAD_X = $4B 
FP_PAD_VEL    = $4C 
FP_CUR_GRAV   = $4D 
FP_TICK       = $4E 

; --- Variabili Power-Up e Multi-Ball ---
FP_PWR_STATE  = $50
FP_PWR_TIME   = $51
FP_PWR_FRAME  = $52
FP_PWR_IDX    = $53
FP_WALL_ACT   = $54
FP_SUPER_BAL  = $55
FP_LARGE_ACT  = $56  

FP_B3_X       = $57 : FP_B3_X_H     = $58 : FP_B3_Y       = $59 
FP_B3_DX      = $5A : FP_B3_DY      = $5B : FP_B3_DYS     = $5C : FP_B3_ACT = $5D
FP_B4_X       = $5E : FP_B4_X_H     = $5F : FP_B4_Y       = $60 
FP_B4_DX      = $61 : FP_B4_DY      = $62 : FP_B4_DYS     = $63 : FP_B4_ACT = $64
FP_MAIN_DEAD  = $65
FP_ALL_LOST_F = $66

; --- Variabili Audio, Cooldown e Tastiera ---
FP_RHYTHM_TICK= $67
FP_RHYTHM_STEP= $68
FP_ZAP_FRAME  = $69
FP_B1_CD      = $6A  
FP_B3_CD      = $6B  
FP_B4_CD      = $6C  
FP_KEY_LOCK   = $70
FP_KEY_MAT    = $71
FP_KEY_MAT_P  = $72
FP_PAUSE_LOCK = $73

; --- Variabili KERNEL Winscreen ---
WIN_COL_S   = $98   
WIN_COL_E   = $99   
WIN_COL_ON  = $9A   
WIN_COL_OFF = $9B 

FP_GRAVITY      = 28  
PWR_DURATION    = 15   
BUMPER_COOLDOWN = 5    
BUMPER_LIFESPAN = 7    

; --- Hardware ---
FP_SP0_X = $D000 : FP_SP0_Y = $D001 ; Extra Ball 1
FP_SP2_X = $D004 : FP_SP2_Y = $D005 ; Pedana sx
FP_SP3_X = $D006 : FP_SP3_Y = $D007 ; Palla 1 (Main)
FP_SP4_X = $D008 : FP_SP4_Y = $D009 ; (Unused)
FP_SP5_X = $D00A : FP_SP5_Y = $D00B ; Bumper Mobile
FP_SP6_X = $D00C : FP_SP6_Y = $D00D ; Pedana dx (per PowerUp L)
FP_SP7_X = $D00E : FP_SP7_Y = $D00F ; Extra Ball 2

FP_MSB_X = $D010 : FP_SPENA = $D015
FP_PTR0  = $07F8 : FP_PTR2  = $07FA : FP_PTR3  = $07FB : FP_PTR4  = $07FC 
FP_PTR5  = $07FD : FP_PTR6  = $07FE : FP_PTR7  = $07FF

FP_PAD_STATE_0 = 48 
FP_BALL_BLK    = 50 
FP_BUMP_NORM   = 51
FP_PAD_LARGE   = 57

FP_COL_LVL1 = 1 ; Bianco
FP_COL_LVL2 = 7 ; Giallo
FP_COL_LVL3 = 2 ; Rosso

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
; PUNTO DI INGRESSO ASSOLUTO
; ==========================================
Flipper:
    sei                     
    lda #0 : sta FP_RESTART : sta FP_KEY_LOCK : sta FP_PAUSE_LOCK          
    
FP_restart_trampoline:
    lda #0 : sta $C6 
    sta FP_SCORE_L : sta FP_SCORE_H 
    sta FP_SCORE_E1 : sta FP_SCORE_E2
    sta FP_RESTART : sta FP_STATE
    sta FP_TICK : sta FP_WALL_ACT : sta FP_SUPER_BAL : sta FP_LARGE_ACT
    
    sta FP_ZAP_FRAME : sta FP_RHYTHM_STEP
    lda #20 : sta FP_RHYTHM_TICK 
    
    lda #5 : sta FP_LIVES   
    lda #1 : sta FP_LEVEL

    jsr FP_InitGame         

    lda FP_RESTART : cmp #1 : beq FP_restart_trampoline 
    rts                     

!zone game_flipper {

; ==========================================
FP_InitGame:
    lda $D011 : and #$EF : sta $D011   
    lda #14 : sta $D021 : sta $D020    
    lda #$1E : sta $D018               
    lda #14 : jsr FillColorRAM         
    jsr ClearScreen 

    jsr .draw_boundary
    jsr .draw_scores
    jsr FP_update_lives
    
    jsr .init_sprites
    
    jsr InitSFX 
    
    lda #1 : sta $CC      
    lda $D011 : ora #$10 : sta $D011   

    lda #128 : sta FP_BUMP_X : lda #130 : sta FP_BUMP_Y : lda #1 : sta FP_BUMP_DX
    jsr .spawn_wall_targets

    jsr .launch_initial
    
    jsr FP_countdown
    lda FP_RESTART : beq .fp_init_end
    rts 
    
.fp_init_end:
    lda #128 : sta FP_BUMP_X : lda #130 : sta FP_BUMP_Y : lda #1 : sta FP_BUMP_DX
    lda #0 : sta FP_STATE
    lda #6 : sta FP_TARG_L : lda #0 : sta FP_TARG_H

    jsr .launch_initial

    lda #$0A : sta $D405 : lda #$00 : sta $D406 
    lda #$09 : sta $D40C : lda #$00 : sta $D40D 
    
    lda #0 : sta $C6 

; ==========================================
; GAME LOOP E INPUT
; ==========================================
.g_loop:
.wt1: lda RASTER : cmp #$F0 : bne .wt1
.wt2: lda RASTER : cmp #$F0 : beq .wt2
    
    jsr .read_paddle
    jsr .update_paddle_anim
    
    jsr .handle_powerup_timer
    jsr .move_bumper
    
    inc FP_TICK
    lda FP_TICK : and #$03 : bne .sk_grav_upd 
    lda FP_CUR_GRAV : cmp #10 : bcc .sk_grav_upd 
    dec FP_CUR_GRAV
.sk_grav_upd:

    jsr .check_grid_col  
    jsr .apply_physics
    jsr .sync_sprites
    
    jsr UpdateSFX           
    jsr FP_Audio_Update     

    lda FP_RESTART : beq .continue_loop
    jmp .loop_exit
.continue_loop:

    ; ==========================================
    ; TASTIERA BARE METAL CON DEBOUNCE DOPPIO (F-KEYS & P)
    ; ==========================================
    sei
    lda #$FF : sta $DC02 
    lda #$00 : sta $DC03 
    
    lda #$FE : sta $DC00 
    lda $DC01 : sta FP_KEY_MAT  
    
    lda #$BF : sta $DC00
    lda $DC01 : sta FP_KEY_MAT_P
    
    lda #$00 : sta $DC00 
    cli

    ; --- Debounce F-Keys ---
    lda FP_KEY_MAT
    and #$18       
    cmp #$18
    beq .f_keys_released

    lda FP_KEY_LOCK
    bne .check_p

    lda #1 : sta FP_KEY_LOCK

    lda FP_KEY_MAT : and #$10 : beq .req_rst
    lda FP_KEY_MAT : and #$08 : beq .req_ext
    jmp .check_p

.f_keys_released:
    lda #0 : sta FP_KEY_LOCK

.check_p:
    ; --- Debounce Tasto 'P' ---
    lda FP_KEY_MAT_P
    and #$02       
    bne .p_released

    lda FP_PAUSE_LOCK
    bne .end_input

    lda #1 : sta FP_PAUSE_LOCK
    jmp .req_pause

.p_released:
    lda #0 : sta FP_PAUSE_LOCK

.end_input:
    jmp .g_loop

.req_rst:
    lda #1 : sta FP_RESTART : rts
.req_ext:
    lda #$FF : sta FP_RESTART : jsr .fp_cleanup : rts

; --- GESTIONE PAUSA ---
.req_pause:
    lda #$10 : sta SCRN+12*40+17 : lda #1 : sta COLRAM+12*40+17
    lda #$01 : sta SCRN+12*40+18 : lda #1 : sta COLRAM+12*40+18
    lda #$15 : sta SCRN+12*40+19 : lda #1 : sta COLRAM+12*40+19
    lda #$13 : sta SCRN+12*40+20 : lda #1 : sta COLRAM+12*40+20
    lda #$01 : sta SCRN+12*40+21 : lda #1 : sta COLRAM+12*40+21

.p_pause_loop:
.wtp1: lda RASTER : cmp #$F0 : bne .wtp1
.wtp2: lda RASTER : cmp #$F0 : beq .wtp2

    sei
    lda #$FF : sta $DC02
    lda #$00 : sta $DC03
    lda #$BF : sta $DC00
    lda $DC01 : sta FP_KEY_MAT_P
    lda #$00 : sta $DC00
    cli

    lda FP_KEY_MAT_P
    and #$02
    bne .p_pause_rel

    lda FP_PAUSE_LOCK
    bne .p_pause_loop

    lda #1 : sta FP_PAUSE_LOCK
    jmp .unpause

.p_pause_rel:
    lda #0 : sta FP_PAUSE_LOCK
    jmp .p_pause_loop

.unpause:
    lda #$20
    sta SCRN+12*40+17 : sta SCRN+12*40+18 : sta SCRN+12*40+19
    sta SCRN+12*40+20 : sta SCRN+12*40+21
    jmp .g_loop

.loop_exit:
    rts

.fp_cleanup:
    lda #0 : sta FP_SPENA : sta $D010 : sta $D017 : sta $D01D : sta $D01C 
    lda $D011 : and #$EF : sta $D011
    
    sei
    lda #$FF : sta $DC02   
    lda #$00 : sta $DC03   
    lda #$00 : sta $DC00   
    cli
    lda #0   : sta $C6     
    rts

; ==========================================
; COUNTDOWN KERNEL
; ==========================================
FP_countdown:
    lda #1
    jsr $1000               
    lda #$0F : sta $D418    

    lda #3 : sta FP_TEMP
.cnt_lp:
    jsr .fclr_count
    lda FP_TEMP : ldx #19 : ldy #10 : jsr .draw_digit
    jsr .fwait_1sec
    lda FP_RESTART : bne .fcd_exit 
    dec FP_TEMP : bne .cnt_lp

    jsr .fclr_count
    
    lda #14 : ldx #16 : ldy #10 : jsr .draw_digit 
    lda #0  : ldx #20 : ldy #10 : jsr .draw_digit 
    
    jsr .fwait_1sec
    lda FP_RESTART : bne .fcd_exit
    jsr .fclr_count
.fcd_exit:
    jsr $1003               
    lda #0 : ldx #0
.cl_sid_fp:
    sta $D400,x
    inx : cpx #25 : bne .cl_sid_fp
    lda #$0F : sta $D418    
    rts

.fclr_count:
    lda #32 : ldx #12
.fccnt_lp:
    sta SCRN+10*40,x : sta SCRN+11*40,x : sta SCRN+12*40,x
    sta SCRN+13*40,x : sta SCRN+14*40,x
    pha
    lda #1
    sta COLRAM+10*40,x : sta COLRAM+11*40,x : sta COLRAM+12*40,x
    sta COLRAM+13*40,x : sta COLRAM+14*40,x
    pla
    inx : cpx #28 : bne .fccnt_lp : rts

.fwait_1sec:
    lda #50
.fwt_frame: 
    pha
.fw_r1: lda RASTER : cmp #$F0 : bne .fw_r1
.fw_r2: lda RASTER : cmp #$F0 : beq .fw_r2

    jsr $1006               
    
    sei
    lda #$FF : sta $DC02 
    lda #$00 : sta $DC03 
    lda #$FE : sta $DC00 
    lda $DC01 : sta FP_KEY_MAT
    lda #$00 : sta $DC00 
    cli
    
    lda FP_KEY_MAT
    and #$18
    cmp #$18
    beq .fwt_released

    lda FP_KEY_LOCK
    bne .fwt_next

    lda #1 : sta FP_KEY_LOCK
    
    lda FP_KEY_MAT : and #$10 : beq .fwda       
    lda FP_KEY_MAT : and #$08 : beq .fw_f7      
    jmp .fwt_next

.fwt_released:
    lda #0 : sta FP_KEY_LOCK
    jmp .fwt_next

.fw_f7:
    lda #$FF : sta FP_RESTART : jsr .fp_cleanup : pla : rts                               

.fwda: 
    lda #1 : sta FP_RESTART : pla : rts                        

.fwt_next:
    pla 
    sec : sbc #1 : beq .fwt_done
    jmp .fwt_frame
.fwt_done:
    rts

; ==========================================
; MOTORE AUDIO BEAMRIDER E HEARTBEAT
; ==========================================
FP_Audio_Update:
    lda FP_ZAP_FRAME
    beq .zap_off
    asl : clc : adc #$15  
    sta $D401             
    lda #$00 : sta $D400  
    lda #$21 : sta $D404  
    dec FP_ZAP_FRAME
    jmp .rhythm_upd
.zap_off:
    lda #$20 : sta $D404  

.rhythm_upd:
    dec FP_RHYTHM_TICK
    bne .aud_end
    
    inc FP_RHYTHM_STEP
    lda FP_RHYTHM_STEP
    and #$03
    sta FP_RHYTHM_STEP

    cmp #0 : beq .beat_1
    cmp #1 : beq .beat_rest_1
    cmp #2 : beq .beat_2
    
.beat_rest_2:
    lda #35 : sta FP_RHYTHM_TICK
    lda #$10 : sta $D40B 
    rts
    
.beat_1:
    lda #12 : sta FP_RHYTHM_TICK
    lda #$0C : sta $D408 : lda #$00 : sta $D407 
    lda #$11 : sta $D40B 
    rts

.beat_rest_1:
    lda #8 : sta FP_RHYTHM_TICK
    lda #$10 : sta $D40B 
    rts

.beat_2:
    lda #12 : sta FP_RHYTHM_TICK
    lda #$09 : sta $D408 : lda #$00 : sta $D407 
    lda #$11 : sta $D40B 
.aud_end:
    rts

; ==========================================
; TIMER POWER-UP E BUMPER CENTRALE
; ==========================================
.handle_powerup_timer:
    lda FP_STATE
    beq .ht_reset_all 
    dec FP_PWR_FRAME
    beq .ht_tick
    rts
.ht_tick:
    lda #50 : sta FP_PWR_FRAME
    dec FP_PWR_TIME
    lda FP_PWR_TIME
    beq .ht_transition
    rts
.ht_transition:
    lda FP_PWR_STATE
    cmp #0 : beq .from_visible
    cmp #1 : beq .from_cooldown
    jmp .from_powerup         
.from_visible:
    lda #1 : sta FP_PWR_STATE
    lda #BUMPER_COOLDOWN : sta FP_PWR_TIME
    jsr .hide_bumper
    rts
.from_cooldown:
    lda #0 : sta FP_PWR_STATE
    lda #BUMPER_LIFESPAN : sta FP_PWR_TIME
    jsr .spawn_powerup_bumper
    rts
.from_powerup:
    jsr .revert_powerups
    lda #1 : sta FP_PWR_STATE
    lda #BUMPER_COOLDOWN : sta FP_PWR_TIME
    jsr .hide_bumper
    rts
.ht_reset_all:
    jsr .revert_powerups
    lda #0 : sta FP_PWR_STATE
    rts

.spawn_powerup_bumper:
    lda FP_TICK
    eor FP_PAD_X
    eor FP_B1_X
    and #$1F : tax 
    lda FP_rnd_table,x : sta FP_PWR_IDX
    tax
    lda FP_bump_colors,x : sta $D02C
    lda FP_bump_sprites,x : sta FP_PTR5
    lda #130 : sta FP_BUMP_Y 
    rts

.hide_bumper:
    lda #0 : sta FP_BUMP_Y : rts

.revert_powerups:
    lda #0 : sta FP_LARGE_ACT
    lda $D01D : and #%10111111 : sta $D01D
    
    lda #0 : sta FP_SUPER_BAL
    jsr .clear_safety_wall
    lda #0 : sta FP_WALL_ACT
    
    lda FP_B3_ACT : ora FP_B4_ACT : bne .rev_col_cyan
    lda #1 : jmp .rev_col_apply
.rev_col_cyan:
    lda #3
.rev_col_apply:
    sta $D02A : sta $D027 : sta $D02E
    rts

; ==========================================
; LETTURA PADDLE E INERZIA (INVERTITA)
; ==========================================
.read_paddle:
    lda FP_PAD_X : sta FP_LAST_PAD_X 

    sei : lda #%01000000 : sta $DC00 : ldy #$60
.pr_lp: dey : bne .pr_lp
    lda $D419 : sta $02 
    lda #$FF : sta $DC02 : lda #$00 : sta $DC00 
    cli
    
    ; --- INVERSIONE DELL'ASSE DEL PADDLE ---
    lda $02 
    eor #$FF                  ; Inverte il valore (0 diventa 255, 255 diventa 0)
    clc : adc #32 : sta FP_PAD_X
    lda #0  : adc #0  : sta FP_PAD_X_H
    lda #234 : sta FP_SP2_Y

    lda FP_PAD_X : sec : sbc FP_LAST_PAD_X : sta FP_PAD_VEL
    rts

; ==========================================
; ANIMAZIONE PEDANA MEGA E NORMALE
; ==========================================
.update_paddle_anim:
    lda FP_LARGE_ACT
    beq .normal_anim
    lda #FP_PAD_LARGE : sta FP_PTR2 : sta FP_PTR6
    rts
.normal_anim:
    lda #FP_PAD_STATE_0 : sta FP_PTR2 
    rts

.move_bumper:
    lda FP_STATE
    bne .mb_powerup_mode
    lda #FP_BUMP_NORM : sta FP_PTR5 
    lda #7  : sta $D02C   
    lda #130 : sta FP_BUMP_Y
    jmp .mb_move
.mb_powerup_mode:
    lda FP_PWR_STATE
    bne .mb_hide_ret
.mb_move:
    lda FP_BUMP_X : clc : adc FP_BUMP_DX : sta FP_BUMP_X
    cmp #40 : bcc .rev_b_dx
    cmp #200 : bcs .rev_b_dx 
    rts
.rev_b_dx:
    lda FP_BUMP_DX : eor #$FF : clc : adc #1 : sta FP_BUMP_DX : rts
.mb_hide_ret:
    rts

; ==========================================
; SISTEMA MAPPE E DISEGNO BUMPER STATICI
; ==========================================
.spawn_wall_targets:
    lda #0 : sta FP_STATE
    lda #6 : sta FP_TARG_L : lda #0 : sta FP_TARG_H

    lda FP_LEVEL : cmp #1 : bne .swt_l2
    lda #FP_COL_LVL1 : jmp .swt_drw
.swt_l2: cmp #2 : bne .swt_l3
    lda #FP_COL_LVL2 : jmp .swt_drw
.swt_l3: lda #FP_COL_LVL3
.swt_drw:
    sta FP_TEMP 
    ldx #0
.swt_lp:
    txa : clc : adc #6 : tay 
    lda ROW_TABLE_LO,y : sta ZP_PTR : lda ROW_TABLE_HI,y : sta ZP_PTR+1
    lda ZP_PTR : sta PRINT_SRC : lda ZP_PTR+1 : clc : adc #$D4 : sta PRINT_SRC+1
    ldy #37 
    lda #$61 : sta (ZP_PTR),y : lda FP_TEMP : sta (PRINT_SRC),y
    inx : cpx #6 : bcc .swt_lp
    
    jsr .revert_powerups
    lda #0 : sta FP_PWR_STATE
    jsr .draw_static_bumpers 
    rts

.spawn_bonus_map:
    lda #1 : sta FP_STATE
    lda #0 : sta FP_TARG_L : sta FP_TARG_H : sta FP_RLE_CNT
    lda #<LEVEL_DATA : sta FP_LVL_PTR : lda #>LEVEL_DATA : sta FP_LVL_PTR+1
    lda #7 : sta FP_ROW : lda #8 : sta FP_COL 

    lda #1 : sta FP_PWR_STATE
    lda #BUMPER_COOLDOWN : sta FP_PWR_TIME
    lda #50 : sta FP_PWR_FRAME
    jsr .hide_bumper

.sbm_loop:
    lda FP_RLE_CNT : bne .place_b_brick          
    ldy #0 : lda (FP_LVL_PTR),y : inc FP_LVL_PTR : bne .sbm_skp
    inc FP_LVL_PTR+1
.sbm_skp:   
    pha : lsr : lsr : lsr : lsr : clc : adc #1 : sta FP_RLE_CNT 
    pla : and #$0F : sta FP_RLE_COL 
.place_b_brick:
    ldx FP_ROW
    lda ROW_TABLE_LO,x : clc : adc FP_COL : sta ZP_PTR
    lda ROW_TABLE_HI,x : adc #0 : sta ZP_PTR+1
    ldy #0 : lda FP_RLE_COL : beq .empty_b_brick          
    
    cmp #6 : beq .place_draw
    cmp #14 : beq .place_draw
    inc FP_TARG_L : bne .place_draw : inc FP_TARG_H
.place_draw:
    lda #$61 : sta (ZP_PTR),y 
    lda ZP_PTR : sta PRINT_SRC : lda ZP_PTR+1 : clc : adc #$D4 : sta PRINT_SRC+1
    lda FP_RLE_COL : sta (PRINT_SRC),y 
    jmp .next_b_brick
.empty_b_brick:
    lda #$20 : sta (ZP_PTR),y 
.next_b_brick:
    dec FP_RLE_CNT : inc FP_COL : lda FP_COL : cmp #32 : bcc .sbm_loop
    lda #8 : sta FP_COL : inc FP_ROW : lda FP_ROW : cmp #19 : bcc .sbm_loop 
    
    jsr .draw_static_bumpers 
    rts

.draw_static_bumpers:
    ldx #0
.dsb_loop:
    lda FP_dsb_rows,x
    cmp #$FF : beq .dsb_end
    tay
    lda ROW_TABLE_LO,y : sta ZP_PTR
    lda ROW_TABLE_HI,y : sta ZP_PTR+1
    lda ZP_PTR : sta PRINT_SRC : lda ZP_PTR+1 : clc : adc #$D4 : sta PRINT_SRC+1
    ldy FP_dsb_cols,x
    lda #$61 : sta (ZP_PTR),y
    lda #4   : sta (PRINT_SRC),y  
    inx
    jmp .dsb_loop
.dsb_end:
    rts

FP_dsb_rows:
    !byte 2,2,2,  2,2,2,    11,14,17,   13,16,19,  $FF  
FP_dsb_cols:
    !byte 3,6,9,  30,33,36, 2,2,2,      37,37,37

.clear_playfield:
    ldx #6
.cpf_row:
    lda ROW_TABLE_LO,x : sta ZP_PTR
    lda ROW_TABLE_HI,x : sta ZP_PTR+1
    ldy #1
    lda #$20
.cpf_col:
    sta (ZP_PTR),y
    iny
    cpy #39
    bcc .cpf_col
    inx
    cpx #24
    bcc .cpf_row
    jsr .draw_scores     
    jsr FP_update_lives
    rts

.check_level_progression:
    lda FP_TARG_L : ora FP_TARG_H : bne .clp_end
    jsr .clear_playfield
    lda FP_STATE : beq .go_bonus
    inc FP_LEVEL : lda FP_LEVEL : cmp #4 : bcc .ok_lvl
    lda #3 : sta FP_LEVEL
.ok_lvl:
    jsr .spawn_wall_targets : rts
.go_bonus:
    jsr .spawn_bonus_map
.clp_end:
    rts

; ==========================================
; COLLISIONI GRIGLIA E MULTI-PALLA
; ==========================================
.check_grid_col:
    lda FP_MAIN_DEAD : bne .cgc_b3
    lda FP_B1_CD : beq .do_b1_col
    dec FP_B1_CD : jmp .cgc_b3
.do_b1_col:
    lda FP_B1_X : sta $F0 : lda FP_B1_X_H : sta $F1 : lda FP_B1_Y : sta $F2 : lda FP_B1_DX : sta $F3 : lda FP_B1_DY : sta $F4
    lda #0 : sta $F5
    jsr .do_grid_col
    lda $F3 : sta FP_B1_DX : lda $F4 : sta FP_B1_DY : lda $F2 : sta FP_B1_Y
    lda $F5 : sta FP_B1_CD

.cgc_b3:
    lda FP_B3_ACT : beq .cgc_b4
    lda FP_B3_CD : beq .do_b3_col
    dec FP_B3_CD : jmp .cgc_b4
.do_b3_col:
    lda FP_B3_X : sta $F0 : lda FP_B3_X_H : sta $F1 : lda FP_B3_Y : sta $F2 : lda FP_B3_DX : sta $F3 : lda FP_B3_DY : sta $F4
    lda #0 : sta $F5
    jsr .do_grid_col
    lda $F3 : sta FP_B3_DX : lda $F4 : sta FP_B3_DY : lda $F2 : sta FP_B3_Y
    lda $F5 : sta FP_B3_CD

.cgc_b4:
    lda FP_B4_ACT : beq .cgc_end
    lda FP_B4_CD : beq .do_b4_col
    dec FP_B4_CD : jmp .cgc_end
.do_b4_col:
    lda FP_B4_X : sta $F0 : lda FP_B4_X_H : sta $F1 : lda FP_B4_Y : sta $F2 : lda FP_B4_DX : sta $F3 : lda FP_B4_DY : sta $F4
    lda #0 : sta $F5
    jsr .do_grid_col
    lda $F3 : sta FP_B4_DX : lda $F4 : sta FP_B4_DY : lda $F2 : sta FP_B4_Y
    lda $F5 : sta FP_B4_CD

.cgc_end:
    rts

.do_grid_col:
    lda $F1 : bne .chk_blocks 
    
    lda FP_STATE : beq .bump_col_active  
    lda FP_PWR_STATE : bne .chk_blocks  
.bump_col_active:
    lda $F0 : clc : adc #7 : cmp FP_BUMP_X : bcc .chk_blocks
    lda FP_BUMP_X : clc : adc #24 : cmp $F0 : bcc .chk_blocks
    
    lda $F2 : clc : adc #7 : cmp FP_BUMP_Y : bcc .chk_blocks
    lda FP_BUMP_Y : clc : adc #9 : cmp $F2 : bcc .chk_blocks
    
    lda #SFX_PAD : jsr PlaySFX
    lda #$30 : jsr .add_score

    lda FP_STATE : beq .bump_bounce_only  
    lda FP_PWR_STATE : bne .bump_bounce_only  
    
    jsr .bump_bounce_only
    jsr .apply_bonus       
    lda #0 : sta FP_BUMP_Y
    jmp .skip_grid
    
.bump_bounce_only:
    lda #32 : sta FP_CUR_GRAV 
    
    lda $F4 : bmi .hit_from_bottom
.hit_from_top:
    lda FP_BUMP_Y : sec : sbc #4 : sta $F2 
    lda #$FA : sta $F4  
    jmp .bump_bounce_x
.hit_from_bottom:
    lda FP_BUMP_Y : clc : adc #9 : sta $F2
    lda #$04 : sta $F4  
.bump_bounce_x:    
    lda FP_BUMP_X : clc : adc #12 : cmp $F0 : bcc .bump_hl
    lda #3 : sta $F3 : rts 
.bump_hl:
    lda #$FD : sta $F3 : rts

.chk_blocks:
    lda $F2 : ldx $F4 : bmi .sy_u
.sy_d: clc : adc #6 : jmp .sy_di
.sy_u: sec : sbc #2
.sy_di: sec : sbc #50 : lsr : lsr : lsr : sta FP_ROW
    
    lda FP_ROW : cmp #24 : bcc .ok_row
    jmp .skip_grid
.ok_row:
    
    lda $F0 : ldx $F3 : bmi .sx_l
.sx_r: clc : adc #6 : bcc .sx_di : inc $F1 : jmp .sx_di
.sx_l: sec : sbc #2 : bcs .sx_di : dec $F1
.sx_di: sec : sbc #24 : sta FP_COL : lda $F1 : sbc #0
    lsr : lda FP_COL : ror : lsr : lsr : sta FP_COL
    
    lda FP_COL : cmp #39 : bcc .ok_col
    jmp .skip_grid
.ok_col:
    
    ldx FP_ROW
    lda ROW_TABLE_LO,x : clc : adc FP_COL : sta ZP_PTR
    lda ROW_TABLE_HI,x : adc #0 : sta ZP_PTR+1
    
    ldy #0 : lda (ZP_PTR),y : cmp #$61 : beq .hit_brick
    jmp .skip_grid
.hit_brick:
    lda #0 : sta FP_TEMP 
    jsr .process_hit 
    
    lda FP_TEMP : bne .force_bounce
    lda FP_SUPER_BAL : beq .force_bounce
    jmp .skip_grid
.force_bounce:
    lda $F4 : eor #$FF : clc : adc #1 : sta $F4
    lda $F3 : eor #$FF : clc : adc #1 : sta $F3
    lda #14 : sta $F5    
.skip_grid:
    rts

; --- ESECUZIONE POWER-UP ---
.apply_bonus:
    lda #SFX_POWERUP : jsr PlaySFX
    lda FP_PWR_IDX
    cmp #3 : beq .apply_instant 

    lda #2 : sta FP_PWR_STATE
    lda #PWR_DURATION : sta FP_PWR_TIME
    lda #50 : sta FP_PWR_FRAME
    
    lda FP_PWR_IDX
    cmp #0 : beq .do_multiball
    cmp #1 : beq .do_large
    cmp #2 : beq .do_wall
    jmp .do_killer

.apply_instant:
    lda #1 : sta FP_PWR_STATE
    lda #5 : sta FP_PWR_TIME
    jmp .do_life

.do_multiball:
    lda #3 : sta $D027 : sta $D02A : sta $D02E
    lda #1 : sta FP_B3_ACT : sta FP_B4_ACT
    lda FP_BUMP_X : sta FP_B3_X : sta FP_B4_X
    lda #0 : sta FP_B3_X_H : sta FP_B4_X_H
    lda FP_BUMP_Y : sta FP_B3_Y : sta FP_B4_Y    
    lda #$FE : sta FP_B3_DX
    lda #$02 : sta FP_B4_DX
    lda #$F5 : sta FP_B3_DY : sta FP_B4_DY 
    lda #0 : sta FP_B3_DYS : sta FP_B4_DYS
    rts

.do_large:
    lda #1 : sta FP_LARGE_ACT
    rts

.do_wall:
    lda #1 : sta FP_WALL_ACT 
    lda #<$0798 : sta $FB : lda #>$0798 : sta $FC 
    lda #<$DB98 : sta $FD : lda #>$DB98 : sta $FE
    ldy #1
.dw_lp:
    lda #$61 : sta ($FB),y 
    lda #15  : sta ($FD),y  
    iny : cpy #39 : bne .dw_lp 
    rts

.clear_safety_wall:
    lda #<$0798 : sta $FB : lda #>$0798 : sta $FC
    ldy #1
.cw_lp:
    lda #$20 : sta ($FB),y
    iny : cpy #39 : bne .cw_lp
    rts

.do_life:
    inc FP_LIVES : jsr FP_update_lives : rts

.do_killer:
    lda #1 : sta FP_SUPER_BAL 
    lda #2 : sta $D027 : sta $D02A : sta $D02E
    rts

; --- PROCESSO DI HIT E NUOVO SCORE MOTORE ---
.process_hit:
    lda ZP_PTR : sta PRINT_SRC : lda ZP_PTR+1 : clc : adc #$D4 : sta PRINT_SRC+1
    lda (PRINT_SRC),y : and #$0F
    
    cmp #6 : beq .ph_wall
    cmp #14 : beq .ph_wall
    cmp #4  : beq .ph_static_bump 
    
    ldx FP_SUPER_BAL : bne .ph_destroy 
    
    cmp #15 : beq .to_white
    cmp #12 : beq .to_white
    jmp .ph_destroy

.to_white:
    lda #1 : sta (PRINT_SRC),y : jmp .ph_sfx

.ph_wall:
    lda #1 : sta FP_TEMP 
    lda #SFX_WALL : jsr PlaySFX
    rts

.ph_static_bump:
    lda #1 : sta FP_TEMP 
    lda #15 : sta FP_ZAP_FRAME 
    lda #SFX_PAD : jsr PlaySFX
    lda #32 : sta FP_CUR_GRAV 
    
    lda FP_ROW : cmp #9 : bcc .dsb_top
.dsb_side:
    lda #$20 : jsr .add_score
    rts
.dsb_top:
    lda #$10 : jsr .add_score 
    rts

.ph_destroy:
    lda #$20 : sta (ZP_PTR),y 
    lda FP_TARG_L : bne .ph_skp : dec FP_TARG_H 
.ph_skp:
    dec FP_TARG_L
    jsr .inc_score 
    jsr .check_level_progression
.ph_sfx:
    lda #SFX_POWERUP : jsr PlaySFX 
    rts

.inc_score:
    lda FP_STATE : bne .score_bonus
.score_wall:
    lda FP_LEVEL : jmp .add_score
.score_bonus:
    lda FP_LEVEL : asl
    
.add_score:
    sta FP_SCORE_TMP
    sed
    lda FP_SCORE_L : clc : adc FP_SCORE_TMP : sta FP_SCORE_L
    lda FP_SCORE_H : adc #0 : sta FP_SCORE_H
    lda FP_SCORE_E1: adc #0 : sta FP_SCORE_E1
    lda FP_SCORE_E2: adc #0 : sta FP_SCORE_E2
    cld : jsr .draw_scores : rts

; ==========================================
; FISICA MURI LINEARI E SALVATAGGI
; ==========================================
.apply_physics:
    lda #0 : sta FP_ALL_LOST_F
    
    lda FP_MAIN_DEAD : beq .phy_main_alive
    jmp .do_b3_phy
.phy_main_alive:

    lda FP_B1_DY_SUB : clc : adc FP_CUR_GRAV : sta FP_B1_DY_SUB
    lda FP_B1_DY : adc #0 : sta FP_B1_DY
    lda FP_B1_Y : clc : adc FP_B1_DY : sta FP_B1_Y
    lda FP_B1_X : clc : adc FP_B1_DX : sta FP_B1_X
    lda FP_B1_DX : bmi .b1_ndx : lda FP_B1_X_H : adc #0 : sta FP_B1_X_H : jmp .chk_bounds_b1
.b1_ndx:
    lda FP_B1_X_H : adc #$FF : sta FP_B1_X_H
.chk_bounds_b1:
    lda FP_WALL_ACT : beq .not_wall_b1
    lda FP_B1_Y : cmp #234 : bcc .not_wall_b1 
    lda #SFX_WALL : jsr PlaySFX
    lda #$F5 : sta FP_B1_DY 
    jsr .clear_safety_wall
    lda #0 : sta FP_WALL_ACT : jmp .b1_cf
.not_wall_b1:
    lda FP_B1_Y : cmp #54 : bcs .chk_right_wall_b1 
    lda #1 : sta FP_B1_DY : lda #54 : sta FP_B1_Y : lda #SFX_WALL : jsr PlaySFX
.chk_right_wall_b1:
    lda FP_B1_X_H : beq .chk_left_wall_b1 
    lda FP_B1_DX : bpl .do_chk_rw_b1 : jmp .chk_left_wall_b1
.do_chk_rw_b1:
    lda FP_B1_X : cmp #68 : bcc .b1_cf
    lda #68 : sta FP_B1_X : lda FP_B1_DX : eor #$FF : clc : adc #1 : sta FP_B1_DX : lda #SFX_WALL : jsr PlaySFX : jmp .b1_cf
.chk_left_wall_b1:
    lda FP_B1_X_H : bne .b1_cf 
    lda FP_B1_X : cmp #16 : bcs .b1_cf
    lda #16 : sta FP_B1_X : lda FP_B1_DX : eor #$FF : clc : adc #1 : sta FP_B1_DX : lda #SFX_WALL : jsr PlaySFX 
.b1_cf:
    lda FP_B1_Y : cmp #230 : bcc .b1_phy_end : lda FP_B1_DY : bmi .b1_phy_end            
    jmp .check_paddle_catch
.b1_phy_end:
    jmp .do_b3_phy

.do_b3_phy:
    lda FP_B3_ACT : bne .b3_is_active
    jmp .do_b4_phy
.b3_is_active:
    lda FP_B3_DYS : clc : adc FP_CUR_GRAV : sta FP_B3_DYS
    lda FP_B3_DY : adc #0 : sta FP_B3_DY
    lda FP_B3_Y : clc : adc FP_B3_DY : sta FP_B3_Y
    lda FP_B3_X : clc : adc FP_B3_DX : sta FP_B3_X
    lda FP_B3_DX : bmi .b3_ndx : lda FP_B3_X_H : adc #0 : sta FP_B3_X_H : jmp .b3_chk_b
.b3_ndx: lda FP_B3_X_H : adc #$FF : sta FP_B3_X_H
.b3_chk_b:
    lda FP_WALL_ACT : beq .b3_nw
    lda FP_B3_Y : cmp #234 : bcc .b3_nw
    lda #SFX_WALL : jsr PlaySFX
    lda #$F5 : sta FP_B3_DY : jsr .clear_safety_wall
    lda #0 : sta FP_WALL_ACT : jmp .b3_cf
.b3_nw:
    lda FP_B3_Y : cmp #54 : bcs .b3_rw
    lda #1 : sta FP_B3_DY : lda #54 : sta FP_B3_Y : lda #SFX_WALL : jsr PlaySFX
.b3_rw:
    lda FP_B3_X_H : beq .b3_lw
    lda FP_B3_DX : bpl .b3_drw : jmp .b3_lw
.b3_drw:
    lda FP_B3_X : cmp #68 : bcc .b3_cf
    lda #68 : sta FP_B3_X : lda FP_B3_DX : eor #$FF : clc : adc #1 : sta FP_B3_DX : lda #SFX_WALL : jsr PlaySFX : jmp .b3_cf
.b3_lw:
    lda FP_B3_X_H : bne .b3_cf
    lda FP_B3_X : cmp #16 : bcs .b3_cf
    lda #16 : sta FP_B3_X : lda FP_B3_DX : eor #$FF : clc : adc #1 : sta FP_B3_DX : lda #SFX_WALL : jsr PlaySFX
.b3_cf:
    lda FP_B3_Y : cmp #245 : bcc .b3_pad
    lda #0 : sta FP_B3_ACT
    lda FP_B3_X : sta $FC : lda FP_B3_X_H : sta $FD
    jsr .check_all_balls_lost
    jmp .do_b4_phy
.b3_pad:
    lda FP_B3_Y : cmp #228 : bcc .b3_jmp_b4 : cmp #240 : bcs .b3_jmp_b4
    lda FP_B3_X : clc : adc #12 : sta FP_TEMP : lda FP_B3_X_H : adc #0 : sta FP_TEMP+1
    lda FP_TEMP : sec : sbc FP_PAD_X : sta FP_TEMP : lda FP_TEMP+1 : sbc FP_PAD_X_H
    beq .b3_hit
    lda FP_LARGE_ACT : bne .b3_l
    lda FP_TEMP : cmp #56 : bcs .b3_jmp_b4 : jmp .b3_hit
.b3_l: lda FP_TEMP : cmp #104 : bcs .b3_jmp_b4
.b3_hit:
    lda #$F5 : sta FP_B3_DY : lda #0 : sta FP_B3_DYS : lda #SFX_PAD : jsr PlaySFX
.b3_jmp_b4:
    jmp .do_b4_phy

.do_b4_phy:
    lda FP_B4_ACT : bne .b4_is_active
    jmp .check_loss_trigger
.b4_is_active:
    lda FP_B4_DYS : clc : adc FP_CUR_GRAV : sta FP_B4_DYS
    lda FP_B4_DY : adc #0 : sta FP_B4_DY
    lda FP_B4_Y : clc : adc FP_B4_DY : sta FP_B4_Y
    lda FP_B4_X : clc : adc FP_B4_DX : sta FP_B4_X
    lda FP_B4_DX : bmi .b4_ndx : lda FP_B4_X_H : adc #0 : sta FP_B4_X_H : jmp .b4_chk_b
.b4_ndx: lda FP_B4_X_H : adc #$FF : sta FP_B4_X_H
.b4_chk_b:
    lda FP_WALL_ACT : beq .b4_nw
    lda FP_B4_Y : cmp #234 : bcc .b4_nw
    lda #SFX_WALL : jsr PlaySFX
    lda #$F5 : sta FP_B4_DY : jsr .clear_safety_wall
    lda #0 : sta FP_WALL_ACT : jmp .b4_cf
.b4_nw:
    lda FP_B4_Y : cmp #54 : bcs .b4_rw
    lda #1 : sta FP_B4_DY : lda #54 : sta FP_B4_Y : lda #SFX_WALL : jsr PlaySFX
.b4_rw:
    lda FP_B4_X_H : beq .b4_lw
    lda FP_B4_DX : bpl .b4_drw : jmp .b4_lw
.b4_drw:
    lda FP_B4_X : cmp #68 : bcc .b4_cf
    lda #68 : sta FP_B4_X : lda FP_B4_DX : eor #$FF : clc : adc #1 : sta FP_B4_DX : lda #SFX_WALL : jsr PlaySFX : jmp .b4_cf
.b4_lw:
    lda FP_B4_X_H : bne .b4_cf
    lda FP_B4_X : cmp #16 : bcs .b4_cf
    lda #16 : sta FP_B4_X : lda FP_B4_DX : eor #$FF : clc : adc #1 : sta FP_B4_DX : lda #SFX_WALL : jsr PlaySFX
.b4_cf:
    lda FP_B4_Y : cmp #245 : bcc .b4_pad
    lda #0 : sta FP_B4_ACT
    lda FP_B4_X : sta $FC : lda FP_B4_X_H : sta $FD
    jsr .check_all_balls_lost
    jmp .check_loss_trigger
.b4_pad:
    lda FP_B4_Y : cmp #228 : bcc .b4_jmp_lt : cmp #240 : bcs .b4_jmp_lt
    lda FP_B4_X : clc : adc #12 : sta FP_TEMP : lda FP_B4_X_H : adc #0 : sta FP_TEMP+1
    lda FP_TEMP : sec : sbc FP_PAD_X : sta FP_TEMP : lda FP_TEMP+1 : sbc FP_PAD_X_H
    beq .b4_hit
    lda FP_LARGE_ACT : bne .b4_l
    lda FP_TEMP : cmp #56 : bcs .b4_jmp_lt : jmp .b4_hit
.b4_l: lda FP_TEMP : cmp #104 : bcs .b4_jmp_lt
.b4_hit:
    lda #$F5 : sta FP_B4_DY : lda #0 : sta FP_B4_DYS : lda #SFX_PAD : jsr PlaySFX
.b4_jmp_lt:
    jmp .check_loss_trigger

.check_loss_trigger:
    lda FP_ALL_LOST_F : beq .phy_exit
    lda #0 : sta FP_ALL_LOST_F
    
    lda $FC : clc : adc #4 : sta EXP_INIT_XL
    lda $FD : adc #0 : sta EXP_INIT_XH
    
    lda EXP_INIT_XH : bne .chk_rb
    lda EXP_INIT_XL : cmp #32 : bcs .chk_rb
    lda #32 : sta EXP_INIT_XL
.chk_rb:
    lda EXP_INIT_XH : beq .cl_ok
    lda EXP_INIT_XL : cmp #64 : bcc .cl_ok
    lda #64 : sta EXP_INIT_XL
.cl_ok:

    lda #230 : sta EXP_INIT_Y
    lda #SFX_LOST : sta EXP_SFX
    lda FP_SPENA : sta EXP_SPENA_AF
    
    lda #%00000000 : sta FP_SPENA : sta $D015 
    jsr DoVerticalExplosion
    
    lda #FP_PAD_STATE_0 : sta FP_PTR2 
    lda #FP_BALL_BLK : sta FP_PTR3 : sta FP_PTR4 : sta FP_PTR0 : sta FP_PTR7
    lda #FP_PAD_LARGE : sta FP_PTR6
    
    lda FP_STATE : bne .skip_bump_rst
    lda #FP_BUMP_NORM : sta FP_PTR5
.skip_bump_rst:
    
    lda #%00111100 : sta FP_SPENA : sta $D015
    dec FP_LIVES : jsr FP_update_lives
    lda FP_LIVES : beq .do_game_over_tr
    jsr .revert_powerups
    jsr .launch_initial
.phy_exit:
    rts

.do_game_over_tr:
    lda #1  : sta <WIN_COL_ON : lda #14 : sta <WIN_COL_OFF
    lda #12 : sta <WIN_COL_S  : lda #28 : sta <WIN_COL_E   
    
    lda #0 : sta $C6 
    jsr DoWinScreen   
    lda #0 : sta $C6 
    
    cmp #$85 : bne .go_f7
    lda #1 : sta FP_RESTART : rts
.go_f7: cmp #$88 : bne .go_replay
    lda #$FF : sta FP_RESTART : jsr .fp_cleanup : rts
.go_replay:
    lda #1 : sta FP_RESTART : rts

; ==========================================
; LOGICA DEL CATCH ED EFFETTO FRUSTA
; ==========================================
.check_paddle_catch:
    lda FP_B1_X : sta $FC : lda FP_B1_X_H : sta $FD : lda FP_B1_Y : sta $FE 

    lda $FC : clc : adc #12 : sta FP_TEMP : lda $FD : adc #0 : sta FP_TEMP+1
    lda FP_TEMP : sec : sbc FP_PAD_X : sta FP_TEMP : lda FP_TEMP+1 : sbc FP_PAD_X_H 
    beq .ch_ok1
    jmp .miss_completely 
.ch_ok1:
    lda FP_LARGE_ACT
    bne .chk_large_width
    lda FP_TEMP : cmp #56 
    bcc .ch_ok2
    jmp .miss_completely 
.chk_large_width:
    lda FP_TEMP : cmp #104 
    bcc .ch_ok2
    jmp .miss_completely

.ch_ok2:
    lda FP_LARGE_ACT
    beq .skip_scale
    lsr FP_TEMP     
.skip_scale:

    ldx FP_TEMP : lda PAD_HIT_DIR,x : sta FP_TEMP 
    
    lda FP_PAD_VEL : cmp #$80 : ror : cmp #$80 : ror 
    clc : adc FP_TEMP
    bmi .chk_neg_clamp
    cmp #7 : bcc .save_fr
    lda #6 : jmp .save_fr
.chk_neg_clamp:
    cmp #$FA : bcs .save_fr
    lda #$FA
.save_fr:
    sta FP_TEMP 
    
    lda #32 : sta FP_CUR_GRAV 

    lda #$F5 : sta FP_B1_DY : lda #0 : sta FP_B1_DY_SUB : lda FP_TEMP : sta FP_B1_DX 
    lda #SFX_PAD : jsr PlaySFX : jmp .do_b3_phy

.miss_completely:
    lda $FE : cmp #245 : bcc .cc_wait 
    
    lda #1 : sta FP_MAIN_DEAD 
    lda #0 : sta FP_SP3_Y 
    jsr .check_all_balls_lost

.cc_wait:
    jmp .do_b3_phy

.check_all_balls_lost:
    lda FP_MAIN_DEAD : beq .cabl_no
    lda FP_B3_ACT : bne .cabl_no
    lda FP_B4_ACT : bne .cabl_no
    lda #1 : sta FP_ALL_LOST_F
.cabl_no:
    rts

; ==========================================
; UTILITIES & TABLES
; ==========================================
PAD_HIT_DIR:
    !byte $FC,$FC,$FC,$FC,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
    !byte $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$02,$02,$02,$02,$02,$02,$02,$02,$03,$03,$03,$03,$03,$03,$03,$03,$04,$04,$04,$04

FP_rnd_table:
    !byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    !byte 1,1,1,1,1,1,1,1,1
    !byte 2,2
    !byte 3
    !byte 4

FP_bump_colors:  !byte 3, 6, 15, 1, 2      
FP_bump_sprites: !byte 52, 53, 54, 55, 56

.launch_initial:
    lda #0 : sta FP_B3_ACT : sta FP_B4_ACT : sta FP_MAIN_DEAD
    sta FP_B1_CD : sta FP_B3_CD : sta FP_B4_CD  
    lda #32 : sta FP_CUR_GRAV
    lda #160 : sta FP_PAD_X : lda #0 : sta FP_PAD_X_H
    
    lda #1 : sta FP_B1_X_H 
    lda #50 : sta FP_B1_X       
    lda #85 : sta FP_B1_Y       
    lda #$02 : sta FP_B1_DY     
    lda #$FE : sta FP_B1_DX     
    lda #0 : sta FP_B1_DY_SUB
    rts

; ==========================================
; HUD VITE IN VERTICALE
; ==========================================
FP_update_lives:
    ldx #4      
.cl_lv:
    lda ROW_TABLE_LO,x : sta $FB
    lda ROW_TABLE_HI,x : sta $FC
    ldy #39
    lda #BRD_VLINE : sta ($FB),y
    inx : inx
    cpx #14
    bcc .cl_lv
    
    lda FP_LIVES
    beq .end_lv
    
    cmp #6            
    bcc .set_temp     
    lda #5            
.set_temp:
    sta FP_TEMP
    
    ldx #4
.dr_lv:
    lda ROW_TABLE_LO,x : sta $FB
    lda ROW_TABLE_HI,x : sta $FC
    ldy #39
    lda #FP_LIFE_CHAR : sta ($FB),y
    inx : inx
    dec FP_TEMP
    bne .dr_lv
.end_lv:
    rts

.sync_sprites:
    lda FP_PAD_X : sta FP_SP2_X 
    lda FP_MAIN_DEAD : bne .ss_b1_sk
    lda FP_B1_X  : sta FP_SP3_X : lda FP_B1_Y : sta FP_SP3_Y
.ss_b1_sk:
    lda FP_BUMP_X: sta FP_SP5_X : lda FP_BUMP_Y : sta FP_SP5_Y
    
    lda #0 : sta $FC
    lda FP_PAD_X_H : beq .no_msb2 : lda $FC : ora #%00000100 : sta $FC
.no_msb2:
    lda FP_MAIN_DEAD : bne .no_msb3
    lda FP_B1_X_H : beq .no_msb3 : lda $FC : ora #%00001000 : sta $FC
.no_msb3:

    lda FP_LARGE_ACT
    beq .skip_sp6_sync
    lda FP_SP2_Y : sta FP_SP6_Y
    lda FP_PAD_X : clc : adc #48 : sta FP_SP6_X
    lda FP_PAD_X_H : adc #0 : beq .no_msb6
    lda $FC : ora #%01000000 : sta $FC
.no_msb6:
.skip_sp6_sync:

    lda FP_B3_ACT : beq .skip_b3_sync
    lda FP_B3_X : sta FP_SP0_X : lda FP_B3_Y : sta FP_SP0_Y
    lda FP_B3_X_H : beq .no_msb0 : lda $FC : ora #%00000001 : sta $FC
.no_msb0:
.skip_b3_sync:

    lda FP_B4_ACT : beq .skip_b4_sync
    lda FP_B4_X : sta FP_SP7_X : lda FP_B4_Y : sta FP_SP7_Y
    lda FP_B4_X_H : beq .no_msb7 : lda $FC : ora #%10000000 : sta $FC
.no_msb7:
.skip_b4_sync:

    lda FP_MSB_X : and #%00100010 : ora $FC : sta FP_MSB_X : sta $D010 

    ; Gestione dinamica SPENA
    lda #%00000100 ; SP2
    
    ldx FP_STATE : beq .spe_bump_on
    ldx FP_PWR_STATE : cpx #1 : beq .spe_bump_off 
.spe_bump_on:
    ora #%00100000 ; SP5
.spe_bump_off:

    ldx FP_MAIN_DEAD : bne .spe_m_d
    ora #%00001000 ; SP3
.spe_m_d:
    ldx FP_LARGE_ACT : beq .spe_l
    ora #%01000000 ; SP6 
.spe_l:
    ldx FP_B3_ACT : beq .spe_b3
    ora #%00000001 ; SP0 
.spe_b3:
    ldx FP_B4_ACT : beq .spe_b4
    ora #%10000000 ; SP7 
.spe_b4:
    sta FP_SPENA : sta $D015

    rts

.init_sprites:
    ldx #0
.cp_sp:
    lda PAD_SPRITE_NORM,x : sta $0C00,x 
    lda BALL_SPRITE,x  : sta $0C80,x : lda BUMPER_SPRITE,x: sta $0CC0,x
    lda PWR_SPRITE_D,x : sta $0D00,x : lda PWR_SPRITE_L,x : sta $0D40,x
    lda PWR_SPRITE_W,x : sta $0D80,x : lda PWR_SPRITE_B,x : sta $0DC0,x
    lda PWR_SPRITE_K,x : sta $0E00,x : lda PAD_SPRITE_LARGE,x : sta $0E40,x
    inx : cpx #64 : bne .cp_sp
    
    lda #FP_PAD_STATE_0 : sta FP_PTR2 
    lda #FP_BALL_BLK : sta FP_PTR3 : sta FP_PTR4 : sta FP_PTR0 : sta FP_PTR7
    lda #FP_BUMP_NORM : sta FP_PTR5
    lda #FP_PAD_LARGE : sta FP_PTR6
    
    lda #1 : sta $D029 : sta $D02D : sta $D02A 
    lda #3 : sta $D027 : sta $D02E             
    lda #15 : sta $D02C                        
    
    lda #0 : sta $D01C : sta $D01B 
    lda #0 : sta $D017 
    
    lda #%00000100 : sta $D01D 
    lda #%00111100 : sta FP_SPENA 
    
    lda #0 : sta $D015
    rts

PAD_SPRITE_NORM: 
    !fill 21, 0
    !byte $FF,$FF,$FF, $FF,$FF,$FF, $FF,$FF,$FF, $FF,$FF,$FF, $FF,$FF,$FF, $FF,$FF,$FF
    !fill 24, 0

BALL_SPRITE:
    !byte $00,$00,$00, $00,$00,$00, $00,$00,$00
    !byte $1F,$C0,$00, $1F,$C0,$00, $1F,$C0,$00, $1F,$C0,$00, $1F,$C0,$00, $1F,$C0,$00, $1F,$C0,$00
    !byte $00,$00,$00, $00,$00,$00, $00,$00,$00, $00,$00,$00, $00,$00,$00, $00,$00,$00
    !byte $00,$00,$00, $00,$00,$00, $00,$00,$00, $00,$00,$00, $00,$00,$00, $00,$00,$00, $00,$00,$00, $00

BUMPER_SPRITE:
    !byte $FF,$FF,$FF,$9A,$41,$EF,$9A,$67
    !byte $E7,$9A,$66,$03,$82,$66,$01,$9A
    !byte $66,$03,$9A,$67,$E7,$9A,$67,$EF
    !byte $FF,$FF,$FF,$00,$00,$00,$00,$00
    !byte $00,$00,$00,$00,$00,$00,$00,$00
    !byte $00,$00,$00,$00,$00,$00,$00,$00
    !byte $00,$00,$00,$00,$00,$00,$00,$00
    !byte $00,$00,$00,$00,$00,$00,$00,$00 
    
PWR_SPRITE_D: 
    !byte $FF,$FF,$FF,$FF,$87,$FF,$FF,$BB
    !byte $FF,$FF,$BB,$FF,$FF,$BB,$FF,$FF
    !byte $BB,$FF,$FF,$87,$FF,$FF,$FF,$FF
    !byte $00,$00,$00,$00,$00,$00,$00,$00
    !byte $00,$00,$00,$00,$00,$00,$00,$00
    !byte $00,$00,$00,$00,$00,$00,$00,$00
    !byte $00,$00,$00,$00,$00,$00,$00,$00
    !byte $00,$00,$00,$00,$00,$00,$00,$00

PWR_SPRITE_L: !byte $FF,$FF,$FF,$FF,$BF,$FF,$FF,$BF,$FF,$FF,$BF,$FF,$FF,$BF,$FF,$FF,$BF,$FF,$FF,$83,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
PWR_SPRITE_W: !byte $FF,$FF,$FF,$FF,$BB,$FF,$FF,$BB,$FF,$FF,$AB,$FF,$FF,$AB,$FF,$FF,$AB,$FF,$FF,$93,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
PWR_SPRITE_B: !byte $FF,$FF,$FF,$FF,$87,$FF,$FF,$BB,$FF,$FF,$BB,$FF,$FF,$87,$FF,$FF,$BB,$FF,$FF,$83,$FF,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
PWR_SPRITE_K: !byte $FF,$FF,$FF,$F6,$DB,$BF,$F6,$DB,$BF,$F1,$DB,$BF,$F6,$DB,$BF,$F6,$DB,$BF,$F6,$D8,$8F,$FF,$FF,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

PAD_SPRITE_LARGE: 
    !fill 21, 0
    !byte $FF,$FF,$FF, $FF,$FF,$FF, $FF,$FF,$FF, $FF,$FF,$FF, $FF,$FF,$FF, $FF,$FF,$FF
    !fill 24, 0

.draw_boundary:
    ldx #38
.dr_top:
    lda #BRD_HLINE : sta SCRN+0*40,x : lda #1 : sta COLRAM+0*40,x : dex : bpl .dr_top
    lda #$70 : sta SCRN+0*40+0 : lda #1 : sta COLRAM+0*40+0
    lda #BRD_TR : sta SCRN+0*40+39 : lda #1 : sta COLRAM+0*40+39
    
    ldx #1
.dr_sides:
    lda ROW_TABLE_LO,x : sta ZP_PTR : lda ROW_TABLE_HI,x : sta ZP_PTR+1
    lda ZP_PTR : sta PRINT_SRC : lda ZP_PTR+1 : clc : adc #$D4 : sta PRINT_SRC+1
    ldy #0 : lda #BRD_VLINE : sta (ZP_PTR),y : lda #1 : sta (PRINT_SRC),y
    ldy #39 : lda #BRD_VLINE : sta (ZP_PTR),y : lda #1 : sta (PRINT_SRC),y
    inx : cpx #25 : bcc .dr_sides
    rts

.draw_scores:
    lda FP_SCORE_H : lsr : lsr : lsr : lsr : ldx #12 : ldy #1 : jsr .draw_digit
    lda FP_SCORE_H : and #$0F : ldx #16 : ldy #1 : jsr .draw_digit
    lda FP_SCORE_L : lsr : lsr : lsr : lsr : ldx #20 : ldy #1 : jsr .draw_digit
    lda FP_SCORE_L : and #$0F : ldx #24 : ldy #1 : jsr .draw_digit
    ldx FP_SCORE_E1 : lda FP_SCORE_E2 : ldy #209 : jsr .draw_prog_digits
    ldx #12
.col_sc:
    lda #1 : sta COLRAM+1*40,x : sta COLRAM+2*40,x : sta COLRAM+3*40,x : sta COLRAM+4*40,x : sta COLRAM+5*40,x
    inx : cpx #28 : bcc .col_sc
    rts

.draw_prog_digits:
    sta FP_TEMP : stx FP_TEMP+1  
    lda FP_TEMP : and #$0F : beq .dp_m_blank : clc : adc #$80 : jmp .dp_m_draw
.dp_m_blank: lda #$20
.dp_m_draw: sta SCRN,y : lda #1 : sta COLRAM,y : iny
    lda FP_TEMP : bne .dp_ht_show : lda FP_TEMP+1 : cmp #$10 : bcc .dp_ht_blank
.dp_ht_show: lda FP_TEMP+1 : lsr : lsr : lsr : lsr : clc : adc #$80 : jmp .dp_ht_draw
.dp_ht_blank: lda #$20
.dp_ht_draw: sta SCRN,y : lda #1 : sta COLRAM,y : iny
    lda FP_TEMP : bne .dp_tt_show : lda FP_TEMP+1 : bne .dp_tt_show
.dp_tt_blank: lda #$20 : jmp .dp_tt_draw
.dp_tt_show: lda FP_TEMP+1 : and #$0F : clc : adc #$80
.dp_tt_draw: sta SCRN,y : lda #1 : sta COLRAM,y : rts

.draw_digit:
    sta FP_TEMP : lda #0 : sta $FC : sta $FB
    tya : beq .add_x
.mul40: clc : lda $FB : adc #40 : sta $FB : bcc .m_ok : inc $FC
.m_ok:  dey : bne .mul40
.add_x: txa : clc : adc $FB : sta $FB : bcc .a_ok : inc $FC
.a_ok:  clc : lda $FC : adc #$04 : sta $FC
    lda FP_TEMP : asl : asl : asl : asl : tax : ldy #0
.yl: lda FP_big_num,x : sta ($FB),y : inx : iny
    lda FP_big_num,x : sta ($FB),y : inx : iny
    lda FP_big_num,x : sta ($FB),y : inx
    lda $FB : clc : adc #40 : sta $FB : bcc .y_ok : inc $FC
.y_ok: ldy #0 : txa : and #$0F : cmp #15 : bcc .yl : rts

FP_big_num:
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

LEVEL_DATA:
    !byte $22,$00,$22,$00,$12,$00,$22,$00,$02,$00,$22,$00
    !byte $02,$10,$02,$20,$02,$00,$02,$00,$02,$10,$02,$20
    !byte $02,$00,$02,$00,$02,$00,$02,$10,$02,$20,$02,$00
    !byte $02,$00,$02,$10,$02,$20,$02,$00,$02,$00,$02,$00
    !byte $02,$10,$27,$00,$07,$00,$07,$00,$07,$10,$07,$20
    !byte $07,$00,$07,$00,$07,$00,$07,$10,$27,$00,$27,$00
    !byte $17,$00,$07,$20,$07,$00,$27,$00,$07,$30,$08,$00
    !byte $08,$20,$08,$10,$08,$20,$08,$00,$08,$00,$08,$00
    !byte $08,$30,$08,$00,$08,$20,$08,$10,$08,$20,$08,$00
    !byte $08,$00,$08,$00,$08,$30,$08,$00,$08,$20,$08,$10
    !byte $08,$20,$08,$00,$08,$00,$08,$00,$08,$30,$08,$00
    !byte $08,$20,$08,$10,$08,$20,$08,$00,$08,$00,$08,$00
    !byte $08,$30,$08,$00,$08,$20,$08,$10,$08,$20,$08,$00
    !byte $08,$00,$08,$00,$08,$10,$28,$00,$08,$20,$08,$10
    !byte $08,$20,$08,$00,$08,$00,$08,$00,$08,$10,$28,$00
    !byte $08,$20,$18,$00,$28,$00,$08,$00,$08,$00,$08,$00
    !byte $28

} ; end zone game_flipper