`timescale 1ns/1ps
module tb_control;
    reg  [31:0] instr;
    wire reg_write, mem_read, mem_write, alu_src, branch, jump, jalr;
    wire [1:0] alu_a_sel, result_src, alu_op;
    wire [3:0] alu_ctrl;
    integer errors = 0;

    control_unit cu (
        .opcode(instr[6:0]),
        .reg_write(reg_write), .mem_read(mem_read), .mem_write(mem_write),
        .alu_src(alu_src), .alu_a_sel(alu_a_sel), .result_src(result_src),
        .branch(branch), .jump(jump), .jalr(jalr), .alu_op(alu_op)
    );

    alu_control ac (
        .alu_op(alu_op), .funct3(instr[14:12]), .funct7_5(instr[30]),
        .alu_ctrl(alu_ctrl)
    );

    // Packed: {reg_write, mem_read, mem_write, alu_src, branch, jump, jalr, alu_a_sel, result_src}
    wire [10:0] ctrl = {reg_write, mem_read, mem_write, alu_src,
                        branch, jump, jalr, alu_a_sel, result_src};

    task check(input [31:0] ins, input [10:0] exp_ctrl, input [3:0] exp_alu,
               input [8*20-1:0] name);
        begin
            instr = ins; #10;
            if (ctrl !== exp_ctrl || alu_ctrl !== exp_alu) begin
                $display("FAIL: %0s  ctrl=%b (exp %b)  alu=%b (exp %b)",
                         name, ctrl, exp_ctrl, alu_ctrl, exp_alu);
                errors = errors + 1;
            end else
                $display("PASS: %0s", name);
        end
    endtask

    initial begin
        $dumpfile("control.vcd");
        $dumpvars(0, tb_control);
        //                                 rw mr mw as br j jr a_sel res     alu
        check(32'h002081B3, 11'b1_0_0_0_0_0_0_00_00, 4'b0000, "add");
        check(32'h402081B3, 11'b1_0_0_0_0_0_0_00_00, 4'b0001, "sub");
        check(32'h0020F1B3, 11'b1_0_0_0_0_0_0_00_00, 4'b0010, "and");
        check(32'h4020D1B3, 11'b1_0_0_0_0_0_0_00_00, 4'b0111, "sra");
        check(32'h0020B1B3, 11'b1_0_0_0_0_0_0_00_00, 4'b1001, "sltu");
        check(32'h00500093, 11'b1_0_0_1_0_0_0_00_00, 4'b0000, "addi +5");
        check(32'hFFF00093, 11'b1_0_0_1_0_0_0_00_00, 4'b0000, "addi -1 (trap)");
        check(32'h00209093, 11'b1_0_0_1_0_0_0_00_00, 4'b0101, "slli");
        check(32'h4030D093, 11'b1_0_0_1_0_0_0_00_00, 4'b0111, "srai");
        check(32'h0080A103, 11'b1_1_0_1_0_0_0_00_01, 4'b0000, "lw");
        check(32'h0020A623, 11'b0_0_1_1_0_0_0_00_00, 4'b0000, "sw");
        check(32'h00208863, 11'b0_0_0_0_1_0_0_00_00, 4'b0001, "beq");
        check(32'h001000EF, 11'b1_0_0_0_0_1_0_00_10, 4'b0000, "jal");
        check(32'h00008067, 11'b1_0_0_1_0_0_1_00_10, 4'b0000, "jalr");
        check(32'h123452B7, 11'b1_0_0_1_0_0_0_10_00, 4'b0000, "lui");
        check(32'hABCDE317, 11'b1_0_0_1_0_0_0_01_00, 4'b0000, "auipc");
        check(32'h00000073, 11'b0_0_0_0_0_0_0_00_00, 4'b0000, "ecall -> NOP");

        if (errors == 0) $display("\nALL TESTS PASSED");
        else             $display("\n%0d TEST(S) FAILED", errors);
        $finish;
    end
endmodule