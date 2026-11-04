"""SNK6502 dsnd programs (MRA index 5), by game id (MRA index 1 byte 0). Levels: MAME's mix balance (route gain x this
core's tone-generator level vs MAME's: 0.12 Vanguard, 0.16 Fantasy); Vanguard SHOT A / BOMB = MAME's sample levels."""
import dsnd_rate  # noqa: F401
import dsnd_snk6502 as snk

def vanguard():
    return snk.vanguard(scale_bomb=0.028146, scale_a=0.005084, scale_b=0.25 * 0.12 / 1.855)

def fantasy():
    return snk.fantasy(scale_bomb=0.5 * 0.16 / 12.0)

BY_GAME_ID = {2: vanguard, 3: fantasy, 4: fantasy, 5: fantasy}    # 0 Sasuke / 1 Satan of Saturn: none yet
