`default_nettype none
module i2c_simple_slave_tb();

    reg clk = 0;
    reg rst_n = 0;
    reg scl_di = 0;
    reg sda_di = 0;

    wire scl_ndo;
    wire sda_ndo;

    reg sda_ndo_reg = 0;

    wire [7:0] i2c_data_rd;
    wire i2c_data_rd_valid_stb;
    reg [7:0] i2c_data_rd_reg;
    
    reg [7:0] i2c_data_wr = 0;
    wire i2c_data_wr_finish_stb;
    reg i2c_data_wr_finish_stb_capture = 0;

    wire i2c_error_stb;
    reg error_capture = 0;

    reg i2c_addr_stall = 0;
    reg i2c_data_rd_stall = 0;
    reg i2c_data_wr_stall = 0;

    i2c_simple_slave #(
        .i2c_address(7'h42)
    ) i2c_simple_slave_inst (
        .clk(clk),
        .rst_n(rst_n),

        .scl_di(scl_di),
        .sda_di(sda_di),
        .scl_ndo(scl_ndo),
        .sda_ndo(sda_ndo),

        .i2c_addr_stall(i2c_addr_stall),

        .i2c_data_rd_stall(i2c_data_rd_stall),
        .i2c_data_rd(i2c_data_rd),
        .i2c_data_rd_valid_stb(i2c_data_rd_valid_stb),

        .i2c_data_wr_stall(i2c_data_wr_stall),
        .i2c_data_wr(i2c_data_wr),
        .i2c_data_wr_finish_stb(i2c_data_wr_finish_stb),

        .i2c_error_stb(i2c_error_stb)
    );

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, i2c_simple_slave_tb);
        $display("Starting simulation");
    end

    always @(posedge clk) begin
        if(i2c_data_rd_valid_stb) begin
            i2c_data_rd_reg <= i2c_data_rd;
            $display("Data received by i2c: %h", i2c_data_rd);
        end
        if(i2c_error_stb) 
            error_capture = 1;
        if(i2c_data_rd_valid_stb)
            i2c_data_wr_finish_stb_capture = 1;
    end
    always begin
        #1 clk = ~clk;
    end

    reg [6:0] i2c_addr_to_send = 7'h42;
    reg [7:0] i2c_master_to_send = {i2c_addr_to_send, 1'b0};
    reg [7:0] i2c_master_data_to_send = 8'h3A;
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

        error_capture = 0;
        test_num = test_num + 1;
        ///////////////////////////////////////////
        $display("\nTest %d: Simple Write", test_num);
        ///////////////////////////////////////////
        i2c_master_to_send = {i2c_addr_to_send, 1'b0};
        i2c_master_data_to_send = 8'h3A;

        //send start bit
        sda_di = 0;
        scl_di = 1;
        #50;
        sda_di = 0;
        scl_di = 0;
        #50;

        //send addr and r/w
        for(i = 0; i < 8; i = i + 1) begin
            sda_di = i2c_master_to_send[7-i];
            scl_di = 0; #20; scl_di = 1;  #10; scl_di = 0;
            #20;
        end

        //check ack
        sda_di = 1;
        scl_di = 0; #20; scl_di = 1; sda_ndo_reg = sda_ndo; #10; scl_di = 0;
        if(sda_ndo_reg == 1) begin
            $display("ACK received correctly");
        end else begin
            $display("Error: ACK not received");
            $finish;
        end
        #20;

        //gap data
        sda_di = 1;
        scl_di = 0;
        #50;
        sda_di = 0;
        scl_di = 0;
        #50;

        //send data
        for(i = 0; i < 8; i = i + 1) begin
            sda_di = i2c_master_data_to_send[7-i];
            scl_di = 0; #20; scl_di = 1;  #10; scl_di = 0;
            #20;
        end

        //check ack
        sda_di = 0;
        scl_di = 0; #20; scl_di = 1; sda_ndo_reg = sda_ndo; #10; scl_di = 0;
        if(sda_ndo_reg == 1) begin
            $display("ACK received correctly");
        end else begin
            $display("Error: ACK not received");
            $finish;
        end
        #20;

        //gap data
        sda_di = 1;
        scl_di = 0;
        #50;
        sda_di = 0;
        scl_di = 0;
        #50;

        //send stop bit
        scl_di = 1;
        #20
        sda_di = 1;
        #20;

        if(i2c_simple_slave_inst.state == i2c_simple_slave_inst.S_IDLE) begin
            $display("i2c state is correctly idle after transaction");
        end else begin
            $display("Error: i2c state not idle");
            $finish;
        end
        if(i2c_data_rd_reg == i2c_master_data_to_send) begin
            $display("Data received correctly");
        end else begin
            $display("Error: Data not received correctly");
            $finish;
        end
        if(error_capture) begin
            $display("Error: i2c module improperly flagged error");
            $finish;
        end 

        test_num = test_num + 1;
        ///////////////////////////////////////////
        $display("\nTest %d: Ignore Byte", test_num);
        ///////////////////////////////////////////

        i2c_master_to_send = {i2c_addr_to_send+1'b1, 1'b0};
        i2c_master_data_to_send = 8'h00;

        //send start bit
        sda_di = 0;
        scl_di = 1;
        #50;
        sda_di = 0;
        scl_di = 0;
        #50;

        //send addr and r/w
        for(i = 0; i < 8; i = i + 1) begin
            sda_di = i2c_master_to_send[7-i];
            scl_di = 0; #20; scl_di = 1;  #10; scl_di = 0;
            #20;
        end

        //check ack
        sda_di = 1;
        scl_di = 0; #20; scl_di = 1; sda_ndo_reg = sda_ndo; #10; scl_di = 0;
        if(sda_ndo_reg == 0) begin
            $display("ACK not received correctly");
        end else begin
            $display("Error: ACK received");
            $finish;
        end
        #20;

        //gap data
        sda_di = 1;
        scl_di = 0;
        #50;
        sda_di = 0;
        scl_di = 0;
        #50;

        //send data
        for(i = 0; i < 8; i = i + 1) begin
            sda_di = i2c_master_data_to_send[7-i];
            scl_di = 0; #20; scl_di = 1;  #10; scl_di = 0;
            #20;
        end

        //check ack
        sda_di = 0;
        scl_di = 0; #20; scl_di = 1; sda_ndo_reg = sda_ndo; #10; scl_di = 0;
        if(sda_ndo_reg == 0) begin
            $display("ACK not received correctly");
        end else begin
            $display("Error: ACK received");
            $finish;
        end
        #20;

        //gap data
        sda_di = 1;
        scl_di = 0;
        #50;
        sda_di = 0;
        scl_di = 0;
        #50;

        //send stop bit
        scl_di = 1;
        #20
        sda_di = 1;
        #20;

        if(i2c_simple_slave_inst.state == i2c_simple_slave_inst.S_IDLE) begin
            $display("i2c state is correctly idle after transaction");
        end else begin
            $display("Error: i2c state not idle");
            $finish;
        end
        if(i2c_data_rd_reg != i2c_master_data_to_send) begin
            $display("Data not received correctly");
        end else begin
            $display("Error: Data received correctly");
            $finish;
        end
        if(error_capture) begin
            $display("Error: i2c module improperly flagged error");
            $finish;
        end

        test_num = test_num + 1;
        ///////////////////////////////////////////
        $display("\nTest %d: Read Byte", test_num);
        ///////////////////////////////////////////

        i2c_data_wr = 8'h91;
        i2c_master_to_send = {i2c_addr_to_send, 1'b1};

        //send start bit
        sda_di = 0;
        scl_di = 1;
        #50;
        sda_di = 0;
        scl_di = 0;
        #50;

        //send addr and r/w
        for(i = 0; i < 8; i = i + 1) begin
            sda_di = i2c_master_to_send[7-i];
            scl_di = 0; #20; scl_di = 1;  #10; scl_di = 0;
            #20;
        end

        //check ack
        sda_di = 0;
        scl_di = 0; #20; scl_di = 1; sda_ndo_reg = sda_ndo; #10; scl_di = 0;
        if(sda_ndo_reg == 1) begin
            $display("ACK received correctly");
        end else begin
            $display("Error: ACK not received");
            $finish;
        end
        #20;

        //gap data
        sda_di = 1;
        scl_di = 0;
        #50;
        sda_di = 0;
        scl_di = 0;
        #50;

        //receive data
        for(i = 0; i < 8; i = i + 1) begin
            sda_di = 0;
            scl_di = 0; #20; scl_di = 1;
            i2c_master_data_received[7-i] = sda_ndo; 
            #10; scl_di = 0;
            #20;
        end

        if(i2c_master_data_received == i2c_data_wr) begin
            $display("Data received correctly");
        end else begin
            $display("Error: Data not received correctly");
            $display("Expected: %h", i2c_data_wr);
            $display("Received: %h", i2c_master_data_received);
            $finish;
        end

        //issue ack
        sda_di = 1;
        scl_di = 0; #20; scl_di = 1; #10; scl_di = 0;
        #20;

        //gap data
        sda_di = 1;
        scl_di = 0;
        #50;
        sda_di = 0;
        scl_di = 0;
        #50;

        //send stop bit
        scl_di = 1;
        #20
        sda_di = 1;
        #20;

        if(i2c_simple_slave_inst.state == i2c_simple_slave_inst.S_IDLE) begin
            $display("i2c state is correctly idle after transaction");
        end else begin
            $display("Error: i2c state not idle");
            $finish;
        end
        if(error_capture) begin
            $display("Error: i2c module improperly flagged error");
            $finish;
        end

        test_num = test_num + 1;
        ///////////////////////////////////////////
        $display("\nTest %d: Write Two Bytes", test_num);
        ///////////////////////////////////////////

        i2c_master_to_send = {i2c_addr_to_send, 1'b0};

        //send start bit
        sda_di = 0;
        scl_di = 1;
        #50;
        sda_di = 0;
        scl_di = 0;
        #50;

        //send addr and r/w
        for(i = 0; i < 8; i = i + 1) begin
            sda_di = i2c_master_to_send[7-i];
            scl_di = 0; #20; scl_di = 1;  #10; scl_di = 0;
            #20;
        end

        //check ack
        sda_di = 1;
        scl_di = 0; #20; scl_di = 1; sda_ndo_reg = sda_ndo; #10; scl_di = 0;
        if(sda_ndo_reg == 1) begin
            $display("ACK received correctly");
        end else begin
            $display("Error: ACK not received");
            $finish;
        end
        #20;

        //gap data
        sda_di = 1;
        scl_di = 0;
        #50;
        sda_di = 0;
        scl_di = 0;
        #50;

        //send data
        i2c_master_data_to_send = 8'h01;

        for(i = 0; i < 8; i = i + 1) begin
            sda_di = i2c_master_data_to_send[7-i];
            scl_di = 0; #20; scl_di = 1;  #10; scl_di = 0;
            #20;
        end

        //check ack
        sda_di = 0;
        scl_di = 0; #20; 
        while(scl_ndo == 1) begin
            #1; //this is in case of clock stretching
        end
        scl_di = 1; sda_ndo_reg = sda_ndo; #10; scl_di = 0;
        if(sda_ndo_reg == 1) begin
            $display("ACK received correctly");
        end else begin
            $display("Error: ACK not received");
            $finish;
        end
        #20;
        if(i2c_data_rd_reg == i2c_master_data_to_send) begin
            $display("Data received correctly");
        end else begin
            $display("Error: Data not received correctly");
            $finish;
        end

        //gap data
        sda_di = 1;
        scl_di = 0;
        #50;
        sda_di = 0;
        scl_di = 0;
        #50;

        //send data
        i2c_master_data_to_send = 8'h31;
        
        for(i = 0; i < 8; i = i + 1) begin
            sda_di = i2c_master_data_to_send[7-i];
            scl_di = 0; #20; scl_di = 1;  #10; scl_di = 0;
            #20;
        end

        //check ack
        sda_di = 0;
        scl_di = 0; #20; 
        while(scl_ndo == 1) begin
            #1; //this is in case of clock stretching
        end
        scl_di = 1; sda_ndo_reg = sda_ndo; #10; scl_di = 0;
        if(sda_ndo_reg == 1) begin
            $display("ACK received correctly");
        end else begin
            $display("Error: ACK not received");
            $finish;
        end
        #20;
        if(i2c_data_rd_reg == i2c_master_data_to_send) begin
            $display("Data received correctly");
        end else begin
            $display("Error: Data not received correctly");
            $finish;
        end

        //gap data
        sda_di = 1;
        scl_di = 0;
        #50;
        sda_di = 0;
        scl_di = 0;
        #50;

        //send stop bit
        scl_di = 1;
        #20
        sda_di = 1;
        #20;

        if(i2c_simple_slave_inst.state == i2c_simple_slave_inst.S_IDLE) begin
            $display("i2c state is correctly idle after transaction");
        end else begin
            $display("Error: i2c state not idle");
            $finish;
        end
        if(error_capture) begin
            $display("Error: i2c module improperly flagged error");
            $finish;
        end 

        test_num = test_num + 1;
        ///////////////////////////////////////////
        $display("\nTest %d: Write Two Bytes With Stretching", test_num);
        ///////////////////////////////////////////

        i2c_master_to_send = {i2c_addr_to_send, 1'b0};
        i2c_addr_stall = 1;
        i2c_data_rd_stall = 1;

        //send start bit
        sda_di = 0;
        scl_di = 1;
        #50;
        sda_di = 0;
        scl_di = 0;
        #50;

        //send addr and r/w
        for(i = 0; i < 8; i = i + 1) begin
            sda_di = i2c_master_to_send[7-i];
            scl_di = 0; #20; scl_di = 1;  #10; scl_di = 0;
            #20;
        end

        //check ack
        sda_di = 0;
        scl_di = 0; #20; 
        if(scl_ndo == 0) begin
            $display("Error: Clock stretching not working");
            $finish;
        end
        $display("Address clock stretch good");
        while(scl_ndo == 1) begin
            i2c_addr_stall = 0;
            #1; //this is in case of clock stretching
        end
        scl_di = 1; sda_ndo_reg = sda_ndo; #10; scl_di = 0;
        if(sda_ndo_reg == 1) begin
            $display("ACK received correctly");
        end else begin
            $display("Error: ACK not received");
            $finish;
        end
        #20;

        //gap data
        sda_di = 1;
        scl_di = 0;
        #50;
        sda_di = 0;
        scl_di = 0;
        #50;

        //send data
        i2c_master_data_to_send = 8'h01;

        for(i = 0; i < 8; i = i + 1) begin
            sda_di = i2c_master_data_to_send[7-i];
            scl_di = 0; #20; scl_di = 1;  #10; scl_di = 0;
            #20;
        end

        //check ack
        sda_di = 0;
        scl_di = 0; #20; 
        if(scl_ndo == 0) begin
            $display("Error: Clock stretching not working");
            $finish;
        end
        $display("Data clock stretch good");
        while(scl_ndo == 1) begin
            i2c_data_rd_stall = 0;
            #1; //this is in case of clock stretching
        end
        scl_di = 1; sda_ndo_reg = sda_ndo; #10; scl_di = 0;
        if(sda_ndo_reg == 1) begin
            $display("ACK received correctly");
        end else begin
            $display("Error: ACK not received");
            $finish;
        end
        i2c_data_rd_stall = 1;
        #20;

        if(i2c_data_rd_reg == i2c_master_data_to_send) begin
            $display("Data received correctly");
        end else begin
            $display("Error: Data not received correctly");
            $finish;
        end

        //gap data
        sda_di = 1;
        scl_di = 0;
        #50;
        sda_di = 0;
        scl_di = 0;
        #50;

        //send data
        i2c_master_data_to_send = 8'h31;
        
        for(i = 0; i < 8; i = i + 1) begin
            sda_di = i2c_master_data_to_send[7-i];
            scl_di = 0; #20; scl_di = 1;  #10; scl_di = 0;
            #20;
        end

        //check ack
        sda_di = 0;
        scl_di = 0; #20; 
        if(scl_ndo == 0) begin
            $display("Error: Clock stretching not working");
            $finish;
        end
        $display("Data clock stretch good");
        while(scl_ndo == 1) begin
            i2c_data_rd_stall = 0;
            #1; //this is in case of clock stretching
        end
        scl_di = 1; sda_ndo_reg = sda_ndo; #10; scl_di = 0;
        if(sda_ndo_reg == 1) begin
            $display("ACK received correctly");
        end else begin
            $display("Error: ACK not received");
            $finish;
        end
        i2c_data_rd_stall = 0;
        #20;

        if(i2c_data_rd_reg == i2c_master_data_to_send) begin
            $display("Data received correctly");
        end else begin
            $display("Error: Data not received correctly");
            $finish;
        end

        //gap data
        sda_di = 1;
        scl_di = 0;
        #50;
        sda_di = 0;
        scl_di = 0;
        #50;

        //send stop bit
        scl_di = 1;
        #20
        sda_di = 1;
        #20;

        if(i2c_simple_slave_inst.state == i2c_simple_slave_inst.S_IDLE) begin
            $display("i2c state is correctly idle after transaction");
        end else begin
            $display("Error: i2c state not idle");
            $finish;
        end
        if(error_capture) begin
            $display("Error: i2c module improperly flagged error");
            $finish;
        end 

        

        test_num = test_num + 1;
        ///////////////////////////////////////////
        $display("\nTest %d: Read Two Bytes", test_num);
        ///////////////////////////////////////////

        i2c_data_wr = 8'h45;
        i2c_master_to_send = {i2c_addr_to_send, 1'b1};

        //send start bit
        sda_di = 0;
        scl_di = 1;
        #50;
        sda_di = 0;
        scl_di = 0;
        #50;

        //send addr and r/w
        for(i = 0; i < 8; i = i + 1) begin
            sda_di = i2c_master_to_send[7-i];
            scl_di = 0; #20; scl_di = 1;  #10; scl_di = 0;
            #20;
        end

        //check ack
        sda_di = 0;
        scl_di = 0; #20; 
        if(scl_ndo == 1) begin
            $display("Error: Unexpected clock stretch");
            $finish;
        end
        scl_di = 1; sda_ndo_reg = sda_ndo; #10; scl_di = 0;
        if(sda_ndo_reg == 1) begin
            $display("ACK received correctly");
        end else begin
            $display("Error: ACK not received");
            $finish;
        end
        #20;

        //gap data
        sda_di = 1;
        scl_di = 0;
        #50;
        sda_di = 0;
        scl_di = 0;
        #50;

        i2c_data_wr_finish_stb_capture = 0;

        //receive data
        for(i = 0; i < 8; i = i + 1) begin
            sda_di = 0;
            scl_di = 0; #20; scl_di = 1;
            i2c_master_data_received[7-i] = sda_ndo; 
            #10; scl_di = 0;
            #20;
        end

        if(i2c_master_data_received == i2c_data_wr) begin
            $display("Data received correctly");
        end else begin
            $display("Error: Data not received correctly");
            $display("Expected: %h", i2c_data_wr);
            $display("Received: %h", i2c_master_data_received);
            $finish;
        end

        if(i2c_data_wr_finish_stb_capture == 1)
            $display("Data write strobe happened correctly");
        else begin
            $display("Error: Data write strobe not received");
            $finish;
        end
        i2c_data_wr_finish_stb_capture = 0;


        //issue ack
        sda_di = 1;
        scl_di = 0; #20; 
        if(scl_ndo == 1) begin
            $display("Error: Unexpected clock stretch");
            $finish;
        end
        scl_di = 1; #10; scl_di = 0;
        #20;

        //gap data
        sda_di = 1;
        scl_di = 0;
        #50;
        sda_di = 0;
        scl_di = 0;
        #50;

        i2c_data_wr = 8'hF0;
        
        i2c_data_wr_finish_stb_capture = 0;

        //receive data
        for(i = 0; i < 8; i = i + 1) begin
            sda_di = 0;
            scl_di = 0; #20; scl_di = 1;
            i2c_master_data_received[7-i] = sda_ndo; 
            #10; scl_di = 0;
            #20;
        end

        if(i2c_master_data_received == i2c_data_wr) begin
            $display("Data received correctly");
        end else begin
            $display("Error: Data not received correctly");
            $display("Expected: %h", i2c_data_wr);
            $display("Received: %h", i2c_master_data_received);
            $finish;
        end

        if(i2c_data_wr_finish_stb_capture == 1) 
            $display("Data write strobe happened correctly");
        else begin
            $display("Error: Data write strobe not received");
            $finish;
        end
        
        
        i2c_data_wr_finish_stb_capture = 0;


        //send stop bit
        scl_di = 1;
        #20
        sda_di = 1;
        #20;

        if(i2c_simple_slave_inst.state == i2c_simple_slave_inst.S_IDLE) begin
            $display("i2c state is correctly idle after transaction");
        end else begin
            $display("Error: i2c state not idle");
            $finish;
        end
        if(error_capture) begin
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

        $display("ALL TESTS PASSED");

        $finish;

    end


endmodule