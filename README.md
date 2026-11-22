# Kadi

2-player mobile card game, built with Godot 4 (standard / non-.NET build).

**Status:** workspace only. No game logic, scenes, or gameplay code have been written yet.

## Opening the project

From PowerShell or CMD:

```powershell
& "D:\Programs\Godot\Godot.exe" --path "D:\Programs\GAME" --editor
```

Or open `D:\Programs\Godot\Godot.exe` and choose **Import** → select `D:\Programs\GAME\project.godot`.

Godot version used: **4.7.2.stable.official** (`D:\Programs\Godot\Godot.exe`).

## Project configuration

- Renderer: Mobile
- Base viewport: 720 x 1280 (portrait)
- Stretch mode: `canvas_items`, aspect `keep`
- Handheld orientation: portrait

## Folder layout

- `scenes/` - Godot scenes (empty)
- `scripts/core/` - pure game rules: no UI or node dependencies, reusable by a bot or a future server
- `scripts/ui/` - presentation/UI scripts (empty)
- `scripts/bot/` - bot decision code (empty)
- `assets/cards/` - card artwork
- `assets/audio/` - sound effects and music
- `docs/rules.md` - current written rules and open design questions

## Rules

See `docs/rules.md`. Several rules are still marked undecided or proposed.
