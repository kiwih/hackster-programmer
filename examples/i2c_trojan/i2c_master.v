`default_nettype none

module i2c_master (
    input wire clk,
    input wire rst,
    input wire start,
    input wire rw,
    input wire [6:0] addr, // 7-bit EEPROM address
    input wire [7:0] byte_address, // 8-bit byte address to read/write
    input wire [7:0] din, // data to be sent to EEPROM
    input wire scl_in, // scl_out drive from slave
    input wire sda_in, // sda_out drive from slave
    output reg [7:0] dout, // data read from EEPROM
    output reg scl_out, // master scl_out
    output reg sda_out, // master sda_out
    output reg error,
    output reg byte_done
);

reg [7:0] clock_counter = 0;
reg periph_scl = 0;
reg periph_sda = 1; // by default no one should hold the sda_out line
reg [3:0] shift_counter = 0;
reg [7:0] data_reg = 0; // used to store addr+rw and transmission data.
reg dummy_write = 0;

assign scl_out = ~periph_scl;
assign sda_out = ~periph_sda; // it's flipped as it's a pulldown.

// Generate a 100K scl_out
always @(posedge clk)
begin
    if (clock_counter == 50) begin
        periph_scl <= ~periph_scl;
        clock_counter <= 0;
    end else begin
        clock_counter <= clock_counter + 1;
    end
end

// Detect scl_out falling for shifting data bits
reg periph_scl_falling = 0;
reg periph_scl_rising = 0;
reg prev_periph_scl = 0;
always @(posedge clk) begin
    prev_periph_scl <= periph_scl;
    periph_scl_falling <= (periph_scl == 0 && prev_periph_scl == 1);
    periph_scl_rising <= (periph_scl == 1 && prev_periph_scl == 0);
end

localparam IDLE = 4'b0000,
           START = 4'b0001,
           SEND_ADDR_RW = 4'b0010,
           ACK_ADDR_RW = 4'b0011,
           SEND_BYTE_ADDR = 4'b0100,
           ACK_BYTE_ADDR = 4'b0101,
           WRITE_DATA_BYTE = 4'b0110,
           ACK_WRITE_DATA_BYTE = 4'b0111,
           DUMMY_WAIT = 4'b1000,
           READ_DATA = 4'b1001,
           STOP = 4'b1010,
           ERROR = 4'b1011,
           ACK_READ_BYTE = 4'b1100,
           DONE = 4'b1101;
    
reg[3:0] state, next_state = IDLE;

// State flip flops
always @(posedge clk) begin
    if (rst == 1) begin
        state <= IDLE;
    end else begin
        state <= next_state;
    end
end

// State transitions
always @* begin
    next_state <= state;
    case (state)
        IDLE: begin
            if (start == 1) begin
                next_state <= START;
            end
        end
        
        START: begin
            if(periph_sda == 0 && periph_scl_falling == 1) begin // wait for the scl_out to be low after the start condition
                next_state <= SEND_ADDR_RW;
            end
        end

        SEND_ADDR_RW: begin
            if (shift_counter == 8 && periph_scl_falling == 1) begin
                next_state <= ACK_ADDR_RW;
            end
        end

        ACK_ADDR_RW: begin
            if (periph_scl_rising == 1) begin
                if (sda_in == 0) begin // make sure that the pull down value covers the period scl_out = 1
                    if ((rw == 1 && dummy_write == 1) || rw == 0) begin // read in dummy write mode, or write ops.
                        next_state <= SEND_BYTE_ADDR;
                    end else begin
                        next_state <= READ_DATA;
                    end
                end else begin // wait until the rising edge of scl_out
                    next_state <= ERROR;
            end
            end
        end

        SEND_BYTE_ADDR: begin
            if (shift_counter == 8 && periph_scl_falling == 1) begin
                next_state <= ACK_BYTE_ADDR;
            end
        end

        ACK_BYTE_ADDR: begin
            if (periph_scl_rising == 1) begin
                if (sda_in == 0) begin // make sure that the pull down value covers the period scl_out = 1
                    if (rw == 1) begin // read
                        next_state <= DUMMY_WAIT; // wait for another start signal
                    end else begin // write
                        next_state <= WRITE_DATA_BYTE;
                    end
                end else begin // wait until the rising edge of scl_out
                    next_state <= ERROR;
            end
            end
        end

        WRITE_DATA_BYTE: begin
            if (shift_counter == 8 && periph_scl_falling == 1) begin
                next_state <= ACK_WRITE_DATA_BYTE;
            end
        end

        ACK_WRITE_DATA_BYTE: begin
            if (periph_scl_rising == 1) begin
                if (sda_in == 0) begin
                    next_state <= DUMMY_WAIT;
                end else begin
                    next_state <= ERROR;
                end
            end
        end

        DUMMY_WAIT: begin
            if (periph_scl_falling == 1) begin // wait for scl_out to be low
                if (rw == 1 && dummy_write == 1) begin
                    next_state <= START; // regen start for read.
                end else begin
                    next_state <= STOP;
                end
            end
        end

        READ_DATA: begin
            if (shift_counter == 8 && periph_scl_falling == 1) begin
                next_state <= ACK_READ_BYTE;
            end
        end

        ACK_READ_BYTE: begin
            if (periph_scl_falling == 1) begin
                next_state <= DUMMY_WAIT; // pull down the sda.
            end
        end

        STOP: begin
            if (periph_scl_falling == 1) begin // wait for scl_out to be low
                next_state <= DONE;
            end
        end

        DONE: begin
            if (periph_scl_falling == 1) begin // wait for scl_out to be low
                next_state <= IDLE;
            end
        end

        ERROR: begin
            next_state <= IDLE;
        end

        default: next_state <= IDLE;
    endcase
end

// State output logic: combo logic
always @(posedge clk) begin
    // dummy_write <= 0;
    // dout <= 0;
    byte_done <= 0;
    error <= 0;
    case (state)
        IDLE: begin
            dummy_write <= 1;
        end

        START: begin
            if (clock_counter == 25 && periph_scl == 1) begin
                periph_sda <= 0; // initiate the start condition that sda_out goes low when scl_out remains high
            end
        end

        SEND_ADDR_RW: begin
            if (dummy_write == 1 || rw == 0) begin
                data_reg = {addr, 1'b0}; // when performing dummy write for reads and actual write operation, the last bit (rw) is 0.
            end else begin
                data_reg = {addr, 1'b1};
            end

            if (shift_counter < 8 && clock_counter == 15 && periph_scl == 0) begin
                periph_sda <= data_reg[7 - shift_counter];
                shift_counter <= shift_counter + 1;
            end else if (shift_counter == 8 && periph_scl_falling == 1) begin // wait for the next falling scl_out to change data
                // Release the sda_out line
                periph_sda <= 0;
                shift_counter <= 0;
            end
        end

        ACK_ADDR_RW: begin
            //do nothing
            periph_sda <= 1; // release sda line
        end

        SEND_BYTE_ADDR: begin
            data_reg = byte_address;
            if (shift_counter < 8 && clock_counter == 15 && periph_scl == 0) begin
                periph_sda <= data_reg[7 - shift_counter];
                shift_counter <= shift_counter + 1;
            end else if (shift_counter == 8 && periph_scl_falling == 1) begin // wait for the next falling scl_out to change data
                // Release the sda_out line
                periph_sda <= 0;
                shift_counter <= 0;
            end
        end

        ACK_BYTE_ADDR: begin
            // do nothing
            periph_sda <= 1; // release sda line
        end

        WRITE_DATA_BYTE: begin
            data_reg = din;
            if (shift_counter < 8 && clock_counter == 15 && periph_scl == 0) begin
                periph_sda <= data_reg[7 - shift_counter];
                shift_counter <= shift_counter + 1;
            end else if (shift_counter == 8 && periph_scl_falling == 1) begin // wait for the next falling scl_out to change data
                // Release the sda_out line
                periph_sda <= 0;
                shift_counter <= 0;
            end
        end

        ACK_WRITE_DATA_BYTE: begin
            //do nothing
            periph_sda <= 1; // release sda line
        end

        READ_DATA: begin
            // master should release the sda line by setting it to high-Z.
            periph_sda <= 1;
            // master should not drive the sda line. Declare a register to store slave response.
            if (shift_counter < 8 && periph_scl_rising == 1) begin
                dout[7 - shift_counter] = sda_in;
                shift_counter <= shift_counter + 1;
            end else if (shift_counter == 8 && periph_scl_falling == 1) begin
                shift_counter <= 0;
            end
        end

        ACK_READ_BYTE: begin
            periph_sda <= 1; // master should respond with no ack to slave at the end of one byte read.
        end

        DUMMY_WAIT: begin
            if (dummy_write == 1 && rw == 1) begin // if in read dummy write
                // pull up sda as we gen start later.
                periph_sda <= 1;
            end else begin
                periph_sda <= 0;
            end

            if (periph_scl_falling == 1) begin
                dummy_write <= 0;
            end
        end

        STOP: begin
            if (clock_counter == 25 && periph_scl == 1) begin
                periph_sda <= 1;
            end
        end

        ERROR: begin
            error <= 1;
        end

        DONE: begin
            byte_done <= 1;
        end

    endcase
end 

endmodule
