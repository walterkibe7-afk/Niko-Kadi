# Niko Kadi

2-player mobile card game built with Godot 4.3 (standard / non-.NET build).

**Status:** Playable prototype with full game logic, AI bots, UI screens, and progression system.

## Opening the project

From PowerShell or CMD:

```powershell
& "D:\Programs\Godot\Godot.exe" --path "D:\Programs\GAME" --editor
```

Or open `D:\Programs\Godot\Godot.exe` and choose **Import** → select `D:\Programs\GAME\project.godot`.

Godot version used: **4.3.stable.official** (`D:\Programs\Godot\Godot.exe`).

## Project configuration

- Renderer: Mobile
- Base viewport: 720 x 1280 (portrait)
- Stretch mode: `canvas_items`, aspect `expand`
- Handheld orientation: portrait
- Main scene: `scenes/main/main.tscn`

## Folder layout

- `scenes/` - Godot scenes
  - `main/` - Gameplay scene (table, clock, cards)
  - `menu/` - Dashboard, Collection, Arena Selection, Game Pass, Profile
  - `onboarding/` - Welcome, Dashboard Tutorial
  - `ui/` - Card Preview, Sub Screen Header
- `scripts/core/` - Pure game rules (no UI/node dependencies)
  - `GameState.gd` - Complete game state machine with all rules
  - `Card.gd`, `Deck.gd` - Card and deck logic
  - `ChessClock.gd` - Turn timer with Fischer increment
- `scripts/ui/` - Presentation/UI scripts
  - `table.gd` - Main gameplay UI
  - `dashboard.gd`, `collection.gd`, `arena_selection.gd`, `game_pass.gd`, `profile.gd` - Menu screens
  - `welcome.gd`, `dashboard_tutorial.gd` - Onboarding
  - `card_view.gd`, `card_preview.gd`, `card_art.gd` - Card rendering
- `scripts/bot/` - Bot AI
  - `simple_bot.gd` - Basic rule-following bot
  - `smart_bot.gd` - Improved AI with strategy
- `scripts/cosmetics/` - Cosmetic system
  - `arena_theme_data.gd`, `deck_skin_data.gd`, `cosmetics_catalog.gd`
- `scripts/progression/` - Player progression
  - `player_progress.gd` - XP, levels, rewards, game pass
- `scripts/sim/` - Simulation & testing tools
- `scripts/tests/` - Unit and integration tests
- `assets/` - Art assets (table felt, card backs)
- `docs/rules.md` - Current written rules

## Game Rules (Niko Kadi)

See `docs/rules.md` for full details. Key mechanics:

- **Deck:** Standard 52 cards. Deal 4 each, 1 face-up starter, rest is draw pile.
- **Turn:** Play matching suit or rank, else draw 1 and end turn.
- **Special cards:**
  - **2/3:** Penalty draw (2/3 cards). Stacks — opponent can counter with 2 or 3.
  - **Ace:** Change suit or block entire penalty stack.
  - **J/K:** Skip/reverse (same in 2P). Can be answered with same rank.
  - **Q/8:** Question — must answer with matching suit, else draw 1.
- **Declaration ("Niko Kadi"):** When a play leaves you with 1 plain card, declare. Last card locked until opponent has a full turn.
- **Win:** First to empty hand with a plain card (4-10). J+plain to go cardless is NOT a win.

## Features implemented

- ✅ Complete game rules engine (GameState)
- ✅ Chess clock with Fischer increment
- ✅ Two AI bots (simple + smart)
- ✅ Full UI: gameplay table, dashboard, collection, arena selection, game pass, profile
- ✅ Onboarding flow (welcome + tutorial)
- ✅ Cosmetic system (arena themes, deck skins)
- ✅ Progression system (XP, levels, daily rewards, game pass)
- ✅ Unit tests for rules, clock, UI declarations
- ✅ Simulation tools for bot vs bot testing

## Running tests

In Godot editor: open `scripts/tests/` and run individual test scenes, or use the test runner.

## License

Proprietary / personal project.