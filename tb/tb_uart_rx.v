`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/06/25 22:12:35
// Design Name: 
// Module Name: tb_uart_rx
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


module tb_uart_rx(

    );
    reg clk;
    reg rst_n;
    reg rx;
    wire rx_done;
    wire [7:0] dout;
    
    uart_rx_top uut (.clk(clk),
     .rst_n(rst_n),
     .rx(rx),
     .rx_done(rx_done),
     .dout(dout) 
     );
     
    initial begin
        clk = 1'd0;
        rst_n = 1'd0;
        
        #200;
        
        rst_n = 1'd1;
        rx = 1'd1;
        #200;
        rx = 1'd0;  //start_bit
        #104160;   //설계를 제대로 했다는 가정하에 tick이 8번 튀는데 걸리는 시간- 감지하는 시간이 반주기일뿐 신호 지속은 한주기 지속되어야한다.
        
        rx = 1'd1;  //0bit
        #104160;  //16 tick이 튀는 시간
        
        rx = 1'd0;  //1bit
        #104160;
        
        rx = 1'd1;  //2bit
        #104160;
        
        rx = 1'd1;  //3bit
        #104160;
        
        rx = 1'd0;  //4bit
        #104160;
        
        rx = 1'd0;  //5bit
        #104160;
        
        rx = 1'd1;  //6bit
        #104160;
        
        rx = 1'd0;  //7bit
        #104160;
        
        rx = 1'd1;  //stop bit
        #104160;
        
        #200;
        $finish;
        
    end
    
    always #5 clk = ~clk; //clk 신호 생성
    
    
    
endmodule
