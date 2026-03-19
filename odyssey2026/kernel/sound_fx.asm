;============================================
; sound_fx.asm - Effetti sonori SID (Standardized Hardware Kill)
; Voice 3 dedicata agli SFX
; FIX: Aggiunto Spegnimento Brutale di ADSR e Filtri! Niente più suoni incantati.
;============================================
SFX_PAD     = 0   ; rimbalzo paddle / mattoncini
SFX_WALL    = 1   ; rimbalzo muro top/bottom / indistruttibili
SFX_GOAL    = 2   ; punto segnato
SFX_LOST    = 3   ; palla persa 
SFX_POWERUP = 4   ; palla rossa / bonus

; ZP
SFX_ACTIVE = $78  
SFX_PTR_L  = $79  
SFX_PTR_H  = $7A  
SFX_TIMER  = $7B  

; SID Voice 3
SID_V3_FL  = $D40E  
SID_V3_FH  = $D40F  
SID_V3_PL  = $D410  
SID_V3_PH  = $D411  
SID_V3_CTR = $D412  
SID_V3_AD  = $D413  
SID_V3_SR  = $D414  
SID_VOL    = $D418  
SID_FILT   = $D417  ; Filtri

SFX_TABLE:  
    !byte <SFX_DATA_PAD,     <SFX_DATA_WALL
    !byte <SFX_DATA_GOAL,    <SFX_DATA_LOST
    !byte <SFX_DATA_POWERUP
SFX_TABLE_H:
    !byte >SFX_DATA_PAD,     >SFX_DATA_WALL
    !byte >SFX_DATA_GOAL,    >SFX_DATA_LOST
    !byte >SFX_DATA_POWERUP

; --- PAD / BRICK ---
SFX_DATA_PAD:
    !byte $44,$1D,$11,$05   
    !byte $00,$00,$00,$00   

; --- WALL / METAL ---
SFX_DATA_WALL:
    !byte $BC,$57,$41,$03   
    !byte $00,$00,$00,$00   

; --- GOAL ---
SFX_DATA_GOAL:
    !byte $D5,$2B,$21,$08   
    !byte $C9,$22,$21,$08   
    !byte $44,$1D,$21,$0C   
    !byte $00,$00,$00,$00   

; --- LOST ---
SFX_DATA_LOST:
    !byte $A2,$0E,$81,$04   
    !byte $F3,$15,$21,$06   
    !byte $6D,$11,$21,$08   
    !byte $A2,$0E,$21,$0E   
    !byte $00,$00,$00,$00   

; --- POWERUP ---
SFX_DATA_POWERUP:
    !byte $44,$1D,$11,$04   
    !byte $D5,$2B,$11,$04   
    !byte $89,$3A,$11,$04   
    !byte $BC,$57,$11,$08   
    !byte $00,$00,$00,$00   

; ============================================
InitSFX:
    lda #0
    sta SFX_ACTIVE
    sta SFX_TIMER
    sta SID_FILT     ; <-- FIX: Spegne tutti i filtri lasciati aperti dalla musica!
    sta SID_V3_CTR   ; gate off
    sta SID_V3_AD    ; azzera attack/decay
    sta SID_V3_SR    ; azzera sustain/release
    lda #$0F : sta SID_VOL
    rts

; ============================================
PlaySFX:
    tax
    ; Hardware Kill preventivo
    lda #0 : sta SID_V3_CTR : sta SID_V3_AD : sta SID_V3_SR

    lda SFX_TABLE,x   : sta SFX_PTR_L
    lda SFX_TABLE_H,x : sta SFX_PTR_H

    lda #1 : sta SFX_ACTIVE
    lda #0 : sta SFX_TIMER    

; ============================================
UpdateSFX:
    lda SFX_ACTIVE : beq .sfx_idle
    pha : txa : pha : tya : pha   

    dec SFX_TIMER
    bpl .sfx_wait                 

    ldy #0
    lda (SFX_PTR_L),y : sta SID_V3_FL : iny  
    lda (SFX_PTR_L),y : sta SID_V3_FH : iny  

    lda (SFX_PTR_L),y                         
    bne .sfx_play                              

    ; --- FIX: HARDWARE KILL A FINE NOTA ---
    lda #0 
    sta SID_V3_CTR 
    sta SID_V3_AD
    sta SID_V3_SR
    sta SFX_ACTIVE
    jmp .sfx_restore

.sfx_play:
    lda (SFX_PTR_L),y : and #$F0              
    cmp #$80 : beq .sfx_noise_adsr            
    cmp #$10 : beq .sfx_tri_adsr              
    lda #$06 : sta SID_V3_AD                  
    lda #$A0 : sta SID_V3_SR                  
    jmp .sfx_do_ctrl
.sfx_noise_adsr:
    lda #$02 : sta SID_V3_AD                  
    lda #$00 : sta SID_V3_SR
    jmp .sfx_do_ctrl
.sfx_tri_adsr:
    lda #$04 : sta SID_V3_AD                  
    lda #$80 : sta SID_V3_SR                  
.sfx_do_ctrl:
    lda #$60 : sta SID_V3_PL
    lda #$08 : sta SID_V3_PH
    lda (SFX_PTR_L),y : sta SID_V3_CTR        

    iny
    lda (SFX_PTR_L),y : sta SFX_TIMER

    lda SFX_PTR_L : clc : adc #4 : sta SFX_PTR_L
    bcc .sfx_wait : inc SFX_PTR_H

.sfx_wait:
.sfx_restore:
    pla : tay : pla : tax : pla   
.sfx_idle:
    rts