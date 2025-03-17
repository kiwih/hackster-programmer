`default_nettype none

module i2c_registers_top(
    input wire ICE_CLK,
    
    inout wire GLOBAL_SDA, GLOBAL_SCL,
    inout wire PERIPH_SDA, PERIPH_SCL,

    input wire PI_ICE_BTN,
    output wire ICE_LED, RGB_R, RGB_G, RGB_B,

    output wire [5:2] APP
);

localparam ice_i2c_address = 7'h42;

wire global_sda_di, global_scl_di, global_sda_pulldown, global_scl_pulldown;

i2c_pin_primitives_ice40 APP_I2C(
    .ICE_CLK(ICE_CLK),
    .SDA(GLOBAL_SDA),
    .SCL(GLOBAL_SCL),
    .SDA_DIN(global_sda_di),
    .SCL_DIN(global_scl_di),
    .SDA_PULLDOWN(global_sda_pulldown),
    .SCL_PULLDOWN(global_scl_pulldown)
);

wire [7:0] i2c_rx;
wire i2c_rx_valid;
reg [7:0] din = 0;
reg [7:0] dout = 0;

i2c_simple_slave #(
    .i2c_address(ice_i2c_address)
) i2c_simple_slave_inst (
    .clk(ICE_CLK),
    .rst_n(1),
    .scl_di(global_scl_di),
    .sda_di(global_sda_di),
    .scl_pulldown(global_scl_pulldown),
    .sda_pulldown(global_sda_pulldown),
    .stall(0),
    .i2c_data_rx(i2c_rx),
    .i2c_data_rx_valid_stb(i2c_rx_valid),
    .i2c_data_tx(dout),
    .debug_i2c_state(APP[5:2])
);

// ############## Starter code: text ICE button value to I2C master ##################
always @(posedge ICE_CLK)
    dout <= {8{PI_ICE_BTN}};



// ############## TODO: Connect the least three significant bits of i2c slave received data to RGB ################# 


endmodule