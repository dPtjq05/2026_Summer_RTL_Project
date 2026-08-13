`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/06/26 13:33:12
// Design Name: 
// Module Name: uart_tx
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


module uart_tx(
    input clk,
    input rst_n,
    input start,
    input [7:0] tx_data,
    input sampling_tick,
    
    output reg tx,
    output reg tx_busy
    );//parellel signal -> serial signal change 송신의 역할
    reg [1:0] current_state;
    reg [1:0] next_state;
    
    reg [7:0] reg_data;
    reg [3:0] cnt_t;
    reg [2:0] cnt_d;
    
    localparam IDLE = 2'b00;
    localparam START = 2'b01;
    localparam DATA = 2'b10;
    localparam STOP = 2'b11;
    
    always@ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx <= 1'd1;
            tx_busy <= 1'd0;
        
            current_state <= IDLE;
            reg_data <= 8'd0;
            cnt_t <= 4'd0;
            cnt_d <= 3'd0;
        end
        else begin
            current_state <= next_state;
            
            case (current_state)
                IDLE: begin
                    if (start) begin
                        cnt_d <= 3'd0;
                        tx <= 1'd0;
                        tx_busy <= 1'd1;
                        reg_data <= tx_data;
                    end
                    else begin
                        tx <= 1'd1;
                        tx_busy <= 1'd0;
                    end
                end
                
                START: begin
                    tx <= 1'd0;
                    tx_busy <= 1'd1;
                    if (sampling_tick) begin
                        if (cnt_t == 4'd15) begin
                            cnt_t <= 4'd0;
                        end
                        else begin
                            cnt_t <= cnt_t + 4'd1;
                        end
                    end
                end
                
                DATA: begin
                    
                    if (sampling_tick) begin
                        if (cnt_t == 4'd15) begin
                            cnt_t <= 4'd0;
                            if (cnt_d == 3'd7) begin
                                cnt_d <= 3'd0;
                            end
                            else begin
                                cnt_d <= cnt_d + 3'd1;
                                
                            end
                            
                        end
                        else begin
                            cnt_t <= cnt_t + 4'd1;
                        end
                        
                        
                    end
                end
                
                STOP: begin
                    tx_busy <= 1'd1;
                    if (sampling_tick) begin
                        if (cnt_t == 4'd15) begin
                            cnt_t <= 4'd0;
                        end
                        else begin
                            cnt_t <= cnt_t + 4'd1;
                        end
                    end
                end
                
            endcase
        end
    end
    
    always@(*) begin
        next_state = current_state;
        //combinational logic에서 의도치 않은 latch 생성을 막기 위함.
        case (current_state)
            IDLE: begin
                tx = 1'd1;
                if (start) begin
                    next_state = START;
                end
                else begin
                    next_state = IDLE;
                end
            end
            
            START: begin
                tx = 1'd0;
                if(sampling_tick) begin
                    if (cnt_t == 4'd15) begin
                       next_state = DATA;
                    end    
                end  
            end
            
            DATA: begin
                //-- LATCH를 방지하기 위함.
                // 여기에 더 쓸 게 없나?
                tx = reg_data[cnt_d];
                if(sampling_tick) begin
                    if ((cnt_t == 4'd15)&&(cnt_d == 3'd7)) begin
                       next_state = STOP;
                    end    
                end                
            end
            
            STOP: begin
                tx = 1'd1;
                if (sampling_tick) begin
                    if (cnt_t == 4'd15) begin
                        next_state = IDLE;
                    end
                    else begin
                        next_state = STOP;
                    end
                end
            end
            
        endcase
    end
    
endmodule
