`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/06/26 08:21:32
// Design Name: 
// Module Name: uart_rx_top
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

// baud_rate_generator와 rx모듈을 연결해주는 top모듈
// tb를 좀 더 단순화하기 위한 구현
module uart_rx_top(
    input clk,
    input rst_n,
    input rx,
    output [7:0] dout,
    output rx_done
    );
    wire w_sampling_tick;
    
    Baud_Rate_Generator uut_b (
        .clk(clk),
        .rst_n(rst_n),
        .sampling_tick(w_sampling_tick)
    );
    
    uart_rx uut_r (
        .clk(clk),
        .rst_n(rst_n),
        .rx(rx),
        .sampling_tick(w_sampling_tick),
        .dout(dout),
        .rx_done(rx_done)
    );
    
endmodule
