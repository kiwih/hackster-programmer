`default_nettype none

module top(
    input wire ICE_CLK,
    output wire ICE_LED, RGB_R, RGB_G, RGB_B,
    output wire DUMMYO
);


reg resetn = 1'b1;
reg did_reset = 1'b0;
always @(posedge ICE_CLK) begin
    if(did_reset == 1'b0 && resetn == 1'b1) begin
        resetn <= 1'b0;
    end else if (resetn == 1'b0) begin
        did_reset <= 1'b1;
        resetn <= 1'b1;
    end
end


//32 bit LFSR
reg [31:0] lfsr_reg = 32'hACE1ACE1;
//put taps at 32, 22, 2, 1
wire lfsr_out;
assign lfsr_out = lfsr_reg[31] ^ lfsr_reg[21] ^ lfsr_reg[1] ^ lfsr_reg[0];
reg lfsr_shift_en;
always @(posedge ICE_CLK) begin
    if(resetn == 1'b0) begin
        lfsr_reg <= 32'hACE1ACE1;
    end else if(lfsr_shift_en == 1'b1) begin
        lfsr_reg <= {lfsr_reg[30:0], lfsr_out};
    end
end

wire [31:0] text_out;
(* keep *) reg [31:0] text_reg;
reg text_reg_en;
reg text_clr;
always @(posedge ICE_CLK) begin
    if(resetn == 1'b0) begin
        text_reg <= 1'b0;
    end else if(text_clr == 1'b1) begin
        text_reg <= 1'b0;
    end else if(text_reg_en == 1'b1) begin
        text_reg <= text_out;
    end
end

wire dec_r = 1'b1;
reg text_in_sel; //1 == text_out_reg, 0 == lfsr_reg
wire [31:0] text_in = (text_in_sel ? text_reg : lfsr_reg) ^ 32'hDEADC0DE;

// NEWAE mod: GF or LUT sboxes
`define SBOX_GF_NO

`ifdef SBOX_GF
    aes_sbox sbox_inst00(.U(text_in[  7:  0]), .dec(dec_r), .S(text_out[  7:  0]));
    aes_sbox sbox_inst01(.U(text_in[ 15:  8]), .dec(dec_r), .S(text_out[ 15:  8]));
    aes_sbox sbox_inst02(.U(text_in[ 23: 16]), .dec(dec_r), .S(text_out[ 23: 16]));
    aes_sbox sbox_inst03(.U(text_in[ 31: 24]), .dec(dec_r), .S(text_out[ 31: 24]));
`else
    aes_sbox_lut sbox_inst00(.byte_in(text_in[  7:  0]), .dec(dec_r), .byte_out(text_out[  7:  0]));
    aes_sbox_lut sbox_inst01(.byte_in(text_in[ 15:  8]), .dec(dec_r), .byte_out(text_out[ 15:  8]));
    aes_sbox_lut sbox_inst02(.byte_in(text_in[ 23: 16]), .dec(dec_r), .byte_out(text_out[ 23: 16]));
    aes_sbox_lut sbox_inst03(.byte_in(text_in[ 31: 24]), .dec(dec_r), .byte_out(text_out[ 31: 24]));
`endif

reg [3:0] counter = 0;
// if 0-10, do nothing
// if 11, advance LFSR
// if 12, set text_in to lfsr_reg and enable text_reg
// if 13, set text_in to text_reg and enable text_reg
// if 14, set text_in to lfsr_reg and enable text_reg
// if 15, set text_in to text_reg and enable text_reg

always @(posedge ICE_CLK) begin
    counter <= counter + 1; // always increment counter
end
always @(counter) begin
    text_reg_en <= 1'b0; // disable text_reg
    text_in_sel <= 1'b0; // set text_in to lfsr_reg
    lfsr_shift_en <= 1'b0; // disable LFSR shift
    text_clr <= 1'b0; // don't clear text_reg
    case(counter)
        4'd10: text_clr <= 1'b1; // clear text_reg
        4'd11: lfsr_shift_en <= 1'b1; // advance LFSR
        4'd12: begin
            text_in_sel <= 1'b0; // set text_in to lfsr_reg
            text_reg_en <= 1'b1; // enable text_reg
        end
        4'd13: begin
            text_in_sel <= 1'b1; // set text_in to text_out
            text_reg_en <= 1'b1; // enable text_reg
        end
        4'd14: begin
            text_in_sel <= 1'b1; // set text_in to text_out
            text_reg_en <= 1'b1; // enable text_reg
        end
        4'd15: begin
            text_in_sel <= 1'b1; // set text_in to text_out
            text_reg_en <= 1'b1; // enable text_reg
        end
    endcase
end

assign ICE_LED = counter > 4'd11; // LED on when counter > 3

//This is a little cursed, but due to the weak signal capturing
// with my lacklustre power capture hardware, I need to amplify
// the signals in the FPGA to perform the power analysis
//We still won't export the signals, just make them "louder"
// in the power domain.
//This is done with unity gates.
//64 unity gates to amplify the signal of a bit
wire [63:0] lut_ins [0:3];
wire [63:0] lut_outs [0:3];

genvar i;
generate
    for(i = 0; i < 4; i = i + 1) begin
        (* keep *) 
        SB_LUT4 #(
            .LUT_INIT(16'h0002)
        ) luts [63:0] (
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
assign lut_ins[0] = {lut_outs[0][62:0], text_reg[0]};
assign lut_ins[1] = {lut_outs[1][62:0], text_reg[8]};
assign lut_ins[2] = {lut_outs[2][62:0], text_reg[16]};
assign lut_ins[3] = {lut_outs[3][62:0], text_reg[24]};

//assign DUMMYO = text_reg[0];

//take the logical OR of all the output and assign it to RGB_R
//assign RGB_R = |text_reg[31:0];
//take the logical AND of all the output and assign it to RGB_G
//assign RGB_G = &text_reg[31:0];
//take the logical XOR of all the output and assign it to RGB_B
//assign RGB_B = ^text_reg[31:0];

//assign RGB_B = text_reg[0];

//ra
endmodule