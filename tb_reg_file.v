`timescale 1ns/1ps
module tb_reg_file;
    reg         clk = 0, rst = 1, we = 0;
    reg  [4:0]  rs1_addr = 0, rs2_addr = 0, rd_addr = 0;
    reg  [31:0] rd_data = 0;
    integer errors = 0;

    // Outputs of the two versions
    wire [31:0] rs1_bp, rs2_bp;   // BYPASS = 1
    wire [31:0] rs1_nb, rs2_nb;   // BYPASS = 0

    reg_file #(.BYPASS(1)) dut_bp (
        .clk(clk), .rst(rst), .we(we),
        .rs1_addr(rs1_addr), .rs2_addr(rs2_addr),
        .rd_addr(rd_addr), .rd_data(rd_data),
        .rs1_data(rs1_bp), .rs2_data(rs2_bp)
    );

    reg_file #(.BYPASS(0)) dut_nb (
        .clk(clk), .rst(rst), .we(we),
        .rs1_addr(rs1_addr), .rs2_addr(rs2_addr),
        .rd_addr(rd_addr), .rd_data(rd_data),
        .rs1_data(rs1_nb), .rs2_data(rs2_nb)
    );

    always #5 clk = ~clk;   // 100 MHz clock

    task write_reg(input [4:0] addr, input [31:0] data);
        begin
            @(negedge clk);
            we = 1; rd_addr = addr; rd_data = data;
            @(negedge clk);
            we = 0;
        end
    endtask

    task expect(input [31:0] got, input [31:0] exp, input [8*28-1:0] name);
        begin
            if (got !== exp) begin
                $display("FAIL: %0s  got %h  expected %h", name, got, exp);
                errors = errors + 1;
            end else
                $display("PASS: %0s = %h", name, got);
        end
    endtask

    initial begin
        $dumpfile("reg_file.vcd");
        $dumpvars(0, tb_reg_file);

        @(negedge clk); @(negedge clk); rst = 0;

        // 1. Normal write and read
        write_reg(5'd5, 32'hDEADBEEF);
        rs1_addr = 5'd5; #1;
        expect(rs1_bp, 32'hDEADBEEF, "x5 read (bypass on)");
        expect(rs1_nb, 32'hDEADBEEF, "x5 read (bypass off)");

        // 2. Writing x0 is ignored
        write_reg(5'd0, 32'h12345678);
        rs1_addr = 5'd0; #1;
        expect(rs1_bp, 32'd0, "x0 stays 0 (bypass on)");
        expect(rs1_nb, 32'd0, "x0 stays 0 (bypass off)");

        // 3. Both read ports at once
        write_reg(5'd10, 32'hAAAA5555);
        rs1_addr = 5'd5; rs2_addr = 5'd10; #1;
        expect(rs1_bp, 32'hDEADBEEF, "port1 x5");
        expect(rs2_bp, 32'hAAAA5555, "port2 x10");

        // 4. Read the register being written in the same cycle
        @(negedge clk);
        we = 1; rd_addr = 5'd7; rd_data = 32'hCAFEBABE; rs1_addr = 5'd7; #1;
        expect(rs1_bp, 32'hCAFEBABE, "same cycle, bypass on");   // new value
        expect(rs1_nb, 32'h00000000, "same cycle, bypass off");  // old value

        // ...after the clock edge, both show the new value
        @(posedge clk); #1;
        expect(rs1_bp, 32'hCAFEBABE, "after edge, bypass on");
        expect(rs1_nb, 32'hCAFEBABE, "after edge, bypass off");
        @(negedge clk); we = 0;

        if (errors == 0) $display("\nALL TESTS PASSED");
        else             $display("\n%0d TEST(S) FAILED", errors);
        $finish;
    end
endmodule