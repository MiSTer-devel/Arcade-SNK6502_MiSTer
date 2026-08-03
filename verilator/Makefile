# Verilator bench for the SNK6502 HD38880 speech chain.
#
#   make            -> build + run phrase 2 with REAL CPU stimulus through
#                      hd38880_ctrl (the write stream from Vanguard's $6F30)
#   make forced     -> same chain, but reproducing the DIAG-REVERT-2026-08-01
#                      forced-start, to test whether that diagnostic was sound
#   make PHRASE=14  -> pick another phrase (trace fires 1, 2 and 14)
#
# Real RTL under ../rtl/sound/hd38880/ is read-only here; the only sim-local
# file is hd38880_top_sim.v (DIAG reverted + debug taps).

VERILATOR ?= verilator
RTL        = ../rtl/sound/hd38880
TOP        = hd38880_top_sim
PHRASE    ?= 2

SRCS = $(TOP).v \
       $(RTL)/hd38880_ctrl.v \
       $(RTL)/hd38880_unpack.v \
       $(RTL)/hd38880_dectab.v \
       $(RTL)/parcor_lattice.v

BIN = obj_dir/V$(TOP)

all: run

$(BIN): $(SRCS) hd38880_tb.cpp
	$(VERILATOR) --cc --exe --top-module $(TOP) -O3 \
	    -Wno-WIDTH -Wno-UNOPTFLAT -Wno-CASEINCOMPLETE -Wno-UNUSED \
	    -Wno-DECLFILENAME -Wno-BLKANDNBLK -Wno-fatal \
	    --Mdir obj_dir $(SRCS) hd38880_tb.cpp
	$(MAKE) -C obj_dir -f V$(TOP).mk V$(TOP)

build: $(BIN)

run: $(BIN)
	./$(BIN) --phrase=$(PHRASE)

forced: $(BIN)
	./$(BIN) --phrase=$(PHRASE) --force

clean:
	rm -rf obj_dir out_frames_*.csv out_audio_*.wav

.PHONY: all build run forced clean
