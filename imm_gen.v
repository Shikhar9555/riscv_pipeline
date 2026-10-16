// RV32I Immediate Generator
module imm_gen (
    input  wire [31:0] instr,
    output reg  [31:0] imm
);
    wire [6:0] opcode = instr[6:0];

    localparam OP_IMM  = 7'b0010011,  // addi, slti, andi, slli ...
               OP_LOAD = 7'b0000011,  // lb, lh, lw, lbu, lhu
               OP_JALR = 7'b1100111,
               OP_STORE= 7'b0100011,  // sb, sh, sw
               OP_BR   = 7'b1100011,  // beq, bne, blt, bge, bltu, bgeu
               OP_LUI  = 7'b0110111,
               OP_AUIPC= 7'b0010111,
               OP_JAL  = 7'b1101111;

    always @(*) begin
        case (opcode)
            OP_IMM, OP_LOAD, OP_JALR:   // I-type
                imm = {{20{instr[31]}}, instr[31:20]};
            OP_STORE:                   // S-type
                imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            OP_BR:                      // B-type
                imm = {{19{instr[31]}}, instr[31], instr[7],
                       instr[30:25], instr[11:8], 1'b0};
            OP_LUI, OP_AUIPC:           // U-type
                imm = {instr[31:12], 12'b0};
            OP_JAL:                     // J-type
                imm = {{11{instr[31]}}, instr[31], instr[19:12],
                       instr[20], instr[30:21], 1'b0};
            default:                    // R-type has no immediate
                imm = 32'd0;
        endcase
    end
endmodule