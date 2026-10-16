`timescale 1ns/1ps
module tb_pipeline;
    reg clk = 0, rst = 1;
    always #5 clk = ~clk;
    integer errors = 0;
    integer cycle  = 0;

    riscv_pipeline #(.INIT_FILE("test2_nops.hex")) dut (.clk(clk), .rst(rst));

    // ---- Copies for the waveform ----
    wire [31:0] pc       = dut.pc;
    wire [31:0] IF_instr = dut.instr_f;
    wire [31:0] ID_instr = dut.d_instr;
    wire [31:0] EX_instr = dut.e_instr;
    wire [31:0] MEM_instr= dut.m_instr;
    wire [31:0] WB_instr = dut.w_instr;
    wire [31:0] x1  = dut.rf.regs[1];
    wire [31:0] x2  = dut.rf.regs[2];
    wire [31:0] x3  = dut.rf.regs[3];
    wire [31:0] x4  = dut.rf.regs[4];
    wire [31:0] x5  = dut.rf.regs[5];
    wire [31:0] x6  = dut.rf.regs[6];
    wire [31:0] x7  = dut.rf.regs[7];
    wire [31:0] x9  = dut.rf.regs[9];
    wire [31:0] x11 = dut.rf.regs[11];

    // ---- Pipeline trace: instruction in each stage, per cycle ----
    always @(posedge clk) begin
        if (!rst) begin
            cycle = cycle + 1;
            if (cycle <= 32)
                $display("cyc %2d  pc=%h | IF=%h  ID=%h  EX=%h  MEM=%h  WB=%h",
                         cycle, pc, IF_instr, ID_instr, EX_instr, MEM_instr, WB_instr);
        end
    end

    task check_reg(input [4:0] r, input [31:0] exp);
        begin
            if (dut.rf.regs[r] !== exp) begin
                $display("FAIL: x%0d = %h, expected %h", r, dut.rf.regs[r], exp);
                errors = errors + 1;
            end else
                $display("PASS: x%0d = %h", r, dut.rf.regs[r]);
        end
    endtask

    initial begin
        $dumpfile("pipeline.vcd");
        $dumpvars(0, tb_pipeline);

        #20 rst = 0;
        repeat (50) @(posedge clk);

        $display("\n----- Final register check -----");
        check_reg(1,  32'd5);
        check_reg(2,  32'd3);
        check_reg(3,  32'd8);           // add
        check_reg(4,  32'd2);           // sub
        check_reg(5,  32'h0000000A);    // or
        check_reg(6,  32'd8);           // lw
        check_reg(7,  32'd9);           // addi after load
        check_reg(8,  32'd0);           // skipped by beq
        check_reg(9,  32'h0000004C);    // jal return address
        check_reg(10, 32'd0);           // skipped by jal
        check_reg(11, 32'hABCDE000);    // lui

        if (dut.dm.mem[0] !== 32'd8) begin
            $display("FAIL: mem[0] = %h, expected 00000008", dut.dm.mem[0]);
            errors = errors + 1;
        end else
            $display("PASS: mem[0] = %h", dut.dm.mem[0]);

        if (errors == 0) $display("\nALL TESTS PASSED - PIPELINE STEP 1 WORKS!");
        else             $display("\n%0d TEST(S) FAILED", errors);
        $finish;
    end
endmodule