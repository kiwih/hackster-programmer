`default_nettype none

module i2c_registers_top(
    input wire ICE_CLK,
    
    inout wire APP_SDA, APP_SCL,
    inout wire PERIPH_SDA, PERIPH_SCL,

    input wire PI_ICE_BTN,
    output wire ICE_LED, RGB_R, RGB_G, RGB_B,

    output wire [5:2] APP
);

localparam ice_i2c_address = 7'h42;

wire app_sda_di, app_scl_di, app_sda_pulldown, app_scl_pulldown;

i2c_pin_primitives_ice40 APP_I2C(
    .ICE_CLK(ICE_CLK),
    .SDA(APP_SDA),
    .SCL(APP_SCL),
    .SDA_DIN(app_sda_di),
    .SCL_DIN(app_scl_di),
    .SDA_PULLDOWN(app_sda_pulldown),
    .SCL_PULLDOWN(app_scl_pulldown)
);

wire [7:0] i2c_rx;
reg [7:0] din = 0;
wire din_wr;
reg [7:0] dout = 0;

always @(posedge ICE_CLK) begin
    if(din_wr) begin
        din <= i2c_rx;
    end
end

i2c_simple_slave #(
    .i2c_address(ice_i2c_address)
) i2c_simple_slave_inst (
    .clk(ICE_CLK),
    .rst_n(1),
    .scl_di(app_scl_di),
    .sda_di(app_sda_di),
    .scl_pulldown(app_scl_pulldown),
    .sda_pulldown(app_sda_pulldown),
    .stall(0),
    //.i2c_addr_rw(?),
    //.i2c_addr_rw_valid_stb(?),
    .i2c_data_rx(i2c_rx),
    .i2c_data_rx_valid_stb(din_wr),
    .i2c_data_tx(dout),
    //.i2c_data_tx_loaded_stb(?),
    //.i2c_data_tx_done_stb(?),
    //.i2c_error_stb(?)
    .debug_i2c_state(APP[5:2])
);

assign ICE_LED = din[0];
assign RGB_R = din[1];
assign RGB_G = din[2];
assign RGB_B = din[3];

always @(posedge ICE_CLK)
    dout <= {8{PI_ICE_BTN}};

endmodule