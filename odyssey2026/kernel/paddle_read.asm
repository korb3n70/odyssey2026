;============================================
; paddle_read.asm - Pattern dal codice funzionante
; SEI → leggi → $DC02=$FF → $DC00=$FF → CLI
;============================================
ReadPaddles:
            sei
            lda #%11000000
            sta CIA1DDR         ; bit 6-7 output per MUX

            ; Porta 1
            lda #%01000000
            sta CIA1PA
            ldy #$80
.w1         dey : bne .w1
            lda POTX : sta POT1X
            lda POTY : sta POT1Y

            ; Porta 2
            lda #%10000000
            sta CIA1PA
            ldy #$80
.w2         dey : bne .w2
            lda POTX : sta POT2X
            lda POTY : sta POT2Y

            ; Fire porta 1
            lda CIA1PB
            pha
            and #%00000100 : eor #%00000100
            beq .f1xz : lda #1 : bne .f1xd
.f1xz       lda #0
.f1xd       sta FIRE1X
            pla
            and #%00001000 : eor #%00001000
            beq .f1yz : lda #1 : bne .f1yd
.f1yz       lda #0
.f1yd       sta FIRE1Y

            ; Fire porta 2
            lda CIA1PA
            pha
            and #%00000100 : eor #%00000100
            beq .f2xz : lda #1 : bne .f2xd
.f2xz       lda #0
.f2xd       sta FIRE2X
            pla
            and #%00001000 : eor #%00001000
            beq .f2yz : lda #1 : bne .f2yd
.f2yz       lda #0
.f2yd       sta FIRE2Y

            ; OBBLIGATORIO: rilascia CIA1 per keyboard scan
            lda #$FF : sta CIA1DDR
            lda #$FF : sta CIA1PA
            cli
            rts
