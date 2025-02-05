`default_nettype none

module spi_aes_top(
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

    wire [127:0] text;
    wire [127:0] text_out;

    wire spi_out;

    wire busy;
    wire done;

    assign ICE_LED = busy;
    assign BUSY = busy;
    wire busy_falling_edge;

    shift_register #(
        .WIDTH(128)
    ) text_reg (
        .clk(SCK),
        .rst(~RST_N),

        .shift_enable(~NORM_CS_N),
        .shift_in(MOSI),
        .shift_out(spi_out),

        .data_enable(busy_falling_edge),
        .data_in(text_out),
        .data_out(text)
    );

    reg aes_start;
    wire aes_busy;

    reg [127:0] aes_key_in = 128'h00112233445566778899aabbccddeeff;
    reg [127:0] aes_text_in = 128'h00112233445566778899aabbccddeeff;
    wire [127:0] aes_text_out;
    wire [127:0] aes_r10_key;

    reg resetn = 1'b1;

    aes_core_static_128 #(
        .KEY(128'h2b7e151628aed2a6abf7976676151301)   
    )aes (
        .clk        (SCK),
        .rst_n      (RST_N),
        .load_i     (START),
        .data_i     (text),
        .dec_i      (ENCRYPT_NDECRYPT),
        .data_o     (text_out),
        .busy_o     (busy)
    );

    reg last_busy = 0;
    always @(posedge SCK) begin
        if (RST_N == 1'b0) begin
            last_busy <= 1'b0;
        end else begin
            last_busy <= busy;
        end
    end
    assign busy_falling_edge = last_busy & ~busy;

    wire MISO_tmp;
    reg MISO_reg;

    assign MISO_tmp = spi_out;

    always @(posedge SCK) begin
        MISO_reg <= MISO_tmp;
    end

    assign MISO = MISO_reg;

endmodule