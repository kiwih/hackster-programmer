`default_nettype none

module special_rpi(
    input wire ICE_CLK,
    
    inout wire PI_SDA, PI_SCL,
    inout wire PERIPH_SDA, PERIPH_SCL,
    input wire IMU_INT,

    output wire ICE_LED,
    output reg RGB_B
);

assign ICE_LED = IMU_INT;

wire enable_pasthrough = 1; //set to 1 to enable passthrough, 0 to disable
    
//-----------I2C interception-------------------------
// for i2c - both sides are high impedance inputs by default - when one side is pulled low, FPGA pulls the other side low and waits until the side that went low is released to release
// in this way, we get bidirectionality

wire PI_SDA_di;
wire PI_SDA_oe;

SB_IO #(
    .PIN_TYPE(6'b 1010_00), // 1010_01 is bidirectional with registered input
    .PULLUP(1'b 0), // no pullup
) sbio_PI_SDA (
    .INPUT_CLK(ICE_CLK), 
    .PACKAGE_PIN(PI_SDA),
    .OUTPUT_ENABLE(PI_SDA_oe), 
    .D_OUT_0(1'b 0),
    .D_IN_0(PI_SDA_di)
);

wire PI_SCL_di, PI_SCL_tmp1;
reg PI_SCL_tmp2;
wire PI_SCL_oe;

SB_IO #(
    .PIN_TYPE(6'b 1010_00), // 1010_01 is bidirectional with registered input
    .PULLUP(1'b 0), // no pullup
) sbio_PI_SCL (
    .INPUT_CLK(ICE_CLK), 
    .PACKAGE_PIN(PI_SCL),
    .OUTPUT_ENABLE(PI_SCL_oe), 
    .D_OUT_0(1'b 0),
    .D_IN_0(PI_SCL_di)
);

wire PERIPH_SDA_di;
wire PERIPH_SDA_oe;

SB_IO #(
    .PIN_TYPE(6'b 1010_00), // 1010_01 is bidirectional with registered input
    .PULLUP(1'b 0), // no pullup
) sbio_PERIPH_SDA (
    .INPUT_CLK(ICE_CLK), 
    .PACKAGE_PIN(PERIPH_SDA),
    .OUTPUT_ENABLE(PERIPH_SDA_oe),
    .D_OUT_0(1'b 0),
    .D_IN_0(PERIPH_SDA_di)
);

wire PERIPH_SCL_di;
wire PERIPH_SCL_oe;

SB_IO #(
    .PIN_TYPE(6'b 1010_00), // 1010_01 is bidirectional with registered input
    .PULLUP(1'b 0), // no pullup
) sbio_PERIPH_SCL (
    .INPUT_CLK(ICE_CLK), 
    .PACKAGE_PIN(PERIPH_SCL),
    .OUTPUT_ENABLE(PERIPH_SCL_oe),
    .D_OUT_0(1'b 0),
    .D_IN_0(PERIPH_SCL_di)
);

reg scl_global_to_ice40 = 0; 
reg scl_ice40_to_global = 0; 
reg [3:0] scl_delay_cnt = 0;

reg sda_global_to_ice40 = 0; 
reg sda_ice40_to_global = 0; //if a 0 is detected on the pi side of SDA, then we set this to "1" for the duration
reg [3:0] sda_delay_cnt = 0;

always @(posedge ICE_CLK) begin
    if(scl_delay_cnt > 0) begin
        scl_delay_cnt <= scl_delay_cnt - 1;
    end
    if(sda_delay_cnt > 0) begin
        sda_delay_cnt <= sda_delay_cnt - 1;
    end
    //ICE_LED = scl_pi_to_a7;
    if(scl_delay_cnt == 0 && scl_global_to_ice40 == 0 && scl_ice40_to_global == 0) begin
        if(PI_SCL_di == 0) begin
            scl_global_to_ice40 = 1;
        end else if(PERIPH_SCL_di == 0) begin
            scl_ice40_to_global = 1;
        end
    end else begin
        if(scl_global_to_ice40 == 1) begin
            if(PI_SCL_di == 1) begin
                scl_global_to_ice40 = 0;
                scl_delay_cnt <= 4'd15;
            end
        end else if(scl_ice40_to_global == 1) begin
            if(PERIPH_SCL_di == 1) begin
                scl_ice40_to_global = 0;
                scl_delay_cnt <= 4'd15;
            end
        end
    end
    
    if(sda_delay_cnt == 0 && sda_global_to_ice40 == 0 && sda_ice40_to_global == 0) begin //etc (same as above, but for SDA)
        if(PI_SDA_di == 0) begin
            sda_global_to_ice40 = 1;
        end else if(PERIPH_SDA_di == 0) begin
            sda_ice40_to_global = 1;
        end
    end else begin
        if(sda_global_to_ice40 == 1) begin
            if(PI_SDA_di == 1) begin
                sda_global_to_ice40 = 0;
                sda_delay_cnt <= 4'd7;
            end
        end else if(sda_ice40_to_global == 1) begin
            if(PERIPH_SDA_di == 1) begin
                sda_ice40_to_global = 0;
                sda_delay_cnt <= 4'd7;
            end
        end
    end
end

//the output enables are then simply the direction we want to hold (since "enabling" will set them to 0)
assign PI_SCL_oe = scl_ice40_to_global;
assign PERIPH_SCL_oe = scl_global_to_ice40;    
assign PI_SDA_oe = sda_ice40_to_global;
assign PERIPH_SDA_oe = sda_global_to_ice40; 

//make a blinky LED on RGB_B
reg [24:0] counter2 = 0;
always @(posedge ICE_CLK) begin
    counter2 <= counter2 + 1;
    RGB_B <= counter2[23];
end

endmodule