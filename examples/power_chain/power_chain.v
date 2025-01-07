module multiplier_block(
    input wire ICE_CLK,
    input wire [31:0] A,
    input wire [31:0] B,
    output wire [63:0] P
);

reg [31:0] a_reg = 0;
reg [31:0] b_reg = 0;
reg [63:0] p_reg = 0;

always @(posedge ICE_CLK) begin
    a_reg <= A;
    b_reg <= B;
    p_reg <= a_reg * b_reg;
end

assign P = p_reg;

endmodule




module power_chain (
    input wire ICE_CLK,
    output wire ICE_LED, RGB_R, RGB_G, RGB_B
);

reg [31:0] a_input_reg = 0;
reg [31:0] b_input_reg = 0;
wire [63:0] p_output_wire [0:127];

// instantiate 128 multiplier blocks all in parallel
genvar i;
generate
    for (i = 0; i < 128; i = i + 1) begin : gen_mul
        multiplier_block mul (
            .ICE_CLK(ICE_CLK),
            .A(a_input_reg),
            .B(b_input_reg),
            .P(p_output_wire[i])
        );
    end
endgenerate

// take the logical OR of all the outputs
integer j;
reg led_t;
always @* begin
    led_t = 0;
    for (j = 0; j < 128; j = j + 1) begin
        led_t = led_t | (|p_output_wire[j]);
    end
end

assign ICE_LED = led_t;
assign RGB_G = 1'b0;
assign RGB_B = 1'b0;
assign RGB_R = 1'b1;

reg [7:0] output_counter = 8'b00000000;

always @(posedge ICE_CLK) begin
    output_counter <= output_counter + 1;
    if(output_counter > 8'd127) begin
        a_input_reg <= 0;
        b_input_reg <= 0;
    end else begin
        a_input_reg <= a_input_reg + (8'd1 + output_counter*3);
        b_input_reg <= b_input_reg ^ (8'd1 + a_input_reg);
    end
end

endmodule