# RV32I 5-Stage Pipelined CPU (Verilog)

A RISC-V RV32I CPU in Verilog, first built as a single-cycle core and then extended into a classic
5-stage pipeline (IF / ID / EX / MEM / WB) with data forwarding and hazard detection.

## Modules

| File | Description |
|------|-------------|
| `riscv_pipeline.v` | Top-level 5-stage pipelined CPU (forwarding + hazard detection) |
| `riscv_single_cycle.v` | Single-cycle reference CPU |
| `alu.v`, `alu_control.v` | ALU and ALU control decoding |
| `control_unit.v` | Main instruction decoder |
| `imm_gen.v` | Immediate generator (I/S/B/U/J formats) |
| `reg_file.v` | 32 x 32-bit register file |
| `imem.v`, `dmem.v` | Instruction memory (`$readmemh`) and data memory |
| `branch_unit.v` | Branch condition evaluation |
| `forwarding_unit.v` | EX/MEM and MEM/WB forwarding |
| `hazard_unit.v` | Load-use stall and branch/jump flush control |

## Test programs

| File | Purpose |
|------|---------|
| `test1.hex` | Base program (single-cycle and pipeline without NOPs) |
| `test2_nops.hex` | Same program padded with NOPs (pipeline without hazard handling) |
| `test3_fwd.hex` | Data-forwarding test |
| `test4_loaduse.hex` | Load-use hazard (stall) test |

## Running (Icarus Verilog)

```sh
iverilog -o alu_sim  tb_alu.v alu.v && vvp alu_sim
iverilog -o cpu_sim  tb_single_cycle.v riscv_single_cycle.v *unit.v alu*.v imm_gen.v reg_file.v imem.v dmem.v && vvp cpu_sim
iverilog -o haz_sim  tb_hazard.v riscv_pipeline.v *unit.v alu*.v imm_gen.v reg_file.v imem.v dmem.v && vvp haz_sim
gtkwave hazard.vcd   # view waveforms
```

Each testbench writes a `.vcd` waveform file. Simulation binaries and waveforms are git-ignored.
