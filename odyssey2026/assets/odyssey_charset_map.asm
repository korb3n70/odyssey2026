;============================================================
; odyssey_charset_map.asm — Costanti screen code per odyssey_charset.bin
;
; odyssey_charset.bin @ $3800, D018=$1E
; Screen codes IDENTICI al charset ROM C64 uppercase.
; Unica differenza: $A0 = mattoncino 7x7 invece del blocco 8x8.
;
; Lettere A-Z: screen code $01-$1A (come ROM)
; Cifre  0-9:  screen code $30-$39 (come ROM)
; Spazio:      $20 o $00
;============================================================

; Bordi (identici ai codici grafici ROM C64)
BRD_HLINE  = $40   ; ─  linea orizzontale
BRD_VLINE  = $5D   ; │  linea verticale
BRD_TL     = $6D   ; ╔  angolo top-left
BRD_TR     = $6E   ; ╗  angolo top-right
BRD_BL     = $70   ; ╚  angolo bottom-left
BRD_BR     = $7D   ; ╝  angolo bottom-right

; Mattoncino Breakout
BRD_WALL   = $61   ; ▉  blocco 7x7 (mattoncino Breakout)

; Lettere (come ROM uppercase)
CHR_A=$01 : CHR_B=$02 : CHR_C=$03 : CHR_D=$04
CHR_E=$05 : CHR_F=$06 : CHR_G=$07 : CHR_H=$08
CHR_I=$09 : CHR_J=$0A : CHR_K=$0B : CHR_L=$0C
CHR_M=$0D : CHR_N=$0E : CHR_O=$0F : CHR_P=$10
CHR_Q=$11 : CHR_R=$12 : CHR_S=$13 : CHR_T=$14
CHR_U=$15 : CHR_V=$16 : CHR_W=$17 : CHR_X=$18
CHR_Y=$19 : CHR_Z=$1A

; Cifre (come ROM)
CHR_0=$30 : CHR_1=$31 : CHR_2=$32 : CHR_3=$33
CHR_4=$34 : CHR_5=$35 : CHR_6=$36 : CHR_7=$37
CHR_8=$38 : CHR_9=$39

CHR_SPACE  = $20
CHR_DOT    = $2E
CHR_DASH   = $2D
CHR_LBRK   = $1B  ; [
CHR_RBRK   = $1D  ; ]
