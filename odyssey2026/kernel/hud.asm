;============================================
; hud.asm - HUD comune tutti i minigiochi
; Cifre 4x5 (20 byte/cifra), score 4 cifre
; P1: col 0,4,8,12   P2: col 24,28,32,36
; Righe 0-4: score area
; Riga  5:   separatore opzionale
; Righe 5-22: area gioco (se no sep: 4-22)
; Riga  23:  info bar
;============================================

SCORE1_A = $20   ; BCD: nibble hi=migliaia, lo=centinaia
SCORE1_B = $21   ; BCD: nibble hi=decine,   lo=unità
SCORE2_A = $22
SCORE2_B = $23
SCORE1_X = $24   ; cifre extra per flipper (milioni/centomila)
SCORE2_X = $25
HUD_TMP  = $26
HUD_COL  = $27

; DIGIT_TABLE: 10 cifre x 20 byte = 200 byte
; Layout per cifra: 5 righe x 4 colonne (col 3 = spazio separatore)
DIGIT_TABLE:
  !byte $A0,$A0,$A0,$20,$A0,$20,$A0,$20,$A0,$20,$A0,$20,$A0,$20,$A0,$20,$A0,$A0,$A0,$20  ; 0
  !byte $20,$A0,$20,$20,$A0,$A0,$20,$20,$20,$A0,$20,$20,$20,$A0,$20,$20,$A0,$A0,$A0,$20  ; 1
  !byte $A0,$A0,$A0,$20,$20,$20,$A0,$20,$A0,$A0,$A0,$20,$A0,$20,$20,$20,$A0,$A0,$A0,$20  ; 2
  !byte $A0,$A0,$A0,$20,$20,$20,$A0,$20,$20,$A0,$A0,$20,$20,$20,$A0,$20,$A0,$A0,$A0,$20  ; 3
  !byte $A0,$20,$A0,$20,$A0,$20,$A0,$20,$A0,$A0,$A0,$20,$20,$20,$A0,$20,$20,$20,$A0,$20  ; 4
  !byte $A0,$A0,$A0,$20,$A0,$20,$20,$20,$A0,$A0,$A0,$20,$20,$20,$A0,$20,$A0,$A0,$A0,$20  ; 5
  !byte $A0,$A0,$A0,$20,$A0,$20,$20,$20,$A0,$A0,$A0,$20,$A0,$20,$A0,$20,$A0,$A0,$A0,$20  ; 6
  !byte $A0,$A0,$A0,$20,$20,$20,$A0,$20,$20,$A0,$20,$20,$20,$A0,$20,$20,$20,$A0,$20,$20  ; 7
  !byte $A0,$A0,$A0,$20,$A0,$20,$A0,$20,$A0,$A0,$A0,$20,$A0,$20,$A0,$20,$A0,$A0,$A0,$20  ; 8
  !byte $A0,$A0,$A0,$20,$A0,$20,$A0,$20,$A0,$A0,$A0,$20,$20,$20,$A0,$20,$A0,$A0,$A0,$20  ; 9

HUD_FKEY: !scr "f7=menu", 0

!zone hud {

;--------------------------------------------
; InitHUD - pulisce area score righe 0-4
; A = colore HUD (non usato qui, per compatibilità)
;--------------------------------------------
InitHUD:
    ldx #39
.cl lda #$20
    sta SCRN+0*40,x : sta SCRN+1*40,x
    sta SCRN+2*40,x : sta SCRN+3*40,x
    sta SCRN+4*40,x
    dex : bpl .cl
    rts

;--------------------------------------------
; DrawInfoBar - riga 23: nome sx già scritto, F7=MENU dx
;--------------------------------------------
DrawInfoBar:
    lda #<(SCRN+23*40+33) : sta ZP_PTR
    lda #>(SCRN+23*40+33) : sta ZP_PTR+1
    lda #<HUD_FKEY : sta PRINT_SRC
    lda #>HUD_FKEY : sta PRINT_SRC+1
    jsr PrintStr
    ldx #39
-   lda #11 : sta COLRAM+23*40,x : dex : bpl -
    rts

;--------------------------------------------
; DrawScore1 - P1 a sinistra, 4 cifre col 0,4,8,12
; A = colore
;--------------------------------------------
DrawScore1:
    sta HUD_COL
    lda SCORE1_A : lsr : lsr : lsr : lsr
    ldx #0  : jsr .dd
    lda SCORE1_A : and #$0F
    ldx #4  : jsr .dd
    lda SCORE1_B : lsr : lsr : lsr : lsr
    ldx #8  : jsr .dd
    lda SCORE1_B : and #$0F
    ldx #12 : jsr .dd
    rts

;--------------------------------------------
; DrawScore2 - P2 a destra, 4 cifre col 24,28,32,36
; A = colore
;--------------------------------------------
DrawScore2:
    sta HUD_COL
    lda SCORE2_A : lsr : lsr : lsr : lsr
    ldx #24 : jsr .dd
    lda SCORE2_A : and #$0F
    ldx #28 : jsr .dd
    lda SCORE2_B : lsr : lsr : lsr : lsr
    ldx #32 : jsr .dd
    lda SCORE2_B : and #$0F
    ldx #36 : jsr .dd
    rts

;--------------------------------------------
; .dd: disegna cifra A a colonna X, righe 0-4
; A = cifra (0-9), X = colonna, HUD_COL = colore
;--------------------------------------------
.dd:
    sta HUD_TMP
    ; offset = A * 20 = A*16 + A*4
    asl : asl : asl : asl    ; A*16
    sta HUD_COL+1             ; salva A*16 (usiamo $28 temporaneo)
    lda HUD_TMP
    asl : asl                 ; A*4
    clc : adc HUD_COL+1       ; A*16 + A*4 = A*20
    tay                       ; Y = offset in tabella

    ; Scrivi 5 righe x 4 byte
    lda DIGIT_TABLE+ 0,y : sta SCRN+0*40+0,x
    lda DIGIT_TABLE+ 1,y : sta SCRN+0*40+1,x
    lda DIGIT_TABLE+ 2,y : sta SCRN+0*40+2,x
    lda DIGIT_TABLE+ 3,y : sta SCRN+0*40+3,x

    lda DIGIT_TABLE+ 4,y : sta SCRN+1*40+0,x
    lda DIGIT_TABLE+ 5,y : sta SCRN+1*40+1,x
    lda DIGIT_TABLE+ 6,y : sta SCRN+1*40+2,x
    lda DIGIT_TABLE+ 7,y : sta SCRN+1*40+3,x

    lda DIGIT_TABLE+ 8,y : sta SCRN+2*40+0,x
    lda DIGIT_TABLE+ 9,y : sta SCRN+2*40+1,x
    lda DIGIT_TABLE+10,y : sta SCRN+2*40+2,x
    lda DIGIT_TABLE+11,y : sta SCRN+2*40+3,x

    lda DIGIT_TABLE+12,y : sta SCRN+3*40+0,x
    lda DIGIT_TABLE+13,y : sta SCRN+3*40+1,x
    lda DIGIT_TABLE+14,y : sta SCRN+3*40+2,x
    lda DIGIT_TABLE+15,y : sta SCRN+3*40+3,x

    lda DIGIT_TABLE+16,y : sta SCRN+4*40+0,x
    lda DIGIT_TABLE+17,y : sta SCRN+4*40+1,x
    lda DIGIT_TABLE+18,y : sta SCRN+4*40+2,x
    lda DIGIT_TABLE+19,y : sta SCRN+4*40+3,x

    ; Colora 5 righe x 4 col
    lda HUD_COL
    sta COLRAM+0*40+0,x : sta COLRAM+0*40+1,x
    sta COLRAM+0*40+2,x : sta COLRAM+0*40+3,x
    sta COLRAM+1*40+0,x : sta COLRAM+1*40+1,x
    sta COLRAM+1*40+2,x : sta COLRAM+1*40+3,x
    sta COLRAM+2*40+0,x : sta COLRAM+2*40+1,x
    sta COLRAM+2*40+2,x : sta COLRAM+2*40+3,x
    sta COLRAM+3*40+0,x : sta COLRAM+3*40+1,x
    sta COLRAM+3*40+2,x : sta COLRAM+3*40+3,x
    sta COLRAM+4*40+0,x : sta COLRAM+4*40+1,x
    sta COLRAM+4*40+2,x : sta COLRAM+4*40+3,x
    rts

;--------------------------------------------
; AddScore1 / AddScore2 - aggiunge A punti BCD
;--------------------------------------------
AddScore1:
    sed
    clc : adc SCORE1_B : sta SCORE1_B
    lda #0 : adc SCORE1_A : sta SCORE1_A
    cld
    rts

AddScore2:
    sed
    clc : adc SCORE2_B : sta SCORE2_B
    lda #0 : adc SCORE2_A : sta SCORE2_A
    cld
    rts

;--------------------------------------------
; ClearScores
;--------------------------------------------
ClearScores:
    lda #0
    sta SCORE1_A : sta SCORE1_B : sta SCORE1_X
    sta SCORE2_A : sta SCORE2_B : sta SCORE2_X
    rts

}
