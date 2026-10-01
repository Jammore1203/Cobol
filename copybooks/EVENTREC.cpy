      *================================================================*
      * EVENTREC - Marshal's event log record (45 bytes)               *
      *   cols  1-4   event type  HIT / CAST / HEAL / REZ / LOOT       *
      *   cols  5-8   acting adventurer id                             *
      *   cols  9-12  target adventurer id ("----" if none)            *
      *   cols 13-15  amount (damage, mana, hp or gold)                *
      *   cols 16-45  free-text description                            *
      *================================================================*
       01  EVENT-RECORD.
           05  EV-TYPE                 PIC X(4).
               88  EV-HIT                  VALUE "HIT ".
               88  EV-CAST                 VALUE "CAST".
               88  EV-HEAL                 VALUE "HEAL".
               88  EV-REZ                  VALUE "REZ ".
               88  EV-LOOT                 VALUE "LOOT".
           05  EV-ACTOR-ID             PIC X(4).
           05  EV-TARGET-ID            PIC X(4).
           05  EV-AMOUNT               PIC 9(3).
           05  EV-DESC                 PIC X(30).
