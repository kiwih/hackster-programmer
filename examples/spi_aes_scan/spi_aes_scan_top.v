`default_nettype none

module spi_aes_scan_top(
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

    wire [127:0] text;
    wire [127:0] text_out;

    wire spi_out, aes_scan_out, spi_scan_out;

    wire busy;
    wire done;

    assign ICE_LED = busy;
    assign BUSY = busy;
    wire busy_falling_edge;

    scan_shift_register #(
        .WIDTH(128)
    ) text_reg (
        .clk(SCK),
        .rst(~RST_N),

        .shift_enable(~NORM_CS_N),
        .shift_in(MOSI),
        .shift_out(spi_out),

        .data_enable(done),
        .data_in(text_out),
        .data_out(text),

        .scan_enable(~SCAN_CS_N),
        .scan_in(MOSI),
        .scan_out(spi_scan_out)
    );

    reg aes_start;

    reg [127:0] aes_text_in = 128'h00112233445566778899aabbccddeeff;
    wire [127:0] aes_text_out;
    wire [127:0] aes_r10_key;

    reg resetn = 1'b1;

    aes_core_static_128_scanchain #(
        .KEY(128'h2b7e151628aed2a6abf7976676151301)   
    )aes (
        .clk        (SCK),
        .rst_n      (RST_N),
        .load_i     (START),
        .data_i     (text),
        .dec_i      (~ENCRYPT_NDECRYPT),
        .data_o     (text_out),
        .busy_o     (busy),
        .done_o     (done),
        .scan_enable(~SCAN_CS_N),
        .scan_in(spi_scan_out),
        .scan_out(aes_scan_out)
    );

    wire MISO_tmp;
    reg MISO_reg;

    assign MISO_tmp = (NORM_CS_N == 0 ? spi_out : aes_scan_out);

    always @(posedge SCK) begin
        MISO_reg <= MISO_tmp;
    end

    assign MISO = MISO_reg;

endmodule