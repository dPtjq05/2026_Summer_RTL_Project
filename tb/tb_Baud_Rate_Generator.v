`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/06/23 00:06:57
// Design Name: 
// Module Name: tb_Baud_Rate_Generator
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


module tb_Baud_Rate_Generator(
    );
    
    reg clk;
    reg rst_n;
    wire sampling_tick;     //output에는 reg타입을 연결할 수 없음.
    
    Baud_Rate_Generator uut (.clk(clk), .rst_n(rst_n), .sampling_tick(sampling_tick));
    
    always #5 clk <= ~clk;
    
    initial begin
        rst_n <= 1'd0;
        clk <= 1'd0;
        
        #5 rst_n <= 1'd1;
        
    
    end
endmodule
