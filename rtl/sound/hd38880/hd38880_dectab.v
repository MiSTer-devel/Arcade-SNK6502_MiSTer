//=============================================================================
// hd38880_dectab.v
//
// HD38880 decode-ROM lookup: raw unpacked frame codes (from hd38880_unpack.v)
// -> fixed-point synthesis parameters (for parcor_lattice.v).
//
// These are the chip's INTERNAL decode tables (amp/pitch/k1..k10 quantiser
// curves) reverse-engineered from hardware recordings — analogous to a
// TMS5220's built-in energy/pitch/coefficient ROMs. They are not part of any
// game ROM dump; there is no physical file to load. Source: hd38880_tables_abs.json
// (see ../hd38880/README.md section 2 "Quantiser recovery").
//
// Fixed-point conventions (per README section 3):
//   k1..k10 -> signed Q1.9 (10-bit, x512), matches parcor_lattice.v k_in[]
//   amp     -> unsigned 8-bit (x255, table is already 0.0-1.0 normalized),
//              matches parcor_lattice.v amp_in
//   pitch   -> unsigned 8-bit, period in samples (16-98), matches pitch_in;
//              code 0 always means "unvoiced" and bypasses the table, exactly
//              as hd38880_decode.py's params() does (`if not F['pitch']: per=0`)
//
// k1 (7-bit raw code, amp/k2 likewise) is looked up via the top bits of the
// raw code directly against the recovered 16-entry table (bin index = top 4
// bits, dropping the low 3/1 bits) rather than the golden Python decoder's
// np.interp — a direct table lookup, no interpolation logic. This matches the
// package's own resource estimate ("64+64+16+16+64 entries = trivial
// BRAM/LUTROM") and the package is explicit that the decode curves are
// approximate/not bit-exact regardless (README section 5 caveats), so the
// small extra quantisation from skipping interpolation is within that same
// margin. amp/pitch use the full 6-bit code against the full 64-entry table,
// so those two are an exact match to the reference tables.
//=============================================================================

module hd38880_dectab (
    input  wire [5:0]        amp_code,
    input  wire [5:0]        pitch_code,
    input  wire [6:0]        k1_code,
    input  wire [4:0]        k2_code,
    input  wire [2:0]        k3_code,
    input  wire [2:0]        k4_code,
    input  wire [2:0]        k5_code,
    input  wire [2:0]        k6_code,
    input  wire [2:0]        k7_code,
    input  wire [2:0]        k8_code,
    input  wire [2:0]        k9_code,
    input  wire [2:0]        k10_code,

    output reg  [7:0]        amp_out,
    output reg  [7:0]        pitch_out,
    output reg  signed [9:0] k1_out,
    output reg  signed [9:0] k2_out,
    output reg  signed [9:0] k3_out,
    output reg  signed [9:0] k4_out,
    output reg  signed [9:0] k5_out,
    output reg  signed [9:0] k6_out,
    output reg  signed [9:0] k7_out,
    output reg  signed [9:0] k8_out,
    output reg  signed [9:0] k9_out,
    output reg  signed [9:0] k10_out
);

    // amp_table[64]: hd38880_tables_abs.json "amp_table", x255
    reg [7:0] amp_table [0:63];
    initial begin
        amp_table[  0]=8'd0;   amp_table[  1]=8'd39;  amp_table[  2]=8'd40;  amp_table[  3]=8'd41;
        amp_table[  4]=8'd41;  amp_table[  5]=8'd41;  amp_table[  6]=8'd42;  amp_table[  7]=8'd42;
        amp_table[  8]=8'd42;  amp_table[  9]=8'd42;  amp_table[ 10]=8'd42;  amp_table[ 11]=8'd43;
        amp_table[ 12]=8'd45;  amp_table[ 13]=8'd45;  amp_table[ 14]=8'd45;  amp_table[ 15]=8'd48;
        amp_table[ 16]=8'd55;  amp_table[ 17]=8'd55;  amp_table[ 18]=8'd55;  amp_table[ 19]=8'd55;
        amp_table[ 20]=8'd63;  amp_table[ 21]=8'd64;  amp_table[ 22]=8'd64;  amp_table[ 23]=8'd64;
        amp_table[ 24]=8'd64;  amp_table[ 25]=8'd71;  amp_table[ 26]=8'd71;  amp_table[ 27]=8'd92;
        amp_table[ 28]=8'd92;  amp_table[ 29]=8'd92;  amp_table[ 30]=8'd92;  amp_table[ 31]=8'd92;
        amp_table[ 32]=8'd129; amp_table[ 33]=8'd139; amp_table[ 34]=8'd139; amp_table[ 35]=8'd139;
        amp_table[ 36]=8'd139; amp_table[ 37]=8'd139; amp_table[ 38]=8'd152; amp_table[ 39]=8'd160;
        amp_table[ 40]=8'd160; amp_table[ 41]=8'd160; amp_table[ 42]=8'd160; amp_table[ 43]=8'd160;
        amp_table[ 44]=8'd188; amp_table[ 45]=8'd188; amp_table[ 46]=8'd193; amp_table[ 47]=8'd194;
        amp_table[ 48]=8'd219; amp_table[ 49]=8'd219; amp_table[ 50]=8'd219; amp_table[ 51]=8'd219;
        amp_table[ 52]=8'd236; amp_table[ 53]=8'd236; amp_table[ 54]=8'd236; amp_table[ 55]=8'd236;
        amp_table[ 56]=8'd255; amp_table[ 57]=8'd255; amp_table[ 58]=8'd255; amp_table[ 59]=8'd255;
        amp_table[ 60]=8'd255; amp_table[ 61]=8'd255; amp_table[ 62]=8'd255; amp_table[ 63]=8'd255;
    end

    // pitch_table_full[64]: hd38880_tables_abs.json "pitch_table_full", samples
    // (code 0 is special-cased to 0/unvoiced below and never reads this table)
    reg [7:0] pitch_table [0:63];
    initial begin
        pitch_table[  0]=8'd16; pitch_table[  1]=8'd16; pitch_table[  2]=8'd17; pitch_table[  3]=8'd18;
        pitch_table[  4]=8'd19; pitch_table[  5]=8'd20; pitch_table[  6]=8'd20; pitch_table[  7]=8'd22;
        pitch_table[  8]=8'd23; pitch_table[  9]=8'd24; pitch_table[ 10]=8'd24; pitch_table[ 11]=8'd26;
        pitch_table[ 12]=8'd27; pitch_table[ 13]=8'd28; pitch_table[ 14]=8'd28; pitch_table[ 15]=8'd30;
        pitch_table[ 16]=8'd31; pitch_table[ 17]=8'd31; pitch_table[ 18]=8'd32; pitch_table[ 19]=8'd34;
        pitch_table[ 20]=8'd35; pitch_table[ 21]=8'd35; pitch_table[ 22]=8'd35; pitch_table[ 23]=8'd38;
        pitch_table[ 24]=8'd39; pitch_table[ 25]=8'd40; pitch_table[ 26]=8'd41; pitch_table[ 27]=8'd41;
        pitch_table[ 28]=8'd43; pitch_table[ 29]=8'd43; pitch_table[ 30]=8'd45; pitch_table[ 31]=8'd45;
        pitch_table[ 32]=8'd46; pitch_table[ 33]=8'd47; pitch_table[ 34]=8'd48; pitch_table[ 35]=8'd48;
        pitch_table[ 36]=8'd52; pitch_table[ 37]=8'd54; pitch_table[ 38]=8'd56; pitch_table[ 39]=8'd58;
        pitch_table[ 40]=8'd60; pitch_table[ 41]=8'd62; pitch_table[ 42]=8'd64; pitch_table[ 43]=8'd65;
        pitch_table[ 44]=8'd68; pitch_table[ 45]=8'd70; pitch_table[ 46]=8'd72; pitch_table[ 47]=8'd74;
        pitch_table[ 48]=8'd74; pitch_table[ 49]=8'd76; pitch_table[ 50]=8'd78; pitch_table[ 51]=8'd81;
        pitch_table[ 52]=8'd83; pitch_table[ 53]=8'd83; pitch_table[ 54]=8'd85; pitch_table[ 55]=8'd85;
        pitch_table[ 56]=8'd85; pitch_table[ 57]=8'd94; pitch_table[ 58]=8'd94; pitch_table[ 59]=8'd98;
        pitch_table[ 60]=8'd98; pitch_table[ 61]=8'd98; pitch_table[ 62]=8'd98; pitch_table[ 63]=8'd98;
    end

    // k1_bins[16] / k2_bins[16]: x512 (Q1.9)
    reg signed [9:0] k1_table [0:15];
    reg signed [9:0] k2_table [0:15];
    initial begin
        k1_table[ 0]=-10'sd103; k1_table[ 1]=-10'sd145; k1_table[ 2]=-10'sd155; k1_table[ 3]=-10'sd155;
        k1_table[ 4]=-10'sd197; k1_table[ 5]=-10'sd259; k1_table[ 6]=-10'sd290; k1_table[ 7]=-10'sd321;
        k1_table[ 8]=-10'sd362; k1_table[ 9]=-10'sd393; k1_table[10]=-10'sd424; k1_table[11]=-10'sd435;
        k1_table[12]=-10'sd455; k1_table[13]=-10'sd466; k1_table[14]=-10'sd476; k1_table[15]=-10'sd476;

        k2_table[ 0]= 10'sd352; k2_table[ 1]= 10'sd352; k2_table[ 2]= 10'sd352; k2_table[ 3]= 10'sd352;
        k2_table[ 4]= 10'sd341; k2_table[ 5]= 10'sd341; k2_table[ 6]= 10'sd331; k2_table[ 7]= 10'sd331;
        k2_table[ 8]= 10'sd310; k2_table[ 9]= 10'sd259; k2_table[10]= 10'sd217; k2_table[11]= 10'sd197;
        k2_table[12]= 10'sd103; k2_table[13]= 10'sd93;  k2_table[14]=-10'sd31;  k2_table[15]=-10'sd93;
    end

    // k3..k10[8]: x512 (Q1.9), direct 3-bit code index
    reg signed [9:0] k3_table  [0:7];
    reg signed [9:0] k4_table  [0:7];
    reg signed [9:0] k5_table  [0:7];
    reg signed [9:0] k6_table  [0:7];
    reg signed [9:0] k7_table  [0:7];
    reg signed [9:0] k8_table  [0:7];
    reg signed [9:0] k9_table  [0:7];
    reg signed [9:0] k10_table [0:7];
    initial begin
        k3_table[0]= 10'sd83;  k3_table[1]= 10'sd72;  k3_table[2]= 10'sd21;  k3_table[3]= 10'sd10;
        k3_table[4]= 10'sd0;   k3_table[5]=-10'sd62;  k3_table[6]=-10'sd124; k3_table[7]=-10'sd124;

        k4_table[0]= 10'sd217; k4_table[1]= 10'sd217; k4_table[2]= 10'sd145; k4_table[3]= 10'sd114;
        k4_table[4]= 10'sd114; k4_table[5]= 10'sd103; k4_table[6]= 10'sd103; k4_table[7]= 10'sd103;

        k5_table[0]= 10'sd145; k5_table[1]= 10'sd93;  k5_table[2]= 10'sd72;  k5_table[3]= 10'sd21;
        k5_table[4]=-10'sd52;  k5_table[5]=-10'sd52;  k5_table[6]=-10'sd114; k5_table[7]=-10'sd166;

        k6_table[0]= 10'sd207; k6_table[1]= 10'sd176; k6_table[2]= 10'sd135; k6_table[3]= 10'sd135;
        k6_table[4]= 10'sd114; k6_table[5]= 10'sd93;  k6_table[6]= 10'sd93;  k6_table[7]= 10'sd93;

        k7_table[0]= 10'sd135; k7_table[1]= 10'sd62;  k7_table[2]= 10'sd52;  k7_table[3]= 10'sd31;
        k7_table[4]= 10'sd31;  k7_table[5]= 10'sd10;  k7_table[6]= 10'sd10;  k7_table[7]=-10'sd10;

        k8_table[0]= 10'sd155; k8_table[1]= 10'sd145; k8_table[2]= 10'sd124; k8_table[3]= 10'sd103;
        k8_table[4]= 10'sd72;  k8_table[5]= 10'sd72;  k8_table[6]= 10'sd72;  k8_table[7]= 10'sd52;

        k9_table[0]= 10'sd93;  k9_table[1]= 10'sd93;  k9_table[2]= 10'sd72;  k9_table[3]= 10'sd52;
        k9_table[4]= 10'sd52;  k9_table[5]= 10'sd21;  k9_table[6]= 10'sd21;  k9_table[7]= 10'sd21;

        k10_table[0]=10'sd135; k10_table[1]=10'sd135; k10_table[2]=10'sd83;  k10_table[3]=10'sd72;
        k10_table[4]=10'sd52;  k10_table[5]=10'sd41;  k10_table[6]=10'sd21;  k10_table[7]=10'sd21;
    end

    always @* begin
        amp_out   = amp_table[amp_code];
        pitch_out = (pitch_code == 6'd0) ? 8'd0 : pitch_table[pitch_code];
        k1_out    = k1_table[k1_code[6:3]];
        k2_out    = k2_table[k2_code[4:1]];
        k3_out    = k3_table[k3_code];
        k4_out    = k4_table[k4_code];
        k5_out    = k5_table[k5_code];
        k6_out    = k6_table[k6_code];
        k7_out    = k7_table[k7_code];
        k8_out    = k8_table[k8_code];
        k9_out    = k9_table[k9_code];
        k10_out   = k10_table[k10_code];
    end

endmodule
