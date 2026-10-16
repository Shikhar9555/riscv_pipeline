`timescale 1ns/1ps
module tb_imm_gen;
    reg  [31:0] instr;
    wire [31:0] imm;
    integer errors = 0;

    imm_gen dut (.instr(instr), .imm(imm));

    task check(input [31:0] ins, input [31:0] expected, input [8*24-1:0] name);
        begin
            instr = ins; #10;
            if (imm !== expected) begin
                $display("FAIL: %0s  instr=%h  got %h  expected %h", name, ins, imm, expected);
                errors = errors + 1;
            end else
                $display("PASS: %0s  imm=%h", name, imm);
        end
    endtask

    initial begin
        $dumpfile("imm_gen.vcd");
        $dumpvars(0, tb_imm_gen);

        // I-type
        check(32'h00500093, 32'h00000005, "addi x1,x0,5");
        check(32'hFFF00093, 32'hFFFFFFFF, "addi x1,x0,-1");
        check(32'h0080A103, 32'h00000008, "lw x2,8(x1)");
        check(32'h00008067, 32'h00000000, "jalr x0,0(x1)");
        // S-type
        check(32'h0020A623, 32'h0000000C, "sw x2,12(x1)");
        check(32'hFE20AE23, 32'hFFFFFFFC, "sw x2,-4(x1)");
        // B-type
        check(32'h00208863, 32'h00000010, "beq x1,x2,+16");
        check(32'hFE209CE3, 32'hFFFFFFF8, "bne x1,x2,-8");
        // U-type
        check(32'h123452B7, 32'h12345000, "lui x5,0x12345");
        check(32'hABCDE317, 32'hABCDE000, "auipc x6,0xABCDE");
        // J-type
        check(32'h001000EF, 32'h00000800, "jal x1,+2048");
        check(32'hFFDFF06F, 32'hFFFFFFFC, "jal x0,-4");
        // R-type (no immediate)
        check(32'h002081B3, 32'h00000000, "add x3,x1,x2");

        if (errors == 0) $display("\nALL TESTS PASSED");
        else             $display("\n%0d TEST(S) FAILED", errors);
        $finish;
    end
endmodule