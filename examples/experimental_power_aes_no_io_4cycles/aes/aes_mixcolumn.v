module aes_mixcolumn(
    input wire [31:0] mxc_i,
    output reg [31:0] mxc_o
);

function [7:0] xtime;
	input [7:0] b; xtime={b[6:0],1'b0} ^ (8'h1b & {8{b[7]}});
endfunction

reg [31:0] mxc_tmp;
always@(mxc_i) begin
    mxc_tmp = {
        mxc_i[ 31: 24] ^ mxc_i[ 23: 16] ^ mxc_i[ 15:  8] ^ mxc_i[  7:  0]
    };
    mxc_o = {
        mxc_i[ 31: 24] ^ xtime(mxc_i[ 31: 24] ^ mxc_i[ 23: 16]) ^ mxc_tmp[ 7: 0],
        mxc_i[ 23: 16] ^ xtime(mxc_i[ 23: 16] ^ mxc_i[ 15:  8]) ^ mxc_tmp[ 7: 0],
        mxc_i[ 15:  8] ^ xtime(mxc_i[ 15:  8] ^ mxc_i[  7:  0]) ^ mxc_tmp[ 7: 0],
        mxc_i[  7:  0] ^ xtime(mxc_i[  7:  0] ^ mxc_i[ 31: 24]) ^ mxc_tmp[ 7: 0]
    };
end

endmodule