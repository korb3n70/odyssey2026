; ==========================================
; logo_screen.asm — Schermata Titolo Odyssey 2026
; Sfondo bianco, logo rosso, testi centrati, no linee
; ==========================================

    jmp StartDisclaimer

D_R09: !byte $20,$20,$20,$20,$20,$20,$2A,$2A,$2A,$20,$0F,$04,$19,$13,$13,$05,$19,$20,$32,$30,$32,$36,$20,$14,$12,$09,$02,$15,$14,$05,$20,$2A,$2A,$2A,$20,$20,$20,$20,$20,$20,$00
D_R10: !byte $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$0D,$01,$13,$13,$09,$0D,$0F,$20,$02,$0F,$0E,$0F,$0D,$0F,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$00
D_R12: !byte $20,$20,$20,$20,$20,$11,$15,$05,$13,$14,$0F,$20,$13,$0F,$06,$14,$17,$01,$12,$05,$20,$05,$27,$20,$15,$0E,$20,$14,$12,$09,$02,$15,$14,$0F,$20,$20,$20,$20,$20,$20,$00
D_R13: !byte $20,$20,$20,$20,$20,$07,$12,$01,$14,$15,$09,$14,$0F,$20,$0E,$0F,$0E,$20,$01,$20,$06,$09,$0E,$09,$20,$04,$09,$20,$0C,$15,$03,$12,$0F,$2E,$20,$20,$20,$20,$20,$20,$00
D_R14: !byte $20,$20,$20,$20,$09,$20,$04,$09,$12,$09,$14,$14,$09,$20,$04,$05,$0C,$20,$0D,$01,$12,$03,$08,$09,$0F,$20,$0F,$12,$09,$07,$09,$0E,$01,$0C,$05,$20,$20,$20,$20,$20,$00
D_R15: !byte $20,$20,$20,$01,$10,$10,$01,$12,$14,$05,$0E,$07,$0F,$0E,$0F,$20,$01,$20,$10,$08,$09,$0C,$09,$10,$13,$20,$05,$20,$0D,$01,$07,$0E,$01,$16,$0F,$18,$2E,$20,$20,$20,$00
D_R17: !byte $20,$20,$20,$20,$20,$09,$0C,$20,$04,$05,$13,$09,$07,$0E,$20,$10,$12,$05,$13,$05,$0E,$14,$01,$20,$03,$0F,$0D,$10,$12,$0F,$0D,$05,$13,$13,$09,$20,$20,$20,$20,$20,$00
D_R18: !byte $20,$20,$20,$07,$12,$01,$06,$09,$03,$09,$20,$04,$0F,$16,$15,$14,$09,$20,$01,$09,$20,$0C,$09,$0D,$09,$14,$09,$20,$04,$05,$0C,$20,$03,$36,$34,$2E,$20,$20,$20,$20,$00
D_R20: !byte $20,$20,$20,$06,$31,$2D,$12,$05,$13,$05,$14,$20,$20,$06,$33,$2F,$06,$35,$2D,$16,$01,$12,$09,$01,$0E,$14,$05,$20,$20,$06,$37,$2D,$0D,$05,$0E,$15,$20,$20,$20,$20,$00
D_R22: !byte $20,$20,$20,$20,$20,$20,$2D,$20,$10,$12,$05,$0D,$09,$20,$06,$09,$12,$05,$20,$10,$05,$12,$20,$09,$0E,$09,$1A,$09,$01,$12,$05,$20,$2D,$20,$20,$20,$20,$20,$20,$20,$00

; Logo 6x28 screen codes
LOGO_DATA:
    !byte $90,$91,$92,$93,$94,$95,$96,$97,$98,$99,$9A,$9B,$9C,$9D,$9E,$9F,$A1,$A2,$A3,$A4,$A5,$A6,$A7,$9B,$A8,$A9,$AA,$A1  ; riga 0
    !byte $AB,$AC,$AD,$AE,$AF,$B0,$B1,$AE,$B2,$B3,$B4,$B5,$B6,$B7,$B8,$B9,$BA,$BB,$BC,$B8,$BD,$BE,$BF,$C0,$C1,$C2,$C3,$C4  ; riga 1
    !byte $AB,$C5,$C6,$C7,$C8,$C9,$CA,$CB,$CC,$CD,$CE,$CF,$D0,$D1,$D2,$D3,$D4,$D5,$AC,$D6,$D2,$D7,$BF,$D8,$D9,$DA,$DB,$C0  ; riga 2
    !byte $DC,$DD,$DE,$DF,$E0,$E1,$E2,$E1,$E3,$E4,$E5,$DF,$E6,$E7,$E8,$E9,$EA,$E1,$EB,$EC,$ED,$EE,$EF,$F0,$F1,$F2,$F3,$F4  ; riga 3
    !byte $F5,$D2,$D2,$D2,$D2,$D2,$D2,$D2,$D2,$D2,$D2,$D2,$D2,$D2,$D2,$D2,$D2,$D2,$D2,$D2,$D2,$D2,$D2,$D2,$D2,$D2,$AC,$F6  ; riga 4
    !byte $F7,$D2,$D2,$D2,$D2,$D2,$D2,$D2,$D2,$D2,$D2,$D2,$D2,$D2,$D2,$D2,$D2,$D2,$D2,$D2,$D2,$D2,$D2,$D2,$D2,$D2,$F8,$F9  ; riga 5

!zone disclaimer_screen {
StartDisclaimer:
    sei
    lda #$36 : sta $01

    lda #$FF : sta $DC02
    lda #$00 : sta $DC00

    lda $D011 : and #$EF : sta $D011
    lda #1 : sta $D020 : sta $D021   ; bordo e sfondo bianchi
    lda #0 : sta VIC_SPREN
    lda #1 : sta $CC
    lda #$1E : sta $D018

    ; Pulisci schermo — colram=1 (bianco su bianco = invisibile)
    ldx #0
.cls:
    lda #$20
    sta SCRN+$000,x : sta SCRN+$100,x
    sta SCRN+$200,x : sta SCRN+$300,x
    lda #1
    sta COLRAM+$000,x : sta COLRAM+$100,x
    sta COLRAM+$200,x : sta COLRAM+$300,x
    inx : bne .cls

    ; --- Logo ODYSSEY 2100 in rosso (6x28, riga 1 col 6) ---
    lda #0 : sta $FD
    lda #0 : sta $FE

.logo_row:
    lda $FE : clc : adc #1
    tax
    clc
    lda ROW_TABLE_LO,x : adc #6 : sta ZP_PTR
    lda ROW_TABLE_HI,x : adc #0 : sta ZP_PTR+1
    clc
    lda ZP_PTR   : adc #0   : sta $F9
    lda ZP_PTR+1 : adc #$D4 : sta $FA
    lda #2 : sta $FF        ; rosso
    ldy #0
.logo_col:
    ldx $FD
    lda LOGO_DATA,x : sta (ZP_PTR),y
    lda $FF         : sta ($F9),y
    inc $FD
    iny : cpy #28 : bcc .logo_col
    inc $FE : lda $FE : cmp #6 : bcc .logo_row

    ; --- Testi centrati ---
    lda #$68 : sta ZP_PTR : lda #$05 : sta ZP_PTR+1
    lda #<D_R09 : sta PRINT_SRC : lda #>D_R09 : sta PRINT_SRC+1 : jsr PrintStr
    ldx #38
-   lda #$02 : sta COLRAM+9*40,x : dex : bpl -
    lda #$90 : sta ZP_PTR : lda #$05 : sta ZP_PTR+1
    lda #<D_R10 : sta PRINT_SRC : lda #>D_R10 : sta PRINT_SRC+1 : jsr PrintStr
    ldx #38
-   lda #$00 : sta COLRAM+10*40,x : dex : bpl -
    lda #$E0 : sta ZP_PTR : lda #$05 : sta ZP_PTR+1
    lda #<D_R12 : sta PRINT_SRC : lda #>D_R12 : sta PRINT_SRC+1 : jsr PrintStr
    ldx #38
-   lda #$06 : sta COLRAM+12*40,x : dex : bpl -
    lda #$08 : sta ZP_PTR : lda #$06 : sta ZP_PTR+1
    lda #<D_R13 : sta PRINT_SRC : lda #>D_R13 : sta PRINT_SRC+1 : jsr PrintStr
    ldx #38
-   lda #$06 : sta COLRAM+13*40,x : dex : bpl -
    lda #$30 : sta ZP_PTR : lda #$06 : sta ZP_PTR+1
    lda #<D_R14 : sta PRINT_SRC : lda #>D_R14 : sta PRINT_SRC+1 : jsr PrintStr
    ldx #38
-   lda #$06 : sta COLRAM+14*40,x : dex : bpl -
    lda #$58 : sta ZP_PTR : lda #$06 : sta ZP_PTR+1
    lda #<D_R15 : sta PRINT_SRC : lda #>D_R15 : sta PRINT_SRC+1 : jsr PrintStr
    ldx #38
-   lda #$06 : sta COLRAM+15*40,x : dex : bpl -
    lda #$A8 : sta ZP_PTR : lda #$06 : sta ZP_PTR+1
    lda #<D_R17 : sta PRINT_SRC : lda #>D_R17 : sta PRINT_SRC+1 : jsr PrintStr
    ldx #38
-   lda #$06 : sta COLRAM+17*40,x : dex : bpl -
    lda #$D0 : sta ZP_PTR : lda #$06 : sta ZP_PTR+1
    lda #<D_R18 : sta PRINT_SRC : lda #>D_R18 : sta PRINT_SRC+1 : jsr PrintStr
    ldx #38
-   lda #$06 : sta COLRAM+18*40,x : dex : bpl -
    lda #$20 : sta ZP_PTR : lda #$07 : sta ZP_PTR+1
    lda #<D_R20 : sta PRINT_SRC : lda #>D_R20 : sta PRINT_SRC+1 : jsr PrintStr
    ldx #38
-   lda #$00 : sta COLRAM+20*40,x : dex : bpl -
    lda #$70 : sta ZP_PTR : lda #$07 : sta ZP_PTR+1
    lda #<D_R22 : sta PRINT_SRC : lda #>D_R22 : sta PRINT_SRC+1 : jsr PrintStr
    ldx #38
-   lda #$02 : sta COLRAM+22*40,x : dex : bpl -

    lda $D011 : ora #$10 : sta $D011
    cli

.drain:
    jsr $FFE4
    cmp #0 : bne .drain

WaitInput:
    lda $DC00 : and #$10 : beq .exit
    jsr $FFE4 : cmp #0 : bne .exit
    jmp WaitInput

.exit:
    lda #0 : sta $C6
    jmp MenuSelect
}