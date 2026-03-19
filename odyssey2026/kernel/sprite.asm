;============================================
; MODULO: sprite.asm
; Progetto: Odyssey 2026
; Autore: Massimo
; Versione: 1.0
;
; Utility VIC-II sprite:
; - InitSprites  : setup base sprite
; - SetSpritePos : posiziona sprite X/Y
; - EnableSprite : abilita/disabilita sprite
;
; Layout sprite:
;   Sprite 0 → palla
;   Sprite 1 → racchetta P1
;   Sprite 2 → racchetta P2
;   Sprite 3 → racchetta P1b (4 paddle)
;   Sprite 4 → racchetta P2b (4 paddle)
;   Sprite 5 → effetto gol / flash
;   Sprite 6 → libero
;   Sprite 7 → libero
;
; Puntatori sprite shape a $07F8-$07FF
; Shape base a $1800 (blocco 96 = $1800/$40)
;============================================

; --- Registri VIC-II sprite ---
VIC_SP0X    = $D000
VIC_SP0Y    = $D001
VIC_SPMSB   = $D010     ; MSB X per tutti sprite
VIC_SPREN   = $D015     ; enable
VIC_SPBGPR  = $D01B     ; sprite-bg priority
VIC_SPMCOL  = $D01C     ; multicolor enable
VIC_SPEXX   = $D01D     ; expand X
VIC_SPEXY   = $D017     ; expand Y
VIC_SPCOL0  = $D027     ; colori sprite 0-7
VIC_SPHIT   = $D01E     ; sprite-sprite collision
VIC_SPBGHIT = $D01F     ; sprite-bg collision

; Puntatori shape sprite (in screen bank)
SPR_PTR     = $07F8     ; base puntatori ($07F8-$07FF)

; Offset shape nella VRAM ($1800 = blocco 96)
SPR_BLOCK0  = 96        ; $1800 / $40 = 96

;--------------------------------------------
; InitSprites
; Setup iniziale: disabilita tutti,
; imposta puntatori shape, colori base
;--------------------------------------------
InitSprites:
            ; Disabilita tutti gli sprite
            lda #0
            sta VIC_SPREN

            ; Puntatori shape → blocco 96+ ($1800+)
            lda #SPR_BLOCK0+0
            sta SPR_PTR+0       ; sprite 0 → $1800
            lda #SPR_BLOCK0+1
            sta SPR_PTR+1       ; sprite 1 → $1840
            lda #SPR_BLOCK0+2
            sta SPR_PTR+2       ; sprite 2 → $1880
            lda #SPR_BLOCK0+3
            sta SPR_PTR+3       ; sprite 3 → $18C0
            lda #SPR_BLOCK0+4
            sta SPR_PTR+4       ; sprite 4 → $1900
            lda #SPR_BLOCK0+5
            sta SPR_PTR+5       ; sprite 5 → $1940
            lda #SPR_BLOCK0+6
            sta SPR_PTR+6       ; sprite 6 → $1980
            lda #SPR_BLOCK0+7
            sta SPR_PTR+7       ; sprite 7 → $19C0

            ; Nessun multicolor (sprite monocromatici)
            lda #0
            sta VIC_SPMCOL

            ; Nessun expand
            sta VIC_SPEXX
            sta VIC_SPEXY

            ; Colori sprite
            lda #1              ; bianco
            sta VIC_SPCOL0+0    ; sprite 0 (palla)
            lda #7              ; giallo
            sta VIC_SPCOL0+1    ; sprite 1 (P1)
            lda #5              ; verde
            sta VIC_SPCOL0+2    ; sprite 2 (P2)
            lda #7
            sta VIC_SPCOL0+3    ; sprite 3 (P1b)
            lda #5
            sta VIC_SPCOL0+4    ; sprite 4 (P2b)
            lda #2              ; rosso
            sta VIC_SPCOL0+5    ; sprite 5 (fx)

            rts

;--------------------------------------------
; SetSpriteXY
; Posiziona uno sprite
; Input: A = numero sprite (0-7)
;        ZP_PTR   lo = X
;        ZP_PTR+1 hi = Y (usa solo lo byte)
; Nota: gestisce bit MSB X (>255)
;--------------------------------------------
SetSpriteXY:
            ; offset = sprite * 2
            asl
            tax
            lda ZP_PTR          ; X lo
            sta VIC_SP0X,x
            lda ZP_PTR+1        ; Y
            sta VIC_SP0Y,x
            rts

;--------------------------------------------
; EnableSprites
; Input: A = bitmask sprite da abilitare
;        (es. %00000111 = sprite 0,1,2)
;--------------------------------------------
EnableSprites:
            sta VIC_SPREN
            rts

;--------------------------------------------
; CheckCollision
; Ritorna stato collisione sprite-sprite
; Output: A = registro $D01E (bit=1 → hit)
; NOTA: lettura azzera il registro
;--------------------------------------------
CheckCollision:
            lda VIC_SPHIT
            rts
