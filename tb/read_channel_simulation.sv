`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/07/29 17:15:58
// Design Name: 
// Module Name: read_channel_simulation
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


module read_channel_simulation(
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
    reg [1:0] tb_rresp;
    
    wire awready;
    wire wready;
    wire bvalid;
    wire bresp;
    wire arready;
    wire rvalid;
    wire [31:0] rdata;
    wire [1:0] rresp;
    
    reg [31:0] tb_rdata;
    
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
        writecase(32'd4, 32'd8);    //data, address
        common_read(32'h8000_0000, tb_rdata, tb_rresp); //address, data, resp
        wait(3) @(posedge clk);
        assert (tb_rdata === 32'd4)
            $display("[PASS] Addr: 0x%08h | Data: 0x%08h (Matches!)", 32'd8, tb_rdata);
        else
            $error("[FAIL] Addr: 0x%08h | Expected: 0x%08h, Got: 0x%08h", 32'd8 , 32'd4, tb_rdata);
        $display("[%0t ns] task finished", $time);
        $finish;
    end
    
    task writecase(
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
            wstrb <= 4'b1111;
        
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
    
    task common_read(
        input [31:0] tb_raddr,
        output [31:0] tb_rdata,
        output [1:0] tb_rresp
    );
        begin
            reg rd_flag;
            
            rst_n <= 1'd0;
            @(posedge clk);
            rst_n <= 1'd1;
            wait(2) @(posedge clk);
            
            arvalid <= 1'd1;
            araddr <= tb_raddr;
            rready <= 1'd1;
            
            fork
                begin
                    wait(arready);
                    wait (3) @(posedge clk);
                    arvalid <= 1'd0;
                end
                
                begin
                    
                    wait(rvalid);
                    @(posedge clk);
                    wait(3) @(posedge clk);
                    tb_rdata = rdata;
                    tb_rresp = rresp;
                    rready <= 1'd0;
                    wait(3) @(posedge clk);
                end
            
            join
            
            wait(5) @(posedge clk);
        end
    endtask
    
endmodule
