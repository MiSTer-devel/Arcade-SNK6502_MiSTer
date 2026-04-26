# Add MAME hiscore.dat support (Nibbler) + pause-audio (mute & freeze)

This document is a self-contained change request for Claude Code. Apply each
edit as a literal `old → new` substitution in the named file. Do not
re-architect, do not add features beyond what is described.

Project rule: stay grounded in MAME source and the schematic. We are
implementing what the original hardware does, not rewriting it. The
high-score RAM range and end-byte values come from MAME's hiscore.dat:

```
nibbler:
@:maincpu,ram,5993,28,00,5b
@:maincpu,ram,59bb,1e,00,00
```

We collapse those two adjacent ranges into one contiguous range
$5993-$59D8 (0x46 = 70 bytes) for simplicity. Last byte at $59D8 is 0x14
in a freshly-initialised table.

Files touched:

1. `Arcade-SNK6502.sv`              (top-level: hiscore module, pause wiring, audio mute)
2. `rtl/snk6502.v`                  (hi-score DPRAM, sound CE wiring, hiscore ports)
3. `rtl/sound/snk6502_sound.sv`     (clock-enable input, gate every sequential always block)
4. `rtl/sound/snk6502_noise.v`      (clock-enable input, gate both sequential always blocks)
5. `releases/Nibbler (Set 9).mra`   (fill in hiscore config + nvram size)

---

## 1. `Arcade-SNK6502.sv`

### 1.A — Add Autosave Hiscores to CONF_STR

Find:

```verilog
	"OB,Vertical flip,Off,On;",
	"-;",
	"DIP;",
	"-;",
	"P1,Pause options;",
```

Replace with:

```verilog
	"OB,Vertical flip,Off,On;",
	"-;",
	"H1OR,Autosave Hiscores,Off,On;",
	"-;",
	"DIP;",
	"-;",
	"P1,Pause options;",
```

### 1.B — status_menumask: gate Autosave on hs_configured

Find:

```verilog
	.status_menumask({direct_video}),
```

Replace with:

```verilog
	.status_menumask({~hs_configured, direct_video}),
```

### 1.C — Remove the dummy ioctl_upload_req / ioctl_din tie-offs

Find:

```verilog
assign ioctl_upload_req = 1'b0;
assign ioctl_din        = 8'd0;
```

Replace with:

```verilog
// ioctl_upload_req and ioctl_din are driven by the hiscore module instantiated below.
```

### 1.D — Wire pause_request to hs_pause

Find:

```verilog
// PAUSE SYSTEM
wire        pause_cpu;
wire [8:0]  rgb_out;
pause #(3,3,3,24) pause (
	.*,
	.user_button(m_pause),
	.pause_request(1'b0),
	.options(~status[26:25]),
	.r(rgb_in[2:0]),
	.g(rgb_in[5:3]),
	.b(rgb_in[8:6])
);
```

Replace with:

```verilog
// PAUSE SYSTEM
wire        pause_cpu;
wire [8:0]  rgb_out;
pause #(3,3,3,24) pause (
	.*,
	.user_button(m_pause),
	.pause_request(hs_pause),
	.options(~status[26:25]),
	.r(rgb_in[2:0]),
	.g(rgb_in[5:3]),
	.b(rgb_in[8:6])
);
```

### 1.E — Pass hiscore wires into the snk6502 instantiation

Find:

```verilog
snk6502 game_core(
	.clk_master (clk_master),
	.clk_sys    (clk_sys),
	.reset      (reset),
	.pause      (pause_cpu),

	.game_id    (game_id),

	.in0        (snk_in0),
	.in1        (snk_in1),
	.in2        (snk_in2),
	.dsw        (snk_dsw),

	.dn_addr    (ioctl_addr[16:0]),
	.dn_data    (ioctl_dout),
	.dn_wr      (ioctl_wr & rom_download),

	.rgb_r      (core_r),
	.rgb_g      (core_g),
	.rgb_b      (core_b),
	.hsync      (core_hs),
	.vsync      (core_vs),
	.hblank     (core_hb),
	.vblank     (core_vb),

	.audio      (core_audio),
	.flip_screen(core_flip),
	.ce_pix     (ce_pix),

	.dbg_game_id  (dbg_game_id),
	.dbg_crtc_hit (dbg_crtc_hit),
	.dbg_cpu_active(dbg_cpu_active)
);
```

Replace with:

```verilog
snk6502 game_core(
	.clk_master (clk_master),
	.clk_sys    (clk_sys),
	.reset      (reset),
	.pause      (pause_cpu),

	.game_id    (game_id),

	.in0        (snk_in0),
	.in1        (snk_in1),
	.in2        (snk_in2),
	.dsw        (snk_dsw),

	.dn_addr    (ioctl_addr[16:0]),
	.dn_data    (ioctl_dout),
	.dn_wr      (ioctl_wr & rom_download),

	.rgb_r      (core_r),
	.rgb_g      (core_g),
	.rgb_b      (core_b),
	.hsync      (core_hs),
	.vsync      (core_vs),
	.hblank     (core_hb),
	.vblank     (core_vb),

	.audio      (core_audio),
	.flip_screen(core_flip),
	.ce_pix     (ce_pix),

	.hs_address (hs_address),
	.hs_data_in (hs_data_in),
	.hs_data_out(hs_data_out),
	.hs_write   (hs_write_enable),

	.dbg_game_id  (dbg_game_id),
	.dbg_crtc_hit (dbg_crtc_hit),
	.dbg_cpu_active(dbg_cpu_active)
);
```

### 1.F — Audio mute on pause + add hiscore module instance

Find:

```verilog
assign CLK_VIDEO = clk_vid;
assign AUDIO_L = core_audio;
assign AUDIO_R = core_audio;
assign AUDIO_S = 1'b1;

endmodule
```

Replace with:

```verilog
assign CLK_VIDEO = clk_vid;
assign AUDIO_L = pause_cpu ? 16'sd0 : core_audio;
assign AUDIO_R = pause_cpu ? 16'sd0 : core_audio;
assign AUDIO_S = 1'b1;

// HISCORE SYSTEM
// --------------
// Runs on clk_sys (~45 MHz), like the Tutankham core. The hi-score DPRAM
// inside snk6502.v has its B port clocked on clk_sys to match this domain
// (port A is on clk_master for the CPU). Two-clock DPRAM: no CDC issues.
wire [15:0] hs_address;
wire [7:0]  hs_data_in;
wire [7:0]  hs_data_out;
wire        hs_write_enable;
wire        hs_access_read;
wire        hs_access_write;
wire        hs_pause;
wire        hs_configured;

hiscore #(
	.HS_ADDRESSWIDTH(16),
	.CFG_ADDRESSWIDTH(2),
	.CFG_LENGTHWIDTH(1)
) hi (
	.*,
	.clk(clk_sys),
	.paused(pause_cpu),
	.autosave(status[27]),
	.ram_address(hs_address),
	.data_from_ram(hs_data_out),
	.data_to_ram(hs_data_in),
	.data_from_hps(ioctl_dout),
	.data_to_hps(ioctl_din),
	.ram_write(hs_write_enable),
	.ram_intent_read(hs_access_read),
	.ram_intent_write(hs_access_write),
	.pause_cpu(hs_pause),
	.configured(hs_configured)
);

endmodule
```

---

## 2. `rtl/snk6502.v`

### 2.A — Add hiscore I/O to module port list

Find:

```verilog
    // Audio output (stub)
    output [15:0] audio,

    // Screen flip output
    output        flip_screen
);
```

Replace with:

```verilog
    // Audio output
    output [15:0] audio,

    // Screen flip output
    output        flip_screen,

    // Hiscore RAM access (driven by external hiscore module)
    input  [15:0] hs_address,
    input  [7:0]  hs_data_in,
    output [7:0]  hs_data_out,
    input         hs_write
);
```

### 2.B — Add the Nibbler high-score DPRAM

Find:

```verilog
spram #(.address_width(10)) work_ram(
    .clock  (clk_master),
    .enable (ram_cs),
    .wren   (ram_wr),
    .address(cpu_addr[9:0]),
    .data   (cpu_dout),
    .q      (ram_dout)
);

// ---------------------------------------------------------------------------
// Video RAM 2 (foreground tilemap) - 1KB at $0400-$07FF
```

Replace with:

```verilog
spram #(.address_width(10)) work_ram(
    .clock  (clk_master),
    .enable (ram_cs),
    .wren   (ram_wr),
    .address(cpu_addr[9:0]),
    .data   (cpu_dout),
    .q      (ram_dout)
);

// ---------------------------------------------------------------------------
// High-score RAM overlay
//
// Per MAME hiscore.dat, Nibbler stores high scores at $5993-$59D8 (70 bytes).
// On real hardware that range lives in the same window as the program ROM;
// on this core there's no general RAM in $3000-$BFFF. We add a small DPRAM
// mapped at the exact range $5993-$59D8 (only valid when game_id==NIBBLER).
//
// Lower 7 bits of address are used directly (cpu/hs):
//   $5993 -> 7'h13 ... $59D8 -> 7'h58.
// 128-entry DPRAM, ~58 entries unused — fine for resource cost.
//
// Port A: CPU (clk_master). Port B: hiscore module (clk_sys).
// Two-clock DPRAM avoids CDC concerns; the hiscore module holds address and
// write strobes stable for many cycles per access.
//
// To extend for other SNK6502 games later, add additional gated CS lines
// (e.g. vanguard_hi_ram_cs, fantasy_hi_ram_cs) and OR them into hi_ram_cs,
// mux per-game ranges into one shared DPRAM (or instantiate per-game RAMs).
// ---------------------------------------------------------------------------
wire        nibbler_hi_cs = (game_id == GID_NIBBLER) &&
                            (cpu_addr >= 16'h5993) && (cpu_addr <= 16'h59D8);
wire        hi_ram_cs     = nibbler_hi_cs;
wire        hi_ram_wr     = hi_ram_cs & ~cpu_rw_n & cpu_clken;
wire [7:0]  hi_ram_dout;

dpram #(.address_width(7)) hi_ram(
    .clock_a  (clk_master),
    .enable_a (1'b1),
    .wren_a   (hi_ram_wr),
    .address_a(cpu_addr[6:0]),
    .data_a   (cpu_dout),
    .q_a      (hi_ram_dout),

    .clock_b  (clk_sys),
    .enable_b (1'b1),
    .wren_b   (hs_write),
    .address_b(hs_address[6:0]),
    .data_b   (hs_data_in),
    .q_b      (hs_data_out)
);

// ---------------------------------------------------------------------------
// Video RAM 2 (foreground tilemap) - 1KB at $0400-$07FF
```

### 2.C — Mux hi_ram_dout into the CPU read data path

Find:

```verilog
assign cpu_din =
    ram_cs      ? ram_dout :
    vram2_cs    ? vram2_cpu_dout :
    vram1_cs    ? vram1_cpu_dout :
    colorram_cs ? colorram_cpu_dout :
    charram_cs  ? charram_cpu_dout :
    crtc_cs     ? crtc_dout :
    in0_cs      ? in0 :
    in1_cs      ? in1 :
    dsw_cs      ? dsw :
    in2_cs      ? in2 :
    rom_dout;
```

Replace with:

```verilog
assign cpu_din =
    ram_cs      ? ram_dout :
    hi_ram_cs   ? hi_ram_dout :
    vram2_cs    ? vram2_cpu_dout :
    vram1_cs    ? vram1_cpu_dout :
    colorram_cs ? colorram_cpu_dout :
    charram_cs  ? charram_cpu_dout :
    crtc_cs     ? crtc_dout :
    in0_cs      ? in0 :
    in1_cs      ? in1 :
    dsw_cs      ? dsw :
    in2_cs      ? in2 :
    rom_dout;
```

### 2.D — Pass `~pause` as clock-enable to the tone generator

Find:

```verilog
snk6502_snd sound(
    .clk         (clk_master),
    .reset       (reset),
    .sound_port0 (cpu_dout),
    .sound_port1 (cpu_dout),
    .sound_port2 (cpu_dout),
    .sound_port3 (cpu_dout),
    .wr0         (snd_wr0),
    .wr1         (snd_wr1),
    .wr2         (snd_wr2),
    .wr3         (snd_wr3),
    .snd_rom_data(snd_rom_dout),
    .snd_rom_addr(snd_rom_addr),
    .audio_out   (snd_audio)
);
```

Replace with:

```verilog
snk6502_snd sound(
    .clk         (clk_master),
    .cen         (~pause),
    .reset       (reset),
    .sound_port0 (cpu_dout),
    .sound_port1 (cpu_dout),
    .sound_port2 (cpu_dout),
    .sound_port3 (cpu_dout),
    .wr0         (snd_wr0),
    .wr1         (snd_wr1),
    .wr2         (snd_wr2),
    .wr3         (snd_wr3),
    .snd_rom_data(snd_rom_dout),
    .snd_rom_addr(snd_rom_addr),
    .audio_out   (snd_audio)
);
```

### 2.E — Pass `~pause` as clock-enable to the noise generator

Find:

```verilog
snk6502_noise noise_gen(
    .clk      (clk_master),
    .reset    (reset),
    .trigger  (bomb_trigger),
    .audio_out(noise_audio)
);
```

Replace with:

```verilog
snk6502_noise noise_gen(
    .clk      (clk_master),
    .cen      (~pause),
    .reset    (reset),
    .trigger  (bomb_trigger),
    .audio_out(noise_audio)
);
```

---

## 3. `rtl/sound/snk6502_sound.sv`

The sound module's `always @(posedge clk)` blocks must freeze when paused.
Add a `cen` (clock-enable) input and gate every sequential block. The
`always @*` block at line 245 is combinational and is left untouched.

### 3.A — Add `cen` to module port list

Find:

```verilog
module snk6502_snd (
    input  wire                 clk,          // 11.289 MHz master clock
    input  wire                 reset,
```

Replace with:

```verilog
module snk6502_snd (
    input  wire                 clk,          // 11.289 MHz master clock
    input  wire                 cen,          // clock enable (low = freeze, used for pause)
    input  wire                 reset,
```

### 3.B — Gate music_cnt counter (line ~175)

Find:

```verilog
    always @(posedge clk) begin
        if (reset) begin
            music_cnt <= 0;
        end else if (music_tick) begin
            music_cnt <= 0;
        end else begin
            music_cnt <= music_cnt + 1'd1;
        end
    end
```

Replace with:

```verilog
    always @(posedge clk) begin
        if (reset) begin
            music_cnt <= 0;
        end else if (cen) begin
            if (music_tick) begin
                music_cnt <= 0;
            end else begin
                music_cnt <= music_cnt + 1'd1;
            end
        end
    end
```

### 3.C — Gate ROM fetch sequencer (line ~190)

Find:

```verilog
    always @(posedge clk) begin
        if (reset) begin
            rom_sel       <= 0;
            rom_latch_sel <= 0;
        end else if (music_tick) begin
            rom_sel <= 0;
        end else if (rom_sel < 2) begin
            rom_sel <= rom_sel + 1'd1;
        end
        rom_latch_sel <= rom_sel;
    end
```

Replace with:

```verilog
    always @(posedge clk) begin
        if (reset) begin
            rom_sel       <= 0;
            rom_latch_sel <= 0;
        end else if (cen) begin
            if (music_tick) begin
                rom_sel <= 0;
            end else if (rom_sel < 2) begin
                rom_sel <= rom_sel + 1'd1;
            end
            rom_latch_sel <= rom_sel;
        end
    end
```

### 3.D — Gate ROM data latch (line ~203)

Find:

```verilog
    // Latch ROM data (handles both combinatorial ROM and registered BRAM)
    always @(posedge clk) begin
        case (rom_latch_sel)
            0: ch_romdata[0] <= snd_rom_data;
            1: ch_romdata[1] <= snd_rom_data;
            2: ch_romdata[2] <= snd_rom_data;
        endcase
    end
```

Replace with:

```verilog
    // Latch ROM data (handles both combinatorial ROM and registered BRAM)
    always @(posedge clk) begin
        if (cen) begin
            case (rom_latch_sel)
                0: ch_romdata[0] <= snd_rom_data;
                1: ch_romdata[1] <= snd_rom_data;
                2: ch_romdata[2] <= snd_rom_data;
            endcase
        end
    end
```

### 3.E — Gate phase_step from ROM (line ~224)

Find:

```verilog
    always @(posedge clk) begin
        if (reset) begin
            ch_phase_step[0] <= 0;
            ch_phase_step[1] <= 0;
            ch_phase_step[2] <= 0;
        end else if (rom_latch_sel < 3) begin
            if (snd_rom_data == 8'hff) begin
                ch_phase_step[rom_latch_sel] <= 0;
            end else begin
                idx = 8'd255 - snd_rom_data;
                ch_phase_step[rom_latch_sel] <= phase_inc_lut[idx] >> 8;
            end
        end
    end
```

Replace with:

```verilog
    always @(posedge clk) begin
        if (reset) begin
            ch_phase_step[0] <= 0;
            ch_phase_step[1] <= 0;
            ch_phase_step[2] <= 0;
        end else if (cen) begin
            if (rom_latch_sel < 3) begin
                if (snd_rom_data == 8'hff) begin
                    ch_phase_step[rom_latch_sel] <= 0;
                end else begin
                    idx = 8'd255 - snd_rom_data;
                    ch_phase_step[rom_latch_sel] <= phase_inc_lut[idx] >> 8;
                end
            end
        end
    end
```

### 3.F — Gate phase accumulators (line ~258)

Find:

```verilog
    always @(posedge clk) begin
        if (reset) begin
            ch_phase[0] <= 0; ch_phase[1] <= 0; ch_phase[2] <= 0;
        end else begin
            for (i = 0; i < 3; i = i + 1) begin
                if (!ch_mute[i]) begin
                    ch_phase[i] <= ch_phase[i] + ch_phase_step[i];
                end
            end
        end
    end
```

Replace with:

```verilog
    always @(posedge clk) begin
        if (reset) begin
            ch_phase[0] <= 0; ch_phase[1] <= 0; ch_phase[2] <= 0;
        end else if (cen) begin
            for (i = 0; i < 3; i = i + 1) begin
                if (!ch_mute[i]) begin
                    ch_phase[i] <= ch_phase[i] + ch_phase_step[i];
                end
            end
        end
    end
```

### 3.G — Gate waveform rebuild state machine (line ~274)

Find:

```verilog
    always @(posedge clk) begin
        if (reset) begin
            wf_busy  <= 1'b0;
            wf_state <= 5'd0;
        end else if (wf_wr && !wf_busy) begin
            ch0_wf_mask <= ch0_mask_calc;
            ch1_wf_mask <= wf_data[7:4];
            wf_busy  <= 1'b1;
            wf_state <= 5'd0;
        end else if (wf_busy) begin
            // compute waveform entry (exact MAME build_waveform formula)
            wf_m = wf_state[4] ? ch1_wf_mask : ch0_wf_mask;
            wf_j = wf_state[3:0];
            wf_bit3 = (wf_m[0] || wf_m[1]) ? 5'd8 : wf_m[2] ? 5'd4 : wf_m[3] ? 5'd2 : 5'd0;
            wf_bit2 = wf_m[2] ? 5'd8 : (wf_m[1] || wf_m[3]) ? 5'd4 : 5'd0;
            wf_bit1 = wf_m[3] ? 5'd8 : wf_m[2] ? 5'd4 : wf_m[1] ? 5'd2 : 5'd0;
            wf_bit0 = wf_bit1 >> 1;
            if ((wf_bit0 + wf_bit1 + wf_bit2 + wf_bit3) < 5'd16) begin
                wf_bit0 = wf_bit0 << 1;
                wf_bit1 = wf_bit1 << 1;
                wf_bit2 = wf_bit2 << 1;
                wf_bit3 = wf_bit3 << 1;
            end
            wf_base_val = (wf_bit0 + wf_bit1 + wf_bit2 + wf_bit3 + 5'd1) / 5'd2;
            wf_data_val = (wf_j[0] ? wf_bit0 : 5'd0) + (wf_j[1] ? wf_bit1 : 5'd0) + (wf_j[2] ? wf_bit2 : 5'd0) + (wf_j[3] ? wf_bit3 : 5'd0);
            ch_form[wf_state[4]][wf_j] <= ($signed(wf_data_val) - $signed(wf_base_val)) * 16'sd409;
            wf_state <= wf_state + 5'd1;
            if (wf_state == 5'd31) begin
                wf_busy <= 1'b0;
            end
        end
    end
```

Replace with:

```verilog
    always @(posedge clk) begin
        if (reset) begin
            wf_busy  <= 1'b0;
            wf_state <= 5'd0;
        end else if (cen) begin
            if (wf_wr && !wf_busy) begin
                ch0_wf_mask <= ch0_mask_calc;
                ch1_wf_mask <= wf_data[7:4];
                wf_busy  <= 1'b1;
                wf_state <= 5'd0;
            end else if (wf_busy) begin
                // compute waveform entry (exact MAME build_waveform formula)
                wf_m = wf_state[4] ? ch1_wf_mask : ch0_wf_mask;
                wf_j = wf_state[3:0];
                wf_bit3 = (wf_m[0] || wf_m[1]) ? 5'd8 : wf_m[2] ? 5'd4 : wf_m[3] ? 5'd2 : 5'd0;
                wf_bit2 = wf_m[2] ? 5'd8 : (wf_m[1] || wf_m[3]) ? 5'd4 : 5'd0;
                wf_bit1 = wf_m[3] ? 5'd8 : wf_m[2] ? 5'd4 : wf_m[1] ? 5'd2 : 5'd0;
                wf_bit0 = wf_bit1 >> 1;
                if ((wf_bit0 + wf_bit1 + wf_bit2 + wf_bit3) < 5'd16) begin
                    wf_bit0 = wf_bit0 << 1;
                    wf_bit1 = wf_bit1 << 1;
                    wf_bit2 = wf_bit2 << 1;
                    wf_bit3 = wf_bit3 << 1;
                end
                wf_base_val = (wf_bit0 + wf_bit1 + wf_bit2 + wf_bit3 + 5'd1) / 5'd2;
                wf_data_val = (wf_j[0] ? wf_bit0 : 5'd0) + (wf_j[1] ? wf_bit1 : 5'd0) + (wf_j[2] ? wf_bit2 : 5'd0) + (wf_j[3] ? wf_bit3 : 5'd0);
                ch_form[wf_state[4]][wf_j] <= ($signed(wf_data_val) - $signed(wf_base_val)) * 16'sd409;
                wf_state <= wf_state + 5'd1;
                if (wf_state == 5'd31) begin
                    wf_busy <= 1'b0;
                end
            end
        end
    end
```

### 3.H — Gate CPU port writes (line ~311)

Find:

```verilog
    always @(posedge clk) begin
        if (reset) begin
            // initial state (MAME device_start + set_music_freq)
            ch_mute[0]   <= 1'b1;
            ch_mute[1]   <= 1'b1;
            ch_mute[2]   <= 1'b1;
            ch_offset[0] <= 0; ch_offset[1] <= 0; ch_offset[2] <= 0;
            ch_mask[0]   <= 8'hff; ch_mask[1] <= 8'hff; ch_mask[2] <= 8'hff;
            ch_base[0]   <= 11'h0000;
            ch_base[1]   <= 11'h0800;
            ch_base[2]   <= 11'h1000;          // ch2 starts at $1000 (high bits set on writes)
            wf_wr        <= 1'b0;              // rebuild trigger must start cleared (was power-up undefined)

            // Channel 2 is always a square wave (MAME special case). Initialize at reset.
            // ch0/ch1 will be rebuilt on first wr2 (MAME build_waveform called later).
            for (j = 0; j < 16; j = j + 1) begin
                ch_form[2][j] <= j[3] ? 16'sd7 * 16'sd409 : -16'sd8 * 16'sd409;
            end
        end else begin
            if (music_tick) begin
                ch_offset[0] <= (ch_offset[0] + 1'd1) & ch_mask[0];
                ch_offset[1] <= (ch_offset[1] + 1'd1) & ch_mask[1];
                ch_offset[2] <= (ch_offset[2] + 1'd1) & ch_mask[2];
            end
            if (wr0) begin
                // fantasy offset 0
                ch_base[0]   <= {sound_port0[2:0], 8'h00};
                // ch0: reset offset on mute OR on mute->unmute edge (MAME mute_channel / unmute_channel)
                if (sound_port0[3] == 1'b0 || ch_mute[0]) ch_offset[0] <= 0;
                ch_mute[0]   <= ~sound_port0[3];
                // ch2: same rule
                if (sound_port0[4] == 1'b0 || ch_mute[2]) ch_offset[2] <= 0;
                ch_mute[2]   <= ~sound_port0[4];
            end

            if (wr1) begin
                // fantasy offset 1
                ch_base[1]   <= 13'h0800 | {sound_port1[2:0], 8'h00};
                // ch1: reset offset on mute OR on mute->unmute edge (MAME mute_channel / unmute_channel)
                if (sound_port1[3] == 1'b0 || ch_mute[1]) ch_offset[1] <= 0;
                ch_mute[1]   <= ~sound_port1[3];
            end

            if (wr2) begin
                // fantasy offset 2 – latch waveform data (triggers rebuild state machine)
                wf_data <= sound_port2;
                wf_wr   <= 1'b1;
            end else if (wf_busy) begin
                // FSM has latched the request; clear strobe so rebuild fires once per wr2
                wf_wr   <= 1'b0;
            end

            if (wr3) begin
                // fantasy offset 3 – ch2 base high bits ($1000 region)
                // MAME: 0x1000 | ((data & 0x70) << 4)  → bits [6:4] land at addr[10:8]
                ch_base[2]   <= 13'h1000 | {sound_port3[6:4], 8'h00};
            end
        end
    end
```

Replace with:

```verilog
    always @(posedge clk) begin
        if (reset) begin
            // initial state (MAME device_start + set_music_freq)
            ch_mute[0]   <= 1'b1;
            ch_mute[1]   <= 1'b1;
            ch_mute[2]   <= 1'b1;
            ch_offset[0] <= 0; ch_offset[1] <= 0; ch_offset[2] <= 0;
            ch_mask[0]   <= 8'hff; ch_mask[1] <= 8'hff; ch_mask[2] <= 8'hff;
            ch_base[0]   <= 11'h0000;
            ch_base[1]   <= 11'h0800;
            ch_base[2]   <= 11'h1000;          // ch2 starts at $1000 (high bits set on writes)
            wf_wr        <= 1'b0;              // rebuild trigger must start cleared (was power-up undefined)

            // Channel 2 is always a square wave (MAME special case). Initialize at reset.
            // ch0/ch1 will be rebuilt on first wr2 (MAME build_waveform called later).
            for (j = 0; j < 16; j = j + 1) begin
                ch_form[2][j] <= j[3] ? 16'sd7 * 16'sd409 : -16'sd8 * 16'sd409;
            end
        end else if (cen) begin
            if (music_tick) begin
                ch_offset[0] <= (ch_offset[0] + 1'd1) & ch_mask[0];
                ch_offset[1] <= (ch_offset[1] + 1'd1) & ch_mask[1];
                ch_offset[2] <= (ch_offset[2] + 1'd1) & ch_mask[2];
            end
            if (wr0) begin
                // fantasy offset 0
                ch_base[0]   <= {sound_port0[2:0], 8'h00};
                // ch0: reset offset on mute OR on mute->unmute edge (MAME mute_channel / unmute_channel)
                if (sound_port0[3] == 1'b0 || ch_mute[0]) ch_offset[0] <= 0;
                ch_mute[0]   <= ~sound_port0[3];
                // ch2: same rule
                if (sound_port0[4] == 1'b0 || ch_mute[2]) ch_offset[2] <= 0;
                ch_mute[2]   <= ~sound_port0[4];
            end

            if (wr1) begin
                // fantasy offset 1
                ch_base[1]   <= 13'h0800 | {sound_port1[2:0], 8'h00};
                // ch1: reset offset on mute OR on mute->unmute edge (MAME mute_channel / unmute_channel)
                if (sound_port1[3] == 1'b0 || ch_mute[1]) ch_offset[1] <= 0;
                ch_mute[1]   <= ~sound_port1[3];
            end

            if (wr2) begin
                // fantasy offset 2 – latch waveform data (triggers rebuild state machine)
                wf_data <= sound_port2;
                wf_wr   <= 1'b1;
            end else if (wf_busy) begin
                // FSM has latched the request; clear strobe so rebuild fires once per wr2
                wf_wr   <= 1'b0;
            end

            if (wr3) begin
                // fantasy offset 3 – ch2 base high bits ($1000 region)
                // MAME: 0x1000 | ((data & 0x70) << 4)  → bits [6:4] land at addr[10:8]
                ch_base[2]   <= 13'h1000 | {sound_port3[6:4], 8'h00};
            end
        end
    end
```

### 3.I — Gate audio output mixer (line ~375)

Find:

```verilog
    always @(posedge clk) begin
        if (reset) begin
            audio_out <= 0;
        end else begin
            sum = 0;
            for (i = 0; i < 3; i = i + 1) begin
                if (!ch_mute[i] && ch_phase_step[i] != 0) begin
                    cur_pos = ch_phase[i] + ch_phase_step[i];
                    prev_idx = ch_phase[i][27:24];
                    cur_idx  = cur_pos[27:24];
                    prev_val = ch_form[i][prev_idx];
                    cur_val  = ch_form[i][cur_idx];
                    frac = cur_pos[23:8];
                    interp = ((prev_val * (FRAC_ONE - frac)) +
                              (cur_val  * frac)) >> FRAC_BITS;
                    sum = sum + interp;
                end
            end
            // MAME scales each waveform entry by 65535/160 (= 409), so
            // per-channel peak is ±3272 and the 3-channel sum peaks at
            // ±9816 — fits in 15 bits signed with headroom. Take the
            // low 16 bits directly (no attenuation).
            audio_out <= sum[18:3];   // fits comfortably in 16-bit signed range
        end
    end
```

Replace with:

```verilog
    always @(posedge clk) begin
        if (reset) begin
            audio_out <= 0;
        end else if (cen) begin
            sum = 0;
            for (i = 0; i < 3; i = i + 1) begin
                if (!ch_mute[i] && ch_phase_step[i] != 0) begin
                    cur_pos = ch_phase[i] + ch_phase_step[i];
                    prev_idx = ch_phase[i][27:24];
                    cur_idx  = cur_pos[27:24];
                    prev_val = ch_form[i][prev_idx];
                    cur_val  = ch_form[i][cur_idx];
                    frac = cur_pos[23:8];
                    interp = ((prev_val * (FRAC_ONE - frac)) +
                              (cur_val  * frac)) >> FRAC_BITS;
                    sum = sum + interp;
                end
            end
            // MAME scales each waveform entry by 65535/160 (= 409), so
            // per-channel peak is ±3272 and the 3-channel sum peaks at
            // ±9816 — fits in 15 bits signed with headroom. Take the
            // low 16 bits directly (no attenuation).
            audio_out <= sum[18:3];   // fits comfortably in 16-bit signed range
        end
    end
```

---

## 4. `rtl/sound/snk6502_noise.v`

### 4.A — Add `cen` to module port list

Find:

```verilog
module snk6502_noise (
    input  wire        clk,       // 11.289 MHz master clock
    input  wire        reset,
    input  wire        trigger,   // rising edge fires one-shot
    output reg  signed [15:0] audio_out
);
```

Replace with:

```verilog
module snk6502_noise (
    input  wire        clk,       // 11.289 MHz master clock
    input  wire        cen,       // clock enable (low = freeze, used for pause)
    input  wire        reset,
    input  wire        trigger,   // rising edge fires one-shot
    output reg  signed [15:0] audio_out
);
```

### 4.B — Gate LFSR

Find:

```verilog
    always @(posedge clk) begin
        if (reset)
            lfsr <= 16'hACE1;
        else
            lfsr <= {lfsr_feedback, lfsr[15:1]} ^
                    (lfsr_feedback ? 16'hB400 : 16'h0000);
    end
```

Replace with:

```verilog
    always @(posedge clk) begin
        if (reset)
            lfsr <= 16'hACE1;
        else if (cen)
            lfsr <= {lfsr_feedback, lfsr[15:1]} ^
                    (lfsr_feedback ? 16'hB400 : 16'h0000);
    end
```

### 4.C — Gate one-shot decay + audio output

Find:

```verilog
    // One-shot state machine + output
    always @(posedge clk) begin
        if (reset) begin
            decay_cnt <= 0;
            trig_prev <= 0;
            audio_out <= 0;
        end else begin
            trig_prev <= trigger;

            if (trig_edge)
                decay_cnt <= DECAY_LEN;
            else if (|decay_cnt)
                decay_cnt <= decay_cnt - 1'd1;

            if (|decay_cnt)
                audio_out <= $signed(noise_sig) * $signed({1'b0, envelope}) >>> 4;
            else
                audio_out <= 0;
        end
    end
```

Replace with:

```verilog
    // One-shot state machine + output
    always @(posedge clk) begin
        if (reset) begin
            decay_cnt <= 0;
            trig_prev <= 0;
            audio_out <= 0;
        end else if (cen) begin
            trig_prev <= trigger;

            if (trig_edge)
                decay_cnt <= DECAY_LEN;
            else if (|decay_cnt)
                decay_cnt <= decay_cnt - 1'd1;

            if (|decay_cnt)
                audio_out <= $signed(noise_sig) * $signed({1'b0, envelope}) >>> 4;
            else
                audio_out <= 0;
        end
    end
```

---

## 5. `releases/Nibbler (Set 9).mra`

Replace the existing empty `<rom index="3">` block (and the missing
`<nvram>` element) with the populated hiscore config and an nvram entry of
the matching length.

### 5.A — Fill ROM index 3 + add nvram

Find:

```xml
    <!-- ROM index 3: High Scores -->
    <!-- Scores   : $5993 To $59BA -->
    <!-- Initials : $59BB To $59D8 -->
    <rom index="3">
    <part></part>
    </rom>


</misterromdescription>
```

Replace with:

```xml
    <!-- ROM index 3: Hiscore.dat configuration -->
    <!--   Header (16 bytes):                                                       -->
    <!--     01 FF FF FF   START_WAIT  = 0x01FFFFFF  (~0.7s @ 45MHz initial wait)   -->
    <!--     00 FF         CHECK_WAIT  = 0x00FF                                     -->
    <!--     00 02         CHECK_HOLD  = 0x0002                                     -->
    <!--     00 02         WRITE_HOLD  = 0x0002                                     -->
    <!--     00 01         WRITE_REPEATCOUNT = 0x0001                               -->
    <!--     00 FF         WRITE_REPEATWAIT  = 0x00FF                               -->
    <!--     00            ACCESS_PAUSEPAD   = 0x00                                 -->
    <!--     00            CHANGEMASK        = 0x00                                 -->
    <!--                                                                            -->
    <!--   Entry 1 (8 bytes): scores+initials combined ($5993-$59D8, 70 bytes)      -->
    <!--     ADDR=$5993, LEN=$46, START=$00, END=$14                                -->
    <rom index="3">
        <part>
            01 FF FF FF 00 FF 00 02 00 02 00 01 00 FF 00 00
            00 00 59 93 46 00 14 00
        </part>
    </rom>

    <nvram index="4" size="70"/>

</misterromdescription>
```

---

## Verification checklist (after applying)

1. `Arcade-SNK6502.sv` compiles. Search for `pause_request(1'b0)` — should be **gone**.
2. `Arcade-SNK6502.sv` should have **no** `assign ioctl_upload_req = 1'b0;` or `assign ioctl_din = 8'd0;` lines.
3. `rtl/snk6502.v` module port list includes `hs_address`, `hs_data_in`, `hs_data_out`, `hs_write`.
4. `rtl/snk6502.v` cpu_din mux contains `hi_ram_cs ? hi_ram_dout :` between `ram_cs` and `vram2_cs`.
5. Both sound module instantiations in `rtl/snk6502.v` pass `.cen(~pause)`.
6. `rtl/sound/snk6502_sound.sv` and `rtl/sound/snk6502_noise.v` both declare `input wire cen,` in their port lists.
7. Every `always @(posedge clk)` in those two files has either `if (reset) ... else if (cen) ...` or a top-level `if (cen)` guard. The single `always @*` block at line ~245 in snk6502_sound.sv stays unchanged.
8. Nibbler MRA `<rom index="3">` contains the 24-byte hex blob exactly as listed and `<nvram index="4" size="70"/>` is present.
9. Build the core. Boot Nibbler. Confirm: title screen → demo → high-score table appears. Insert coin, score, enter initials, reboot core — score should persist (autosave on if status[27] is set).
10. Pause via L-shoulder (or assigned pause): audio cuts immediately and resumes cleanly when unpaused (no glitch from frozen-then-resumed sound state).
