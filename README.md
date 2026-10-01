# ⚔️ QUESTLOG: A COBOL Battle Chronicler for LARP

![Build & Test](https://github.com/jammore1203/cobol/actions/workflows/build.yml/badge.svg)

**QUESTLOG** is a batch COBOL program for running a weekend LARP skirmish. It loads
the adventurer roster, replays the field marshal's event log (sword hits, spells,
heals, resurrections and loot), applies the rules of the game, and prints a
chronicle of the battle with a final status report for everyone on the field.

It works the way a classic mainframe batch job does: fixed-width input records
described by copybooks, a table held in working storage, validation of every
transaction, and a formatted printed report.

## Sample output

```
  [ROUND 007]  Grimtooth strikes Morwenna Ashcroft for 20 damage
               ~ OGRE SMASH ~
              >>> Morwenna Ashcroft has FALLEN! Take a knee and start your death count. <<<
  [ROUND 008]  ** MARSHAL CALL ** CAST by 0004 voided: the fallen cannot act - lie down!
  ...
  [ROUND 011]  Brother Tuck RESURRECTS Morwenna Ashcroft with 10 HP
               ~ Rise, sister. Not today. ~
  ...
  ID    ADVENTURER           CLASS      HP       VITALITY     MANA     GOLD  DAMAGE  HEALED  STATUS
  ----------------------------------------------------------------------------------------------------
  0001  Sir Gareth           WARRIOR    40/40    [##########]    0      370      33       0  STANDING
  0003  Vex the Unseen       ROGUE      20/28    [#######...]   10      450      42       0  STANDING
  0004  Morwenna Ashcroft    MAGE       10/20    [#####.....]    0       60      90       0  STANDING
  0101  Grimtooth            OGRE-NPC   0/60     [..........]    0      500      32       0  FALLEN
  ...
  Champion of battle .. Morwenna Ashcroft (90 damage dealt)
  Saviour of the day .. Elowen Brightleaf (30 HP restored)
```

The full report is in [`tests/expected-chronicle.txt`](tests/expected-chronicle.txt).

## Rules of the field

| Event  | Effect |
|--------|--------|
| `HIT`  | Actor deals *amount* damage to the target. At 0 HP the target **falls**. |
| `CAST` | Actor spends *amount* mana to deal *amount* damage. Without enough mana the spell **fizzles**. |
| `HEAL` | Restores *amount* HP to the target, up to their maximum. Has no effect on the fallen. |
| `REZ`  | Costs the actor 20 mana. Brings a fallen target back with *amount* HP. |
| `LOOT` | Actor gains *amount* gold. |

The marshal **voids** any event that breaks the rules: the fallen trying to act,
unknown adventurers, hitting someone who is already down, or actions that are
not in the rulebook.

## Project layout

```
src/QUESTLOG.cbl            main program
copybooks/CHARREC.cpy       roster record layout
copybooks/EVENTREC.cpy      event record layout (with 88-level event types)
data/roster.dat             the adventurers and the monster crew (NPCs)
data/events.dat             the marshal's event log for the battle
tests/expected-chronicle.txt  golden output used by `make test`
```

### Input formats

Both files are fixed-width text. Lines starting with `*` are comments.

```
roster.dat   ID(4) NAME(20) CLASS(10) MAX-HP(3) MANA(3) GOLD(5)
             0001Sir Gareth          WARRIOR   04000000120

events.dat   TYPE(4) ACTOR(4) TARGET(4) AMOUNT(3) DESCRIPTION(30)
             HIT 00010101008Greatsword to the ogre's ribs
```

## Building and running

You need [GnuCOBOL](https://gnucobol.sourceforge.io/) (`cobc`).

```bash
# Debian/Ubuntu
sudo apt-get install gnucobol
# macOS
brew install gnucobol

make run    # compile, run, and print the chronicle
make test   # compare the output with the expected chronicle
make clean
```

To stage your own battle, edit `data/roster.dat` and `data/events.dat` and run `make run`.

## COBOL features used

- `COPY` copybooks for shared record layouts
- `LINE SEQUENTIAL` file I/O with `FILE STATUS` checking
- Variable-length tables (`OCCURS ... DEPENDING ON`) searched with `SEARCH`
- 88-level condition names for event types and adventurer status
- `EVALUATE TRUE` for rule validation and dispatch
- `STRING` with intrinsic functions (`TRIM`, `MIN`, `MAX`) to build report lines
- Numeric editing (`ZZ,ZZ9`) and reference modification for the HP bars
- Structured `PERFORM` paragraphs in the usual numbered batch style
