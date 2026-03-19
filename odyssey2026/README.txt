================================================
  ODYSSEY 2026 - Commodore 64
  Autore: Massimo Bonono
  Assembler: ACME
================================================

STRUTTURA PROGETTO
------------------
odyssey2026\
  main.asm              Entry point + costanti globali
  build.bat             Script compilazione + lancio VICE

  kernel\
    paddle_read.asm     Lettura 4 paddle (collaudata su HW reale)
    input.asm           Gestione tastiera F1/F3/F5/F7 + 1-6
    screen.asm          Utility schermo (clear, print, Dec3)
    sprite.asm          Utility VIC-II sprite
    sound_fx.asm        Effetti sonori SID voice 3

  menu\
    logo_screen.asm     Schermata logo Odyssey 2026
    menu_select.asm     Menu selezione giochi 1-6

  games\
    game_tennis.asm     Tennis (varianti 1-2)
    game_breakout.asm   Breakout (varianti 1-7)
    game_flipper.asm    Flipper (varianti 1-7)
    game_handball.asm   Handball (varianti 1-2)
    game_hockey.asm     Hockey (varianti 1-2)
    game_football.asm   Football (varianti 1-3)

  assets\
    fastidio.sid        Fastidio porting Massimo Bonomo

MAPPA MEMORIA
-------------
$0801-$080C   BASIC stub SYS 2061
$080D-$0FFF   Kernel (paddle, input, screen, sprite, sfx)
$1000-$17FF   Charset custom (font Odyssey 2026)
$1800-$1FFF   Sprite shapes
$2000-$2FFF   Logo screen
$2800-$3FFF   Menu select
$4000-$5FFF   Tennis
$6000-$6FFF   Breakout
$7000-$7FFF   Flipper
$8000-$8FFF   Handball
$9000-$97FF   Hockey
$9800-$9FFF   Football
$A000-$B529   SID Auf Wiedersehen Monty (Rob Hubbard)
$D000-$DFFF   I/O Hardware (VIC/SID/CIA)
$E000-$FFFF   KERNAL ROM

CONTROLLI
---------
Menu principale:
  1-6           Seleziona gioco

In-game:
  F1            Restart gioco corrente
  F3            Variante successiva (con restart)
  F5            Variante precedente (con restart)
  F7            Torna al menu principale

SID - Auf Wiedersehen Monty
---------------------------
Load range  : $A000-$B529
Init address: $A8E2
Play address: $A40F
Brani       : 13
Default     : 1

COMPILAZIONE
------------
1. Copia AWM_A000.sid in assets\
2. Esegui build.bat

STATO SVILUPPO
--------------
[OK] Struttura progetto
[OK] Kernel: paddle_read (collaudato su HW reale)
[OK] Kernel: input, screen, sprite, sound_fx
[OK] Menu: menu_select (placeholder)
[OK] Logo screen grafica
[OK] game_tennis (prossimo passo)
[OK] game_breakout
[OK] game_flipper
[OK] game_handball
[OK] game_hockey
[OK] game_football
