`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/06/29 16:31:00
// Design Name: 
// Module Name: tb_uart_tx
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


module tb_uart_tx(

    );
    
    reg clk;
    reg rst_n;
    wire sampling_tick;
    reg start;
    reg [7:0] in_data;
    wire tx;
    wire tx_busy;
    
    Baud_Rate_Generator uut (
    .clk(clk),
    .rst_n(rst_n),
    .sampling_tick(sampling_tick)
    );
    
    uart_tx dut (
    .clk(clk),
    .rst_n(rst_n),
    .sampling_tick(sampling_tick),
    .start(start),
    .data(in_data),
    
    .tx(tx),
    .tx_busy(tx_busy)
    );
    
    always #5 clk = ~clk;
    always #10 in_data = ~in_data;
    
    initial begin
        clk = 1'd0;
        rst_n = 1'd0;
        in_data = 8'b10110010;
        #20;
        
        rst_n = 1'd1;
        start = 1'd1;
        
        #1000000;
        $finish;
    end
    
endmodule
