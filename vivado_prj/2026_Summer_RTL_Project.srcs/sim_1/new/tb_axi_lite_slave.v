`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/07/21 14:16:35
// Design Name: 
// Module Name: tb_axi_lite_slave
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


module tb_axi_lite_slave(
    );
    //global signal
    reg clk;
    reg rst_n;
    
    //write
    reg [31:0] awaddr;
    reg awvalid;
    reg [2:0] awprot;
    
    reg [31:0] wdata;
    reg wvalid;
    reg [3:0] wstrb;
    
    reg bready;
    
    //read
    reg arvalid;
    reg [2:0] arprot;
    reg [31:0] araddr;
    
    reg rready;
    
    wire awready;
    wire wready;
    wire bvalid;
    wire bresp;
    wire arready;
    wire rvalid;
    wire rdata;
    wire rresp;
    
    axi_lite_slave dut (
        .s_aclk(clk),
        .s_arst_n(rst_n),
        
        .s_awaddr(awaddr),
        .s_awvalid(awvalid),
        .s_awprot(awprot),
        
        .s_wdata(wdata),
        .s_wvalid(wvalid),
        .s_wstrb(wstrb),
        
        .s_bready(bready),
        
        .s_arvalid(arvalid),
        .s_arprot(arprot),
        .s_araddr(araddr),
        
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
    always #5 clk =~clk;
    
    initial begin
        clk <= 1'd0;
        rst_n <= 1'd0;
        #20
        bready <= 1'd0;
        rst_n <= 1'd1;
        
        $display("[%0t ns] task started", $time);
        data_first(32'd4, 32'd8);
        //commoncase (32'd4, 32'd8);
        $display("[%0t ns] task finished", $time);
        $finish;
    end
    
    
    
    task commoncase(
        input [31:0] tb_wdata,
        input [31:0] tb_awaddr
        );
        reg timeout_flag;
        begin
            timeout_flag = 0;
     
            @(posedge clk);
            awaddr  <= tb_awaddr;
            wdata   <= tb_wdata;
            awvalid <= 1'd1;
            wvalid  <= 1'd1;
            bready <= 1'd0;
            wstrb <= 4'b1110;
        
            fork
                begin
                    
                    fork
                        begin
                            wait(awready);
                            @(posedge clk);
                            awvalid <= 1'd0;
                        end
                        begin
                            wait(wready);
                            @(posedge clk);
                            wvalid <= 1'd0;
                        end
                    join
        
                    wait(bvalid);
                    $display("[CHECK] %t | bvalid captured! Current value = %b", $time, bvalid);
                    bready <= 1'd1;
                    @(posedge clk);
                    bready <= 1'd0;
                    repeat(3) @(posedge clk);
                end
                begin
                    repeat(100) @(posedge clk);
                    timeout_flag = 1; // 100 클럭이 지날 때까지 스레드 A가 안 끝나면 타임아웃
                end
            join_any
        
            disable fork;
        
            if (timeout_flag) begin
                $display("[ERROR] %t | AXI Write Timeout! Deadlock Detected at Addr: 0x%h", $time, tb_awaddr);
            
                awvalid <= 1'd0;
                wvalid  <= 1'd0;
                bready  <= 1'd0;
               
            end 
            else begin
                $display("[PASS] %t | AXI Write Success: Addr 0x%h = Data 0x%h", $time, tb_awaddr, tb_wdata);
            end
        end
    endtask

    
    task data_first(
        input [31:0] tb_wdata,
        input [31:0] tb_awaddr
    );
        reg df_flag;
        begin
            df_flag = 0;
            wstrb <= 4'b1110;
            
            //아 시발 진짜 3클럭 지연 뒤에 wready를 기다리느라 그런 거 같은데, 아 나 에미 시발 ㅈ같은 거진
            fork//fix: common case와는 달리 3clk지연 뒤에 ready를 기다리니까 무한 대기에 걸린 거 같음
                begin
                    fork
                        begin
                            repeat(3) @(posedge clk);
                            awvalid <= 1'd1;
                            awaddr <= tb_awaddr;
                            
                            wait(awvalid && awready);
                            @(posedge clk);
                            awvalid <= 1'd0;
                        end
                        begin
                            @(posedge clk);
                            wdata <= tb_wdata;
                            wvalid <= 1'd1;
                            
                            wait(wready && wvalid);
                            @(posedge clk);
                            wvalid <= 1'd0;
                        end
                    join
        
                    wait(bvalid==1'd1);
                    @(posedge clk);
                    bready <= 1'd1;
                        
                    wait(bvalid && bready);
                    @(posedge clk);
                    bready <= 1'd0;
                    
                    repeat(3) @(posedge clk);
                end
                begin
                    repeat(100) @(posedge clk);
                    df_flag = 1; // 100 클럭이 지날 때까지 스레드 A가 안 끝나면 타임아웃
                end
            join_any
        
            disable fork;
        
            if (df_flag) begin
                $display("[ERROR] %t | AXI Write Timeout! Deadlock Detected at Addr: 0x%h", $time, tb_awaddr);
            
                awvalid <= 1'd0;
                wvalid  <= 1'd0;
                bready  <= 1'd0;
               
            end 
            else begin
                $display("[PASS] %t | AXI Write Success: Addr 0x%h = Data 0x%h", $time, tb_awaddr, tb_wdata);
            end
        end
    endtask
    
    task address_first(
        input [31:0] tb_wdata,
        input [31:0] tb_awaddr
    );
        reg af_flag;
        begin
        
            af_flag <= 1'd0;
            @(posedge clk); //clk 동기화.
            awaddr <= tb_awaddr;
            repeat (3) @(posedge clk);
            wdata <= tb_wdata;
            
            fork
            
                begin   //여기에는 원래 동작들
                    fork
                        begin
                            wait(awready);
                            @(posedge clk);
                            awvalid <= 1'd0;
                        end
                        begin
                            wait(wready);
                            @(posedge clk);
                            wvalid <= 1'd0;
                        end
                        
                        
                        wait(bvalid);
                        @(posedge clk);
                        bready <= 1'd1;
                        
                        wait(bvalid && bready);
                        @(posedge clk);
                        bready <= 1'd0;
                    join
                end
                begin
                    repeat(100) @(posedge clk);
                    af_flag <= 1'd1;
                end
                
            join_any
            
            disable fork;
            
            if (af_flag) begin
                $display("[ERROR] %t | AXI Write Timeout! Deadlock Detected at Addr: 0x%h", $time, tb_awaddr);
            
                awvalid <= 1'd0;
                wvalid  <= 1'd0;
                bready  <= 1'd0;
               
            end 
            else begin
                $display("[PASS] %t | AXI Write Success: Addr 0x%h = Data 0x%h", $time, tb_awaddr, tb_wdata);
            end

        end
    endtask
    
endmodule
