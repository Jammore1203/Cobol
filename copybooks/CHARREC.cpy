      *================================================================*
      * CHARREC - Adventurer roster record (45 bytes, fixed layout)    *
      *   cols  1-4   adventurer id                                    *
      *   cols  5-24  character name                                   *
      *   cols 25-34  class                                            *
      *   cols 35-37  max hit points                                   *
      *   cols 38-40  starting mana                                    *
      *   cols 41-45  starting gold                                    *
      *================================================================*
       01  CHAR-RECORD.
           05  CR-ID                   PIC X(4).
           05  CR-NAME                 PIC X(20).
           05  CR-CLASS                PIC X(10).
           05  CR-MAX-HP               PIC 9(3).
           05  CR-MANA                 PIC 9(3).
           05  CR-GOLD                 PIC 9(5).
