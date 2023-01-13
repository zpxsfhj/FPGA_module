`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/07/03 11:18:31
// Design Name: 
// Module Name: iic_send
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


module iic_drive(
    input            clk           ,
    input            rst_n         ,
    input            drive_en      ,
    input      [7:0] iic_data_w    ,
    input      [15:0] iic_adress    ,
    input            iic_rh_wl     ,

    output reg [7:0] iic_data_r    ,
    output reg       iic_done      ,     
    output reg       iic_scl       ,
    output reg       iic_busy      ,
    inout  wire      sda   //双端口        

    //output  wire     sda_in        ,
    //output reg       rst_n0        ,
    //output reg       rst_n1        ,
    //output reg       sda_out       ,
    //output reg       drive_en_d0   ,
    //output reg       drive_en_d1   ,
    //output wire      drive_en_flag ,
    //output reg       sda_rw        ,
    //output reg [3:0] current_state 
    //output reg [3:0] next_state    ,
    //output reg [2:0] iic_ack       ,
    //output reg [3:0] iic_cnt       ,
    //output reg [7:0] clk_cnt       ,
    //output reg [7:0] device_addr   
    );
//////////////////////DEFINE Variables///////////////////////////////////
    parameter IDLE    = 4'b0000;//空闲状态
    parameter START   = 4'b0001;//起始信号
    parameter SL_ADDR = 4'b0111;//器件地址发送
    parameter ADDR8   = 4'b1111;//字节地址低八位发送
    parameter ADDR16  = 4'b1110;//字节地址高八位发送
    parameter DATA_W  = 4'b0101;//写数据
    parameter ADDR_R  = 4'b0100;//读地址
    parameter DATA_R  = 4'b1100;//读数据
    parameter STOP    = 4'b0010;//停止信号
    parameter R_START = 4'b0011;//读开始信号

    parameter CTR_ADDR_W = 8'b10100000;//器件地址_写
    parameter CTR_ADDR_R = 8'b10100001;//器件地址_读

    reg       rst_n0        ;//异步复位同步释放
    reg       rst_n1        ;
    reg       sda_out       ;//sda输出
    wire      sda_in        ;//sda输入
    reg       drive_en_d0   ;// 模块使能信号
    reg       drive_en_d1   ;
    wire      drive_en_flag ;//模块使能上升沿
    reg       drive_en_reg  ;//模块工作状态
    reg       sda_rw        ;//sda I/O控制信号
    reg [3:0] current_state ;// 状态机
    reg [3:0] next_state    ;
    reg [3:0] iic_ack       ;//从机应答信号
    reg [3:0] iic_cnt       ;//位个数计数器
    reg [7:0] clk_cnt       ;//位周期计数器
    reg [7:0] device_addr   ;//设备地址



/////////////////////PROGRAM AREA///////////////////////////////////////
//  双端口定义
    assign sda = sda_rw ? sda_out : 1'bz;
    assign sda_in = sda;

    assign drive_en_flag = drive_en_d0 & ~drive_en_d1;
    
    always @(posedge clk or negedge rst_n) begin//异步复位同步释放实现
        if(rst_n == 1'b0) begin
            rst_n0 <= 1'b0;
            rst_n1 <= 1'b0;
        end
        else begin
            rst_n0 <= 1'b1;
            rst_n1 <= rst_n0;
        end
    end
    always @(posedge clk or negedge rst_n1) begin
        if(rst_n1 == 1'b0)begin
            drive_en_d0 <= 1'b0;
            drive_en_d1 <= 1'b0;
        end
        else begin
            drive_en_d0 <= drive_en;
            drive_en_d1 <= drive_en_d0;
        end
    end
    always @(posedge clk or negedge rst_n1) begin
        if(rst_n1 == 1'b0)begin
            drive_en_reg <= 1'b0;
        end
        else begin
            if(drive_en_flag == 1'b1)
                drive_en_reg <= 1'b1;
            else if(clk_cnt == 8'd0)
                drive_en_reg <= 1'b0;
            else
                drive_en_reg <= drive_en_reg;
        end
    end
    always @(posedge clk or negedge rst_n1) begin//位周期计数
        if(rst_n1 == 1'b0)
            clk_cnt <= 8'd239;
        else if(clk_cnt == 8'd0 || drive_en_flag == 1'b1)
            clk_cnt <= 8'd239;   
        else 
            clk_cnt <= clk_cnt - 1'b1; 
    end

    always @(posedge clk or negedge rst_n1) begin//状态转移
        if(rst_n1 == 1'b0)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end
    always @(*) begin//状态转移条件，组合逻辑电路
        case (current_state)
            IDLE: begin
                if(drive_en_reg == 1'b1 && clk_cnt == 8'd239)
                    next_state = START;
                else
                    next_state = IDLE;
            end
            START: begin
                if(clk_cnt == 8'd0)
                    next_state = SL_ADDR;
                else
                    next_state = START;
            end
            SL_ADDR: begin
                if(iic_ack == 4'b0001 && clk_cnt == 8'd0)
                    next_state = ADDR16;
                else
                    next_state = SL_ADDR;
            end
            ADDR16: begin
                if(clk_cnt == 8'd0 && iic_ack == 4'b0011)
                    next_state = ADDR8;
                else
                    next_state = ADDR16;
            end
            ADDR8: begin
                if(iic_rh_wl == 1'b0 )begin
                    if(clk_cnt == 8'd0 && iic_ack == 4'b0111)
                        next_state = DATA_W;
                    else
                        next_state = ADDR8;
                end
                else if(iic_rh_wl == 1'b1 )begin
                    if(clk_cnt == 8'd0 && iic_ack == 4'b0111)
                        next_state = R_START;
                    else 
                        next_state = ADDR8;
                end
                else 
                    next_state = ADDR8;
            end
            DATA_W: begin
                if(clk_cnt == 8'd0 && iic_ack == 4'b1111)
                    next_state = STOP;
                else
                    next_state = DATA_W;
            end
            R_START: begin
                if(clk_cnt == 8'd0)
                    next_state = ADDR_R;
                else
                    next_state = R_START;
            end    
            ADDR_R: begin
                if(clk_cnt == 8'd0 && iic_ack == 4'b1111)
                    next_state = DATA_R;
                else
                    next_state = ADDR_R;
            end
            DATA_R: begin
                if(iic_cnt == 4'd8 && clk_cnt == 8'd0)
                    next_state = STOP;
                else 
                    next_state = DATA_R;
            end
            STOP: begin
                if(sda_out == 1'b1 && clk_cnt == 8'd0)
                    next_state = IDLE;
                else
                    next_state = STOP;
            end
            default: next_state = IDLE;
        endcase
    end
    always @(posedge clk or negedge rst_n1) begin//状态输出
        if(rst_n1 == 1'b0)begin
            sda_out <= 1'b1;
            sda_rw  <= 1'b1;
            iic_ack <= 4'b0000;
            iic_data_r <= 8'd0;
        end
        else begin
            case (current_state)
                IDLE: begin
                    sda_rw <= 1'b1;
                    sda_out <= 1'b1;
                    iic_ack <= 4'd0;
                end
                START: begin
                    sda_rw  <= 1'b1;
                    if(clk_cnt > 8'd119 )
                        sda_out <= 1'b1;
                    else
                        sda_out <= 1'b0;
                end
                SL_ADDR: begin
                    device_addr <= CTR_ADDR_W;
                    if(clk_cnt >8'd119 && iic_cnt < 4'd8)begin
                        sda_rw  <= 1'b1;
                        sda_out <= device_addr[7-iic_cnt];
                    end
                    else if(clk_cnt >8'd119 && iic_cnt == 4'd8)begin
                        sda_rw  <= 1'b0;
                        sda_out <= 1'd1;
                    end
                    else if(clk_cnt <= 8'd119 && iic_cnt == 4'd8) begin
                        sda_rw  <= 1'b0;
                        if(sda_in == 1'b0)
                            iic_ack[0] <= 1'b1;
                        else
                            iic_ack[0] <= 1'b0;
                    end  
                    else begin
                        sda_rw <= sda_rw;
                        sda_out <= sda_out;
                        iic_ack <= iic_ack;
                    end
                end
                ADDR16: begin
                    if(clk_cnt > 8'd119 && iic_cnt < 4'd8)begin
                        sda_rw  <= 1'b1;
                        sda_out <= iic_adress[15-iic_cnt];
                    end
                    else if(clk_cnt > 8'd119 && iic_cnt == 4'd8)begin
                        sda_rw  <= 1'b0;
                        sda_out <= 1'd1;
                    end
                    else if(clk_cnt <= 8'd119 && iic_cnt == 4'd8) begin
                        sda_rw  <= 1'b0;
                        if(sda_in == 1'b0)
                            iic_ack[1] <= 1'b1;
                        else
                            iic_ack[1] <= 1'b0;
                    end   
                    else begin
                        sda_rw <= sda_rw;
                        sda_out <= sda_out;
                        iic_ack <= iic_ack;
                    end 
                end
                ADDR8: begin
                    if(clk_cnt > 8'd119 && iic_cnt < 4'd8)begin
                        sda_rw  <= 1'b1;
                        sda_out <= iic_adress[7-iic_cnt];
                    end
                    else if(clk_cnt > 8'd119 && iic_cnt == 4'd8)begin
                        sda_rw  <= 1'b0;
                        sda_out <= 1'd1;
                    end
                    else if(clk_cnt <= 8'd119 && iic_cnt == 4'd8) begin
                        sda_rw  <= 1'b0;
                        if(sda_in == 1'b0)
                            iic_ack[2] <= 1'b1;
                        else
                            iic_ack[2] <= 1'b0;
                    end   
                    else begin
                        sda_rw <= sda_rw;
                        sda_out <= sda_out;
                        iic_ack <= iic_ack;
                    end 
                end
                DATA_W: begin
                    if(clk_cnt >8'd119 && iic_cnt < 4'd8)begin
                        sda_rw  <= 1'b1;
                        sda_out <= iic_data_w[7-iic_cnt];
                    end
                    else if(clk_cnt >8'd119 && iic_cnt == 4'd8)begin
                        sda_rw  <= 1'b0;
                        sda_out <= 1'd1;
                    end
                    else if(clk_cnt <= 8'd119 && iic_cnt == 4'd8) begin
                        sda_rw  <= 1'b0;
                        sda_out <= 1'd1;
                        if(sda_in == 1'b0)
                            iic_ack[3] <= 1'b1;
                        else
                            iic_ack[3] <= 1'b0;
                    end    
                    else begin
                        sda_rw <= sda_rw;
                        sda_out <= sda_out;
                        iic_ack <= iic_ack;
                    end 
                end
                R_START: begin
                    sda_rw  <= 1'b1;
                    if(clk_cnt > 8'd119 )
                        sda_out <= 1'b1;
                    else
                        sda_out <= 1'b0;
                end
                ADDR_R: begin
                    device_addr <= CTR_ADDR_R;
                    if(clk_cnt > 8'd119 && iic_cnt < 4'd8)begin
                        sda_rw  <= 1'b1;
                        sda_out <= device_addr[7-iic_cnt];
                    end
                    else if(clk_cnt > 8'd119 && iic_cnt == 4'd8)begin
                        sda_rw  <= 1'b0;
                        sda_out <= 1'd1;
                    end
                    else if(clk_cnt <= 8'd119 && iic_cnt == 4'd8) begin
                        sda_rw  <= 1'b0;
                        sda_out <= 1'd1;
                        if(sda_in == 1'b0)
                            iic_ack[3] <= 1'b1;
                        else
                            iic_ack[3] <= 1'b0;
                    end   
                    else begin
                        sda_rw <= sda_rw;
                        sda_out <= sda_out;
                        iic_ack <= iic_ack;
                    end    
                end
                DATA_R: begin
                    sda_rw  <= 1'b0;
                    sda_out <= 1'b0;
                    if(clk_cnt > 8'd119 && iic_cnt < 4'd8) begin
                        iic_data_r[7-iic_cnt] <= sda_in;
                    end 
                    else begin
                        iic_data_r <= iic_data_r;
                    end
                end
                STOP: begin
                    sda_rw <= 1'b1;
                    iic_ack <= 4'd0;
                    if(clk_cnt < 8'd119)
                        sda_out <= 1'b1;
                    else
                        sda_out <= 1'b0;
                end
            endcase
        end

    end
    
    always @(posedge clk) begin//位个数计数
        if(rst_n1 == 1'b0)
            iic_cnt <= 4'd0;
        else if(current_state > 4'd3)begin
            if((clk_cnt == 8'd0))begin
                if(iic_cnt < 4'd8)
                    iic_cnt <= iic_cnt + 1'b1;
                else
                    iic_cnt <= 4'd0;
            end
            else
                iic_cnt <= iic_cnt;  
        end
        else 
            iic_cnt <= 4'd0;  
    end
    always @(posedge clk or negedge rst_n1) begin//IIC 时钟控制
        if(rst_n1 == 1'b0)
            iic_scl <= 1'd0;
        else begin
            case (current_state)
                IDLE   : iic_scl <= 1'd1;
                START  : iic_scl <= 1'b1;
                STOP   : iic_scl <= 1'b1;
                R_START: iic_scl <= 1'b1;
                default: begin
                    if(clk_cnt < 8'd119)
                        iic_scl <= 1'b1;
                    else
                        iic_scl <= 1'b0;
                end
            endcase
        end 
    end
    always @(posedge clk or negedge rst_n1) begin//IIC 发送完成标志
        if(rst_n1 == 1'b0)
            iic_done <= 1'b0;
        else if(current_state == STOP)
            iic_done <= 1'b1;
        else
            iic_done <= 1'b0;
    end
    always @(posedge clk or negedge rst_n1) begin//IIC 忙碌信号
        if(rst_n1 == 1'b0)
            iic_busy <= 1'b0;
        else if(current_state == IDLE)
            iic_busy <= 1'b0;
        else
            iic_busy <= 1'b1;
    end

    ila_0 your_instance_name (//打探针，内置逻辑仪
	    .clk(clk), // input wire clk
	    .probe0(drive_en), // input wire [0:0]  probe0  
	    .probe1(iic_rh_wl), // input wire [0:0]  probe1 
	    .probe2(iic_done), // input wire [0:0]  probe2 
	    .probe3(sda_out), // input wire [0:0]  probe3 
	    .probe4(current_state), // input wire [0:0]  probe4 
	    .probe5(iic_scl), // input wire [0:0]  probe5 
	    .probe6(sda_in), // input wire [0:0]  probe6 
	    .probe7(iic_data_w), // input wire [7:0]  probe7 
	    .probe8(iic_data_r), // input wire [7:0]  probe8 
	    .probe9(iic_adress) // input wire [7:0]  probe9
);

endmodule