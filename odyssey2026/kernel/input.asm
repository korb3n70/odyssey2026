;============================================
; input.asm v7.0 - Pattern dal codice funzionante
; CheckKeys: legge KBD_COUNT/$C6 + KBD_BUF/$0277
; Output: A = PETSCII tasto, oppure 0
;============================================

ClearFlags:
            lda #0
            sta FLAG_F1 : sta FLAG_F3
            sta FLAG_F5 : sta FLAG_F7
            sta KEY_PRESSED
            rts

;--------------------------------------------
; CheckKeys - identico al codice funzionante
; Output: A = PETSCII oppure 0
;--------------------------------------------
CheckKeys:
            lda KBD_COUNT       ; $C6
            beq .no_key
            lda KBD_BUF         ; $0277
            ldx #0 : stx KBD_COUNT
            rts
.no_key     lda #0
            rts

;--------------------------------------------
; ReadMenuKey (alias per compatibilità)
;--------------------------------------------
ReadMenuKey:
            jmp CheckKeys

; Alias non più usati ma presenti per sicurezza
HandleGameKeys:     rts
WaitKeyRelease:     lda #0 : sta KBD_COUNT : rts
WaitAllKeysUp:      lda #0 : sta KBD_COUNT : rts
ReadInput:          jmp CheckKeys
