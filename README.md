# Force Showdown

An original space-opera auto-battler prototype built in **Godot 4.4+**. You lead a
squad of collectible heroes from five factions. Between battles you recruit units
from a depot and merge duplicates to level them up. Battles then resolve on their
own in real time.

Everything is original. All art is drawn in code (portraits, icons, bolts, the
starfield shader) and all audio is synthesized at startup. The project ships no
image or sound assets, so you can replace any piece with real art and audio
later without touching the game logic.

## Running it

1. Install Godot 4.4 or newer (standard build, not .NET).
2. Open Godot, choose **Import**, and select this folder's `project.godot`.
3. Press **F5**.

To run the headless balance and smoke test from a terminal:

```bash
godot --headless --path . res://tests/smoke_test.tscn
```

To render every screen to PNGs in `user://screenshots` (this opens a window):

```bash
godot --path . res://tests/screenshots.tscn
```

## How a run works

| Phase | What happens |
|---|---|
| Commander | Pick 1 of 3 random commanders. Their passive applies to every battle. |
| Shop | 10 credits per round. Units cost tier + 1. Rerolling costs 1. Buying a unit you already own levels it up (max 3, +50% output per level). Selling refunds half the cost × level. |
| Battle | Both squads share one HP pool (80 + 50 × round). Each unit charges its cooldown, then casts. A cast applies all of the unit's stats. |
| Result | A win adds 1 win. A loss costs 1, 2 or 3 lives depending on the round. 10 wins completes the campaign; 0 lives ends it. |

**Status effects**
- **Shield** absorbs damage first.
- **Burn** deals its stacks every 0.5 s, then loses 1 stack.
- **Toxin** deals its stacks every 1 s and never fades.
- **Ion** adds bonus damage equal to its stacks to every direct hit, then loses 1 stack.
- **Sudden Death** starts at 30 s: both sides take 6 × 2^(t/3) damage every 0.5 s, where t is seconds since it started. It ignores shields.

**Faction bonuses** activate with 2 or 4 distinct units of a faction:

| Faction | Bonus (2 / 4 units) |
|---|---|
| Concord Alliance | Concord units +2 / +5 Damage |
| The Dominion | Enemy starts with 3 / 8 Burn |
| Gilded Fang Syndicate | Syndicate units +1 / +3 Toxin |
| Order of the Veil | All allies +10% / +25% cooldown speed |
| The Forge | Team starts with 20 / 60 Shield |

## Project layout

```
scenes/main.tscn            Root scene (Main control + background)
scripts/main.gd             Screen flow: title -> commander -> shop <-> battle -> summary
scripts/autoload/
  game_db.gd                ALL CONTENT: factions, units, commanders (plain data)
  run_state.gd              Campaign state: squad, credits, shop odds, lives, wins
  sfx.gd                    Procedural sound effects + music
scripts/data/               UnitData, CommanderData (Resources), UnitInstance
scripts/battle/
  battle_sim.gd             The rules. UI-free and deterministic.
  battle_unit.gd            Live per-battle unit state and stat math
  bot_generator.gd          Builds opponents by replaying the shop greedily
scripts/ui/                 Theme, unit card, portraits, icons, HP bar, FX layer
scripts/screens/            Title, commander, shop, battle, summary
shaders/starfield.gdshader  Animated nebula, stars, planet, sudden-death tint
tests/smoke_test.gd         Headless sim and UI smoke test plus balance report
tests/screenshots.gd        Renders each screen to PNG for quick visual checks
```

## Extending it

**Add a unit:** append a dictionary to `UNIT_DEFS` in `scripts/autoload/game_db.gd`.

```gdscript
{"id": &"veil_sentry", "display_name": "Veil Sentry", "tier": 2, "faction": &"veil", "role": &"mystic",
	"cooldown": 3.0, "damage": 6, "shield": 6,
	"ability_trigger": &"on_cast", "ability_effect": &"buff_adjacent", "ability_params": {"stat": "shield", "amount": 2},
	"ability_name": "Warding Step", "ability_text": "After each cast, adjacent allies gain +{a} Shield."},
```

- **Triggers:** `battle_start`, `on_cast`, `ally_cast`, `on_shielded`
- **Effects:** `buff_self`, `buff_adjacent`, `buff_faction`, `buff_all`, `haste_self`,
  `haste_all`, `status_enemy`, `charge_self`, `damage_enemy`, `heal_team`, `shield_team`
- **Roles** (portrait silhouettes): `trooper`, `pilot`, `construct`, `hunter`, `mystic`, `officer`

Amounts scale with the unit's level. In ability text, `{a}` shows the amount and
`{p}` shows it as a percent.

**Add an ability type:** add a `match` branch in `BattleSim._run_ability`.

**Add a commander:** append to `COMMANDER_DEFS`. Battle effects go in
`BattleSim._apply_commander`; shop effects go in `Run` (see `bonus_gold`).

**Add a faction:** add an entry to `FACTIONS` with colors and synergy values,
then a `match` branch in `BattleSim._apply_synergies`.

**Swap in real art:** add an `@export var portrait: Texture2D` to `UnitData` and
draw it in `UnitCard._draw()` in place of the `Portrait.draw(...)` call. Do the
same for commanders in `PortraitView`.

**Swap in real audio:** load your streams in `Sfx._build()` under the same keys
(`laser`, `heavy`, `blade`, `heal`, `shield`, `burn`, `toxin`, `ion`, `explosion`, ...).

**Tune balance:** costs, income, HP, lives and shop odds live at the top of
`run_state.gd`. Battle timings live at the top of `battle_sim.gd`. The smoke test
prints win rates for each opponent strength, which helps when tuning.

## Ideas for next steps

- Drag-and-drop squad arrangement (Godot's `_get_drag_data` / `_drop_data`)
- A bench for holding units, and freezing shop offers
- Save/load campaigns (serialize `Run` to `user://`)
- Asynchronous PvP: upload squads and fight other players' saved squads
- More trigger types: on knockout, every Nth cast, when an enemy casts
