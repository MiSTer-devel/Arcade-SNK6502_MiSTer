//============================================================================
//  snk6502_voice_lpf.sv - SK-6 voice board output filter: two unity-gain Sallen-Key low-pass stages (22K / 22K,
//  2.2n / 1n: f0 4.88 kHz, Q 0.74), as two Q16 biquads at clk / 235 (48.04 kHz) sharing one multiplier; states carry
//  8 fraction bits so the output settles to exactly 0 (no truncation limit cycle).
//  Copyright (C) 2026 Rodimus
//============================================================================

module snk6502_voice_lpf
(
    input  logic               clk,            // clk_master 11.2896 MHz
    input  logic               reset,
    input  logic signed [15:0] din,
    output logic signed [15:0] dout
);

localparam logic signed [17:0] B0 = 18'sd4352, B1 = 18'sd8705, B2 = 18'sd4352, NA1 = 18'sd76862, NA2 = -18'sd28736;

logic        [7:0]  div;
logic        [3:0]  step;
logic signed [27:0] x0, x1a, x2a, y1a, y2a, y1b, y2b, ya;
logic signed [53:0] acc;
logic signed [17:0] c;
logic signed [27:0] d;

always_comb begin
    case (step)
        4'd1:    begin c = B0;  d = x0;  end
        4'd2:    begin c = B1;  d = x1a; end
        4'd3:    begin c = B2;  d = x2a; end
        4'd4:    begin c = NA1; d = y1a; end
        4'd5:    begin c = NA2; d = y2a; end
        4'd7:    begin c = B0;  d = ya;  end
        4'd8:    begin c = B1;  d = y1a; end
        4'd9:    begin c = B2;  d = y2a; end
        4'd10:   begin c = NA1; d = y1b; end
        4'd11:   begin c = NA2; d = y2b; end
        default: begin c = 18'sd0; d = 28'sd0; end
    endcase
end

wire signed [45:0] prod = c * d;
wire signed [53:0] prod_x = {{8{prod[45]}}, prod};
wire signed [37:0] acc_q = acc[53:16];
wire signed [27:0] acc_s28 = (acc_q > 38'sd134217727) ? 28'sd134217727 : (acc_q < -38'sd134217728) ? -28'sd134217728 : acc_q[27:0];
wire signed [28:0] out_r = $signed({acc_s28[27], acc_s28}) + 29'sd128;
wire signed [20:0] out_q = out_r[28:8];
wire signed [15:0] out_s16 = (out_q > 21'sd32767) ? 16'sd32767 : (out_q < -21'sd32768) ? -16'sd32768 : out_q[15:0];

always_ff @(posedge clk) begin
    if (reset) begin
        div <= 8'd0; step <= 4'd0; acc <= 54'sd0;
        x0 <= 28'sd0; x1a <= 28'sd0; x2a <= 28'sd0; y1a <= 28'sd0; y2a <= 28'sd0; y1b <= 28'sd0; y2b <= 28'sd0;
        ya <= 28'sd0; dout <= 16'sd0;
    end
    else begin
        div <= (div == 8'd234) ? 8'd0 : div + 8'd1;
        if (div == 8'd234) begin
            x0   <= {{4{din[15]}}, din, 8'd0};
            step <= 4'd1;
        end
        else if (step != 4'd0) begin
            step <= (step == 4'd12) ? 4'd0 : step + 4'd1;
            case (step)
                4'd1, 4'd7: acc <= prod_x;
                4'd6:       ya  <= acc_s28;
                4'd12: begin
                    dout <= out_s16;
                    y2b  <= y1b;  y1b <= acc_s28;
                    y2a  <= y1a;  y1a <= ya;
                    x2a  <= x1a;  x1a <= x0;
                end
                default:    acc <= acc + prod_x;
            endcase
        end
    end
end

endmodule
