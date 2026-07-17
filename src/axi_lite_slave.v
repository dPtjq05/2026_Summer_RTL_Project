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
input [3:0] s_wstrb,        //이게 좀 복병인데,,, 데이터 중에 몇 비트를 선택해서 사용할 것인지 나타낸다. 데이터랑 같이 들어옴.

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

output reg s_arready,

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
    
    reg [3:0] buf_wstrb; //wstrb를 저장해둘 buffer 추가.
    
    localparam WIDLE = 2'b00;
    localparam DWAIT = 2'b01;
    localparam AWAIT = 2'b10;
    localparam WRESP = 2'b11;
    //이렇게 d,a wait을 나눈 이유는 이렇게 나눠야 로직을 더 단순하게 짤 수 있음. 그냥 하나의 wait으로 짜면 combinational logic의 case문을 짤 때 과도하게 복잡한 코드를 짜야함.
    
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
                        buf_wstrb <= s_wstrb;
                    end
                    
                    if (s_awvalid && s_awready) begin
                        buf_awaddr <= s_awaddr;
                    end
                end
                
                DWAIT: begin    //address는 확보함, data를 기다리는 상태.--주소를 미리 저장해두고 있음.
                    if (s_wvalid && s_wready) begin
                        case (buf_awaddr[3:2])
                            2'b00: begin
                                if (s_wstrb[0]) dummy0[7:0] <= s_wdata[7:0];
                                if (s_wstrb[1]) dummy0[15:8] <= s_wdata[15:8];
                                if (s_wstrb[2]) dummy0[23:16] <= s_wdata[23:16];
                                if (s_wstrb[3]) dummy0[31:24] <= s_wdata[31:24];
                            end
                            2'b01: begin
                                if (s_wstrb[0]) dummy1[7:0] <= s_wdata[7:0];
                                if (s_wstrb[1]) dummy1[15:8] <= s_wdata[15:8];
                                if (s_wstrb[2]) dummy1[23:16] <= s_wdata[23:16];
                                if (s_wstrb[3]) dummy1[31:24] <= s_wdata[31:24];
                            end
                            
                            2'b10: begin
                                if (s_wstrb[0]) dummy2[7:0] <= s_wdata[7:0];
                                if (s_wstrb[1]) dummy2[15:8] <= s_wdata[15:8];
                                if (s_wstrb[2]) dummy2[23:16] <= s_wdata[23:16];
                                if (s_wstrb[3]) dummy2[31:24] <= s_wdata[31:24];
                            end
                            2'b11:begin
                                if (s_wstrb[0]) dummy3[7:0] <= s_wdata[7:0];
                                if (s_wstrb[1]) dummy3[15:8] <= s_wdata[15:8];
                                if (s_wstrb[2]) dummy3[23:16] <= s_wdata[23:16];
                                if (s_wstrb[3]) dummy3[31:24] <= s_wdata[31:24];
                            end
                        endcase
                    end
                end
                
                AWAIT: begin        //주소를 기다린다. 그러니까 데이터는 버퍼에 있다. 주소가 들어오는 타이밍에 버퍼가 아닌 주소 wire에서 가져와야 한다.
                    if (s_awvalid && s_awready) begin
                        case (s_awaddr[3:2])
                            2'b00: begin
                                if (buf_wstrb[0]) dummy0[7:0] <= buf_wdata[7:0];
                                if (buf_wstrb[1]) dummy0[15:8] <= buf_wdata[15:8];
                                if (buf_wstrb[2]) dummy0[23:16] <= buf_wdata[23:16];
                                if (buf_wstrb[3]) dummy0[31:24] <= buf_wdata[31:24];
                            end
                            
                            2'b01: begin
                                if (buf_wstrb[0]) dummy1[7:0] <= buf_wdata[7:0];
                                if (buf_wstrb[1]) dummy1[15:8] <= buf_wdata[15:8];
                                if (buf_wstrb[2]) dummy1[23:16] <= buf_wdata[23:16];
                                if (buf_wstrb[3]) dummy1[31:24] <= buf_wdata[31:24];
                            end
                            
                            2'b10: begin
                                if (buf_wstrb[0]) dummy2[7:0] <= buf_wdata[7:0];
                                if (buf_wstrb[1]) dummy2[15:8] <= buf_wdata[15:8];
                                if (buf_wstrb[2]) dummy2[23:16] <= buf_wdata[23:16];
                                if (buf_wstrb[3]) dummy2[31:24] <= buf_wdata[31:24];
                            end
                            
                            2'b11: begin
                                if (buf_wstrb[0]) dummy3[7:0] <= buf_wdata[7:0];
                                if (buf_wstrb[1]) dummy3[15:8] <= buf_wdata[15:8];
                                if (buf_wstrb[2]) dummy3[23:16] <= buf_wdata[23:16];
                                if (buf_wstrb[3]) dummy3[31:24] <= buf_wdata[31:24];
                            end
                        endcase
                    end
                
                end
                WRESP: begin
                    
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
            
            DWAIT: begin        //주소 확보, 데이터 기다림--- 주소를 버퍼에 저장, 
                s_awready = 1'd0;
                if (s_wready && s_wvalid) begin
                    w_next_state = WRESP;
                    s_bvalid = 1'd1;
                    s_bresp =1'd1;
                end
            end
            
            AWAIT: begin
                s_wready = 1'd0;
                if (s_awready && s_awvalid) begin
                    w_next_state = WRESP;
                    s_bvalid = 1'd1;
                    s_bresp =1'd1;
                end
            end
            
            WRESP: begin
                s_wready = 1'd1;
                s_awready = 1'd1;
                s_bresp = 1'd1;
                s_bvalid = 1'd1;
                if (s_bready) begin //sequential logic으로 짜면 좀 더 안전한 타이밍 설계를 할 수 있지만 처음에 설계할 때 이 resp 상태를 고려하지 않은 구조로 짜서 그냥 combi로 짬.
                    w_next_state = WIDLE;
                    s_bvalid = 1'd0;
                    s_bresp = 1'd0;
                end
                else begin
                    w_next_state = WRESP;
                end
            end
            
        endcase
    
    end
    
endmodule
