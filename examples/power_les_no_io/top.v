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
reg [3:0] counter = 0;
// if 0-10, do nothing
// if 11, advance LFSR
// if 12, start the LES system

always @(posedge ICE_CLK) begin
    counter <= counter + 1; // always increment counter
end

reg les_start, les_clr;

always @(counter) begin
    les_start <= 0;
    lfsr_shift_en <= 1'b0; // disable LFSR shift
    les_clr <= 1'b0; // don't clear text_reg
    case(counter)
        4'd10: les_clr <= 1'b1; // clear text_reg
        4'd11: lfsr_shift_en <= 1'b1; // advance LFSR
        4'd12: begin
            les_start <= 1'b1; // start LES
        end
    endcase
end

wire les_busy;
wire [31:0] les_cipher_out;
les_top les_inst(
    .clk(ICE_CLK),
    .clr(les_clr),
    .plaintext_in(lfsr_reg),
    .cipher_out(les_cipher_out),
    .start(les_start),
    .busy(les_busy)
);

assign RGB_B = les_busy;

assign ICE_LED = counter > 4'd11;

endmodule