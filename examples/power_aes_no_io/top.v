`default_nettype none
`define SBOX_GF

module top(
    input wire ICE_CLK,
    output wire ICE_LED, RGB_R, RGB_G, RGB_B
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

reg aes_start;
wire aes_busy;

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


reg [127:0] aes_text_in = {lfsr_reg, lfsr_reg, lfsr_reg, lfsr_reg}; //4 repetitions of the LFSR
wire [127:0] aes_text_out;
wire [127:0] aes_r10_key;


aes_core_static_128 #(
    .KEY(128'h00112233445566778899aabbccddeeff)
) aes_core (
    .clk        (ICE_CLK),
    .rst_n      (resetn),
    .load_i     (aes_start),
    .data_i     (aes_text_in),
    .dec_i      (1'b0),
    .data_o     (aes_text_out),
    .busy_o     (aes_busy)
);

reg [7:0] counter = 0;

always @(posedge ICE_CLK) begin
    aes_start <= 1'b0;
    lfsr_shift_en <= 1'b0;
    //if(aes_busy == 1'b1) begin
    //    counter <= 0;
    //end else if(aes_busy == 1'b0) begin
    counter <= counter + 1;
    if(counter == 8'hFC) begin 
        lfsr_shift_en <= 1'b1;
    end else if(counter == 8'hF0) begin
        aes_start <= 1'b1;
    end else if(counter == 8'hFF) begin
        counter <= 0;
    end
    //end
end

assign ICE_LED = (counter >= 8'hF0);

//take the logical OR of all the output aes_text_out and assign it to RGB_R
assign RGB_R = |aes_text_out[127:0];
//take the logical AND of all the output aes_text_out and assign it to RGB_G
assign RGB_G = &aes_text_out[127:0];
//take the logical XOR of all the output aes_text_out and assign it to RGB_B
assign RGB_B = ^aes_text_out[127:0];

//ra
endmodule