//============================================================================
//  SNK6502 board: Sasuke vs. Commander, Satan of Saturn / Zarzon, Vanguard, Fantasy, Pioneer Balloon, Nibbler
//  (game_id selects the memory map / I/O layout).
//
//  Drives the dispatcher's pools (rtl/snk6502_dispatcher.sv): T65, MC6845, HD38880, two SN76477 noise legs, the ROM
//  blocks and the board RAM pool. Boards never instantiate a CPU, sound chip, ROM store or board RAM.
//============================================================================

module snk6502_board(
    input         clk_master,     // 11.289 MHz master clock
    input         reset,
    input         pause,
    input         crt_flip,       // OSD CRT Flip: 180 degree mirror of the whole raster
    output        ce_pix,

    input  [3:0]  game_id,        // which game variant (see defines below)

    // Player controls, active high: p1 / p2 = {btn4, btn3, btn2, btn1, up, down, left, right}
    input  [7:0]  p1,
    input  [7:0]  p2,
    input  [3:0]  p1_rstick,      // P1 right stick {U, D, L, R}: Vanguard's second set of fire buttons
    input  [3:0]  sys_ctl,        // {start2, start1, coin2, coin1}
    input  [7:0]  dsw,            // DIP switches

    // Video output
    output [7:0]  rgb_r,
    output [7:0]  rgb_g,
    output [7:0]  rgb_b,
    output        hsync,
    output        vsync,
    output        hblank,
    output        vblank,

    output [15:0] audio,
    output        flip_screen,

    // Shared CPU / sound chip pool
    output chip_pool_pkg::t65_i_t           t65_0_i,
    input  chip_pool_pkg::t65_o_t           t65_0_o,
    output chip_pool_pkg::mc6845_i_t        mc6845_0_i,
    input  chip_pool_pkg::mc6845_o_t        mc6845_0_o,
    output chip_pool_pkg::hd38880_i_t       hd38880_0_i,
    input  chip_pool_pkg::hd38880_o_t       hd38880_0_o,
    output chip_pool_pkg::sn76477_noise_i_t sn76477_noise_0_i,
    input  chip_pool_pkg::sn76477_noise_o_t sn76477_noise_0_o,
    output chip_pool_pkg::sn76477_noise_i_t sn76477_noise_1_i,
    input  chip_pool_pkg::sn76477_noise_o_t sn76477_noise_1_o,

    // Shared ROM blocks (read port, one clock to data)
    output [15:0] rom0_a,         // program ROM
    input  [7:0]  rom0_d,
    output [11:0] rom1_a,         // gfx plane 0
    input  [7:0]  rom1_d,
    output [11:0] rom2_a,         // gfx plane 1
    input  [7:0]  rom2_d,
    output [5:0]  rom3_a,         // colour PROMs
    input  [7:0]  rom3_d,
    output [12:0] rom4_a,         // sound ROM
    input  [7:0]  rom4_d,
    output [12:0] rom5_a,         // speech ROM
    input  [7:0]  rom5_d,

    // Shared board RAM pool (ram_pool_pkg): block n = pr_i[n] / pr_o[n], map in the dispatcher
    output ram_pool_pkg::pram_i_t [6:0] pr_i,
    input  ram_pool_pkg::pram_o_t [6:0] pr_o
);

// Game IDs
localparam GID_SASUKE   = 4'd0;
localparam GID_SATANSAT = 4'd1;
localparam GID_VANGUARD = 4'd2;
localparam GID_FANTASY  = 4'd3;
localparam GID_PBALLOON = 4'd4;
localparam GID_NIBBLER  = 4'd5;

// ============================================================
// Player controls -> IN0 / IN1 / IN2 (the board's input wiring)
// ============================================================
wire m_right1  = p1[0], m_left1  = p1[1], m_down1  = p1[2], m_up1  = p1[3];
wire m_btn1_p1 = p1[4], m_btn2_p1 = p1[5], m_btn3_p1 = p1[6], m_btn4_p1 = p1[7];
wire m_right2  = p2[0], m_left2  = p2[1], m_down2  = p2[2], m_up2  = p2[3];
wire m_btn1_p2 = p2[4], m_btn2_p2 = p2[5], m_btn3_p2 = p2[6], m_btn4_p2 = p2[7];
wire r_fire_right = p1_rstick[0], r_fire_left = p1_rstick[1], r_fire_down = p1_rstick[2], r_fire_up = p1_rstick[3];
wire m_coin1   = sys_ctl[0], m_coin2  = sys_ctl[1], m_start1 = sys_ctl[2], m_start2 = sys_ctl[3];
wire music0_playing;   // sound ch0 muted (custom IN bit, read by Vanguard / Sasuke / Satan of Saturn)

// Vanguard fire bits = ABXY OR'd with right analog stick
wire m_fire_right_p1 = m_btn1_p1 | r_fire_right;  // A   or stick right
wire m_fire_down_p1  = m_btn2_p1 | r_fire_down;   // B   or stick down
wire m_fire_up_p1    = m_btn3_p1 | r_fire_up;     // X   or stick up
wire m_fire_left_p1  = m_btn4_p1 | r_fire_left;   // Y   or stick left

wire m_fire_right_p2 = m_btn1_p2;
wire m_fire_down_p2  = m_btn2_p2;
wire m_fire_up_p2    = m_btn3_p2;
wire m_fire_left_p2  = m_btn4_p2;

// ----- Sasuke / SatanSat free-running counter -----
// MAME (snk6502.cpp): 8-bit counter += 0x10 at 1.4 MHz; the game reads counter >> 4.
// Net effect: 4-bit counter at ~1.4 MHz feeding IN2[7:4]. Used by game as RNG.
// clk_master ≈ 11.289 MHz; /8 ≈ 1.411 MHz.
// Counter lives in clk_master domain — IN ports are sampled by CPU also in clk_master,
// so a single-bit transition crossing the assign is benign for an RNG bit.
reg [2:0] sasuke_div   = 3'd0;
reg [3:0] sasuke_count = 4'd0;
always @(posedge clk_master) begin
	sasuke_div <= sasuke_div + 3'd1;
	if (sasuke_div == 3'd7)
		sasuke_count <= sasuke_count + 4'd1;
end

// =========================================================================
// Per-game IN0 / IN1 / IN2 construction (active high — matches MAME)
// Bit ordering reminder: {b7, b6, b5, b4, b3, b2, b1, b0}
// =========================================================================

// --- Sasuke (game_id=0) ---
//  IN0 b7=START2 b6=START1 b5..3=cocktail b2=BTN1 b1=R(2W) b0=L(2W)
//  IN1 b7=music0_playing(NI) b1..0=unused
//  IN2 b7..4=sasuke_count (NI) b3..1=NC b0=COIN1
wire [7:0] in0_sasuke   = {m_start2, m_start1, 3'b000, m_btn1_p1, m_right1, m_left1};
wire [7:0] in1_sasuke   = {music0_playing, 7'b0000000};
wire [7:0] in2_sasuke   = {sasuke_count, 3'b000, m_coin1};

// --- SatanSat / Zarzon (game_id=1) ---
//  IN0 b7=BTN2_cock b6=BTN2 b5..3=cocktail b2=BTN1 b1=R(2W) b0=L(2W)
//  IN1 b7=music0_playing(NI) b6..2=NC b1=START2 b0=START1
//  IN2 b7..4=sasuke_count (NI) b3..1=NC b0=COIN1
wire [7:0] in0_satansat = {1'b0, m_btn2_p1, 3'b000, m_btn1_p1, m_right1, m_left1};
wire [7:0] in1_satansat = {music0_playing, 5'b00000, m_start2, m_start1};
wire [7:0] in2_satansat = {sasuke_count, 3'b000, m_coin1};

// --- Vanguard (game_id=2) ---
//  IN0 b7=L  b6=R  b5=U  b4=D  b3=BTN1(fireL) b2=BTN2(fireR) b1=BTN4(fireU) b0=BTN3(fireD)
//  IN1 same layout for P2 cocktail
//  IN2 b7=START1 b6=START2 b5=NC b4=music0_playing(NI) b3..2=NC b1=COIN1 b0=COIN2
wire [7:0] in0_vanguard = {m_left1, m_right1, m_up1, m_down1,
                           m_fire_left_p1, m_fire_right_p1, m_fire_up_p1, m_fire_down_p1};
wire [7:0] in1_vanguard = {m_left2, m_right2, m_up2, m_down2,
                           m_fire_left_p2, m_fire_right_p2, m_fire_up_p2, m_fire_down_p2};
wire [7:0] in2_vanguard = {m_start1, m_start2, 1'b0, music0_playing, 2'b00, m_coin1, m_coin2};

// --- Fantasy (game_id=3) ---
//  IN0 b7=L b6=R b5=U b4=D (8W); MAME has b3..0=UNKNOWN.
//  Real hw has a fire button — map it to b3 like pballoon (any ABXY OR'd).
//  IN2 same as Vanguard but with b4=NC (no music0 read)
wire [7:0] in0_fantasy  = {m_left1, m_right1, m_up1, m_down1, m_btn1_p1, 3'b000};
wire [7:0] in1_fantasy  = {m_left2, m_right2, m_up2, m_down2, m_btn1_p2, 3'b000};
wire [7:0] in2_fantasy  = {m_start1, m_start2, 4'b0000, m_coin1, m_coin2};

// --- Pioneer Balloon (game_id=4) ---
//  IN0 b7=L b6=R b5=U b4=D b3=BTN1 b2..0=UNKNOWN
//  IN2 same as fantasy
wire [7:0] in0_pballoon = {m_left1, m_right1, m_up1, m_down1, m_btn1_p1, 3'b000};
wire [7:0] in1_pballoon = {m_left2, m_right2, m_up2, m_down2, m_btn1_p2, 3'b000};
wire [7:0] in2_pballoon = {m_start1, m_start2, 4'b0000, m_coin1, m_coin2};

// --- Nibbler (game_id=5) ---
// Real Nibbler cabinet has NO buttons — IN0/IN1 bits 0-3 are unconnected.
// MAME maps debug service inputs (slow-down, pause, end-game) onto those bits
// for testing, but the ROM treats any high level on those bits as debug
// activity. Putting any button there causes weird in-game behaviour
// including disabling normal coin/credit handling.
wire [7:0] in0_nibbler  = {m_left1, m_right1, m_up1, m_down1, 4'b0000};
wire [7:0] in1_nibbler  = {m_left2, m_right2, m_up2, m_down2, 4'b0000};
wire [7:0] in2_nibbler  = {m_start1, m_start2, 4'b0000, m_coin1, m_coin2};

// --- Per-game mux ---
reg [7:0] snk_in0, snk_in1, snk_in2;
always @(*) begin
	case (game_id)
		GID_NIBBLER:  begin snk_in0 = in0_nibbler;  snk_in1 = in1_nibbler;  snk_in2 = in2_nibbler;  end
		GID_FANTASY:  begin snk_in0 = in0_fantasy;  snk_in1 = in1_fantasy;  snk_in2 = in2_fantasy;  end
		GID_PBALLOON: begin snk_in0 = in0_pballoon; snk_in1 = in1_pballoon; snk_in2 = in2_pballoon; end
		GID_VANGUARD: begin snk_in0 = in0_vanguard; snk_in1 = in1_vanguard; snk_in2 = in2_vanguard; end
		GID_SASUKE:   begin snk_in0 = in0_sasuke;   snk_in1 = in1_sasuke;   snk_in2 = in2_sasuke;   end
		GID_SATANSAT: begin snk_in0 = in0_satansat; snk_in1 = in1_satansat; snk_in2 = in2_satansat; end
		default:      begin snk_in0 = in0_nibbler;  snk_in1 = in1_nibbler;  snk_in2 = in2_nibbler;  end
	endcase
end

wire [7:0] in0 = snk_in0;
wire [7:0] in1 = snk_in1;
wire [7:0] in2 = snk_in2;

// Declared ahead of the stages that drive them: the tile / pixel fetch addresses use them first
// (Quartus 17 rejects a use before the declaration).
wire [2:0] fl_line;            // CRT Flip line within the tile
wire [2:0] bg_line;            // fine-scrolled BG line within the tile
wire [7:0] fg_tile_code;
wire [8:0] bg_tile_code;
reg  [7:0] scroll_x;
reg  [7:0] scroll_y;

// I/O region base address varies by game
// Vanguard:        $31xx (reads at $3104-$3107)
// Fantasy:         $21xx
// PBalloon:        $B1xx
// Sasuke/SatanSat: $B0xx (different register layout)

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

// 6502: pooled T65 (t65_0)
assign cpu_addr = t65_0_o.a;
assign cpu_dout = t65_0_o.dout;
assign cpu_rw_n = t65_0_o.rw;

// ---------------------------------------------------------------------------
// Program ROM - 64KB (sparse, loaded by .mra at correct addresses): rom0
// ---------------------------------------------------------------------------
wire [7:0] rom_dout;
assign rom0_a   = cpu_addr;
assign rom_dout = rom0_d;


// ---------------------------------------------------------------------------
// Work RAM - 1KB at $0000-$03FF
// ---------------------------------------------------------------------------
wire ram_cs = (cpu_addr[15:10] == 6'b000000);
wire [7:0] ram_dout;
wire ram_wr = ram_cs & ~cpu_rw_n & cpu_clken;

assign pr_i[0] = '{a_addr: {5'd0, cpu_addr[9:0]}, a_d: cpu_dout, a_we: ram_wr, b_addr: 15'd0, b_d: 8'd0, b_we: 1'b0};
assign ram_dout = pr_o[0].a_q;

// ---------------------------------------------------------------------------
// Video RAM 2 (foreground tilemap) - 1KB at $0400-$07FF
// ---------------------------------------------------------------------------
wire vram2_cs = (cpu_addr[15:10] == 6'b000001);
wire [7:0] vram2_cpu_dout;
wire vram2_wr = vram2_cs & ~cpu_rw_n & cpu_clken;

wire [9:0] vram2_vid_addr;
wire [7:0] vram2_vid_dout;

assign pr_i[1] = '{a_addr: {5'd0, cpu_addr[9:0]}, a_d: cpu_dout, a_we: vram2_wr, b_addr: {5'd0, vram2_vid_addr}, b_d: 8'd0, b_we: 1'b0};
assign vram2_cpu_dout = pr_o[1].a_q;
assign vram2_vid_dout = pr_o[1].b_q;

// ---------------------------------------------------------------------------
// Video RAM 1 (background tilemap) - 1KB at $0800-$0BFF
// ---------------------------------------------------------------------------
wire vram1_cs = (cpu_addr[15:10] == 6'b000010);
wire [7:0] vram1_cpu_dout;
wire vram1_wr = vram1_cs & ~cpu_rw_n & cpu_clken;

wire [9:0] vram1_vid_addr;
wire [7:0] vram1_vid_dout;

assign pr_i[2] = '{a_addr: {5'd0, cpu_addr[9:0]}, a_d: cpu_dout, a_we: vram1_wr, b_addr: {5'd0, vram1_vid_addr}, b_d: 8'd0, b_we: 1'b0};
assign vram1_cpu_dout = pr_o[2].a_q;
assign vram1_vid_dout = pr_o[2].b_q;

// ---------------------------------------------------------------------------
// Color RAM - 1KB at $0C00-$0FFF
// ---------------------------------------------------------------------------
wire colorram_cs = (cpu_addr[15:10] == 6'b000011);
wire [7:0] colorram_cpu_dout;
wire colorram_wr = colorram_cs & ~cpu_rw_n & cpu_clken;

wire [9:0] colorram_fg_vid_addr;  // unscrolled (FG tile)
wire [9:0] colorram_bg_vid_addr;  // scrolled   (BG tile)
wire [7:0] colorram_fg_vid_dout;
wire [7:0] colorram_bg_vid_dout;

// Copy A: CPU port + FG video port (drives CPU readback)
assign pr_i[3] = '{a_addr: {5'd0, cpu_addr[9:0]}, a_d: cpu_dout, a_we: colorram_wr, b_addr: {5'd0, colorram_fg_vid_addr}, b_d: 8'd0, b_we: 1'b0};
assign colorram_cpu_dout    = pr_o[3].a_q;
assign colorram_fg_vid_dout = pr_o[3].b_q;

// Copy B: mirror writes from CPU; video port drives BG color attribute
assign pr_i[4] = '{a_addr: {5'd0, cpu_addr[9:0]}, a_d: cpu_dout, a_we: colorram_wr, b_addr: {5'd0, colorram_bg_vid_addr}, b_d: 8'd0, b_we: 1'b0};
assign colorram_bg_vid_dout = pr_o[4].b_q;

// ---------------------------------------------------------------------------
// Character Generator RAM - 4KB at $1000-$1FFF
// ---------------------------------------------------------------------------
wire charram_cs = (cpu_addr[15:12] == 4'b0001);
// CPU-side readback: separate wire per plane, muxed on cpu_addr[11]
wire [7:0] charram_p0_cpu_dout;
wire [7:0] charram_p1_cpu_dout;
wire [7:0] charram_cpu_dout = cpu_addr[11] ? charram_p1_cpu_dout : charram_p0_cpu_dout;

wire charram_wr = charram_cs & ~cpu_rw_n & cpu_clken;

// Charram split into two 2KB planes for simultaneous video read
// Plane 0 (IC67): $1000-$17FF (addr bit 11 = 0)
// Plane 1 (IC68): $1800-$1FFF (addr bit 11 = 1)
wire [10:0] charram_vid_addr = {fg_tile_code, fl_line};
wire [7:0]  charram_p0_dout, charram_p1_dout;

assign pr_i[5] = '{a_addr: {4'd0, cpu_addr[10:0]}, a_d: cpu_dout, a_we: charram_wr & ~cpu_addr[11], b_addr: {4'd0, charram_vid_addr}, b_d: 8'd0, b_we: 1'b0};
assign charram_p0_cpu_dout = pr_o[5].a_q;
assign charram_p0_dout     = pr_o[5].b_q;

assign pr_i[6] = '{a_addr: {4'd0, cpu_addr[10:0]}, a_d: cpu_dout, a_we: charram_wr & cpu_addr[11], b_addr: {4'd0, charram_vid_addr}, b_d: 8'd0, b_we: 1'b0};
assign charram_p1_cpu_dout = pr_o[6].a_q;
assign charram_p1_dout     = pr_o[6].b_q;

// GFX ROM: rom1 = plane 0, rom2 = plane 1 (the MRA pads plane 0 to 4KB before plane 1 data)

// BG gfx row = the fine-scrolled line within the tile (see bg_row / bg_line below).
wire [11:0] bg_pixel_addr = {bg_tile_code[8:0], bg_line};
wire [7:0] bg_p0_dout, bg_p1_dout;

assign rom1_a = bg_pixel_addr;
assign rom2_a = bg_pixel_addr;
assign bg_p0_dout = rom1_d;
assign bg_p1_dout = rom2_d;


// ---------------------------------------------------------------------------
// Color PROMs - 64 bytes (2x 32-byte PROMs): rom3
// ---------------------------------------------------------------------------
wire [7:0] prom_dout;
wire [5:0] prom_addr;

assign rom3_a    = prom_addr;
assign prom_dout = rom3_d;

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

// pooled MC6845 (mc6845_0)
assign mc6845_0_i  = '{reset_n: ~cpu_reset, clken: crtc_clken, enable: crtc_cs & cpu_clken, r_nw: cpu_rw_n,
                       rs: cpu_addr[0], di: cpu_dout};
assign crtc_dout   = mc6845_0_o.dout;
assign crtc_vsync  = mc6845_0_o.vsync;
assign crtc_hsync  = mc6845_0_o.hsync;
assign crtc_vblank = mc6845_0_o.vblank;
assign crtc_hblank = mc6845_0_o.hblank;
assign crtc_de     = mc6845_0_o.de;
assign crtc_ma     = mc6845_0_o.ma;
assign crtc_ra     = mc6845_0_o.ra;

// satansat-family one-character display offset.
//
// Measured in MAME: Sasuke and Satan of Saturn program
// an IDENTICAL 6845 register table to Vanguard except for ONE register pair -
// the start address R12/R13. Vanguard = $03FF, satansat family = $0000. Every
// geometry register (R0 h-total 45, R1 32 displayed, R6 28 rows, R9 8 lines/row)
// matches exactly.
//
// Our fetch runs one character AHEAD of the displayed pixel, so the character at
// the screen origin is VRAM[start + 1]:
//   Vanguard  start $03FF (= -1 mod 1024) -> VRAM[0] at origin. Cancels exactly (HW-confirmed).
//   Sasuke    start $0000                 -> VRAM[1] at origin. Picture lands one
//                                            character early, so the top tile row
//                                            is pushed off the top edge (ROT90:
//                                            native X is the screen's vertical).
// Uncorrected, the family's top tile row is missing and the content is SHIFTED with no dead band - a fetch-address
// signature, not an envelope one.
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
// the BG's separate `+1` further down is the fine-X-scroll lookahead and is
// deliberately separate.
wire        ma_needs_start_adj = (game_id <= GID_SATANSAT);
wire [9:0]  crtc_ma_disp = crtc_ma[9:0] - {9'd0, ma_needs_start_adj};

wire [4:0] tile_col  = crtc_ma_disp[4:0];
wire [4:0] tile_row  = crtc_ma_disp[9:5];
wire [2:0] tile_line = crtc_ra[2:0];

// OSD CRT Flip mirrors the raster by mirroring what is FETCHED (no frame/line buffer here).
// The visible area is 32 x 28 characters starting one past S, the address of the frame's first DE fetch (the
// fetch runs one character ahead): addresses S+1 .. S+896. A char at address A is replaced by 2S+897-A (row and
// column mirrored together), its line by 7-line, and the pixel shift registers below run the other way.
// S is latched per frame because the games program different start addresses (Pioneer Balloon != Vanguard).
// Every crt_flip term is a no-op at crt_flip = 0.
reg [9:0] fl_s;
reg       fl_s_armed;
always @(posedge clk_master)
    if (crtc_vblank) fl_s_armed <= 1'b1;
    else if (crtc_clken && crtc_de && fl_s_armed) begin
        fl_s       <= crtc_ma_disp;
        fl_s_armed <= 1'b0;
    end
wire [9:0] fl_addr = {fl_s, 1'b0} + 10'd897 - crtc_ma_disp;
wire [4:0] fl_col  = crt_flip ? fl_addr[4:0]        : tile_col;
wire [4:0] fl_row  = crt_flip ? fl_addr[9:5]        : tile_row;
assign     fl_line = crt_flip ? (3'd7  - tile_line) : tile_line;
wire [9:0] tile_addr = {fl_row, fl_col};

// BG layer: the scroll registers are 8-bit PIXEL values (MAME applies the full value).
// Y: the fine offset scroll_y[2:0] is added to the line within the tile, carrying into the tile row past 7.
// X: a fine offset f = scroll_x[2:0] needs pixels [f..f+7] of the byte stream, which straddle tile T and T+1, so X
// fetches one tile AHEAD (+1): at display-character time T the newly latched gfx byte is byte T+1 while the previous
// latch still holds byte T; the pixel stage assembles them into a 16-bit window tapped at bit (15 - f). The +1 wraps
// mod 32 (tilemap wrapping).
// CRT Flip: the scan walks the world DOWNWARD, so the window needs the tile itself (t0) plus the one ABOVE it (t0+1,
// fetched on the previous character) - no +1 lookahead.
wire [4:0] bg_col = crt_flip ? (fl_col + scroll_x[7:3]) : (tile_col + scroll_x[7:3] + 5'd1);

wire [3:0] bg_line_sum   = {1'b0, fl_line} + {1'b0, scroll_y[2:0]};
assign     bg_line       = bg_line_sum[2:0];
wire       bg_line_carry = bg_line_sum[3];
wire [4:0] bg_row = fl_row + scroll_y[7:3] + {4'd0, bg_line_carry};

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
// Speech is decoded at $3400 EXACTLY (as MAME's Vanguard memory map): a stray write anywhere else in the page would
// feed a spurious nibble into the HD38880 command FSM and desync it. Fantasy's $2400 likewise.
wire vg_speech_wr  = io_wr & (cpu_addr[15:0] == 16'h3400);  // $3400 exact

// --- Fantasy I/O writes ($2xxx) ---
wire fy_sound_wr   = io_wr & (cpu_addr[15:8] == 8'h21) & (cpu_addr[1:0] != 2'b11);
wire fy_flip_wr    = io_wr & (cpu_addr[15:0] == 16'h2103);
wire fy_scrollx_wr = io_wr & (cpu_addr[15:8] == 8'h22);
wire fy_scrolly_wr = io_wr & (cpu_addr[15:8] == 8'h23);
// exact address (see vg_speech_wr above).
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

// IRQ held as MAME's HOLD_LINE: assert on vblank rising edge,
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

assign t65_0_i = '{res_n: cpu_reset_n, enable: cpu_clken, rdy: cpu_rdy, irq_n: cpu_irq_n, nmi_n: cpu_nmi_n, di: cpu_din};

// ============================================================
// Video Control Registers
// ============================================================
reg [2:0] backcolor;
reg       charbank;
reg       flip;

always @(posedge clk_master or posedge reset)
    if (reset) begin
        backcolor <= 3'd0;
        charbank  <= 1'b0;
        flip      <= 1'b0;
        scroll_x  <= 8'd0;
        scroll_y  <= 8'd0;
        irq_mask  <= 1'b0;
    end else begin
        // flip / charbank / back colour register (Vanguard / Fantasy / Pioneer Balloon / Nibbler)
        // bit 7 = flip screen, bit 3 = charbank (inverted), bits 2:0 = backcolor
        if (flip_wr) begin
            flip      <= cpu_dout[7];
            charbank  <= (game_id == GID_VANGUARD) ? 1'b0 : ~cpu_dout[3];
            backcolor <= cpu_dout[2:0];
        end

        // $B002 (Sasuke / Satan of Saturn only)
        // bit 0 = flip, bit 1 = irq_mask
        if (ss_b002_wr) begin
            flip     <= cpu_dout[0];
            irq_mask <= cpu_dout[1];
        end

        // $B003 back colour (Sasuke / Satan of Saturn only)
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

// ce_pix: one pulse per pixel = master clock / 2. clk_div free-runs 0..15 (16 master clocks per character), so
// clk_div[0] gives the 8 pixel slots {1,3,..,15}: 256 pixels per line. Slot 15 coincides with crtc_clken, which is
// harmless: the shift-register block is `if (crtc_clken) <load> else if (ce_pix) <shift>`, so the load wins there
// while the pixel sampled is still the pre-load content, i.e. pixel 7. (ROT90: the native X axis is screen Y, so a
// missing slot shows as a missing bottom row on every tile.)
assign ce_pix = (clk_div[0] == 1'b1);

assign     bg_tile_code = {charbank, vram1_vid_dout};

wire [2:0] bg_color = (game_id <= GID_SATANSAT) ?
    {1'b0, colorram_bg_vid_dout[3:2]} :
    (colorram_bg_vid_dout[5:3]);

assign     fg_tile_code = vram2_vid_dout;
wire [2:0] fg_color = (game_id <= GID_SATANSAT) ?
    {1'b0, colorram_fg_vid_dout[1:0]} :
    (colorram_fg_vid_dout[2:0]);

// BG: a 16-bit two-tile window plus a one-character history register; FG: 8-bit shift latches.
reg [7:0]  bg_p0_prev, bg_p1_prev;
reg [15:0] bg_p0_win,  bg_p1_win;
reg [2:0]  bg_color_prev;
reg [7:0] fg_p0_latch, fg_p1_latch;
reg [2:0] bg_color_latch, fg_color_latch;

// FG pixel data latched directly from both planes simultaneously
wire [7:0] fg_p0_raw = charram_p0_dout;
wire [7:0] fg_p1_raw = charram_p1_dout;

// Latch tile data one clock after crtc_clken (dpram needs 1 cycle to respond to new MA)
reg crtc_clken_d;
always @(posedge clk_master) crtc_clken_d <= crtc_clken;

// BG pixel stage: a 16-bit two-tile window (the FG does not scroll).
//
//   bg_*_prev  holds byte T   (latched one character time ago)
//   bg_*_dout  holds byte T+1 (because bg_col fetches at +1, see above)
//   bg_*_win   = {byte T, byte T+1}, shifted left one bit per ce_pix
//   output tap = bit (15 - f), f = scroll_x[2:0]
//
// After k shifts the tap exposes original bit (15-f-k), so a character time emits
// bits 15-f .. 8-f of the window - exactly pixels [f..f+7] of the stream.
//
// At f = 0 the tap is bg_*_prev[7-k]: a plain 8-bit shift of tile T. The colour is delayed one character
// (bg_color_prev) so it still belongs to tile T.
// CRT Flip: every shift runs RIGHT. The BG window is {byte t0, byte t0+1} = {cur, prev},
// and the slot's colour is t0's (the current fetch) - the exact mirror of the unflipped one-colour-per-slot rule.
always @(posedge clk_master) begin
    if (crtc_clken) begin
        bg_p0_win      <= crt_flip ? {bg_p0_dout, bg_p0_prev} : {bg_p0_prev, bg_p0_dout};
        bg_p1_win      <= crt_flip ? {bg_p1_dout, bg_p1_prev} : {bg_p1_prev, bg_p1_dout};
        bg_p0_prev     <= bg_p0_dout;
        bg_p1_prev     <= bg_p1_dout;
        bg_color_latch <= crt_flip ? bg_color : bg_color_prev;   // colour of tile T, matching window[15:8]
        bg_color_prev  <= bg_color;
        fg_p0_latch    <= fg_p0_raw;
        fg_p1_latch    <= fg_p1_raw;
        fg_color_latch <= fg_color;
    end else if (ce_pix) begin
        bg_p0_win   <= crt_flip ? {1'b0, bg_p0_win[15:1]}  : {bg_p0_win[14:0], 1'b0};
        bg_p1_win   <= crt_flip ? {1'b0, bg_p1_win[15:1]}  : {bg_p1_win[14:0], 1'b0};
        fg_p0_latch <= crt_flip ? {1'b0, fg_p0_latch[7:1]} : {fg_p0_latch[6:0], 1'b0};
        fg_p1_latch <= crt_flip ? {1'b0, fg_p1_latch[7:1]} : {fg_p1_latch[6:0], 1'b0};
    end
end

wire fantasy_nibbler_swap = (game_id == GID_FANTASY) || (game_id == GID_NIBBLER);

// Pioneer Balloon: BG plane swap candidate (uses same hardware family)
wire pballoon_bg_swap = (game_id == GID_PBALLOON);

// Sasuke swaps bitplane order in GFX ROM
wire sasuke_swap = (game_id == GID_SASUKE);
// BG pixel: tap the two-tile window at (15 - fine offset); CRT-flipped the window shifts right and the slot's first
// pixel is bit (8 - f). The index is a named wire because this .v file is elaborated as Verilog-2001 by Quartus 17.0.
wire [3:0] bg_fine_tap  = crt_flip ? (4'd8 - {1'b0, scroll_x[2:0]}) : (4'd15 - {1'b0, scroll_x[2:0]});
wire       bg_p0_bit    = bg_p0_win[bg_fine_tap];
wire       bg_p1_bit    = bg_p1_win[bg_fine_tap];
wire [1:0] bg_pixel_raw = {bg_p1_bit, bg_p0_bit};
wire bg_swap = sasuke_swap | fantasy_nibbler_swap | pballoon_bg_swap | (game_id == GID_VANGUARD);
wire [1:0] bg_pixel = bg_swap ? {bg_pixel_raw[0], bg_pixel_raw[1]} : bg_pixel_raw;

wire [1:0] fg_pixel_raw = crt_flip ? {fg_p1_latch[0], fg_p0_latch[0]} : {fg_p1_latch[7], fg_p0_latch[7]};
// FG pen bits: MAME's Vanguard FG layout has planes { 0, 256*8*8 } with the first plane = pixel MSB, so MSB =
// charram+0x000 (charram_p0) and LSB = charram+0x800 (charram_p1). fg_pixel_raw is {p1, p0}, so Vanguard swaps, as do
// Fantasy / Nibbler; the BG does the same through bg_swap.
// NOTE: Pioneer Balloon swaps its BG but not its FG - untested; check here if its colours look off.
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

// Pipe-tap index (delay in ce_pix cycles = env_idx + 1). The pixel path is ~2 characters deep = 2 * 8 ce_pix = 16
// stages and has no game_id-dependent stage (every game_id use in it is combinational: bg_swap / fg_plane_swap /
// ss_*_prom_addr), so one tap fits every game; 15 is HW-confirmed on Vanguard. Too little delay shows as junk rows at
// the top and missing rows at the bottom (ROT90: screen rows are native pixel columns, i.e. ce_pix cycles).
// ENVELOPE_DELAY_MAX is 16, so 15 is the last valid tap; more delay needs ENVELOPE_DELAY_MAX to grow first.
wire [3:0] env_idx = 4'd15;

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
// Resistor-weighted palette (MAME's SNK6502 and Satan of Saturn palettes are identical, so one formula covers all
// six games): weights 0x21 / 0x47 / 0x97 per bit:
//     r = 0x21*bit0 + 0x47*bit1 + 0x97*bit2      (prom bits 2:0)
//     g = 0x21*bit3 + 0x47*bit4 + 0x97*bit5      (prom bits 5:3)
//     b =            0x47*bit6 + 0x97*bit7       (prom bits 7:6)  <-- only TWO resistors
//
// The BLUE channel has no 0x21 leg, so blue peaks at 0x47 + 0x97 = 222, not 255 (MAME's brightest blue is 222 too).
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
// Sound ROM - 6KB at $12040 in download space, addressed as 0x000-0x17FF: rom4
// ---------------------------------------------------------------------------
wire [12:0] snd_rom_addr;
wire [7:0]  snd_rom_dout;

assign rom4_a       = snd_rom_addr;
assign snd_rom_dout = rom4_d;

// ---------------------------------------------------------------------------
// Speech ROM (HD38880 PARCOR data) - 6KB at $14000 in download space,
// Vanguard (sk6_ic07/08/11.bin) or Fantasy (fs_d_7/e_8/f_11.bin) depending
// on which MRA is loaded. Addressed 0x000-0x17FF (game address $4000 base
// subtracted by hd38880_top): rom5
// ---------------------------------------------------------------------------
wire [12:0] speech_rom_addr;
wire [7:0]  speech_rom_dout;

assign rom5_a          = speech_rom_addr;
assign speech_rom_dout = rom5_d;

// ---------------------------------------------------------------------------
// HD38880 speech synthesizer (Vanguard / Fantasy)
// ---------------------------------------------------------------------------
wire signed [14:0] speech_audio;

// pooled HD38880 (hd38880_0)
assign hd38880_0_i     = '{host_wr: speech_wr, host_din: cpu_dout[5:0], game_is_fantasy: speech_game_is_fantasy,
                           rom_data: speech_rom_dout};
assign speech_rom_addr = hd38880_0_o.rom_addr;
assign speech_audio    = hd38880_0_o.audio;

// ---------------------------------------------------------------------------
// Sound port write strobes — game-aware (per MAME memory maps)
//   Fantasy/Nibbler:  $2100-$2103  (port 3 is also the flip register)
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

// Sasuke / Satan of Saturn sound ports: $B000 / $B001. Gated on game_id <= GID_SATANSAT so it cannot clash with
// Pioneer Balloon, whose CRTC lives at those same addresses.
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
    // Vanguard's sound ports differ from Fantasy's
    .game_is_vanguard (game_id == GID_VANGUARD),
    .game_is_sasuke   (game_id == GID_SASUKE),
    .game_is_satansat (game_id == GID_SATANSAT),
    // selects pballoon's 40.3 Hz music clock
    .game_is_pballoon (game_id == GID_PBALLOON),
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

// Latch the whole of sound port 0 so the SN76477 legs
// can see bits 5/6 as LEVELS (the ENABLE pin is level driven, not edge).
reg [7:0] snd_p0_latch;
always @(posedge clk_master or posedge reset)
    if (reset)        snd_p0_latch <= 8'h00;
    else if (snd_wr0) snd_p0_latch <= cpu_dout;

wire game_vg = (game_id == GID_VANGUARD);
wire game_fy = (game_id == GID_FANTASY);

// Sound port 0 (as MAME's Vanguard / Fantasy sound handlers):
//   Vanguard: bit 5 SHOT A -> SN76477 #1, bit 6 SHOT B -> SN76477 #2, bit 7 BOMB -> the one-shot below
//   Fantasy:  bit 7 BOMB -> SN76477 #1, driven as a LEVEL
wire shot_a_gate  = game_vg & snd_p0_latch[5];
wire shot_b_gate  = game_vg & snd_p0_latch[6];
wire fy_bomb_gate = game_fy & snd_p0_latch[7];

// Fantasy's bomb comes from the modelled SN76477 leg (it sustains while the bit is held); every other game uses the
// fixed 26 ms one-shot (Nibbler HW-confirmed).
wire bomb_trigger = bomb_enable & ~game_fy;

// ---- SN76477 leg A (sn76477_noise_0): 470k noise clock (3081.7 Hz) + 1.5M/220pF filter --------
// Shared by Vanguard SHOT A and Fantasy BOMB: identical component values in
// MAME, and they belong to different games so the gates can never both be high.
wire signed [15:0] sn_lo_audio;
assign sn76477_noise_0_i = '{gate: shot_a_gate | fy_bomb_gate};   // pooled leg sn76477_noise_0
assign sn_lo_audio        = sn76477_noise_0_o.audio;

// ---- SN76477 leg B (sn76477_noise_1): 10k noise clock (97493 Hz), NO filter cap (C=0) ---------
// Vanguard SHOT B only. MAME routes this at 0.25 vs SHOT A's 0.50, hence half
// the amplitude.
wire signed [15:0] sn_hi_audio;
assign sn76477_noise_1_i = '{gate: shot_b_gate};                  // pooled leg sn76477_noise_1
assign sn_hi_audio        = sn76477_noise_1_o.audio;

wire signed [15:0] noise_audio;

snk6502_noise noise_gen(
    .clk      (clk_master),
    .reset    (reset),
    .pause    (pause),
    .trigger  (bomb_trigger),
    .audio_out(noise_audio)
);

// Saturating signed mix (tone + noise + speech).
// speech_audio is signed 15-bit (+-16384), every other source signed 16-bit: <<< 1 level-matches it (full scale onto
// full scale). Vanguard only: speech x4 and the three noise sources (SHOT A, SHOT B, BOMB) -6 dB. Its bomb bursts reach
// full scale and SHOT A / B run continuously while fire is held, burying the speech (MAME's snk6502_a.cpp mixer has the
// same imbalance: Vanguard speech 0.25 vs custom / SHOT A 0.50). Fantasy's speech level is fine at x2.
// TUNABLE: the <<< 2 / <<< 1 here and the three >>> 1 taps below.
wire signed [17:0] speech_audio_w18 = {{3{speech_audio[14]}}, speech_audio};
wire signed [17:0] speech_audio_amp = game_vg ? (speech_audio_w18 <<< 2)
                                              : (speech_audio_w18 <<< 1);
wire signed [15:0] speech_audio_scaled =
      (speech_audio_amp >  18'sd32767) ? 16'sd32767
    : (speech_audio_amp < -18'sd32768) ? 16'sh8000
    : speech_audio_amp[15:0];

// Vanguard-only -6 dB on the maskers.
wire signed [15:0] noise_mix = game_vg ? (noise_audio >>> 1) : noise_audio;
wire signed [15:0] sn_lo_mix = game_vg ? (sn_lo_audio >>> 1) : sn_lo_audio;
wire signed [15:0] sn_hi_mix = game_vg ? (sn_hi_audio >>> 1) : sn_hi_audio;
// Five signed 16-bit terms peak at 5*32768 = 163840 (19 bits signed): 20-bit accumulator, saturated to 16 bits.
wire signed [19:0] audio_mix3 = $signed(snd_audio) + $signed(noise_mix)
                              + $signed(speech_audio_scaled)
                              + $signed(sn_lo_mix) + $signed(sn_hi_mix);
wire audio_mix3_ovf = ~(&audio_mix3[19:15] | ~|audio_mix3[19:15]);
assign audio = audio_mix3_ovf ?
               (audio_mix3[19] ? 16'sh8000 : 16'sh7FFF) :
               audio_mix3[15:0];

endmodule