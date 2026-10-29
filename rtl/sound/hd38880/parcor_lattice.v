//  PARCOR lattice speech synthesizer (Hitachi HD38880 architecture)
//  After Hitachi Hyoron Vol.63 No.12 (Dec 1981), "Speech Synthesis LSIs"

module parcor_lattice #(
    parameter CLK_HZ      = 12_000_000,
    parameter SAMPLE_HZ   = 8_000,
    parameter ALPHA_Q9    = 11'sd508      // 0.992 * 512 = 507.9
)(
    input  wire               clk,
    input  wire               rst,
    input  wire               pause,        // freeze sample-rate divider on MiSTer OSD halt

    // synthesis path. Reassembled into a local k_in[] array immediately below
    input  wire signed [9:0]  k1_in, k2_in, k3_in, k4_in, k5_in,
                               k6_in, k7_in, k8_in, k9_in, k10_in,
    input  wire        [7:0]  amp_in,       // linear amplitude (post decode ROM)
    input  wire        [7:0]  pitch_in,     // pitch period in samples; 0 = unvoiced
    input  wire               frame_we,     // 1-clk pulse: latch new frame

    input  wire               tri_src,      // 1 = triangular, 0 = impulse
    input  wire               loss_en,      // 1 = apply alpha to reflected wave
    input  wire               ten_stage,    // 1 = 10 stages, 0 = 8 stages
    input  wire        [7:0]  ext_pitch,    // EXTP A/B derived pitch offset
    input  wire               ext_pitch_en,

    output reg  signed [14:0] audio_out,
    output reg                audio_stb     // 1-clk pulse at each new sample
);

    wire signed [9:0] k_in [0:9];
    assign k_in[0]=k1_in; assign k_in[1]=k2_in; assign k_in[2]=k3_in; assign k_in[3]=k4_in;
    assign k_in[4]=k5_in; assign k_in[5]=k6_in; assign k_in[6]=k7_in; assign k_in[7]=k8_in;
    assign k_in[8]=k9_in; assign k_in[9]=k10_in;

    localparam integer DIV = CLK_HZ / SAMPLE_HZ;   // clocks per audio sample

    localparam integer SPF     = (SAMPLE_HZ * 20) / 1000;  // samples per 20 ms frame
    localparam integer SUBSTEP = SPF / 8;

    reg signed [9:0] k_tgt  [0:9];
    reg signed [9:0] k_cur  [0:9];
    reg signed [10:0] k_step [0:9];
    reg        [7:0] amp_tgt, amp_cur;
    reg        [7:0] pitch_tgt, pitch_cur;

    reg [9:0] samp_cnt;
    reg [3:0] interp_idx;

    integer n;

    reg [15:0] div_cnt;
    wire       sample_tick = (div_cnt == DIV-1);

    always @(posedge clk) begin
        if (rst) div_cnt <= 0;
        else if (pause) div_cnt <= div_cnt;
        else     div_cnt <= sample_tick ? 16'd0 : div_cnt + 16'd1;
    end

    reg  [7:0]  pitch_cnt;
    reg  [15:0] lfsr;
    wire        voiced = (pitch_cur != 8'd0);
    wire [7:0]  pitch_eff = ext_pitch_en ? ext_pitch : pitch_cur;

    reg signed [14:0] excite;

    wire [7:0] tri_len = 8'd8;

    wire [10:0] amp_ugain = {3'd0, amp_cur} + {5'd0, amp_cur[7:2]} + {7'd0, amp_cur[7:4]};

    always @(posedge clk) begin
        if (rst) begin
            pitch_cnt <= 8'd0;
            lfsr      <= 16'hACE1;
            excite    <= 15'sd0;
        end else if (sample_tick) begin
            lfsr <= {lfsr[14:0], lfsr[15]^lfsr[13]^lfsr[12]^lfsr[10]};

            if (!voiced) begin
                excite <= lfsr[0] ?  $signed({4'd0, amp_ugain})
                                  : -$signed({4'd0, amp_ugain});
            end else begin
                if (pitch_cnt >= pitch_eff - 1) pitch_cnt <= 8'd0;
                else                            pitch_cnt <= pitch_cnt + 8'd1;

                begin
                    excite <= (pitch_cnt == 8'd0)
                        ? ($signed({4'd0, amp_cur, 3'd0}) - $signed({6'd0, amp_cur, 1'd0}))
                          + (lfsr[0] ?  $signed({11'd0, amp_cur[7:4]})
                                     : -$signed({11'd0, amp_cur[7:4]}))
                        : (lfsr[0] ?  $signed({11'd0, amp_cur[7:4]})
                                   : -$signed({11'd0, amp_cur[7:4]}));
                end
            end
        end
    end

    reg signed [14:0] b_delay [0:9];
    reg signed [14:0] f_val;
    reg signed [14:0] b_new  [0:9];

    reg  [4:0] stage;
    reg  [1:0] phase;
    reg        busy;

    wire signed [9:0]  k_now  = k_cur[stage-1];
    wire signed [14:0] b_raw  = b_delay[stage-1];

    wire signed [25:0] b_loss_p = b_raw * (loss_en ? ALPHA_Q9 : 11'sd512);
    wire signed [14:0] b_loss   = b_loss_p >>> 9;

    wire signed [24:0] p_kb = k_now * b_loss;
    wire signed [24:0] p_kf = k_now * f_val;

    wire [4:0] top_stage = ten_stage ? 5'd10 : 5'd8;

    always @(posedge clk) begin
        audio_stb <= 1'b0;

        if (rst) begin
            busy  <= 1'b0;
            stage <= 5'd0;
            phase <= 2'd0;
            f_val <= 15'sd0;
            for (n = 0; n < 10; n = n + 1) begin
                b_delay[n] <= 15'sd0;
                b_new[n]   <= 15'sd0;
            end
            audio_out <= 15'sd0;
        end
        else if (sample_tick) begin
            f_val <= excite;
            stage <= top_stage;
            phase <= 2'd0;
            busy  <= 1'b1;
        end
        else if (busy) begin
            case (phase)
            2'd0: begin
                f_val <= f_val - (p_kb >>> 9);
                phase <= 2'd1;
            end
            2'd1: begin
                b_new[stage-1] <= b_loss + (p_kf >>> 9);
                if (stage == 5'd1) begin
                    busy      <= 1'b0;
                    audio_out <= f_val;
                    audio_stb <= 1'b1;
                    b_delay[0] <= f_val;
                    b_delay[1] <= b_loss + (p_kf >>> 9);
                    for (n = 2; n < 10; n = n + 1)
                        b_delay[n] <= b_new[n-1];
                end else begin
                    stage <= stage - 5'd1;
                end
                phase <= 2'd0;
            end
            default: phase <= 2'd0;
            endcase
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            samp_cnt   <= 10'd0;
            interp_idx <= 4'd0;
            amp_cur    <= 8'd0;
            amp_tgt    <= 8'd0;
            pitch_cur  <= 8'd0;
            pitch_tgt  <= 8'd0;
            for (n = 0; n < 10; n = n + 1) begin
                k_cur[n]  <= 10'sd0;
                k_tgt[n]  <= 10'sd0;
                k_step[n] <= 11'sd0;
            end
        end
        else begin
            if (frame_we) begin
                amp_cur   <= amp_in;
                amp_tgt   <= amp_in;
                pitch_cur <= pitch_in;
                pitch_tgt <= pitch_in;

                for (n = 0; n < 10; n = n + 1) k_tgt[n] <= k_in[n];

                if ((pitch_in == 8'd0) != (pitch_cur == 8'd0)) begin
                    for (n = 0; n < 10; n = n + 1) begin
                        k_cur[n]  <= k_in[n];
                        k_step[n] <= 11'sd0;
                    end
                end
                else begin
                    for (n = 0; n < 10; n = n + 1)
                        k_step[n] <= (k_in[n] - k_cur[n]) >>> 3;
                end

                samp_cnt   <= 10'd0;
                interp_idx <= 4'd0;
            end
            else if (sample_tick) begin
                samp_cnt <= samp_cnt + 10'd1;
                if (samp_cnt % SUBSTEP == 0 && interp_idx < 4'd8) begin
                    if (interp_idx == 4'd7) begin
                        for (n = 0; n < 10; n = n + 1) k_cur[n] <= k_tgt[n];
                    end
                    else begin
                        for (n = 0; n < 10; n = n + 1)
                            k_cur[n] <= k_cur[n] + k_step[n];
                    end
                    interp_idx <= interp_idx + 4'd1;
                end
            end
        end
    end

endmodule
