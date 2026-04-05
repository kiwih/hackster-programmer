/*
 * Author: Hammond Pearce
 * Date: 4/4/2026
 */
`default_nettype none

module i2c_master(
    input wire clk, //50MHz clock input
    input wire rst_n,

    /* i2c pin interface */
    input wire scl_di,
    input wire sda_di,
    output wire scl_pulldown,
    output wire sda_pulldown,

    /* handshakes for controlling the transaction */
    input wire transaction_start_stb, //strobe to start a transaction, must be held high for at least 1 cycle
    output reg transaction_active,    //1 == transaction in progress, 0 == idle
    output reg transaction_stalling,  //1 == transaction is stalling waiting for next byte/instruction
    input wire transaction_restart,   //if 1, will end stall and restart the transaction 
    input wire transaction_stop,      //if 1, will end stall and send a stop condition to end the transaction
    input wire transaction_continue,  //if 1, will end stall and continue the transaction

    /* transaction data i/o */
    input wire [7:0] i2c_addr_rw,

    input wire [7:0] i2c_data_tx,
    output reg i2c_data_tx_loaded_stb,
    output reg i2c_data_tx_done_stb,

    output reg [7:0] i2c_data_rx,
    output reg i2c_data_rx_valid_stb,

    /* error reporting */
    output wire i2c_slave_stretching,
    output reg i2c_error_stb,
    output reg i2c_nack_stb
);

reg periph_scl = 0;
reg periph_sda = 1; // by default no one should hold the sda_out line
reg [3:0] shift_counter = 0;
reg [7:0] data_reg = 0; // used to store addr+rw and transmission data.
reg dummy_write = 0;

assign scl_pulldown = ~periph_scl;
assign sda_pulldown = ~periph_sda; // it's flipped as it's a pulldown.

//
reg timer_en;
reg timer_clr;
reg timer_halfperiod_done;
reg timer_fullperiod_done;

reg timer_1qperiod_stb;
reg timer_2qperiod_stb;
reg timer_3qperiod_stb;

reg [8:0] timer_counter;
always @(posedge clk) begin
    timer_1qperiod_stb <= 0;
    timer_2qperiod_stb <= 0;
    timer_3qperiod_stb <= 0;

    if(timer_clr == 1 || rst_n == 0) begin
        timer_counter <= 0;
        timer_halfperiod_done <= 0;
        timer_fullperiod_done <= 0;
    end else if(timer_en == 1) begin
        if(~timer_fullperiod_done) begin
            timer_counter <= timer_counter + 1;
            if (timer_counter >= 499) // 5000ns 
                timer_fullperiod_done <= 1;
            if (timer_counter >= 249) // 2500ns 
                timer_halfperiod_done <= 1;

            if (timer_counter == 124) // exactly at the quarter period, we can strobe the quarter period signal for timing the state machine transitions
                timer_1qperiod_stb <= 1;
            if (timer_counter == 249) // exactly at the half period, we can strobe the half period signal for timing the state machine transitions
                timer_2qperiod_stb <= 1;
            if (timer_counter == 374) // exactly at the three quarter period, we can strobe the three quarter period signal for timing the state machine transitions
                timer_3qperiod_stb <= 1;
        end
    end
end

// Synchronize the sda_di input to our clock domain
reg sda_di_reg;
always @(posedge clk) begin
    sda_di_reg <= sda_di;
end

reg scl_di_reg;
always @(posedge clk) begin
    scl_di_reg <= scl_di;
end

reg ack_reg, ack_reg_en;
always @(posedge clk) begin
    if(~rst_n) 
        ack_reg <= 1; // default to released state
    if(ack_reg_en)
        ack_reg <= sda_di_reg;
end

//the shift register used for incoming and outgoing data bits 
// in the I2C protocol
reg [7:0] i2c_buf;
reg i2c_buf_clr;
reg i2c_buf_ld_tx;
reg i2c_buf_ld_addr_rw;
reg i2c_buf_rx_shift_en;
reg i2c_buf_tx_shift_en;
always@(posedge clk) begin
    if(~rst_n || i2c_buf_clr) begin
        i2c_buf <= 8'h00;
    end else begin
        if(i2c_buf_ld_tx == 1)
            i2c_buf <= i2c_data_tx;
        else if(i2c_buf_ld_addr_rw == 1)
            i2c_buf <= i2c_addr_rw;
        else if(i2c_buf_rx_shift_en == 1) begin
            i2c_buf <= {i2c_buf[6:0], sda_di_reg};
        end else if(i2c_buf_tx_shift_en == 1)
            i2c_buf <= {i2c_buf[6:0], 1'd0};
    end
end

//this counter is used to keep track of the number of bits shifted in/out
reg [2:0] i2c_buf_cnt;
reg i2c_buf_cnt_clr;
reg i2c_buf_cnt_en;
always@(posedge clk ) begin
    if(~rst_n || i2c_buf_cnt_clr) begin
        i2c_buf_cnt <= 3'h0;
    end else begin
        if(i2c_buf_cnt_en == 1) begin
            i2c_buf_cnt <= i2c_buf_cnt + 1;
        end
    end
end

//this register preserves the contents of the shift register
// after a data byte is received
reg i2c_data_rx_ld;
always @(posedge clk ) begin
    i2c_data_rx_valid_stb <= 0;
    if(~rst_n) 
        i2c_data_rx <= 8'h00;
    else if(i2c_data_rx_ld) begin
        i2c_data_rx <= i2c_buf;
        i2c_data_rx_valid_stb <= 1;
    end
end

localparam S_IDLE = 4'd0,
           
           S_START = 4'd1,
           S_SEND_ADDR_RW = 4'd2,
           S_ACK_ADDR_RW = 4'd3,
           S_STALL_AFTER_ADDR_RW = 4'd4,

           S_WRITE_DATA = 4'd5,
           S_ACK_WRITE_DATA = 4'd6,
           S_STALL_AFTER_WRITE_DATA = 4'd7,

           S_READ_DATA = 4'd8,
           S_ACK_READ_DATA = 4'd9,
           S_STALL_AFTER_READ_DATA = 4'd10,

           S_RESTART = 4'd11,

           S_NACK = 4'd12,
           S_ERROR = 4'd13,
           S_STOP = 4'd14,
           S_STOP_DELAY = 4'd15;

reg [3:0] state, next_state = S_IDLE;

//state register
always @(posedge clk) begin
    if(rst_n == 0) begin
        state <= S_IDLE;
    end else begin
        if(state != next_state) begin
            $display("Master state transition: %d -> %d", state, next_state);
        end
        state <= next_state;
    end
end

//scl and sda registers
reg scl_go_low, scl_go_high, scl_toggle;
reg sda_go_low, sda_go_high, sda_take_i2c_buf_bit;

wire scl_stretching; // if 1 that means we've pulled scl low and we're waiting for the slave to release it for clock stretching
reg wait_scl_go_high; // if 1 that means we're waiting for scl to be pulled low by the slave for clock stretching

always @(posedge clk) begin
    if(rst_n == 0) begin
        periph_scl <= 1;
        periph_sda <= 1;
        wait_scl_go_high <= 0;
    end else begin


        if(scl_go_low)
            periph_scl <= 0;
        else if(scl_go_high && periph_scl == 0) begin
            periph_scl <= 1;
            wait_scl_go_high <= 1;
        end

        if(wait_scl_go_high) begin
            if(scl_di_reg == 1) begin
                wait_scl_go_high <= 0;
            end 
        end

        if(sda_go_low)
            periph_sda <= 0;
        else if(sda_go_high)
            periph_sda <= 1;
        else if(sda_take_i2c_buf_bit)
            periph_sda <= i2c_buf[7]; // the current bit to be shifted out is always at bit 7 of the buffer, as we shift the buffer on the falling edge of the clock after we've set up the next bit to be output on sda_out
    end
end

assign scl_stretching = wait_scl_go_high;
assign i2c_slave_stretching = scl_stretching;

//state transition and output logic
always @(*) begin
    next_state <= state; // default to hold state
    timer_en <= 0;
    timer_clr <= 0;
    i2c_buf_cnt_clr <= 0;
    i2c_buf_cnt_en <= 0;

    i2c_buf_clr <= 0;
    i2c_buf_ld_tx <= 0;
    i2c_buf_ld_addr_rw <= 0;
    i2c_buf_rx_shift_en <= 0;
    i2c_buf_tx_shift_en <= 0;

    i2c_data_rx_ld <= 0;

    transaction_active <= 1;
    transaction_stalling <= 0;

    ack_reg_en <= 0;

    scl_go_low <= 0;
    scl_go_high <= 0;
    scl_toggle <= 0;
    sda_go_low <= 0;
    sda_go_high <= 0;
    sda_take_i2c_buf_bit <= 0;

    i2c_nack_stb <= 0;
    i2c_error_stb <= 0;

    if(scl_stretching)
        next_state <= state;
    else begin
        case(state)
            S_IDLE: begin
                timer_clr <= 1;
                scl_go_high <= 1;
                sda_go_high <= 1;
                transaction_active <= 0;       
                if (transaction_start_stb) begin
                    next_state <= S_START;
                    i2c_buf_ld_addr_rw <= 1;
                end
            end

            S_START: begin
                //first we pull down sda_out while scl_out is high, which is the start condition in i2c
                sda_go_low <= 1;
                timer_en <= 1; // start the timer generation
                i2c_buf_cnt_clr <= 1; // clear the bit counter

                if (timer_3qperiod_stb) begin
                    scl_go_low <= 1; // after the first quarter period, we can pull scl low to prepare for the first bit to be sent, and to allow for the slave to set sda_di for the ack bit after the address+rw bits are sent
                end

                if (timer_fullperiod_done) begin 
                    timer_en <= 0; //stop/reset the timer
                    timer_clr <= 1;
                    next_state <= S_SEND_ADDR_RW;
                end
            end

            S_SEND_ADDR_RW: begin
                timer_en <= 1; 
                sda_take_i2c_buf_bit <= 1;

                if(timer_1qperiod_stb) begin
                    scl_go_high <= 1; // set scl high at the half period point to meet the timing requirements of the i2c protocol, and to allow for the slave to read the bit on sda_out
                end

                if(timer_3qperiod_stb) begin
                    scl_go_low <= 1; // pull scl low at the full period point to prepare for the next bit, and to allow for the slave to set sda_di for the ack bit after the address+rw bits are sent
                end

                if(timer_fullperiod_done) begin
                    timer_en <= 0; // start the timer for the next bit period
                    timer_clr <= 1;
                    i2c_buf_tx_shift_en <= 1; // shift the buffer on each falling clock cycle to get the next bit ready
                    i2c_buf_cnt_en <= 1; // increment the bit counter on each falling edge of the clock
                    if (i2c_buf_cnt == 3'd7) begin // after we've shifted out all 8 bits of the address+rw
                        next_state <= S_ACK_ADDR_RW;
                    end
                end
            end

            S_ACK_ADDR_RW: begin
                sda_go_high <= 1; // release sda so the slave can drive it for the ack bit
                timer_en <= 1; 

                if(timer_1qperiod_stb) begin
                    scl_go_high <= 1; // set scl high at the half period point to meet the timing requirements of the i2c protocol, and to allow for the slave to read the bit on sda_out
                end

                if(timer_2qperiod_stb) begin
                    //read the ack bit now
                    ack_reg_en <= 1;
                end

                if(timer_halfperiod_done) begin
                    sda_go_high <= 0;
                    sda_go_low <= 1; // pull sda low at the full period point to prepare for the next bit, and to allow for the slave to set sda_di for the ack bit after the address+rw bits are sent
                end

                if(timer_3qperiod_stb) begin
                    scl_go_low <= 1; // pull scl low at the full period point to prepare for the next bit, and to allow for the slave to set sda_di for the ack bit after the address+rw bits are sent
                end

                if (timer_fullperiod_done) begin
                    timer_en <= 0; // stop/reset the timer as we've reached the end of the ack bit period
                    timer_clr <= 1;
                    sda_go_low <= 1;
                    if(ack_reg) begin
                        next_state <= S_NACK; // if the ack bit is high, that means the slave didn't acknowledge the address, so we can end the transaction with an error
                    end else begin
                        next_state <= S_STALL_AFTER_ADDR_RW; // if the ack bit is low, that means the slave acknowledged the address, so we can proceed with the transaction
                    end
                end
            end

            S_STALL_AFTER_ADDR_RW: begin
                timer_en <= 1;
                if (timer_fullperiod_done) begin
                    transaction_stalling <= 1; // now that we've sent the address and rw bit, we can stall the transaction to wait for the next instruction from the master controller (whether that's to send data, receive data, restart, or stop)
                    if (transaction_restart) begin
                        timer_en <= 0;
                        timer_clr <= 1;
                        next_state <= S_RESTART;
                    end else if (transaction_stop) begin
                        timer_en <= 0;
                        timer_clr <= 1;
                        next_state <= S_STOP;
                    end else if (transaction_continue) begin
                        if (i2c_addr_rw[0] == 0) begin // if rw bit is 0, that means we want to write data
                            timer_en <= 0;
                            timer_clr <= 1;
                            i2c_buf_cnt_clr <= 1; // clear the bit counter
                            i2c_buf_ld_tx <= 1; // load the data to be transmitted into the buffer
                            next_state <= S_WRITE_DATA;
                        end else begin // if rw bit is 1, that means we want to read data
                            timer_en <= 0;
                            timer_clr <= 1;
                            i2c_buf_cnt_clr <= 1; // clear the bit counter
                            next_state <= S_READ_DATA;
                        end
                    end
                end
            end

            S_RESTART: begin
                sda_go_high <= 1; // to generate a restart condition, we first release sda to go high while scl is still high, which is the stop condition in i2c
                timer_en <= 1;

                if (timer_1qperiod_stb) begin
                    scl_go_high <= 1; // set scl high at the half period point to meet the timing requirements of the i2c protocol, and to allow for the slave to read the bit on sda_out
                end
                //await the clock to return high with normal timing
                if (timer_fullperiod_done) begin
                    next_state <= S_START;
                    timer_en <= 0;
                    timer_clr <= 1;
                    i2c_buf_ld_addr_rw <= 1; // load the address and rw bit for the new transaction into the buffer to be sent out
                    i2c_buf_cnt_clr <= 1; // clear the bit counter to prepare for shifting out the new address and rw bit
                end
            end

            S_STOP: begin
                timer_en <= 1;
                sda_go_low <= 1; // to generate a stop condition, keep sda low

                if (timer_1qperiod_stb) begin
                    scl_go_high <= 1; // set scl high at the quarter period point to meet the timing requirements of the i2c protocol for the stop condition, and to allow for the slave to read the bit on sda_out if needed
                end
                if (timer_fullperiod_done) begin
                    timer_en <= 0;
                    timer_clr <= 1;
                    sda_go_low <= 0; 
                    sda_go_high <= 1; // then we release sda to go high while scl is still high
                    next_state <= S_STOP_DELAY; // after the stop condition, we need a short inter-transaction delay
                end
            end

            S_STOP_DELAY: begin
                timer_en <= 1;
                if (timer_fullperiod_done) begin
                    timer_en <= 0;
                    timer_clr <= 1;
                    next_state <= S_IDLE; // after the stop condition, we can return to the idle state
                end
            end

            S_WRITE_DATA: begin
                timer_en <= 1; 
                sda_take_i2c_buf_bit <= 1;
                
                if(timer_1qperiod_stb) begin
                    scl_go_high <= 1; // set scl high at the half period point to meet the timing requirements of the i2c protocol, and to allow for the slave to read the bit on sda_out
                end

                if(timer_3qperiod_stb) begin
                    scl_go_low <= 1; // pull scl low at the full period point to prepare for the next bit, and to allow for the slave to set sda_di for the ack bit after the address+rw bits are sent
                end

                if(timer_fullperiod_done) begin
                    scl_go_low <= 1; // pull scl low at the full period point to prepare for the next bit, and to allow for the slave to set sda_di for the ack bit after we've sent all 8 bits of data
                    timer_en <= 0; // start the timer for the next bit period
                    timer_clr <= 1;
                    i2c_buf_tx_shift_en <= 1; // shift the buffer on each falling clock cycle to get the next bit ready
                    i2c_buf_cnt_en <= 1; // increment the bit counter on each falling edge of the clock

                    if (i2c_buf_cnt == 3'd7) begin // after we've shifted out all 8 bits of data
                        next_state <= S_ACK_WRITE_DATA;
                    end
                end
            end

            S_ACK_WRITE_DATA: begin
                sda_go_high <= 1; // release sda so the slave can drive it for the ack bit
                timer_en <= 1; 

                if(timer_1qperiod_stb) begin
                    scl_go_high <= 1; // set scl high at the half period point to meet the timing requirements of the i2c protocol, and to allow for the slave to read the bit on sda_out
                end

                if(timer_2qperiod_stb) begin
                    //read the ack bit now
                    ack_reg_en <= 1;
                end

                if(timer_halfperiod_done) begin
                    sda_go_high <= 0;
                    sda_go_low <= 1; // pull sda low at the full period point to prepare for the next bit, and to allow for the slave to set sda_di for the ack bit after the address+rw bits are sent
                end

                if(timer_3qperiod_stb) begin
                    scl_go_low <= 1; // pull scl low at the full period point to prepare for the next bit, and to allow for the slave to set sda_di for the ack bit after the address+rw bits are sent
                end

                if (timer_fullperiod_done) begin
                    timer_en <= 0; // stop/reset the timer as we've reached the end of the ack bit period
                    timer_clr <= 1;
                    sda_go_low <= 1;
                    scl_go_low <= 1; // pull scl low at the full period point to prepare for the next bit, and to allow for the slave to set sda_di for the ack bit after we've sent all 8 bits of data
                    if(ack_reg) begin
                        next_state <= S_NACK; // if the ack bit is high, that means the slave didn't acknowledge the data byte, so we can end the transaction with an error
                    end else begin
                        next_state <= S_STALL_AFTER_WRITE_DATA; // if the ack bit is low, that means the slave acknowledged the data byte, so we can either end the transaction or continue sending/receiving more data based on what instruction we get from the master controller while we're stalled in this state
                    end
                end
            end

            S_STALL_AFTER_WRITE_DATA: begin
                timer_en <= 1;
                if(timer_fullperiod_done) begin
                    transaction_stalling <= 1; // now that we've sent a data byte, we can stall the transaction to wait for the next instruction from the master controller (whether that's to send more data, receive data, restart, or stop)
                    if (transaction_restart) begin
                        next_state <= S_RESTART;
                        timer_en <= 0;
                        timer_clr <= 1;
                    end else if (transaction_stop) begin
                        next_state <= S_STOP;
                        timer_en <= 0;
                        timer_clr <= 1;
                    end else if (transaction_continue) begin
                        timer_en <= 0;
                        timer_clr <= 1;
                        i2c_buf_cnt_clr <= 1; // clear the bit counter
                        i2c_buf_ld_tx <= 1; // load the data to be transmitted into the buffer
                        next_state <= S_WRITE_DATA;
                    end
                end
            end

            S_READ_DATA: begin
                timer_en <= 1; 
                sda_go_high <= 1; // release sda so the slave can drive it to send us the data bits

                if(timer_1qperiod_stb) begin
                    scl_go_high <= 1; // set scl high at the half period point to meet the timing requirements of the i2c protocol, and to allow for the slave to read the bit on sda_out
                end

                if(timer_2qperiod_stb) begin
                    //read the data bit now
                    i2c_buf_rx_shift_en <= 1; // shift the buffer on each falling clock cycle to store the incoming bits from sda_di
                end

                if(timer_3qperiod_stb) begin
                    scl_go_low <= 1; // pull scl low at the full period point to prepare for the next bit, and to allow for the slave to set sda_di for the ack bit after the address+rw bits are sent
                end

                if(timer_fullperiod_done) begin
                    scl_go_low <= 1; // pull scl low at the full period point to prepare for the next bit, and to allow for the slave to set sda_di for the ack bit after we've read all 8 bits of data
                    timer_en <= 0; // start the timer for the next bit period
                    timer_clr <= 1;
                    i2c_buf_cnt_en <= 1; // increment the bit counter on each falling edge of the clock

                    if (i2c_buf_cnt == 3'd7) begin // after we've shifted in all 8 bits of data
                        next_state <= S_ACK_READ_DATA;
                        i2c_data_rx_ld <= 1; // load the received data from the buffer into the i2c_data_rx register and strobe it as valid
                    end
                end
            end

            S_ACK_READ_DATA: begin
                timer_en <= 1; 
                sda_go_low <= 1;

                if(timer_1qperiod_stb) begin
                    scl_go_high <= 1; // set scl high at the half period point to meet the timing requirements of the i2c protocol, and to allow for the slave to read the bit on sda_out
                end

                if(timer_3qperiod_stb) begin
                    scl_go_low <= 1; // pull scl low at the full period point to prepare for the next bit, and to allow for the slave to set sda_di for the ack bit after the address+rw bits are sent
                end

                if (timer_fullperiod_done) begin
                    timer_en <= 0; // stop/reset the timer as we've reached the end of the ack/nack bit period
                    timer_clr <= 1;
                    sda_go_low <= 0; // stop pulling sda low
                    sda_go_high <= 1; // 
                    next_state <= S_STALL_AFTER_READ_DATA; // after reading a data byte, we can either end the transaction or continue sending/receiving more data based on what instruction we get from the master controller while we're stalled in this state
                end
            end

            S_STALL_AFTER_READ_DATA: begin
                timer_en <= 1;
                if(timer_fullperiod_done) begin
                    transaction_stalling <= 1; // now that we've read a data byte, we can stall the transaction to wait for the next instruction from the master controller (whether that's to send data, receive more data, restart, or stop)
                    if (transaction_restart) begin
                        next_state <= S_RESTART;
                        timer_en <= 0;
                        timer_clr <= 1;
                    end else if (transaction_stop) begin
                        next_state <= S_STOP;
                        timer_en <= 0;
                        timer_clr <= 1;
                    end else if (transaction_continue) begin
                        if (i2c_addr_rw[0] == 0) begin // if rw bit is 0, that means we want to write data
                            timer_en <= 0;
                            timer_clr <= 1;
                            i2c_buf_ld_tx <= 1; // load the data to be transmitted into the buffer
                            i2c_buf_cnt_clr <= 1; // clear the bit counter to prepare for shifting out the new address and rw bit
                            next_state <= S_WRITE_DATA;
                        end else begin // if rw bit is 1, that means we want to read more data
                            timer_en <= 0;
                            timer_clr <= 1;
                            i2c_buf_cnt_clr <= 1; // clear the bit counter to prepare for shifting in the new data
                            next_state <= S_READ_DATA;
                        end
                    end
                end
            end

            S_NACK: begin
                i2c_nack_stb <= 1; // strobe the nack signal to indicate to the master controller that the slave didn't acknowledge either the address or the data byte that was sent
                timer_en <= 0;
                timer_clr <= 1;
                next_state <= S_STOP; // after a nack, we can end the transaction with a stop condition
            end

            S_ERROR: begin
                i2c_error_stb <= 1; // strobe the error signal to indicate to the master controller that there was an error in the transaction (such as a timing violation, or unexpected change on the sda line, etc)
                next_state <= S_STOP; // after an error, we can end the transaction with a stop condition
            end
        endcase
    end
end
endmodule