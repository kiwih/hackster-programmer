`default_nettype none

module i2c_reg_and_pass(
    input wire ICE_CLK,
    
    inout wire rp2040_sda, rp2040_scl,
    inout wire periph_sda, periph_scl

    wire [7:0] i2c_data_rd[31:0],
    wire i2c_data_rd_valid,
    wire [7:0] i2c_data_wr[31:0],
    wire i2c_data_wr_finish,
);

localparam ice_i2c_address = 8'h42;

wire enable_pasthrough = 1; //set to 1 to enable passthrough, 0 to disable
    
//-----------I2C interception-------------------------
// for i2c - both sides are high impedance inputs by default - when one side is pulled low, FPGA pulls the other side low and waits until the side that went low is released to release
// in this way, we get bidirectionality

wire rp2040_sda_di;
wire rp2040_sda_oe;

SB_IO #(
    .PIN_TYPE(6'b 1010_00), // 1010_01 is bidirectional with registered input
    .PULLUP(1'b 1), // yes pullup
) sbio_rp2040_sda (
    .INPUT_CLK(ICE_CLK), 
    .PACKAGE_PIN(rp2040_sda),
    .OUTPUT_ENABLE(rp2040_sda_oe), 
    .D_OUT_0(1'b 0),
    .D_IN_0(rp2040_sda_di)
);

wire rp2040_scl_di, rp2040_scl_tmp1;
reg rp2040_scl_tmp2;
wire rp2040_scl_oe;

SB_IO #(
    .PIN_TYPE(6'b 1010_00), // 1010_01 is bidirectional with registered input
    .PULLUP(1'b 1), // yes pullup
) sbio_rp2040_scl (
    .INPUT_CLK(ICE_CLK), 
    .PACKAGE_PIN(rp2040_scl),
    .OUTPUT_ENABLE(rp2040_scl_oe), 
    .D_OUT_0(1'b 0),
    .D_IN_0(rp2040_scl_di)
);

wire periph_sda_di;
wire periph_sda_oe;

SB_IO #(
    .PIN_TYPE(6'b 1010_00), // 1010_01 is bidirectional with registered input
    .PULLUP(1'b 1), // yes pullup
) sbio_periph_sda (
    .INPUT_CLK(ICE_CLK), 
    .PACKAGE_PIN(periph_sda),
    .OUTPUT_ENABLE(periph_sda_oe),
    .D_OUT_0(1'b 0),
    .D_IN_0(periph_sda_di)
);

wire periph_scl_di;
wire periph_scl_oe;

SB_IO #(
    .PIN_TYPE(6'b 1010_00), // 1010_01 is bidirectional with registered input
    .PULLUP(1'b 1), // yes pullup
) sbio_periph_scl (
    .INPUT_CLK(ICE_CLK), 
    .PACKAGE_PIN(periph_scl),
    .OUTPUT_ENABLE(periph_scl_oe),
    .D_OUT_0(1'b 0),
    .D_IN_0(periph_scl_di)
);

wire ice_scl_di = rp2040_scl_di | periph_scl_di;
wire ice_sda_di = rp2040_sda_di | periph_sda_di;
wire ice_scl_ndo;
wire ice_sda_ndo;

reg scl_rp2040_to_ice40 = 0; 
reg scl_ice40_to_rp2040 = 0; 
reg [3:0] scl_delay_cnt = 0;

reg sda_rp2040_to_ice40 = 0; 
reg sda_ice40_to_rp2040 = 0; //if a 0 is detected on the pi side of SDA, then we set this to "1" for the duration
reg [3:0] sda_delay_cnt = 0;

always @(posedge ICE_CLK) begin
    if(scl_delay_cnt > 0) begin
        scl_delay_cnt <= scl_delay_cnt - 1;
    end
    if(sda_delay_cnt > 0) begin
        sda_delay_cnt <= sda_delay_cnt - 1;
    end
    //ICE_LED = scl_pi_to_a7;
    if(scl_delay_cnt == 0 && scl_rp2040_to_ice40 == 0 && scl_ice40_to_rp2040 == 0 && ice_scl_ndo == 0) begin
        if(rp2040_scl_di == 0) begin
            scl_rp2040_to_ice40 = 1;
        end else if(periph_scl_di == 0) begin
            scl_ice40_to_rp2040 = 1;
        end 
    end else begin
        if(scl_rp2040_to_ice40 == 1) begin
            if(rp2040_scl_di == 1) begin
                scl_rp2040_to_ice40 = 0;
                scl_delay_cnt <= 4'd15;
            end
        end else if(scl_ice40_to_rp2040 == 1) begin
            if(periph_scl_di == 1) begin
                scl_ice40_to_rp2040 = 0;
                scl_delay_cnt <= 4'd15;
            end
        end
    end
    
    if(sda_delay_cnt == 0 && sda_rp2040_to_ice40 == 0 && sda_ice40_to_rp2040 == 0 && ice_sda_ndo == 0) begin //etc (same as above, but for SDA)
        if(rp2040_sda_di == 0) begin
            sda_rp2040_to_ice40 = 1;
        end else if(periph_sda_di == 0) begin
            sda_ice40_to_rp2040 = 1;
        end
    end else begin
        if(sda_rp2040_to_ice40 == 1) begin
            if(rp2040_sda_di == 1) begin
                sda_rp2040_to_ice40 = 0;
                sda_delay_cnt <= 4'd7;
            end
        end else if(sda_ice40_to_rp2040 == 1) begin
            if(periph_sda_di == 1) begin
                sda_ice40_to_rp2040 = 0;
                sda_delay_cnt <= 4'd7;
            end
        end
    end
end

//the output enables are then simply the direction we want to hold (since "enabling" will set them to 0)
assign rp2040_scl_oe = scl_ice40_to_rp2040 | ice_scl_ndo;
assign periph_scl_oe = scl_rp2040_to_ice40 | ice_scl_ndo;    
assign rp2040_sda_oe = sda_ice40_to_rp2040 | ice_sda_ndo;
assign periph_sda_oe = sda_rp2040_to_ice40 | ice_sda_ndo; 

i2c_simple_slave #(
    .i2c_address(i2c_address)
) i2c_simple_slave_inst (
    .clk(ICE_CLK),
    .rst_n(1),
    .scl_di(ice_scl_di),
    .sda_di(ice_sda_di),
    .scl_ndo(ice_scl_ndo),
    .sda_ndo(ice_sda_ndo),
    .i2c_data_rd(i2c_data_rd),
    .i2c_data_rd_valid(i2c_data_rd_valid),
    .i2c_data_wr(i2c_data_wr),
    .i2c_data_wr_finish(i2c_data_wr_finish)
);

endmodule