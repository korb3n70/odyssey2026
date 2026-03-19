; ==========================================
; game_tennis.asm - Tennis / Pong V89 (Bare Metal Debounce Fix)
; FIX: Mantenuta la lettura Bare Metal ($DC00) ma con debounce perfetto!
; FIX: Il KEY_LOCK ora persiste al riavvio. Nessun tasto spara più a raffica.
; FIX: Anche F1 e F7 ora sono protetti dal KEY_LOCK.
; ==========================================
* = $4000

!src "assets/odyssey_charset_map.asm"

; --- ZP Tennis ---
TN_BALL_X_L = $62 : TN_BALL_X_H = $63
TN_BALL_Y   = $64 : TN_BALL_DX  = $65 : TN_BALL_DY = $66
TN_SCORE_P1 = $67 : TN_SCORE_P2 = $68 : TN_TEMP_VAL = $69
TN_LAST_WIN = $6B : TN_HITS     = $6C : TN_CUR_SPD  = $6D
TN_VARIANT  = $6E : TN_PAD_H    = $6F : TN_PAD_LIM  = $70
TN_START_S  = $71 : TN_MAX_S    = $72 : TN_PAD_MY   = $73
TN_RESTART  = $74 : TN_AI_OFFSET= $75
TN_KEY_LOCK = $76   
TN_KEY_MAT  = $77   

; --- VIC sprites ---
TN_SP2_X = $D004 : TN_SP2_Y = $D005 
TN_SP3_X = $D006 : TN_SP3_Y = $D007 
TN_SP4_X = $D008 : TN_SP4_Y = $D009  
TN_SP5_X = $D00A : TN_SP5_Y = $D00B 
TN_SP6_X = $D00C : TN_SP6_Y = $D00D 
TN_SP7_X = $D00E : TN_SP7_Y = $D00F 

TN_MSB_X = $D010 : TN_SPENA = $D015
TN_PTR2  = $07FA : TN_PTR3  = $07FB 
TN_PTR4  = $07FC : TN_PTR5  = $07FD
TN_PTR6  = $07FE : TN_PTR7  = $07FF

TN_PAD_BLK   = 13   
TN_BALL_BLK  = 14   
TN_PAD_W     = %11110000

TN_SPEED_STEPS = 5

TN_tab_pad_h:   !byte 42, 42, 24, 16, 42  
TN_tab_pad_lim: !byte 63, 63, 36, 24, 63  
TN_tab_start_s: !byte  2,  4,  2,  4,  2  
TN_tab_max_s:   !byte  9,  9,  9,  9,  9  

; Variabili KERNEL Esplosione
EXP_INIT_XL   = $92
EXP_INIT_XH   = $93
EXP_INIT_Y    = $94
EXP_SFX       = $95
EXP_SPENA_AF  = $96
EXP_PTR4_AF   = $97
EXP_DIR       = $98 

Tennis:
    ; Inizializza KEY_LOCK solo qui, al primissimo avvio!
    lda #0 : sta TN_VARIANT : sta TN_KEY_LOCK

TN_restart:
    lda #0 : sta TN_RESTART : jsr TN_sg              
    lda TN_RESTART : cmp #1 : beq TN_restart
    rts                    

!zone game_tennis {
TN_sg:
    lda #0 : sta TN_SCORE_P1 : sta TN_SCORE_P2
    ; NOTA: Non azzeriamo più TN_KEY_LOCK qui, così persiste al riavvio!
    sta $C6                 ; Svuota buffer tastiera in ingresso

    ldx TN_VARIANT
    lda TN_tab_pad_h,x   : sta TN_PAD_H
    lda TN_tab_pad_lim,x : sta TN_PAD_LIM
    lda TN_tab_start_s,x : sta TN_START_S
    lda TN_tab_max_s,x   : sta TN_MAX_S
    
    lda #244 : sec : sbc TN_PAD_H : sta TN_PAD_MY

    ldx #0 : lda #0
.cl_sp: sta $0340,x : inx : cpx #64 : bne .cl_sp
    ldx #0
.dr_pad: lda #TN_PAD_W : sta $0340,x : inx : inx : inx : cpx TN_PAD_LIM : bcc .dr_pad

    ldx #0 : lda #0
.cl_ball: sta $0380,x : inx : cpx #63 : bne .cl_ball
    lda #$FF : sta $0380 : sta $0383 : sta $0386 : sta $0389 

    jsr .init_gfx
    jsr .draw_boundary
    lda TN_SCORE_P1 : jsr .draw_p1_score
    lda TN_SCORE_P2 : jsr .draw_p2_score
    jsr TN_draw_speed_hud

    lda #TN_PAD_BLK : sta TN_PTR2 : sta TN_PTR3
    lda #TN_BALL_BLK: sta TN_PTR4
    lda #24 : sta TN_SP2_X : lda #84 : sta TN_SP3_X
    lda #146 : sta TN_SP2_Y : sta TN_SP3_Y
    lda #%00001000 : sta TN_MSB_X
    lda #%00001100 : sta TN_SPENA   
    lda #%00001100 : sta $D017      
    lda #1 : sta $D029 : sta $D02A  

    jsr .countdown
    lda TN_RESTART : beq .cnt_ok
    jmp .sg_exit 
.cnt_ok:
    jsr .reset_ball

.g_loop:
.wt_rst1: lda RASTER : cmp #$F0 : bne .wt_rst1
.wt_rst2: lda RASTER : cmp #$F0 : beq .wt_rst2

    lda #TN_PAD_BLK  : sta TN_PTR2 : sta TN_PTR3
    lda #TN_BALL_BLK : sta TN_PTR4
    
    lda #%00011100   : sta TN_SPENA   
    lda #%00001100   : sta $D017      
    lda #0           : sta $D01D : sta $D01C 
    lda #1           : sta $D029 
    lda #7           : sta $D02A      

    jsr .paddle_read
    jsr .move_ball
    jsr .check_col
    jsr UpdateSFX

    lda TN_BALL_X_L : sta TN_SP4_X : lda TN_BALL_Y : sta TN_SP4_Y
    lda #%00001000 : ldx TN_BALL_X_H : beq .upd_msb : ora #%00010000
.upd_msb: sta TN_MSB_X

    lda TN_SCORE_P1 : jsr .draw_p1_score : lda TN_SCORE_P2 : jsr .draw_p2_score

    ; ==========================================
    ; TASTIERA BARE METAL CON DEBOUNCE BLINDATO
    ; ==========================================
    sei
    lda #$FF : sta $DC02 
    lda #$00 : sta $DC03 
    lda #$FE : sta $DC00 
    lda $DC01 : sta TN_KEY_MAT  
    lda #$00 : sta $DC00 
    cli

    ; Controlla se c'è ALMENO UN tasto F premuto
    ; Maschera per F1($10), F7($08), F3($20), F5($40) -> $78
    lda TN_KEY_MAT
    and #$78
    cmp #$78
    beq .keys_released  ; Se sono tutti a 1, nessun tasto è premuto

    ; C'è un tasto premuto. Controlliamo se è bloccato
    lda TN_KEY_LOCK
    bne .chk_win        ; Se è 1, ignora il tasto (già processato)

    ; Non è bloccato: blocchiamolo e processiamo!
    lda #1 : sta TN_KEY_LOCK

    lda TN_KEY_MAT : and #$10 : beq .do_res_f1
    lda TN_KEY_MAT : and #$08 : beq .do_exit_f7
    lda TN_KEY_MAT : and #$20 : beq .do_f3
    lda TN_KEY_MAT : and #$40 : beq .do_f5
    jmp .chk_win

.keys_released:
    lda #0 : sta TN_KEY_LOCK
    jmp .chk_win

.do_f3:
    inc TN_VARIANT : lda TN_VARIANT
    cmp #5 : bcc .do_res_f1
    lda #0 : sta TN_VARIANT : jmp .do_res_f1

.do_f5:
    dec TN_VARIANT : bpl .do_res_f1
    lda #4 : sta TN_VARIANT : jmp .do_res_f1

.do_res_f1:
    lda #1 : sta TN_RESTART : rts

.do_exit_f7:
    lda #$FF : sta TN_RESTART : jsr .tn_cleanup : rts

.tn_cleanup:
    lda #0 : sta TN_SPENA : sta $D017 : sta $D01D : sta $D010
    lda $D011 : and #$EF : sta $D011   

    ; ============================================
    ; RESTORE ASSOLUTO CIA PER FUNZIONAMENTO MENU
    ; ============================================
    sei
    lda #$FF : sta $DC02   ; Forza Port A come Output
    lda #$00 : sta $DC03   ; Forza Port B come Input
    lda #$00 : sta $DC00   ; Lascia matrice in stato neutro KERNAL
    cli
    lda #0   : sta $C6     ; SVUOTA il buffer da eventuali tasti residui
    ; ============================================
    rts

.chk_win:
    lda TN_SCORE_P1 : cmp #15 : bcs .won
    lda TN_SCORE_P2 : cmp #15 : bcs .won
    jmp .g_loop

.won:
    jsr .clr_center : jsr .set_white
    lda #1  : sta WIN_COL_ON  
    lda #5  : sta WIN_COL_OFF 
    lda TN_LAST_WIN : bne .won_blink_p2
    lda #8  : sta WIN_COL_S : lda #14 : sta WIN_COL_E   
    jmp .won_win
.won_blink_p2:
    lda #25 : sta WIN_COL_S : lda #31 : sta WIN_COL_E   
.won_win:
    jsr DoWinScreen   

    cmp #$85 : beq .won_replay

    cmp #$86 : bne .won_f5
    inc TN_VARIANT : lda TN_VARIANT : cmp #5 : bcc .won_var
    lda #0 : sta TN_VARIANT : jmp .won_var
.won_f5:
    cmp #$87 : bne .won_f7
    dec TN_VARIANT : bpl .won_var : lda #4 : sta TN_VARIANT
.won_var:
    jsr .clr_center : lda #1 : sta TN_RESTART : rts
.won_f7:
    cmp #$88 : bne .won_replay
    jsr .clr_center : lda #$FF : sta TN_RESTART : jsr .tn_cleanup : rts 
.won_replay:
    jsr .clr_center : lda #1 : sta TN_RESTART : rts

.sg_exit:
    rts

.init_gfx:
    lda $D011 : and #$EF : sta $D011   
    lda #5 : sta $D021 : sta $D020     
    lda #$1E : sta $D018               
    lda #5 : jsr FillColorRAM : jsr ClearScreen
    lda #0 : sta KBD_COUNT : lda #1 : sta $CC                
    lda $D011 : ora #$10 : sta $D011   
    lda #0 : sta TN_SPENA : jsr InitSFX : rts

.draw_boundary:
    ldx #39
.drb_lp:
    lda #BRD_HLINE : sta SCRN+0*40,x : sta SCRN+24*40,x
    lda #1 : sta COLRAM+0*40,x : sta COLRAM+24*40,x
    dex : bpl .drb_lp : rts

.draw_p1_score:
    jsr .bin_bcd : pha : lda TN_TEMP_VAL : ldx #8  : ldy #1 : jsr .draw_digit
    pla : ldx #12 : ldy #1 : jsr .draw_digit : rts
.draw_p2_score:
    jsr .bin_bcd : pha : lda TN_TEMP_VAL : ldx #25 : ldy #1 : jsr .draw_digit
    pla : ldx #29 : ldy #1 : jsr .draw_digit : rts

.bin_bcd:
    ldx #0 : stx TN_TEMP_VAL
.bcd_lp:
    cmp #10 : bcc .bcd_end : sbc #10 : inc TN_TEMP_VAL : jmp .bcd_lp
.bcd_end:
    rts

.roll_ai_target:
    lda $D012       
    and #$01        
    beq .ai_t_up
.ai_t_down:
    lda TN_PAD_H : sec : sbc #2 : sta TN_AI_OFFSET : rts 
.ai_t_up:
    lda #2 : sta TN_AI_OFFSET : rts   

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
    jmp .pr_end

.read_port2:
    lda #%10000000 : sta $DC00 
    ldy #$C0                   ; FIX JITTER
.pr_lp2: 
    dey : bne .pr_lp2
    lda $D419 : sta $03        

.pr_end:
    lda #$FF : sta $DC02 : lda #$00 : sta $DC00 
    cli
    
    lda #24 : sta TN_SP2_X : lda #84 : sta TN_SP3_X
    lda $02 : jsr .cl_y : sta TN_SP2_Y

    lda TN_VARIANT : cmp #4 : bne .human_p2

.ai_p2:
    lda TN_BALL_Y
    sec : sbc TN_AI_OFFSET
    bcs +
    lda #0         
+   sta TN_TEMP_VAL
    
    lda TN_SP3_Y
    cmp TN_TEMP_VAL
    beq .ai_done
    bcc .ai_down
.ai_up:
    lda TN_SP3_Y : sec : sbc TN_TEMP_VAL
    cmp #6 : bcc .ai_snap   
    lda TN_SP3_Y : sec : sbc #6 : jmp .ai_apply 
.ai_down:
    lda TN_TEMP_VAL : sec : sbc TN_SP3_Y
    cmp #6 : bcc .ai_snap   
    lda TN_SP3_Y : clc : adc #6 : jmp .ai_apply              
.ai_snap:
    lda TN_TEMP_VAL         
.ai_apply:
    jsr .cl_y : sta TN_SP3_Y
.ai_done:
    rts

.human_p2:
    lda $03 : jsr .cl_y : sta TN_SP3_Y
    rts

.cl_y:
    cmp #54 : bcs .c1 : lda #54
.c1 cmp TN_PAD_MY : bcc .c2 : lda TN_PAD_MY
.c2 rts

.move_ball:
    lda TN_BALL_X_L : clc : adc TN_BALL_DX : sta TN_BALL_X_L
    lda TN_BALL_DX  : bmi .neg_dx
    lda TN_BALL_X_H : adc #0   : sta TN_BALL_X_H : jmp .chk_goal
.neg_dx:
    lda TN_BALL_X_H : adc #$FF : sta TN_BALL_X_H
.chk_goal:
    lda TN_BALL_X_H : bne .side_dx
    lda TN_BALL_X_L : cmp #12 : bcs .move_y
    inc TN_SCORE_P2 : lda #1 : sta TN_LAST_WIN
    lda #24 : sta EXP_INIT_XL : lda #0 : sta EXP_INIT_XH
    lda TN_BALL_Y : sta EXP_INIT_Y
    lda #SFX_GOAL : sta EXP_SFX
    lda #TN_BALL_BLK : sta EXP_PTR4_AF
    lda #%00011100  : sta EXP_SPENA_AF
    lda #0 : sta EXP_DIR   
    lda #%00001100 : sta TN_SPENA : sta $D015 
    jsr DoVectrexExplosion
    jsr .reset_ball : rts
.side_dx:
    lda TN_BALL_X_L : cmp #94 : bcc .move_y
    inc TN_SCORE_P1 : lda #0 : sta TN_LAST_WIN
    lda #84 : sta EXP_INIT_XL : lda #1 : sta EXP_INIT_XH
    lda TN_BALL_Y : sta EXP_INIT_Y
    lda #SFX_GOAL : sta EXP_SFX
    lda #TN_BALL_BLK : sta EXP_PTR4_AF
    lda #%00011100  : sta EXP_SPENA_AF
    lda #1 : sta EXP_DIR   
    lda #%00001100 : sta TN_SPENA : sta $D015 
    jsr DoVectrexExplosion
    jsr .reset_ball : rts
.move_y:
    lda TN_BALL_Y : clc : adc TN_BALL_DY : sta TN_BALL_Y
    cmp #54  : bcs .nt
    lda #SFX_WALL : jsr PlaySFX
    lda #2   : sta TN_BALL_DY : lda #54  : sta TN_BALL_Y : rts
.nt cmp #240 : bcc .em
    lda #SFX_WALL : jsr PlaySFX
    lda #$FE : sta TN_BALL_DY : lda #240 : sta TN_BALL_Y
.em rts

.reset_ball:
    lda #0 : sta TN_HITS : lda TN_START_S : sta TN_CUR_SPD
    lda #1 : sta $D02B  
    jsr .roll_ai_target  
    
    lda TN_LAST_WIN : bne .rb_p2
    lda #0  : sta TN_BALL_X_H        
    lda #32 : sta TN_BALL_X_L        
    lda TN_SP2_Y : sta TN_BALL_Y    
    lda TN_CUR_SPD : sta TN_BALL_DX : jmp .rb_c
.rb_p2:
    lda #1  : sta TN_BALL_X_H        
    lda #60 : sta TN_BALL_X_L        
    lda TN_SP3_Y : sta TN_BALL_Y    
    lda #0  : sec : sbc TN_CUR_SPD : sta TN_BALL_DX  
.rb_c:
    lda #2 : sta TN_BALL_DY
    jsr TN_draw_speed_hud
    rts

.check_col:
    lda TN_BALL_X_H : bne .c_dx     
    lda TN_BALL_DX  : bpl .c_dx     
    
    lda TN_BALL_X_L : cmp #8 : bcc .c_dx : cmp #30 : bcs .c_dx
    lda TN_BALL_Y : clc : adc #20 : cmp TN_SP2_Y : bcc .c_dx          
    lda TN_BALL_Y : sec : sbc TN_PAD_H : sec : sbc #4 : cmp TN_SP2_Y : bcs .c_dx          
    
    lda #29 : sta TN_BALL_X_L        
    lda $08 : sta $FA               
    lda TN_SP2_Y : sta TN_TEMP_VAL  
    jsr .apply_english_arcade 
    jsr .inc_spd
    jsr .roll_ai_target  
    rts

.c_dx:
    lda TN_BALL_X_H : beq .ex_c     
    lda TN_BALL_DX  : bmi .ex_c     
    
    lda TN_BALL_X_L : cmp #75 : bcc .ex_c : cmp #105 : bcs .ex_c
    lda TN_BALL_Y : clc : adc #20 : cmp TN_SP3_Y : bcc .ex_c          
    lda TN_BALL_Y : sec : sbc TN_PAD_H : sec : sbc #4 : cmp TN_SP3_Y : bcs .ex_c          
    
    lda #75 : sta TN_BALL_X_L        
    lda $09 : sta $FA               
    lda TN_SP3_Y : sta TN_TEMP_VAL  
    jsr .apply_english_arcade 
    jsr .inc_spd
    
    lda TN_BALL_DX : eor #$FF : clc : adc #1 : sta TN_BALL_DX
.ex_c: 
    rts

.inc_spd:
    inc TN_HITS : lda TN_HITS : cmp #TN_SPEED_STEPS : bcc .ih_pad_sfx
    lda #0 : sta TN_HITS : lda TN_CUR_SPD : cmp TN_MAX_S : bcs .ih_pad_sfx
    clc : adc #1 : sta TN_CUR_SPD : cmp TN_MAX_S : bcc .ih_upd
    lda #2 : sta $D02B   
.ih_upd: 
    jsr TN_draw_speed_hud
    lda #SFX_POWERUP : jsr PlaySFX : rts
.ih_pad_sfx:
    lda #SFX_PAD : jsr PlaySFX : rts

.apply_english_arcade:
    lda TN_CUR_SPD : sta TN_BALL_DX
    
    lda TN_TEMP_VAL       
    sec : sbc $FA 
    sta $FC           
    
    lda TN_PAD_H : lsr : clc : adc TN_TEMP_VAL : sta $FB  
    lda TN_BALL_Y : clc : adc #10
    
    cmp $FB 
    bcs .hit_lower_half

.hit_upper_half:
    lda $FB : sec : sbc TN_BALL_Y : sec : sbc #10
    cmp #7 : bcc .ang_up
    jmp .smash_up

.hit_lower_half:
    sec : sbc $FB
    cmp #7 : bcc .ang_down
    jmp .smash_down

.ang_up:
    lda #$FF : sta TN_BALL_DY : jmp .apply_inertia
.ang_down:
    lda #1 : sta TN_BALL_DY : jmp .apply_inertia
    
.smash_up:
    lda TN_CUR_SPD : clc : adc #1 : sta TN_BALL_DX 
    lda TN_CUR_SPD : lsr : clc : adc #1 : eor #$FF : clc : adc #1 : sta TN_BALL_DY
    jmp .apply_inertia

.smash_down:
    lda TN_CUR_SPD : clc : adc #1 : sta TN_BALL_DX 
    lda TN_CUR_SPD : lsr : clc : adc #1 : sta TN_BALL_DY
    
.apply_inertia:
    lda $FC : beq .done_inertia 
    bmi .spin_up
.spin_down:
    lda TN_BALL_DY : clc : adc #1
    beq .done_inertia 
    sta TN_BALL_DY : jmp .done_inertia
.spin_up:
    lda TN_BALL_DY : sec : sbc #1
    beq .done_inertia 
    sta TN_BALL_DY
.done_inertia:
    rts

TN_draw_speed_hud:
    lda #$8A : sta SCRN+24*40+19 : lda #1 : sta COLRAM+24*40+19
    lda TN_CUR_SPD : clc : adc #$80 : sta SCRN+24*40+20 : lda #1 : sta COLRAM+24*40+20
    rts

; ==========================================
; COUNTDOWN ED ESECUZIONE FANFARA
; ==========================================
.countdown:
    lda #1
    jsr $1000
    lda #$0F : sta $D418    

    lda #0 : sta TN_SP4_Y
    jsr .set_white : jsr .clr_center

    lda #10 : ldx #12 : ldy #8  : jsr .draw_digit  
    lda #11 : ldx #16 : ldy #8  : jsr .draw_digit  
    lda #12 : ldx #20 : ldy #8  : jsr .draw_digit  
    lda TN_VARIANT : ldx #25 : ldy #8 : jsr .draw_digit

    lda #3 : sta TN_TEMP_VAL
.cnt_lp:
    jsr .clr_count
    lda TN_TEMP_VAL : ldx #19 : ldy #16 : jsr .draw_digit
    
    jsr .wait_1sec
    
    lda TN_RESTART : bne .cd_exit
    dec TN_TEMP_VAL : bne .cnt_lp

    jsr .clr_count
    lda #14 : ldx #15 : ldy #16 : jsr .draw_digit  
    lda #0  : ldx #19 : ldy #16 : jsr .draw_digit  
    lda #15 : ldx #23 : ldy #16 : jsr .draw_digit  
    
    jsr .wait_1sec
    
    lda TN_RESTART : bne .cd_exit

    jsr .clr_center
.cd_exit:
    jsr $1003
    
    ; --- DEEP CLEAN DEL SID ---
    lda #0 : ldx #0
.cl_sid_tn:
    sta $D400,x
    inx : cpx #25 : bne .cl_sid_tn

    lda #$0F : sta $D418       
    jsr InitSFX     
    rts

; ==========================================
; WAIT_1SEC BARE METAL CON DEBOUNCE BLINDATO
; ==========================================
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
    lda $DC01 : sta TN_KEY_MAT
    lda #$00 : sta $DC00 
    cli
    
    lda TN_KEY_MAT
    and #$78
    cmp #$78
    beq .wt_released

    lda TN_KEY_LOCK
    bne .wt_next

    lda #1 : sta TN_KEY_LOCK

    lda TN_KEY_MAT : and #$10 : beq .wda
    lda TN_KEY_MAT : and #$08 : beq .w_f7
    lda TN_KEY_MAT : and #$20 : beq .w_f3
    lda TN_KEY_MAT : and #$40 : beq .w_f5
    jmp .wt_next

.wt_released:
    lda #0 : sta TN_KEY_LOCK
    jmp .wt_next

.w_f3:
    inc TN_VARIANT : lda TN_VARIANT : cmp #5 : bcc .wda : lda #0 : sta TN_VARIANT : jmp .wda

.w_f5:
    dec TN_VARIANT : bpl .wda : lda #4 : sta TN_VARIANT : jmp .wda

.w_f7:
    lda #$FF : sta TN_RESTART : jsr .tn_cleanup : pla : rts                               

.wda: 
    lda #1 : sta TN_RESTART : pla : rts                        

.wt_next: 
    pla 
    sec : sbc #1 
    beq .wt_done            
    jmp .wt_frame           
.wt_done:
    rts

.set_white:
    lda #1 : ldx #0
.sw_lp:
    sta COLRAM+8*40,x  : sta COLRAM+9*40,x : sta COLRAM+10*40,x : sta COLRAM+11*40,x : sta COLRAM+12*40,x
    sta COLRAM+16*40,x : sta COLRAM+17*40,x : sta COLRAM+18*40,x : sta COLRAM+19*40,x : sta COLRAM+20*40,x
    inx : cpx #40 : bne .sw_lp : rts

.clr_center:
    lda #32 : ldx #0
.cc1: sta SCRN+$140,x : inx : cpx #200 : bne .cc1
    ldx #0
.cc2: sta SCRN+$280,x : inx : cpx #200 : bne .cc2 : rts

.clr_count:
    lda #32 : ldx #0
.cco: sta SCRN+$280,x : inx : cpx #200 : bne .cco : rts

.draw_digit:
    sta $FD : lda #0 : sta $FC : sta $FB
    tya : beq .add_x
.mul40: clc : lda $FB : adc #40 : sta $FB : bcc .m_ok : inc $FC
.m_ok:  dey : bne .mul40
.add_x: txa : clc : adc $FB : sta $FB : bcc .a_ok : inc $FC
.a_ok:  clc : lda $FC : adc #$04 : sta $FC
    lda $FD : asl : asl : asl : asl : tax : ldy #0
.yl: lda TN_big_num+0,x : sta ($FB),y : inx : iny
    lda TN_big_num+0,x : sta ($FB),y : inx : iny
    lda TN_big_num+0,x : sta ($FB),y : inx
    lda $FB : clc : adc #40 : sta $FB : bcc .y_ok : inc $FC
.y_ok:  ldy #0 : txa : and #$0F : cmp #15 : bcc .yl : rts

TN_big_num:
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

}