//  Hitachi HD38880 speech: host command decoder
//  Command protocol from MAME snk6502_a.cpp (Nicola Salmoria, Dan Boris, BSD-3-Clause)

module hd38880_ctrl #(
    parameter GAME = 0            // 0 = Vanguard, 1 = Fantasy (phrase table)
)(
    input  wire        clk,
    input  wire        rst,

    input  wire        wr,        // write strobe, 1 clk wide
    input  wire [5:0]  din,       // {CMV, CTP, SYBS4..SYBS1}

    output reg         start,     // 1-clk pulse: begin phrase playback
    output reg         stop,      // 1-clk pulse: halt playback
    output reg  [3:0]  phrase,    // phrase index 0..15 (valid with start)
    output reg         phrase_ok, // ADSET address matched the table
    output reg  [19:0] adset_addr,// raw 20-bit speech-ROM start address
    output reg  [19:0] end_addr,  // valid together with start

    output reg  [3:0]  int1_cfg,  // [3] tri(1)/impulse(0) excitation
    output reg  [3:0]  int2_cfg,  // [3] 48(1)/96(0) bits per frame
    output reg  [3:0]  syspd      // speed = (syspd+1)/10
);

    localparam [3:0] CMD_ADSET  = 4'd2,
                     CMD_READ   = 4'd3,
                     CMD_INT1   = 4'd4,
                     CMD_INT2   = 4'd6,
                     CMD_SYSPD  = 4'd8,
                     CMD_STOP   = 4'd10,
                     CMD_CONDT  = 4'd11,
                     CMD_START  = 4'd12,
                     CMD_SSTART = 4'd14;

    localparam [2:0] S_IDLE  = 3'd0,
                     S_INT1  = 3'd1,
                     S_INT2  = 3'd2,
                     S_SYSPD = 3'd3,
                     S_ADSET = 3'd4;

    reg [2:0] state;
    reg [2:0] adset_cnt;

    wire        strobe = wr & din[5] & din[4];
    wire [3:0]  nib    = din[3:0];

    function [19:0] table_lookup;
        input [3:0] idx;
        begin
            if (GAME == 0) begin
                case (idx)
                    4'h0: table_lookup = 20'h04000;
                    4'h1: table_lookup = 20'h04325;
                    4'h2: table_lookup = 20'h044a2;
                    4'h3: table_lookup = 20'h045b7;
                    4'h4: table_lookup = 20'h046ee;
                    4'h5: table_lookup = 20'h04838;
                    4'h6: table_lookup = 20'h04984;
                    4'h7: table_lookup = 20'h04b01;
                    4'h8: table_lookup = 20'h04c38;
                    4'h9: table_lookup = 20'h04de6;
                    4'ha: table_lookup = 20'h04f43;
                    4'hb: table_lookup = 20'h05048;
                    4'hc: table_lookup = 20'h05160;
                    4'hd: table_lookup = 20'h05289;
                    4'he: table_lookup = 20'h0539e;
                    4'hf: table_lookup = 20'h054ce;
                endcase
            end else begin
                case (idx)
                    4'h0: table_lookup = 20'h04000;
                    4'h1: table_lookup = 20'h04297;
                    4'h2: table_lookup = 20'h044b6;
                    4'h3: table_lookup = 20'h04682;
                    4'h4: table_lookup = 20'h04927;
                    4'h5: table_lookup = 20'h04be0;
                    4'h6: table_lookup = 20'h04cc2;
                    4'h7: table_lookup = 20'h04e36;
                    4'h8: table_lookup = 20'h05000;
                    4'h9: table_lookup = 20'h05163;
                    4'ha: table_lookup = 20'h052c9;
                    4'hb: table_lookup = 20'h053fd;
                    default: table_lookup = 20'h00000;
                endcase
            end
        end
    endfunction

    function [19:0] end_lookup;
        input [3:0] idx;
        begin
            if (GAME == 0)
                end_lookup = (idx == 4'hf) ? 20'h05605 : table_lookup(idx + 4'd1);
            else
                end_lookup = (idx >= 4'hb) ? 20'h05800 : table_lookup(idx + 4'd1);
        end
    endfunction

    reg [3:0] match_idx;
    reg       match_hit;
    integer i;
    always @* begin
        match_idx = 4'd0;
        match_hit = 1'b0;
        for (i = 0; i < 16; i = i + 1) begin
            if (!match_hit &&
                table_lookup(i[3:0]) != 20'd0 &&
                table_lookup(i[3:0]) == adset_addr) begin
                match_idx = i[3:0];
                match_hit = 1'b1;
            end
        end
    end

    always @(posedge clk) begin
        start <= 1'b0;
        stop  <= 1'b0;

        if (rst) begin
            state      <= S_IDLE;
            adset_cnt  <= 3'd0;
            adset_addr <= 20'd0;
            end_addr   <= 20'hFFFFF;
            int1_cfg   <= 4'd0;
            int2_cfg   <= 4'hf;
            syspd      <= 4'd9;
            phrase     <= 4'd0;
            phrase_ok  <= 1'b0;
        end
        else if (strobe) begin
            case (state)

            S_IDLE: begin
                case (nib)
                    CMD_ADSET: begin
                        state      <= S_ADSET;
                        adset_cnt  <= 3'd0;
                        adset_addr <= 20'd0;
                    end
                    CMD_INT1:  state <= S_INT1;
                    CMD_INT2:  state <= S_INT2;
                    CMD_SYSPD: state <= S_SYSPD;
                    CMD_START: begin
                        phrase    <= match_idx;
                        phrase_ok <= match_hit;
                        end_addr  <= end_lookup(match_idx);
                        if (match_hit)
                            start <= 1'b1;
                    end
                    CMD_STOP:   stop <= 1'b1;
                    CMD_SSTART: ;
                    CMD_READ:   ;
                    CMD_CONDT:  ;
                    4'd0:       ;
                    default:    ;
                endcase
            end

            S_INT1:  begin int1_cfg <= nib; state <= S_IDLE; end
            S_INT2:  begin int2_cfg <= nib; state <= S_IDLE; end
            S_SYSPD: begin syspd    <= nib; state <= S_IDLE; end

            S_ADSET: begin
                adset_addr <= adset_addr | ({16'd0, nib} << (adset_cnt * 4));
                if (adset_cnt == 3'd4)
                    state <= S_IDLE;
                else
                    adset_cnt <= adset_cnt + 3'd1;
            end

            default: state <= S_IDLE;
            endcase
        end
    end

endmodule
