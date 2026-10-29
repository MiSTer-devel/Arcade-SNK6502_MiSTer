//  SNK6502 bomb / explosion one-shot noise
//  Based on MAME snk6502_a.cpp (Nicola Salmoria, Dan Boris, BSD-3-Clause)

module snk6502_noise (
    input  wire        clk,       // 11.289 MHz master clock
    input  wire        reset,
    input  wire        pause,     // halt in-flight one-shot on pause/OSD
    input  wire        trigger,   // rising edge fires one-shot
    output reg  signed [15:0] audio_out
);

    localparam DECAY_LEN = 19'd293514;

    reg [18:0] decay_cnt;
    reg        trig_prev;

    wire trig_edge = trigger & ~trig_prev;

    reg [15:0] lfsr;
    wire lfsr_feedback = lfsr[0];

    always @(posedge clk) begin
        if (reset)
            lfsr <= 16'hACE1;
        else
            lfsr <= {lfsr_feedback, lfsr[15:1]} ^
                    (lfsr_feedback ? 16'hB400 : 16'h0000);
    end

    wire [3:0] envelope = decay_cnt[18:15];

    wire signed [15:0] noise_sig = {lfsr[11:0], 4'b0};

    always @(posedge clk) begin
        if (reset) begin
            decay_cnt <= 0;
            trig_prev <= 0;
            audio_out <= 0;
        end else if (!pause) begin
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

endmodule