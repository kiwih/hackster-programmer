`default_nettype none
module aes_ks_static_128_tb();

    wire [127:0] rks_o [0:10];

    aes_core_static_multicycle_4sbox_128 #(
        .key_i(128'h2b7e151628aed2a6abf7976676151301)
    ) dut (
        .rks_o(rks_o)
    );

    integer i;
    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, dut);
        $display("Starting simulation");
        #1;
        for(i=0; i<11; i=i+1) begin
            $display("rks_o[%0d] = %h", i, rks_o[i]);
        end
    end

endmodule