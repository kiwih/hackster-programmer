`default_nettype none

module i2c_write_rtc (
    input wire ICE_CLK,
    inout wire PERIPH_SDA, PERIPH_SCL,
    input wire PI_ICE_BTN,
    output wire ICE_LED, RGB_B, RGB_R, RGB_G,
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
localparam [7:0] timer_disable_60_per_min = 8'h02; // TE=0, TD=10
localparam [7:0] timer_enable_60_per_min = 8'h82; // TE=1, TD=10

//need to write the following sequence
// reg_timer_control = timer_disable_60_per_min
// reg_cs2 = cs2_tie
// reg_timer = 60 (peripheral will count down from this value and trigger an interrupt when it hits 0)
// reg_timer_control = timer_enable_60_per_min

// ------------------- Declare your signals here ------------------------

reg periph_i2c_start;
reg [7:0] periph_i2c_data_tx = 8'h00;

wire periph_i2c_stalling;

reg periph_i2c_rw = 0;

reg periph_i2c_busy;

reg periph_i2c_stop;
reg periph_i2c_continue;

wire periph_nack;
wire periph_i2c_stretching;

// ------------------- Instantiate i2c master here -----------------------

i2c_master i2c_master_inst(
    .clk(ICE_CLK), //50MHz clock input
    .rst_n(1),

    /* i2c pin interface */
    .scl_di(periph_scl_di),
    .sda_di(periph_sda_di),
    .scl_pulldown(periph_scl_pulldown),
    .sda_pulldown(periph_sda_pulldown),

    /* handshakes for controlling the transaction */
    .transaction_start_stb(periph_i2c_start),
    .transaction_active(periph_i2c_busy),
    .transaction_stalling(periph_i2c_stalling),
    .transaction_restart(1'b0), // not used in this example
    .transaction_stop(periph_i2c_stop),
    .transaction_continue(periph_i2c_continue),

    /* transaction data i/o */
    .i2c_addr_rw({rtc_i2c_address, periph_i2c_rw}),

    .i2c_data_tx(periph_i2c_data_tx),
    .i2c_data_tx_loaded_stb(),
    .i2c_data_tx_done_stb(),

    .i2c_data_rx(), //not used in this example
    .i2c_data_rx_valid_stb(),

    /* error reporting */
    .i2c_slave_stretching(periph_i2c_stretching), 
    .i2c_error_stb(), //not used in this example
    .i2c_nack_stb(periph_nack)
);

assign RGB_G = ~periph_i2c_busy;

reg nacked = 0;
always@(posedge ICE_CLK) begin
    if (periph_nack) begin
        nacked <= 1;
    end
end

assign RGB_R = ~nacked; // Light red if we're getting stretched at any point in the sequence

reg [3:0] state = 0; // state variable for our FSM that will perform the write and read sequence to the RTC
localparam [3:0] S_IDLE = 0, 

                 S_WRITE_TIMER_CONTROL_DISABLE_ADDR_WAIT = 1,
                 S_WRITE_TIMER_CONTROL_DISABLE_BYTE1_WAIT = 2, 
                 S_WRITE_TIMER_CONTROL_DISABLE_BYTE2_WAIT = 3,
                 S_WRITE_TIMER_CONTROL_DISABLE_STOP = 4,

                 S_WRITE_CS2_ADDR_WAIT = 5,
                 S_WRITE_CS2_BYTE1_WAIT = 6,
                 S_WRITE_CS2_BYTE2_WAIT = 7,

                 S_WRITE_TIMER_ADDR_WAIT = 8,
                 S_WRITE_TIMER_BYTE1_WAIT = 9,
                 S_WRITE_TIMER_BYTE2_WAIT = 10,

                 S_WRITE_TIMER_CONTROL_ENABLE_ADDR_WAIT = 11,
                 S_WRITE_TIMER_CONTROL_ENABLE_BYTE1_WAIT = 12,
                 S_WRITE_TIMER_CONTROL_ENABLE_BYTE2_WAIT = 13,

                 S_DONE = 14;

reg btn_sync_reg;

always @(posedge ICE_CLK) begin
    btn_sync_reg <= PI_ICE_BTN; // synchronize button press to our clock domain
end

reg wait_for_handshake = 0;

always @(posedge ICE_CLK) begin
    periph_i2c_start <= 0;
    periph_i2c_stop <= 0;
    periph_i2c_continue <= 0;

    case (state)

        S_IDLE: begin
            if (btn_sync_reg) begin // Start the sequence when we press the button
                state <= S_WRITE_TIMER_CONTROL_DISABLE_ADDR_WAIT;
                periph_i2c_rw <= 0; // write
                wait_for_handshake <= 0;
            end
        end

        S_WRITE_TIMER_CONTROL_DISABLE_ADDR_WAIT: begin
            periph_i2c_start <= 1;

            if(periph_i2c_stalling && wait_for_handshake == 0) begin
                periph_i2c_start <= 0;
                wait_for_handshake <= 1;
                periph_i2c_continue <= 1;
                periph_i2c_data_tx <= reg_timer_control;

            end else if(wait_for_handshake == 1 && ~periph_i2c_stalling) begin
                state <= S_WRITE_TIMER_CONTROL_DISABLE_BYTE1_WAIT;
                wait_for_handshake <= 0;

            end
        end

        S_WRITE_TIMER_CONTROL_DISABLE_BYTE1_WAIT: begin
            if (periph_i2c_stalling && wait_for_handshake == 0) begin
                periph_i2c_data_tx <= timer_disable_60_per_min;
                periph_i2c_continue <= 1;
                wait_for_handshake <= 1;

            end else if(wait_for_handshake == 1 && ~periph_i2c_stalling) begin
                state <= S_WRITE_TIMER_CONTROL_DISABLE_BYTE2_WAIT;
                wait_for_handshake <= 0;
            end
        end

        S_WRITE_TIMER_CONTROL_DISABLE_BYTE2_WAIT: begin
            if (periph_i2c_stalling && wait_for_handshake == 0) begin
                periph_i2c_stop <= 1;
                wait_for_handshake <= 1;
            end

            if (!periph_i2c_busy) begin
                wait_for_handshake <= 0;
                state <= S_WRITE_CS2_ADDR_WAIT;
                periph_i2c_rw <= 0; // write
            end
        end

        S_WRITE_CS2_ADDR_WAIT: begin
            periph_i2c_start <= 1;

            if(periph_i2c_stalling && wait_for_handshake == 0) begin
                periph_i2c_start <= 0;
                wait_for_handshake <= 1;
                periph_i2c_continue <= 1;
                periph_i2c_data_tx <= reg_cs2;

            end else if(wait_for_handshake == 1 && ~periph_i2c_stalling) begin
                state <= S_WRITE_CS2_BYTE1_WAIT;
                wait_for_handshake <= 0;

            end
        end

        S_WRITE_CS2_BYTE1_WAIT: begin
            if (periph_i2c_stalling && wait_for_handshake == 0) begin
                periph_i2c_data_tx <= cs2_tie;
                periph_i2c_continue <= 1;
                wait_for_handshake <= 1;

            end else if(wait_for_handshake == 1 && ~periph_i2c_stalling) begin
                state <= S_WRITE_CS2_BYTE2_WAIT;
                wait_for_handshake <= 0;
            end
        end

        S_WRITE_CS2_BYTE2_WAIT: begin
            if (periph_i2c_stalling && wait_for_handshake == 0) begin
                periph_i2c_stop <= 1;
                wait_for_handshake <= 1;
            end

            if (!periph_i2c_busy) begin
                wait_for_handshake <= 0;
                state <= S_WRITE_TIMER_ADDR_WAIT;
                periph_i2c_rw <= 0; // write
            end
        end

        S_WRITE_TIMER_ADDR_WAIT: begin
            periph_i2c_start <= 1;

            if(periph_i2c_stalling && wait_for_handshake == 0) begin
                periph_i2c_start <= 0;
                wait_for_handshake <= 1;
                periph_i2c_continue <= 1;
                periph_i2c_data_tx <= reg_timer;

            end else if(wait_for_handshake == 1 && ~periph_i2c_stalling) begin
                state <= S_WRITE_TIMER_BYTE1_WAIT;
                wait_for_handshake <= 0;

            end
        end

        S_WRITE_TIMER_BYTE1_WAIT: begin
            if (periph_i2c_stalling && wait_for_handshake == 0) begin
                periph_i2c_data_tx <= 8'd60; // start counting down from 1 so we get an interrupt after 1 minute
                periph_i2c_continue <= 1;
                wait_for_handshake <= 1;

            end else if(wait_for_handshake == 1 && ~periph_i2c_stalling) begin
                state <= S_WRITE_TIMER_BYTE2_WAIT;
                wait_for_handshake <= 0;
            end
        end

        S_WRITE_TIMER_BYTE2_WAIT: begin
            if (periph_i2c_stalling && wait_for_handshake == 0) begin
                periph_i2c_stop <= 1;
                wait_for_handshake <= 1;
            end

            if (!periph_i2c_busy) begin
                wait_for_handshake <= 0;
                state <= S_WRITE_TIMER_CONTROL_ENABLE_ADDR_WAIT;
                periph_i2c_rw <= 0; // write
            end
        end

        S_WRITE_TIMER_CONTROL_ENABLE_ADDR_WAIT: begin
            periph_i2c_start <= 1;

            if(periph_i2c_stalling && wait_for_handshake == 0) begin
                periph_i2c_start <= 0;
                wait_for_handshake <= 1;
                periph_i2c_continue <= 1;
                periph_i2c_data_tx <= reg_timer_control;

            end else if(wait_for_handshake == 1 && ~periph_i2c_stalling) begin
                state <= S_WRITE_TIMER_CONTROL_ENABLE_BYTE1_WAIT;
                wait_for_handshake <= 0;

            end
        end

        S_WRITE_TIMER_CONTROL_ENABLE_BYTE1_WAIT: begin
            if (periph_i2c_stalling && wait_for_handshake == 0) begin
                periph_i2c_data_tx <= timer_enable_60_per_min;
                periph_i2c_continue <= 1;
                wait_for_handshake <= 1;

            end else if(wait_for_handshake == 1 && ~periph_i2c_stalling) begin
                state <= S_WRITE_TIMER_CONTROL_ENABLE_BYTE2_WAIT;
                wait_for_handshake <= 0;
            end
        end

        S_WRITE_TIMER_CONTROL_ENABLE_BYTE2_WAIT: begin
            if (periph_i2c_stalling && wait_for_handshake == 0) begin
                periph_i2c_stop <= 1;
                wait_for_handshake <= 1;
            end

            if (!periph_i2c_busy) begin
                wait_for_handshake <= 0;
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