//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Zping
// 
// Create Date: 2023/01/10 10:04
// Design Name: 
// Module Name: 
// Project Name: 
// Target Devices: EP4CE6F17C8
// Tool Versions: Quartus Prime 18.1
// Description: 
// 除法器
//移位相减，高位为余低位为商
// Dependencies: 
// 
// Revision:                       
// Revision 0.01 - File Created by Zping
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module div_rill (
    input   wire [3:0] a,
    input   wire [3:0] b,
    output  wire [3:0] quo,//quotient
    output  wire [3:0] rem//remainder
);
/////////////////////DEFINE Variables/////////////////////////////////////////////
    reg [7:0] tempa;
    reg [7:0] tempb;
/////////////////////PROGRAM AREA/////////////////////////////////////////////////
    integer i;
    always @(*) begin
        tempa = {4'd0,a};
        tempb = {b,4'd0};
        for(i=0;i<4;i=i+1)begin
            tempa={tempa[6:0],1'b0};
            if(tempa>=tempb)
                tempa = tempa-tempb+1'b1;
            else
                tempa = tempa;
        end
    end
    assign rem = tempa[7:4];
    assign quo = tempa[3:0];
endmodule