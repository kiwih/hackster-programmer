//Author: Hammond Pearce
//Email: hammond.pearce@unsw.edu.au
//Date: Jan 30 2025

`default_nettype none

module i2c_simple_slave #(
    parameter i2c_address = 7'h42
) (
    input wire clk,
    input wire rst_n,

    input wire scl_di,
    input wire sda_di,
    output reg scl_pulldown,
    output reg sda_pulldown,

    input wire stall,

    output wire [7:0] i2c_addr_rw,
    output reg i2c_addr_rw_valid_stb,

    output reg [7:0] i2c_data_rx,
    output reg i2c_data_rx_valid_stb,

    input wire [7:0] i2c_data_tx,
    output reg i2c_data_tx_loaded_stb,
    output reg i2c_data_tx_done_stb,

    output reg i2c_error_stb,

    output wire [3:0] debug_i2c_state
);


reg scl_di_reg, sda_di_reg = 0;
reg scl_rising_edge, scl_falling_edge;
reg sda_rising_edge, sda_falling_edge;

//this block is for identifying rising and falling edges of SCL and SDA
// (this is needed for start bits, stop bits, etc)
always@(posedge clk )
begin
    if(~rst_n)
    begin
        scl_di_reg <= 1'b1;
        sda_di_reg <= 1'b1;

        scl_rising_edge <= 1'b0;
        scl_falling_edge <= 1'b0;
        sda_rising_edge <= 1'b0;
        sda_falling_edge <= 1'b0;
    end
    else
    begin
        scl_di_reg <= scl_di;
        sda_di_reg <= sda_di; 

        scl_rising_edge <= (scl_di == 1 && scl_di_reg == 0);
        scl_falling_edge <= (scl_di == 0 && scl_di_reg == 1);
        sda_rising_edge <= (sda_di == 1 && sda_di_reg == 0);
        sda_falling_edge <= (sda_di == 0 && sda_di_reg == 1);
    end
end

reg i2c_rx_addr_r_w_save = 0;
reg i2c_rx_data_save = 0;

//the shift register used for incoming and outgoing data bits 
// in the I2C protocol
reg [7:0] i2c_buf;
reg i2c_buf_clr;
reg i2c_buf_ld_tx;
reg i2c_buf_rx_shift_en;
reg i2c_buf_tx_shift_en;
always@(posedge clk) begin
    if(~rst_n || i2c_buf_clr) begin
        i2c_buf <= 8'h00;
    end else begin
        if(i2c_buf_ld_tx == 1)
            i2c_buf <= i2c_data_tx;
        else if(i2c_buf_rx_shift_en == 1)
            i2c_buf <= {i2c_buf[6:0], sda_di_reg};
        else if(i2c_buf_tx_shift_en == 1)
            i2c_buf <= {i2c_buf[6:0], 1'd0};
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

//this register preserves the contents of the shift register
// after an address/r_w byte is received
reg [7:0] i2c_addr_rw_reg;
reg i2c_addr_rw_reg_ld;
always@(posedge clk ) begin
    i2c_addr_rw_valid_stb <= 0;
    if(~rst_n) 
        i2c_addr_rw_reg <= 8'h00;
    else if(i2c_addr_rw_reg_ld) begin
        i2c_addr_rw_reg <= i2c_buf;
        i2c_addr_rw_valid_stb <= 1;
    end
end
assign i2c_addr_rw = i2c_addr_rw_reg;

//this counter is used to keep track of the number of bits shifted in/out
reg [2:0] i2c_buf_cnt;
reg i2c_buf_cnt_clr;
reg i2c_buf_cnt_en;
always@(posedge clk ) begin
    if(~rst_n || i2c_buf_cnt_clr) begin
        i2c_buf_cnt <= 3'h0;
    end else begin
        if(i2c_buf_cnt_en == 1)
            i2c_buf_cnt <= i2c_buf_cnt + 1;
    end
end

// This register stores whether the host returned a NAK for our last TX.
reg i2c_nak;
wire i2c_nak_clr;
wire i2c_nak_en;
always @(posedge clk) begin
    if (~rst_n || i2c_nak_clr) begin
        i2c_nak <= 0;
    end else if (i2c_nak_en) begin
        i2c_nak <= sda_di_reg;
    end
end

localparam  S_IDLE      = 4'h0, 
            S_START     = 4'h1, 
            S_ADDR_RX   = 4'h2,
            S_ADDR_ACK  = 4'h3,

            S_STALL  = 4'h4,

            S_DATA_RX       = 4'h5,
            S_DATA_RX_ACK   = 4'h6,

            S_DATA_TX      = 4'h7,
            S_DATA_TX_ACK  = 4'h8,

            S_ERROR     = 4'hD,
            S_IGNORE    = 4'hE,
            S_DONE      = 4'hF;

reg [3:0] state, next_state = S_IDLE;

always@(posedge clk )
begin
    if(~rst_n)
        state <= S_IDLE;
    else
        state <= next_state;
end


reg i2c_ack = 0;
reg i2c_clock_stretch = 0;

reg i2c_tx_en = 0;
//Clock stretching should occur prior to any slave-controlled ACK
// see https://vanhunteradams.com/Protocols/I2C/I2C.html clock stretch figure
always@* begin
    i2c_clock_stretch <= 0;
    i2c_ack <= 0;

    i2c_buf_clr <= 0;
    i2c_buf_ld_tx <= 0;
    i2c_buf_rx_shift_en <= 0;
    i2c_buf_tx_shift_en <= 0;
    i2c_buf_cnt_clr <= 0;
    i2c_buf_cnt_en <= 0;
    i2c_nak_clr <= 0;
    i2c_nak_en <= 0;

    i2c_data_tx_loaded_stb <= 0;
    i2c_data_tx_done_stb <= 0;
    i2c_error_stb <= 0;

    i2c_addr_rw_reg_ld <= 0;
    i2c_data_rx_ld <= 0;
    i2c_tx_en <= 0;

    next_state <= S_ERROR;
case(state)
    S_IDLE: begin //wait for SDA to go low while SCL stays high
        if(sda_falling_edge && scl_di_reg == 1)
            next_state <= S_START;
        else
            next_state <= S_IDLE;
    end
    S_START: begin //now wait for SCL to go low to join SDA
        i2c_nak_clr <= 1;
        if(sda_di_reg == 0 && scl_di_reg == 0) begin
            next_state <= S_ADDR_RX;
            i2c_buf_clr <= 1;
            i2c_buf_cnt_clr <= 1;
        end else if(sda_di_reg == 0 && scl_di_reg == 1)
            next_state <= S_START; //wait here
        else 
            next_state <= S_ERROR; //something goofed
    end
    S_ADDR_RX: begin //read the address
        if(scl_rising_edge == 1) begin
            i2c_buf_rx_shift_en <= 1;
            next_state <= S_ADDR_RX;
        end else if(scl_falling_edge == 1 && i2c_buf_cnt == 3'h7) begin
            i2c_addr_rw_reg_ld <= 1;
            next_state <= S_ADDR_ACK;
        end else if(scl_falling_edge == 1) begin
            i2c_buf_cnt_en <= 1;
            next_state <= S_ADDR_RX;
        end else if(i2c_buf_cnt != 3'h7) 
            next_state <= S_ADDR_RX;
        else
            next_state <= S_ADDR_RX;
    end
    S_ADDR_ACK: begin //send ACK
        if(i2c_addr_rw_reg[7:1] != i2c_address) begin
            //$display("Address mismatch: %h != %h", i2c_addr_rw_reg[7:1], i2c_address);
            next_state <= S_IGNORE;
        end else begin
            if(scl_falling_edge) 
                next_state <= S_STALL;
            else begin
                i2c_ack <= 1;
                next_state <= S_ADDR_ACK;
            end
        end 
    end

    S_STALL: begin
        if(stall == 1) begin
            i2c_clock_stretch <= 1;
            next_state <= S_STALL;
        end else begin
            i2c_clock_stretch <= 1; //we'll always stall at least 1 clock cycle 
                                    //  for stability reasons
            if(i2c_addr_rw_reg[0] == 0) begin
                i2c_buf_clr <= 1;
                i2c_buf_cnt_clr <= 1;
                next_state <= S_DATA_RX;
            end else begin
                i2c_buf_ld_tx <= 1;
                i2c_buf_cnt_clr <= 1;
                i2c_data_tx_loaded_stb <= ~i2c_nak;
                next_state <= S_DATA_TX;
            end
        end
    end

    S_DATA_RX: begin
        //(it is however possible to have a re-start)
        if(sda_falling_edge == 1 && scl_di_reg == 1) begin
            //restart condition
            next_state <= S_START;
        end else if(sda_rising_edge == 1 && scl_di_reg == 1 && i2c_buf_cnt <= 1) 
            //due to the way the counter would be incremented if this wasn't
            // a stop bit, we check for <= 1 rather than 0 as counter is 1 ahead
            //we're done here
            next_state <= S_DONE;
        else if(scl_rising_edge == 1) begin
            i2c_buf_rx_shift_en <= 1;
            next_state <= S_DATA_RX;
        end else if(scl_falling_edge == 1 && i2c_buf_cnt == 3'h7) begin
            i2c_data_rx_ld <= 1;
            next_state <= S_DATA_RX_ACK;
        end else if(scl_falling_edge) begin
            i2c_buf_cnt_en <= 1;
            next_state <= S_DATA_RX;
        end else if(i2c_buf_cnt != 3'h7) 
            next_state <= S_DATA_RX;
        else
            next_state <= S_DATA_RX;
    end
    
    S_DATA_RX_ACK: begin
        if(scl_falling_edge) 
            next_state <= S_STALL;        
        else begin
            i2c_ack <= 1;
            next_state <= S_DATA_RX_ACK;
        end  
    end

    S_DATA_TX: begin
        i2c_tx_en <= ~i2c_nak;
        // TODO: check for start conditions here too
        if(sda_rising_edge == 1 && scl_di_reg == 1 && i2c_buf_cnt <= 1) begin
            //we're done here
            next_state <= S_DONE;
        end else if(sda_rising_edge == 1 && scl_di_reg == 1 && i2c_buf_cnt <= 1) begin
            //this is an error, this shouldn't happen mid-byte
            next_state <= S_ERROR;
        end else if (scl_falling_edge == 1) begin
            if (i2c_nak == 1)
                next_state <= S_ERROR;
            else if(i2c_buf_cnt != 3'h7) begin
                i2c_buf_tx_shift_en <= 1;
                i2c_buf_cnt_en <= 1;
                next_state <= S_DATA_TX;
            end else begin
                i2c_data_tx_done_stb <= 1;
                next_state <= S_DATA_TX_ACK;
            end
        end else  
            next_state <= S_DATA_TX;
    end

    S_DATA_TX_ACK: begin
        //unlike with the RX_ACK, the ACK actually comes from the master
        if(scl_falling_edge) 
            next_state <= S_STALL;
        else begin
            if (scl_rising_edge == 1) begin
                i2c_nak_en <= 1;
            end
            next_state <= S_DATA_TX_ACK;
        end
    end

    S_IGNORE: begin
        //wait until a stop bit
        if(sda_rising_edge == 1 && scl_di_reg == 1)
            next_state <= S_DONE;
        else
            next_state <= S_IGNORE;
    end

    S_DONE: begin
        next_state <= S_IDLE;
    end

    default: begin //includes S_ERROR
        i2c_error_stb <= 1;
        next_state <= S_DONE;
    end
endcase
end

assign scl_pulldown = 0 | i2c_clock_stretch;
assign sda_pulldown = 0 | i2c_ack | (i2c_tx_en ? ~i2c_buf[7] : 0);



assign debug_i2c_state = state;

endmodule