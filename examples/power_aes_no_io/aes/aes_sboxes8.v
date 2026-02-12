module aes_sboxes8(
    input wire [63:0] sbb_i,   //input to SBOX
    input wire dec_r,           //1 for decrypt, 0 for encrypt
    output wire [63:0] sbb_o   //output of SBOX
);
`define SBOX_GF_NO
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
`else
    aes_sbox_lut sbox_inst00(.byte_in(sbb_i[  7:  0]), .dec(dec_r), .byte_out(sbb_o[  7:  0]));
    aes_sbox_lut sbox_inst01(.byte_in(sbb_i[ 15:  8]), .dec(dec_r), .byte_out(sbb_o[ 15:  8]));
    aes_sbox_lut sbox_inst02(.byte_in(sbb_i[ 23: 16]), .dec(dec_r), .byte_out(sbb_o[ 23: 16]));
    aes_sbox_lut sbox_inst03(.byte_in(sbb_i[ 31: 24]), .dec(dec_r), .byte_out(sbb_o[ 31: 24]));
    aes_sbox_lut sbox_inst04(.byte_in(sbb_i[ 39: 32]), .dec(dec_r), .byte_out(sbb_o[ 39: 32]));
    aes_sbox_lut sbox_inst05(.byte_in(sbb_i[ 47: 40]), .dec(dec_r), .byte_out(sbb_o[ 47: 40]));
    aes_sbox_lut sbox_inst06(.byte_in(sbb_i[ 55: 48]), .dec(dec_r), .byte_out(sbb_o[ 55: 48]));
    aes_sbox_lut sbox_inst07(.byte_in(sbb_i[ 63: 56]), .dec(dec_r), .byte_out(sbb_o[ 63: 56]));
`endif


endmodule