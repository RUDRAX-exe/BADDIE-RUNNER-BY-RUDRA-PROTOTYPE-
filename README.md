# Baddie Runner — Full Prototype

A self-contained cartoon mobile endless-runner foundation.

## Game identity
Rudra = RUN FOR the Baddies
Lakshya = RUN FROM the Baddies
Arsh = RUN BETWEEN the Baddies

## Included
- Character select and tutorial cards
- 3 distinct modes
- Procedural cartoon characters, maps and effects
- 4 themed maps
- Coins, gems, shields, magnets and disguises
- Combo scoring and missions
- Persistent best scores
- Funny dialogue/reactions
- Touch swipe controls
- Generated WAV music and sound effects
- Pause/settings
- Android export configuration
- GitHub Actions workflow

## Controls
Swipe left/right = lane change
Swipe up = jump
Swipe down = slide
Tap = special ability
Keyboard: A/D, Space, S, E

## Build
Open with Godot 4.7 and run the project. For Android, configure the Android export preset and SDK/JDK as documented by Godot.


## Baddie NPC update
The game now treats “baddies” as **girl NPCs**, not monsters. The four randomly styled cartoon girl NPCs (Maya, Riya, Tara, Zara) appear during runs.

- **Rudra — RUN FOR:** catches girl NPCs for bonus points.
- **Lakshya — RUN FROM:** girl NPCs chase/block the route; avoid them.
- **Arsh — RUN BETWEEN:** girl NPCs appear across lanes; weave through the chaos.

The girl characters are currently rendered procedurally in `scripts/game.gd`, so the project remains self-contained and does not require external art packs.
