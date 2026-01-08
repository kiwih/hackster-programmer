module les_top #(
    parameter [31:0] KEY = 32'hDEADC0DE
) (
    input clk,
    input clr,
    input wire [31:0] plaintext_in,
    output wire [31:0] cipher_out,
    input wire start,
    output reg busy
);

wire [31:0] sbox_out, rotate_out;
wire [31:0] text_in;
(* keep *) reg [31:0] text_reg;
reg text_reg_en;
reg text_clr;
always @(posedge clk) begin
    if(clr == 1'b1) begin
        text_reg <= 1'b0;
    end else if(text_clr == 1'b1) begin
        text_reg <= 1'b0;
    end else if(text_reg_en == 1'b1) begin
        text_reg <= text_in;
    end
end

wire dec_r = 1'b1;
reg sbox_in_sel; //1 == text_out_reg, 0 == lfsr_reg
wire [31:0] sbox_in = (sbox_in_sel ? text_reg : plaintext_in) ^ KEY;

// NEWAE mod: GF or LUT sboxes
`define SBOX_GF_NO

`ifdef SBOX_GF
    aes_sbox sbox_inst00(.U(sbox_in[  7:  0]), .dec(dec_r), .S(sbox_out[  7:  0]));
    aes_sbox sbox_inst01(.U(sbox_in[ 15:  8]), .dec(dec_r), .S(sbox_out[ 15:  8]));
    aes_sbox sbox_inst02(.U(sbox_in[ 23: 16]), .dec(dec_r), .S(sbox_out[ 23: 16]));
    aes_sbox sbox_inst03(.U(sbox_in[ 31: 24]), .dec(dec_r), .S(sbox_out[ 31: 24]));
`else
    aes_sbox_lut sbox_inst00(.byte_in(sbox_in[  7:  0]), .dec(dec_r), .byte_out(sbox_out[  7:  0]));
    aes_sbox_lut sbox_inst01(.byte_in(sbox_in[ 15:  8]), .dec(dec_r), .byte_out(sbox_out[ 15:  8]));
    aes_sbox_lut sbox_inst02(.byte_in(sbox_in[ 23: 16]), .dec(dec_r), .byte_out(sbox_out[ 23: 16]));
    aes_sbox_lut sbox_inst03(.byte_in(sbox_in[ 31: 24]), .dec(dec_r), .byte_out(sbox_out[ 31: 24]));
`endif

//rotate_out is the sbox_out rotated by 8 bits
assign rotate_out = {sbox_out[23:0], sbox_out[31:24]};
 
//assign to text_in
assign text_in = rotate_out;


reg [1:0] les_state_counter, les_state_counter_next;

always @(les_state_counter, start, clr) begin
    text_clr <= 1'b0;
    busy <= 1'b0;
    sbox_in_sel <= 1'b0; // set sbox_in to lfsr_reg
    text_reg_en <= 1'b0; // disable text_reg
    les_state_counter_next <= les_state_counter;
    if(clr == 1'b1) begin
        les_state_counter_next <= 2'b00;
        text_clr <= 1'b1;
    end else if(start == 1'b1 && les_state_counter == 2'b00) begin
        les_state_counter_next <= 2'b01;
        text_reg_en <= 1'b1;
        busy <= 1'b1;
    end else if(les_state_counter > 2'b00) begin
        text_reg_en <= 1'b1;
        sbox_in_sel <= 1'b1;
        les_state_counter_next <= les_state_counter + 1;
        busy <= 1'b1;
    end
end

always @(posedge clk) begin
    les_state_counter <= les_state_counter_next;
end

assign cipher_out = text_reg;


/*

//This is a little cursed, but due to the weak signal capturing
// with the simplified LES algorithm, I want to amplify
// the signals in the FPGA to simplify the power analysis
//We still won't export the signals, just make them "louder"
// in the power domain.
//This is done with unity gates.
//64 unity gates to amplify the signal of a bit (target LSB of each byte)
wire [7:0] lut_ins [0:3];
wire [7:0] lut_outs [0:3];

genvar i;
generate
    for(i = 0; i < 4; i = i + 1) begin
        (* keep *) 
        SB_LUT4 #(
            .LUT_INIT(16'h0002)
        ) luts [7:0] (
            .I0(lut_ins[i]),
            .I1(1'b0),
            .I2(1'b0),
            .I3(1'b0),
            .O(lut_outs[i])
        );
    end   
endgenerate

//wire all UNITY gates in a sequence, with each sequence connected to 
//the least significant bit of one of the bytes of the text_reg
assign lut_ins[0] = {lut_outs[0][6:0], text_reg[0]};
assign lut_ins[1] = {lut_outs[1][6:0], text_reg[8]};
assign lut_ins[2] = {lut_outs[2][6:0], text_reg[16]};
assign lut_ins[3] = {lut_outs[3][6:0], text_reg[24]};

*/

endmodule