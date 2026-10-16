// RV32I ALU Control
module alu_control (
    input  wire [1:0] alu_op,
    input  wire [2:0] funct3,
    input  wire       funct7_5,     // instr[30]
    output reg  [3:0] alu_ctrl
);
    localparam ALU_ADD  = 4'b0000, ALU_SUB  = 4'b0001,
               ALU_AND  = 4'b0010, ALU_OR   = 4'b0011,
               ALU_XOR  = 4'b0100, ALU_SLL  = 4'b0101,
               ALU_SRL  = 4'b0110, ALU_SRA  = 4'b0111,
               ALU_SLT  = 4'b1000, ALU_SLTU = 4'b1001;

    always @(*) begin
        case (alu_op)
            2'b00: alu_ctrl = ALU_ADD;   // load, store, jalr, lui, auipc
            2'b01: alu_ctrl = ALU_SUB;   // branch
            default: begin               // 10 = R-type, 11 = I-type
                case (funct3)
                    3'b000: alu_ctrl = (alu_op == 2'b10 && funct7_5) ? ALU_SUB : ALU_ADD;
                    3'b001: alu_ctrl = ALU_SLL;
                    3'b010: alu_ctrl = ALU_SLT;
                    3'b011: alu_ctrl = ALU_SLTU;
                    3'b100: alu_ctrl = ALU_XOR;
                    3'b101: alu_ctrl = funct7_5 ? ALU_SRA : ALU_SRL;
                    3'b110: alu_ctrl = ALU_OR;
                    3'b111: alu_ctrl = ALU_AND;
                endcase
            end
        endcase
    end
endmodule