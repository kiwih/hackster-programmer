`default_nettype none
//set time unit to ns
`timescale 1ns/1ns

module aes_core_tb();

    reg clk;
    reg load_i;
    reg [255:0] key_i;
    reg [127:0] data_i;
    reg [1:0] size_i = 2'd0;
    reg dec_i = 0;
    wire [127:0] data_o;
    wire busy_o;

    aes_core dut (
        .clk(clk),
        .load_i(load_i),
        .key_i(key_i),
        .data_i(data_i),
        .size_i(size_i),
        .dec_i(dec_i),
        .data_o(data_o),
        .busy_o(busy_o)
    );

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, dut);
        $display("Starting simulation");
    end

    reg [127:0] data_o_expected;

    initial begin
        clk = 0;
        load_i = 1'b0;
        //128-bit key
        key_i = {128'h00112233445566778899aabbccddeeff, 128'h0};
        //128-bit data
        data_i = 128'h00112233445566778899aabbccddeeff;
        //expected output
        data_o_expected = 128'h62F679BE2BF0D931641E039CA3401BB2;

        //run one clock cycle
        #1; clk = 1; #1; clk = 0;

        //set start signal
        load_i = 1'b1;

        //run one clock cycle
        #1; clk = 1; #1; clk = 0;

        //clear start signal
        load_i = 1'b0;

        //make sure busy signal is high
        if(busy_o != 1) begin
            $display("Error: busy signal is not high");
            $finish;
        end

        //run until busy signal is low
        while(busy_o == 1) begin
            #1; clk = 1; #1; clk = 0;
        end

        //check output
        if(data_o != data_o_expected) begin
            $display("Error: data_o does not match expected value");
            $finish;
        end

        $display("Simulation complete");
        $finish;
    end

endmodule