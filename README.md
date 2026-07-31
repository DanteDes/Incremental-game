# Incremental-game

## Debug CLI options

For local testing, you can start the game with startup overrides via CLI args (passed after `--`):

```
godot --path . -- --gold=500 --stage=2 --skill_tree
```

| Flag | Description |
| --- | --- |
| `--gold=N` | Sets starting gold |
| `--stage=N` | Sets starting stage (0=Air, 1=Hay, 2=Tree, 3=Stone, 4=Waterfall, 5=Sensei) |
| `--skill_tree` | Unlocks the skill tree at startup |

