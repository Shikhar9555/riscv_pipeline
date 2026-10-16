`timescale 1ns/1ps
module tb_mem;
    reg clk = 0;
    always #5 clk = ~clk;
    integer errors = 0;

    // Instruction memory
    reg  [31:0] iaddr = 0;
    wire [31:0] instr;
    imem #(.DEPTH(256), .INIT_FILE("program.hex")) im (.addr(iaddr), .instr(instr));

    // Data memory
    reg         we = 0;
    reg  [2:0]  f3 = 0;
    reg  [31:0] daddr = 0, wdata = 0;
    wire [31:0] rdata;
    dmem #(.DEPTH(256)) dm (.clk(clk), .mem_write(we), .funct3(f3),
                            .addr(daddr), .wdata(wdata), .rdata(rdata));

    task compare(input [31:0] got, input [31:0] exp, input [8*20-1:0] name);
        begin
            if (got !== exp) begin
                $display("FAIL: %0s  got %h  expected %h", name, got, exp);
                errors = errors + 1;
            end else
                $display("PASS: %0s = %h", name, got);
        end
    endtask

    task store(input [2:0] f, input [31:0] a, input [31:0] d);
        begin
            @(negedge clk); we = 1; f3 = f; daddr = a; wdata = d;
            @(negedge clk); we = 0;
        end
    endtask

    task load(input [2:0] f, input [31:0] a, input [31:0] exp, input [8*20-1:0] name);
        begin
            f3 = f; daddr = a; #1;
            compare(rdata, exp, name);
        end
    endtask

    initial begin
        $dumpfile("mem.vcd");
        $dumpvars(0, tb_mem);

        // ----- Instruction memory -----
        iaddr = 32'h0; #1; compare(instr, 32'h00500093, "imem[0x0]");
        iaddr = 32'h4; #1; compare(instr, 32'h00300113, "imem[0x4]");
        iaddr = 32'h8; #1; compare(instr, 32'h002081B3, "imem[0x8]");
        iaddr = 32'hC; #1; compare(instr, 32'h40208233, "imem[0xC]");
        iaddr = 32'h10; #1; compare(instr, 32'h00000013, "imem[0x10] NOP");

        // ----- Data memory -----
        store(3'b010, 32'h10, 32'h12345678);                 // sw
        load (3'b010, 32'h10, 32'h12345678, "lw  0x10");
        load (3'b000, 32'h10, 32'h00000078, "lb  0x10");
        load (3'b000, 32'h13, 32'h00000012, "lb  0x13");

        store(3'b000, 32'h11, 32'h00000080);                 // sb 0x80 -> byte 1
        load (3'b010, 32'h10, 32'h12348078, "lw after sb");
        load (3'b000, 32'h11, 32'hFFFFFF80, "lb  0x11 (neg)");
        load (3'b100, 32'h11, 32'h00000080, "lbu 0x11");

        store(3'b001, 32'h12, 32'h0000BEEF);                 // sh -> upper half
        load (3'b010, 32'h10, 32'hBEEF8078, "lw after sh");
        load (3'b001, 32'h12, 32'hFFFFBEEF, "lh  0x12 (neg)");
        load (3'b101, 32'h12, 32'h0000BEEF, "lhu 0x12");

        if (errors == 0) $display("\nALL TESTS PASSED");
        else             $display("\n%0d TEST(S) FAILED", errors);
        $finish;
    end
endmodule