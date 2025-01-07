module power_chain_tb();

reg clk_t = 0;
wire led_t;

power_chain power_chain_dut (
    .ICE_CLK(clk_t),
    .ICE_LED(led_t)
);

always begin
    #5 clk_t = ~clk_t;
end

//emit waveform.vcd
initial begin
    $dumpfile("waveform.vcd");
    $dumpvars(0, power_chain_tb);
    #10000 $finish;
end

endmodule