`default_nettype none
//set time unit to ns
`timescale 1ns/1ns

module aes_core_tb();

    reg clk;
    reg rst_n;
    reg load_i;
    reg [127:0] data_i;
    reg [1:0] size_i = 2'd0;
    reg dec_i = 0;
    wire [127:0] data_o;
    wire busy_o;

    aes_core_static_128 #(
        .KEY(128'h00112233445566778899aabbccddeeff)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .load_i(load_i),
        .data_i(data_i),
        .dec_i(dec_i),
        .data_o(data_o),
        .busy_o(busy_o)
    );

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, dut);
        $display("Starting simulation");
    end

    reg [127:0] plaintext;
    reg [127:0] ciphertext;

    reg [127:0] data_o_expected;

    initial begin
        plaintext = 128'h00112233445566778899aabbccddeeff;
        ciphertext = 128'h62f679be2bf0d931641e039ca3401bb2;

        rst_n = 1;
        clk = 0;
        load_i = 1'b0;
        //128-bit data
        data_i = plaintext;

        //reset the circuit
        rst_n = 0;
        #1; clk = 1; #1; clk = 0;
        rst_n = 1;

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
        

        //run until busy signal is low or timeout
        for(int i = 0; i < 100 && busy_o == 1; i++) begin
            $display("Busy: %b, Data: %h", busy_o, data_o);
            #1; clk = 1; #1; clk = 0;
        end

        if(busy_o == 1) begin
            $display("Error: timeout waiting for busy signal to go low");
            $finish;
        end
        $display("Busy: %b, Data: %h", busy_o, data_o);

        //check output
        if(data_o != ciphertext) begin
            $display("Error: data_o does not match expected value");
            $finish;
        end

        $display("Encryption successful");

        data_i = ciphertext;
        dec_i = 1;
        load_i = 1;

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
            $display("Busy: %b, Data: %h", busy_o, data_o);
            #1; clk = 1; #1; clk = 0;
        end

        $display("Busy: %b, Data: %h", busy_o, data_o);

        //check output
        if(data_o != plaintext) begin
            $display("Error: data_o does not match expected value");
            $finish;
        end

        $display("Decryption successful");

        $finish;
    end

endmodule