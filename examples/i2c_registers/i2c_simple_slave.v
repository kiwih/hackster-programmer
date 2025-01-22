`default_nettype none

//module i2c_simple_slave has parameters:
// i2c_address: 7-bit address of the slave device
//inputs:
// clk: 10MHz clock input
// rst_n: active low reset
// scl_di: input SCL from pins 
// sda_di: input SDA from pins
// i2c_data_wr: data to be transmitted on the I2C bus
//outputs:
// scl_ndo: output SCL to pins (use as output enable)
// sda_ndo: output SDA to pins (use as output enable)
// i2c_data_rd: data received on the I2C bus
// i2c_data_rd_valid_stb: data strobe: received on the I2C bus is valid
// i2c_data_wr_finish_stb: strobe to indicate that the data has been transmitted
// i2c_error_strobe: strobe to indicate an error has occurred

module i2c_simple_slave #(
    parameter i2c_address = 7'h42
) (
    input wire clk,
    input wire rst_n,

    input wire scl_di,
    input wire sda_di,
    output reg scl_ndo,
    output reg sda_ndo,

    output reg [7:0] i2c_data_rd,
    output reg i2c_data_rd_valid_stb,
    input wire [7:0] i2c_data_wr,
    output reg i2c_data_wr_finish_stb,
    output reg i2c_error_stb
);

reg scl_di_reg, sda_di_reg = 0;
reg scl_di_reg_prev, sda_di_reg_prev = 0;
wire scl_rising_edge, scl_falling_edge;
wire sda_rising_edge, sda_falling_edge;

always@(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        scl_di_reg <= 1'b1;
        sda_di_reg <= 1'b1;

        scl_di_reg_prev <= 1'b1;
        sda_di_reg_prev <= 1'b1;
    end
    else
    begin
        scl_di_reg <= scl_di;
        sda_di_reg <= sda_di; 

        scl_di_reg_prev <= scl_di_reg;
        sda_di_reg_prev <= sda_di_reg;
    end
end

assign scl_rising_edge = (scl_di_reg == 1 && scl_di_reg_prev == 0);
assign scl_falling_edge = (scl_di_reg == 0 && scl_di_reg_prev == 1);
assign sda_rising_edge = (sda_di_reg == 1 && sda_di_reg_prev == 0);
assign sda_falling_edge = (sda_di_reg == 0 && sda_di_reg_prev == 1);

reg i2c_rx_en = 0;
reg i2c_tx_en = 0;
reg i2c_tx_ld = 0;

reg i2c_rxtx_clr = 0;
reg [2:0] i2c_rxtx_cnt = 0;
reg [7:0] i2c_rxtx_reg = 0;
reg i2c_rxtx_done = 0;

reg [7:0] i2c_rx_addr_r_w = 0;
reg i2c_rx_addr_r_w_save = 0;
reg i2c_rx_data_save = 0;

//rxtx data register
always@(posedge clk or negedge rst_n) begin
    i2c_data_rd_valid_stb <= 0;
    i2c_data_wr_finish_stb <= 0;
    if(~rst_n || i2c_rxtx_clr == 1)
    begin
        i2c_rxtx_cnt <= 3'b000;
        i2c_rxtx_reg = 8'h00;
        i2c_rxtx_done <= 0;
    end
    else
        //if rx enabled, on each rising edge shift in a bit
        if(i2c_rx_en == 1 && scl_rising_edge) begin
            i2c_rxtx_reg[7:0] = {i2c_rxtx_reg[6:0], sda_di_reg};
            if(i2c_rxtx_cnt < 3'd7) begin
                i2c_rxtx_cnt <= i2c_rxtx_cnt + 1;
            end
            else begin
                i2c_rxtx_done <= 1;
                if(i2c_rx_addr_r_w_save == 1)
                    i2c_rx_addr_r_w <= i2c_rxtx_reg;
                else if(i2c_rx_data_save == 1) begin
                    i2c_data_rd <= i2c_rxtx_reg;
                    i2c_data_rd_valid_stb <= 1;
                end
            end
        end
        //i2c_tx_ld loads the data to be transmitted and 
        //resets the internal counter
        //it also will emit the strobe so the parent module knows data is going out
        if(i2c_tx_ld == 1) begin
            i2c_rxtx_reg <= i2c_data_wr;
            i2c_data_wr_finish_stb <= 1;
            i2c_rxtx_cnt <= 0;
            i2c_rxtx_done <= 0;
        end
        //if tx enabled, on each falling edge shift out a bit
        if(i2c_tx_en == 1 && scl_falling_edge) begin
            i2c_rxtx_reg[7:0] = {i2c_rxtx_reg[6:0], 1'b0};
            if(i2c_rxtx_cnt < 3'd6) begin //falling edge means we finish 1 bit early
                i2c_rxtx_cnt <= i2c_rxtx_cnt + 1;
            end
            else begin
                i2c_rxtx_done <= 1;
            end
        end

end





localparam  S_IDLE      = 4'h0, 
            S_START     = 4'h1, 
            S_ADDR_RX   = 4'h2,
            S_ADDR_ACK  = 4'h3,

            S_DATA_WAIT = 4'h4, 

            S_DATA_RX      = 4'h5,
            S_DATA_RX_ACK  = 4'h6,

            S_DATA_TX_LD   = 4'h7,
            S_DATA_TX      = 4'h8,
            S_DATA_TX_ACK  = 4'h9,

            S_ERROR     = 4'hD,
            S_IGNORE    = 4'hE,
            S_DONE      = 4'hF;

reg [3:0] state, next_state = S_IDLE;

always@(posedge clk or negedge rst_n)
begin
    if(~rst_n)
        state <= S_IDLE;
    else
        state <= next_state;
end


reg i2c_ack = 0;

//TODO: if clock stretching, this would occur prior to any slave-controlled ACK
// see https://vanhunteradams.com/Protocols/I2C/I2C.html clock stretch figure
always@* begin
    i2c_rxtx_clr <= 0;
    i2c_rx_en <= 0;
    i2c_tx_ld <= 0;
    i2c_tx_en <= 0;
    i2c_ack <= 0;
    i2c_rx_addr_r_w_save <= 0;
    i2c_error_stb <= 0;
case(state)
    S_IDLE: begin //wait for SDA to go low while SCL stays high
        if(sda_falling_edge && scl_di_reg == 1)
            next_state <= S_START;
        else
            next_state <= S_IDLE;
    end
    S_START: begin //now wait for SCL to go low to join SDA
        i2c_rxtx_clr <= 1;
        if(sda_di_reg == 0 && scl_di_reg == 0)
            next_state <= S_ADDR_RX;
        else if(sda_di_reg == 0 && scl_di_reg == 1)
            next_state <= S_START; //wait here
        else 
            next_state <= S_ERROR; //something goofed
    end
    S_ADDR_RX: begin //read the address
        i2c_rx_en <= 1;
        i2c_rx_addr_r_w_save <= 1;
        if(sda_rising_edge == 1 && scl_di_reg == 1)
            //this is an error, this shouldn't happen until we have full addr
            next_state <= S_ERROR;
        else if(scl_falling_edge == 1 && i2c_rxtx_done == 1) begin
            if(i2c_rx_addr_r_w[7:1] == i2c_address) begin
                next_state <= S_ADDR_ACK;
            end else
                next_state <= S_IGNORE; //this one is not for us
        end else
            next_state <= S_ADDR_RX;
    end
    S_ADDR_ACK: begin //send ACK
        i2c_ack <= 1;
        i2c_rxtx_clr <= 1;
        if(sda_rising_edge == 1 && scl_di_reg == 1)
            //this is an error, this shouldn't happen until post addr accept
            next_state <= S_ERROR;
        else if(scl_falling_edge == 1)
            next_state <= S_DATA_WAIT;
        else
            next_state <= S_ADDR_ACK;
    end

    S_DATA_WAIT: begin
        //wait for the next sda falling edge before going to tx/rx as needed
        //(it is however possible to have a re-start)
        if(sda_falling_edge == 1 && scl_di_reg == 1) 
            //restart condition
            next_state <= S_ADDR_RX;
        if(sda_falling_edge == 1 && scl_di_reg == 0) begin
            if(i2c_rx_addr_r_w[0] == 0) begin
                next_state <= S_DATA_RX;
            end else
                next_state <= S_DATA_TX_LD;
        end else
            next_state <= S_DATA_WAIT;
    end

    S_DATA_RX: begin
        i2c_rx_en <= 1;
        i2c_rx_data_save <= 1;
        if(sda_rising_edge == 1 && scl_di_reg == 1 && i2c_rxtx_cnt <= 1) 
            //due to the way the counter would be incremented if this wasn't
            // a stop bit, we check for <= 1 rather than 0 as counter is 1 ahead
            //we're done here
            next_state <= S_DONE;
        else if(sda_rising_edge == 1 && scl_di_reg == 1 && i2c_rxtx_cnt > 1)
            //this is an error, this shouldn't happen mid-byte
            next_state <= S_ERROR;
        else if(scl_falling_edge == 1 && i2c_rxtx_done == 1)
            next_state <= S_DATA_RX_ACK;
        else
            next_state <= S_DATA_RX;
    end
    S_DATA_RX_ACK: begin
        i2c_ack <= 1;
        i2c_rxtx_clr <= 1;
        if(sda_rising_edge == 1 && scl_di_reg == 1)
            //this is an error, this shouldn't happen mid-byte
            next_state <= S_ERROR;
        else if(scl_falling_edge == 1) 
            next_state <= S_DATA_WAIT;
        else
            next_state <= S_DATA_RX_ACK;
    end

    S_DATA_TX_LD: begin
        i2c_tx_ld <= 1;
        next_state <= S_DATA_TX;
    end

    S_DATA_TX: begin
        i2c_tx_en <= 1;
        if(sda_rising_edge == 1 && scl_di_reg == 1 && i2c_rxtx_cnt == 0)
            //we're done here
            next_state <= S_DONE;
        else if(sda_rising_edge == 1 && scl_di_reg == 1 && i2c_rxtx_cnt != 0)
            //this is an error, this shouldn't happen mid-byte
            next_state <= S_ERROR;
        else if(scl_falling_edge == 1 && i2c_rxtx_done == 1)
            next_state <= S_DATA_TX_ACK;
        else
            next_state <= S_DATA_TX;
    end

    S_DATA_TX_ACK: begin
        //unlike with the RX_ACK, the ACK actually comes from the master
        if(scl_rising_edge == 1) 
            if(sda_di_reg == 1)
                next_state <= S_DATA_WAIT;
            else
                next_state <= S_ERROR; //the master didn't ack for some reason
        else
            next_state <= S_DATA_TX_ACK;
    end

    S_IGNORE: begin
        //wait until a stop bit
        if(sda_rising_edge == 1 && scl_di_reg == 1)
            next_state <= S_DONE;
        else
            next_state <= S_IGNORE;
    end

    S_DONE: begin
        i2c_rxtx_clr <= 1;
        next_state <= S_IDLE;
    end

    default: begin //includes S_ERROR
        i2c_error_stb <= 1;
        next_state <= S_DONE;
    end
endcase
end

assign scl_ndo = 0;
assign sda_ndo = 0 | i2c_ack | (i2c_tx_en ? i2c_rxtx_reg[7] : 0);


endmodule