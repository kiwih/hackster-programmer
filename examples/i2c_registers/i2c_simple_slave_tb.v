`default_nettype none
module i2c_simple_slave_tb();

    task test_i2c_master_send_startbit;
        sda_di = 0;
        scl_di = 1;
        #50;
        sda_di = 0;
        scl_di = 0;
        #50;
    endtask

    task test_i2c_master_send_byte;
        input [7:0] send_byte;
        integer i;
        for(i = 0; i < 8; i = i + 1) begin
            sda_di = send_byte[7-i];
            scl_di = 0; #20; scl_di = 1;  #10; scl_di = 0;
            #20;
        end
    endtask

    task test_i2c_master_test_stretch_rx_ack;
        input want_stretch;
        input want_ack;
        //check ack
        sda_di = 0;
        scl_di = 0; #20; 
        scl_di = 1; sda_ndo_reg = sda_ndo; #10; scl_di = 0;
        if(sda_ndo_reg == 1 && want_ack) begin
            $display("ACK received correctly");
        end else if(sda_ndo_reg == 0 && !want_ack) begin
            $display("ACK not received correctly");
        end else begin
            $display("Error: ACK incorrect, want_ack=%b, got_ack=%b", want_ack, sda_ndo_reg);
            $finish;
        end
        #20;
        if(scl_ndo == 0 && want_stretch) begin
            $display("Error: Clock stretching not working");
            $finish;
        end
        $display("Clock stretch good");
        while(scl_ndo == 1) begin
            stall = 0;
            #1; //this is in case of clock stretching
        end
    endtask

    task test_i2c_master_receive_byte;
        output [7:0] receive_byte;
        //receive data
        integer i;
        for(i = 0; i < 8; i = i + 1) begin
            sda_di = 0;
            scl_di = 0; #20; scl_di = 1;
            receive_byte[7-i] = sda_ndo; 
            #10; scl_di = 0;
            #20;
        end
    endtask

    task test_i2c_master_test_stretch_tx_ack;
        input want_stretch;
        //send ack
        sda_di = 1;
        scl_di = 0; #20; scl_di = 1; #10; scl_di = 0;
        #20;
        if(scl_ndo == 0 && want_stretch) begin
            $display("Error: Clock stretching not working");
            $finish;
        end
        $display("Clock stretch good");
        while(scl_ndo == 1) begin
            stall = 0;
            #1; //this is in case of clock stretching
        end
    endtask

    task test_i2c_master_send_interbyte_gap;
        sda_di = 1;
        scl_di = 0;
        #50;
        sda_di = 0;
        scl_di = 0;
        #50;
    endtask

    task test_i2c_master_send_stopbit;
        scl_di = 1;
        #20
        sda_di = 1;
        #20;
    endtask

    reg clk = 0;
    reg rst_n = 0;
    reg scl_di = 0;
    reg sda_di = 0;

    wire scl_ndo;
    wire sda_ndo;
    reg sda_ndo_reg = 0;

    reg stall;
    wire [7:0] i2c_addr_rw;
    wire i2c_addr_rw_valid_stb;
    
    wire [7:0] i2c_data_rx;
    reg [7:0] i2c_data_rx_TB_CAPTURE;
    wire i2c_data_rx_valid_stb;

    reg [7:0] i2c_data_tx;
    wire i2c_data_tx_loaded_stb;
    wire i2c_data_tx_done_stb;
    wire i2c_error_stb;

    reg i2c_data_tx_loaded_TB_CAPTURE;
    reg i2c_error_TB_CAPTURE;

    i2c_simple_slave #(
        .i2c_address(7'h42)
    ) i2c_simple_slave_inst (
        .clk(clk),
        .rst_n(rst_n),

        .scl_di(scl_di),
        .sda_di(sda_di),
        .scl_pulldown(scl_ndo),
        .sda_pulldown(sda_ndo),

        .stall(stall),
        .i2c_addr_rw(i2c_addr_rw),
        .i2c_addr_rw_valid_stb(i2c_addr_rw_valid_stb),

        .i2c_data_rx(i2c_data_rx),
        .i2c_data_rx_valid_stb(i2c_data_rx_valid_stb),

        .i2c_data_tx(i2c_data_tx),
        .i2c_data_tx_loaded_stb(i2c_data_tx_loaded_stb),
        .i2c_data_tx_done_stb(i2c_data_tx_done_stb),

        .i2c_error_stb(i2c_error_stb)
    );

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, i2c_simple_slave_tb);
        $display("Starting simulation");
    end

    always @(posedge clk) begin
        if(i2c_data_rx_valid_stb) begin
            i2c_data_rx_TB_CAPTURE = i2c_data_rx;
            $display("Data received by i2c: %h", i2c_data_rx_TB_CAPTURE);
        end
        if(i2c_error_stb) 
            i2c_error_TB_CAPTURE = 1;
        if(i2c_data_tx_loaded_stb)
            i2c_data_tx_loaded_TB_CAPTURE = 1;
    end
    always begin
        #1 clk = ~clk;
    end

    reg [6:0] i2c_addr_to_send = 7'h42;
    reg [7:0] i2c_master_data_received = 8'h00;

    integer i;
    integer test_num = 0;
    always begin
        rst_n = 0;
        scl_di = 1;
        sda_di = 1;
        #50; 
        rst_n = 1;
        #50; 

        i2c_error_TB_CAPTURE = 0;
        test_num = test_num + 1;
        ///////////////////////////////////////////
        $display("\nTest %d: Simple Write", test_num);
        ///////////////////////////////////////////

        //send start bit
        test_i2c_master_send_startbit();
        //send addr and r/w
        test_i2c_master_send_byte({i2c_addr_to_send, 1'b0});
        //check ack
        test_i2c_master_test_stretch_rx_ack(0, 1);
        //gap data
        test_i2c_master_send_interbyte_gap();
        //send data
        test_i2c_master_send_byte(8'h3A);
        //check ack
        test_i2c_master_test_stretch_rx_ack(0, 1);
        //gap data
        test_i2c_master_send_interbyte_gap();
        //send stop bit
        test_i2c_master_send_stopbit();

        if(i2c_simple_slave_inst.state == i2c_simple_slave_inst.S_IDLE) begin
            $display("i2c state is correctly idle after transaction");
        end else begin
            $display("Error: i2c state not idle");
            $finish;
        end
        if(i2c_data_rx_TB_CAPTURE == 8'h3A) begin
            $display("Data received correctly");
        end else begin
            $display("Error: Data not received correctly");
            $finish;
        end
        if(i2c_error_TB_CAPTURE) begin
            $display("Error: i2c module improperly flagged error");
            $finish;
        end 

        test_num = test_num + 1;
        
        ///////////////////////////////////////////
        $display("\nTest %d: Ignore Byte", test_num);
        ///////////////////////////////////////////

        //send start bit
        test_i2c_master_send_startbit();
        //send addr and r/w
        test_i2c_master_send_byte({i2c_addr_to_send+1'b1, 1'b0});
        //check ack
        //check ack
        test_i2c_master_test_stretch_rx_ack(0, 0);
        //gap data
        test_i2c_master_send_interbyte_gap();
        //send data
        test_i2c_master_send_byte(8'hAA);
        //check ack
        test_i2c_master_test_stretch_rx_ack(0, 0);
        //gap data
        test_i2c_master_send_interbyte_gap();
        //send stop bit
        test_i2c_master_send_stopbit();
        if(i2c_simple_slave_inst.state == i2c_simple_slave_inst.S_IDLE) begin
            $display("i2c state is correctly idle after transaction");
        end else begin
            $display("Error: i2c state not idle");
            $finish;
        end
        if(i2c_data_rx_TB_CAPTURE != 8'hAA) begin
            $display("Data not received correctly");
        end else begin
            $display("Error: Data received correctly");
            $finish;
        end
        if(i2c_error_TB_CAPTURE) begin
            $display("Error: i2c module improperly flagged error");
            $finish;
        end

        test_num = test_num + 1;
        ///////////////////////////////////////////
        $display("\nTest %d: Read Byte", test_num);
        ///////////////////////////////////////////

        i2c_data_tx = 8'h91;

        //send start bit
        test_i2c_master_send_startbit();
        //send addr and r/w
        test_i2c_master_send_byte({i2c_addr_to_send, 1'b1});
        //check ack
        test_i2c_master_test_stretch_rx_ack(0, 1);
        //gap data
        test_i2c_master_send_interbyte_gap();
        //receive data
        test_i2c_master_receive_byte(i2c_master_data_received);

        if(i2c_master_data_received == 8'h91) begin
            $display("Data received correctly");
        end else begin
            $display("Error: Data not received correctly");
            $display("Expected: %h", 8'h91);
            $display("Received: %h", i2c_master_data_received);
            $finish;
        end

        //issue ack
        test_i2c_master_test_stretch_tx_ack(0);
        //gap data
        test_i2c_master_send_interbyte_gap();
        //send stop bit
        test_i2c_master_send_stopbit();

        if(i2c_simple_slave_inst.state == i2c_simple_slave_inst.S_IDLE) begin
            $display("i2c state is correctly idle after transaction");
        end else begin
            $display("Error: i2c state not idle");
            $finish;
        end
        if(i2c_error_TB_CAPTURE) begin
            $display("Error: i2c module improperly flagged error");
            $finish;
        end

        
        test_num = test_num + 1;
        ///////////////////////////////////////////
        $display("\nTest %d: Write Two Bytes", test_num);
        ///////////////////////////////////////////

        //send start bit
        test_i2c_master_send_startbit();
        //send addr and r/w
        test_i2c_master_send_byte({i2c_addr_to_send, 1'b0});
        //check ack
        test_i2c_master_test_stretch_rx_ack(0, 1);
        //gap data
        test_i2c_master_send_interbyte_gap();
        //send data
        test_i2c_master_send_byte(8'h01);
        //check ack
        test_i2c_master_test_stretch_rx_ack(0, 1);
        
        if(i2c_data_rx_TB_CAPTURE == 8'h01) begin
            $display("Data received correctly");
        end else begin
            $display("Error: Data not received correctly");
            $finish;
        end

        //gap data
        test_i2c_master_send_interbyte_gap();
        //send data
        test_i2c_master_send_byte(8'h4A);
        //check ack
        test_i2c_master_test_stretch_rx_ack(0, 1);

        if(i2c_data_rx_TB_CAPTURE == 8'h4A) begin
            $display("Data received correctly");
        end else begin
            $display("Error: Data not received correctly");
            $finish;
        end

        //gap data
        test_i2c_master_send_interbyte_gap();
        //send stop bit
        test_i2c_master_send_stopbit();

        if(i2c_simple_slave_inst.state == i2c_simple_slave_inst.S_IDLE) begin
            $display("i2c state is correctly idle after transaction");
        end else begin
            $display("Error: i2c state not idle");
            $finish;
        end
        if(i2c_error_TB_CAPTURE) begin
            $display("Error: i2c module improperly flagged error");
            $finish;
        end 

        
        test_num = test_num + 1;
        ///////////////////////////////////////////
        $display("\nTest %d: Write Two Bytes With Stretching", test_num);
        ///////////////////////////////////////////

        stall = 1;

        //send start bit
        test_i2c_master_send_startbit();
        //send addr and r/w
        test_i2c_master_send_byte({i2c_addr_to_send, 1'b0});
        //check ack
        test_i2c_master_test_stretch_rx_ack(1, 1);
        //gap data
        stall = 1;
        test_i2c_master_send_interbyte_gap();
        //send data
        test_i2c_master_send_byte(8'h02);
        //check ack
        test_i2c_master_test_stretch_rx_ack(1, 1);

        if(i2c_data_rx_TB_CAPTURE == 8'h02) begin
            $display("Data received correctly");
        end else begin
            $display("Error: Data not received correctly");
            $finish;
        end

        //gap data
        stall = 1;
        test_i2c_master_send_interbyte_gap();

        //send data
        test_i2c_master_send_byte(8'h4B);
        //check ack
        test_i2c_master_test_stretch_rx_ack(1, 1);

        if(i2c_data_rx_TB_CAPTURE == 8'h4B) begin
            $display("Data received correctly");
        end else begin
            $display("Error: Data not received correctly");
            $finish;
        end

        //gap data
        test_i2c_master_send_interbyte_gap();

        //send stop bit
        test_i2c_master_send_stopbit();

        if(i2c_simple_slave_inst.state == i2c_simple_slave_inst.S_IDLE) begin
            $display("i2c state is correctly idle after transaction");
        end else begin
            $display("Error: i2c state not idle");
            $finish;
        end
        if(i2c_error_TB_CAPTURE) begin
            $display("Error: i2c module improperly flagged error");
            $finish;
        end 

        
        test_num = test_num + 1;
        ///////////////////////////////////////////
        $display("\nTest %d: Read Two Bytes", test_num);
        ///////////////////////////////////////////

        i2c_data_tx = 8'hF0;
        i2c_data_tx_loaded_TB_CAPTURE = 0;

        //send start bit
        test_i2c_master_send_startbit();
        //send addr and r/w
        test_i2c_master_send_byte({i2c_addr_to_send, 1'b1});
        //check ack
        test_i2c_master_test_stretch_rx_ack(0, 1);
        //gap data
        test_i2c_master_send_interbyte_gap();
        //receive data
        test_i2c_master_receive_byte(i2c_master_data_received);

        if(i2c_master_data_received == 8'hF0) begin
            $display("Data received correctly");
        end else begin
            $display("Error: Data not received correctly");
            $display("Expected: %h", 8'hF0);
            $display("Received: %h", i2c_master_data_received);
            $finish;
        end

        if(i2c_data_tx_loaded_TB_CAPTURE == 1)
            $display("Data write strobe happened correctly");
        else begin
            $display("Error: Data write strobe not received");
            $finish;
        end
        i2c_data_tx_loaded_TB_CAPTURE = 0;
        i2c_data_tx = 8'h1A;

        //issue ack
        test_i2c_master_test_stretch_tx_ack(0);
        //gap data
        test_i2c_master_send_interbyte_gap();
        //receive data
        test_i2c_master_receive_byte(i2c_master_data_received);

        if(i2c_master_data_received == 8'h1A) begin
            $display("Data received correctly");
        end else begin
            $display("Error: Data not received correctly");
            $display("Expected: %h", 8'h1A);
            $display("Received: %h", i2c_master_data_received);
            $finish;
        end

        if(i2c_data_tx_loaded_TB_CAPTURE == 1) 
            $display("Data write strobe happened correctly");
        else begin
            $display("Error: Data write strobe not received");
            $finish;
        end
        
        i2c_data_tx_loaded_TB_CAPTURE = 0;

        //issue ack
        test_i2c_master_test_stretch_tx_ack(0);
        //gap data
        test_i2c_master_send_interbyte_gap();
        //send stop bit
        test_i2c_master_send_stopbit();

        if(i2c_simple_slave_inst.state == i2c_simple_slave_inst.S_IDLE) begin
            $display("i2c state is correctly idle after transaction");
        end else begin
            $display("Error: i2c state not idle");
            $finish;
        end
        if(i2c_error_TB_CAPTURE) begin
            $display("Error: i2c module improperly flagged error");
            $finish;
        end

        //todo


        ///////////////////////////////
        //////TEST 6: RESTART//////////
        ///////////////////////////////

        //todo

        ///////////////////////////////
        //////TEST 7: CLOCK STRETCH////
        ///////////////////////////////

        //*/
        $display("ALL TESTS PASSED");

        $finish;

    end


endmodule