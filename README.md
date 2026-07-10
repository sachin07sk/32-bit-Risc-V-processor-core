# 32-bit RISC-V Processor Core (RV32)

**Author:** Saravana Kumar T J A
**Role:** Design & Verification Engineer — Semiconductor
**Tools:** Verilog | QuestaSim 10.4e
**Architecture:** 5-Stage In-Order Pipeline
**GitHub:** [32-bit-Risc-V-processor-core](https://github.com/sachin07sk/32-bit-Risc-V-processor-core)

---

## Overview

A fully functional **32-bit RISC-V RV32I pipelined processor core** designed in Verilog from scratch. Implements the base integer instruction set with a classic 5-stage pipeline, complete hazard handling, and data forwarding — verified using a self-checking testbench on QuestaSim.

---

## Processor Specification

| Parameter         | Value                              |
|-------------------|------------------------------------|
| ISA               | RISC-V RV32I (Base Integer)        |
| Pipeline stages   | 5 — IF, ID, EX, MEM, WB            |
| Registers         | 32 × 32-bit (x0 hardwired zero)    |
| Data width        | 32-bit                             |
| Instruction types | R, I, S, B                         |
| Hazard handling   | Forwarding + Stall + Flush         |
| Memory            | Harvard (separate instr + data)    |
| Reset             | Synchronous active HIGH            |
| Simulation tool   | QuestaSim 10.4e                    |

---

## Supported Instructions

| Type   | Instructions                                   |
|--------|------------------------------------------------|
| R-type | ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT     |
| I-type | ADDI, ANDI, ORI, XORI, SLTI, LW                |
| S-type | SW                                             |
| B-type | BEQ, BNE                                       |

---

## Pipeline Architecture

```
         ┌──────┐   ┌──────┐   ┌──────┐   ┌──────┐   ┌──────┐
Clock ──►│  IF  │──►│  ID  │──►│  EX  │──►│ MEM  │──►│  WB  │
         └──────┘   └──────┘   └──────┘   └──────┘   └──────┘
            │    IF/ID   │   ID/EX  │  EX/MEM │  MEM/WB  │
            │   ┌─────┐  │  ┌─────┐ │  ┌─────┐│  ┌─────┐ │
            └──►│ REG │──┘  │ REG │ └─►│ REG ││  │ REG │ └──►  OUTPUT
                └─────┘     └─────┘    └─────┘└─►└─────┘
                                           ▲
                                    ┌──────┴──────┐
                                    │ Hazard Unit │
                                    │  Fwd Unit   │
                                    └─────────────┘
```

### What Each Stage Does

| Stage | Full Name          | Function                                                |
|-------|--------------------|---------------------------------------------------------|
| IF    | Instruction Fetch  | Read instruction from ROM using PC                      |
| ID    | Instruction Decode | Decode opcode, read registers, generate control signals |
| EX    | Execute            | ALU computes result or memory address                   |
| MEM   | Memory Access      | Read/write data memory for LW/SW                        |
| WB    | Write Back         | Write result back to register file                      |

---

## Hazard Handling

### Data Hazard — Load-Use (Stall)

```
Cycle →     1    2    3    4    5    6    7
LW  x1      IF   ID   EX  MEM  WB
ADD x3,x1        IF   ID  ───  EX  MEM  WB
                          ↑
                    1-cycle bubble inserted
                    hazard_unit: pc_stall=1
                                 if_id_stall=1
                                 id_ex_flush=1
```

### Data Hazard — ALU-ALU (Forwarding)

```
Cycle →     1    2    3    4    5
ADD x1      IF   ID   EX  MEM  WB
SUB x4,x1        IF   ID   EX ──────── fwd=10 (EX/MEM bypass)
AND x6,x1             IF   ID   EX ─── fwd=01 (MEM/WB bypass)

No stalls needed — result forwarded directly to ALU input
```

### Control Hazard — Branch Taken (Flush)

```
Cycle →     1    2    3    4    5
BEQ         IF   ID   EX  MEM  WB
WRONG_1          IF   ID ←── flushed (if_id_flush=1)
WRONG_2               IF ←── flushed (id_ex_flush=1)
CORRECT                   IF  ID ...

2-cycle branch penalty when branch is taken
```

---

## Forwarding Unit

```
fwd value    Source              When used
─────────────────────────────────────────────────────
  2'b00      Register file       No hazard — normal
  2'b10      EX/MEM register     Prev instruction just finished EX
  2'b01      MEM/WB register     Two instructions ago finished EX

Priority: EX/MEM always wins over MEM/WB (most recent value)
```

---

## Module Hierarchy

```
riscv_top.v                  ← Top — wires all modules
├── pc.v                     ← Program counter (stall, branch)
├── instr_mem.v              ← Instruction ROM (256×32-bit)
├── if_stage.v               ← IF stage + IF/ID register
├── register_file.v          ← 32×32-bit (2 read, 1 write)
├── id_stage.v               ← Decode + ID/EX register
├── hazard_unit.v            ← Stall and flush control
├── ex_stage.v               ← Execute + EX/MEM register
│   └── alu.v                ← ALU (ADD/SUB/AND/OR/XOR/SLT)
├── forwarding_unit.v        ← Bypass path selector
├── mem_stage.v              ← Memory + MEM/WB register
├── data_mem.v               ← Data RAM (256×32-bit)
└── wb_stage.v               ← Write-back MUX
```

---

## File Structure

```
riscv_core/
├── rtl/
│   ├── alu.v                ALU — 10 operations
│   ├── register_file.v      32×32-bit register file
│   ├── pc.v                 Program counter with stall
│   ├── instr_mem.v          Instruction ROM ($readmemh)
│   ├── data_mem.v           Data RAM for LW/SW
│   ├── hazard_unit.v        Load-use + branch hazard detection
│   ├── forwarding_unit.v    EX/MEM and MEM/WB bypass paths
│   ├── if_stage.v           IF stage + IF/ID pipeline register
│   ├── id_stage.v           Decode + control + ID/EX register
│   ├── ex_stage.v           Execute + EX/MEM pipeline register
│   ├── mem_stage.v          Memory + MEM/WB pipeline register
│   ├── wb_stage.v           Write-back MUX
│   └── riscv_top.v          Top level — connects all modules
│
├── tb/
│   └── riscv_tb.v           Self-checking testbench
│
└── sim/
    └── instructions.mem     Test program in hex format
```

---

## Test Program

```
File: sim/instructions.mem

00A00093    ADDI x1, x0, 10     → x1 = 10
01400113    ADDI x2, x0, 20     → x2 = 20
002081B3    ADD  x3, x1, x2     → x3 = 30  (tests forwarding)
00302023    SW   x3, 0(x0)      → mem[0] = 30
00002203    LW   x4, 0(x0)      → x4 = 30  (tests load-use)
00100313    ADDI x6, x0, 1      → x6 = 1
00208463    BEQ  x1, x2, +8     → not taken (x1≠x2)
00000013    NOP
```

---

## Simulation Results

```
===========================================
 RISC-V RV32I Processor — Simulation Start
===========================================
[0] Reset released — processor running

Cycle | PC       | Instruction | x1  | x2  | x3  | x4   |
------|----------|-------------|-----|-----|-----|------|
    1 | 00000000 | 00000000    |   0 |   0 |   0 |   0  |
    2 | 00000000 | 00a00093    |   0 |   0 |   0 |   0  |
    3 | 00000004 | 01400113    |  10 |   0 |   0 |   0  |
    4 | 00000008 | 002081b3    |  10 |  20 |   0 |   0  |
    5 | 0000000c | 00302023    |  10 |  20 |  30 |   0  |
    6 | 00000010 | 00002203    |  10 |  20 |  30 |   0  |

--- Register Checks ---
PASS | ADDI_x1  | x1 = 10  (expected 10)  |
PASS | ADDI_x2  | x2 = 20  (expected 20)  |
PASS | ADD_x3   | x3 = 30  (expected 30)  |
PASS | LW_x4    | x4 = 30  (expected 30)  |
PASS | ADDI_x6  | x6 = 1   (expected 1)   |
PASS | x0_zero  | x0 = 0   (expected 0)   |

===========================================
 Results: 6 PASSED | 0 FAILED
 STATUS: ALL TESTS PASSED ✓
===========================================
```

---

## RTL Code Highlights

```

### Forwarding MUX

```verilog
always @(*) begin
    case (fwd_a)
        2'b10:   alu_operand_a = ex_mem_alu_result; // EX/MEM bypass
        2'b01:   alu_operand_a = wb_write_data;     // MEM/WB bypass
        default: alu_operand_a = id_ex_read_data1;  // register file
    endcase
end
```

### Load-Use Hazard Detection

```verilog
if (id_ex_mem_read &&
    id_ex_rd != 5'd0 &&
    (id_ex_rd == if_id_rs1 || id_ex_rd == if_id_rs2))
begin
    pc_stall    = 1;  // freeze PC
    if_id_stall = 1;  // freeze IF/ID register
    id_ex_flush = 1;  // insert NOP bubble
end
```
```
**### OUTPUT Waveform**
--------

**<img width="1875" height="590" alt="Screenshot 2026-06-22 075403" src="https://github.com/user-attachments/assets/434ca295-730d-4d98-a27b-79be8d88caee" />**
<img width="1875" height="590" alt="Screenshot 2026-06-22 075403" src="https://github.com/user-attachments/assets/bbf8f6e4-e327-45ec-8a18-781782a5fcac" />


---

*Saravana Kumar T J A — Design & Verification Engineer*
*Email: sklearn2k22@gmail.com*
*LinkedIn: linkedin.com/in/sk-212010-tja*
*GitHub: github.com/sachin07sk*
