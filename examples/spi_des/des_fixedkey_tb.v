`default_nettype none

module des_fixedkey_tb ();

    localparam KEY = 64'hFEF9545BB7A45DFD;
    localparam PLAINTEXT = 64'h0000000000000004;
    localparam CIPHERTEXT = 64'h454CF26DB6CA571A;

    reg clk = 0;
    reg rst_n = 0;
    reg start = 0;
    wire busy;
    reg [63:0] starttext;
    wire [63:0] finishtext;
    reg encrypt_ndecrypt = 0;

    des_fixedkey #(
        .KEY(KEY)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .starttext(starttext),
        .finishtext(finishtext),
        .start(start),
        .encrypt_ndecrypt(encrypt_ndecrypt),
        .busy(busy)
    );

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, dut);
        $display("Starting simulation");
    end

    always begin
        #1 clk = ~clk;
    end

    always begin
        rst_n = 0;
        encrypt_ndecrypt = 1;
        starttext = PLAINTEXT;
        #2; 
        rst_n = 1;
        #2; 
        start = 1;
        #2;
        start = 0;
        #2;
        if(!busy) begin
            $display("Error: busy signal not set");
            $finish;
        end
        while(busy) begin
            #2;
        end
        if(finishtext != CIPHERTEXT) begin
            $display("Error: finishtext = %h, expected = %h", finishtext, CIPHERTEXT);
            $finish;
        end
        starttext = finishtext;
        #2;
        encrypt_ndecrypt = 0;
        start = 1;
        #2;
        start = 0;
        #2;
        if(!busy) begin
            $display("Error: busy signal not set");
            $finish;
        end
        while(busy) begin
            #2;
        end
        if(finishtext != PLAINTEXT) begin
            $display("Error: finishtext = %h, expected = %h", finishtext, PLAINTEXT);
            $finish;
        end
        $display("Simulation finished, all tests passed");
        $finish;

    end

endmodule