`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: UNSW
// Engineer: Hammond Pearce 
//////////////////////////////////////////////////////////////////////////////////

module scan_shift_register #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire shift_enable,
    input wire shift_in,
    output wire shift_out,
    input wire [WIDTH-1:0] data_in,
    input wire data_enable,
    output wire [WIDTH-1:0] data_out,
    input wire scan_enable,
    input wire scan_in,
    output wire scan_out
);

    reg [WIDTH-1:0] internal_data;

    // Shift register operation
    always @(posedge clk) begin
        if (rst) begin
            internal_data <= {WIDTH{1'b0}};
        end else if (scan_enable) begin
            if (WIDTH == 1) begin
                internal_data <= scan_in;
            end else begin
                internal_data <= {internal_data[WIDTH-2:0], scan_in};
            end
        end else if (shift_enable) begin
            if (WIDTH == 1) begin
                internal_data <= shift_in;
            end else begin
                internal_data <= {internal_data[WIDTH-2:0], shift_in};
            end 
        end else if (data_enable) begin
            internal_data <= data_in;
        end
    end

    // Output assignment
    assign data_out = internal_data;
    assign scan_out = internal_data[WIDTH-1];
    assign shift_out = internal_data[WIDTH-1];
endmodule