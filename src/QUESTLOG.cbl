       IDENTIFICATION DIVISION.
       PROGRAM-ID. QUESTLOG.
      *================================================================*
      * QUESTLOG - The Battle Chronicler                               *
      *                                                                *
      * A batch program for running a weekend LARP skirmish. It loads  *
      * the adventurer roster, replays the field marshal's event log   *
      * (hits, spells, heals, resurrections and loot), enforces the    *
      * rules of the game, and prints a chronicle of the battle with   *
      * a final party status report.                                   *
      *                                                                *
      * Inputs : data/roster.dat   (CHARREC layout)                    *
      *          data/events.dat   (EVENTREC layout)                   *
      * Output : out/chronicle.txt                                     *
      *================================================================*
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ROSTER-FILE ASSIGN TO "data/roster.dat"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-ROSTER-STATUS.
           SELECT EVENT-FILE ASSIGN TO "data/events.dat"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-EVENT-STATUS.
           SELECT REPORT-FILE ASSIGN TO "out/chronicle.txt"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-REPORT-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  ROSTER-FILE.
           COPY CHARREC.

       FD  EVENT-FILE.
           COPY EVENTREC.

       FD  REPORT-FILE.
       01  REPORT-LINE                 PIC X(110).

       WORKING-STORAGE SECTION.
      *---------------------------------------------------------------*
      * File status codes and switches                                *
      *---------------------------------------------------------------*
       01  WS-FILE-STATUSES.
           05  WS-ROSTER-STATUS        PIC XX.
           05  WS-EVENT-STATUS         PIC XX.
           05  WS-REPORT-STATUS        PIC XX.

       01  WS-SWITCHES.
           05  WS-ROSTER-EOF-SW        PIC X       VALUE "N".
               88  ROSTER-EOF                      VALUE "Y".
           05  WS-EVENT-EOF-SW         PIC X       VALUE "N".
               88  EVENT-EOF                       VALUE "Y".
           05  WS-ACTOR-FOUND-SW       PIC X.
               88  ACTOR-FOUND                     VALUE "Y".
           05  WS-TARGET-FOUND-SW      PIC X.
               88  TARGET-FOUND                    VALUE "Y".

      *---------------------------------------------------------------*
      * Rules of the game                                             *
      *---------------------------------------------------------------*
       01  WS-RULES.
           05  WS-MAX-PARTY            PIC 99      VALUE 20.
           05  WS-REZ-MANA-COST        PIC 99      VALUE 20.
           05  WS-BAR-WIDTH            PIC 99      VALUE 10.

      *---------------------------------------------------------------*
      * Counters and work fields                                      *
      *---------------------------------------------------------------*
       01  WS-COUNTERS.
           05  WS-PARTY-SIZE           PIC 99      VALUE 0.
           05  WS-ROUND                PIC 9(3)    VALUE 0.
           05  WS-VOID-COUNT           PIC 9(3)    VALUE 0.
           05  WS-FALLEN-COUNT         PIC 99      VALUE 0.
           05  WS-TOTAL-GOLD           PIC 9(6)    VALUE 0.

       01  WS-WORK.
           05  WS-I                    PIC 99.
           05  WS-ACT                  PIC 99.
           05  WS-TGT                  PIC 99.
           05  WS-MVP                  PIC 99      VALUE 0.
           05  WS-TOP-HEALER           PIC 99      VALUE 0.
           05  WS-HEAL-AMT             PIC 9(3).
           05  WS-BAR-LEN              PIC 99.
           05  WS-AMT-ED               PIC ZZ9.
           05  WS-NUM-ED               PIC ZZ,ZZ9.
           05  WS-HP-ED                PIC ZZ9.
           05  WS-MAX-ED               PIC ZZ9.
           05  WS-NARRATIVE            PIC X(70).
           05  WS-VOID-REASON          PIC X(50).

      *---------------------------------------------------------------*
      * The party - everyone on the field, players and monster crew   *
      *---------------------------------------------------------------*
       01  WS-PARTY-TABLE.
           05  WS-HERO OCCURS 1 TO 20 TIMES
                       DEPENDING ON WS-PARTY-SIZE
                       INDEXED BY HX.
               10  H-ID                PIC X(4).
               10  H-NAME              PIC X(20).
               10  H-CLASS             PIC X(10).
               10  H-MAX-HP            PIC 9(3).
               10  H-HP                PIC S9(4).
               10  H-MANA              PIC 9(3).
               10  H-GOLD              PIC 9(5).
               10  H-DMG-DEALT         PIC 9(5).
               10  H-HEAL-DONE         PIC 9(5).
               10  H-STATUS            PIC X.
                   88  H-STANDING                  VALUE "S".
                   88  H-FALLEN                    VALUE "F".

      *---------------------------------------------------------------*
      * Report layouts                                                *
      *---------------------------------------------------------------*
       01  WS-RULE-LINE                PIC X(100)  VALUE ALL "=".
       01  WS-THIN-LINE                PIC X(100)  VALUE ALL "-".
       01  WS-PRINT-LINE               PIC X(110).

       01  WS-COLUMN-HEADER.
           05  FILLER                  PIC X(2)    VALUE SPACES.
           05  FILLER                  PIC X(6)    VALUE "ID".
           05  FILLER                  PIC X(21)   VALUE "ADVENTURER".
           05  FILLER                  PIC X(11)   VALUE "CLASS".
           05  FILLER                  PIC X(9)    VALUE "HP".
           05  FILLER                  PIC X(13)   VALUE "VITALITY".
           05  FILLER                  PIC X(7)    VALUE "MANA".
           05  FILLER                  PIC X(8)    VALUE "  GOLD".
           05  FILLER                  PIC X(8)    VALUE "DAMAGE".
           05  FILLER                  PIC X(8)    VALUE "HEALED".
           05  FILLER                  PIC X(8)    VALUE "STATUS".

       01  WS-HERO-LINE.
           05  FILLER                  PIC X(2)    VALUE SPACES.
           05  HL-ID                   PIC X(4).
           05  FILLER                  PIC X(2)    VALUE SPACES.
           05  HL-NAME                 PIC X(20).
           05  FILLER                  PIC X(1)    VALUE SPACES.
           05  HL-CLASS                PIC X(10).
           05  FILLER                  PIC X(1)    VALUE SPACES.
           05  HL-HP                   PIC X(7).
           05  FILLER                  PIC X(2)    VALUE SPACES.
           05  HL-BAR                  PIC X(12).
           05  FILLER                  PIC X(2)    VALUE SPACES.
           05  HL-MANA                 PIC ZZ9.
           05  FILLER                  PIC X(3)    VALUE SPACES.
           05  HL-GOLD                 PIC ZZ,ZZ9.
           05  FILLER                  PIC X(2)    VALUE SPACES.
           05  HL-DMG                  PIC ZZ,ZZ9.
           05  FILLER                  PIC X(2)    VALUE SPACES.
           05  HL-HEAL                 PIC ZZ,ZZ9.
           05  FILLER                  PIC X(2)    VALUE SPACES.
           05  HL-STATUS               PIC X(8).

       PROCEDURE DIVISION.
      *================================================================*
       0000-MAIN.
      *================================================================*
           PERFORM 1000-INITIALIZE
           PERFORM 2000-PROCESS-EVENT
               UNTIL EVENT-EOF
           PERFORM 3000-WRITE-SUMMARY
           PERFORM 9000-TERMINATE
           STOP RUN.

      *================================================================*
       1000-INITIALIZE.
      *================================================================*
           OPEN INPUT ROSTER-FILE
           IF WS-ROSTER-STATUS NOT = "00"
               DISPLAY "QUESTLOG: cannot open roster, status "
                   WS-ROSTER-STATUS
               MOVE 16 TO RETURN-CODE
               STOP RUN
           END-IF
           PERFORM 1100-LOAD-ADVENTURER
               UNTIL ROSTER-EOF
           CLOSE ROSTER-FILE

           OPEN INPUT EVENT-FILE
           IF WS-EVENT-STATUS NOT = "00"
               DISPLAY "QUESTLOG: cannot open event log, status "
                   WS-EVENT-STATUS
               MOVE 16 TO RETURN-CODE
               STOP RUN
           END-IF

           OPEN OUTPUT REPORT-FILE
           IF WS-REPORT-STATUS NOT = "00"
               DISPLAY "QUESTLOG: cannot open chronicle, status "
                   WS-REPORT-STATUS
               MOVE 16 TO RETURN-CODE
               STOP RUN
           END-IF

           PERFORM 1200-WRITE-BANNER
           PERFORM 8100-READ-EVENT.

      *----------------------------------------------------------------*
       1100-LOAD-ADVENTURER.
      *----------------------------------------------------------------*
           READ ROSTER-FILE
               AT END
                   SET ROSTER-EOF TO TRUE
               NOT AT END
                   EVALUATE TRUE
                       WHEN CHAR-RECORD(1:1) = "*"
                       WHEN CHAR-RECORD = SPACES
                           CONTINUE
                       WHEN CR-MAX-HP NOT NUMERIC
                         OR CR-MANA NOT NUMERIC
                         OR CR-GOLD NOT NUMERIC
                         OR CR-MAX-HP = ZERO
                           DISPLAY "QUESTLOG: bad roster entry "
                               CR-ID " skipped"
                       WHEN WS-PARTY-SIZE >= WS-MAX-PARTY
                           DISPLAY "QUESTLOG: party full, "
                               CR-ID " turned away at the gate"
                       WHEN OTHER
                           PERFORM 1110-ADD-TO-PARTY
                   END-EVALUATE
           END-READ.

      *----------------------------------------------------------------*
       1110-ADD-TO-PARTY.
      *----------------------------------------------------------------*
           ADD 1 TO WS-PARTY-SIZE
           MOVE CR-ID      TO H-ID(WS-PARTY-SIZE)
           MOVE CR-NAME    TO H-NAME(WS-PARTY-SIZE)
           MOVE CR-CLASS   TO H-CLASS(WS-PARTY-SIZE)
           MOVE CR-MAX-HP  TO H-MAX-HP(WS-PARTY-SIZE)
                              H-HP(WS-PARTY-SIZE)
           MOVE CR-MANA    TO H-MANA(WS-PARTY-SIZE)
           MOVE CR-GOLD    TO H-GOLD(WS-PARTY-SIZE)
           MOVE ZERO       TO H-DMG-DEALT(WS-PARTY-SIZE)
                              H-HEAL-DONE(WS-PARTY-SIZE)
           SET H-STANDING(WS-PARTY-SIZE) TO TRUE.

      *----------------------------------------------------------------*
       1200-WRITE-BANNER.
      *----------------------------------------------------------------*
           WRITE REPORT-LINE FROM WS-RULE-LINE
           MOVE "     THE CHRONICLE OF THE SKIRMISH AT GREYMARSH FORD"
               TO WS-PRINT-LINE
           PERFORM 8200-PRINT
           MOVE "     As recorded by the Field Marshal. Lay on!"
               TO WS-PRINT-LINE
           PERFORM 8200-PRINT
           WRITE REPORT-LINE FROM WS-RULE-LINE
           MOVE SPACES TO WS-PRINT-LINE
           PERFORM 8200-PRINT.

      *================================================================*
       2000-PROCESS-EVENT.
      *================================================================*
           ADD 1 TO WS-ROUND
           PERFORM 2100-FIND-COMBATANTS

           EVALUATE TRUE
               WHEN NOT ACTOR-FOUND
                   MOVE "no such adventurer is on the field"
                       TO WS-VOID-REASON
                   PERFORM 2900-VOID-EVENT
               WHEN EV-AMOUNT NOT NUMERIC
                   MOVE "the amount is unreadable"
                       TO WS-VOID-REASON
                   PERFORM 2900-VOID-EVENT
               WHEN H-FALLEN(WS-ACT)
                   MOVE "the fallen cannot act - lie down!"
                       TO WS-VOID-REASON
                   PERFORM 2900-VOID-EVENT
               WHEN EV-HIT
                   PERFORM 2200-RESOLVE-HIT
               WHEN EV-CAST
                   PERFORM 2300-RESOLVE-CAST
               WHEN EV-HEAL
                   PERFORM 2400-RESOLVE-HEAL
               WHEN EV-REZ
                   PERFORM 2500-RESOLVE-REZ
               WHEN EV-LOOT
                   PERFORM 2600-RESOLVE-LOOT
               WHEN OTHER
                   MOVE "that is not in the rulebook"
                       TO WS-VOID-REASON
                   PERFORM 2900-VOID-EVENT
           END-EVALUATE

           PERFORM 8100-READ-EVENT.

      *----------------------------------------------------------------*
       2100-FIND-COMBATANTS.
      *----------------------------------------------------------------*
           MOVE "N" TO WS-ACTOR-FOUND-SW
                       WS-TARGET-FOUND-SW

           SET HX TO 1
           SEARCH WS-HERO
               WHEN H-ID(HX) = EV-ACTOR-ID
                   SET WS-ACT TO HX
                   SET ACTOR-FOUND TO TRUE
           END-SEARCH

           SET HX TO 1
           SEARCH WS-HERO
               WHEN H-ID(HX) = EV-TARGET-ID
                   SET WS-TGT TO HX
                   SET TARGET-FOUND TO TRUE
           END-SEARCH.

      *----------------------------------------------------------------*
       2200-RESOLVE-HIT.
      *----------------------------------------------------------------*
           EVALUATE TRUE
               WHEN NOT TARGET-FOUND
                   MOVE "swinging at thin air" TO WS-VOID-REASON
                   PERFORM 2900-VOID-EVENT
               WHEN H-FALLEN(WS-TGT)
                   MOVE "no hitting the fallen" TO WS-VOID-REASON
                   PERFORM 2900-VOID-EVENT
               WHEN OTHER
                   MOVE EV-AMOUNT TO WS-AMT-ED
                   MOVE SPACES TO WS-NARRATIVE
                   STRING FUNCTION TRIM(H-NAME(WS-ACT))
                               DELIMITED BY SIZE
                          " strikes "  DELIMITED BY SIZE
                          FUNCTION TRIM(H-NAME(WS-TGT))
                               DELIMITED BY SIZE
                          " for "      DELIMITED BY SIZE
                          FUNCTION TRIM(WS-AMT-ED)
                               DELIMITED BY SIZE
                          " damage"    DELIMITED BY SIZE
                       INTO WS-NARRATIVE
                   END-STRING
                   PERFORM 2700-APPLY-DAMAGE
           END-EVALUATE.

      *----------------------------------------------------------------*
       2300-RESOLVE-CAST.
      *----------------------------------------------------------------*
           EVALUATE TRUE
               WHEN NOT TARGET-FOUND
                   MOVE "the spell has no target" TO WS-VOID-REASON
                   PERFORM 2900-VOID-EVENT
               WHEN H-FALLEN(WS-TGT)
                   MOVE "no blasting the fallen" TO WS-VOID-REASON
                   PERFORM 2900-VOID-EVENT
               WHEN H-MANA(WS-ACT) < EV-AMOUNT
                   MOVE SPACES TO WS-NARRATIVE
                   STRING FUNCTION TRIM(H-NAME(WS-ACT))
                               DELIMITED BY SIZE
                          "'s spell FIZZLES - out of mana!"
                               DELIMITED BY SIZE
                       INTO WS-NARRATIVE
                   END-STRING
                   PERFORM 2800-LOG-NARRATIVE
               WHEN OTHER
                   SUBTRACT EV-AMOUNT FROM H-MANA(WS-ACT)
                   MOVE EV-AMOUNT TO WS-AMT-ED
                   MOVE SPACES TO WS-NARRATIVE
                   STRING FUNCTION TRIM(H-NAME(WS-ACT))
                               DELIMITED BY SIZE
                          " blasts "   DELIMITED BY SIZE
                          FUNCTION TRIM(H-NAME(WS-TGT))
                               DELIMITED BY SIZE
                          " with magic for "
                                       DELIMITED BY SIZE
                          FUNCTION TRIM(WS-AMT-ED)
                               DELIMITED BY SIZE
                          " damage"    DELIMITED BY SIZE
                       INTO WS-NARRATIVE
                   END-STRING
                   PERFORM 2700-APPLY-DAMAGE
           END-EVALUATE.

      *----------------------------------------------------------------*
       2400-RESOLVE-HEAL.
      *----------------------------------------------------------------*
           EVALUATE TRUE
               WHEN NOT TARGET-FOUND
                   MOVE "nobody there to heal" TO WS-VOID-REASON
                   PERFORM 2900-VOID-EVENT
               WHEN H-FALLEN(WS-TGT)
                   MOVE "the fallen need a REZ, not a bandage"
                       TO WS-VOID-REASON
                   PERFORM 2900-VOID-EVENT
               WHEN OTHER
      *            Healing never takes anyone above their maximum
                   COMPUTE WS-HEAL-AMT =
                       FUNCTION MIN(EV-AMOUNT,
                                    H-MAX-HP(WS-TGT) - H-HP(WS-TGT))
                   ADD WS-HEAL-AMT TO H-HP(WS-TGT)
                                      H-HEAL-DONE(WS-ACT)
                   MOVE WS-HEAL-AMT TO WS-AMT-ED
                   MOVE SPACES TO WS-NARRATIVE
                   STRING FUNCTION TRIM(H-NAME(WS-ACT))
                               DELIMITED BY SIZE
                          " heals "    DELIMITED BY SIZE
                          FUNCTION TRIM(H-NAME(WS-TGT))
                               DELIMITED BY SIZE
                          " for "      DELIMITED BY SIZE
                          FUNCTION TRIM(WS-AMT-ED)
                               DELIMITED BY SIZE
                          " HP"        DELIMITED BY SIZE
                       INTO WS-NARRATIVE
                   END-STRING
                   PERFORM 2800-LOG-NARRATIVE
           END-EVALUATE.

      *----------------------------------------------------------------*
       2500-RESOLVE-REZ.
      *----------------------------------------------------------------*
           EVALUATE TRUE
               WHEN NOT TARGET-FOUND
                   MOVE "nobody there to resurrect" TO WS-VOID-REASON
                   PERFORM 2900-VOID-EVENT
               WHEN H-STANDING(WS-TGT)
                   MOVE "the target is not dead (yet)"
                       TO WS-VOID-REASON
                   PERFORM 2900-VOID-EVENT
               WHEN H-MANA(WS-ACT) < WS-REZ-MANA-COST
                   MOVE "not enough mana to resurrect"
                       TO WS-VOID-REASON
                   PERFORM 2900-VOID-EVENT
               WHEN OTHER
                   SUBTRACT WS-REZ-MANA-COST FROM H-MANA(WS-ACT)
                   COMPUTE H-HP(WS-TGT) =
                       FUNCTION MAX(1,
                           FUNCTION MIN(EV-AMOUNT, H-MAX-HP(WS-TGT)))
                   SET H-STANDING(WS-TGT) TO TRUE
                   SUBTRACT 1 FROM WS-FALLEN-COUNT
                   MOVE H-HP(WS-TGT) TO WS-AMT-ED
                   MOVE SPACES TO WS-NARRATIVE
                   STRING FUNCTION TRIM(H-NAME(WS-ACT))
                               DELIMITED BY SIZE
                          " RESURRECTS " DELIMITED BY SIZE
                          FUNCTION TRIM(H-NAME(WS-TGT))
                               DELIMITED BY SIZE
                          " with "     DELIMITED BY SIZE
                          FUNCTION TRIM(WS-AMT-ED)
                               DELIMITED BY SIZE
                          " HP"        DELIMITED BY SIZE
                       INTO WS-NARRATIVE
                   END-STRING
                   PERFORM 2800-LOG-NARRATIVE
           END-EVALUATE.

      *----------------------------------------------------------------*
       2600-RESOLVE-LOOT.
      *----------------------------------------------------------------*
           ADD EV-AMOUNT TO H-GOLD(WS-ACT)
               ON SIZE ERROR
                   MOVE 99999 TO H-GOLD(WS-ACT)
           END-ADD
           MOVE EV-AMOUNT TO WS-AMT-ED
           MOVE SPACES TO WS-NARRATIVE
           STRING FUNCTION TRIM(H-NAME(WS-ACT)) DELIMITED BY SIZE
                  " loots "                     DELIMITED BY SIZE
                  FUNCTION TRIM(WS-AMT-ED)      DELIMITED BY SIZE
                  " gold"                       DELIMITED BY SIZE
               INTO WS-NARRATIVE
           END-STRING
           PERFORM 2800-LOG-NARRATIVE.

      *----------------------------------------------------------------*
       2700-APPLY-DAMAGE.
      *----------------------------------------------------------------*
           SUBTRACT EV-AMOUNT FROM H-HP(WS-TGT)
           ADD EV-AMOUNT TO H-DMG-DEALT(WS-ACT)
           PERFORM 2800-LOG-NARRATIVE

           IF H-HP(WS-TGT) <= 0
               MOVE ZERO TO H-HP(WS-TGT)
               SET H-FALLEN(WS-TGT) TO TRUE
               ADD 1 TO WS-FALLEN-COUNT
               MOVE SPACES TO WS-PRINT-LINE
               STRING "              >>> "    DELIMITED BY SIZE
                      FUNCTION TRIM(H-NAME(WS-TGT))
                                              DELIMITED BY SIZE
                      " has FALLEN! Take a knee and start your"
                                              DELIMITED BY SIZE
                      " death count. <<<"     DELIMITED BY SIZE
                   INTO WS-PRINT-LINE
               END-STRING
               PERFORM 8200-PRINT
           END-IF.

      *----------------------------------------------------------------*
       2800-LOG-NARRATIVE.
      *----------------------------------------------------------------*
           MOVE SPACES TO WS-PRINT-LINE
           STRING "  [ROUND " DELIMITED BY SIZE
                  WS-ROUND    DELIMITED BY SIZE
                  "]  "       DELIMITED BY SIZE
                  FUNCTION TRIM(WS-NARRATIVE) DELIMITED BY SIZE
               INTO WS-PRINT-LINE
           END-STRING
           PERFORM 8200-PRINT
           IF EV-DESC NOT = SPACES
               MOVE SPACES TO WS-PRINT-LINE
               STRING "               ~ "        DELIMITED BY SIZE
                      FUNCTION TRIM(EV-DESC)     DELIMITED BY SIZE
                      " ~"                       DELIMITED BY SIZE
                   INTO WS-PRINT-LINE
               END-STRING
               PERFORM 8200-PRINT
           END-IF.

      *----------------------------------------------------------------*
       2900-VOID-EVENT.
      *----------------------------------------------------------------*
           ADD 1 TO WS-VOID-COUNT
           MOVE SPACES TO WS-PRINT-LINE
           STRING "  [ROUND " DELIMITED BY SIZE
                  WS-ROUND    DELIMITED BY SIZE
                  "]  ** MARSHAL CALL ** "  DELIMITED BY SIZE
                  EV-TYPE     DELIMITED BY SIZE
                  " by "      DELIMITED BY SIZE
                  EV-ACTOR-ID DELIMITED BY SIZE
                  " voided: " DELIMITED BY SIZE
                  FUNCTION TRIM(WS-VOID-REASON) DELIMITED BY SIZE
               INTO WS-PRINT-LINE
           END-STRING
           PERFORM 8200-PRINT.

      *================================================================*
       3000-WRITE-SUMMARY.
      *================================================================*
           MOVE SPACES TO WS-PRINT-LINE
           PERFORM 8200-PRINT
           WRITE REPORT-LINE FROM WS-RULE-LINE
           MOVE "     STATE OF THE FIELD WHEN TIME WAS CALLED"
               TO WS-PRINT-LINE
           PERFORM 8200-PRINT
           WRITE REPORT-LINE FROM WS-RULE-LINE
           WRITE REPORT-LINE FROM WS-COLUMN-HEADER
           WRITE REPORT-LINE FROM WS-THIN-LINE

           PERFORM VARYING WS-I FROM 1 BY 1
                   UNTIL WS-I > WS-PARTY-SIZE
               PERFORM 3100-WRITE-HERO-LINE
               ADD H-GOLD(WS-I) TO WS-TOTAL-GOLD
               IF WS-MVP = 0
                  OR H-DMG-DEALT(WS-I) > H-DMG-DEALT(WS-MVP)
                   MOVE WS-I TO WS-MVP
               END-IF
               IF WS-TOP-HEALER = 0
                  OR H-HEAL-DONE(WS-I) > H-HEAL-DONE(WS-TOP-HEALER)
                   MOVE WS-I TO WS-TOP-HEALER
               END-IF
           END-PERFORM

           WRITE REPORT-LINE FROM WS-THIN-LINE
           PERFORM 3200-WRITE-HONOURS.

      *----------------------------------------------------------------*
       3100-WRITE-HERO-LINE.
      *----------------------------------------------------------------*
           MOVE H-ID(WS-I)          TO HL-ID
           MOVE H-NAME(WS-I)        TO HL-NAME
           MOVE H-CLASS(WS-I)       TO HL-CLASS
           MOVE H-MANA(WS-I)        TO HL-MANA
           MOVE H-GOLD(WS-I)        TO HL-GOLD
           MOVE H-DMG-DEALT(WS-I)   TO HL-DMG
           MOVE H-HEAL-DONE(WS-I)   TO HL-HEAL

           MOVE H-HP(WS-I)          TO WS-HP-ED
           MOVE H-MAX-HP(WS-I)      TO WS-MAX-ED
           MOVE SPACES TO HL-HP
           STRING FUNCTION TRIM(WS-HP-ED)  DELIMITED BY SIZE
                  "/"                      DELIMITED BY SIZE
                  FUNCTION TRIM(WS-MAX-ED) DELIMITED BY SIZE
               INTO HL-HP
           END-STRING

      *    Vitality bar: one '#' per tenth of max HP, rounded,
      *    but never empty while the adventurer is still standing
           COMPUTE WS-BAR-LEN ROUNDED =
               H-HP(WS-I) * WS-BAR-WIDTH / H-MAX-HP(WS-I)
           IF WS-BAR-LEN = 0 AND H-HP(WS-I) > 0
               MOVE 1 TO WS-BAR-LEN
           END-IF
           MOVE "[..........]" TO HL-BAR
           IF WS-BAR-LEN > 0
               MOVE ALL "#" TO HL-BAR(2:WS-BAR-LEN)
           END-IF

           IF H-FALLEN(WS-I)
               MOVE "FALLEN"   TO HL-STATUS
           ELSE
               MOVE "STANDING" TO HL-STATUS
           END-IF

           WRITE REPORT-LINE FROM WS-HERO-LINE.

      *----------------------------------------------------------------*
       3200-WRITE-HONOURS.
      *----------------------------------------------------------------*
           MOVE SPACES TO WS-PRINT-LINE
           STRING "  Events logged ....... " DELIMITED BY SIZE
                  WS-ROUND                   DELIMITED BY SIZE
                  "   (voided by marshal: "  DELIMITED BY SIZE
                  WS-VOID-COUNT              DELIMITED BY SIZE
                  ")"                        DELIMITED BY SIZE
               INTO WS-PRINT-LINE
           END-STRING
           PERFORM 8200-PRINT

           MOVE SPACES TO WS-PRINT-LINE
           STRING "  Still fallen ........ " DELIMITED BY SIZE
                  WS-FALLEN-COUNT            DELIMITED BY SIZE
                  " of "                     DELIMITED BY SIZE
                  WS-PARTY-SIZE              DELIMITED BY SIZE
               INTO WS-PRINT-LINE
           END-STRING
           PERFORM 8200-PRINT

           MOVE WS-TOTAL-GOLD TO WS-NUM-ED
           MOVE SPACES TO WS-PRINT-LINE
           STRING "  Gold on the field ... "  DELIMITED BY SIZE
                  FUNCTION TRIM(WS-NUM-ED)    DELIMITED BY SIZE
               INTO WS-PRINT-LINE
           END-STRING
           PERFORM 8200-PRINT

           IF WS-MVP > 0
               MOVE H-DMG-DEALT(WS-MVP) TO WS-NUM-ED
               MOVE SPACES TO WS-PRINT-LINE
               STRING "  Champion of battle .. "  DELIMITED BY SIZE
                      FUNCTION TRIM(H-NAME(WS-MVP))
                                                  DELIMITED BY SIZE
                      " ("                        DELIMITED BY SIZE
                      FUNCTION TRIM(WS-NUM-ED)    DELIMITED BY SIZE
                      " damage dealt)"            DELIMITED BY SIZE
                   INTO WS-PRINT-LINE
               END-STRING
               PERFORM 8200-PRINT
           END-IF

           IF WS-TOP-HEALER > 0
               MOVE H-HEAL-DONE(WS-TOP-HEALER) TO WS-NUM-ED
               MOVE SPACES TO WS-PRINT-LINE
               STRING "  Saviour of the day .. "  DELIMITED BY SIZE
                      FUNCTION TRIM(H-NAME(WS-TOP-HEALER))
                                                  DELIMITED BY SIZE
                      " ("                        DELIMITED BY SIZE
                      FUNCTION TRIM(WS-NUM-ED)    DELIMITED BY SIZE
                      " HP restored)"             DELIMITED BY SIZE
                   INTO WS-PRINT-LINE
               END-STRING
               PERFORM 8200-PRINT
           END-IF

           WRITE REPORT-LINE FROM WS-RULE-LINE.

      *================================================================*
      * Utility paragraphs                                             *
      *================================================================*
       8100-READ-EVENT.
      *    Skip comment lines (starting with '*') and blank lines
           PERFORM WITH TEST AFTER
                   UNTIL EVENT-EOF
                      OR (EVENT-RECORD(1:1) NOT = "*"
                          AND EVENT-RECORD NOT = SPACES)
               READ EVENT-FILE
                   AT END
                       SET EVENT-EOF TO TRUE
               END-READ
           END-PERFORM.

       8200-PRINT.
           WRITE REPORT-LINE FROM WS-PRINT-LINE.

       9000-TERMINATE.
           CLOSE EVENT-FILE
                 REPORT-FILE
           DISPLAY "QUESTLOG: " WS-ROUND " events chronicled, "
                   WS-VOID-COUNT " voided. See out/chronicle.txt".
