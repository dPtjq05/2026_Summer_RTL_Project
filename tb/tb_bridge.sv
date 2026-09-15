`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/08/04 17:14:17
// Design Name: 
// Module Name: tb_bridge
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


module tb_bridge(

    );
    
    localparam bit_period = 104320; // 9600 bps 기준 비트 주기 (ns)

    reg clk;
    reg rst_n;
    reg rx;
    wire tx;
    system_top uut (
        .clk   (clk),
        .rst_n (rst_n),
        .rx    (rx),
        .tx    (tx)
    );
    
    
    always #5 clk = ~clk;
    
    initial begin
        clk = 1'd0;
        rst_n = 1'd0;
        rx = 1'd1;    
        #20 rst_n = 1'd1;
        
        common_write(8'h57, 32'h0101_0010, 32'h0110_0110);
        //cmd-addr-data
        #20000;
        common_read(8'h52, 32'h0101_0010);
        //cmd-addr
    end
    
    task common_write (
        input [7:0] cmd,
        input [31:0] addr,
        input [31:0] data
    );
        send_byte(cmd);
        
        send_byte(addr[31:24]); //01
        send_byte(addr[23:16]); //01
        send_byte(addr[15:8]);  //00
        send_byte(addr[7:0]);   //10
        
        send_byte(data[31:24]); //01
        send_byte(data[23:16]); //10
        send_byte(data[15:8]);  //01
        send_byte(data[7:0]);   //10
        
    endtask
    
    task common_read(
        input [7:0] cmd_w,
        input [31:0] addr_w
        );
        send_byte(cmd_w);
        
        send_byte(addr_w[31:24]);
        send_byte(addr_w[23:16]);
        send_byte(addr_w[15:8]);
        send_byte(addr_w[7:0]);
    
    endtask
    
    task send_byte(
        input [7:0] data
    );
        begin
            rx = 1'd0;
            #bit_period;
            for (int i =0; i< 8; i++) begin
                rx = data[i];
                #bit_period;
            end
            
            rx = 1'd1;  //stop bit 할당
            #bit_period;
        end
    endtask
    
    
endmodule
