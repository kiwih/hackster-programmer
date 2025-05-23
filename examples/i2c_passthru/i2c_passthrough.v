`default_nettype none

module i2c_passthrough(
    input wire ICE_CLK,
    
    inout wire global_sda, global_scl,
    inout wire periph_sda, periph_scl,

    output reg ICE_LED
);

reg [24:0] counter = 0;
always @(posedge ICE_CLK) begin
    counter <= counter + 1;
    ICE_LED <= counter[23];
end


wire enable_pasthrough = 1; //set to 1 to enable passthrough, 0 to disable
    
//-----------I2C interception-------------------------
// for i2c - both sides are high impedance inputs by default - when one side is pulled low, FPGA pulls the other side low and waits until the side that went low is released to release
// in this way, we get bidirectionality

wire global_sda_di;
wire global_sda_oe;

SB_IO #(
    .PIN_TYPE(6'b 1010_00), // 1010_01 is bidirectional with registered input
    .PULLUP(1'b 0), // no pullup
) sbio_global_sda (
    .INPUT_CLK(ICE_CLK), 
    .PACKAGE_PIN(global_sda),
    .OUTPUT_ENABLE(global_sda_oe), 
    .D_OUT_0(1'b 0),
    .D_IN_0(global_sda_di)
);

wire global_scl_di, global_scl_tmp1;
reg global_scl_tmp2;
wire global_scl_oe;

SB_IO #(
    .PIN_TYPE(6'b 1010_00), // 1010_01 is bidirectional with registered input
    .PULLUP(1'b 0), // no pullup
) sbio_global_scl (
    .INPUT_CLK(ICE_CLK), 
    .PACKAGE_PIN(global_scl),
    .OUTPUT_ENABLE(global_scl_oe), 
    .D_OUT_0(1'b 0),
    .D_IN_0(global_scl_di)
);

wire periph_sda_di;
wire periph_sda_oe;

SB_IO #(
    .PIN_TYPE(6'b 1010_00), // 1010_01 is bidirectional with registered input
    .PULLUP(1'b 0), // no pullup
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
    .PULLUP(1'b 0), // no pullup
) sbio_periph_scl (
    .INPUT_CLK(ICE_CLK), 
    .PACKAGE_PIN(periph_scl),
    .OUTPUT_ENABLE(periph_scl_oe),
    .D_OUT_0(1'b 0),
    .D_IN_0(periph_scl_di)
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
        if(global_scl_di == 0) begin
            scl_global_to_ice40 = 1;
        end else if(periph_scl_di == 0) begin
            scl_ice40_to_global = 1;
        end
    end else begin
        if(scl_global_to_ice40 == 1) begin
            if(global_scl_di == 1) begin
                scl_global_to_ice40 = 0;
                scl_delay_cnt <= 4'd15;
            end
        end else if(scl_ice40_to_global == 1) begin
            if(periph_scl_di == 1) begin
                scl_ice40_to_global = 0;
                scl_delay_cnt <= 4'd15;
            end
        end
    end
    
    if(sda_delay_cnt == 0 && sda_global_to_ice40 == 0 && sda_ice40_to_global == 0) begin //etc (same as above, but for SDA)
        if(global_sda_di == 0) begin
            sda_global_to_ice40 = 1;
        end else if(periph_sda_di == 0) begin
            sda_ice40_to_global = 1;
        end
    end else begin
        if(sda_global_to_ice40 == 1) begin
            if(global_sda_di == 1) begin
                sda_global_to_ice40 = 0;
                sda_delay_cnt <= 4'd7;
            end
        end else if(sda_ice40_to_global == 1) begin
            if(periph_sda_di == 1) begin
                sda_ice40_to_global = 0;
                sda_delay_cnt <= 4'd7;
            end
        end
    end
end

//the output enables are then simply the direction we want to hold (since "enabling" will set them to 0)
assign global_scl_oe = scl_ice40_to_global;
assign periph_scl_oe = scl_global_to_ice40;    
assign global_sda_oe = sda_ice40_to_global;
assign periph_sda_oe = sda_global_to_ice40; 

endmodule