; ==========================================
; menu_select.asm - V18 (Games moved up & Line removed)
; FIX: Rimossa riga orizzontale partendo a pulire lo schermo dalla riga 4.
; FIX: Spostata in alto di 4 righe la selezione dei giochi (1-6).
; ==========================================
MN_SCRDATA  = $3000
MN_CLRDATA  = $3400
MN_CHARSET  = $3800
VIC_MEMCTRL = $D018
MN_D018_NORM = $16      
MN_D018_MENU = $1E      
VICBKGD = $D021
VICBORD = $D020
SCRN    = $0400
COLRAM  = $D800
VIC_SPREN = $D015

; Variabile Globale per i controlli (0 = Entrambi Port 1, 1 = Port 1 e Port 2)
GLOBAL_PAD_CFG = $033C

* = $2800

MenuSelect:
    ldx #$FF
    txs

    sei     ; Blocchiamo gli interrupt per sicurezza

    ; --- SILENZIA IL SID COMPLETAMENTE ---
    lda #0
    ldx #0
.cl_sid:
    sta $D400,x
    inx
    cpx #25
    bne .cl_sid

    ; --- PULIZIA ZERO PAGE (Previene Bug Batteria e corruzione) ---
    lda #0
    ldx #$02
.cl_zp1:
    sta $00,x : inx : cpx #$80 : bne .cl_zp1

    ldx #$F0
.cl_zp2:
    sta $00,x : inx : cpx #$FF : bne .cl_zp2
    
    ; --- INIZIALIZZA LA VARIABILE PADDLE ---
    lda GLOBAL_PAD_CFG
    cmp #$00 : beq .cfg_ok
    cmp #$01 : beq .cfg_ok
    lda #$00 : sta GLOBAL_PAD_CFG   ; Default a 0 se trova spazzatura
.cfg_ok:
    ; -----------------------------------------

    lda #$FF : sta $DC02 
    lda #$00 : sta $DC00 

    lda $D011 : and #$EF : sta $D011    
    lda #6 : sta VICBKGD : lda #6 : sta VICBORD
    lda #0 : sta $C6 : sta VIC_SPREN
    lda #1 : sta $CC

    lda #MN_D018_MENU : sta VIC_MEMCTRL

    ldx #0
.cps0: lda MN_SCRDATA+$000,x : sta SCRN+$000,x : inx : bne .cps0
    ldx #0
.cps1: lda MN_SCRDATA+$100,x : sta SCRN+$100,x : inx : bne .cps1
    ldx #0
.cps2: lda MN_SCRDATA+$200,x : sta SCRN+$200,x : inx : bne .cps2
    ldx #0
.cps3: lda MN_SCRDATA+$300,x : sta SCRN+$300,x : inx : cpx #232 : bne .cps3

    ldx #0
.cpc0: lda MN_CLRDATA+$000,x : sta COLRAM+$000,x : inx : bne .cpc0
    ldx #0
.cpc1: lda MN_CLRDATA+$100,x : sta COLRAM+$100,x : inx : bne .cpc1
    ldx #0
.cpc2: lda MN_CLRDATA+$200,x : sta COLRAM+$200,x : inx : bne .cpc2
    ldx #0
.cpc3: lda MN_CLRDATA+$300,x : sta COLRAM+$300,x : inx : cpx #232 : bne .cpc3

    ; ---> PATCH GRAFICA IN ESADECIMALE ASSOLUTO <---
    jsr ApplyMenuPatch

    lda $D011 : ora #$10 : sta $D011    

    ; --- MUSICA IN BACKGROUND ---
    lda #0 
    jsr $1000               ; Init Menu Theme (Subtune 0)
    lda #$0F : sta $D418    ; Accende il volume al massimo

    lda #<MN_IRQ : sta $0314
    lda #>MN_IRQ : sta $0315
    cli                     

MS_Loop:
    jsr $FFE4
    cmp #0 : beq MS_Loop

    cmp #$43 : bne .c1      ; Tasto C ($43) per cambiare controlli!
    lda GLOBAL_PAD_CFG
    eor #1                  ; Inverte 0 <-> 1
    sta GLOBAL_PAD_CFG
    jsr DrawPaddleStatus    ; Aggiorna la scritta e i colori a schermo
    jmp MS_Loop

.c1 cmp #$31 : bne .c2
    jsr MN_StopMusic : jsr Breakout  : jmp MenuSelect
.c2 cmp #$32 : bne .c3
    jsr MN_StopMusic : jsr Flipper   : jmp MenuSelect
.c3 cmp #$33 : bne .c4
    jsr MN_StopMusic : jsr Tennis    : jmp MenuSelect
.c4 cmp #$34 : bne .c5
    jsr MN_StopMusic : jsr Handball  : jmp MenuSelect
.c5 cmp #$35 : bne .c6
    jsr MN_StopMusic : jsr Hockey    : jmp MenuSelect
.c6 cmp #$36 : bne MS_Loop
    jsr MN_StopMusic : jsr Football  : jmp MenuSelect

; --- IRQ musica menu ---
MN_IRQ:
    jsr $1006               ; mus_play
    jmp $EA31               ; ritorna al KERNAL IRQ

; --- Stop musica + ripristina IRQ KERNAL ---
MN_StopMusic:
    sei
    jsr $1003               ; mus_stop
    
    lda #0 : ldx #0
.cl_sm: 
    sta $D400,x : inx : cpx #25 : bne .cl_sm

    lda #$31 : sta $0314    
    lda #$EA : sta $0315
    cli
    rts

MN_Activate:
    lda #$1E : sta $D018   
    rts

MN_Restore:
    lda #MN_D018_NORM : sta VIC_MEMCTRL
    rts

; ========================================================
; ROUTINE DI SOVRASCRITTURA SCHERMO (PATCH GRAFICA)
; ========================================================
ApplyMenuPatch:
    ; Pulisce l'area centrale e bassa (da riga 4 a riga 23) cancellando la linea
    lda #<$04A0 : sta $FB : lda #>$04A0 : sta $FC
    lda #<$D8A0 : sta $FD : lda #>$D8A0 : sta $FE
    ldx #20     
.clr_row:
    ldy #0
    lda #$20    ; Spazio (Cancella)
.clr_col:
    sta ($FB),y : iny : cpy #40 : bne .clr_col
    lda $FB : clc : adc #40 : sta $FB : lda $FC : adc #0 : sta $FC
    lda $FD : clc : adc #40 : sta $FD : lda $FE : adc #0 : sta $FE
    dex : bne .clr_row

    ; --- STAMPA I GIOCHI ---
    ldx #0 

    ; Riga 6
    lda #<$04F7 : sta $FB : lda #>$04F7 : sta $FC : lda #<$D8F7 : sta $FD : lda #>$D8F7 : sta $FE
    lda #1 : sta $8F : lda #0 : jsr PrintStringByIndex ; 1 BREAKOUT

    lda #<$0507 : sta $FB : lda #>$0507 : sta $FC : lda #<$D907 : sta $FD : lda #>$D907 : sta $FE
    lda #1 : sta $8F : lda #1 : jsr PrintStringByIndex ; 4 HANDBALL

    ; Riga 8
    lda #<$0547 : sta $FB : lda #>$0547 : sta $FC : lda #<$D947 : sta $FD : lda #>$D947 : sta $FE
    lda #1 : sta $8F : lda #2 : jsr PrintStringByIndex ; 2 FLIPPER

    lda #<$0557 : sta $FB : lda #>$0557 : sta $FC : lda #<$D957 : sta $FD : lda #>$D957 : sta $FE
    lda #1 : sta $8F : lda #3 : jsr PrintStringByIndex ; 5 HOCKEY

    ; Riga 10
    lda #<$0597 : sta $FB : lda #>$0597 : sta $FC : lda #<$D997 : sta $FD : lda #>$D997 : sta $FE
    lda #1 : sta $8F : lda #4 : jsr PrintStringByIndex ; 3 TENNIS

    lda #<$05A7 : sta $FB : lda #>$05A7 : sta $FC : lda #<$D9A7 : sta $FD : lda #>$D9A7 : sta $FE
    lda #1 : sta $8F : lda #5 : jsr PrintStringByIndex ; 6 FOOTBALL

    ; --- INTESTAZIONE CONFIGURAZIONE CONTROLLI (Riga 17, Bianco, Centrata) ---
    lda #<$06B0 : sta $FB : lda #>$06B0 : sta $FC : lda #<$DAB0 : sta $FD : lda #>$DAB0 : sta $FE
    lda #1 : sta $8F : lda #6 : jsr PrintStringByIndex

    ; --- INTESTAZIONE TASTI (Riga 21, Bianco, Centrata) ---
    lda #<$0754 : sta $FB : lda #>$0754 : sta $FC : lda #<$DB54 : sta $FD : lda #>$DB54 : sta $FE
    lda #1 : sta $8F : lda #7 : jsr PrintStringByIndex ; IN GAME KEYS:

    ; --- LEGENDA TASTI (Righe 22 e 23, Giallo) ---
    lda #<$0774 : sta $FB : lda #>$0774 : sta $FC : lda #<$DB74 : sta $FD : lda #>$DB74 : sta $FE
    lda #7 : sta $8F : lda #8 : jsr PrintStringByIndex ; F1 RESTART - F7 MENU...

    lda #<$079A : sta $FB : lda #>$079A : sta $FC : lda #<$DB9A : sta $FD : lda #>$DB9A : sta $FE
    lda #7 : sta $8F : lda #9 : jsr PrintStringByIndex ; F3/F5 VARIANT...

    ; Stampa lo stato dinamico e i colori dei Paddle (Riga 18)
    jsr DrawPaddleStatus
    rts

; ========================================================
; MOTORE DI STAMPA DINAMICO E COLORAZIONE PADDLE
; ========================================================
DrawPaddleStatus:
    ; Sceglie la stringa in base alla configurazione
    lda GLOBAL_PAD_CFG
    bne .dp_p2
    lda #10     ; Stringa 10 (Entrambi Port 1)
    jmp .dp_draw
.dp_p2:
    lda #11     ; Stringa 11 (P1 Port 1, P2 Port 2)
    
.dp_draw:
    pha         ; Salva l'indice
    lda #<$06D2 : sta $FB : lda #>$06D2 : sta $FC   ; Coordinate Riga 18
    lda #<$DAD2 : sta $FD : lda #>$DAD2 : sta $FE
    lda #1 : sta $8F                                ; Stampa base in Bianco
    pla         ; Recupera indice
    jsr PrintStringByIndex

    ; --- APPICAZIONE COLORI SPECIFICI (VERDE E CIANO) ---
    ; Colora la prima porta (Sempre Verde = 5)
    ldy #0
    lda #5
.col_port1:
    sta $DADC,y     ; Offset esatto per "PORT 1"
    iny
    cpy #6
    bne .col_port1

    ; Colora la seconda porta (Verde o Ciano in base al config)
    lda GLOBAL_PAD_CFG
    bne .is_cyan
    lda #5          ; Se entrambi su Port 1, anche il secondo è Verde
    jmp .apply_p2
.is_cyan:
    lda #3          ; Ciano per Port 2
.apply_p2:
    ldy #0
.col_port2:
    sta $DAEE,y     ; Offset esatto per la seconda "PORT X"
    iny
    cpy #6
    bne .col_port2

    rts

PrintStringByIndex:
    sta $8E         
    ldx #0
    lda $8E
    beq .psbi_print 
.psbi_find:
    lda MenuStrings,x
    inx
    cmp #0          
    bne .psbi_find
    dec $8E
    bne .psbi_find  
.psbi_print:
    ldy #0
.psbi_lp:
    lda MenuStrings,x
    beq .psbi_end
    sta ($FB),y
    lda $8F
    sta ($FD),y
    inx
    iny
    jmp .psbi_lp
.psbi_end:
    rts

; ========================================================
; ARCHIVIO STRINGHE
; ========================================================
MenuStrings:
; 0: "1 BREAKOUT"
!byte $31,$20,$02,$12,$05,$01,$0B,$0F,$15,$14,0
; 1: "4 HANDBALL"
!byte $34,$20,$08,$01,$0E,$04,$02,$01,$0C,$0C,0
; 2: "2 FLIPPER"
!byte $32,$20,$06,$0C,$09,$10,$10,$05,$12,0
; 3: "5 HOCKEY"
!byte $35,$20,$08,$0F,$03,$0B,$05,$19,0
; 4: "3 TENNIS"
!byte $33,$20,$14,$05,$0E,$0E,$09,$13,0
; 5: "6 FOOTBALL"
!byte $36,$20,$06,$0F,$0F,$14,$02,$01,$0C,$0C,0

; 6: " CONTROL CONFIGURATION: "
!byte $20,$03,$0F,$0E,$14,$12,$0F,$0C,$20,$03,$0F,$0E,$06,$09,$07,$15,$12,$01,$14,$09,$0F,$0E,$3A,$20,0

; 7: " IN GAME KEYS: " 
!byte $20,$09,$0E,$20,$07,$01,$0D,$05,$20,$0B,$05,$19,$13,$3A,$20,0

; 8: " F1 RESTART - F7 MENU - P PAUSE "
!byte $20,$06,$31,$20,$12,$05,$13,$14,$01,$12,$14,$20,$2D,$20,$06,$37,$20,$0D,$05,$0E,$15,$20,$2D,$20,$10,$20,$10,$01,$15,$13,$05,$20,0

; 9: " F3/F5 VARIANT - C SWITCH CONTROLS "
!byte $20,$06,$33,$2F,$06,$35,$20,$16,$01,$12,$09,$01,$0E,$14,$20,$2D,$20,$03,$20,$13,$17,$09,$14,$03,$08,$20,$03,$0F,$0E,$14,$12,$0F,$0C,$13,$20,0

; 10: " PADDLE 1 PORT 1 - PADDLE 2 PORT 1 "
!byte $20,$10,$01,$04,$04,$0C,$05,$20,$31,$20,$10,$0F,$12,$14,$20,$31,$20,$2D,$20,$10,$01,$04,$04,$0C,$05,$20,$32,$20,$10,$0F,$12,$14,$20,$31,$20,0

; 11: " PADDLE 1 PORT 1 - PADDLE 2 PORT 2 "
!byte $20,$10,$01,$04,$04,$0C,$05,$20,$31,$20,$10,$0F,$12,$14,$20,$31,$20,$2D,$20,$10,$01,$04,$04,$0C,$05,$20,$32,$20,$10,$0F,$12,$14,$20,$32,$20,0