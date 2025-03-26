`default_nettype none

// start your project from here.
module top (
    input wire ICE_CLK,
    input wire [3:0] APP_in,
    input wire [2:0] APP_key,
    output wire [1:0] APP_out,
);

// the same circuit as before, now with a key of 101
assign APP_out[0] = APP_in[0] & APP_in[1];
assign APP_out[1] = APP_in[2] ^ APP_in[3];

endmodule
