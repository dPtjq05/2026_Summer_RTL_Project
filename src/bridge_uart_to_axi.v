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
    reg aw_done;    //write channel에서 사용.
    reg w_done; //얘도 write에서 사용함.
    
    reg [2:0] current_state;
    reg [2:0] next_state;
    
    reg [7:0] cmd_reg;
    reg [31:0] data_reg;
    
    reg [1:0] cnt_addr;
    reg [31:0] addr_reg;
    
    reg [1:0] cnt_data; //RX_DATA에서 쓸거임.
    reg [1:0] cnt_resp; //resp에서 쓰는 cnt
    wire flag_resp;  //resp에서 pulse를 담당.
    reg busy_d; // busy 신호의 1클럭 delay.
    
    assign flag_resp = (busy_d && !tx_busy);
    
    always@ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= 3'd0;
            ar_done <= 1'd0;
            cmd_reg <= 8'd0;
            data_reg <= 32'd0;
            cnt_addr <= 2'd0;
            addr_reg <= 32'd0;
            cnt_resp <= 2'd0;
        end
        else begin
            current_state <= next_state;
            busy_d <= tx_busy;
            case (current_state)
                IDLE: begin
                    if ((rx_done ==1'd1)&&((rx_data==CMD_READ) || (rx_data==CMD_WRITE))) begin
                        cnt_addr <= 2'd0;
                        cmd_reg <= rx_data; //내부 reg에 read, write 신호라는 것을 저장.
                    end
                end
                RX_ADDR: begin  //state=1;
                    if (rx_done) begin
                        addr_reg <= {addr_reg[23:0], rx_data};
                        if (cnt_addr == 2'd3) begin
                            cnt_addr <= 2'd0;
                            ar_done <= 1'd0;
                            cnt_data <= 2'd0;
                            data_reg <= 32'd0;
                        end
                        else begin
                            cnt_addr <= cnt_addr + 2'd1;
                        end
                    end
                end
                
                RX_DATA:begin       //state = 2;
                    
                    if (rx_done) begin
                        data_reg <= {data_reg[23:0],rx_data};
                        if (cnt_data== 2'd3) begin
                            cnt_data <= 2'd0;
                            aw_done <= 1'd0;    //다음 state를 위해 미리 초기화.
                            w_done <= 1'd0;
                        end
                        else begin
                            
                            cnt_data <= cnt_data + 2'd1;
                        end
                    end
                end
                
                AXI_READ: begin     //state =4;
                    m_axi_araddr <= addr_reg;
                    
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
                                
                                cnt_resp <= 2'd0;
                            end
                            else begin
                                //비정상 응답
                            end
                        end
                    end
                end
                
                AXI_WRITE: begin    //state =3;
                    m_axi_awaddr <= addr_reg;
                    m_axi_wdata <= data_reg;
                    if (!aw_done) begin
                        if (m_axi_awvalid && m_axi_awready) begin
                            aw_done <= 1'd1;
                        end
                    end
                    
                    if (!w_done) begin
                        if (m_axi_wvalid && m_axi_wready) begin
                            w_done <= 1'd1;
                        end
                    end
                    
                    if (w_done && aw_done) begin
                        if (m_axi_bvalid && m_axi_bready) begin
                            aw_done <= 1'd0;
                            w_done <= 1'd0;
                            cnt_resp <= 2'd0;
                           
                            if (m_axi_bresp == 2'b00) begin
                                
                            end
                        end
                    end
                    
                    
                end
                
                TX_RESP: begin
                    
                    if (flag_resp) begin    
                        if (cnt_resp == 2'd3) begin
                            cnt_resp <= 2'd0;
                        end
                        else begin
                            cnt_resp <= cnt_resp + 2'd1;
                        end
                    end
                end
                
            endcase
        end
    end
    
    always@ (*) begin
        m_axi_awprot = 3'd0;
        m_axi_arprot = 3'd0;
        m_axi_wstrb = 4'b1111;
        next_state = current_state;
        m_axi_arvalid = 1'd0;
        m_axi_rready = 1'd0;
        tx_start = 1'd0;
        tx_data = 8'h00;
        case (current_state)
            IDLE: begin //state = 0;
                if ((rx_done ==1'd1)&& ((rx_data==CMD_READ)||(rx_data == CMD_WRITE))) begin
                    next_state = RX_ADDR;
                end
                else next_state = IDLE;
            end
            
            RX_ADDR: begin  //state =1;
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
            
            RX_DATA: begin
                if (rx_done) begin
                    if (cnt_data == 2'd3) begin
                        next_state = AXI_WRITE;
                    end
                end
            end
            
            AXI_READ: begin
                m_axi_arvalid = !ar_done;
                m_axi_rready = ar_done;
                if (!ar_done) begin //ar handshake 이전
                    if (m_axi_arvalid && m_axi_arready) begin
                        
                    end
                    else begin
                    end
                end
                else begin  //ar handshake 이후 r handshake 대기중
                    if (m_axi_rvalid  && m_axi_rready) begin
                        next_state = TX_RESP;
                    end
                    else begin
                        
                    end
                end
            end
            
            AXI_WRITE: begin    //state =3
                m_axi_awvalid = (!aw_done);
                m_axi_wvalid = (!w_done);
                m_axi_bready = (w_done && aw_done);
                
                if (aw_done&& w_done) begin
                    if (m_axi_bvalid && m_axi_bready) begin //여기서 bresp가 다음 클러겡 0으로 넘어가는 바람에 다음 state로 못 넘어가는 거 같은데.
                        if (m_axi_bresp == 2'b00) next_state = TX_RESP;
                    end
                end
            end
            
            TX_RESP: begin  //state 5;
                if (!tx_busy) tx_start = 1'd1;
                case (cnt_resp)
                    2'd0: tx_data = data_reg[31:24];
                    2'd1: tx_data = data_reg[23:16];
                    2'd2: tx_data = data_reg[15:8];
                    2'd3: tx_data = data_reg[7:0];
                endcase 
                
                if ((cnt_resp == 2'd3)&&(flag_resp)) next_state = IDLE;
                else begin
                    next_state = TX_RESP;
                end
                
            end
            
        endcase
            
    end
    
endmodule
