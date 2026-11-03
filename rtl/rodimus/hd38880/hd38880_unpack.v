//  SPDX-License-Identifier: BSD-3-Clause
//  Copyright (C) 2026 Rodimus
//  HD38880 speech engine, written from analysis of the speech data and the SK-6 board (no third-party code).
//  HD38880 speech-ROM frame unpacker
//
//  Frame format (LSB-first within each byte, fields LSB-first). Normal frame = 49 bits:
//    bits  0-5   Amp   (6)  0 = silence frame (these 6 bits only), 63 = stop (end of phrase), else amplitude code
//    bit   6     stop-assist flag (Fantasy terminators)
//    bits  7-12  Pitch (6)  0 = unvoiced (noise source), else period code
//    bits 13-19  k1    (7)
//    bits 20-24  k2    (5)
//    bits 25-48  k3..k10 (3 each)

module hd38880_unpack (
    input  wire        clk,
    input  wire        rst,

    input  wire        start,
    input  wire [19:0] start_addr,
    input  wire [19:0] end_addr,
    input  wire        abort,
    output reg         done,

    output reg  [19:0] rom_addr,
    input  wire [7:0]  rom_data,
    output reg         rom_rd,
    input  wire        rom_valid,

    output reg         frame_valid,
    input  wire        frame_ack,
    output reg         f_silent,
    output reg  [5:0]  f_amp,
    output reg  [5:0]  f_pitch,        // raw 6-bit pitch code (0 = unvoiced)
    output reg  [6:0]  f_k1,
    output reg  [4:0]  f_k2,
    output reg  [2:0]  f_k3, f_k4, f_k5, f_k6, f_k7, f_k8, f_k9, f_k10
);

    reg [63:0] resv;
    reg [6:0]  nbits;
    reg        fetch_skip;

    wire [5:0] pk_amp = resv[5:0];

    localparam [2:0] S_IDLE=0, S_FILL=1, S_HDR=2, S_BODY=3, S_WAIT=4, S_DONE=5;
    reg [2:0] state;

    always @(posedge clk) begin
        rom_rd <= 1'b0;
        done   <= 1'b0;

        if (rst) begin
            state <= S_IDLE; frame_valid <= 1'b0; nbits <= 0;
            fetch_skip <= 1'b0;
        end
        else if (start) begin
            rom_addr <= start_addr;
            nbits    <= 0;
            resv     <= 64'd0;
            frame_valid <= 1'b0;
            state    <= S_FILL;
            // a fetch in flight returns a byte of the old address stream: discard it
            fetch_skip <= rom_rd;
        end
        else if (abort) begin
            state <= S_DONE; frame_valid <= 1'b0;
        end
        else case (state)

        S_IDLE: ;

        S_FILL: begin
            if (nbits >= 7'd49)
                state <= S_HDR;
            else if (rom_valid) begin
                if (fetch_skip)
                    fetch_skip <= 1'b0;
                else begin
                    resv  <= resv | ({56'd0, rom_data} << nbits);
                    nbits <= nbits + 7'd8;
                    rom_addr <= rom_addr + 20'd1;
                end
            end
            else if (rom_addr >= end_addr)
                state <= S_DONE;
            else if (!rom_rd)
                rom_rd <= 1'b1;
        end

        S_HDR: begin
            if (pk_amp == 6'd63) begin
                state <= S_DONE;
            end
            else if (pk_amp == 6'd0) begin
                f_silent <= 1'b1; f_amp <= 6'd0; f_pitch <= 6'd0;
                resv  <= resv >> 6;
                nbits <= nbits - 7'd6;
                frame_valid <= 1'b1;
                state <= S_WAIT;
            end
            else begin
                f_silent <= 1'b0;
                f_amp    <= resv[5:0];
                f_pitch  <= resv[12:7];
                f_k1     <= resv[19:13];
                f_k2     <= resv[24:20];
                f_k3     <= resv[27:25];
                f_k4     <= resv[30:28];
                f_k5     <= resv[33:31];
                f_k6     <= resv[36:34];
                f_k7     <= resv[39:37];
                f_k8     <= resv[42:40];
                f_k9     <= resv[45:43];
                f_k10    <= resv[48:46];
                resv  <= resv >> 49;
                nbits <= nbits - 7'd49;
                frame_valid <= 1'b1;
                state <= S_WAIT;
            end
        end

        S_WAIT: if (frame_ack) begin
            frame_valid <= 1'b0;
            state <= S_FILL;
        end

        S_DONE: begin
            done  <= 1'b1;
            state <= S_IDLE;
        end

        default: state <= S_IDLE;
        endcase
    end

endmodule

