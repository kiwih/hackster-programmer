`default_nettype none

module i2c_read_write_eeprom (
    input wire ICE_CLK,
    inout wire PERIPH_SDA, PERIPH_SCL,
    input wire PI_ICE_BTN,
    output wire ICE_LED, RGB_B
);

wire periph_sda_di, periph_scl_di, periph_sda_pulldown, periph_scl_pulldown;

// Instantiate eeprom i2c scl and sda inout pins.
i2c_pin_primitives_ice40 PERIPH_I2C(
    .ICE_CLK(ICE_CLK),
    .SDA(PERIPH_SDA),
    .SCL(PERIPH_SCL),
    .SDA_DIN(periph_sda_di),
    .SCL_DIN(periph_scl_di),
    .SDA_PULLDOWN(periph_sda_pulldown),
    .SCL_PULLDOWN(periph_scl_pulldown)
);

// ------------------- TODO: Declare your signals here ------------------------



// ------------------- TODO: Instantiate i2c master here -----------------------



// ------------------- TODO: FSM that swiches between one read and one write operation ---------------



endmodule