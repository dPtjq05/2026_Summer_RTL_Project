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
    
    reg [2:0] current_state;
    reg [2:0] next_state;
    
    reg [7:0] cmd_reg;
    
    reg [1:0] cnt_addr;
    reg [31:0] shift_reg;
    
    
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
                        cmd_reg <= rx_data;
                    end
                end
                RX_ADDR: begin
                    if (rx_done) begin
                        if (cnt_addr == 2'd3) begin
                            cnt_addr <= 2'd0;
                        end
                        else begin    
                            shift_reg <= {shift_reg[23:0], rx_data};
                            cnt_addr <= cnt_addr+ 2'd1;
                        end
                    end
                    
                end
                AXI_READ: begin
                    m_axi_arvalid = 1'd1;
                    if (m_axi_arready && m_axi_arvalid) begin
                        
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
                if (cnt_addr == 2'd3) begin
                    if (cmd_reg == CMD_READ) begin
                        next_state = AXI_READ;
                    end
                    else if (cmd_reg == CMD_WRITE) begin
                        next_state = RX_DATA;
                    end
                end
                else next_state = RX_ADDR;
            end
            AXI_READ: begin
                
            end
            
        endcase
            
    end
    
endmodule
