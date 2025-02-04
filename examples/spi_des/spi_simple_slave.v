//Author: Hammond Pearce
//Email: hammond.pearce@unsw.edu.au
//Date: Jan 31 2025

`default_nettype none

module spi_simple_slave (
    input wire clk,
    input wire rst_n,

    input wire mosi,
    output wire miso,
    input wire sck,
    input wire cs_n,

    output reg [7:0] data_out,
    output reg data_out_valid,

    input wire [7:0] data_in,
    input wire data_in_read
);


    




endmodule