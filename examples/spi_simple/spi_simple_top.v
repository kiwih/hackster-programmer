`default_nettype none

module spi_simple_top(
    input wire RST_N,
    input wire SCK,
    input wire MOSI,
    output wire MISO,
    input wire NORM_CS_N,

    output wire ICE_LED, RGB_R, RGB_G, RGB_B
);

    wire [7:0] text;

    assign ICE_LED = text[0];
    assign RGB_R = ~text[1];
    assign RGB_G = ~text[2];
    assign RGB_B = ~text[3];

    wire MISO_tmp;
    reg MISO_reg;

    scan_register #(
        .WIDTH(8)
    ) text_reg (
        .clk(SCK),
        .rst(~RST_N),
        .enable(1'b0),
        .data_in(8'b0),
        .data_out(text),
        .scan_enable(~NORM_CS_N),
        .scan_in(MOSI),
        .scan_out(MISO_tmp)
    );

    always @(posedge SCK) begin
        MISO_reg <= MISO_tmp;
    end

    assign MISO = MISO_reg;

endmodule