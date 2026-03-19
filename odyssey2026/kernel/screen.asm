;============================================
; MODULO: screen.asm
; Progetto: Odyssey 2026
; Autore: Massimo
; Versione: 1.0
;
; Utility schermo:
; - ClearScreen
; - PrintStr (stringa con terminatore $00)
; - Dec3 (numero 0-255 in 3 cifre decimali)
; - Dec2 (numero 0-99 in 2 cifre decimali)
; - FillColorRAM
; - Tabelle indirizzi righe schermo
;
; Dipendenze: ZP_PTR, PRINT_SRC in main.asm
;============================================

;--------------------------------------------
; ClearScreen
; Pulisce schermo tramite KERNAL
; Colore testo: bianco ($01)
;--------------------------------------------
ClearScreen:
            ; Pulisce schermo scrivendo spazi ($20) diretti
            ; Non usa KERNAL per evitare conflitti col banking
            lda #$20            ; spazio (screen code)
            ldx #0
.cs_loop    sta SCRN+$000,x
            sta SCRN+$100,x
            sta SCRN+$200,x
            sta SCRN+$2E8,x     ; ultimi 40 bytes
            inx
            bne .cs_loop
            ; Colore bianco su tutta la color RAM
            lda #1
            jsr FillColorRAM
            ; Cursore off ($CC=1 = disabilitato)
            lda #1
            sta $CC
            rts

;--------------------------------------------
; FillColorRAM
; Riempie tutta la color RAM con colore in A
; Input: A = colore (0-15)
;--------------------------------------------
FillColorRAM:
            ldx #0
.fcr_loop   sta $D800,x
            sta $D900,x
            sta $DA00,x
            inx
            bne .fcr_loop
            ; ultimi 24 bytes ($D9E8-$DBFF inclusi)
            ldx #0
.fcr_last   sta $DBE8,x
            inx
            cpx #$18
            bne .fcr_last
            rts

;--------------------------------------------
; PrintStr
; Stampa stringa screen codes a destinazione
; Input: PRINT_SRC ($FD/$FE) = puntatore stringa
;        ZP_PTR ($FB/$FC)    = destinazione schermo
; Stringa terminata da $00
;--------------------------------------------
PrintStr:
            ldy #0
.ps_loop    lda (PRINT_SRC),y
            beq .ps_exit
            sta (ZP_PTR),y
            iny
            bne .ps_loop
.ps_exit    rts

;--------------------------------------------
; Dec3
; Converte byte 0-255 in 3 cifre decimali
; Input:  A = valore
;         X = indirizzo schermo lo
;         Y = indirizzo schermo hi
;--------------------------------------------
Dec3:
            stx ZP_PTR
            sty ZP_PTR+1
            ldy #0

            ldx #$FF
.d3h        inx
            sec
            sbc #100
            bcs .d3h
            adc #100
            pha
            txa
            ora #$30
            sta (ZP_PTR),y
            iny
            pla

            ldx #$FF
.d3t        inx
            sec
            sbc #10
            bcs .d3t
            adc #10
            pha
            txa
            ora #$30
            sta (ZP_PTR),y
            iny
            pla

            ora #$30
            sta (ZP_PTR),y
            rts

;--------------------------------------------
; Dec2
; Converte byte 0-99 in 2 cifre decimali
; Input:  A = valore
;         X = indirizzo schermo lo
;         Y = indirizzo schermo hi
;--------------------------------------------
Dec2:
            stx ZP_PTR
            sty ZP_PTR+1
            ldy #0

            ldx #$FF
.d2t        inx
            sec
            sbc #10
            bcs .d2t
            adc #10
            pha
            txa
            ora #$30
            sta (ZP_PTR),y
            iny
            pla

            ora #$30
            sta (ZP_PTR),y
            rts

;--------------------------------------------
; Tabella indirizzi righe schermo
; Uso: ldx #riga
;      lda ROW_TABLE_LO,x → ZP_PTR lo
;      lda ROW_TABLE_HI,x → ZP_PTR hi
;--------------------------------------------
ROW_TABLE_LO:
!byte <(SCRN+ 0*40), <(SCRN+ 1*40), <(SCRN+ 2*40)
!byte <(SCRN+ 3*40), <(SCRN+ 4*40), <(SCRN+ 5*40)
!byte <(SCRN+ 6*40), <(SCRN+ 7*40), <(SCRN+ 8*40)
!byte <(SCRN+ 9*40), <(SCRN+10*40), <(SCRN+11*40)
!byte <(SCRN+12*40), <(SCRN+13*40), <(SCRN+14*40)
!byte <(SCRN+15*40), <(SCRN+16*40), <(SCRN+17*40)
!byte <(SCRN+18*40), <(SCRN+19*40), <(SCRN+20*40)
!byte <(SCRN+21*40), <(SCRN+22*40), <(SCRN+23*40)
!byte <(SCRN+24*40)

ROW_TABLE_HI:
!byte >(SCRN+ 0*40), >(SCRN+ 1*40), >(SCRN+ 2*40)
!byte >(SCRN+ 3*40), >(SCRN+ 4*40), >(SCRN+ 5*40)
!byte >(SCRN+ 6*40), >(SCRN+ 7*40), >(SCRN+ 8*40)
!byte >(SCRN+ 9*40), >(SCRN+10*40), >(SCRN+11*40)
!byte >(SCRN+12*40), >(SCRN+13*40), >(SCRN+14*40)
!byte >(SCRN+15*40), >(SCRN+16*40), >(SCRN+17*40)
!byte >(SCRN+18*40), >(SCRN+19*40), >(SCRN+20*40)
!byte >(SCRN+21*40), >(SCRN+22*40), >(SCRN+23*40)
!byte >(SCRN+24*40)
