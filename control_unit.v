// RV32I Main Control Unit
module control_unit (
    input  wire [6:0] opcode,
    output reg        reg_write,
    output reg        mem_read,
    output reg        mem_write,
    output reg        alu_src,      // 0 = rs2, 1 = imm
    output reg  [1:0] alu_a_sel,    // 00 = rs1, 01 = PC, 10 = zero
    output reg  [1:0] result_src,   // 00 = ALU, 01 = MEM, 10 = PC+4
    output reg        branch,
    output reg        jump,         // jal
    output reg        jalr,
    output reg  [1:0] alu_op        // 00 ADD, 01 SUB, 10 R-type, 11 I-type
);
    localparam OP_R     = 7'b0110011,
               OP_IMM   = 7'b0010011,
               OP_LOAD  = 7'b0000011,
               OP_STORE = 7'b0100011,
               OP_BR    = 7'b1100011,
               OP_JAL   = 7'b1101111,
               OP_JALR  = 7'b1100111,
               OP_LUI   = 7'b0110111,
               OP_AUIPC = 7'b0010111;

    always @(*) begin
        // Defaults: behaves like a NOP (nothing written anywhere)
        reg_write  = 1'b0;
        mem_read   = 1'b0;
        mem_write  = 1'b0;
        alu_src    = 1'b0;
        alu_a_sel  = 2'b00;
        result_src = 2'b00;
        branch     = 1'b0;
        jump       = 1'b0;
        jalr       = 1'b0;
        alu_op     = 2'b00;

        case (opcode)
            OP_R: begin
                reg_write = 1'b1;
                alu_op    = 2'b10;
            end
            OP_IMM: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;
                alu_op    = 2'b11;
            end
            OP_LOAD: begin
                reg_write  = 1'b1;
                mem_read   = 1'b1;
                alu_src    = 1'b1;
                result_src = 2'b01;
            end
            OP_STORE: begin
                mem_write = 1'b1;
                alu_src   = 1'b1;
            end
            OP_BR: begin
                branch = 1'b1;
                alu_op = 2'b01;
            end
            OP_JAL: begin
                reg_write  = 1'b1;
                jump       = 1'b1;
                result_src = 2'b10;
            end
            OP_JALR: begin
                reg_write  = 1'b1;
                jalr       = 1'b1;
                alu_src    = 1'b1;
                result_src = 2'b10;
            end
            OP_LUI: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;
                alu_a_sel = 2'b10;
            end
            OP_AUIPC: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;
                alu_a_sel = 2'b01;
            end
            default: ; // FENCE, ECALL, EBREAK, unknown -> NOP
        endcase
    end
endmodule
