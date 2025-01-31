`default_nettype none

module spi_des_scan_top(
    input wire RST_N,
    input wire SCK,
    input wire MOSI,
    output wire MISO,
    input wire NORM_CS_N,
    input wire SCAN_CS_N,
    input wire START,
    input wire ENCRYPT_NDECRYPT,

    output wire ICE_LED,
    output wire BUSY
);

    wire [63:0] text;
    wire [63:0] text_out;
    reg last_busy;

    wire spi_out, des_scan_out;

    wire busy;
    always @(posedge SCK) last_busy = busy;
    wire busy_falling_edge = last_busy & ~busy;

    assign ICE_LED = busy;
    assign BUSY = busy;

    scan_register #(
        .WIDTH(64)
    ) text_reg (
        .clk(SCK),
        .rst(~RST_N),
        .enable(busy_falling_edge),
        .data_in(text_out),
        .data_out(text),
        .scan_enable(~NORM_CS_N),
        .scan_in(MOSI),
        .scan_out(spi_out)
    );

    des_fixedkey_scanchain #(
        .KEY(64'hFEF9545BB7A45DFD)
    ) des (
        .clk(SCK),
        .rst_n(RST_N),
        .starttext(text),
        .finishtext(text_out),
        .start(START),
        .encrypt_ndecrypt(ENCRYPT_NDECRYPT),
        .busy(busy),
        .scan_enable(~SCAN_CS_N),
        .scan_in(MOSI),
        .scan_out(des_scan_out)
    );

    wire MISO_tmp;
    reg MISO_reg;

    assign MISO_tmp = (NORM_CS_N == 0 ? spi_out : des_scan_out);

    always @(posedge SCK) begin
        MISO_reg <= MISO_tmp;
    end

    assign MISO = MISO_reg;

endmodule