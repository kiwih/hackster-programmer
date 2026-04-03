`default_nettype none

module i2c_read_write_rtc (
    input wire ICE_CLK,
    inout wire PERIPH_SDA, PERIPH_SCL,
    input wire PI_ICE_BTN,
    output wire ICE_LED, RGB_B,
    input wire PERIPH_INT
);

wire periph_sda_di, periph_scl_di, periph_sda_pulldown, periph_scl_pulldown;

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

assign ICE_LED = PERIPH_INT; // Light up LED when we get an interrupt from the RTC

localparam [7:1] rtc_i2c_address = 7'h51; // RTC address

localparam [7:0] reg_cs2 = 8'h01;
localparam [7:0] reg_timer_control = 8'h0E;
localparam [7:0] reg_timer = 8'h0F;

localparam [7:0] cs2_tie = 8'h01; // enable timer interrupt
localparam [7:0] timer_disable_1_per_min = 8'h03; // TE=0, TD=11
localparam [7:0] timer_enable_1_per_min = 8'h83; // TE=1, TD=11 

//need to write the following sequence
// reg_timer_control = timer_disable_1_per_min
// reg_cs2 = cs2_tie
// reg_timer = 1 (peripheral will count down from this value and trigger an interrupt when it hits 0)
// reg_timer_control = timer_enable_1_per_min

// ------------------- Declare your signals here ------------------------

reg periph_i2c_rw;

reg periph_i2c_start;
reg [7:0] periph_i2c_data_tx;
reg [7:0] periph_i2c_data_byte_addr;

reg periph_i2c_rw;

reg periph_i2c_busy;

// ------------------- Instantiate i2c master here -----------------------

i2c_master i2c_master_inst(
    .i_clk(ICE_CLK),
    .reset_n(1),
    .i_addr_w_rw({rtc_i2c_address, periph_i2c_rw}),
    .i_sub_addr({8'h0, periph_i2c_data_byte_addr}),
    .i_sub_len(0),
    .i_byte_len(23'h1), //we only ever send one byte
    .i_data_write(periph_i2c_data_tx),
    .req_trans(periph_i2c_start),

    .data_out(),
    .valid_out(), //we don't need to read data

    .scl(periph_scl_di),
    .sda(periph_sda_di),
    .scl_pulldown(periph_scl_pulldown),
    .sda_pulldown(periph_sda_pulldown),

    .req_data_chunk(),
    .busy(periph_i2c_busy),
    .nack()
);

reg [3:0] state = 0; // state variable for our FSM that will perform the write and read sequence to the RTC
localparam [3:0] S_IDLE = 0, 
                 S_WRITE_TIMER_CONTROL_DISABLE = 1, 
                 S_WRITE_TIMER_CONTROL_DISABLE_WAIT = 2,
                 S_WRITE_CS2 = 3,
                 S_WRITE_CS2_WAIT = 4,
                 S_WRITE_TIMER = 5, 
                 S_WRITE_TIMER_WAIT = 6,
                 S_WRITE_TIMER_CONTROL_ENABLE = 7,
                 S_WRITE_TIMER_CONTROL_ENABLE_WAIT = 8,
                 S_DONE = 9;

reg btn_sync_reg;

always @(posedge ICE_CLK) begin
    btn_sync_reg <= PI_ICE_BTN; // synchronize button press to our clock domain
end

always @(posedge ICE_CLK) begin
    periph_i2c_start <= 0;
    case (state)
        S_IDLE: begin
            if (btn_sync_reg) begin // Start the sequence when we press the button
                state <= S_WRITE_TIMER_CONTROL_DISABLE;
            end
        end
        S_WRITE_TIMER_CONTROL_DISABLE: begin
            if (!periph_i2c_busy) begin
                periph_i2c_rw <= 0; // write
                periph_i2c_data_byte_addr <= reg_timer_control;
                periph_i2c_data_tx <= timer_disable_1_per_min;
                periph_i2c_start <= 1;
                state <= S_WRITE_TIMER_CONTROL_DISABLE_WAIT;
            end
        end
        S_WRITE_TIMER_CONTROL_DISABLE_WAIT: begin
            if (!periph_i2c_busy) begin
                state <= S_WRITE_CS2;
            end
        end
        S_WRITE_CS2: begin
            if (!periph_i2c_busy) begin
                periph_i2c_rw <= 0; // write
                periph_i2c_data_byte_addr <= reg_cs2;
                periph_i2c_data_tx <= cs2_tie;
                periph_i2c_start <= 1;
                state <= S_WRITE_CS2_WAIT;
            end
        end
        S_WRITE_CS2_WAIT: begin
            if (!periph_i2c_busy) begin
                state <= S_WRITE_TIMER;
            end
        end
        S_WRITE_TIMER: begin 
            if (!periph_i2c_busy) begin
                periph_i2c_rw <= 0; // write
                periph_i2c_data_byte_addr <= reg_timer;
                periph_i2c_data_tx <= 8'h01; // count down from 1 so we get an interrupt every minute (assuming our clock is set correctly)
                periph_i2c_start <= 1;
                state <= S_WRITE_TIMER_WAIT;
            end
        end
        S_WRITE_TIMER_WAIT: begin 
            if (!periph_i2c_busy) begin
                state <= S_WRITE_TIMER_CONTROL_ENABLE;
            end
        end
        S_WRITE_TIMER_CONTROL_ENABLE: begin 
            if (!periph_i2c_busy) begin
                periph_i2c_rw <= 0; // write
                periph_i2c_data_byte_addr <= reg_timer_control;
                periph_i2c_data_tx <= timer_enable_1_per_min;
                periph_i2c_start <= 1;
                state <= S_WRITE_TIMER_CONTROL_ENABLE_WAIT;
            end
        end
        S_WRITE_TIMER_CONTROL_ENABLE_WAIT: begin
            if (!periph_i2c_busy) begin
                state <= S_DONE;
            end
        end
        S_DONE: begin
            // We're done with the sequence, just stay here
            state <= S_DONE;
        end
        
    endcase
end

assign RGB_B = (state == S_DONE) ? 1 : 0; // Light blue off when we're done with the sequence

endmodule