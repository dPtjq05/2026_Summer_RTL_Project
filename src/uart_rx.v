`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/06/23 11:11:58
// Design Name: 
// Module Name: uart_rx
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


module uart_rx(
    input clk,
    input rst_n,
    input rx,
    input sampling_tick,
    output reg rx_done,
    output reg [7:0] dout
    );
    // 설계목표: rx에서 start bit를 감지해서 그 이후로 8bit의 데이터를 parallel data로 변환
    // -start 감지
    // -data 저장
    // -done 신호 켜기
    
    
    localparam IDLE = 2'b00;
    localparam START = 2'b01;
    localparam DATA = 2'b10;
    localparam STOP = 2'b11;
    // 위 state는 현업 표준을 따랐음.
    
    reg [1:0] current_state;
    reg [1:0] next_state;
    
    //ready, start, running, end? -----아니 그럴거면 start를 굳이 해야하나?
    reg [3:0] current_cnt_t;  //tick이 튄 횟수를 셀 카운터-16까지 수를 세야함 -> need 4bit
    reg [3:0] next_cnt_t;
    reg [2:0] current_cnt_d;  //data를 셀 카운터-8bit data의 수를 세야함-> need 3bit
    reg [2:0] next_cnt_d;
    
    // 전송된 값을 저장해둘 변수들
    reg [7:0] current_data;
    reg [7:0] next_data;
    
    always@ (posedge clk) begin
        if (!rst_n) begin
            rx_done <= 1'd0;
            dout<= 8'd0;
            current_cnt_t <= 4'd0;
            current_cnt_d <= 3'd0;
            current_state <= IDLE;
            dout <= 7'd0;
        end
        else begin
            current_state <= next_state;
            current_cnt_d <= next_cnt_d;
            current_cnt_t <= next_cnt_t;
            current_data <= next_data;
            dout <= current_data;
        end
    
    end
    
    
    always@(*) begin
        next_state = current_state;
        next_cnt_t = current_cnt_t;
        next_cnt_d = current_cnt_d;
        next_data = current_data;
    
        case (current_state)
            IDLE: begin //1이 계속 유지된다면 대기 상태, 0으로 떨어지는 순간이 start bit가 맞는지 판단 시작
                if (rx) begin 
                    next_state = IDLE;
                end
                else begin
                    next_state = START;
                end
            end
                
            START: begin //tick의 수를 세면서 진짜 시작인지 판단
                if (sampling_tick) begin
                    if (current_cnt_t == 4'd7) begin
                        if(!rx) begin
                            next_cnt_t = 4'd0;
                            next_state = DATA;
                        end
                        else begin
                            next_cnt_t = 4'd0;
                            next_state = IDLE;
                        end
                    end
                    else begin
                        next_cnt_t = current_cnt_t + 4'd1;
                        next_state = START;
                    end
                end
            end
            
//                if (current_cnt_t == 4'd7) begin //시작 비트의 중간에 도착했을 때
//                    if (!rx) begin              //시작 비트가 유효하다면 데이터를 받는 상태로 넘어간다
//                        next_cnt_t = 4'd0;
//                        next_state = DATA;
//                    end
//                    else begin      //시작 비트가 유효하지 않다면 다시 대기 상태로 돌아간다
//                        next_cnt_t = current_cnt_t;
//                        next_state = IDLE;
//                    end
//                end
//                else begin
//                   if (sampling_tick) begin
//                       next_cnt_t = current_cnt_t+4'd1;
//                   end
//                   else next_cnt_t = next_cnt_t;
//                   next_state = START;
//                end
            DATA: begin // start state에서 판단이 섰으면 바로 데이터 읽으러 간다
                if (sampling_tick) begin        //tick이 튄 경우
                   if (current_cnt_t == 4'd15) begin    //tick이 15번 튀어서 신호의 중간에 간 경우
                       next_data = {rx, current_data[7:1]}; //data 집어넣고 
                       next_cnt_t = 0;
                       if (current_cnt_d == 3'd7) begin     // 신호중간이라서 data 받으려고 하는데 다 찬 경우
                           next_state = STOP;
                           next_cnt_d = 3'd0;
                       end
                       else begin
                           next_cnt_d = current_cnt_d + 3'd1;   //data의 숫자를 하나 더함
                           next_state = DATA;
                       end
                   end
                   else begin       //tick이 튀긴 했는데 아직 15번이 안 찼을 경우 - 이때는 기존 값들을 그냥 보존
                       next_cnt_t = current_cnt_t + 4'd1;
                   end 
                   
                end
                else begin
                    next_state = DATA;
                
                end
            end
                
            STOP: begin     //15개의 tick을 세고 15가 되었을 때 stop이 맞는지 확인
            // +) 스탑 비트가 정상일 때 최종 출력 선에 데이터 할당
                if (sampling_tick) begin
                    rx_done = 1'd0;
                    if (current_cnt_t == 4'd15) begin
                        next_cnt_t = 4'd0;
                        if (rx == 1'd1) begin
                            rx_done = 1'd1;
                            next_state = IDLE;
                        end
                        
                    end
                    else begin
                        next_cnt_t = current_cnt_t + 4'd1;  //cnt_T가 아직 가득차지 않았으면 그냥 1을 더한다.
                    end
                
                end
                next_state = STOP;
            end
            
            default: next_state = IDLE;
                
         endcase
        
    end
    
    
endmodule
