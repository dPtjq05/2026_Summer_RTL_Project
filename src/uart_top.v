`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/07/02 14:06:20
// Design Name: 
// Module Name: uart_top
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


module uart_top(
    input clk,
    input rst_n,
    input start,
    input [7:0] tx_data,
    
    output tx_busy,
    output rx_done,
    output [7:0] dout
    );
    wire sampling_tick;
    wire tx_rx;
    
    Baud_Rate_Generator brg(
    .clk(clk),
    .rst_n(rst_n),
    .sampling_tick(sampling_tick)
    );
    
    uart_tx tx(
    .clk(clk), 
    .rst_n(rst_n),
    .start(start),
    .tx_data(tx_data),
    .sampling_tick(sampling_tick),
    .tx(tx_rx),
    .tx_busy(tx_busy)
    );
    
    uart_rx rx(
    .clk(clk),
    .rst_n(rst_n),
    .rx(tx_rx),
    .sampling_tick(sampling_tick),
    .rx_done(rx_done),
    .dout(dout)
    );
    
endmodule
