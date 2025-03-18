`default_nettype none

module spi_les_top(
    input wire RST_N,
    input wire SCK,
    input wire MOSI,
    output wire MISO,
    input wire NORM_CS_N,
    input wire START,

    output wire ICE_LED,
    output wire BUSY
);

    wire [31:0] text;
    wire [31:0] text_out;

    wire spi_out;

    wire busy;
    wire done;

    assign ICE_LED = busy;
    assign BUSY = busy;
    wire busy_falling_edge;

    shift_register #(
        .WIDTH(32)
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

    reg resetn = 1'b1;

    les_top #(
        .KEY(32'hDEADC0DE)   
    )les (
        .clk        (SCK),
        .clr        (~RST_N),
        .start      (START),
        .plaintext_in (text),
        .cipher_out   (text_out),
        .busy       (busy)
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