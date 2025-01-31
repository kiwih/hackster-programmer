module des_fixedkey_scanchain_fsm(
    input wire clk,
    input wire rst_n,
    input wire start,
    output reg busy,

    output wire [3:0] round,
    output reg ld_output,
    output reg ld_l_r,
    output reg sel_l_r, //0 for l0/r0, 1 for 1 for r_round/l_round

    input wire scan_enable,
    input wire scan_in,
    output wire scan_out
);
    
    reg count_rst, count_enable;
    wire scan_count_out;

   //scan register for round counter
    scan_register #(
        .WIDTH(4)
    ) count (
        .clk(clk),
        .rst(count_rst),
        .enable(count_enable),
        .data_in(round + 4'd1),
        .data_out(round),
        .scan_enable(scan_enable),
        .scan_in(scan_in),
        .scan_out(scan_count_out)
    );

    localparam  S_IDLE = 2'd0,
                S_START = 2'd1,
                S_ROUND = 2'd2,
                S_LASTROUND = 2'd3;

    wire [1:0] state;
    reg [1:0] next_state;
    scan_register #(
        .WIDTH(2)
    ) state_reg (
        .clk(clk),
        .rst(~rst_n),
        .enable(1'b1),
        .data_in(next_state),
        .data_out(state),
        .scan_enable(scan_enable),
        .scan_in(scan_count_out),
        .scan_out(scan_out)
    );

    always@(state,start,round) begin
        busy <= 0;
        ld_output <= 0;
        ld_l_r <= 0;
        sel_l_r <= 0;
        count_rst <= 0;
        count_enable <= 0;
        case(state)
            S_IDLE: begin
                if(start) begin
                    next_state = S_START;
                end else begin
                    next_state = S_IDLE;
                end
            end
            S_START: begin
                count_rst <= 1;
                ld_l_r <= 1;
                busy <= 1;
                next_state = S_ROUND;
            end
            S_ROUND: begin
                count_enable <= 1;
                ld_l_r <= 1;
                sel_l_r <= 1;
                busy <= 1;
                if(round == 14) begin //mealy machine == count will be 15 in S_LASTROUND
                    next_state = S_LASTROUND;
                end else begin
                    next_state = S_ROUND;
                end
            end
            S_LASTROUND: begin
                busy <= 1;
                ld_output <= 1;
                next_state = S_IDLE;
            end
        endcase
    end

endmodule