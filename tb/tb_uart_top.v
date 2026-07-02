`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/07/02 14:57:24
// Design Name: 
// Module Name: tb_uart_top
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


module tb_uart_top(

    );
    reg clk;
    reg rst_n;
    reg start;
    reg [7:0] tx_data;
    
    wire tx_busy;
    wire rx_done;
    wire dout;
    
    
    uart_top dut(
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .tx_data(tx_data),
    .tx_busy(tx_busy),
    .rx_done(rx_done),
    .dout(dout)
    );
    
    
    initial begin
        start = 1'd0;
        tx_data = 8'd0;
        clk = 1'd0;
        rst_n = 1'd0;
        #200;
        
        rst_n = 1'd1;
        tx_data = 8'b10110010;
        start = 1'd1;
        #10;
        start = 1'd0;
        
        #2000000;
        $finish;
    end
    
    always #5 clk = ~clk;
    
endmodule
