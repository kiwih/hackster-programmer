module signal_amplify(
    input wire [127:0] data
);

`define __SYNTH__

`ifdef __SYNTH__
//This is a little cursed, but due to the weak signal capturing
// with my lacklustre power capture hardware, I need to amplify
// the signals in the FPGA to perform the power analysis
//We still won't export the signals, just make them "louder"
// in the power domain.
//This is done with unity gates.
//64 unity gates to amplify the signal of a bit
wire [63:0] lut_ins [0:15];
wire [63:0] lut_outs [0:15];

genvar i;
generate
    for(i = 0; i < 15; i = i + 1) begin
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
assign lut_ins[0] = {lut_outs[0][62:0], data[0]};
assign lut_ins[1] = {lut_outs[1][62:0], data[8]};
assign lut_ins[2] = {lut_outs[2][62:0], data[16]};
assign lut_ins[3] = {lut_outs[3][62:0], data[24]};
assign lut_ins[4] = {lut_outs[4][62:0], data[32]};
assign lut_ins[5] = {lut_outs[5][62:0], data[40]};
assign lut_ins[6] = {lut_outs[6][62:0], data[48]};
assign lut_ins[7] = {lut_outs[7][62:0], data[56]};
assign lut_ins[8] = {lut_outs[8][62:0], data[64]};
assign lut_ins[9] = {lut_outs[9][62:0], data[72]};
assign lut_ins[10] = {lut_outs[10][62:0], data[80]};
assign lut_ins[11] = {lut_outs[11][62:0], data[88]};
assign lut_ins[12] = {lut_outs[12][62:0], data[96]};
assign lut_ins[13] = {lut_outs[13][62:0], data[104]};
assign lut_ins[14] = {lut_outs[14][62:0], data[112]};
assign lut_ins[15] = {lut_outs[15][62:0], data[120]};
`endif

endmodule