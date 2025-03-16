`default_nettype none

module i2c_trojan_accelerometer(
    input wire ICE_CLK,
    
    inout wire GLOBAL_SDA, GLOBAL_SCL,
    inout wire PERIPH_SDA, PERIPH_SCL,

    input wire PI_ICE_BTN,
    output wire ICE_LED, RGB_R, RGB_G, RGB_B,

    output wire [5:2] APP
);

localparam ice_i2c_address = 7'h42;

wire global_sda_di, glocal_scl_di, global_sda_pulldown, glocal_scl_pulldown,
     periph_sda_di, periph_scl_di, periph_sda_pulldown, periph_scl_pulldown;

i2c_pin_primitives_ice40 GLOBAL_I2C(
    .ICE_CLK(ICE_CLK),
    .SDA(GLOBAL_SDA),
    .SCL(GLOBAL_SCL),
    .SDA_DIN(global_sda_di),
    .SCL_DIN(glocal_scl_di),
    .SDA_PULLDOWN(global_sda_pulldown),
    .SCL_PULLDOWN(glocal_scl_pulldown)
);

i2c_pin_primitives_ice40 PERIPH_I2C(
    .ICE_CLK(ICE_CLK),
    .SDA(PERIPH_SDA),
    .SCL(PERIPH_SCL),
    .SDA_DIN(periph_sda_di),
    .SCL_DIN(periph_scl_di),
    .SDA_PULLDOWN(periph_sda_pulldown),
    .SCL_PULLDOWN(periph_scl_pulldown)
);

// ------------------- Declare your signals here ------------------------



// ------------------- Instantiate i2c masters and i2c slave here -----------------------



// ------------------- FSM to control i2c master and slave ---------------




endmodule