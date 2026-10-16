`timescale 1ns/1ps
module tb_single_cycle;
    reg clk = 0, rst = 1;
    always #5 clk = ~clk;
    integer errors = 0;

    riscv_single_cycle #(.INIT_FILE("test1.hex")) dut (.clk(clk), .rst(rst));

    // ---- Copies of CPU signals so they appear at the top of the waveform ----
    wire [31:0] pc     = dut.pc;
    wire [31:0] instr  = dut.instr;
    wire [31:0] result = dut.result;
    wire        taken  = dut.taken;

    // ---- Registers (arrays are not dumped by Icarus, so copy them) ----
    wire [31:0] x1  = dut.rf.regs[1];
    wire [31:0] x2  = dut.rf.regs[2];
    wire [31:0] x3  = dut.rf.regs[3];
    wire [31:0] x4  = dut.rf.regs[4];
    wire [31:0] x5  = dut.rf.regs[5];
    wire [31:0] x6  = dut.rf.regs[6];
    wire [31:0] x7  = dut.rf.regs[7];
    wire [31:0] x8  = dut.rf.regs[8];
    wire [31:0] x9  = dut.rf.regs[9];
    wire [31:0] x10 = dut.rf.regs[10];
    wire [31:0] x11 = dut.rf.regs[11];
    wire [31:0] mem0 = dut.dm.mem[0];
    wire [31:0] mem1 = dut.dm.mem[1];

    // ---- Instruction trace (stops printing once the CPU reaches the halt loop) ----
    always @(posedge clk)
        if (!rst && instr != 32'h0000006F)
            $display("t=%0t  pc=%h  instr=%h  result=%h  taken=%b",
                     $time, pc, instr, result, taken);

    task check_reg(input [4:0] r, input [31:0] exp);
        begin
            if (dut.rf.regs[r] !== exp) begin
                $display("FAIL: x%0d = %h, expected %h", r, dut.rf.regs[r], exp);
                errors = errors + 1;
            end else
                $display("PASS: x%0d = %h", r, dut.rf.regs[r]);
        end
    endtask

    task check_mem(input [9:0] w, input [31:0] exp);
        begin
            if (dut.dm.mem[w] !== exp) begin
                $display("FAIL: mem[word %0d] = %h, expected %h", w, dut.dm.mem[w], exp);
                errors = errors + 1;
            end else
                $display("PASS: mem[word %0d] = %h", w, dut.dm.mem[w]);
        end
    endtask

    initial begin
        $dumpfile("single_cycle.vcd");
        $dumpvars(0, tb_single_cycle);

        #20 rst = 0;
        repeat (100) @(posedge clk);

        $display("\n----- Final register check -----");
        check_reg(1,  32'd55);          // loop sum 1+2+...+10
        check_reg(2,  32'd11);
        check_reg(3,  32'd11);
        check_reg(4,  32'd55);          // lw
        check_reg(5,  32'h12345678);    // lui + addi
        check_reg(6,  32'h00000078);    // lb
        check_reg(7,  32'hFFFFFFFF);    // -1
        check_reg(8,  32'd0);           // skipped by blt
        check_reg(9,  32'h00000040);    // jal return address
        check_reg(10, 32'd1);           // after return
        check_reg(11, 32'h00000048);    // auipc
        check_mem(0,  32'd55);          // sw
        check_mem(1,  32'h00000078);    // sb

        if (errors == 0) $display("\nALL TESTS PASSED - CPU WORKS!");
        else             $display("\n%0d TEST(S) FAILED", errors);
        $finish;
    end
endmodule