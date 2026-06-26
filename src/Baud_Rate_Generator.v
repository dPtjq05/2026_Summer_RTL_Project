`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/06/22 15:28:48
// Design Name: 
// Module Name: Baud_Rate_Generator
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


module Baud_Rate_Generator(
    input clk,
    input rst_n,
    output reg sampling_tick
    );
    reg [9:0] cnt;    //clk을 받아서 지나온 클럭의 수를 세는 신호
    
    initial cnt <= 7'd0;
    //------------------------------------------//
    //sequential logic
    //매 클럭마다 카운터를 증가시킴, 만약 카운터값이 78이 되면 tick값을 1로 변경하고 다시 0으로 리셋
    always@ (posedge clk) begin
        if (!rst_n) begin
            cnt<=10'd0;
            sampling_tick <=1'd0;
        end
        else begin
            if (cnt==10'd651) begin
                sampling_tick <= 1'd1;
                cnt<= 10'd0;
            end
            else begin
                sampling_tick <= 1'd0;
                cnt <= cnt+ 10'd1;
            end
        end
    end
endmodule
