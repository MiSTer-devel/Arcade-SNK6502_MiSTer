//============================================================================
//  SNK6502 FPGA Core
//
//  Supports: Sasuke vs. Commander, Satan of Saturn / Zarzon, Vanguard,
//            Fantasy, Pioneer Balloon, Nibbler
//
//  Phase 05: Address decode, I/O registers, inputs, NMI
//============================================================================

module snk6502(
    input         clk_master,     // 11.289 MHz master clock
    input         clk_sys,        // ~45 MHz system clock (for ROM download)
    input         reset,
    input         pause,
    output        ce_pix,

    // Game configuration (selects memory map / I/O layout)
    input  [3:0]  game_id,        // which game variant (see defines below)

    // Player inputs
    input  [7:0]  in0,            // IN0 port
    input  [7:0]  in1,            // IN1 port
    input  [7:0]  in2,            // IN2 port (coins, starts)
    input  [7:0]  dsw,            // DIP switches

    // ROM download interface
    input  [16:0] dn_addr,
    input  [7:0]  dn_data,
    input         dn_wr,

    // Video output
    output [7:0]  rgb_r,
    output [7:0]  rgb_g,
    output [7:0]  rgb_b,
    output        hsync,
    output        vsync,
    output        hblank,
    output        vblank,

    // Audio output (stub)
    output [15:0] audio,

    // Screen flip output
    output        flip_screen,

    // Sound channel 0 mute status (MAME music0_playing — active high when muted).
    // Wired into IN port custom bits at top level.
    output        music0_playing
);

// Game IDs
localparam GID_SASUKE   = 4'd0;
localparam GID_SATANSAT = 4'd1;
localparam GID_VANGUARD = 4'd2;
localparam GID_FANTASY  = 4'd3;
localparam GID_PBALLOON = 4'd4;
localparam GID_NIBBLER  = 4'd5;

// I/O region base address varies by game
// Vanguard:        $31xx (reads at $3104-$3107)
// Fantasy:         $21xx
// PBalloon:        $B1xx
// Sasuke/SatanSat: $B0xx (different register layout)

// ---------------------------------------------------------------------------
// ROM download address decoding
// Layout: $00000-$0FFFF = maincpu (64K), $10000-$11FFF = gfx1 (8K),
//         $12000-$1203F = proms (64 bytes), $12040-$137FF = sound ROM (6K),
//         $14000-$157FF = speech ROM (6K, Vanguard/Fantasy HD38880 PARCOR data)
wire dn_maincpu = (dn_addr[16:16] == 1'b0);                    // $00000-$0FFFF
wire dn_gfx1    = (dn_addr[16:13] == 4'b1_000);                // $10000-$11FFF
wire dn_proms   = (dn_addr[16:6]  == 11'b1_0010_0000_00);      // $12000-$1203F
wire dn_sndrom  = (dn_addr[16:13] == 4'b1_001) & ~dn_proms;    // $12040-$13FFF
wire dn_speech  = (dn_addr[16:13] == 4'b1_010);                // $14000-$15FFF

// ---------------------------------------------------------------------------
// Clock generation
// ---------------------------------------------------------------------------
reg [3:0] clk_div;
always @(posedge clk_master or posedge reset)
    if (reset)
        clk_div <= 4'd0;
    else
        clk_div <= clk_div + 4'd1;

wire crtc_clken = (clk_div == 4'd15);

wire is_slow_cpu = (game_id == GID_SASUKE) || (game_id == GID_SATANSAT);
wire cpu_clken   = is_slow_cpu ? crtc_clken : (clk_div[2:0] == 3'd7);

// ---------------------------------------------------------------------------
// Reset logic
// ---------------------------------------------------------------------------
reg [7:0] reset_cnt;
reg       cpu_reset;
wire      cpu_reset_n = ~cpu_reset;

always @(posedge clk_master)
    if (reset) begin
        cpu_reset <= 1'b1;
        reset_cnt <= 8'd0;
    end else begin
        if (reset_cnt != 8'h10)
            reset_cnt <= reset_cnt + 8'd1;
        else
            cpu_reset <= 1'b0;
    end

// ---------------------------------------------------------------------------
// CPU instantiation (T65 - 6502 mode)
// ---------------------------------------------------------------------------
wire [15:0] cpu_addr;
wire [7:0]  cpu_din;
wire [7:0]  cpu_dout;
wire        cpu_rw_n;
wire        cpu_nmi_n;

wire cpu_rdy;
wire is_highmem_read = cpu_rw_n & (cpu_addr[15:14] != 2'b00);
wire needs_wait = ~is_slow_cpu & is_highmem_read;

reg wait_state;
always @(posedge clk_master or posedge reset)
    if (reset)
        wait_state <= 1'b0;
    else if (cpu_clken)
        wait_state <= needs_wait & ~wait_state;

assign cpu_rdy = ~pause & ~(needs_wait & ~wait_state);

T65 cpu(
    .mode   (2'b00),
    .res_n  (cpu_reset_n),
    .enable (cpu_clken),
    .clk    (clk_master),
    .rdy    (cpu_rdy),
    .abort_n(1'b1),
    .irq_n  (cpu_irq_n),
    .nmi_n  (cpu_nmi_n),
    .so_n   (1'b1),
    .r_w_n  (cpu_rw_n),
    .a      (cpu_addr),
    .di     (cpu_din),
    .do     (cpu_dout)
);

// ---------------------------------------------------------------------------
// Program ROM - 64KB (sparse, loaded by .mra at correct addresses)
// ---------------------------------------------------------------------------
wire [7:0] rom_dout;

dpram #(.address_width(16)) prog_rom(
    .clock_a  (clk_sys),
    .enable_a (1'b1),
    .wren_a   (dn_wr & dn_maincpu),
    .address_a(dn_addr[15:0]),
    .data_a   (dn_data),
    .q_a      (),

    .clock_b  (clk_master),
    .enable_b (1'b1),
    .wren_b   (1'b0),
    .address_b(cpu_addr),
    .data_b   (8'd0),
    .q_b      (rom_dout)
);

// ---------------------------------------------------------------------------
// Work RAM - 1KB at $0000-$03FF
// ---------------------------------------------------------------------------
wire ram_cs = (cpu_addr[15:10] == 6'b000000);
wire [7:0] ram_dout;
wire ram_wr = ram_cs & ~cpu_rw_n & cpu_clken;

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
// ---------------------------------------------------------------------------
wire vram2_cs = (cpu_addr[15:10] == 6'b000001);
wire [7:0] vram2_cpu_dout;
//wire vram2_wr = vram2_cs & ~cpu_rw_n;
wire vram2_wr = vram2_cs & ~cpu_rw_n & cpu_clken;

wire [9:0] vram2_vid_addr;
wire [7:0] vram2_vid_dout;

dpram #(.address_width(10)) vram2(
    .clock_a  (clk_master),
    .enable_a (1'b1),
    .wren_a   (vram2_wr),
    .address_a(cpu_addr[9:0]),
    .data_a   (cpu_dout),
    .q_a      (vram2_cpu_dout),

    .clock_b  (clk_master),
    .enable_b (1'b1),
    .wren_b   (1'b0),
    .address_b(vram2_vid_addr),
    .data_b   (8'd0),
    .q_b      (vram2_vid_dout)
);

// ---------------------------------------------------------------------------
// Video RAM 1 (background tilemap) - 1KB at $0800-$0BFF
// ---------------------------------------------------------------------------
wire vram1_cs = (cpu_addr[15:10] == 6'b000010);
wire [7:0] vram1_cpu_dout;
//wire vram1_wr = vram1_cs & ~cpu_rw_n;
wire vram1_wr = vram1_cs & ~cpu_rw_n & cpu_clken;

wire [9:0] vram1_vid_addr;
wire [7:0] vram1_vid_dout;

dpram #(.address_width(10)) vram1(
    .clock_a  (clk_master),
    .enable_a (1'b1),
    .wren_a   (vram1_wr),
    .address_a(cpu_addr[9:0]),
    .data_a   (cpu_dout),
    .q_a      (vram1_cpu_dout),

    .clock_b  (clk_master),
    .enable_b (1'b1),
    .wren_b   (1'b0),
    .address_b(vram1_vid_addr),
    .data_b   (8'd0),
    .q_b      (vram1_vid_dout)
);

// ---------------------------------------------------------------------------
// Color RAM - 1KB at $0C00-$0FFF
// ---------------------------------------------------------------------------
wire colorram_cs = (cpu_addr[15:10] == 6'b000011);
wire [7:0] colorram_cpu_dout;
// wire colorram_wr = colorram_cs & ~cpu_rw_n;
wire colorram_wr = colorram_cs & ~cpu_rw_n & cpu_clken;

wire [9:0] colorram_fg_vid_addr;  // unscrolled (FG tile)
wire [9:0] colorram_bg_vid_addr;  // scrolled   (BG tile)
wire [7:0] colorram_fg_vid_dout;
wire [7:0] colorram_bg_vid_dout;

// Copy A: CPU port + FG video port (drives CPU readback)
dpram #(.address_width(10)) color_ram_fg(
    .clock_a  (clk_master),
    .enable_a (1'b1),
    .wren_a   (colorram_wr),
    .address_a(cpu_addr[9:0]),
    .data_a   (cpu_dout),
    .q_a      (colorram_cpu_dout),

    .clock_b  (clk_master),
    .enable_b (1'b1),
    .wren_b   (1'b0),
    .address_b(colorram_fg_vid_addr),
    .data_b   (8'd0),
    .q_b      (colorram_fg_vid_dout)
);

// Copy B: mirror writes from CPU; video port drives BG color attribute
dpram #(.address_width(10)) color_ram_bg(
    .clock_a  (clk_master),
    .enable_a (1'b1),
    .wren_a   (colorram_wr),
    .address_a(cpu_addr[9:0]),
    .data_a   (cpu_dout),
    .q_a      (),

    .clock_b  (clk_master),
    .enable_b (1'b1),
    .wren_b   (1'b0),
    .address_b(colorram_bg_vid_addr),
    .data_b   (8'd0),
    .q_b      (colorram_bg_vid_dout)
);

// ---------------------------------------------------------------------------
// Character Generator RAM - 4KB at $1000-$1FFF
// ---------------------------------------------------------------------------
wire charram_cs = (cpu_addr[15:12] == 4'b0001);
// CPU-side readback: separate wire per plane, muxed on cpu_addr[11]
wire [7:0] charram_p0_cpu_dout;
wire [7:0] charram_p1_cpu_dout;
wire [7:0] charram_cpu_dout = cpu_addr[11] ? charram_p1_cpu_dout : charram_p0_cpu_dout;

// wire charram_wr = charram_cs & ~cpu_rw_n;
wire charram_wr = charram_cs & ~cpu_rw_n & cpu_clken;

// Charram split into two 2KB planes for simultaneous video read
// Plane 0 (IC67): $1000-$17FF (addr bit 11 = 0)
// Plane 1 (IC68): $1800-$1FFF (addr bit 11 = 1)
wire [10:0] charram_vid_addr = {fg_tile_code, tile_line};
wire [7:0]  charram_p0_dout, charram_p1_dout;

dpram #(.address_width(11)) char_ram_p0(
    .clock_a  (clk_master),
    .enable_a (1'b1),
    .wren_a   (charram_wr & ~cpu_addr[11]),
    .address_a(cpu_addr[10:0]),
    .data_a   (cpu_dout),
    .q_a      (charram_p0_cpu_dout),

    .clock_b  (clk_master),
    .enable_b (1'b1),
    .wren_b   (1'b0),
    .address_b(charram_vid_addr),
    .data_b   (8'd0),
    .q_b      (charram_p0_dout)
);

dpram #(.address_width(11)) char_ram_p1(
    .clock_a  (clk_master),
    .enable_a (1'b1),
    .wren_a   (charram_wr & cpu_addr[11]),
    .address_a(cpu_addr[10:0]),
    .data_a   (cpu_dout),
    .q_a      (charram_p1_cpu_dout),

    .clock_b  (clk_master),
    .enable_b (1'b1),
    .wren_b   (1'b0),
    .address_b(charram_vid_addr),
    .data_b   (8'd0),
    .q_b      (charram_p1_dout)
);

// GFX ROM - always split at 4KB boundary in download space
// MRA must pad plane 0 to 4KB before plane 1 data
wire dn_gfx_p0 = dn_gfx1 & (dn_addr[12] == 1'b0);   // $10000-$10FFF
wire dn_gfx_p1 = dn_gfx1 & (dn_addr[12] == 1'b1);   // $11000-$11FFF

// SCROLL-FINE-Y-2026-08-03: was `tile_line`; now the fine-scrolled line so the
// BG samples the right pixel row within the tile (see bg_row / bg_line below).
// Original: wire [11:0] bg_pixel_addr = {bg_tile_code[8:0], tile_line};
wire [11:0] bg_pixel_addr = {bg_tile_code[8:0], bg_line};
wire [7:0] bg_p0_dout, bg_p1_dout;

dpram #(.address_width(12)) gfx_p0(
    .clock_a  (clk_sys),
    .enable_a (1'b1),
    .wren_a   (dn_wr & dn_gfx_p0),
    .address_a(dn_addr[11:0]),
    .data_a   (dn_data),
    .q_a      (),
    .clock_b  (clk_master),
    .enable_b (1'b1),
    .wren_b   (1'b0),
    .address_b(bg_pixel_addr),
    .data_b   (8'd0),
    .q_b      (bg_p0_dout)
);

dpram #(.address_width(12)) gfx_p1(
    .clock_a  (clk_sys),
    .enable_a (1'b1),
    .wren_a   (dn_wr & dn_gfx_p1),
    .address_a(dn_addr[11:0]),
    .data_a   (dn_data),
    .q_a      (),
    .clock_b  (clk_master),
    .enable_b (1'b1),
    .wren_b   (1'b0),
    .address_b(bg_pixel_addr),
    .data_b   (8'd0),
    .q_b      (bg_p1_dout)
);

// ---------------------------------------------------------------------------
// Color PROMs - 64 bytes (2x 32-byte PROMs)
// ---------------------------------------------------------------------------
wire [7:0] prom_dout;
wire [5:0] prom_addr;

dpram #(.address_width(6)) color_proms(
    .clock_a  (clk_sys),
    .enable_a (1'b1),
    .wren_a   (dn_wr & dn_proms),
    .address_a(dn_addr[5:0]),
    .data_a   (dn_data),
    .q_a      (),

    .clock_b  (clk_master),
    .enable_b (1'b1),
    .wren_b   (1'b0),
    .address_b(prom_addr),
    .data_b   (8'd0),
    .q_b      (prom_dout)
);

// ============================================================
// MC6845 CRTC
// ============================================================

wire crtc_cs;
assign crtc_cs =
    (game_id == GID_FANTASY || game_id == GID_NIBBLER) ? (cpu_addr[15:1] == 15'h1000) : // $2000-$2001
    (game_id == GID_PBALLOON) ? (cpu_addr[15:1] == 15'h5800) :                          // $B000-$B001
    (cpu_addr[15:1] == 15'h1800);                                                       // $3000-$3001 (default)

wire crtc_wr = crtc_cs & ~cpu_rw_n;

wire        crtc_hsync;
wire        crtc_vsync;
wire        crtc_hblank;
wire        crtc_vblank;
wire        crtc_de;
wire [13:0] crtc_ma;
wire [4:0]  crtc_ra;
wire [7:0]  crtc_dout;

mc6845 crtc(
    .CLOCK  (clk_master),
    .CLKEN  (crtc_clken),
    .nRESET (~cpu_reset),

    .ENABLE (crtc_cs & cpu_clken),
    .R_nW   (cpu_rw_n),
    .RS     (cpu_addr[0]),
    .DI     (cpu_dout),
    .DO     (crtc_dout),

    .VSYNC  (crtc_vsync),
    .HSYNC  (crtc_hsync),
    .VBLANK (crtc_vblank),
    .HBLANK (crtc_hblank),
    .DE     (crtc_de),
    .CURSOR (),
    .LPSTB  (1'b0),

    .MA     (crtc_ma),
    .RA     (crtc_ra)
);

// SASUKE-MA-OFFSET-2026-08-04: satansat-family one-character display offset.
//
// MEASURED (MAME debugger, user, 2026-08-04): Sasuke and Satan of Saturn program
// an IDENTICAL 6845 register table to Vanguard except for ONE register pair -
// the start address R12/R13. Vanguard = $03FF, satansat family = $0000. Every
// geometry register (R0 h-total 45, R1 32 displayed, R6 28 rows, R9 8 lines/row)
// matches exactly.
//
// Our fetch runs one character AHEAD of the displayed pixel, so the character at
// the screen origin is VRAM[start + 1]:
//   Vanguard  start $03FF (= -1 mod 1024) -> VRAM[0] at origin. Cancels exactly.
//                                            HW-confirmed correct 2026-08-03.
//   Sasuke    start $0000                 -> VRAM[1] at origin. Picture lands one
//                                            character early, so the top tile row
//                                            is pushed off the top edge (ROT90:
//                                            native X is the screen's vertical).
// HW symptom (user, 2026-08-04): "top of the screen is missing an entire tile row
// worth of data", content SHIFTED with no dead band - a fetch-address signature,
// not an envelope one. Both games in the family show it identically.
//
// MAME cannot arbitrate this: it ignores R12/R13 entirely and renders the tilemap
// from its own scan (TILEMAP_SCAN_ROWS, tile_index 0 at the origin, no scrolldx),
// so the whole question is invisible there. Vanguard's $03FF is the real-hardware
// idiom of programming -1 to cancel a 1-character fetch pipeline; the earlier
// satansat board evidently doesn't need it, and our shared pipeline does.
//
// Subtracting 1 from MA for this family makes it fetch EXACTLY as if it had
// programmed $03FF like Vanguard - i.e. it reuses the path already proven correct
// on hardware rather than introducing a new tuned constant. Applied once at the
// source so the FG (tile_addr) and BG (bg_col/bg_row) planes stay in lockstep;
// the BG's separate `+1` further down is the SCROLL-FINE-X lookahead and is
// deliberately untouched.
wire        ma_needs_start_adj = (game_id <= GID_SATANSAT);
wire [9:0]  crtc_ma_disp = crtc_ma[9:0] - {9'd0, ma_needs_start_adj};

// Original: wire [4:0] tile_col  = crtc_ma[4:0];
// Original: wire [4:0] tile_row  = crtc_ma[9:5];
// Original: wire [9:0] tile_addr = crtc_ma[9:0];
wire [4:0] tile_col  = crtc_ma_disp[4:0];
wire [4:0] tile_row  = crtc_ma_disp[9:5];
wire [2:0] tile_line = crtc_ra[2:0];
wire [9:0] tile_addr = crtc_ma_disp;

// BG layer: apply scroll registers
//
// SCROLL-FINE-Y-2026-08-03: the scroll registers are 8-bit PIXEL values, but
// only bits [7:3] (the tile index) were used - the low 3 bits, the fine pixel
// offset inside the tile, were discarded. That makes the BG layer move in whole
// 8-pixel tile steps: correct position, but it HOPS instead of gliding (user
// report: the Vanguard intro logo scroll). MAME applies the full 8-bit value
// (snk6502_v.cpp:139 set_scrolly(0, data)), so [7:3]-only is wrong vs reference.
//
// Fix for the Y axis: add the fine offset to the line-within-tile, and carry
// into the tile row when it wraps past 7. Vanguard writes $3300 (scroll_y)
// 2967 times vs 199 for $3200 in the MAME trace, so this is the axis that
// actually carries the scrolling.
//
// NOTE: the X axis is still coarse-only. Fixing it needs the pixel shift
// register (bg_p0_latch/bg_p1_latch, ~line 664) restructured to span two tiles
// so a sub-tile start bit can be selected - a real change to the render
// pipeline, deliberately NOT bundled in with this one.
//
// Original: wire [4:0] bg_row = tile_row + scroll_y[7:3];
//
// SCROLL-FINE-X-2026-08-03: the X axis now fetches one tile AHEAD (+1). A fine
// offset f = scroll_x[2:0] needs pixels [f..f+7] of the byte stream, which
// straddles tile T and tile T+1 - i.e. it needs LOOKAHEAD. Fetching at +1 means
// that at display-character time T the newly latched gfx byte is byte T+1, while
// the previous latch still holds byte T; the pixel stage below assembles those
// into a 16-bit window and taps it at bit (15 - f). The +1 wraps mod 32, which is
// correct tilemap wrapping. See the pixel-pipeline block for the rest.
// Original: wire [4:0] bg_col = tile_col + scroll_x[7:3];
wire [4:0] bg_col = tile_col + scroll_x[7:3] + 5'd1;

wire [3:0] bg_line_sum   = {1'b0, tile_line} + {1'b0, scroll_y[2:0]};
wire [2:0] bg_line       = bg_line_sum[2:0];
wire       bg_line_carry = bg_line_sum[3];
wire [4:0] bg_row = tile_row + scroll_y[7:3] + {4'd0, bg_line_carry};

wire [9:0] bg_tile_addr = {bg_row, bg_col};

assign vram2_vid_addr    = tile_addr;
assign vram1_vid_addr    = bg_tile_addr;
assign colorram_fg_vid_addr = tile_addr;
assign colorram_bg_vid_addr = bg_tile_addr;

// ============================================================
// I/O Write Decode
// ============================================================

// Common I/O write signals
wire io_wr = ~cpu_rw_n & cpu_clken;  // CPU is writing

// --- Vanguard I/O writes ($3xxx) ---
wire vg_sound_wr   = io_wr & (cpu_addr[15:8] == 8'h31) & (cpu_addr[1:0] != 2'b11);  // $3100-$3102
wire vg_flip_wr    = io_wr & (cpu_addr[15:0] == 16'h3103);
wire vg_scrollx_wr = io_wr & (cpu_addr[15:8] == 8'h32);  // $3200
wire vg_scrolly_wr = io_wr & (cpu_addr[15:8] == 8'h33);  // $3300
// SPEECH-ADDR-DECODE-2026-08-23: was the whole $34xx page (cpu_addr[15:8] ==
// 8'h34). MAME maps speech_w at $3400 EXACTLY (snk6502.cpp vanguard_map:409);
// a stray write anywhere else in the page would feed a spurious nibble into
// the HD38880 command FSM and desync it. Same tightening for Fantasy's $2400.
// Original: wire vg_speech_wr  = io_wr & (cpu_addr[15:8] == 8'h34);
wire vg_speech_wr  = io_wr & (cpu_addr[15:0] == 16'h3400);  // $3400 exact

// --- Fantasy I/O writes ($2xxx) ---
wire fy_sound_wr   = io_wr & (cpu_addr[15:8] == 8'h21) & (cpu_addr[1:0] != 2'b11);
wire fy_flip_wr    = io_wr & (cpu_addr[15:0] == 16'h2103);
wire fy_scrollx_wr = io_wr & (cpu_addr[15:8] == 8'h22);
wire fy_scrolly_wr = io_wr & (cpu_addr[15:8] == 8'h23);
// SPEECH-ADDR-DECODE-2026-08-23: exact address (see vg_speech_wr above).
// Original: wire fy_speech_wr  = io_wr & (cpu_addr[15:8] == 8'h24);
wire fy_speech_wr  = io_wr & (cpu_addr[15:0] == 16'h2400);

// --- PBalloon I/O writes ($Bxxx) ---
wire pb_sound_wr   = io_wr & (cpu_addr[15:8] == 8'hB1) & (cpu_addr[1:0] != 2'b11);
wire pb_flip_wr    = io_wr & (cpu_addr[15:0] == 16'hB103);
wire pb_scrollx_wr = io_wr & (cpu_addr[15:8] == 8'hB2);
wire pb_scrolly_wr = io_wr & (cpu_addr[15:8] == 8'hB3);

// --- Sasuke/SatanSat I/O writes ($Bxxx, different layout) ---
wire ss_sound_wr   = io_wr & (cpu_addr[15:8] == 8'hB0) & (cpu_addr[0] != 1'b1 | cpu_addr[1] != 1'b1);
wire ss_b002_wr    = io_wr & (cpu_addr[15:0] == 16'hB002);
wire ss_bkcolor_wr = io_wr & (cpu_addr[15:0] == 16'hB003);

// Multiplexed write signals based on game_id
wire flip_wr = (game_id == GID_VANGUARD)  ? vg_flip_wr :
               (game_id == GID_FANTASY)   ? fy_flip_wr :
               (game_id == GID_NIBBLER)   ? fy_flip_wr :
               (game_id == GID_PBALLOON)  ? pb_flip_wr :
               1'b0;  // sasuke/satansat handled separately

wire scrollx_wr = (game_id == GID_VANGUARD)  ? vg_scrollx_wr :
                  (game_id == GID_FANTASY)   ? fy_scrollx_wr :
                  (game_id == GID_NIBBLER)   ? fy_scrollx_wr :
                  (game_id == GID_PBALLOON)  ? pb_scrollx_wr :
                  1'b0;

wire scrolly_wr = (game_id == GID_VANGUARD)  ? vg_scrolly_wr :
                  (game_id == GID_FANTASY)   ? fy_scrolly_wr :
                  (game_id == GID_NIBBLER)   ? fy_scrolly_wr :
                  (game_id == GID_PBALLOON)  ? pb_scrolly_wr :
                  1'b0;

// HD38880 speech chip host port (Vanguard $3400 / Fantasy $2400 only —
// Nibbler shares Fantasy's I/O map but has no speech hardware, so it's
// excluded here even though fy_speech_wr's address decode would otherwise fire).
wire speech_wr = (game_id == GID_VANGUARD) ? vg_speech_wr :
                  (game_id == GID_FANTASY)  ? fy_speech_wr :
                  1'b0;
wire speech_game_is_fantasy = (game_id == GID_FANTASY);

// ---------------------------------------------------------------------------
// VBlank IRQ generation
// ---------------------------------------------------------------------------
reg irq_mask;   // only meaningful for sasuke/satansat

reg vblank_prev;
always @(posedge clk_master or posedge reset)
    if (reset)
        vblank_prev <= 1'b0;
    else
        vblank_prev <= crtc_vblank;

wire vblank_rising = crtc_vblank & ~vblank_prev;

// Mirror MAME's HOLD_LINE: assert on vblank rising edge,
// auto-clear when CPU starts fetching the IRQ vector ($FFFE).
wire irq_vector_fetch = (cpu_addr == 16'hFFFE) & cpu_rw_n & cpu_clken;

reg cpu_irq;
always @(posedge clk_master or posedge reset)
    if (reset)
        cpu_irq <= 1'b0;
    else if (vblank_rising)
        cpu_irq <= (~is_slow_cpu || irq_mask) ? 1'b1 : 1'b0;
    else if (irq_vector_fetch)
        cpu_irq <= 1'b0;

wire cpu_irq_n = ~cpu_irq;

// ============================================================
// Video Control Registers
// ============================================================
reg [2:0] backcolor;
reg       charbank;
reg       flip;
reg [7:0] scroll_x;
reg [7:0] scroll_y;

always @(posedge clk_master or posedge reset)
    if (reset) begin
        backcolor <= 3'd0;
        charbank  <= 1'b0;
        flip      <= 1'b0;
        scroll_x  <= 8'd0;
        scroll_y  <= 8'd0;
        irq_mask  <= 1'b0;
    end else begin
        // flipscreen_w (vanguard/fantasy/pballoon/nibbler)
        // bit 7 = flip screen, bit 3 = charbank (inverted), bits 2:0 = backcolor
        if (flip_wr) begin
            flip      <= cpu_dout[7];
//            charbank  <= ~cpu_dout[3];
            charbank  <= (game_id == GID_VANGUARD) ? 1'b0 : ~cpu_dout[3];
            backcolor <= cpu_dout[2:0];
        end

        // satansat_b002_w (sasuke/satansat only)
        // bit 0 = flip, bit 1 = irq_mask
        if (ss_b002_wr) begin
            flip     <= cpu_dout[0];
            irq_mask <= cpu_dout[1];
        end

        // satansat_backcolor_w (sasuke/satansat only)
        // bits 1:0 = backcolor
        if (ss_bkcolor_wr) begin
            backcolor <= {1'b0, cpu_dout[1:0]};
        end

        // Scroll registers
        if (scrollx_wr) scroll_x <= cpu_dout;
        if (scrolly_wr) scroll_y <= cpu_dout;
    end

assign flip_screen = flip;

// ============================================================
// I/O Read Decode
// ============================================================

wire in0_cs, in1_cs, dsw_cs, in2_cs;

assign in0_cs =
    (game_id <= GID_SATANSAT)  ? (cpu_addr == 16'hB004) :
    (game_id == GID_VANGUARD)  ? (cpu_addr == 16'h3104) :
    (game_id == GID_PBALLOON)  ? (cpu_addr == 16'hB104) :
    (cpu_addr == 16'h2104);  // fantasy/nibbler

assign in1_cs =
    (game_id <= GID_SATANSAT)  ? (cpu_addr == 16'hB005) :
    (game_id == GID_VANGUARD)  ? (cpu_addr == 16'h3105) :
    (game_id == GID_PBALLOON)  ? (cpu_addr == 16'hB105) :
    (cpu_addr == 16'h2105);

assign dsw_cs =
    (game_id <= GID_SATANSAT)  ? (cpu_addr == 16'hB006) :
    (game_id == GID_VANGUARD)  ? (cpu_addr == 16'h3106) :
    (game_id == GID_PBALLOON)  ? (cpu_addr == 16'hB106) :
    (cpu_addr == 16'h2106);

assign in2_cs =
    (game_id <= GID_SATANSAT)  ? (cpu_addr == 16'hB007) :
    (game_id == GID_VANGUARD)  ? (cpu_addr == 16'h3107) :
    (game_id == GID_PBALLOON)  ? (cpu_addr == 16'hB107) :
    (cpu_addr == 16'h2107);

// ============================================================
// Pixel Rendering Pipeline - locked to CRTC character clock
// ============================================================

// pix_cnt counts 0-7 pixels within each character, reset on crtc_clken
reg [2:0] pix_cnt;
always @(posedge clk_master or posedge reset)
    if (reset)
        pix_cnt <= 3'd0;
    else if (crtc_clken)
        pix_cnt <= 3'd0;
    else
        pix_cnt <= pix_cnt + 3'd1;

// ce_pix: one pulse per pixel = master clock / 2
// CE-PIX-8PX-2026-08-03: the `&& (clk_div != 4'd15)` term DROPPED ONE PIXEL FROM
// EVERY CHARACTER. clk_div free-runs 0..15 (16 master clocks per character), so
// clk_div[0] alone gives the 8 pixel slots {1,3,5,7,9,11,13,15}. Excluding slot 15
// left only 7 -> 224 of 256 pixels per line.
//
// The exclusion was presumably to avoid colliding with crtc_clken (= clk_div==15),
// but that collision is harmless: the pixel shift-register block is
// `if (crtc_clken) <load> else if (ce_pix) <shift>`, so at slot 15 the load wins and
// no shift happens -- while the pixel value sampled at that instant is still the
// PRE-load register content, i.e. exactly pixel 7. Excluding it simply discards it.
//
// **Under ROT90 the native raster's X axis is screen Y**, so losing the last pixel
// of each character = losing the BOTTOM ROW of every tile on screen. That is the
// user's "squares are missing their bottom lines" / compressed HUD rows, and it
// affected BOTH layers because it is in the common pixel clock.
//
// MEASURED in verilator/ (snk6502_video_sim.v + mc6845_sim.v, real Vanguard CRTC
// register values R0=0x2C R1=0x20 ... R9=0x07):
//   before: 50176 visible px, 224 px/line, 32 chars -> 7 px per char
//   after : 57344 visible px (== 256*224 expected), 256 px/line -> 8 px per char
//
// NOTE: this changes the pixel count per character from 7 to 8, so ENVELOPE_DELAY
// (documented as "the depth of the pixel path in ce_pix cycles") may need a small
// retune; adjust +/-1 if the image sits a pixel off after this lands.
// Original: assign ce_pix = (clk_div[0] == 1'b1) && (clk_div != 4'd15);
assign ce_pix = (clk_div[0] == 1'b1);

wire [8:0] bg_tile_code = {charbank, vram1_vid_dout};

wire [2:0] bg_color = (game_id <= GID_SATANSAT) ?
    {1'b0, colorram_bg_vid_dout[3:2]} :
    (colorram_bg_vid_dout[5:3]);

wire [7:0] fg_tile_code = vram2_vid_dout;
wire [2:0] fg_color = (game_id <= GID_SATANSAT) ?
    {1'b0, colorram_fg_vid_dout[1:0]} :
    (colorram_fg_vid_dout[2:0]);

// SCROLL-FINE-X-2026-08-03: BG is now a 16-bit two-tile window plus a one-character
// history register; FG keeps the original 8-bit shift latches.
// Original: reg [7:0] bg_p0_latch, bg_p1_latch;
reg [7:0]  bg_p0_prev, bg_p1_prev;
reg [15:0] bg_p0_win,  bg_p1_win;
reg [2:0]  bg_color_prev;
reg [7:0] fg_p0_latch, fg_p1_latch;
reg [2:0] bg_color_latch, fg_color_latch;

reg charram_plane_sel; // unused, kept for compatibility
always @(posedge clk_master or posedge reset)
    if (reset) charram_plane_sel <= 1'b0;
    else if (crtc_clken) charram_plane_sel <= ~charram_plane_sel;

// FG pixel data latched directly from both planes simultaneously
wire [7:0] fg_p0_raw = charram_p0_dout;
wire [7:0] fg_p1_raw = charram_p1_dout;

// Latch tile data one clock after crtc_clken (dpram needs 1 cycle to respond to new MA)
reg crtc_clken_d;
always @(posedge clk_master) crtc_clken_d <= crtc_clken;

// SCROLL-FINE-X-2026-08-03: BG pixel stage rebuilt as a 16-bit two-tile window.
// FG is UNCHANGED (it does not scroll).
//
//   bg_*_prev  holds byte T   (latched one character time ago)
//   bg_*_dout  holds byte T+1 (because bg_col fetches at +1, see above)
//   bg_*_win   = {byte T, byte T+1}, shifted left one bit per ce_pix
//   output tap = bit (15 - f), f = scroll_x[2:0]
//
// After k shifts the tap exposes original bit (15-f-k), so a character time emits
// bits 15-f .. 8-f of the window - exactly pixels [f..f+7] of the stream.
//
// SAFETY PROPERTY: at f=0 the tap is bit 15 = bg_*_prev[7], and after k shifts it
// is bg_*_prev[7-k] - bit-identical to the old bg_*_latch[7] behaviour. The colour
// is likewise delayed one character (bg_color_prev) so it still belongs to tile T.
// So f=0 reproduces the previous design exactly; only nonzero fine bits change
// anything, and MAME applies the full 8-bit scroll value the same way.
//
// Original block:
// always @(posedge clk_master) begin
//     if (crtc_clken) begin
//         bg_p0_latch    <= bg_p0_dout;
//         bg_p1_latch    <= bg_p1_dout;
//         fg_p0_latch    <= fg_p0_raw;
//         fg_p1_latch    <= fg_p1_raw;
//         bg_color_latch <= bg_color;
//         fg_color_latch <= fg_color;
//     end else if (ce_pix) begin
//         bg_p0_latch <= {bg_p0_latch[6:0], 1'b0};
//         bg_p1_latch <= {bg_p1_latch[6:0], 1'b0};
//         fg_p0_latch <= {fg_p0_latch[6:0], 1'b0};
//         fg_p1_latch <= {fg_p1_latch[6:0], 1'b0};
//     end
// end
always @(posedge clk_master) begin
    if (crtc_clken) begin
        bg_p0_win      <= {bg_p0_prev, bg_p0_dout};
        bg_p1_win      <= {bg_p1_prev, bg_p1_dout};
        bg_p0_prev     <= bg_p0_dout;
        bg_p1_prev     <= bg_p1_dout;
        bg_color_latch <= bg_color_prev;   // colour of tile T, matching window[15:8]
        bg_color_prev  <= bg_color;
        fg_p0_latch    <= fg_p0_raw;
        fg_p1_latch    <= fg_p1_raw;
        fg_color_latch <= fg_color;
    end else if (ce_pix) begin
        bg_p0_win   <= {bg_p0_win[14:0], 1'b0};
        bg_p1_win   <= {bg_p1_win[14:0], 1'b0};
        fg_p0_latch <= {fg_p0_latch[6:0], 1'b0};
        fg_p1_latch <= {fg_p1_latch[6:0], 1'b0};
    end
end

wire fantasy_nibbler_swap = (game_id == GID_FANTASY) || (game_id == GID_NIBBLER);

// Pioneer Balloon: BG plane swap candidate (uses same hardware family)
wire pballoon_bg_swap = (game_id == GID_PBALLOON);

// Sasuke swaps bitplane order in GFX ROM
wire sasuke_swap = (game_id == GID_SASUKE);
// SCROLL-FINE-X-2026-08-03: tap the two-tile window at (15 - fine offset).
// Index computed into a named wire first - this is a .v file, elaborated as
// Verilog-2001 by Quartus 17.0 (see feedback_verilog2001_expression_bitselect).
// Original: wire [1:0] bg_pixel_raw = {bg_p1_latch[7], bg_p0_latch[7]};
wire [3:0] bg_fine_tap  = 4'd15 - {1'b0, scroll_x[2:0]};
wire       bg_p0_bit    = bg_p0_win[bg_fine_tap];
wire       bg_p1_bit    = bg_p1_win[bg_fine_tap];
wire [1:0] bg_pixel_raw = {bg_p1_bit, bg_p0_bit};
//wire bg_swap = sasuke_swap | fantasy_nibbler_swap | pballoon_bg_swap;
wire bg_swap = sasuke_swap | fantasy_nibbler_swap | pballoon_bg_swap | (game_id == GID_VANGUARD);
wire [1:0] bg_pixel = bg_swap ? {bg_pixel_raw[0], bg_pixel_raw[1]} : bg_pixel_raw;

//wire [1:0] fg_pixel = {fg_p1_latch[7], fg_p0_latch[7]};
wire [1:0] fg_pixel_raw = {fg_p1_latch[7], fg_p0_latch[7]};
// FG-PLANE-SWAP-VANGUARD-2026-08-03: Vanguard's FG pen bits were inverted.
// MAME gfx_vanguard uses charlayout_memory for the FG with planes { 0, 256*8*8 },
// and MAME's FIRST plane entry is the pixel MSB => MSB = charram+0x000 (= our
// charram_p0), LSB = charram+0x800 (= our charram_p1). But fg_pixel_raw is built
// as {p1, p0} = {LSB, MSB} - inverted. The BG has the identical inversion and
// already corrects it via bg_swap (which includes Vanguard); the FG swap only
// covered Fantasy/Nibbler, so Vanguard's FG ran with pen bits 1<->2 swapped,
// indexing the wrong palette entries. FG is the layer holding the HUD, the ships
// and the minimap - exactly the regions the user reports as mis-coloured, and it
// explains the minimap reading as background/line colours exchanged.
// NOTE: Pioneer Balloon may have the same issue (its BG swaps but its FG does
// not) - left alone here because it is untested; check it if its colours look off.
// Original: wire [1:0] fg_pixel = fantasy_nibbler_swap ?
wire fg_plane_swap = fantasy_nibbler_swap | (game_id == GID_VANGUARD);
wire [1:0] fg_pixel = fg_plane_swap ?
    {fg_pixel_raw[0], fg_pixel_raw[1]} :   // swapped planes
    fg_pixel_raw;


wire fg_transparent = (fg_pixel == 2'b00);

wire [1:0] final_pixel = fg_transparent ? bg_pixel : fg_pixel;
wire [2:0] final_color = fg_transparent ? bg_color_latch : fg_color_latch;
wire       final_is_bg = fg_transparent;

// ============================================================
// Palette from PROMs
// ============================================================

wire [4:0] fg_prom_addr = {fg_color_latch, fg_pixel};
wire [4:0] bg_prom_addr_raw = {bg_color_latch, bg_pixel};
wire [4:0] bg_prom_addr = (bg_pixel == 2'b00) ?
    {backcolor, 2'b00} : bg_prom_addr_raw;

// Sasuke/SatanSat palette addressing is different
// FG: prom[4*(pixel) + color] instead of prom[color*4 + pixel]
// BG: same but offset by $10, pixel 0 = backcolor
wire [4:0] ss_fg_prom_addr = {fg_pixel, fg_color_latch[1:0]};
wire [4:0] ss_bg_prom_addr = (bg_pixel == 2'b00) ?
    {3'b100, backcolor[1:0]} :
    {1'b1, bg_pixel, bg_color_latch[1:0]};  // $10 + 4*pixel + color

// Select palette addressing based on game
assign prom_addr = (game_id <= GID_SATANSAT) ?
    (final_is_bg ? {1'b0, ss_bg_prom_addr} : {1'b0, ss_fg_prom_addr}) :
    (final_is_bg ? {1'b1, bg_prom_addr} : {1'b0, fg_prom_addr});

// Raw DE envelope (MA-aligned, coming directly from CRTC)
reg display_active_raw;
always @(posedge clk_master)
    display_active_raw <= crtc_de & ~crtc_hblank & ~crtc_vblank;

// Pipeline delay — align DE envelope with actual pixel output.
// Pixel path: CRTC MA -> dpram (1 cycle) -> shift-reg latch (next crtc_clken) -> ce_pix shift out.
// ENVELOPE_DELAY must match the depth of the pixel path in ce_pix cycles.
// Start at 14; tune +/-1 if top/bottom still off (see diagnostic table).

// Pipe depth sized to max possible delay; per-game tap index picks the actual delay.
localparam integer ENVELOPE_DELAY_MAX = 16;

reg [ENVELOPE_DELAY_MAX-1:0] de_pipe;
reg [ENVELOPE_DELAY_MAX-1:0] hblank_pipe;
reg [ENVELOPE_DELAY_MAX-1:0] hsync_pipe;
reg [ENVELOPE_DELAY_MAX-1:0] vblank_pipe;
reg [ENVELOPE_DELAY_MAX-1:0] vsync_pipe;

// Per-game pipe-tap index (delay in ce_pix cycles = env_idx + 1).
//
// ENVELOPE-RETUNE-2026-08-03: bumped 13 -> 15 as the direct consequence of
// CE-PIX-8PX-2026-08-03. The pixel path is a fixed number of CHARACTERS deep, but
// this delay is counted in ce_pix cycles - and ce_pix went from 7 to 8 pulses per
// character. A ~2-character-deep path was 2*7 = 14 stages, and is now 2*8 = 16,
// i.e. env_idx 13 -> 15.
//
// Confirmed by HW symptom after the ce_pix fix: "2 rows of crap at the top, 2 rows
// missing at the bottom" = the envelope opening 2 ce_pix too early, so real pixel
// data starts 2 late and overruns the close. More delay is the fix, and the
// magnitude (2) matches the predicted 14 -> 16 exactly.
// (ROT90: screen rows are native pixel columns, so "rows" here are ce_pix cycles.)
//
// Original: wire [3:0] env_idx = (game_id == GID_SASUKE) ? 4'd10 : 4'd13;
// NOTE: Sasuke's 10 was tuned under the old 7-px/char timing too and by the same
// scaling wants ~11-12, but Sasuke/SatanSat have never run, so it is left alone
// rather than guessed at. ENVELOPE_DELAY_MAX is 16, so index 15 is the last valid
// tap - if more delay is ever needed, ENVELOPE_DELAY_MAX must grow first.
//
// SASUKE-ENVELOPE-2026-08-04: Sasuke's special case DELETED - it now takes the
// same tap as every other game. Sasuke boots as of the 08-03 MRA vector fix, and
// HW shows misalignment on the ROT90 vertical axis (= the ce_pix axis).
// Justification for one shared value, from source, not from scaling the old 10:
// the pixel path (crtc_clken load -> ce_pix shift latches) contains NO
// game_id-dependent stage. Every game_id use in the pixel path is combinational
// (bg_swap / fg_plane_swap / ss_*_prom_addr). So the pipeline is exactly as deep
// for Sasuke as for Vanguard, where 15 is HW-confirmed correct.
// Original: wire [3:0] env_idx = (game_id == GID_SASUKE) ? 4'd10 : 4'd15;
wire [3:0] env_idx = 4'd15;
//wire [3:0] env_idx = 4'd13;

always @(posedge clk_master) begin
    if (ce_pix) begin
        de_pipe     <= {de_pipe[ENVELOPE_DELAY_MAX-2:0],     display_active_raw};
        hblank_pipe <= {hblank_pipe[ENVELOPE_DELAY_MAX-2:0], crtc_hblank};
        hsync_pipe  <= {hsync_pipe[ENVELOPE_DELAY_MAX-2:0],  crtc_hsync};
        vblank_pipe <= {vblank_pipe[ENVELOPE_DELAY_MAX-2:0], crtc_vblank};
        vsync_pipe  <= {vsync_pipe[ENVELOPE_DELAY_MAX-2:0],  crtc_vsync};
    end
end

wire display_active = de_pipe[env_idx];

// ---------------------------------------------------------------------------
// CPU read data mux
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Video sync/blank outputs from CRTC
// ---------------------------------------------------------------------------
// Sync/blank outputs — delayed to align with pixel pipeline.
// Uses same ENVELOPE_DELAY as display_active above so arcade_video's
// capture window aligns with where pixels actually arrive.
assign hsync  = hsync_pipe[env_idx];
assign vsync  = vsync_pipe[env_idx];
assign hblank = hblank_pipe[env_idx];
assign vblank = vblank_pipe[env_idx];

// ---------------------------------------------------------------------------
// RGB pixel output
// ---------------------------------------------------------------------------
// PALETTE-WEIGHTS-2026-08-03: was bit-replication, which is NOT what the board
// does. MAME snk6502_v.cpp:26 (snk6502_palette; satansat_palette:189 is
// identical, so one formula covers all six games) uses resistor weights
// 0x21 / 0x47 / 0x97 per bit:
//     r = 0x21*bit0 + 0x47*bit1 + 0x97*bit2      (prom bits 2:0)
//     g = 0x21*bit3 + 0x47*bit4 + 0x97*bit5      (prom bits 5:3)
//     b =            0x47*bit6 + 0x97*bit7       (prom bits 7:6)  <-- only TWO resistors
//
// The BLUE channel has no 0x21 leg, so blue maxes at 0x47+0x97 = 222, NOT 255.
// Bit-replication gave blue 0/85/170/255 - systematically ~15% too bright -
// which is why our cyan terrain measured (0,255,255) where MAME has (0,255,222).
// Red/green replication happened to land within a few LSB, so this mostly shows
// up as a blue/cyan hue shift across terrain, minimap and sprites alike.
// Verified against screenshots: MAME's brightest blue really is 222.
// Original:
//   assign rgb_r = display_active ? {prom_dout[2:0], prom_dout[2:0], prom_dout[1:0]} : 8'd0;
//   assign rgb_g = display_active ? {prom_dout[5:3], prom_dout[5:3], prom_dout[4:3]} : 8'd0;
//   assign rgb_b = display_active ? {prom_dout[7:6], prom_dout[7:6], prom_dout[7:6], prom_dout[7:6]} : 8'd0;
wire [7:0] pal_r = (prom_dout[0] ? 8'h21 : 8'h00)
                 + (prom_dout[1] ? 8'h47 : 8'h00)
                 + (prom_dout[2] ? 8'h97 : 8'h00);
wire [7:0] pal_g = (prom_dout[3] ? 8'h21 : 8'h00)
                 + (prom_dout[4] ? 8'h47 : 8'h00)
                 + (prom_dout[5] ? 8'h97 : 8'h00);
wire [7:0] pal_b = (prom_dout[6] ? 8'h47 : 8'h00)
                 + (prom_dout[7] ? 8'h97 : 8'h00);

assign rgb_r = display_active ? pal_r : 8'd0;
assign rgb_g = display_active ? pal_g : 8'd0;
assign rgb_b = display_active ? pal_b : 8'd0;

// NMI on coin insertion - edge triggered one-shot
//
// Matches MAME's PORT_IMPULSE(1) + coin_inserted() semantics: NMI is asserted
// on the FALLING edge of the coin bit (i.e., when the user releases the coin
// button, or when MAME's 1-frame impulse expires). Firing on the rising edge
// (press) leaves the bit still high inside the NMI handler, which Nibbler's
// handler treats as "spurious — bail out without crediting."
reg coin_prev;
reg cpu_nmi;
always @(posedge clk_master or posedge reset)
    if (reset) begin
        coin_prev <= 1'b0;
        cpu_nmi   <= 1'b0;
    end else begin
        coin_prev <= in2[1] | in2[0];
        // pulse NMI for one cpu_clken on FALLING edge of coin
        if (~(in2[1] | in2[0]) & coin_prev)
            cpu_nmi <= 1'b1;
        else if (cpu_clken)
            cpu_nmi <= 1'b0;
    end
assign cpu_nmi_n = ~cpu_nmi;

// ---------------------------------------------------------------------------
// Sound ROM - 6KB at $12040 in download space, addressed as 0x000-0x17FF
// ---------------------------------------------------------------------------
wire [12:0] snd_rom_addr;
wire [7:0]  snd_rom_dout;

dpram #(.address_width(13)) sound_rom(
    .clock_a  (clk_sys),
    .enable_a (1'b1),
    .wren_a   (dn_wr & dn_sndrom),
    .address_a(dn_addr[12:0] - 13'h040),
    .data_a   (dn_data),
    .q_a      (),

    .clock_b  (clk_master),
    .enable_b (1'b1),
    .wren_b   (1'b0),
    .address_b(snd_rom_addr),
    .data_b   (8'd0),
    .q_b      (snd_rom_dout)
);

// ---------------------------------------------------------------------------
// Speech ROM (HD38880 PARCOR data) - 6KB at $14000 in download space,
// Vanguard (sk6_ic07/08/11.bin) or Fantasy (fs_d_7/e_8/f_11.bin) depending
// on which MRA is loaded. Addressed 0x000-0x17FF (game address $4000 base
// subtracted by hd38880_top).
// ---------------------------------------------------------------------------
wire [12:0] speech_rom_addr;
wire [7:0]  speech_rom_dout;

dpram #(.address_width(13)) speech_rom(
    .clock_a  (clk_sys),
    .enable_a (1'b1),
    .wren_a   (dn_wr & dn_speech),
    .address_a(dn_addr[12:0]),
    .data_a   (dn_data),
    .q_a      (),

    .clock_b  (clk_master),
    .enable_b (1'b1),
    .wren_b   (1'b0),
    .address_b(speech_rom_addr),
    .data_b   (8'd0),
    .q_b      (speech_rom_dout)
);

// ---------------------------------------------------------------------------
// HD38880 speech synthesizer (Vanguard / Fantasy)
// ---------------------------------------------------------------------------
wire signed [14:0] speech_audio;

hd38880_top #(.CLK_HZ(11_289_000)) speech (
    .clk             (clk_master),
    .reset           (reset),
    .pause           (pause),
    .host_wr         (speech_wr),
    .host_din        (cpu_dout[5:0]),
    .game_is_fantasy (speech_game_is_fantasy),
    .rom_addr        (speech_rom_addr),
    .rom_data        (speech_rom_dout),
    .audio_out       (speech_audio)
);

// ---------------------------------------------------------------------------
// Sound port write strobes — game-aware (per MAME memory maps)
//   Fantasy/Nibbler:  $2100-$2103  (port 3 also written by fantasy_flipscreen_w)
//   Vanguard:         $3100-$3102  (no port 3; $3103 is flipscreen only)
//   Pioneer Balloon:  $B100-$B102  (no port 3; $B103 is flipscreen only)
// Address ranges don't overlap, so a simple OR decode works without game_id.
// ---------------------------------------------------------------------------
wire snd_wr0 = io_wr & ((cpu_addr == 16'h2100) |
                        (cpu_addr == 16'h3100) |
                        (cpu_addr == 16'hB100));
wire snd_wr1 = io_wr & ((cpu_addr == 16'h2101) |
                        (cpu_addr == 16'h3101) |
                        (cpu_addr == 16'hB101));
wire snd_wr2 = io_wr & ((cpu_addr == 16'h2102) |
                        (cpu_addr == 16'h3102) |
                        (cpu_addr == 16'hB102));
wire snd_wr3 = io_wr &  (cpu_addr == 16'h2103);  // Fantasy/Nibbler only

// SASUKE-SATANSAT-SOUND-2026-08-03: Sasuke/SatanSat put their sound port at
// $B000/$B001 (MAME sasuke_map:347 / satansat_map:367), which was NOT DECODED
// ANYWHERE - so no sound command from either game ever reached snk6502_snd.
// Gated on game_id <= GID_SATANSAT so it cannot clash with Pioneer Balloon, whose
// CRTC lives at those same addresses.
wire ss_snd_wr0 = io_wr & (game_id <= GID_SATANSAT) & (cpu_addr == 16'hB000);
wire ss_snd_wr1 = io_wr & (game_id <= GID_SATANSAT) & (cpu_addr == 16'hB001);

// ---------------------------------------------------------------------------
// SNK6502 tone generator
// ---------------------------------------------------------------------------
wire [15:0] snd_audio;

snk6502_snd sound(
    .clk           (clk_master),
    .reset         (reset),
    .pause         (pause),
    .sound_port0   (cpu_dout),
    .sound_port1   (cpu_dout),
    .sound_port2   (cpu_dout),
    .sound_port3   (cpu_dout),
    .wr0           (snd_wr0),
    .wr1           (snd_wr1),
    .wr2           (snd_wr2),
    .wr3           (snd_wr3),
    // VANGUARD-SOUND-2026-08-03: selects MAME's vanguard_sound_device semantics
    // instead of fantasy_sound_device's. See Claude/vanguard_audio_audit_2026-08-03.md
    .game_is_vanguard (game_id == GID_VANGUARD),
    .game_is_sasuke   (game_id == GID_SASUKE),
    .game_is_satansat (game_id == GID_SATANSAT),
    .ss_wr0           (ss_snd_wr0),
    .ss_wr1           (ss_snd_wr1),
    .snd_rom_data  (snd_rom_dout),
    .snd_rom_addr  (snd_rom_addr),
    .audio_out     (snd_audio),
    .music0_playing(music0_playing)
);

reg bomb_enable;
always @(posedge clk_master or posedge reset)
    if (reset)
        bomb_enable <= 0;
    else if (snd_wr0)
        bomb_enable <= cpu_dout[7];

// SN76477-NOISE-2026-08-03: latch the whole of sound port 0 so the SN76477 legs
// can see bits 5/6 as LEVELS (the ENABLE pin is level driven, not edge).
reg [7:0] snd_p0_latch;
always @(posedge clk_master or posedge reset)
    if (reset)        snd_p0_latch <= 8'h00;
    else if (snd_wr0) snd_p0_latch <= cpu_dout;

wire game_vg = (game_id == GID_VANGUARD);
wire game_fy = (game_id == GID_FANTASY);

// MAME vanguard_sound_device::sound_w port 0 (snk6502_a.cpp:577-617):
//   bit 5 SHOT A -> sn76477.1  (was: NOT WIRED TO ANYTHING - silent gun)
//   bit 6 SHOT B -> sn76477.2  (was: NOT WIRED TO ANYTHING)
//   bit 7 BOMB   -> "explsion" sample; left on the existing one-shot below.
// MAME fantasy_sound_device::sound_w port 0 (:762-795):
//   bit 7 BOMB   -> sn76477.1 -> discrete, driven as a LEVEL
//                   (m_discrete->write(FANTASY_BOMB_EN, data & 0x80))
wire shot_a_gate  = game_vg & snd_p0_latch[5];
wire shot_b_gate  = game_vg & snd_p0_latch[6];
wire fy_bomb_gate = game_fy & snd_p0_latch[7];

// Fantasy's bomb now comes from the modelled SN76477 leg instead of the old
// fixed 26ms one-shot, which fired once instead of sustaining while the bit is
// held. Every other game keeps the previous behaviour untouched (Nibbler is
// HW-confirmed good and must not move).
wire bomb_trigger = bomb_enable & ~game_fy;

// ---- SN76477 leg A: 470k noise clock (3081.7 Hz) + 1.5M/220pF filter --------
// Shared by Vanguard SHOT A and Fantasy BOMB: identical component values in
// MAME, and they belong to different games so the gates can never both be high.
wire signed [15:0] sn_lo_audio;
sn76477_noise #(
    .CLK_HZ(11_289_000), .NOISE_HZ(3082), .FILTER_EN(1'b1), .AMPLITUDE(6000)
) sn76477_lo (
    .clk(clk_master), .reset(reset), .pause(pause),
    .gate(shot_a_gate | fy_bomb_gate),
    .audio_out(sn_lo_audio)
);

// ---- SN76477 leg B: 10k noise clock (97493 Hz), NO filter cap (C=0) ---------
// Vanguard SHOT B only. MAME routes this at 0.25 vs SHOT A's 0.50, hence half
// the amplitude.
wire signed [15:0] sn_hi_audio;
sn76477_noise #(
    .CLK_HZ(11_289_000), .NOISE_HZ(97493), .FILTER_EN(1'b0), .AMPLITUDE(3000)
) sn76477_hi (
    .clk(clk_master), .reset(reset), .pause(pause),
    .gate(shot_b_gate),
    .audio_out(sn_hi_audio)
);

wire signed [15:0] noise_audio;

snk6502_noise noise_gen(
    .clk      (clk_master),
    .reset    (reset),
    .pause    (pause),
    .trigger  (bomb_trigger),
    .audio_out(noise_audio)
);

// Saturating signed mix (tone + noise + speech).
//
// SPEECH-GAIN-2026-08-03: the original `>>> 6` was a guess inherited from a
// DIFFERENT chip's mixing note, and it is wrong by ~40 dB in the wrong
// direction. parcor_lattice's audio_out is signed 15-bit (+-16384) while
// snd_audio and noise_audio are both signed 16-bit (+-32768), so speech was
// already the QUIETER channel before any shift; >>>6 then divided it by a
// further 64. Verilator bench (verilator/, real $3400 stimulus reconstructed
// from vanguard_maincpu-4000.dasm) measured a phrase peak of 4233/16384 raw,
// which >>>6 turned into 66 out of 32768 output full scale = -54 dB. The whole
// chain was working; the mix made it inaudible.
//
// A straight level-match of 15-bit onto 16-bit is <<1 (full scale maps to full
// scale exactly, no clipping possible beyond the existing saturation). The
// measured phrase peak becomes 8466 = ~26% of output full scale, with headroom
// for hotter phrases. TUNABLE: drop the <<<1 to a plain assign if too loud.
// Original: wire signed [14:0] speech_audio_scaled = speech_audio >>> 6;
// Explicit sign-extension 15 -> 16 (not relying on implicit signed widening):
// if this ever zero-extended, negative samples would become large positives.
wire signed [15:0] speech_audio_ext    = {speech_audio[14], speech_audio};
wire signed [15:0] speech_audio_scaled = speech_audio_ext <<< 1;
// SN76477-NOISE-2026-08-03: two more sources in the sum, so the accumulator is
// widened 18 -> 20 bits. Five signed 16-bit terms peak at 5*32768 = 163840,
// which needs 19 bits signed; 20 gives a bit of headroom. The saturation test
// widens with it.
wire signed [19:0] audio_mix3 = $signed(snd_audio) + $signed(noise_audio)
                              + $signed(speech_audio_scaled)
                              + $signed(sn_lo_audio) + $signed(sn_hi_audio);
wire audio_mix3_ovf = ~(&audio_mix3[19:15] | ~|audio_mix3[19:15]);
assign audio = audio_mix3_ovf ?
               (audio_mix3[19] ? 16'sh8000 : 16'sh7FFF) :
               audio_mix3[15:0];

endmodule