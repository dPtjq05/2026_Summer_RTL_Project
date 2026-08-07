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
    //logic 쓰는 거 압니다. 근데 공부하는 입장에서는 reg, wire 직접 구분하는 게 좋을 것 같아서 그렇습니다.
    wire tx_start, bready, arvalid, rready;
    wire [7:0] tx_data;
    wire [31:0] awaddr, wdata, araddr,rdata;
    wire awvalid, wvalid;
    wire [2:0] awprot, arprot;
    wire [3:0] wstrb;
    
    reg clk, rst_n, rx;
    wire [1:0] bresp, rresp;
    wire tx_busy, rx_done;
    wire [7:0] rx_data;
    wire awready, wready, bvalid,rvalid, arready;
    wire tx;
    
    bridge_uart_to_axi u_dut (
        .clk(clk),
        .rst_n(rst_n),
        
        .tx_busy(tx_busy),
        .rx_done(rx_done),
        .rx_data(rx_data),
        
        .m_axi_awready(awready),
        .m_axi_wready(wready),
        
        .m_axi_bresp(bresp),
        .m_axi_bvalid(bvalid),
        
        .m_axi_arready(arready),
        
        .m_axi_rdata(rdata),
        .m_axi_rresp(rresp),
        .m_axi_rvalid(rvalid),
        //output
        .tx_start(tx_start),
        .tx_data(tx_data),
        
        .m_axi_awaddr(awaddr),
        .m_axi_awvalid(awvalid),
        .m_axi_awprot(awprot),
        
        .m_axi_wdata(wdata),
        .m_axi_wvalid(wvalid),
        .m_axi_wstrb(wstrb),
        
        .m_axi_bready(bready),
        
        .m_axi_arvalid(arvalid),
        .m_axi_arprot(arprot),
        .m_axi_araddr(araddr),
        
        .m_axi_rready(rready)
        );
        
        
        
    uart_top dut_uart(
        .clk(clk),
        .rst_n(rst_n),
        .start(tx_start),
        .tx_data(tx_data),
        .rx(rx),
        //output
        .tx_busy(tx_busy),
        .rx_done(rx_done),
        .dout(rx_data),
        .tx(tx)
    );
    
    axi_lite_slave dut_axi(
        .s_aclk(clk),
        .s_arst_n(rst_n),
        
        .s_awaddr(awaddr),
        .s_awvalid(awvalid),
        .s_awprot(awprot),
        
        //write data channel
        .s_wdata(wdata),
        .s_wvalid(wvalid),
        .s_wstrb(wstrb),        //이게 좀 복병인데,,, 데이터 중에 몇 비트를 선택해서 사용할 것인지 나타낸다. 데이터랑 같이 들어옴.
        
        //write response channel
        .s_bready(bready),
        
        //read address channel
        .s_arvalid(arvalid),
        .s_arprot(arprot),
        .s_araddr(araddr),
        
        //read data channel
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
    
    
    always #5 clk = ~clk;
    
    initial begin
        clk = 1'd0;
        rst_n = 1'd0;
        rx = 1'd1;    
        #20 rst_n = 1'd1;
    end
    
    task common_write (
        input [7:0] cmd,
        input [31:0] addr,
        input [31:0] data
    );
        
    endtask
    
endmodule
