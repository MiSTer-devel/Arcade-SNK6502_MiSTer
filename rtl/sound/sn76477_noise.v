//  SN76477 noise leg as wired on Vanguard / Fantasy (VCO, SLF, one-shot off; mixer = noise)
//  Configuration from MAME snk6502_a.cpp (Nicola Salmoria, Dan Boris, BSD-3-Clause)

module sn76477_noise #(
    parameter integer CLK_HZ    = 11_289_000,
    parameter integer NOISE_HZ  = 3082,   // 3082 = 470k leg, 97493 = 10k leg
    parameter         FILTER_EN = 1'b1,   // 0 when the filter cap is absent (C=0)
    parameter integer AMPLITUDE = 6000
)(
    input  wire        clk,
    input  wire        reset,
    input  wire        pause,
    input  wire        gate,      // ENABLE, active high (level, not edge)
    output reg signed [15:0] audio_out
);

    localparam integer NOISE_DIV = CLK_HZ / NOISE_HZ;   // 3663 @3082Hz, 115 @97493Hz
    reg [15:0] ndiv;
    wire       noise_ce = (ndiv == NOISE_DIV[15:0] - 16'd1);

    always @(posedge clk) begin
        if (reset)        ndiv <= 16'd0;
        else if (pause)   ndiv <= ndiv;
        else if (noise_ce) ndiv <= 16'd0;
        else              ndiv <= ndiv + 16'd1;
    end

    reg [16:0] lfsr;
    always @(posedge clk) begin
        if (reset)                 lfsr <= 17'h1ACE7;
        else if (noise_ce & ~pause) lfsr <= {lfsr[15:0], lfsr[16] ^ lfsr[13]};
    end
    wire noise_bit = lfsr[16];

    localparam integer FILT_DIV = CLK_HZ / 48000;       // 235
    reg [11:0] fdiv;
    wire       filt_ce = (fdiv == FILT_DIV[11:0] - 12'd1);
    always @(posedge clk) begin
        if (reset)        fdiv <= 12'd0;
        else if (pause)   fdiv <= fdiv;
        else if (filt_ce) fdiv <= 12'd0;
        else              fdiv <= fdiv + 12'd1;
    end

    wire signed [15:0] raw = noise_bit ?  $signed(AMPLITUDE[15:0])
                                       : -$signed(AMPLITUDE[15:0]);

    reg signed [15:0] filt;
    always @(posedge clk) begin
        if (reset) begin
            filt      <= 16'sd0;
            audio_out <= 16'sd0;
        end else if (!pause && filt_ce) begin
            filt <= filt + ((raw - filt) >>> 4);
            audio_out <= ~gate ? 16'sd0
                       : (FILTER_EN ? filt : raw);
        end
    end

endmodule
