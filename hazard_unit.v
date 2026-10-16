// Hazard Detection Unit
//  - Load-use: stall IF and ID for 1 cycle, insert a bubble into EX
//  - Taken branch / jump (decided in EX): flush the 2 wrong instructions
module hazard_unit (
    input  wire [4:0] d_rs1,       // source registers of instruction in ID
    input  wire [4:0] d_rs2,
    input  wire [4:0] e_rd,        // destination of instruction in EX
    input  wire       e_mem_read,  // instruction in EX is a load
    input  wire       pc_sel_e,    // branch taken / jump in EX
    output wire       stall_f,
    output wire       stall_d,
    output wire       flush_d,
    output wire       flush_e
);
    wire load_use = e_mem_read && (e_rd != 5'd0) &&
                    ((e_rd == d_rs1) || (e_rd == d_rs2));

    assign stall_f = load_use;
    assign stall_d = load_use;
    assign flush_d = pc_sel_e;
    assign flush_e = load_use | pc_sel_e;
endmodule