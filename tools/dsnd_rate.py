"""SNK6502 dsnd_engine rate: clk_sys 45.1584 MHz / TICK 941. Every board module imports this first."""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "RodimusCoresMaster_MiSTer" / "tools"))
import dsnd
CLK_HZ, TICK = 45158400, 941
dsnd.set_fs(CLK_HZ / TICK)
