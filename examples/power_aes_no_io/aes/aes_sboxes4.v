module aes_sboxes4(
    input wire [31:0] sbb_i,   //input to SBOX
    input wire dec_r,           //1 for decrypt, 0 for encrypt
    output wire [31:0] sbb_o   //output of SBOX
);
`define SBOX_GF_NO
// NEWAE mod: GF or LUT sboxes
`ifdef SBOX_GF
    aes_sbox sbox_inst00(.U(sbb_i[  7:  0]), .dec(dec_r), .S(sbb_o[  7:  0]));
    aes_sbox sbox_inst01(.U(sbb_i[ 15:  8]), .dec(dec_r), .S(sbb_o[ 15:  8]));
    aes_sbox sbox_inst02(.U(sbb_i[ 23: 16]), .dec(dec_r), .S(sbb_o[ 23: 16]));
    aes_sbox sbox_inst03(.U(sbb_i[ 31: 24]), .dec(dec_r), .S(sbb_o[ 31: 24]));
`else
    aes_sbox_lut sbox_inst00(.byte_in(sbb_i[  7:  0]), .dec(dec_r), .byte_out(sbb_o[  7:  0]));
    aes_sbox_lut sbox_inst01(.byte_in(sbb_i[ 15:  8]), .dec(dec_r), .byte_out(sbb_o[ 15:  8]));
    aes_sbox_lut sbox_inst02(.byte_in(sbb_i[ 23: 16]), .dec(dec_r), .byte_out(sbb_o[ 23: 16]));
    aes_sbox_lut sbox_inst03(.byte_in(sbb_i[ 31: 24]), .dec(dec_r), .byte_out(sbb_o[ 31: 24]));
`endif


endmodule