`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/06/20 21:51:38
// Design Name: 
// Module Name: keys
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

/*
    key_filter u_key_filter(
        .sys_clk   (),
        .sys_rst_n (),
        .key       (),
        .key_flag  ()
    );
*/
module key_filter(
    input  wire  clk,
    input  wire  rst_n,
    input  wire  key,
    output reg   key_flag
    
    );
    parameter CLK_FRE = 50;
    parameter CNT_20MS= 20_000*CLK_FRE;

    reg [21:0]  cnt_20ms;
    reg         en_cnt_20ms;
    wire        end_cnt_20ms;

    reg key0;
    reg key1;
    wire key_negedge;

    //按键下降沿
    assign key_negedge = ~key0 & key1;
    always @(posedge clk or negedge rst_n) begin
        if (rst_n==1'b0)begin
            key0 <= 1'b0;
            key1 <= 1'b0;
        end
        else begin
            key0 <= key;
            key1 <= key0;
        end
    end
 
    //20ms计数器
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            cnt_20ms <= 22'd0;
        else if(en_cnt_20ms) begin
            if(end_cnt_20ms)
                cnt_20ms <= 22'd0;
            else
                cnt_20ms <= cnt_20ms + 1'b1;
        end
        else
            cnt_20ms <= cnt_20ms;
    end
    assign end_cnt_20ms = en_cnt_20ms && (cnt_20ms == CNT_20MS);
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            en_cnt_20ms <= 1'b0;
        else if(key_negedge)
            en_cnt_20ms <= 1'b1;
        else if(end_cnt_20ms)
            en_cnt_20ms <= 1'b0;
        else
            en_cnt_20ms <= en_cnt_20ms;
    end
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            key_flag <= 1'b0;
        else if(end_cnt_20ms && !key)
            key_flag <= 1'b1;
        else
            key_flag <= 1'b0;
    end
  
endmodule