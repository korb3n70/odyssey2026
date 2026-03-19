; ==========================================
; kernel/winscreen.asm - Schermata fine partita
; FIX: Ripristino KERNAL I/O (DFLTN/DFLTO) per non "accecare" il Menu!
; ==========================================

WIN_COL_S   = $98   
WIN_COL_E   = $99   
WIN_COL_ON  = $9A   
WIN_COL_OFF = $9B   

DoWinScreen:
    lda WIN_COL_S   : sta ws_col_s
    lda WIN_COL_E   : sta ws_col_e
    lda WIN_COL_ON  : sta ws_col_on
    lda WIN_COL_OFF : sta ws_col_off

    lda #0 : sta SFX_ACTIVE
    
    jsr $1003               ; Stoppa audio precedente

    lda #3
    jsr $1000               ; Init Jingle (Subtune 3)
    lda #$0F : sta $D418    
    
    lda #0 : sta ws_timer
    sta $C6                 ; Svuota buffer in ingresso per sicurezza

.ws_loop:
.ws_w1: lda RASTER : cmp #$F0 : bne .ws_w1
.ws_w2: lda RASTER : cmp #$F0 : beq .ws_w2

    jsr $1006               ; Play Jingle 1 frame

    inc ws_timer
    lda ws_timer : cmp #60 : bcc .ws_blink
    lda #0 : sta ws_timer

.ws_blink:
    cmp #30 : bcc .ws_on
    lda ws_col_off : jmp .ws_paint
.ws_on:
    lda ws_col_on

.ws_paint:
    ldx ws_col_s
.ws_col:
    sta COLRAM+1*40,x : sta COLRAM+2*40,x : sta COLRAM+3*40,x
    sta COLRAM+4*40,x : sta COLRAM+5*40,x
    inx : cpx ws_col_e : bcc .ws_col
    sta COLRAM+1*40,x : sta COLRAM+2*40,x : sta COLRAM+3*40,x
    sta COLRAM+4*40,x : sta COLRAM+5*40,x

    ; ==============================================
    ; LETTURA TASTIERA DIRETTA (HARDWARE BARE METAL)
    ; ==============================================
    sei
    lda #$FF : sta $DC02
    lda #$00 : sta $DC03
    lda #$FE : sta $DC00
    lda $DC01 : sta ws_key_matrix
    lda #$00 : sta $DC00
    cli

    lda ws_key_matrix
    and #$10 : beq .k_f1

    lda ws_key_matrix
    and #$20 : beq .k_f3

    lda ws_key_matrix
    and #$40 : beq .k_f5

    lda ws_key_matrix
    and #$08 : beq .k_f7

    jmp .ws_loop

.k_f1: lda #$85 : sta ws_key : jmp .ws_exit
.k_f3: lda #$86 : sta ws_key : jmp .ws_exit
.k_f5: lda #$87 : sta ws_key : jmp .ws_exit
.k_f7: lda #$88 : sta ws_key : jmp .ws_exit

.ws_exit:
    jsr $1003               ; Ferma Jingle
    
    lda ws_col_on : ldx ws_col_s
.ws_restore:
    sta COLRAM+1*40,x : sta COLRAM+2*40,x : sta COLRAM+3*40,x
    sta COLRAM+4*40,x : sta COLRAM+5*40,x
    inx : cpx ws_col_e : bcc .ws_restore
    sta COLRAM+1*40,x : sta COLRAM+2*40,x : sta COLRAM+3*40,x
    sta COLRAM+4*40,x : sta COLRAM+5*40,x

    lda #0 : sta $C6        ; Svuota buffer tastiera 

    ; ----------------------------------------------------
    ; FIX CRUCIALE: Ripristino dei registri KERNAL I/O!
    ; Assicura che il Menu torni a leggere la tastiera vera.
    ; ----------------------------------------------------
    lda #0
    sta $98     ; LDTND (Nessun file aperto)
    sta $99     ; DFLTN (Default Input = 0, ovvero la Tastiera)
    sta $9B     ; PRTY  (Parity disattivata)
    lda #3
    sta $9A     ; DFLTO (Default Output = 3, ovvero lo Schermo)
    ; ----------------------------------------------------
    
    lda ws_key              ; Ritorna il codice corretto al gioco in A
    rts

ws_col_s:      !byte 0
ws_col_e:      !byte 0
ws_col_on:     !byte 0
ws_col_off:    !byte 0
ws_timer:      !byte 0
ws_key:        !byte 0
ws_key_matrix: !byte 0