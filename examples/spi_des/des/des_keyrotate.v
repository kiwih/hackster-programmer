module des_keyrotate(
    input wire [3:0] round,
    input wire [1:28] in,
    output reg [1:28] out
);
    always @(round or in) begin
        if(round == 4'd0 || round == 4'd1 || round == 4'd8 || round == 4'd15) begin
            out[1:27] <= in[2:28];
            out[28] <= in[1];
        end else begin
            out[1:26] <= in[3:28];
            out[27:28] <= in[1:2];
        end
    end
endmodule