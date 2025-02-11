`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: New York University
// Engineer: ChatGPT GPT-4 Mar 23 version; Hammond Pearce (prompting)
// For more information, see https://github.com/kiwih/tt03-verilog-qtcoreA1
// 
// Last Edited Date (NYU): 04/19/2023
//////////////////////////////////////////////////////////////////////////////////

module shift_register #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire enable,
    input wire [WIDTH-1:0] data_in,
    output wire [WIDTH-1:0] data_out,
    input wire shift_enable,
    input wire shift_in,
    output wire shift_out
);

    reg [WIDTH-1:0] internal_data;

    // Shift register operation
    always @(posedge clk) begin
        if (rst) begin
            internal_data <= {WIDTH{1'b0}};
        end else if (shift_enable) begin
            if (WIDTH == 1) begin
                internal_data <= shift_in;
            end else begin
                internal_data <= {internal_data[WIDTH-2:0], shift_in};
            end
        end else if (enable) begin
            internal_data <= data_in;
        end
    end

    // Output assignment
    assign data_out = internal_data;
    assign shift_out = internal_data[WIDTH-1];

endmodule