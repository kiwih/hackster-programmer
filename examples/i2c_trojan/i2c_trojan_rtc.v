`default_nettype none

module i2c_trojan_rtc(
    input wire ICE_CLK,
    
    inout wire GLOBAL_SDA, GLOBAL_SCL,
    inout wire PERIPH_SDA, PERIPH_SCL,

    input wire PI_ICE_BTN,
    output wire ICE_LED, RGB_R, RGB_G, RGB_B,

    output wire [5:2] APP
);

localparam ice_i2c_address = 7'h51;

wire global_sda_di, glocal_scl_di, global_sda_pulldown, global_scl_pulldown,
     periph_sda_di, periph_scl_di, periph_sda_pulldown, periph_scl_pulldown;

i2c_pin_primitives_ice40 GLOBAL_I2C(
    .ICE_CLK(ICE_CLK),
    .SDA(GLOBAL_SDA),
    .SCL(GLOBAL_SCL),
    .SDA_DIN(global_sda_di),
    .SCL_DIN(glocal_scl_di),
    .SDA_PULLDOWN(global_sda_pulldown),
    .SCL_PULLDOWN(global_scl_pulldown)
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

reg global_stall;

wire [7:0] global_i2c_addr_rw;
wire global_i2c_addr_rw_valid_stb;
reg [7:0] global_i2c_addr_rw_reg;
always @(posedge ICE_CLK) begin
    if(global_i2c_addr_rw_valid_stb) begin
        global_i2c_addr_rw_reg <= global_i2c_addr_rw;
    end
end

wire [7:0] global_i2c_data_rx;
reg [7:0] global_i2c_data_rx_reg;
wire global_i2c_data_rx_valid_stb;
always @(posedge ICE_CLK) begin
    if(global_i2c_data_rx_valid_stb) begin
        global_i2c_data_rx_reg <= global_i2c_data_rx;
    end
end

wire [7:0] global_i2c_data_tx;
wire i2c_data_tx_loaded_stb;
wire global_i2c_data_tx_done_stb;

// ------------------- Instantiate i2c master and i2c slave here -----------------------

i2c_simple_slave #(
    .I2C_ADDR(ice_i2c_address)
) i2c_slave_inst (
    .clk(ICE_CLK),
    .rst_n(1'b1),

    .scl_di(glocal_scl_di),
    .sda_di(global_sda_di),
    .sda_pulldown(global_sda_pulldown),
    .scl_pulldown(global_scl_pulldown)

    .stall(global_stall),

    .i2c_addr_rw(global_i2c_addr_rw),
    .i2c_addr_rw_valid_stb(global_i2c_addr_rw_valid_stb),

    .i2c_data_rx(global_i2c_data_rx),
    .i2c_data_rx_valid_stb(global_i2c_data_rx_valid_stb),

    .i2c_data_tx(global_i2c_data_tx),
    .i2c_data_tx_loaded_stb(i2c_data_tx_loaded_stb),
    .i2c_data_tx_done_stb(global_i2c_data_tx_done_stb)
);

i2c_master i2c_master_inst(
    .i_clk(ICE_CLK),
    .reset_n(1),

    .i_addr_w_rw(global_i2c_addr_rw_reg), //we only ever write in this example, so tie the rw bit low
    .i_sub_addr({8'h0, 8'h0}), //we don't use sub addressing in this example, so just tie this to 0
    .i_sub_len(0),
    .read_byte_len(23'h0), //we don't use the rx functionality in this example, so just set this to 0
    .i_data_write(global_i2c_data_rx_reg), //just loop back whatever data we receive on the slave as the data to transmit on the master



// ------------------- FSM that passes all transactions from global (simple slave) to periph (simple master) ---------------
// (we use the stall signals judiciously)



endmodule