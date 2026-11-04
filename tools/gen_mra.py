#!/usr/bin/env python3
"""Generate MRAs for the SNK6502 core straight from MAME source. Engine: RodimusCoresMaster_MiSTer/tools/mra_lib.py
(its docstring has the release layout, the ioctl index map and the game-ID block).

Usage:
    gen_mra.py <releases_dir> [set ...]      (no sets: every supported set)
    gen_mra.py --check                       every GAME() in DRIVERS accounted for, every ROM_START parsed
"""
import re
import sys
from pathlib import Path
sys.path.insert(0, "/Work/Projects/RodimusCoresMaster_MiSTer/tools")
sys.path.insert(0, str(Path(__file__).resolve().parent))
import mra_lib
import dsnd_boards

GFX_HALF = [(0x000, 0x800, 0x10000), (0x800, 0x800, 0x11000)]
SPEECH = [(0x4000, 0x1800, 0x14000)]


def satansat_coinage(ports):
    """Coinage on SW1:2 + SW1:4 (mask 0x0A) -> one DIP per switch"""
    dsw = ports["DSW"]
    i = next(n for n, f in enumerate(dsw) if f["kind"] == "dip" and f["mask"] == 0x0A)
    dsw[i:i + 1] = [dict(mask=0x02, kind="dip", default=0x00, name="Coinage (SW1:2)", settings=[(0x00, "1C/1C"), (0x02, "1C/2C")]),
                    dict(mask=0x08, kind="dip", default=0x00, name="Coinage 2C/1C (SW1:4)", settings=[(0x00, "Off"), (0x08, "On")])]
    return ports


class Core(mra_lib.Core):
    RBF = "SNK6502"
    DRIVERS = ["snk6502.cpp"]
    CLK_HZ, FRAME_HZ = 45_158_400, 59.968
    REGIONS = {"maincpu": (0x00000, 0x10000), "gfx1": (0x10000, 0x2000), "proms": (0x12000, 0x40),
               "snk6502": (0x12040, 0x1800)}
    REGION_OVERRIDE = {"sasuke": {"gfx1": "split"}, "satansat": {"gfx1": "split"},
                       "vanguard": {"gfx1": "split", "speech": "split"}, "fantasy": {"speech": "split"}}
    REGION_SPLIT = {"sasuke": {"gfx1": GFX_HALF}, "satansat": {"gfx1": GFX_HALF},
                    "vanguard": {"gfx1": GFX_HALF, "speech": SPEECH}, "fantasy": {"speech": SPEECH}}
    SUPPORTED = {("sasuke", "empty_init"): 0, ("satansat", "empty_init"): 1, ("vanguard", "empty_init"): 2,
                 ("fantasy", "empty_init"): 3, ("pballoon", "empty_init"): 4, ("nibbler", "empty_init"): 5}
    PORTS = [("IN0",), ("IN1",), ("IN2",), ("DSW",), ("DSW1",), ("COIN",)]
    PORT_REWRITE = {"satansat": satansat_coinage}
    BUTTONS_BY_MACHINE = {"vanguard": {1: "Fire Right", 2: "Fire Down", 3: "Fire Up", 4: "Fire Left"}, "fantasy": {1: "Fire"}}
    SERIES_BY_PARENT = {"sasuke": ("Sasuke Vs. Commander", "Shooter"), "satansat": ("Satan Of Saturn", "Shooter"),
                        "vanguard": ("Vanguard", "Shooter"), "fantasyu": ("Fantasy", "Shooter"),
                        "pballoon": ("Pioneer Balloon", "Shooter"), "nibbler": ("Nibbler", "Maze")}
    HISCORE_INIT_FRAME = {"sasuke": 0, "satansat": 0, "vanguard": 0, "fantasyu": 7, "pballoon": 7, "nibbler": 178}
    HISCORE_FROM = {"sasukea": "sasuke", "vanguarda": "vanguard"}

    def index0(self, segs, g, variant):
        """ROMREGION_ERASEFF regions: the unloaded bytes are FF"""
        rom = re.search(r'ROM_START\(\s*%s\s*\)(.*?)ROM_END' % g["name"], self.src, re.S).group(1)
        for size, reg in re.findall(r'ROM_REGION\(\s*(0x[0-9a-fA-F]+)\s*,\s*"(\w+)"\s*,[^)]*ROMREGION_ERASEFF', rom):
            base, pos = self.REGIONS[reg][0], self.REGIONS[reg][0]
            for s in sorted((s for s in segs if s["region"] == reg), key=lambda s: s["addr"]) + [dict(addr=base + int(size, 16), len=0)]:
                if s["addr"] > pos:
                    segs = segs + [dict(name=None, crc=None, fill=0xFF, src=0, addr=pos, len=s["addr"] - pos, region=reg)]
                pos = s["addr"] + s["len"]
        return sorted(segs, key=lambda s: s["addr"]), []

    def dsnd_program(self, g):
        fn = dsnd_boards.BY_GAME_ID.get(self.variant(g))
        return bytes(fn().binary()) if fn else None


if __name__ == "__main__":
    Core().main(sys.argv)
