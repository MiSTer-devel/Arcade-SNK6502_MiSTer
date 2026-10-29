//============================================================================
//  Arcade: SNK6502 (Vanguard, Sasuke vs Commander, Fantasy, etc.)
//
//  Port to MiSTer
//  Copyright (C) 2024
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//============================================================================

module emu
(
    `include "sys/emu_ports.vh"
);

///////// Default values for ports not used in this core /////////

assign ADC_BUS  = 'Z;
assign USER_OUT = '1;
assign {UART_RTS, UART_TXD, UART_DTR} = 0;
assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;
assign {SDRAM_DQ, SDRAM_A, SDRAM_BA, SDRAM_CLK, SDRAM_CKE, SDRAM_DQML, SDRAM_DQMH, SDRAM_nWE, SDRAM_nCAS, SDRAM_nRAS, SDRAM_nCS} = 'Z;
assign FB_FORCE_BLANK = '0;

assign VGA_F1 = '0;
assign VGA_SCALER = '0;
assign VGA_DISABLE = '0;
assign HDMI_FREEZE = '0;
assign HDMI_BLACKOUT = '0;
assign HDMI_BOB_DEINT = '0;

assign AUDIO_MIX = '0;

assign LED_DISK = '0;
assign LED_POWER = '0;
assign BUTTONS = '0;

wire [1:0] ar = status[20:19];

assign VIDEO_ARX = (!ar) ? (status[2] ? 8'd4 : 8'd3) : (ar - 1'd1);
assign VIDEO_ARY = (!ar) ? (status[2] ? 8'd3 : 8'd4) : 12'd0;

`include "build_id.v"
localparam CONF_STR = {
	"SNK6502;;",
	"P1,Video Options;",
	"H0P1OJK,Aspect Ratio,Original,Full Screen,[ARC1],[ARC2];",
	"H0P1O2,Orientation,Vert,Horz;",
	"P1OB,HDMI Flip,Off,On;",
	"P1OM,CRT Flip,Off,On;",
	"P1O35,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",
	"-;",
	"DIP;",
	"-;",
	"P2,Pause Options;",
	"P2OP,Pause when OSD is open,On,Off;",
	"P2OQ,Dim video after 10s,On,Off;",
	"-;",
	"R0,Reset;",
	"J1,Button 1,Button 2,Button 3,Button 4,Coin,Start 1P,Start 2P,Pause;",
	"jn,A,B,X,Y,Select,Start,R,L;",
	"V,v",`BUILD_DATE
};

////////////////////   CLOCKS   ///////////////////

wire clk_vid;
wire clk_master;
wire pll_locked;

pll pll
(
    .refclk(CLK_50M),
    .rst(0),
    .outclk_0(clk_vid),
    .outclk_1(),
    .outclk_2(clk_master),
    .locked(pll_locked)
);

wire clk_sys = clk_vid;

///////////////////////////////////////////////////

wire [31:0] status;
wire  [1:0] buttons;
wire        forced_scandoubler;
wire        video_rotated;
wire        direct_video;

wire        ioctl_download;
wire        ioctl_upload;
wire        ioctl_upload_req;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire  [7:0] ioctl_din;

wire [15:0] joystick_0, joystick_1;
wire [15:0] joystick_r_analog_0;
wire [10:0] ps2_key;

wire [21:0] gamma_bus;

hps_io #(.CONF_STR(CONF_STR)) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),
	.EXT_BUS(),

	.buttons(buttons),
	.status(status),
	.status_menumask({direct_video}),

	.forced_scandoubler(forced_scandoubler),
	.video_rotated(video_rotated),
	.gamma_bus(gamma_bus),
	.direct_video(direct_video),

	.ioctl_download(ioctl_download),
	.ioctl_upload(ioctl_upload),
	.ioctl_upload_req(ioctl_upload_req),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	.ioctl_din(ioctl_din),
	.ioctl_index(ioctl_index),

	.joystick_0(joystick_0),
	.joystick_1(joystick_1),
	.joystick_r_analog_0(joystick_r_analog_0),
	.ps2_key(ps2_key)
);

assign ioctl_upload_req = 1'b0;
assign ioctl_din        = 8'd0;

reg [3:0] game_id;
always @(posedge clk_sys)
	if (ioctl_wr && ioctl_index == 8'd1 && ioctl_addr == 25'd0)
		game_id <= ioctl_dout[3:0];

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

///////////////////   CONTROLS   ////////////////////

wire [12:0] kb;
wire  [1:0] kbx;
ctl_keyboard #(.NX(2), .NXO(2), .XKEYS({24'h10_29_01, 24'h10_12_00})) keyboard
	(.clk(clk_sys), .ps2_key(ps2_key), .pause(pause_cpu), .kb(kb), .kbx(kbx));
wire btn_up       = kb[0];
wire btn_down     = kb[1];
wire btn_left     = kb[2];
wire btn_right    = kb[3];
wire btn_fire1    = kb[4];
wire btn_fire2    = kbx[0];
wire btn_fire3    = kb[5];
wire btn_fire4    = kbx[1];
wire btn_coin1    = kb[8];
wire btn_coin2    = kb[9];
wire btn_1p_start = kb[6];
wire btn_2p_start = kb[7];
wire btn_pause    = kb[12];

wire [3:0] rstick_dir;
ctl_stick_dirs #(.MODE(0), .THRESH(7'd64)) rstick(.stick(joystick_r_analog_0), .dir(rstick_dir));

wire m_up1    = btn_up    | joystick_0[3];
wire m_down1  = btn_down  | joystick_0[2];
wire m_left1  = btn_left  | joystick_0[1];
wire m_right1 = btn_right | joystick_0[0];

wire m_up2    = joystick_1[3];
wire m_down2  = joystick_1[2];
wire m_left2  = joystick_1[1];
wire m_right2 = joystick_1[0];

wire m_btn1_p1 = btn_fire1 | joystick_0[4];
wire m_btn2_p1 = btn_fire2 | joystick_0[5];
wire m_btn3_p1 = btn_fire3 | joystick_0[6];
wire m_btn4_p1 = btn_fire4 | joystick_0[7];

wire m_btn1_p2 = joystick_1[4];
wire m_btn2_p2 = joystick_1[5];
wire m_btn3_p2 = joystick_1[6];
wire m_btn4_p2 = joystick_1[7];

wire m_coin1  = btn_coin1    | joystick_0[8];
wire m_coin2  = btn_coin2    | joystick_1[8];
wire m_start1 = btn_1p_start | joystick_0[9];
wire m_start2 = btn_2p_start | joystick_1[9];
wire m_pause  = btn_pause    | joystick_0[11];

assign LED_USER = m_coin1;

wire [7:0] snk_dsw = sw[0];

reg [7:0] sw[8];
always @(posedge clk_sys)
begin
	if (ioctl_wr && (ioctl_index==8'd254) && !ioctl_addr[24:3]) sw[ioctl_addr[2:0]] <= ioctl_dout;
end

wire rom_download = ioctl_download & (ioctl_index == 8'd0);
wire reset = (RESET | status[0] | buttons[1] | ioctl_download);

wire [7:0] core_r, core_g, core_b;
wire       core_hs, core_vs, core_hb, core_vb;
wire [15:0] core_audio;
wire        core_flip;
wire        ce_pix;
wire [3:0]  dbg_game_id;
wire        dbg_crtc_hit;
wire        dbg_cpu_active;

snk6502_dispatcher game_core(
	.clk_master (clk_master),
	.clk_sys    (clk_sys),
	.reset      (reset),
	.pause      (pause_cpu),
	.crt_flip   (status[22]),

	.game_id    (game_id),

	.p1         ({m_btn4_p1, m_btn3_p1, m_btn2_p1, m_btn1_p1, m_up1, m_down1, m_left1, m_right1}),
	.p2         ({m_btn4_p2, m_btn3_p2, m_btn2_p2, m_btn1_p2, m_up2, m_down2, m_left2, m_right2}),
	.p1_rstick  (rstick_dir),
	.sys_ctl    ({m_start2, m_start1, m_coin2, m_coin1}),
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
	.ce_pix     (ce_pix)
);

wire [8:0] rgb_in = {core_b[7:5], core_g[7:5], core_r[7:5]};

wire hblank = core_hb;
wire vblank = core_vb;
wire hs = core_hs;
wire vs = core_vs;

reg ce_pix_r, ce_pix_rr;
always @(posedge clk_vid) begin ce_pix_r <= ce_pix; ce_pix_rr <= ce_pix_r; end
wire ce_pix_sync = ce_pix_r & ~ce_pix_rr;

wire no_rotate = status[2] | direct_video;
wire rotate_ccw = 0;
wire flip = status[11];

screen_rotate screen_rotate (.*);

arcade_video #(256,9,1) arcade_video
(
	.*,
    .clk_video(clk_vid),
	.RGB_in(rgb_out),
	.ce_pix    (ce_pix_sync),
	.HBlank(hblank),
	.VBlank(vblank),
	.HSync(hs),
	.VSync(vs),
	.fx(status[5:3])
);

assign CLK_VIDEO = clk_vid;
assign AUDIO_L = core_audio;
assign AUDIO_R = core_audio;
assign AUDIO_S = 1'b1;

endmodule
