`default_nettype none

module i2c_pin_primitives_ice40(
    input wire ICE_CLK,
    
    inout wire SDA, SCL,
    output wire SDA_DIN, SCL_DIN,
    input wire SDA_PULLDOWN, SCL_PULLDOWN
);

SB_IO #(
    .PIN_TYPE(6'b 1010_00), // 1010_01 is bidirectional with registered input
    .PULLUP(1'b 1), // yes pullup
) sbio_sda (
    .INPUT_CLK(ICE_CLK), 
    .PACKAGE_PIN(SDA),
    .OUTPUT_ENABLE(SDA_PULLDOWN), 
    .D_OUT_0(1'b 0),
    .D_IN_0(SDA_DIN)
);

SB_IO #(
    .PIN_TYPE(6'b 1010_00), // 1010_01 is bidirectional with registered input
    .PULLUP(1'b 1), // yes pullup
) sbio_scl (
    .INPUT_CLK(ICE_CLK), 
    .PACKAGE_PIN(SCL),
    .OUTPUT_ENABLE(SCL_PULLDOWN), 
    .D_OUT_0(1'b 0),
    .D_IN_0(SCL_DIN)
);

endmodule