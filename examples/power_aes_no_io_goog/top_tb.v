`default_nettype none
//set time unit to ns
`timescale 1ns/1ns

module top_tb();

    reg ICE_CLK;
    wire ICE_LED, RGB_R, RGB_G, RGB_B;

    top top_inst (
        .ICE_CLK(ICE_CLK),
        .ICE_LED(ICE_LED),
        .RGB_R(RGB_R),
        .RGB_G(RGB_G),
        .RGB_B(RGB_B)
    );

    initial begin
        ICE_CLK = 1'b0;
        repeat(10000) begin
            #5 ICE_CLK = ~ICE_CLK;
        end
    end

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, top_inst);
        $display("Starting simulation");
    end
endmodule