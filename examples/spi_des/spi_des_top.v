`default_nettype none

module spi_des_top(
    input wire RST_N,
    input wire SCK,
    input wire MOSI,
    output wire MISO,
    input wire NORM_CS_N,
    input wire START,
    input wire ENCRYPT_NDECRYPT,

    output wire ICE_LED,
    output wire BUSY
);

    wire [63:0] text;
    wire [63:0] text_out;
    reg last_busy;

    wire spi_out;

    wire busy;
    wire done;

    assign ICE_LED = busy;
    assign BUSY = busy;

    shift_register #(
        .WIDTH(64)
    ) text_reg (
        .clk(SCK),
        .rst(~RST_N),

        .shift_enable(~NORM_CS_N),
        .shift_in(MOSI),
        .shift_out(spi_out),

        .data_enable(done),
        .data_in(text_out),
        .data_out(text)
    );

    des_fixedkey #(
        .KEY(64'hFEF9545BB7A45DFD)
    ) des (
        .clk(SCK),
        .rst_n(RST_N),
        .starttext(text),
        .finishtext(text_out),
        .start(START),
        .encrypt_ndecrypt(ENCRYPT_NDECRYPT),
        .busy(busy),
        .done(done)
    );

    wire MISO_tmp;
    reg MISO_reg;

    assign MISO_tmp = spi_out;

    always @(posedge SCK) begin
        MISO_reg <= MISO_tmp;
    end

    assign MISO = MISO_reg;

endmodule