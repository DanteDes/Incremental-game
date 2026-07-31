# Incremental-game

## Testing

This project uses [GUT](https://github.com/bitwes/Gut) (Godot Unit Test) for `GameState.gd`'s logic. There is no CI wiring yet (tracked in issue #10) — run tests locally with:

```bash
godot --headless -s addons/gut/gut_cmdln.gd -gconfig=.gutconfig.json
```

(Substitute your local Godot 4.7 executable for `godot` if it isn't on your `PATH`.)
