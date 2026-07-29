`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/07/29 17:15:58
// Design Name: 
// Module Name: read_channel_simulation
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


module read_channel_simulation(
    );
    //global signal
    reg clk;
    reg rst_n;
    
    //write
    reg [31:0] awaddr;
    reg awvalid;
    reg [2:0] awprot;
    
    reg [31:0] wdata;
    reg wvalid;
    reg [3:0] wstrb;
    
    reg bready;
    
    //read
    reg arvalid;
    reg [2:0] arprot;
    reg [31:0] araddr;
    
    reg rready;
    
    wire awready;
    wire wready;
    wire bvalid;
    wire bresp;
    wire arready;
    wire rvalid;
    wire rdata;
    wire rresp;
    
    axi_lite_slave dut (
        .s_aclk(clk),
        .s_arst_n(rst_n),
        
        .s_awaddr(awaddr),
        .s_awvalid(awvalid),
        .s_awprot(awprot),
        
        .s_wdata(wdata),
        .s_wvalid(wvalid),
        .s_wstrb(wstrb),
        
        .s_bready(bready),
        
        .s_arvalid(arvalid),
        .s_arprot(arprot),
        .s_araddr(araddr),
        
        .s_rready(rready),
        
        .s_awready(awready),
        .s_wready(wready),
        .s_bvalid(bvalid),
        .s_bresp(bresp),
        .s_arready(arready),
        .s_rvalid(rvalid),
        .s_rdata(rdata),
        .s_rresp(rresp)
    );
    always #5 clk =~clk;
    
    initial begin
        clk <= 1'd0;
        rst_n <= 1'd0;
        #20
        bready <= 1'd0;
        rst_n <= 1'd1;
        
        $display("[%0t ns] task started", $time);
        
        $display("[%0t ns] task finished", $time);
        $finish;
    end
    
    task common_case (
        input [31:0] tb_addr,
        output [31:0] tb_data
    );
        reg flag;
        begin
            
        end
        
    endtask
endmodule
