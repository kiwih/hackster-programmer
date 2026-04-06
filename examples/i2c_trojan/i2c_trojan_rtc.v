`default_nettype none

module i2c_trojan_rtc (
    input wire ICE_CLK,
    inout wire PERIPH_SDA, PERIPH_SCL,
    inout wire GLOBAL_SDA, GLOBAL_SCL, 
    input wire PI_ICE_BTN,
    output wire ICE_LED, RGB_B, RGB_R, RGB_G,
    input wire PERIPH_INT
);

wire periph_sda_di, periph_scl_di, periph_sda_pulldown, periph_scl_pulldown;
wire global_sda_di, global_scl_di, global_sda_pulldown, global_scl_pulldown;

// Instantiate rtc i2c scl and sda inout pins.
i2c_pin_primitives_ice40 PERIPH_I2C(
    .ICE_CLK(ICE_CLK),
    .SDA(PERIPH_SDA),
    .SCL(PERIPH_SCL),
    .SDA_DIN(periph_sda_di),
    .SCL_DIN(periph_scl_di),
    .SDA_PULLDOWN(periph_sda_pulldown),
    .SCL_PULLDOWN(periph_scl_pulldown)
);

i2c_pin_primitives_ice40 GLOBAL_I2C(
    .ICE_CLK(ICE_CLK),
    .SDA(GLOBAL_SDA),
    .SCL(GLOBAL_SCL),
    .SDA_DIN(global_sda_di),
    .SCL_DIN(global_scl_di),
    .SDA_PULLDOWN(global_sda_pulldown),
    .SCL_PULLDOWN(global_scl_pulldown)
);

localparam [7:1] rtc_i2c_address = 7'h51; // RTC address

// ------------------- Declare your signals here ------------------------


// ------------------- Instantiate i2c master and slave devices here -----------------------


// ------------------- Instantiate your trojan logic itself here -----------------------

endmodule