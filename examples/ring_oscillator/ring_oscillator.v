`default_nettype none

module ring_oscillator(
    //input wire ICE_CLK,
    output reg ICE_LED //, RGB_R, RGB_G, RGB_B
);

//instantiate 70 NOT gates (as raw LUTs)
wire [69:0] lut_ins, lut_outs;
(* keep *)
SB_LUT4 #(
    .LUT_INIT(16'h0001)
) luts [69:0] (
    .I0(lut_ins),
    .I1(1'b0),
    .I2(1'b0),
    .I3(1'b0),
    .O(lut_outs)
);

//wire all the NOT gates in a ring
assign lut_ins = {lut_outs[68:0], lut_outs[69]};

wire puf_clk;
assign puf_clk = lut_outs[69];

reg [20:0] counter = 0;

always@(posedge puf_clk) begin
    counter <= counter + 1;
    ICE_LED <= counter[20];
end

endmodule