`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/09/07 16:46:05
// Design Name: 
// Module Name: system_top
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


module system_top (
    input  wire clk,        
    input  wire rst_n,      
    input  wire rx,         
    output wire tx          
);

    // 1. 내부 인터커넥트 와이어 선언
    // UART <-> Bridge 와이어
    wire [7:0] rx_data;
    wire       rx_done;
    wire [7:0] tx_data;
    wire       tx_start;
    wire       tx_busy;

    // Bridge <-> AXI Slave 버스 와이어 (AW, W, B, AR, R 채널)
    wire [31:0] s_axi_awaddr;
    wire        s_axi_awvalid;
    wire        s_axi_awready;
    wire [31:0] s_axi_wdata;
    wire [3:0]  s_axi_wstrb;
    wire        s_axi_wvalid;
    wire        s_axi_wready;
    wire [1:0]  s_axi_bresp;
    wire        s_axi_bvalid;
    wire        s_axi_bready;
    wire [31:0] s_axi_araddr;
    wire        s_axi_arvalid;
    wire        s_axi_arready;
    wire [31:0] s_axi_rdata;
    wire [1:0]  s_axi_rresp;
    wire        s_axi_rvalid;
    wire        s_axi_rready;

    // 2. UART Top 모듈 인스턴스화
    uart_top u_uart_top (
        .clk      (clk),
        .rst_n    (rst_n),
        .rx       (rx),
        .tx       (tx),
        .dout(rx_data),
        .rx_done(rx_done),
        .tx_data  (tx_data),
        .start (tx_start),
        .tx_busy  (tx_busy)
    );

    // 3. UART to AXI Bridge 모듈 인스턴스화
    bridge_uart_to_axi u_bridge (
        .clk          (clk),
        .rst_n        (rst_n),
        // UART 인터페이스
        .rx_data      (rx_data),
        .rx_done      (rx_done),
        .tx_data      (tx_data),
        .tx_start     (tx_start),
        .tx_busy      (tx_busy),
        // AXI Master 인터페이스 -> Slave로 연결
        .m_axi_awaddr (s_axi_awaddr),
        .m_axi_awvalid(s_axi_awvalid),
        .m_axi_awready(s_axi_awready),
        .m_axi_wdata  (s_axi_wdata),
        .m_axi_wstrb  (s_axi_wstrb),
        .m_axi_wvalid (s_axi_wvalid),
        .m_axi_wready (s_axi_wready),
        .m_axi_bresp  (s_axi_bresp),
        .m_axi_bvalid (s_axi_bvalid),
        .m_axi_bready (s_axi_bready),
        .m_axi_araddr (s_axi_araddr),
        .m_axi_arvalid(s_axi_arvalid),
        .m_axi_arready(s_axi_arready),
        .m_axi_rdata  (s_axi_rdata),
        .m_axi_rresp  (s_axi_rresp),
        .m_axi_rvalid (s_axi_rvalid),
        .m_axi_rready (s_axi_rready)
    );

    // 4. AXI4-Lite Slave 모듈 인스턴스화
    axi_lite_slave u_axi_slave (
        .s_aclk          (clk),
        .s_arst_n        (rst_n),
        .s_awaddr (s_axi_awaddr),
        .s_awvalid(s_axi_awvalid),
        .s_awready(s_axi_awready),
        .s_wdata  (s_axi_wdata),
        .s_wstrb  (s_axi_wstrb),
        .s_wvalid (s_axi_wvalid),
        .s_wready (s_axi_wready),
        .s_bresp  (s_axi_bresp),
        .s_bvalid (s_axi_bvalid),
        .s_bready (s_axi_bready),
        .s_araddr (s_axi_araddr),
        .s_arvalid(s_axi_arvalid),
        .s_arready(s_axi_arready),
        .s_rdata  (s_axi_rdata),
        .s_rresp  (s_axi_rresp),
        .s_rvalid (s_axi_rvalid),
        .s_rready (s_axi_rready)
    );

endmodule
