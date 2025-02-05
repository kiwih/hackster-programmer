module aes_sboxes(
    input wire [127:0] sbb_i,   //input to SBOX
    input wire dec_r,           //1 for decrypt, 0 for encrypt
    output wire [127:0] sbb_o   //output of SBOX
);
`define SBOX_GF
// NEWAE mod: GF or LUT sboxes
`ifdef SBOX_GF
    aes_sbox sbox_inst00(.U(sbb_i[  7:  0]), .dec(dec_r), .S(sbb_o[  7:  0]));
    aes_sbox sbox_inst01(.U(sbb_i[ 15:  8]), .dec(dec_r), .S(sbb_o[ 15:  8]));
    aes_sbox sbox_inst02(.U(sbb_i[ 23: 16]), .dec(dec_r), .S(sbb_o[ 23: 16]));
    aes_sbox sbox_inst03(.U(sbb_i[ 31: 24]), .dec(dec_r), .S(sbb_o[ 31: 24]));
    aes_sbox sbox_inst04(.U(sbb_i[ 39: 32]), .dec(dec_r), .S(sbb_o[ 39: 32]));
    aes_sbox sbox_inst05(.U(sbb_i[ 47: 40]), .dec(dec_r), .S(sbb_o[ 47: 40]));
    aes_sbox sbox_inst06(.U(sbb_i[ 55: 48]), .dec(dec_r), .S(sbb_o[ 55: 48]));
    aes_sbox sbox_inst07(.U(sbb_i[ 63: 56]), .dec(dec_r), .S(sbb_o[ 63: 56]));
    aes_sbox sbox_inst08(.U(sbb_i[ 71: 64]), .dec(dec_r), .S(sbb_o[ 71: 64]));
    aes_sbox sbox_inst09(.U(sbb_i[ 79: 72]), .dec(dec_r), .S(sbb_o[ 79: 72]));
    aes_sbox sbox_inst10(.U(sbb_i[ 87: 80]), .dec(dec_r), .S(sbb_o[ 87: 80]));
    aes_sbox sbox_inst11(.U(sbb_i[ 95: 88]), .dec(dec_r), .S(sbb_o[ 95: 88]));
    aes_sbox sbox_inst12(.U(sbb_i[103: 96]), .dec(dec_r), .S(sbb_o[103: 96]));
    aes_sbox sbox_inst13(.U(sbb_i[111:104]), .dec(dec_r), .S(sbb_o[111:104]));
    aes_sbox sbox_inst14(.U(sbb_i[119:112]), .dec(dec_r), .S(sbb_o[119:112]));
    aes_sbox sbox_inst15(.U(sbb_i[127:120]), .dec(dec_r), .S(sbb_o[127:120]));
`else
    aes_sbox_lut sbox_inst00(.byte_in(sbb_i[  7:  0]), .dec(dec_r), .byte_out(sbb_o[  7:  0]));
    aes_sbox_lut sbox_inst01(.byte_in(sbb_i[ 15:  8]), .dec(dec_r), .byte_out(sbb_o[ 15:  8]));
    aes_sbox_lut sbox_inst02(.byte_in(sbb_i[ 23: 16]), .dec(dec_r), .byte_out(sbb_o[ 23: 16]));
    aes_sbox_lut sbox_inst03(.byte_in(sbb_i[ 31: 24]), .dec(dec_r), .byte_out(sbb_o[ 31: 24]));
    aes_sbox_lut sbox_inst04(.byte_in(sbb_i[ 39: 32]), .dec(dec_r), .byte_out(sbb_o[ 39: 32]));
    aes_sbox_lut sbox_inst05(.byte_in(sbb_i[ 47: 40]), .dec(dec_r), .byte_out(sbb_o[ 47: 40]));
    aes_sbox_lut sbox_inst06(.byte_in(sbb_i[ 55: 48]), .dec(dec_r), .byte_out(sbb_o[ 55: 48]));
    aes_sbox_lut sbox_inst07(.byte_in(sbb_i[ 63: 56]), .dec(dec_r), .byte_out(sbb_o[ 63: 56]));
    aes_sbox_lut sbox_inst08(.byte_in(sbb_i[ 71: 64]), .dec(dec_r), .byte_out(sbb_o[ 71: 64]));
    aes_sbox_lut sbox_inst09(.byte_in(sbb_i[ 79: 72]), .dec(dec_r), .byte_out(sbb_o[ 79: 72]));
    aes_sbox_lut sbox_inst10(.byte_in(sbb_i[ 87: 80]), .dec(dec_r), .byte_out(sbb_o[ 87: 80]));
    aes_sbox_lut sbox_inst11(.byte_in(sbb_i[ 95: 88]), .dec(dec_r), .byte_out(sbb_o[ 95: 88]));
    aes_sbox_lut sbox_inst12(.byte_in(sbb_i[103: 96]), .dec(dec_r), .byte_out(sbb_o[103: 96]));
    aes_sbox_lut sbox_inst13(.byte_in(sbb_i[111:104]), .dec(dec_r), .byte_out(sbb_o[111:104]));
    aes_sbox_lut sbox_inst14(.byte_in(sbb_i[119:112]), .dec(dec_r), .byte_out(sbb_o[119:112]));
    aes_sbox_lut sbox_inst15(.byte_in(sbb_i[127:120]), .dec(dec_r), .byte_out(sbb_o[127:120]));
`endif


endmodule