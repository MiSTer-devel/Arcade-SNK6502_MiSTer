//  SNK6502 board: Sasuke vs. Commander, Satan of Saturn / Zarzon, Vanguard, Fantasy, Pioneer Balloon, Nibbler
//  Based on MAME snk6502.cpp, snk6502_v.cpp (Nicola Salmoria, Dan Boris, BSD-3-Clause)

module snk6502_board(
    input         clk_master,     // 11.289 MHz master clock
    input         reset,
    input         pause,
    input         crt_flip,       // OSD CRT Flip: 180 degree mirror of the whole raster
    output        ce_pix,

    input  [3:0]  game_id,        // which game variant (see defines below)

    input  [7:0]  p1,
    input  [7:0]  p2,
    input  [3:0]  p1_rstick,      // P1 right stick {U, D, L, R}: Vanguard's second set of fire buttons
    input  [3:0]  sys_ctl,        // {start2, start1, coin2, coin1}
    input  [7:0]  dsw,            // DIP switches

    output [7:0]  rgb_r,
    output [7:0]  rgb_g,
    output [7:0]  rgb_b,
    output        hsync,
    output        vsync,
    output        hblank,
    output        vblank,

    output [15:0] audio,
    output        flip_screen,

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

    output ram_pool_pkg::pram_i_t [6:0] pr_i,
    input  ram_pool_pkg::pram_o_t [6:0] pr_o
);

localparam GID_SASUKE   = 4'd0;
localparam GID_SATANSAT = 4'd1;
localparam GID_VANGUARD = 4'd2;
localparam GID_FANTASY  = 4'd3;
localparam GID_PBALLOON = 4'd4;
localparam GID_NIBBLER  = 4'd5;

wire m_right1  = p1[0], m_left1  = p1[1], m_down1  = p1[2], m_up1  = p1[3];
wire m_btn1_p1 = p1[4], m_btn2_p1 = p1[5], m_btn3_p1 = p1[6], m_btn4_p1 = p1[7];
wire m_right2  = p2[0], m_left2  = p2[1], m_down2  = p2[2], m_up2  = p2[3];
wire m_btn1_p2 = p2[4], m_btn2_p2 = p2[5], m_btn3_p2 = p2[6], m_btn4_p2 = p2[7];
wire r_fire_right = p1_rstick[0], r_fire_left = p1_rstick[1], r_fire_down = p1_rstick[2], r_fire_up = p1_rstick[3];
wire m_coin1   = sys_ctl[0], m_coin2  = sys_ctl[1], m_start1 = sys_ctl[2], m_start2 = sys_ctl[3];
wire music0_playing;

wire m_fire_right_p1 = m_btn1_p1 | r_fire_right;
wire m_fire_down_p1  = m_btn2_p1 | r_fire_down;
wire m_fire_up_p1    = m_btn3_p1 | r_fire_up;
wire m_fire_left_p1  = m_btn4_p1 | r_fire_left;

wire m_fire_right_p2 = m_btn1_p2;
wire m_fire_down_p2  = m_btn2_p2;
wire m_fire_up_p2    = m_btn3_p2;
wire m_fire_left_p2  = m_btn4_p2;

reg [2:0] sasuke_div   = 3'd0;
reg [3:0] sasuke_count = 4'd0;
always @(posedge clk_master) begin
	sasuke_div <= sasuke_div + 3'd1;
	if (sasuke_div == 3'd7)
		sasuke_count <= sasuke_count + 4'd1;
end

wire [7:0] in0_sasuke   = {m_start2, m_start1, 3'b000, m_btn1_p1, m_right1, m_left1};
wire [7:0] in1_sasuke   = {music0_playing, 7'b0000000};
wire [7:0] in2_sasuke   = {sasuke_count, 3'b000, m_coin1};

wire [7:0] in0_satansat = {1'b0, m_btn2_p1, 3'b000, m_btn1_p1, m_right1, m_left1};
wire [7:0] in1_satansat = {music0_playing, 5'b00000, m_start2, m_start1};
wire [7:0] in2_satansat = {sasuke_count, 3'b000, m_coin1};

wire [7:0] in0_vanguard = {m_left1, m_right1, m_up1, m_down1,
                           m_fire_left_p1, m_fire_right_p1, m_fire_up_p1, m_fire_down_p1};
wire [7:0] in1_vanguard = {m_left2, m_right2, m_up2, m_down2,
                           m_fire_left_p2, m_fire_right_p2, m_fire_up_p2, m_fire_down_p2};
wire [7:0] in2_vanguard = {m_start1, m_start2, 1'b0, music0_playing, 2'b00, m_coin1, m_coin2};

wire [7:0] in0_fantasy  = {m_left1, m_right1, m_up1, m_down1, m_btn1_p1, 3'b000};
wire [7:0] in1_fantasy  = {m_left2, m_right2, m_up2, m_down2, m_btn1_p2, 3'b000};
wire [7:0] in2_fantasy  = {m_start1, m_start2, 4'b0000, m_coin1, m_coin2};

wire [7:0] in0_pballoon = {m_left1, m_right1, m_up1, m_down1, m_btn1_p1, 3'b000};
wire [7:0] in1_pballoon = {m_left2, m_right2, m_up2, m_down2, m_btn1_p2, 3'b000};
wire [7:0] in2_pballoon = {m_start1, m_start2, 4'b0000, m_coin1, m_coin2};

wire [7:0] in0_nibbler  = {m_left1, m_right1, m_up1, m_down1, 4'b0000};
wire [7:0] in1_nibbler  = {m_left2, m_right2, m_up2, m_down2, 4'b0000};
wire [7:0] in2_nibbler  = {m_start1, m_start2, 4'b0000, m_coin1, m_coin2};

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

wire [2:0] fl_line;
wire [2:0] bg_line;
wire [7:0] fg_tile_code;
wire [8:0] bg_tile_code;
reg  [7:0] scroll_x;
reg  [7:0] scroll_y;

reg [3:0] clk_div;
always @(posedge clk_master or posedge reset)
    if (reset)
        clk_div <= 4'd0;
    else
        clk_div <= clk_div + 4'd1;

wire crtc_clken = (clk_div == 4'd15);

wire is_slow_cpu = (game_id == GID_SASUKE) || (game_id == GID_SATANSAT);
wire cpu_clken   = is_slow_cpu ? crtc_clken : (clk_div[2:0] == 3'd7);

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

assign cpu_addr = t65_0_o.a;
assign cpu_dout = t65_0_o.dout;
assign cpu_rw_n = t65_0_o.rw;

wire [7:0] rom_dout;
assign rom0_a   = cpu_addr;
assign rom_dout = rom0_d;

wire ram_cs = (cpu_addr[15:10] == 6'b000000);
wire [7:0] ram_dout;
wire ram_wr = ram_cs & ~cpu_rw_n & cpu_clken;

assign pr_i[0] = '{a_addr: {5'd0, cpu_addr[9:0]}, a_d: cpu_dout, a_we: ram_wr, b_addr: 15'd0, b_d: 8'd0, b_we: 1'b0};
assign ram_dout = pr_o[0].a_q;

wire vram2_cs = (cpu_addr[15:10] == 6'b000001);
wire [7:0] vram2_cpu_dout;
wire vram2_wr = vram2_cs & ~cpu_rw_n & cpu_clken;

wire [9:0] vram2_vid_addr;
wire [7:0] vram2_vid_dout;

assign pr_i[1] = '{a_addr: {5'd0, cpu_addr[9:0]}, a_d: cpu_dout, a_we: vram2_wr, b_addr: {5'd0, vram2_vid_addr}, b_d: 8'd0, b_we: 1'b0};
assign vram2_cpu_dout = pr_o[1].a_q;
assign vram2_vid_dout = pr_o[1].b_q;

wire vram1_cs = (cpu_addr[15:10] == 6'b000010);
wire [7:0] vram1_cpu_dout;
wire vram1_wr = vram1_cs & ~cpu_rw_n & cpu_clken;

wire [9:0] vram1_vid_addr;
wire [7:0] vram1_vid_dout;

assign pr_i[2] = '{a_addr: {5'd0, cpu_addr[9:0]}, a_d: cpu_dout, a_we: vram1_wr, b_addr: {5'd0, vram1_vid_addr}, b_d: 8'd0, b_we: 1'b0};
assign vram1_cpu_dout = pr_o[2].a_q;
assign vram1_vid_dout = pr_o[2].b_q;

wire colorram_cs = (cpu_addr[15:10] == 6'b000011);
wire [7:0] colorram_cpu_dout;
wire colorram_wr = colorram_cs & ~cpu_rw_n & cpu_clken;

wire [9:0] colorram_fg_vid_addr;
wire [9:0] colorram_bg_vid_addr;
wire [7:0] colorram_fg_vid_dout;
wire [7:0] colorram_bg_vid_dout;

assign pr_i[3] = '{a_addr: {5'd0, cpu_addr[9:0]}, a_d: cpu_dout, a_we: colorram_wr, b_addr: {5'd0, colorram_fg_vid_addr}, b_d: 8'd0, b_we: 1'b0};
assign colorram_cpu_dout    = pr_o[3].a_q;
assign colorram_fg_vid_dout = pr_o[3].b_q;

assign pr_i[4] = '{a_addr: {5'd0, cpu_addr[9:0]}, a_d: cpu_dout, a_we: colorram_wr, b_addr: {5'd0, colorram_bg_vid_addr}, b_d: 8'd0, b_we: 1'b0};
assign colorram_bg_vid_dout = pr_o[4].b_q;

wire charram_cs = (cpu_addr[15:12] == 4'b0001);
wire [7:0] charram_p0_cpu_dout;
wire [7:0] charram_p1_cpu_dout;
wire [7:0] charram_cpu_dout = cpu_addr[11] ? charram_p1_cpu_dout : charram_p0_cpu_dout;

wire charram_wr = charram_cs & ~cpu_rw_n & cpu_clken;

wire [10:0] charram_vid_addr = {fg_tile_code, fl_line};
wire [7:0]  charram_p0_dout, charram_p1_dout;

assign pr_i[5] = '{a_addr: {4'd0, cpu_addr[10:0]}, a_d: cpu_dout, a_we: charram_wr & ~cpu_addr[11], b_addr: {4'd0, charram_vid_addr}, b_d: 8'd0, b_we: 1'b0};
assign charram_p0_cpu_dout = pr_o[5].a_q;
assign charram_p0_dout     = pr_o[5].b_q;

assign pr_i[6] = '{a_addr: {4'd0, cpu_addr[10:0]}, a_d: cpu_dout, a_we: charram_wr & cpu_addr[11], b_addr: {4'd0, charram_vid_addr}, b_d: 8'd0, b_we: 1'b0};
assign charram_p1_cpu_dout = pr_o[6].a_q;
assign charram_p1_dout     = pr_o[6].b_q;

wire [11:0] bg_pixel_addr = {bg_tile_code[8:0], bg_line};
wire [7:0] bg_p0_dout, bg_p1_dout;

assign rom1_a = bg_pixel_addr;
assign rom2_a = bg_pixel_addr;
assign bg_p0_dout = rom1_d;
assign bg_p1_dout = rom2_d;

wire [7:0] prom_dout;
wire [5:0] prom_addr;

assign rom3_a    = prom_addr;
assign prom_dout = rom3_d;

wire crtc_cs;
assign crtc_cs =
    (game_id == GID_FANTASY || game_id == GID_NIBBLER) ? (cpu_addr[15:1] == 15'h1000) :
    (game_id == GID_PBALLOON) ? (cpu_addr[15:1] == 15'h5800) :
    (cpu_addr[15:1] == 15'h1800);

wire crtc_wr = crtc_cs & ~cpu_rw_n;

wire        crtc_hsync;
wire        crtc_vsync;
wire        crtc_hblank;
wire        crtc_vblank;
wire        crtc_de;
wire [13:0] crtc_ma;
wire [4:0]  crtc_ra;
wire [7:0]  crtc_dout;

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

wire        ma_needs_start_adj = (game_id <= GID_SATANSAT);
wire [9:0]  crtc_ma_disp = crtc_ma[9:0] - {9'd0, ma_needs_start_adj};

wire [4:0] tile_col  = crtc_ma_disp[4:0];
wire [4:0] tile_row  = crtc_ma_disp[9:5];
wire [2:0] tile_line = crtc_ra[2:0];

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

wire io_wr = ~cpu_rw_n & cpu_clken;

wire vg_sound_wr   = io_wr & (cpu_addr[15:8] == 8'h31) & (cpu_addr[1:0] != 2'b11);
wire vg_flip_wr    = io_wr & (cpu_addr[15:0] == 16'h3103);
wire vg_scrollx_wr = io_wr & (cpu_addr[15:8] == 8'h32);
wire vg_scrolly_wr = io_wr & (cpu_addr[15:8] == 8'h33);
wire vg_speech_wr  = io_wr & (cpu_addr[15:0] == 16'h3400);

wire fy_sound_wr   = io_wr & (cpu_addr[15:8] == 8'h21) & (cpu_addr[1:0] != 2'b11);
wire fy_flip_wr    = io_wr & (cpu_addr[15:0] == 16'h2103);
wire fy_scrollx_wr = io_wr & (cpu_addr[15:8] == 8'h22);
wire fy_scrolly_wr = io_wr & (cpu_addr[15:8] == 8'h23);
wire fy_speech_wr  = io_wr & (cpu_addr[15:0] == 16'h2400);

wire pb_sound_wr   = io_wr & (cpu_addr[15:8] == 8'hB1) & (cpu_addr[1:0] != 2'b11);
wire pb_flip_wr    = io_wr & (cpu_addr[15:0] == 16'hB103);
wire pb_scrollx_wr = io_wr & (cpu_addr[15:8] == 8'hB2);
wire pb_scrolly_wr = io_wr & (cpu_addr[15:8] == 8'hB3);

wire ss_sound_wr   = io_wr & (cpu_addr[15:8] == 8'hB0) & (cpu_addr[0] != 1'b1 | cpu_addr[1] != 1'b1);
wire ss_b002_wr    = io_wr & (cpu_addr[15:0] == 16'hB002);
wire ss_bkcolor_wr = io_wr & (cpu_addr[15:0] == 16'hB003);

wire flip_wr = (game_id == GID_VANGUARD)  ? vg_flip_wr :
               (game_id == GID_FANTASY)   ? fy_flip_wr :
               (game_id == GID_NIBBLER)   ? fy_flip_wr :
               (game_id == GID_PBALLOON)  ? pb_flip_wr :
               1'b0;

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

wire speech_wr = (game_id == GID_VANGUARD) ? vg_speech_wr :
                  (game_id == GID_FANTASY)  ? fy_speech_wr :
                  1'b0;
wire speech_game_is_fantasy = (game_id == GID_FANTASY);

reg irq_mask;

reg vblank_prev;
always @(posedge clk_master or posedge reset)
    if (reset)
        vblank_prev <= 1'b0;
    else
        vblank_prev <= crtc_vblank;

wire vblank_rising = crtc_vblank & ~vblank_prev;

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
        if (flip_wr) begin
            flip      <= cpu_dout[7];
            charbank  <= (game_id == GID_VANGUARD) ? 1'b0 : ~cpu_dout[3];
            backcolor <= cpu_dout[2:0];
        end

        if (ss_b002_wr) begin
            flip     <= cpu_dout[0];
            irq_mask <= cpu_dout[1];
        end

        if (ss_bkcolor_wr) begin
            backcolor <= {1'b0, cpu_dout[1:0]};
        end

        if (scrollx_wr) scroll_x <= cpu_dout;
        if (scrolly_wr) scroll_y <= cpu_dout;
    end

assign flip_screen = flip;

wire in0_cs, in1_cs, dsw_cs, in2_cs;

assign in0_cs =
    (game_id <= GID_SATANSAT)  ? (cpu_addr == 16'hB004) :
    (game_id == GID_VANGUARD)  ? (cpu_addr == 16'h3104) :
    (game_id == GID_PBALLOON)  ? (cpu_addr == 16'hB104) :
    (cpu_addr == 16'h2104);

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

reg [2:0] pix_cnt;
always @(posedge clk_master or posedge reset)
    if (reset)
        pix_cnt <= 3'd0;
    else if (crtc_clken)
        pix_cnt <= 3'd0;
    else
        pix_cnt <= pix_cnt + 3'd1;

assign ce_pix = (clk_div[0] == 1'b1);

assign     bg_tile_code = {charbank, vram1_vid_dout};

wire [2:0] bg_color = (game_id <= GID_SATANSAT) ?
    {1'b0, colorram_bg_vid_dout[3:2]} :
    (colorram_bg_vid_dout[5:3]);

assign     fg_tile_code = vram2_vid_dout;
wire [2:0] fg_color = (game_id <= GID_SATANSAT) ?
    {1'b0, colorram_fg_vid_dout[1:0]} :
    (colorram_fg_vid_dout[2:0]);

reg [7:0]  bg_p0_prev, bg_p1_prev;
reg [15:0] bg_p0_win,  bg_p1_win;
reg [2:0]  bg_color_prev;
reg [7:0] fg_p0_latch, fg_p1_latch;
reg [2:0] bg_color_latch, fg_color_latch;

wire [7:0] fg_p0_raw = charram_p0_dout;
wire [7:0] fg_p1_raw = charram_p1_dout;

reg crtc_clken_d;
always @(posedge clk_master) crtc_clken_d <= crtc_clken;

always @(posedge clk_master) begin
    if (crtc_clken) begin
        bg_p0_win      <= crt_flip ? {bg_p0_dout, bg_p0_prev} : {bg_p0_prev, bg_p0_dout};
        bg_p1_win      <= crt_flip ? {bg_p1_dout, bg_p1_prev} : {bg_p1_prev, bg_p1_dout};
        bg_p0_prev     <= bg_p0_dout;
        bg_p1_prev     <= bg_p1_dout;
        bg_color_latch <= crt_flip ? bg_color : bg_color_prev;
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

wire pballoon_bg_swap = (game_id == GID_PBALLOON);

wire sasuke_swap = (game_id == GID_SASUKE);
wire [3:0] bg_fine_tap  = crt_flip ? (4'd8 - {1'b0, scroll_x[2:0]}) : (4'd15 - {1'b0, scroll_x[2:0]});
wire       bg_p0_bit    = bg_p0_win[bg_fine_tap];
wire       bg_p1_bit    = bg_p1_win[bg_fine_tap];
wire [1:0] bg_pixel_raw = {bg_p1_bit, bg_p0_bit};
wire bg_swap = sasuke_swap | fantasy_nibbler_swap | pballoon_bg_swap | (game_id == GID_VANGUARD);
wire [1:0] bg_pixel = bg_swap ? {bg_pixel_raw[0], bg_pixel_raw[1]} : bg_pixel_raw;

wire [1:0] fg_pixel_raw = crt_flip ? {fg_p1_latch[0], fg_p0_latch[0]} : {fg_p1_latch[7], fg_p0_latch[7]};
wire fg_plane_swap = fantasy_nibbler_swap | (game_id == GID_VANGUARD);
wire [1:0] fg_pixel = fg_plane_swap ?
    {fg_pixel_raw[0], fg_pixel_raw[1]} :
    fg_pixel_raw;

wire fg_transparent = (fg_pixel == 2'b00);

wire [1:0] final_pixel = fg_transparent ? bg_pixel : fg_pixel;
wire [2:0] final_color = fg_transparent ? bg_color_latch : fg_color_latch;
wire       final_is_bg = fg_transparent;

wire [4:0] fg_prom_addr = {fg_color_latch, fg_pixel};
wire [4:0] bg_prom_addr_raw = {bg_color_latch, bg_pixel};
wire [4:0] bg_prom_addr = (bg_pixel == 2'b00) ?
    {backcolor, 2'b00} : bg_prom_addr_raw;

wire [4:0] ss_fg_prom_addr = {fg_pixel, fg_color_latch[1:0]};
wire [4:0] ss_bg_prom_addr = (bg_pixel == 2'b00) ?
    {3'b100, backcolor[1:0]} :
    {1'b1, bg_pixel, bg_color_latch[1:0]};

assign prom_addr = (game_id <= GID_SATANSAT) ?
    (final_is_bg ? {1'b0, ss_bg_prom_addr} : {1'b0, ss_fg_prom_addr}) :
    (final_is_bg ? {1'b1, bg_prom_addr} : {1'b0, fg_prom_addr});

reg display_active_raw;
always @(posedge clk_master)
    display_active_raw <= crtc_de & ~crtc_hblank & ~crtc_vblank;

localparam integer ENVELOPE_DELAY_MAX = 16;

reg [ENVELOPE_DELAY_MAX-1:0] de_pipe;
reg [ENVELOPE_DELAY_MAX-1:0] hblank_pipe;
reg [ENVELOPE_DELAY_MAX-1:0] hsync_pipe;
reg [ENVELOPE_DELAY_MAX-1:0] vblank_pipe;
reg [ENVELOPE_DELAY_MAX-1:0] vsync_pipe;

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

assign hsync  = hsync_pipe[env_idx];
assign vsync  = vsync_pipe[env_idx];
assign hblank = hblank_pipe[env_idx];
assign vblank = vblank_pipe[env_idx];

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

reg coin_prev;
reg cpu_nmi;
always @(posedge clk_master or posedge reset)
    if (reset) begin
        coin_prev <= 1'b0;
        cpu_nmi   <= 1'b0;
    end else begin
        coin_prev <= in2[1] | in2[0];
        if (~(in2[1] | in2[0]) & coin_prev)
            cpu_nmi <= 1'b1;
        else if (cpu_clken)
            cpu_nmi <= 1'b0;
    end
assign cpu_nmi_n = ~cpu_nmi;

wire [12:0] snd_rom_addr;
wire [7:0]  snd_rom_dout;

assign rom4_a       = snd_rom_addr;
assign snd_rom_dout = rom4_d;

wire [12:0] speech_rom_addr;
wire [7:0]  speech_rom_dout;

assign rom5_a          = speech_rom_addr;
assign speech_rom_dout = rom5_d;

wire signed [14:0] speech_audio;

assign hd38880_0_i     = '{host_wr: speech_wr, host_din: cpu_dout[5:0], game_is_fantasy: speech_game_is_fantasy,
                           rom_data: speech_rom_dout};
assign speech_rom_addr = hd38880_0_o.rom_addr;
assign speech_audio    = hd38880_0_o.audio;

wire snd_wr0 = io_wr & ((cpu_addr == 16'h2100) |
                        (cpu_addr == 16'h3100) |
                        (cpu_addr == 16'hB100));
wire snd_wr1 = io_wr & ((cpu_addr == 16'h2101) |
                        (cpu_addr == 16'h3101) |
                        (cpu_addr == 16'hB101));
wire snd_wr2 = io_wr & ((cpu_addr == 16'h2102) |
                        (cpu_addr == 16'h3102) |
                        (cpu_addr == 16'hB102));
wire snd_wr3 = io_wr &  (cpu_addr == 16'h2103);

wire ss_snd_wr0 = io_wr & (game_id <= GID_SATANSAT) & (cpu_addr == 16'hB000);
wire ss_snd_wr1 = io_wr & (game_id <= GID_SATANSAT) & (cpu_addr == 16'hB001);

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
    .game_is_vanguard (game_id == GID_VANGUARD),
    .game_is_sasuke   (game_id == GID_SASUKE),
    .game_is_satansat (game_id == GID_SATANSAT),
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

reg [7:0] snd_p0_latch;
always @(posedge clk_master or posedge reset)
    if (reset)        snd_p0_latch <= 8'h00;
    else if (snd_wr0) snd_p0_latch <= cpu_dout;

wire game_vg = (game_id == GID_VANGUARD);
wire game_fy = (game_id == GID_FANTASY);

wire shot_a_gate  = game_vg & snd_p0_latch[5];
wire shot_b_gate  = game_vg & snd_p0_latch[6];
wire fy_bomb_gate = game_fy & snd_p0_latch[7];

wire bomb_trigger = bomb_enable & ~game_fy;

wire signed [15:0] sn_lo_audio;
assign sn76477_noise_0_i = '{gate: shot_a_gate | fy_bomb_gate};
assign sn_lo_audio        = sn76477_noise_0_o.audio;

wire signed [15:0] sn_hi_audio;
assign sn76477_noise_1_i = '{gate: shot_b_gate};
assign sn_hi_audio        = sn76477_noise_1_o.audio;

wire signed [15:0] noise_audio;

snk6502_noise noise_gen(
    .clk      (clk_master),
    .reset    (reset),
    .pause    (pause),
    .trigger  (bomb_trigger),
    .audio_out(noise_audio)
);

wire signed [17:0] speech_audio_w18 = {{3{speech_audio[14]}}, speech_audio};
wire signed [17:0] speech_audio_amp = game_vg ? (speech_audio_w18 <<< 2)
                                              : (speech_audio_w18 <<< 1);
wire signed [15:0] speech_audio_scaled =
      (speech_audio_amp >  18'sd32767) ? 16'sd32767
    : (speech_audio_amp < -18'sd32768) ? 16'sh8000
    : speech_audio_amp[15:0];

wire signed [15:0] noise_mix = game_vg ? (noise_audio >>> 1) : noise_audio;
wire signed [15:0] sn_lo_mix = game_vg ? (sn_lo_audio >>> 1) : sn_lo_audio;
wire signed [15:0] sn_hi_mix = game_vg ? (sn_hi_audio >>> 1) : sn_hi_audio;
wire signed [19:0] audio_mix3 = $signed(snd_audio) + $signed(noise_mix)
                              + $signed(speech_audio_scaled)
                              + $signed(sn_lo_mix) + $signed(sn_hi_mix);
wire audio_mix3_ovf = ~(&audio_mix3[19:15] | ~|audio_mix3[19:15]);
assign audio = audio_mix3_ovf ?
               (audio_mix3[19] ? 16'sh8000 : 16'sh7FFF) :
               audio_mix3[15:0];

endmodule