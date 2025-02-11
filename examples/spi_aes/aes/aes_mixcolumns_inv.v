module aes_mixcolumns_inv(
    input wire [127:0] mxc_i,
    output reg [127:0] mxc_o
);

function [7:0] xtime;
	input [7:0] b; xtime={b[6:0],1'b0} ^ (8'h1b & {8{b[7]}});
endfunction

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

always@(mxc_i) begin
    // InvMixColumns(state);
    mxc_o = {
        x14(mxc_i[127:120]) ^ x11(mxc_i[119:112]) ^ x13(mxc_i[111:104]) ^ x09(mxc_i[103: 96]),
        x09(mxc_i[127:120]) ^ x14(mxc_i[119:112]) ^ x11(mxc_i[111:104]) ^ x13(mxc_i[103: 96]),
        x13(mxc_i[127:120]) ^ x09(mxc_i[119:112]) ^ x14(mxc_i[111:104]) ^ x11(mxc_i[103: 96]),
        x11(mxc_i[127:120]) ^ x13(mxc_i[119:112]) ^ x09(mxc_i[111:104]) ^ x14(mxc_i[103: 96]),
        
        x14(mxc_i[ 95: 88]) ^ x11(mxc_i[ 87: 80]) ^ x13(mxc_i[ 79: 72]) ^ x09(mxc_i[ 71: 64]),
        x09(mxc_i[ 95: 88]) ^ x14(mxc_i[ 87: 80]) ^ x11(mxc_i[ 79: 72]) ^ x13(mxc_i[ 71: 64]),
        x13(mxc_i[ 95: 88]) ^ x09(mxc_i[ 87: 80]) ^ x14(mxc_i[ 79: 72]) ^ x11(mxc_i[ 71: 64]),
        x11(mxc_i[ 95: 88]) ^ x13(mxc_i[ 87: 80]) ^ x09(mxc_i[ 79: 72]) ^ x14(mxc_i[ 71: 64]),
        
        x14(mxc_i[ 63: 56]) ^ x11(mxc_i[ 55: 48]) ^ x13(mxc_i[ 47: 40]) ^ x09(mxc_i[ 39: 32]),
        x09(mxc_i[ 63: 56]) ^ x14(mxc_i[ 55: 48]) ^ x11(mxc_i[ 47: 40]) ^ x13(mxc_i[ 39: 32]),
        x13(mxc_i[ 63: 56]) ^ x09(mxc_i[ 55: 48]) ^ x14(mxc_i[ 47: 40]) ^ x11(mxc_i[ 39: 32]),
        x11(mxc_i[ 63: 56]) ^ x13(mxc_i[ 55: 48]) ^ x09(mxc_i[ 47: 40]) ^ x14(mxc_i[ 39: 32]),
        
        x14(mxc_i[ 31: 24]) ^ x11(mxc_i[ 23: 16]) ^ x13(mxc_i[ 15:  8]) ^ x09(mxc_i[  7:  0]),
        x09(mxc_i[ 31: 24]) ^ x14(mxc_i[ 23: 16]) ^ x11(mxc_i[ 15:  8]) ^ x13(mxc_i[  7:  0]),
        x13(mxc_i[ 31: 24]) ^ x09(mxc_i[ 23: 16]) ^ x14(mxc_i[ 15:  8]) ^ x11(mxc_i[  7:  0]),
        x11(mxc_i[ 31: 24]) ^ x13(mxc_i[ 23: 16]) ^ x09(mxc_i[ 15:  8]) ^ x14(mxc_i[  7:  0])
    };
end

endmodule