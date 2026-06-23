`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/06/23 11:11:58
// Design Name: 
// Module Name: uart_rx
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


module uart_rx(
    input clk,
    input rst_n,
    input rx,
    input sampling_tick,
    output reg rx_done,
    output reg [7:0] dout
    );
    // 설계목표: rx에서 start bit를 감지해서 그 이후로 8bit의 데이터를 parallel data로 변환
    // -start 감지
    // -data 저장
    // -done 신호 켜기
    
    reg [1:0] state;    //state를 어떻게 해야하지....
    
    //ready, start, running, end? -----아니 그럴거면 start를 굳이 해야하나?
    reg [3:0] cnt_t;  //tick이 튄 횟수를 셀 카운터-16까지 수를 세야함 -> need 4bit
    reg [2:0] cnt_d;  //data를 셀 카운터-8bit data의 수를 세야함-> need 3bit
    
    always@ (posedge clk) begin
        if (!rst_n) begin
            rx_done <= 1'd0;
            dout<= 8'd0;
            cnt_t <= 4'd0;
            cnt_d <= 3'd0;
        end
        else begin
             if (!rx) begin
                
             end
        
        
        end
    
    end
    
    
    
endmodule
