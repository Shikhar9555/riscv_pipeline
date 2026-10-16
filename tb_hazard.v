`timescale 1ns/1ps
module tb_hazard;
    reg clk = 0, rst = 1;
    always #5 clk = ~clk;

    localparam NOP  = 32'h00000013;
    localparam HALT = 32'h0000006F;

    integer errors = 0, cycle = 0;
    integer cycles_t1 = 0, instrs_t1 = 0;
    reg     done_t1 = 0;

    // CPU 1: load-use test      CPU 2: original single-cycle program
    riscv_pipeline #(.INIT_FILE("test4_loaduse.hex")) dut_lu (.clk(clk), .rst(rst));
    riscv_pipeline #(.INIT_FILE("test1.hex"))         dut_t1 (.clk(clk), .rst(rst));

    // ---- Copies for the waveform ----
    wire        stall   = dut_lu.stall_f;
    wire        flush_d = dut_lu.flush_d;
    wire        flush_e = dut_lu.flush_e;
    wire [31:0] pc      = dut_lu.pc;

    // ---- Trace of the load-use CPU ----
    always @(posedge clk) begin
        if (!rst) begin
            cycle = cycle + 1;
            if (cycle <= 18)
                $display("cyc %2d  pc=%h | ID=%h  EX=%h  MEM=%h | stall=%b flushD=%b flushE=%b",
                         cycle, dut_lu.pc, dut_lu.d_instr, dut_lu.e_instr, dut_lu.m_instr,
                         dut_lu.stall_f, dut_lu.flush_d, dut_lu.flush_e);
        end
    end

    // ---- Performance counter for test1 (until halt reaches WB) ----
    always @(posedge clk) begin
        if (!rst && !done_t1) begin
            cycles_t1 = cycles_t1 + 1;
            if (dut_t1.w_instr != NOP)  instrs_t1 = instrs_t1 + 1;
            if (dut_t1.w_instr == HALT) done_t1   = 1;
        end
    end

    task check(input [31:0] got, input [31:0] exp, input [8*28-1:0] name);
        begin
            if (got !== exp) begin
                $display("FAIL: %0s = %h, expected %h", name, got, exp);
                errors = errors + 1;
            end else
                $display("PASS: %0s = %h", name, got);
        end
    endtask

    initial begin
        $dumpfile("hazard.vcd");
        $dumpvars(0, tb_hazard);

        #20 rst = 0;
        repeat (150) @(posedge clk);

        $display("\n----- Part 1: load-use + flush test -----");
        check(dut_lu.rf.regs[1], 32'd20, "x1");
        check(dut_lu.rf.regs[2], 32'd20, "x2 (lw)");
        check(dut_lu.rf.regs[3], 32'd40, "x3 (load-use add)");
        check(dut_lu.rf.regs[4], 32'd20, "x4 (lw)");
        check(dut_lu.rf.regs[5], 32'd20, "x5 (lw)");
        check(dut_lu.rf.regs[6], 32'd0,  "x6 (flushed)");
        check(dut_lu.rf.regs[7], 32'd7,  "x7");
        check(dut_lu.dm.mem[0],  32'd20, "mem[0]");
        check(dut_lu.dm.mem[1],  32'd20, "mem[1] (load-use sw)");

        $display("\n----- Part 2: test1.hex, NO NOPs (same as single-cycle) -----");
        check(dut_t1.rf.regs[1],  32'd55,         "x1 (loop sum)");
        check(dut_t1.rf.regs[2],  32'd11,         "x2");
        check(dut_t1.rf.regs[3],  32'd11,         "x3");
        check(dut_t1.rf.regs[4],  32'd55,         "x4 (lw)");
        check(dut_t1.rf.regs[5],  32'h12345678,   "x5 (lui+addi)");
        check(dut_t1.rf.regs[6],  32'h00000078,   "x6 (lb)");
        check(dut_t1.rf.regs[7],  32'hFFFFFFFF,   "x7");
        check(dut_t1.rf.regs[8],  32'd0,          "x8 (skipped)");
        check(dut_t1.rf.regs[9],  32'h00000040,   "x9 (jal ra)");
        check(dut_t1.rf.regs[10], 32'd1,          "x10");
        check(dut_t1.rf.regs[11], 32'h00000048,   "x11 (auipc)");
        check(dut_t1.dm.mem[0],   32'd55,         "mem[0] (sw)");
        check(dut_t1.dm.mem[1],   32'h00000078,   "mem[1] (sb)");

        $display("\n----- Performance (test1.hex) -----");
        $display("Instructions: %0d   Cycles: %0d   CPI = %0.2f",
                 instrs_t1, cycles_t1, cycles_t1 * 1.0 / instrs_t1);

        if (errors == 0) $display("\nALL TESTS PASSED - PIPELINED RISC-V CPU COMPLETE!");
        else             $display("\n%0d TEST(S) FAILED", errors);
        $finish;
    end
endmodule