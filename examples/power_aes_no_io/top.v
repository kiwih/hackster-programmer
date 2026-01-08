`default_nettype none

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

//128 bit LFSR
reg [127:0] lfsr_reg = 128'hACE1ACE159C359C3B386B386670D670C;
//put taps at 127, 109, 85, 0
wire lfsr_out;
assign lfsr_out = lfsr_reg[127] ^ lfsr_reg[109] ^ lfsr_reg[85] ^ lfsr_reg[0];
reg lfsr_shift_en;
always @(posedge ICE_CLK) begin
    if(resetn == 1'b0) begin
        lfsr_reg <= 128'hACE1ACE159C359C3B386B386670D670C;
    end else if(lfsr_shift_en == 1'b1) begin
        lfsr_reg <= {lfsr_reg[126:0], lfsr_out};
    end
end


wire [127:0] aes_text_in = lfsr_reg; //the LFSR
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
    if(counter == 8'hEF) begin 
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
assign RGB_R = aes_text_out[0];
//take the logical AND of all the output aes_text_out and assign it to RGB_G
assign RGB_G = aes_text_out[127];
////take the logical XOR of all the output aes_text_out and assign it to RGB_B
//assign RGB_B = ^aes_text_out[127:0];0
assign RGB_B = aes_text_out[63];
//ra
endmodule