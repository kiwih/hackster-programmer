`default_nettype none

module spi_simple_top(
    input wire RST_N,
    input wire SCK,
    input wire MOSI,
    output wire MISO,
    input wire NORM_CS_N,

    output wire ICE_LED, RGB_R, RGB_G, RGB_B,
    input wire PI_ICE_BTN
);

    wire [7:0] text;

    assign ICE_LED = text[0];
    assign RGB_R = ~text[1];
    assign RGB_G = ~text[2];
    assign RGB_B = ~text[3];

    wire MISO_tmp;
    reg MISO_reg;

    shift_register #(
        .WIDTH(8)
    ) text_reg (
        .clk(SCK),
        .rst(~RST_N),
        .enable(NORM_CS_N),
        .data_in({PI_ICE_BTN, text[6:0]}), //override the MSB with the button
        .data_out(text),
        .shift_enable(~NORM_CS_N),
        .shift_in(MOSI),
        .shift_out(MISO_tmp)
    );

    //output shifting supposed to occur on falling edges for the SPI specification.
    //in reality this register can be a rising edge and it usually works, but
    //not when capturing with the oscilloscope which is more strict!
    always @(negedge SCK) begin
        MISO_reg <= MISO_tmp;
    end

    assign MISO = MISO_reg;

endmodule