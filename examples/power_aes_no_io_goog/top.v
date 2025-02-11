`default_nettype none
`define SBOX_GF

module top(
    input wire ICE_CLK,
    output wire ICE_LED, RGB_R, RGB_G, RGB_B
);

reg aes_start;
wire aes_busy;

reg [127:0] aes_key_in = 128'h00112233445566778899aabbccddeeff;
reg [127:0] aes_text_in = 128'h00112233445566778899aabbccddeeff;
wire [127:0] aes_text_out;
wire [127:0] aes_r10_key;

reg resetn = 1'b1;

aes_core AESGoogleVault(
    .clk        (ICE_CLK),
    .load_i     (aes_start),
    .key_i      ({aes_key_in, 128'h0}),
    .data_i     (aes_text_in),
    .size_i     (2'd0), //AES-128
    .dec_i      (1'b0),
    .data_o     (aes_text_out),
    .busy_o     (aes_busy)
);

reg did_reset = 1'b0;
always @(posedge ICE_CLK) begin
    if(did_reset == 1'b0 && resetn == 1'b1) begin
        resetn <= 1'b0;
    end else if (resetn == 1'b0) begin
        did_reset <= 1'b1;
        resetn <= 1'b1;
    end
end

reg [7:0] counter = 0;

always @(posedge ICE_CLK) begin
    aes_start <= 1'b0;
    if(aes_busy == 1'b0) begin
        if(counter == 8'hFF) begin
            counter <= 0;
            aes_text_in <= aes_text_in + 128'h1;
            aes_start <= 1'b1;
        end else begin
            counter <= counter + 1;
        end
    end
end

reg [18:0] counter2 = 0;
always @(posedge ICE_CLK) begin
    counter2 <= counter2 + 1;
end
assign ICE_LED = aes_busy;

//take the logical OR of all the output aes_text_out and assign it to RGB_R
assign RGB_R = |aes_text_out[127:0];
//take the logical AND of all the output aes_text_out and assign it to RGB_G
assign RGB_G = &aes_text_out[127:0];
//take the logical XOR of all the output aes_text_out and assign it to RGB_B
assign RGB_B = ^aes_text_out[127:0];

//ra
endmodule