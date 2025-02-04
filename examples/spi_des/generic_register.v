`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Hammond Pearce
//////////////////////////////////////////////////////////////////////////////////

module generic_register #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire enable,
    input wire [WIDTH-1:0] data_in,
    output wire [WIDTH-1:0] data_out
);

    reg [WIDTH-1:0] internal_data;

    // Shift register operation
    always @(posedge clk) begin
        if (rst) begin
            internal_data <= {WIDTH{1'b0}};
        end else if (enable) begin
            internal_data <= data_in;
        end
    end

    // Output assignment
    assign data_out = internal_data;

endmodule