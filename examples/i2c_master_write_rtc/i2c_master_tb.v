`default_nettype none
module i2c_master_tb();

    localparam [7:1] SLAVE_i2C_ADDR = 7'h42;

    reg clk = 0;
    reg rst_n = 0;
    reg scl_di = 0;
    reg sda_di = 0;

    wire scl_pulldown_slave, scl_pulldown_master;
    wire sda_pulldown_slave, sda_pulldown_master;

    always @(scl_pulldown_master or scl_pulldown_slave or sda_pulldown_master or sda_pulldown_slave) begin
        sda_di <= 1;
        scl_di <= 1;

        if(sda_pulldown_slave || sda_pulldown_master) begin
            sda_di <= 0;
        end

        if(scl_pulldown_slave || scl_pulldown_master) begin
            scl_di <= 0;
        end
    end

    reg sda_pulldown_reg = 0;

    reg stall;
    wire [7:0] slave_i2c_addr_rw;
    wire slave_i2c_addr_rw_valid_stb;
    
    wire [7:0] slave_i2c_data_rx;
    wire slave_i2c_data_rx_valid_stb;

    reg [7:0] slave_i2c_data_tx;
    wire slave_i2c_data_tx_loaded_stb;
    wire slave_i2c_data_tx_done_stb;
    wire slave_i2c_error_stb;


    i2c_simple_slave #(
        .i2c_address(SLAVE_i2C_ADDR)
    ) i2c_simple_slave_inst (
        .clk(clk),
        .rst_n(rst_n),

        .scl_di(scl_di),
        .sda_di(sda_di),
        .scl_pulldown(scl_pulldown_slave),
        .sda_pulldown(sda_pulldown_slave),

        .stall(1'b0),
        .i2c_addr_rw(slave_i2c_addr_rw),
        .i2c_addr_rw_valid_stb(slave_i2c_addr_rw_valid_stb),

        .i2c_data_rx(slave_i2c_data_rx),
        .i2c_data_rx_valid_stb(slave_i2c_data_rx_valid_stb),

        .i2c_data_tx(slave_i2c_data_tx),
        .i2c_data_tx_loaded_stb(slave_i2c_data_tx_loaded_stb),
        .i2c_data_tx_done_stb(slave_i2c_data_tx_done_stb),

        .i2c_error_stb(slave_i2c_error_stb)
    );

    reg transaction_start_stb, transaction_restart, transaction_stop, transaction_continue;
    wire transaction_active, transaction_stalling;

    reg [7:0] master_i2c_data_tx;
    wire master_i2c_data_tx_loaded_stb;
    wire master_i2c_data_tx_done_stb;

    wire [7:0] master_i2c_data_rx;
    wire master_i2c_data_rx_valid_stb;

    wire master_i2c_error_stb;
    wire master_i2c_nack_stb;

    reg [7:0] master_i2c_addr_rw;

    reg master_rw_bit;

    i2c_master i2c_master_inst (
        .clk(clk),
        .rst_n(rst_n),

        .scl_di(scl_di),
        .sda_di(sda_di),
        .scl_pulldown(scl_pulldown_master),
        .sda_pulldown(sda_pulldown_master),

        .transaction_start_stb(transaction_start_stb), //strobe to start a transaction, must be held high for at least 1 cycle
        .transaction_active(transaction_active),    //1 == transaction in progress, 0 == idle
        .transaction_stalling(transaction_stalling),  //1 == transaction is stalling waiting for next byte/instruction
        .transaction_restart(transaction_restart),   //if 1, will end stall and restart the transaction 
        .transaction_stop(transaction_stop),      //if 1, will end stall and send a stop condition to end the transaction
        .transaction_continue(transaction_continue),  //if 1, will end stall and continue the transaction

        /* transaction data i/o */
        .i2c_addr_rw(master_i2c_addr_rw), // the address and rw bits to send for the transaction, must be held stable during the entire transaction

        .i2c_data_tx(master_i2c_data_tx),
        .i2c_data_tx_loaded_stb(master_i2c_data_tx_loaded_stb),
        .i2c_data_tx_done_stb(master_i2c_data_tx_done_stb),

        .i2c_data_rx(master_i2c_data_rx),
        .i2c_data_rx_valid_stb(master_i2c_data_rx_valid_stb),

        /* error reporting */
        .i2c_error_stb(master_i2c_error_stb),
        .i2c_nack_stb(master_i2c_nack_stb)
    );

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, i2c_master_tb);
        $display("Starting simulation");
    end

    reg [7:0] slave_i2c_data_rx_TB_CAPTURE;
    reg slave_i2c_data_tx_loaded_TB_CAPTURE;
    reg slave_i2c_error_TB_CAPTURE;
    reg [7:0] slave_i2c_addr_rw_TB_CAPTURE;

    always @(posedge clk) begin
        if(slave_i2c_data_rx_valid_stb) begin
            slave_i2c_data_rx_TB_CAPTURE = slave_i2c_data_rx;
            $display("Data received by SLAVE i2c: %h", slave_i2c_data_rx_TB_CAPTURE);
        end
        if(slave_i2c_error_stb) 
            slave_i2c_error_TB_CAPTURE = 1;
        if(slave_i2c_data_tx_loaded_stb)
            slave_i2c_data_tx_loaded_TB_CAPTURE = 1;
        if(slave_i2c_addr_rw_valid_stb) begin
            slave_i2c_addr_rw_TB_CAPTURE = slave_i2c_addr_rw;
            $display("Address and RW bits received by SLAVE i2c: %h", slave_i2c_addr_rw_TB_CAPTURE);
        end
    end

    reg [7:0] master_i2c_data_rx_TB_CAPTURE;
    reg master_i2c_data_tx_done_TB_CAPTURE;
    reg master_i2c_error_TB_CAPTURE;

    always @(posedge clk) begin
        if(master_i2c_data_rx_valid_stb) begin
            master_i2c_data_rx_TB_CAPTURE = master_i2c_data_rx;
            $display("Data received by MASTER i2c: %h", master_i2c_data_rx_TB_CAPTURE);
        end
        if(master_i2c_error_stb) 
            master_i2c_error_TB_CAPTURE = 1;
        if(master_i2c_data_tx_done_stb)
            master_i2c_data_tx_done_TB_CAPTURE = 1;
    end

    always begin
        #1 clk = ~clk;
    end

    reg [6:0] i2c_addr_to_send = 7'h42;
    reg [7:0] i2c_master_data_received = 8'h00;

    integer i;
    integer test_num = 0;
    always begin
        slave_i2c_addr_rw_TB_CAPTURE = 8'h00;
        master_rw_bit = 0; // start with a write transaction
        transaction_start_stb = 0; 
        transaction_restart = 0;
        transaction_stop = 0;
        transaction_continue = 0;
        
        master_i2c_addr_rw = {i2c_addr_to_send, master_rw_bit};

        rst_n = 0;
        #50; 
        rst_n = 1;
        #50; 

        

        ///////////////////////////////////
        $display("Test %d: Master writes a byte to the slave, and then ends the transaction", test_num);
        test_num = test_num + 1;
        ///////////////////////////////////

        slave_i2c_data_rx_TB_CAPTURE = 8'h00;
        
        master_rw_bit = 0; // start with a write transaction

        master_i2c_data_tx = 8'h37;
        @(negedge clk);
        transaction_start_stb = 1;
        @(negedge clk);
        transaction_start_stb = 0;

        @(posedge transaction_stalling);
        $display("Start, Address and RW bits sent, transaction is stalling waiting for the next instruction.");
        
        if(slave_i2c_addr_rw_TB_CAPTURE != {SLAVE_i2C_ADDR, master_rw_bit}) begin
            $display("TEST FAILED: Slave received incorrect address and rw bits. Expected %b, got %b", {SLAVE_i2C_ADDR, master_rw_bit}, slave_i2c_addr_rw_TB_CAPTURE);
            $finish;
        end else begin
            $display("TEST PASSED: Slave received correct address and rw bits");
        end

        $display("Sending CONTINUE.");
        @(negedge clk);
        transaction_continue = 1;
        @(negedge clk);
        transaction_continue = 0;

        @(posedge transaction_stalling);
        $display("Data byte sent, transaction is stalling waiting for the next instruction. Sending STOP to end the transaction.");
        @(negedge clk);
        transaction_stop = 1;
        @(negedge clk);
        transaction_stop = 0;

        @(negedge transaction_active);
        $display("Transaction completed, checking results...");
        @(negedge clk);

        //check that the slave received the correct data
        if(slave_i2c_data_rx_TB_CAPTURE != 8'h37) begin
            $display("TEST FAILED: Slave received incorrect data. Expected 0x37, got %h", slave_i2c_data_rx_TB_CAPTURE);
            $finish;
        end else begin
            $display("TEST PASSED: Slave received correct data");
        end

        
        ///////////////////////////////////
        $display("Test %d: Master writes a byte to a address with no listening slave (should result in a NACK)", test_num);
        test_num = test_num + 1;
        ///////////////////////////////////

        slave_i2c_data_rx_TB_CAPTURE = 8'h00;
        master_i2c_addr_rw = {i2c_addr_to_send + 7'b1, master_rw_bit};
        
        master_rw_bit = 0; // start with a write transaction
        
        master_i2c_data_tx = 8'h37;
        @(negedge clk);
        transaction_start_stb = 1;
        @(negedge clk);
        transaction_start_stb = 0;

        @(posedge master_i2c_nack_stb);
        $display("Master received NACK as expected because there is no slave listening at the address we sent.");
        $display("Waiting for transaction to go inactive.");
        @(negedge transaction_active);
        $display("Transaction completed.");

        ///////////////////////////////////
        $display("Test %d: Master writes two bytes to the slave, and then ends the transaction", test_num);
        test_num = test_num + 1;
        ///////////////////////////////////

        slave_i2c_data_rx_TB_CAPTURE = 8'h00;
        
        master_rw_bit = 0; // start with a write transaction
        master_i2c_addr_rw = {i2c_addr_to_send, master_rw_bit};

        master_i2c_data_tx = 8'h48;
        @(negedge clk);
        transaction_start_stb = 1;
        @(negedge clk);
        transaction_start_stb = 0;

        @(posedge transaction_stalling);
        $display("Start, Address and RW bits sent, transaction is stalling waiting for the next instruction.");
        
        if(slave_i2c_addr_rw_TB_CAPTURE != {SLAVE_i2C_ADDR, master_rw_bit}) begin
            $display("TEST FAILED: Slave received incorrect address and rw bits. Expected %b, got %b", {SLAVE_i2C_ADDR, master_rw_bit}, slave_i2c_addr_rw_TB_CAPTURE);
            $finish;
        end else begin
            $display("TEST PASSED: Slave received correct address and rw bits");
        end

        $display("Sending CONTINUE.");
        @(negedge clk);
        transaction_continue = 1;
        @(negedge clk);
        transaction_continue = 0;

        @(posedge transaction_stalling);
        $display("Data byte sent. Checking intermediate result...");
        //check that the slave received the correct data
        if(slave_i2c_data_rx_TB_CAPTURE != 8'h48) begin
            $display("TEST FAILED: Slave received incorrect data. Expected 0x48, got %h", slave_i2c_data_rx_TB_CAPTURE);
            $finish;
        end else begin
            $display("TEST PASSED: Slave received correct data");
        end
        master_i2c_data_tx = 8'h99;

        $display("Sending CONTINUE to send the next byte in the transaction.");
        @(negedge clk);
        transaction_continue = 1;
        @(negedge clk);
        transaction_continue = 0;

        @(posedge transaction_stalling);
        $display("Data byte sent, transaction is stalling waiting for the next instruction. Sending STOP to end the transaction.");
        @(negedge clk);
        transaction_stop = 1;
        @(negedge clk);
        transaction_stop = 0;

        @(negedge transaction_active);
        $display("Transaction completed, checking results...");
        @(negedge clk);
        //check that the slave received the correct data
        if(slave_i2c_data_rx_TB_CAPTURE != 8'h99) begin
            $display("TEST FAILED: Slave received incorrect data. Expected 0x99, got %h", slave_i2c_data_rx_TB_CAPTURE);
            $finish;
        end else begin
            $display("TEST PASSED: Slave received correct data");
        end
        
        ///////////////////////////////////
        $display("Test %d: Master reads a byte from the slave, and then ends the transaction", test_num);
        test_num = test_num + 1;
        ///////////////////////////////////

        master_rw_bit = 1; // set the read bit
        master_i2c_addr_rw = {i2c_addr_to_send, master_rw_bit};
        slave_i2c_data_tx = 8'hA5;
        slave_i2c_addr_rw_TB_CAPTURE = 8'h00;
        master_i2c_data_rx_TB_CAPTURE = 8'h00;

        @(negedge clk);
        transaction_start_stb = 1;
        @(negedge clk);
        transaction_start_stb = 0;

        @(posedge transaction_stalling);
        $display("Start, Address and RW bits sent, transaction is stalling waiting for the next instruction.");
        
        if(slave_i2c_addr_rw_TB_CAPTURE != {SLAVE_i2C_ADDR, master_rw_bit}) begin
            $display("TEST FAILED: Slave received incorrect address and rw bits. Expected %b, got %b", {SLAVE_i2C_ADDR, master_rw_bit}, slave_i2c_addr_rw_TB_CAPTURE);
            $finish;
        end else begin
            $display("TEST PASSED: Slave received correct address and rw bits");
        end

        $display("Sending CONTINUE.");
        @(negedge clk);
        transaction_continue = 1;
        @(negedge clk);
        transaction_continue = 0;

        @(posedge transaction_stalling);
        $display("Data byte received by master, transaction is stalling waiting for the next instruction. Sending STOP to end the transaction.");
        @(negedge clk);
        transaction_stop = 1;
        @(negedge clk);
        transaction_stop = 0;

        @(negedge transaction_active);
        $display("Transaction completed, checking results...");
        @(negedge clk);

        //check that the master received the correct data
        if(master_i2c_data_rx_TB_CAPTURE != 8'hA5) begin
            $display("TEST FAILED: Master received incorrect data. Expected 0xA5, got %h", master_i2c_data_rx_TB_CAPTURE);
            $finish;
        end else begin
            $display("TEST PASSED: Master received correct data");
        end


        ///////////////////////////////////
        $display("Test %d: Master writes a byte to the slave, then restarts, then writes two bytes", test_num);
        test_num = test_num + 1;
        ///////////////////////////////////

        master_rw_bit = 0; // set the write bit
        slave_i2c_data_rx_TB_CAPTURE = 8'h00;
        slave_i2c_addr_rw_TB_CAPTURE = 8'h00;
        master_i2c_addr_rw = {i2c_addr_to_send, master_rw_bit};

        master_i2c_data_tx = 8'h88;
        @(negedge clk);
        transaction_start_stb = 1;
        @(negedge clk);
        transaction_start_stb = 0;

        @(posedge transaction_stalling);
        $display("Start, Address and RW bits sent, transaction is stalling waiting for the next instruction.");
        
        if(slave_i2c_addr_rw_TB_CAPTURE != {SLAVE_i2C_ADDR, master_rw_bit}) begin
            $display("TEST FAILED: Slave received incorrect address and rw bits. Expected %b, got %b", {SLAVE_i2C_ADDR, master_rw_bit}, slave_i2c_addr_rw_TB_CAPTURE);
            $finish;
        end else begin
            $display("TEST PASSED: Slave received correct address and rw bits");
        end

        $display("Sending CONTINUE.");
        @(negedge clk);
        transaction_continue = 1;
        @(negedge clk);
        transaction_continue = 0;

        @(posedge transaction_stalling);
        $display("Data byte sent. Checking intermediate result...");
        //check that the slave received the correct data
        if(slave_i2c_data_rx_TB_CAPTURE != 8'h88) begin
            $display("TEST FAILED: Slave received incorrect data. Expected 0x88, got %h", slave_i2c_data_rx_TB_CAPTURE);
            $finish;
        end else begin
            $display("TEST PASSED: Slave received correct data");
        end

        $display("Sending RESTART to restart the transaction without sending a STOP condition.");
        slave_i2c_addr_rw_TB_CAPTURE = 8'h00;
        @(negedge clk);
        transaction_restart = 1;
        @(negedge clk);
        transaction_restart = 0;
        
        @(posedge transaction_stalling);
        $display("Start, Address and RW bits sent, transaction is stalling waiting for the next instruction.");
        
        if(slave_i2c_addr_rw_TB_CAPTURE != {SLAVE_i2C_ADDR, master_rw_bit}) begin
            $display("TEST FAILED: Slave received incorrect address and rw bits. Expected %b, got %b", {SLAVE_i2C_ADDR, master_rw_bit}, slave_i2c_addr_rw_TB_CAPTURE);
            $finish;
        end else begin
            $display("TEST PASSED: Slave received correct address and rw bits");
        end

        $display("Sending CONTINUE.");
        master_i2c_data_tx = 8'hAB;

        @(negedge clk);
        transaction_continue = 1;
        @(negedge clk);
        transaction_continue = 0;

        @(posedge transaction_stalling);
        $display("Data byte sent. Checking intermediate result...");
        //check that the slave received the correct data
        if(slave_i2c_data_rx_TB_CAPTURE != 8'hAB) begin
            $display("TEST FAILED: Slave received incorrect data. Expected 0xAB, got %h", slave_i2c_data_rx_TB_CAPTURE);
            $finish;
        end else begin
            $display("TEST PASSED: Slave received correct data");
        end

        $display("Sending CONTINUE to send the next byte in the transaction.");
        master_i2c_data_tx = 8'hCD;

        @(negedge clk);
        transaction_continue = 1;
        @(negedge clk);
        transaction_continue = 0;

        @(posedge transaction_stalling);
        $display("Data byte sent, transaction is stalling waiting for the next instruction. Sending STOP to end the transaction.");
        @(negedge clk);
        transaction_stop = 1;
        @(negedge clk);
        transaction_stop = 0;

        @(negedge transaction_active);
        $display("Transaction completed, checking results...");
        @(negedge clk);

        //check that the slave received the correct data
        if(slave_i2c_data_rx_TB_CAPTURE != 8'hCD) begin
            $display("TEST FAILED: Slave received incorrect data. Expected 0xCD, got %h", slave_i2c_data_rx_TB_CAPTURE);
            $finish;
        end else begin
            $display("TEST PASSED: Slave received correct data");
        end

        $display("ALL TESTS PASSED");


        ///////////////////////////////////
        $display("Test %d: Master writes a byte to the slave, then restarts, then reads two bytes", test_num);
        test_num = test_num + 1;
        ///////////////////////////////////

        master_rw_bit = 0; // set the write bit
        master_i2c_addr_rw = {i2c_addr_to_send, master_rw_bit};
        slave_i2c_data_rx_TB_CAPTURE = 8'h00;
        slave_i2c_addr_rw_TB_CAPTURE = 8'h00;

        master_i2c_data_tx = 8'h88;
        @(negedge clk);
        transaction_start_stb = 1;
        @(negedge clk);
        transaction_start_stb = 0;

        @(posedge transaction_stalling);
        $display("Start, Address and RW bits sent, transaction is stalling waiting for the next instruction.");
        
        if(slave_i2c_addr_rw_TB_CAPTURE != {SLAVE_i2C_ADDR, master_rw_bit}) begin
            $display("TEST FAILED: Slave received incorrect address and rw bits. Expected %b, got %b", {SLAVE_i2C_ADDR, master_rw_bit}, slave_i2c_addr_rw_TB_CAPTURE);
            $finish;
        end else begin
            $display("TEST PASSED: Slave received correct address and rw bits");
        end

        $display("Sending CONTINUE.");
        @(negedge clk);
        transaction_continue = 1;
        @(negedge clk);
        transaction_continue = 0;

        @(posedge transaction_stalling);
        $display("Data byte sent. Checking intermediate result...");
        //check that the slave received the correct data
        if(slave_i2c_data_rx_TB_CAPTURE != 8'h88) begin
            $display("TEST FAILED: Slave received incorrect data. Expected 0x88, got %h", slave_i2c_data_rx_TB_CAPTURE);
            $finish;
        end else begin
            $display("TEST PASSED: Slave received correct data");
        end

        $display("Sending RESTART to restart the transaction without sending a STOP condition.");
        master_rw_bit = 1; // set the read bit for the restarted transaction
        master_i2c_addr_rw = {i2c_addr_to_send, master_rw_bit};
        slave_i2c_data_tx = 8'h22;
        slave_i2c_addr_rw_TB_CAPTURE = 8'h00;
        master_i2c_data_rx_TB_CAPTURE = 8'h00;

        @(negedge clk);
        transaction_restart = 1;
        @(negedge clk);
        transaction_restart = 0;

        @(posedge transaction_stalling);
        $display("Start, Address and RW bits sent, transaction is stalling waiting for the next instruction.");
        
        if(slave_i2c_addr_rw_TB_CAPTURE != {SLAVE_i2C_ADDR, master_rw_bit}) begin
            $display("TEST FAILED: Slave received incorrect address and rw bits. Expected %b, got %b", {SLAVE_i2C_ADDR, master_rw_bit}, slave_i2c_addr_rw_TB_CAPTURE);
            $finish;
        end else begin
            $display("TEST PASSED: Slave received correct address and rw bits");
        end

        $display("Sending CONTINUE.");
        @(negedge clk);
        transaction_continue = 1;
        @(negedge clk);
        transaction_continue = 0;
        slave_i2c_data_tx = 8'h33; //put this slightly earlier than we expect because we're not properly stalling the slave, so it thinks data is ready before the master is done

        @(posedge transaction_stalling);
        $display("Data byte received. Checking intermediate result...");
        //check that the master received the correct data
        if(master_i2c_data_rx_TB_CAPTURE != 8'h22) begin
            $display("TEST FAILED: Master received incorrect data. Expected 0x22, got %h", master_i2c_data_rx_TB_CAPTURE);
            $finish;
        end else begin
            $display("TEST PASSED: Master received correct data");
        end

        $display("Sending CONTINUE to receive the next byte in the transaction.");
        

        @(negedge clk);
        transaction_continue = 1;
        @(negedge clk);
        transaction_continue = 0;

        @(posedge transaction_stalling);
        $display("Data byte received, transaction is stalling waiting for the next instruction. Sending STOP to end the transaction.");
        @(negedge clk);
        transaction_stop = 1;
        @(negedge clk);
        transaction_stop = 0;

        @(negedge transaction_active);
        $display("Transaction completed, checking results...");
        @(negedge clk);
        
        //check that the master received the correct data
        if(master_i2c_data_rx_TB_CAPTURE != 8'h33) begin
            $display("TEST FAILED: Master received incorrect data. Expected 0x33, got %h", master_i2c_data_rx_TB_CAPTURE);
            $finish;
        end else begin
            $display("TEST PASSED: Master received correct data");
        end


        $display("ALL TESTS PASSED");


        $finish;
    end

endmodule