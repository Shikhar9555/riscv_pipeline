# RV32I ALU (Verilog)

The ALU and ALU control unit of a RISC-V RV32I CPU, written in Verilog.

## Files

| File | Description |
|------|-------------|
| `alu.v` | 32-bit combinational ALU with a `zero` flag |
| `alu_control.v` | Decodes `alu_op`, `funct3` and `funct7[5]` into a 4-bit `alu_ctrl` |

## `alu` operations

| `alu_ctrl` | Operation | Result |
|-----------|-----------|--------|
| `0000` | ADD  | `a + b` |
| `0001` | SUB  | `a - b` |
| `0010` | AND  | `a & b` |
| `0011` | OR   | `a \| b` |
| `0100` | XOR  | `a ^ b` |
| `0101` | SLL  | `a << b[4:0]` |
| `0110` | SRL  | `a >> b[4:0]` (logical) |
| `0111` | SRA  | `a >>> b[4:0]` (arithmetic) |
| `1000` | SLT  | `1` if `a < b` (signed), else `0` |
| `1001` | SLTU | `1` if `a < b` (unsigned), else `0` |

`zero` is high when `result == 0`; the CPU uses it for branch decisions.

## `alu_control` decoding

| `alu_op` | Used for | `alu_ctrl` |
|----------|----------|------------|
| `00` | load, store, JALR, LUI, AUIPC | ADD |
| `01` | branches | SUB |
| `10` | R-type | from `funct3`; `funct7[5]` selects SUB vs ADD and SRA vs SRL |
| `11` | I-type | from `funct3`; `funct7[5]` selects SRAI vs SRLI (ADDI never becomes SUB) |

## Building

```sh
iverilog -o alu_check alu.v alu_control.v
```
