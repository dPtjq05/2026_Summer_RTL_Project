`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/07/06 14:07:19
// Design Name: 
// Module Name: axi_lite_slave
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


module axi_lite_slave(
//글로벌 신호들
input s_aclk,
input s_arst_n,

//write address channel
input [31:0] s_awaddr,
input s_awvalid,
input [2:0] s_awprot,

//write data channel
input [31:0] s_wdata,
input s_wvalid,
input [3:0] s_wstrb,

//write response channel
input s_bready,

//read address channel
input s_arvalid,
input [2:0] s_arprot,
input [31:0] s_araddr,

//read data channel
input s_rready,

output reg s_awready,
output reg s_wready,

output reg s_bvalid,
output reg s_bresp,

output reg s_arrready,

output reg s_rvalid,
output reg s_rdata,
output reg s_rresp
    );
    
    reg [31:0] dummy0;
    reg [31:0] dummy1;
    reg [31:0] dummy2;
    reg [31:0] dummy3;
    
    reg [1:0] w_current_state;
    reg [1:0] w_next_state;
    
    reg [1:0] r_current_state;
    reg [1:0] r_next_state;
    
    reg [31:0] buf_wdata;   //내부에 저장해둘 buffer.
    reg [31:0] buf_awaddr;
    
    localparam WIDLE = 2'b00;
    localparam DWAIT = 2'b01;
    localparam AWAIT = 2'b10;
    localparam WRESP = 2'b11;
    
    localparam RIDLE = 1'b0;
    localparam READ = 1'b1;
    // read, write의 병렬 처리로 좀 더 효율적이라고는 하는데 이게 왜 효율적인 거지?--wire 선언을 추가해서 합성이나 연산이 더 빠르게 일어나도록 할 수 있음.

    always@ (posedge s_aclk or negedge s_arst_n) begin
        if (!s_arst_n) begin
            w_current_state <= WIDLE;
            r_current_state <= RIDLE;
            
        end
        else begin
            w_current_state <= w_next_state;
            r_current_state <= r_next_state;
            
            case (w_current_state)
                WIDLE: begin
                    if (s_wvalid && s_wready) begin
                        buf_wdata <= s_wdata;
                    end
                    
                    if (s_awvalid && s_awready) begin
                        buf_awaddr <= s_awaddr;
                    end
                end
                
                DWAIT: begin    //address는 확보함, data를 기다리는 상태.
                    if (s_wvalid && s_wready) begin
                        case (buf_awaddr[3:2])
                            2'b00: dummy0 <= s_wdata;
                            2'b01: dummy1 <= s_wdata;
                            2'b10: dummy2 <= s_wdata;
                            2'b11: dummy3 <= s_wdata;
                        endcase
                    end
                end
                
            endcase
        end
    end
    
    always@ (*) begin
        r_next_state = r_current_state;
        w_next_state = w_current_state;
        
        s_wready = 1'd0;
        s_awready = 1'd0;
        s_bvalid = 1'd0;
        s_bresp = 1'd0;
        
        case (w_current_state)
            WIDLE: begin
                s_wready = 1'b1;
                s_awready = 1'b1;
                if (s_wvalid && s_awvalid) begin
                    w_next_state = WRESP;   //대기 상태로 넘어갈 필요 없이 바로 RESP로 넘어간다.
                end
                else if (s_wvalid) begin    //data만 들어오고 주소 기다리는 경우
                    w_next_state = AWAIT;
                end
                else if (s_awvalid) begin   //주소 들어오고 data 기다리는 경우
                    w_next_state = DWAIT;
                end
                else begin
                    w_next_state = WIDLE;
                end
            end
            
            DWAIT: begin
                s_awready = 1'd0;
                if (s_wready && s_wvalid) begin
                    w_next_state = WRESP;
                end
            end
            
            AWAIT: begin
                s_wready = 1'd0;
            end
            
            WRESP: begin
                s_wready = 1'd0;
                s_awready = 1'd0;
            end
            
        endcase
    
    end
    
endmodule
