`timescale 1ns/1ps
module tb_forward;
    reg clk = 0, rst = 1;
    always #5 clk = ~clk;
    integer errors = 0;
    integer cycle  = 0;

    riscv_pipeline #(.INIT_FILE("test3_fwd.hex")) dut (.clk(clk), .rst(rst));

    // ---- Copies for the waveform ----
    wire [31:0] pc        = dut.pc;
    wire [31:0] EX_instr  = dut.e_instr;
    wire [1:0]  forward_a = dut.forward_a;
    wire [1:0]  forward_b = dut.forward_b;
    wire [31:0] src_a     = dut.e_src_a;
    wire [31:0] src_b     = dut.e_src_b;

    // ---- Trace: instruction in EX and where its operands came from ----
    always @(posedge clk) begin
        if (!rst) begin
            cycle = cycle + 1;
            if (cycle <= 28)
                $display("cyc %2d  pc=%h | ID=%h  EX=%h  MEM=%h  WB=%h | fwdA=%b fwdB=%b  A=%h B=%h",
                         cycle, pc, dut.d_instr, dut.e_instr, dut.m_instr, dut.w_instr,
                         forward_a, forward_b, src_a, src_b);
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
        $dumpfile("forward.vcd");
        $dumpvars(0, tb_forward);

        #20 rst = 0;
        repeat (50) @(posedge clk);

        $display("\n----- Final register check -----");
        check_reg(0,  32'd0);
        check_reg(1,  32'd5);
        check_reg(2,  32'd8);
        check_reg(3,  32'd13);
        check_reg(4,  32'd16);
        check_reg(5,  32'd16);
        check_reg(6,  32'd17);
        check_reg(7,  32'd17);
        check_reg(8,  32'h00000030);
        check_reg(9,  32'd0);
        check_reg(10, 32'h00000034);
        check_reg(11, 32'h00000034);
        check_reg(12, 32'd0);
        check_reg(13, 32'd1);

        if (dut.dm.mem[0] !== 32'd16) begin
            $display("FAIL: mem[0] = %h, expected 00000010", dut.dm.mem[0]);
            errors = errors + 1;
        end else
            $display("PASS: mem[0] = %h", dut.dm.mem[0]);

        if (errors == 0) $display("\nALL TESTS PASSED - FORWARDING WORKS!");
        else             $display("\n%0d TEST(S) FAILED", errors);
        $finish;
    end
endmodule