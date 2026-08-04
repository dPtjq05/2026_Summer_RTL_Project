`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/08/03 11:35:00
// Design Name: 
// Module Name: bridge_uart_to_axi
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


module bridge_uart_to_axi(
    input clk,
    input rst_n,
    
    input tx_busy,
    input rx_done,
    input [7:0] rx_data,
    
    input m_axi_awready,
    input m_axi_wready,
    
    input [1:0] m_axi_bresp,
    input m_axi_bvalid,
    
    input m_axi_arready,
    
    input [31:0] m_axi_rdata,
    input [1:0] m_axi_rresp,
    input m_axi_rvalid,
    
    output reg tx_start,
    output reg [7:0] tx_data,
    
    output reg [31:0] m_axi_awaddr,
    output reg m_axi_awvalid,
    output reg [2:0] m_axi_awprot,
    
    output reg [31:0] m_axi_wdata,
    output reg m_axi_wvalid,
    output reg [3:0] m_axi_wstrb,
    
    output reg m_axi_bready,
    
    output reg m_axi_arvalid,
    output reg [2:0] m_axi_arprot,
    output reg [31:0] m_axi_araddr,
    
    output reg m_axi_rready
    );
    localparam CMD_WRITE = 8'h57;
    localparam CMD_READ = 8'h52;
    
    localparam IDLE = 3'b000;       //0
    localparam RX_ADDR = 3'b001;    //1
    localparam RX_DATA = 3'b010;    //2
    localparam AXI_WRITE = 3'b011;  //3
    localparam AXI_READ = 3'b100;   //4
    localparam TX_RESP = 3'b101;    //5
    
    reg ar_done; //AR channel의 handshake 여부를 확인하는 reg.
    reg [2:0] current_state;
    reg [2:0] next_state;
    
    reg [7:0] cmd_reg;
    reg [31:0] data_reg;
    
    reg [1:0] cnt_addr;
    reg [31:0] addr_reg;
    
    reg [1:0] cnt_resp; //resp에서 쓰는 cnt
    
    always@ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= 3'd0;
        end
        else begin
            current_state <= next_state;
            
            case (current_state)
                IDLE: begin
                    if ((rx_done ==1'd1)&&(rx_data==CMD_READ)) begin
                        cnt_addr <= 2'd0;
                        cmd_reg <= rx_data; //내부 reg에 write 신호라는 것을 저장.
                    end
                end
                RX_ADDR: begin
                    if (rx_done) begin
                        addr_reg <= {addr_reg[23:0], rx_data};
                        if (cnt_addr == 2'd3) begin
                            cnt_addr <= 2'd0;
                        end
                        else cnt_addr <= cnt_addr + 2'd1;
                    end
                    
                end
                AXI_READ: begin
                    m_axi_araddr <= addr_reg;
                    ar_done <= 1'd0;
                    if (!ar_done) begin
                        if (m_axi_arvalid && m_axi_arready) begin
                            ar_done <= 1'd1;
                        end
                    end
                    else begin
                        if (m_axi_rvalid && m_axi_rready) begin //R channel handshake
                        //이제 정상적으로 읽었는지 아닌지 판단해야함.
                            if (m_axi_rresp==2'b00) begin   //정상작동 응답
                                data_reg <= m_axi_rdata;
                                m_axi_rready <= 1'd0;
                            end
                            else begin
                                //비정상 응답
                            end
                        end
                    end
                end
                
                TX_RESP: begin
                    cnt_resp <= 2'd0;
                    case (cnt_resp)
                        2'd0: tx_data <= data_reg [31:24];
                        2'd1: tx_data <= data_reg [23:16];
                        2'd2: tx_data <= data_reg [15:8];
                        2'd3: tx_data <= data_reg [7:0];
                    endcase
                    if (cnt_resp == 2'd3) begin
                        cnt_resp <= 2'd0;
                    end
                end
            endcase
        end
    end
    
    always@ (*) begin
        case (current_state)
            IDLE: begin
                if ((rx_done ==1'd1)&& (rx_data==CMD_READ)) begin
                    next_state = RX_ADDR;
                end
                else next_state = IDLE;
            end
            
            RX_ADDR: begin
                if (rx_done) begin
                    if (cnt_addr == 2'd3) begin
                        if (cmd_reg == CMD_READ) begin
                            next_state = AXI_READ;
                        end
                        else if (cmd_reg == CMD_WRITE) begin
                            next_state = RX_DATA;
                        end
                    end
                end
            end
            AXI_READ: begin
                m_axi_arvalid = 1'd1;
                m_axi_rready = 1'd0;
                if (!ar_done) begin //ar handshake 이전
                    if (m_axi_arvalid && m_axi_arready) begin
                        m_axi_arvalid = 1'd0;
                        m_axi_rready = 1'd1;
                    end
                    else begin
                        m_axi_arvalid = 1'd1;
                        m_axi_rready = 1'd0;
                    end
                end
                else begin  //ar handshake 이후 r handshake 대기중
                    if (m_axi_rvalid  && m_axi_rready) begin
                        m_axi_rready = 1'd0;
                        m_axi_arvalid = 1'd1;
                        next_state = TX_RESP;
                    end
                end
            end
            TX_RESP: begin
                if (cnt_resp == 2'd3) next_state = IDLE;
            end
            
        endcase
            
    end
    
endmodule
