module aes_mixcolumns(
    input wire [127:0] mxc_i,
    output reg [127:0] mxc_o
);

function [7:0] xtime;
	input [7:0] b; xtime={b[6:0],1'b0} ^ (8'h1b & {8{b[7]}});
endfunction

/*
function [7:0] x02;
	input [7:0] b; x02={b[6:0],1'b0} ^ (8'h1b & {8{b[7]}});
endfunction

function [7:0] x03;
	input [7:0] b; x03=x02(b)^b;
endfunction

function [7:0] x04;
	input [7:0] b; x04=x02(x02(b));
endfunction

function [7:0] x08;
	input [7:0] b; x08=x02(x04(b));
endfunction

function [7:0] x09;
	input [7:0] b; x09=x08(b)^b;
endfunction

function [7:0] x11;
	input [7:0] b; x11=x08(b)^x02(b)^b;
endfunction

function [7:0] x13;
	input [7:0] b; x13=x08(b)^x04(b)^b;
endfunction

function [7:0] x14;
	input [7:0] b; x14=x08(b)^x04(b)^x02(b);
endfunction
*/

reg [31:0] mxc_tmp;
always@(mxc_i) begin
    mxc_tmp = {
        mxc_i[127:120] ^ mxc_i[119:112] ^ mxc_i[111:104] ^ mxc_i[103: 96],
        mxc_i[ 95: 88] ^ mxc_i[ 87: 80] ^ mxc_i[ 79: 72] ^ mxc_i[ 71: 64],
        mxc_i[ 63: 56] ^ mxc_i[ 55: 48] ^ mxc_i[ 47: 40] ^ mxc_i[ 39: 32],
        mxc_i[ 31: 24] ^ mxc_i[ 23: 16] ^ mxc_i[ 15:  8] ^ mxc_i[  7:  0]
    };
    mxc_o = {
        mxc_i[127:120] ^ xtime(mxc_i[127:120] ^ mxc_i[119:112]) ^ mxc_tmp[31:24],
        mxc_i[119:112] ^ xtime(mxc_i[119:112] ^ mxc_i[111:104]) ^ mxc_tmp[31:24],
        mxc_i[111:104] ^ xtime(mxc_i[111:104] ^ mxc_i[103: 96]) ^ mxc_tmp[31:24],
        mxc_i[103: 96] ^ xtime(mxc_i[103: 96] ^ mxc_i[127:120]) ^ mxc_tmp[31:24],
        
        mxc_i[ 95: 88] ^ xtime(mxc_i[ 95: 88] ^ mxc_i[ 87: 80]) ^ mxc_tmp[23:16],
        mxc_i[ 87: 80] ^ xtime(mxc_i[ 87: 80] ^ mxc_i[ 79: 72]) ^ mxc_tmp[23:16],
        mxc_i[ 79: 72] ^ xtime(mxc_i[ 79: 72] ^ mxc_i[ 71: 64]) ^ mxc_tmp[23:16],
        mxc_i[ 71: 64] ^ xtime(mxc_i[ 71: 64] ^ mxc_i[ 95: 88]) ^ mxc_tmp[23:16],
        
        mxc_i[ 63: 56] ^ xtime(mxc_i[ 63: 56] ^ mxc_i[ 55: 48]) ^ mxc_tmp[15: 8],
        mxc_i[ 55: 48] ^ xtime(mxc_i[ 55: 48] ^ mxc_i[ 47: 40]) ^ mxc_tmp[15: 8],
        mxc_i[ 47: 40] ^ xtime(mxc_i[ 47: 40] ^ mxc_i[ 39: 32]) ^ mxc_tmp[15: 8],
        mxc_i[ 39: 32] ^ xtime(mxc_i[ 39: 32] ^ mxc_i[ 63: 56]) ^ mxc_tmp[15: 8],
        
        mxc_i[ 31: 24] ^ xtime(mxc_i[ 31: 24] ^ mxc_i[ 23: 16]) ^ mxc_tmp[ 7: 0],
        mxc_i[ 23: 16] ^ xtime(mxc_i[ 23: 16] ^ mxc_i[ 15:  8]) ^ mxc_tmp[ 7: 0],
        mxc_i[ 15:  8] ^ xtime(mxc_i[ 15:  8] ^ mxc_i[  7:  0]) ^ mxc_tmp[ 7: 0],
        mxc_i[  7:  0] ^ xtime(mxc_i[  7:  0] ^ mxc_i[ 31: 24]) ^ mxc_tmp[ 7: 0]
    };
end

endmodule