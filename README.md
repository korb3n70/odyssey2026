

#  Odyssey 2026

**Un revival "Director's Cut" della storica console Magnavox/Philips Odyssey 2100 (1978) per Commodore 64.**

![Odyssey 2026](https://img.shields.io/badge/Platform-Commodore_64-blue.svg)
![Language](https://img.shields.io/badge/Language-Assembly_6502-red.svg)
![Assembler](https://img.shields.io/badge/Assembler-ACME-green.svg)
![Input](https://img.shields.io/badge/Input-Dual_Paddles-orange.svg)

**Odyssey 2026** non è un semplice porting, ma una ricostruzione da zero, potenziata e modernizzata, dei classici giochi della console del 1978. Sviluppato interamente in puro **Assembly 6502 (Bare Metal)**, il progetto spreme al massimo l'hardware del C64 offrendo un'esperienza di gioco fluida, reattiva e fisicamente avanzata.

[watch on youtube](https://youtu.be/Ya9MNjs8rn0)
---

##  Caratteristiche Principali

*  **Architettura Modulare (Bare Metal):** Un Hub centrale (`menu_select.asm`) gestisce e lancia 6 moduli di gioco indipendenti. Il codice bypassa completamente il KERNAL del C64, accedendo direttamente ai registri del VIC-II e del chip CIA per garantire zero input-lag e una pulizia assoluta della memoria.
*  **Supporto Dual Paddle Avanzato:** Lettura dinamica dei potenziometri analogici con filtri **Anti-Jitter hardware** (delay-loop ottimizzati) per movimenti precisissimi a 50Hz, sia su singola porta che su doppia porta.
*  **Fisica Dinamica & Motore Arcade:** * Effetto "Frusta" (*English/Spin*) per tagliare la traiettoria della palla in base al punto di impatto e all'inerzia del paddle.
  * Gestione della gravità reale (nel Flipper).
  * Esplosioni particellari in stile Vectrex.
*  **Debounce Hardware:** Gestione della tastiera tramite interrogazione diretta della matrice ($DC00/$DC01) con maschere di bit e lock di sicurezza, per eliminare completamente le raffiche e i "rimbalzi" dei tasti.

---

##  I Giochi Inclusi

1. **BREAKOUT:** Abbatti il muro mattone dopo mattone.
2. **FLIPPER:** Modalità flipper con gravità, bumper statici, bumper mobili e power-up multipli (Multiball, Paddle Gigante, Muro di Salvataggio).
3. **TENNIS:** Il grande classico, ma con l'effetto spin sulle racchette.
4. **HANDBALL (Biliardino):** Una variante complessa con giocatori multipli su diverse linee (Portieri e Attaccanti).
5. **HOCKEY:** Scontri sul ghiaccio ad altissima velocità.
6. **FOOTBALL:** Gestione avanzata del campo per partite all'ultimo respiro.

*(Nota: Ogni gioco supporta varianti grafiche o di gameplay attivabili tramite i tasti funzione).*

---

##  Controlli

Il gioco è progettato per essere goduto con i **Paddle originali Commodore**. 

### Menu Principale
* `C` - Cambia la configurazione delle porte (Paddle 1 e 2 su Porta 1, oppure Paddle 1 su Porta 1 e Paddle 2 su Porta 2).
* `1-6` - Seleziona e avvia il gioco corrispondente.

### In Gioco
* **Paddle Analogico:** Muove le racchette/pedane.
* `F1` - Riavvia la partita (Restart).
* `F3 / F5` - Cambia la variante del gioco (es. aggiunge muri, ostacoli, IA).
* `F7` - Esce dal gioco e torna al Menu Principale (eseguendo un cleanup totale dell'hardware).
* `P` - Pausa (attualmente supportato in Flipper).

---

##  Compilazione e Avvio

Il progetto è scritto nel dialetto dell'assemblatore **ACME Cross-Assembler**.

### Come Compilare
Assicurati di avere ACME installato nel tuo sistema e lancia il seguente comando (esempio generico):
```bash
acme -f cbm -o odyssey2026.prg menu_select.asm
