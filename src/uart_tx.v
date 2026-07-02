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
    );
    reg [1:0] current_state;
    reg [1:0] next_state;
    
    reg [7:0] current_reg_data;
    reg [7:0] next_reg_data;
    
    reg [3:0] current_cnt_t;
    reg [3:0] next_cnt_t;
    
    reg [2:0] next_cnt_d;
    reg [2:0] current_cnt_d;
    
    localparam IDLE = 2'b00;
    localparam START = 2'b01;
    localparam DATA = 2'b10;
    localparam STOP = 2'b11;
    
    always@ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx <= 1'd1;
            tx_busy <= 1'd0;
            current_state <= IDLE;
            current_reg_data <= 8'd0;
            current_cnt_t <= 4'd0;
            current_cnt_d <= 3'd0;
        end
        else begin
            current_state <= next_state;
            current_cnt_t <= next_cnt_t;
            current_cnt_d <= next_cnt_d;
            current_reg_data <= next_reg_data;
        end
    end
    
    always@(*) begin
        next_state = current_state;
        next_cnt_d = current_cnt_d;
        next_cnt_t = current_cnt_t;
        next_reg_data = current_reg_data;
        
        tx = 1'd1;
        tx_busy = 1'd1;
        
        //combinational logic에서 의도치 않은 latch 생성을 막기 위함.
        
        case (current_state)
            IDLE: begin
                if (start) begin
                    next_reg_data = tx_data;
                    next_state = START;
                    next_cnt_d = 3'd0;
                end
                else begin
                    tx = 1'd1;
                    tx_busy = 1'd0;
                end
            end
            
            START: begin
                tx = 1'd0;
                tx_busy = 1'd0;
                if (sampling_tick) begin
                    if (current_cnt_t == 4'd15) begin
                        next_state = DATA;
                        next_cnt_t = 4'd0;
                        
                    end
                    else begin
                        next_cnt_t = current_cnt_t + 4'd1;
                    end
                end
            end
            
            DATA: begin
                
                tx = next_reg_data [current_cnt_d]; //-- LATCH를 방지하기 위함.
                // 여기에 더 쓸 게 없나?
                if(sampling_tick) begin
                    if (current_cnt_t == 4'd15) begin
                        next_cnt_t = 4'd0;
                        if (current_cnt_d == 3'd7) begin
                            next_cnt_d = 3'd0;
                            next_state = STOP;
                        end
                        else begin
                            next_cnt_d = current_cnt_d + 3'd1;
                        end
                    end
                    else begin
                        next_cnt_t = current_cnt_t + 4'd1;
                    end
                end
                else begin
                end
            end
            
            STOP: begin
            tx = 1'd1;
            if (sampling_tick) begin
                if (current_cnt_t == 4'd15) begin
                    next_state = IDLE;
                    next_cnt_t = 4'd0;
                end
                else begin
                    next_cnt_t = current_cnt_t + 4'd1;
                end
            end
            end
            
        endcase
    end
    
endmodule
