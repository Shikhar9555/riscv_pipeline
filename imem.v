// Instruction Memory (read-only, loaded from a hex file)
module imem #(
    parameter DEPTH     = 1024,              // number of 32-bit words
    parameter INIT_FILE = "program.hex"
)(
    input  wire [31:0] addr,                 // byte address (PC)
    output wire [31:0] instr
);
    localparam AW = $clog2(DEPTH);
    reg [31:0] mem [0:DEPTH-1];
    integer i;

    initial begin
        for (i = 0; i < DEPTH; i = i + 1)
            mem[i] = 32'h00000013;           // fill with NOP (addi x0,x0,0)
        $readmemh(INIT_FILE, mem);
    end

    assign instr = mem[addr[AW+1:2]];        // word-aligned read
endmodule