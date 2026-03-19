;============================================
; sound_test.asm - Sound Test Screen
; Entry:  SoundTest (JSR da menu con F2)
; Keys:   CUR_DOWN($11)/CUR_UP($91) = naviga
;         SPACE($20) = play effetto
;         F7($88) = torna al menu
;============================================

ST_BG      = 0    ; nero sfondo
ST_TITLE   = 7    ; giallo titolo
ST_SEL     = 1    ; bianco = riga selezionata
ST_NORM    = 12   ; grigio = righe normali
ST_HINT    = 5    ; verde = hints
ST_PLAYING = 10   ; arancione = "playing"

ST_NUM     = 5    ; numero di effetti
ST_ROW0    = 8    ; prima riga lista (effetti a righe pari: 8,10,12,14,16)

ST_CUR     = $7C  ; indice corrente 0..ST_NUM-1
ST_PREV    = $7D  ; indice precedente

ST_STR_TITLE:  !scr "* sound test *", 0
ST_STR_HINT:   !scr "up/dn=sel  spc=play  f7=menu", 0
ST_STR_PLAY:   !scr "playing...", 0
ST_STR_BLANK:  !scr "          ", 0

ST_LBL0:  !scr " 0  pad bounce     ", 0
ST_LBL1:  !scr " 1  wall bounce    ", 0
ST_LBL2:  !scr " 2  goal scored    ", 0
ST_LBL3:  !scr " 3  ball lost      ", 0
ST_LBL4:  !scr " 4  power up       ", 0

ST_LBL_LO: !byte <ST_LBL0,<ST_LBL1,<ST_LBL2,<ST_LBL3,<ST_LBL4
ST_LBL_HI: !byte >ST_LBL0,>ST_LBL1,>ST_LBL2,>ST_LBL3,>ST_LBL4

; Righe schermo per ogni effetto
ST_ROWS:    !byte ST_ROW0+0, ST_ROW0+2, ST_ROW0+4, ST_ROW0+6, ST_ROW0+8

!zone sound_test {

SoundTest:
    ; Init schermo
    lda $D011 : and #$EF : sta $D011
    lda #ST_BG : sta VICBKGD : sta VICBORD
    lda #ST_BG : jsr FillColorRAM
    jsr ClearScreen
    lda #1 : sta $CC
    lda $D011 : ora #$10 : sta $D011
    lda #0 : sta KBD_COUNT
    jsr InitSFX

    ; Titolo riga 2 col 10 — "* sound test *" = 14 chars → celle 10-23
    ldx #2 : jsr .set_ptr_col10
    lda #<ST_STR_TITLE : sta PRINT_SRC
    lda #>ST_STR_TITLE : sta PRINT_SRC+1
    jsr PrintStr
    ldx #10
-   lda #ST_TITLE : sta COLRAM+2*40,x : inx : cpx #24 : bne -

    ; Lista effetti: stampa etichette e colora subito grigio
    ldx #0
.draw_list:
    txa : pha
    lda ST_ROWS,x : tax             ; X = numero riga schermo
    jsr .set_ptr_col10
    pla : tax                       ; X = indice effetto
    lda ST_LBL_LO,x : sta PRINT_SRC
    lda ST_LBL_HI,x : sta PRINT_SRC+1
    jsr PrintStr
    ; Colora subito grigio la riga appena stampata
    lda ST_ROWS,x : tay             ; Y = numero riga schermo
    lda ROW_TABLE_LO,y : clc : adc #10 : sta ZP2_PTR
    lda ROW_TABLE_HI,y : adc #0    : clc : adc #$D4 : sta ZP2_PTR+1
    ldy #0
-   lda #ST_NORM : sta (ZP2_PTR),y : iny : cpy #20 : bne -
    inx : cpx #ST_NUM : bne .draw_list

    ; Hint riga 23
    ldx #23 : jsr .set_ptr_col6
    lda #<ST_STR_HINT : sta PRINT_SRC
    lda #>ST_STR_HINT : sta PRINT_SRC+1
    jsr PrintStr
    ldx #39
-   lda #ST_HINT : sta COLRAM+23*40,x : dex : bpl -

    ; Cursore iniziale
    lda #0 : sta ST_CUR : sta ST_PREV
    lda #0 : jsr .color_sel

; --- Loop principale ---
ST_loop:
-   lda RASTER : cmp #$F0 : bne -
    jsr UpdateSFX

    lda KBD_COUNT : beq ST_loop
    lda KBD_BUF : ldx #0 : stx KBD_COUNT

    ; Cursor down
    cmp #$11 : bne .st_up
    lda ST_CUR : sta ST_PREV
    clc : adc #1 : cmp #ST_NUM : bcc +
    lda #0
+   sta ST_CUR
    lda ST_PREV : jsr .color_norm
    lda ST_CUR  : jsr .color_sel
    jmp ST_loop

    ; Cursor up
.st_up:
    cmp #$91 : bne .st_space
    lda ST_CUR : sta ST_PREV
    sec : sbc #1 : bpl +
    lda #ST_NUM-1
+   sta ST_CUR
    lda ST_PREV : jsr .color_norm
    lda ST_CUR  : jsr .color_sel
    jmp ST_loop

    ; SPACE = play
.st_space:
    cmp #$20 : bne .st_f7
    lda ST_CUR : jsr PlaySFX
    ; Mostra "playing..." riga 21
    ldx #21 : jsr .set_ptr_col15
    lda #<ST_STR_PLAY : sta PRINT_SRC
    lda #>ST_STR_PLAY : sta PRINT_SRC+1
    jsr PrintStr
    ldx #39
-   lda #ST_PLAYING : sta COLRAM+21*40,x : dex : bpl -
    ; Aspetta fine
-   lda RASTER : cmp #$F0 : bne -
    jsr UpdateSFX
    lda SFX_ACTIVE : bne -
    ; Cancella "playing..."
    ldx #21 : jsr .set_ptr_col15
    lda #<ST_STR_BLANK : sta PRINT_SRC
    lda #>ST_STR_BLANK : sta PRINT_SRC+1
    jsr PrintStr
    jmp ST_loop

    ; F7 = exit
.st_f7:
    cmp #$88 : bne .st_nof7
    lda #0 : sta $D412     ; SID voice 3 gate off
    rts
.st_nof7:
    jmp ST_loop

; --- Helper: set ZP_PTR a riga X, colonna 10 ---
.set_ptr_col10:
    lda ROW_TABLE_LO,x : clc : adc #10 : sta ZP_PTR
    lda ROW_TABLE_HI,x : adc #0        : sta ZP_PTR+1
    rts

.set_ptr_col6:
    lda ROW_TABLE_LO,x : clc : adc #6 : sta ZP_PTR
    lda ROW_TABLE_HI,x : adc #0       : sta ZP_PTR+1
    rts

.set_ptr_col15:
    lda ROW_TABLE_LO,x : clc : adc #15 : sta ZP_PTR
    lda ROW_TABLE_HI,x : adc #0        : sta ZP_PTR+1
    rts

; --- Colora riga effetto A in bianco (selezione) ---
.color_sel:
    ldx #ST_SEL : jmp .color_row
; --- Colora riga effetto A in grigio (normale) ---
.color_norm:
    ldx #ST_NORM
; --- Colora riga: A=indice effetto(0..4), X=colore ---
.color_row:
    tay                             ; Y = indice effetto
    lda ST_ROWS,y                   ; A = numero riga schermo (8,10,12,14,16)
    tay                             ; Y = numero riga → indice corretto per ROW_TABLE
    lda ROW_TABLE_LO,y : clc : adc #10 : sta ZP2_PTR
    lda ROW_TABLE_HI,y : adc #0        ; carry da adc#10
                         clc : adc #$D4 ; $04+$D4=$D8 → COLRAM high byte
                         sta ZP2_PTR+1
    ldy #0
-   txa : sta (ZP2_PTR),y : iny : cpy #20 : bne -
    rts

} ; fine !zone sound_test
