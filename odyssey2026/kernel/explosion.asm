; ==========================================
; kernel/explosion.asm - Effetto Vectrex (Multi-Direzionale)
; FIX: Aggiunta routine DoVerticalExplosion per giochi asse X (Breakout/Flipper).
; NEW: Nuovi sprite diagonali (Blocchi 178 e 179) per l'esplosione a "V" dal basso.
; ==========================================
EXP_INIT_XL   = $92
EXP_INIT_XH   = $93
EXP_INIT_Y    = $94
EXP_SFX       = $95
EXP_SPENA_AF  = $96
EXP_PTR4_AF   = $97
EXP_DIR       = $98   

EXP_SPA_X = $D00C : EXP_SPA_Y = $D00D   
EXP_SPB_X = $D00E : EXP_SPB_Y = $D00F   
EXP_MSB_X = $D010 : EXP_SPENA = $D015
EXP_PTRA  = $07FE   
EXP_PTRB  = $07FF   

; --- BLOCCHI SPRITE (Area Sicura $2C00 - $2CFF) ---
EXP1_BLK  = 176  ; Orizzontale SX
EXP2_BLK  = 177  ; Orizzontale DX
EXP3_BLK  = 178  ; Verticale Up-SX
EXP4_BLK  = 179  ; Verticale Up-DX

EXP_shape_1:
!byte $F0,$00,$00, $78,$00,$00, $3C,$00,$00, $1E,$00,$00, $0F,$00,$00, $07,$80,$00, $03,$C0,$00, $01,$E0,$00
!byte $00,$F0,$00, $00,$78,$00, $00,$3C,$00, $00,$1E,$00, $00,$0F,$00, $00,$07,$80, $00,$03,$C0, $00,$01,$E0
!byte $00,$00,$F0, $00,$00,$78, $00,$00,$3C, $00,$00,$1E, $00,$00,$0F

EXP_shape_2:
!byte $00,$00,$0F, $00,$00,$1E, $00,$00,$3C, $00,$00,$78, $00,$00,$F0, $00,$01,$E0, $00,$03,$C0, $00,$07,$80
!byte $00,$0F,$00, $00,$1E,$00, $00,$3C,$00, $00,$78,$00, $00,$F0,$00, $01,$E0,$00, $03,$C0,$00, $07,$80,$00
!byte $0F,$00,$00, $1E,$00,$00, $3C,$00,$00, $78,$00,$00, $F0,$00,$00

EXP_shape_3: ; Scintilla UP-LEFT
!fill 12, 0
!byte $03,$00,$00, $06,$00,$00, $0C,$00,$00, $18,$00,$00, $30,$00,$00, $60,$00,$00, $C0,$00,$00
!fill 31, 0

EXP_shape_4: ; Scintilla UP-RIGHT
!fill 12, 0
!byte $C0,$00,$00, $60,$00,$00, $30,$00,$00, $18,$00,$00, $0C,$00,$00, $06,$00,$00, $03,$00,$00
!fill 31, 0

exp_xl:    !fill 2
exp_xh:    !fill 2
exp_y:     !fill 2
exp_mask:  !byte 0   
exp_timer: !byte 0

; ===================================================
; ESPLOSIONE ORIZZONTALE (Pong, Hockey, Football)
; ===================================================
DoVectrexExplosion:
    lda #0 : ldy #0
.zv: sta $2C00,y : sta $2C40,y : iny : cpy #64 : bne .zv
    ldx #0
.cv: lda EXP_shape_1,x : sta $2C00,x : lda EXP_shape_2,x : sta $2C40,x : inx : cpx #63 : bne .cv

    lda EXP_DIR : bne .sh_sx
    lda #EXP2_BLK : sta EXP_PTRA : lda #EXP1_BLK : sta EXP_PTRB : jmp .sh_done
.sh_sx:
    lda #EXP1_BLK : sta EXP_PTRA : lda #EXP2_BLK : sta EXP_PTRB   
.sh_done:
    jsr ApplyExpColor

    lda EXP_INIT_XL : sta exp_xl+0 : sta exp_xl+1
    lda EXP_INIT_XH : sta exp_xh+0 : sta exp_xh+1
    lda EXP_INIT_Y  : sta exp_y+0  : sta exp_y+1

    lda #%11000000 : sta exp_mask   
    lda EXP_SFX : jsr PlaySFX
    lda #20 : sta exp_timer

.v_loop:
    lda exp_mask : and #%01000000 : beq .rN_dn
    lda exp_y+0 : sec : sbc #12 : sta exp_y+0
    cmp #30 : bcc .kN   
    lda EXP_DIR : bne .rN_sx
    lda exp_xl+0 : clc : adc #12 : sta exp_xl+0 : bcc .rN_chk : inc exp_xh+0
    jmp .rN_chk
.rN_sx:
    lda exp_xl+0 : sec : sbc #12 : sta exp_xl+0 : bcs .rN_chk : dec exp_xh+0
.rN_chk:
    lda EXP_DIR : bne .rN_chk_sx
    lda exp_xh+0 : beq .rN_ok : cmp #1 : bne .kN : lda exp_xl+0 : cmp #88 : bcs .kN : jmp .rN_ok
.rN_chk_sx:
    lda exp_xh+0 : cmp #$FF : beq .kN : bne .rN_ok : lda exp_xl+0 : cmp #12 : bcc .kN
.rN_ok:
    lda exp_xl+0 : sta EXP_SPA_X : lda exp_y+0 : sta EXP_SPA_Y : jmp .rN_dn
.kN: lda exp_mask : and #%10111111 : sta exp_mask
.rN_dn:

    lda exp_mask : and #%10000000 : beq .rS_dn
    lda exp_y+1 : clc : adc #12 : sta exp_y+1
    cmp #250 : bcs .kS   
    lda EXP_DIR : bne .rS_sx
    lda exp_xl+1 : clc : adc #12 : sta exp_xl+1 : bcc .rS_chk : inc exp_xh+1 : jmp .rS_chk
.rS_sx:
    lda exp_xl+1 : sec : sbc #12 : sta exp_xl+1 : bcs .rS_chk : dec exp_xh+1
.rS_chk:
    lda EXP_DIR : bne .rS_chk_sx
    lda exp_xh+1 : beq .rS_ok : cmp #1 : bne .kS : lda exp_xl+1 : cmp #88 : bcs .kS : jmp .rS_ok
.rS_chk_sx:
    lda exp_xh+1 : cmp #$FF : beq .kS : bne .rS_ok : lda exp_xl+1 : cmp #12 : bcc .kS
.rS_ok:
    lda exp_xl+1 : sta EXP_SPB_X : lda exp_y+1 : sta EXP_SPB_Y : jmp .rS_dn
.kS: lda exp_mask : and #%01111111 : sta exp_mask
.rS_dn:

    jsr RenderExplosion
    jsr UpdateSFX
    lda exp_mask : beq .v_done
    dec exp_timer : beq .v_done
    jmp .v_loop

.v_done:
    lda EXP_SPENA_AF : sta EXP_SPENA
    lda EXP_MSB_X : and #%00111111 : sta EXP_MSB_X : sta $D010
    rts

; ===================================================
; ESPLOSIONE VERTICALE (Breakout, Flipper)
; ===================================================
DoVerticalExplosion:
    lda #0 : ldy #0
.zv2: sta $2C80,y : sta $2CC0,y : iny : cpy #64 : bne .zv2
    ldx #0
.cv2: lda EXP_shape_3,x : sta $2C80,x : lda EXP_shape_4,x : sta $2CC0,x : inx : cpx #63 : bne .cv2

    lda #EXP3_BLK : sta EXP_PTRA   
    lda #EXP4_BLK : sta EXP_PTRB   
    jsr ApplyExpColor

    lda EXP_INIT_XL : sta exp_xl+0 : sta exp_xl+1
    lda EXP_INIT_XH : sta exp_xh+0 : sta exp_xh+1
    lda EXP_INIT_Y  : sta exp_y+0  : sta exp_y+1

    lda #%11000000 : sta exp_mask   
    lda EXP_SFX : jsr PlaySFX
    lda #30 : sta exp_timer

.vy_loop:
    ; Raggio SX (Sale e va a sinistra)
    lda exp_mask : and #%01000000 : beq .vy_r2
    lda exp_y+0 : sec : sbc #6 : sta exp_y+0 : cmp #50 : bcc .ky_1   
    lda exp_xl+0 : sec : sbc #4 : sta exp_xl+0 : bcs .vx_ok1 : dec exp_xh+0
.vx_ok1:
    lda exp_xh+0 : cmp #$FF : beq .ky_1 : lda exp_xl+0 : cmp #12 : bcc .ky_1
    lda exp_xl+0 : sta EXP_SPA_X : lda exp_y+0 : sta EXP_SPA_Y : jmp .vy_r2
.ky_1: lda exp_mask : and #%10111111 : sta exp_mask

.vy_r2:
    ; Raggio DX (Sale e va a destra)
    lda exp_mask : and #%10000000 : beq .vy_rnd
    lda exp_y+1 : sec : sbc #6 : sta exp_y+1 : cmp #50 : bcc .ky_2   
    lda exp_xl+1 : clc : adc #4 : sta exp_xl+1 : bcc .vx_ok2 : inc exp_xh+1
.vx_ok2:
    lda exp_xh+1 : beq .vy_okb : cmp #1 : bne .ky_2 : lda exp_xl+1 : cmp #88 : bcs .ky_2
.vy_okb:
    lda exp_xl+1 : sta EXP_SPB_X : lda exp_y+1 : sta EXP_SPB_Y : jmp .vy_rnd
.ky_2: lda exp_mask : and #%01111111 : sta exp_mask

.vy_rnd:
    jsr RenderExplosion
    jsr UpdateSFX
    lda exp_mask : beq .vy_done
    dec exp_timer : beq .vy_done
    jmp .vy_loop

.vy_done:
    lda EXP_SPENA_AF : sta EXP_SPENA
    lda EXP_MSB_X : and #%00111111 : sta EXP_MSB_X : sta $D010
    rts

; --- Subroutines Comuni ---
ApplyExpColor:
    lda $D021 : and #$0F : cmp #1 : beq .set_blue : lda #1 : jmp .apply_col
.set_blue: lda #6         
.apply_col:
    sta $D02D : sta $D02E : lda #0 : sta $D01C : rts

RenderExplosion:
    lda EXP_SPENA : and #%00111111 : ora exp_mask : sta EXP_SPENA
    lda EXP_MSB_X : and #%00111111 : sta EXP_MSB_X
    lda exp_xh+0 : beq .mA : lda EXP_MSB_X : ora #%01000000 : sta EXP_MSB_X
.mA: lda exp_xh+1 : beq .mB : lda EXP_MSB_X : ora #%10000000 : sta EXP_MSB_X
.mB: lda EXP_MSB_X : sta $D010  
.wr1: lda RASTER : cmp #$F0 : bne .wr1
.wr2: lda RASTER : cmp #$F0 : beq .wr2
    rts