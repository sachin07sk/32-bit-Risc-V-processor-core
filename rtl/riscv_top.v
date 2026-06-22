// ============================================
// RISC-V RV32I — Top Level Module (Fully Corrected)
// Connects all 12 submodules with explicit stage tracking
// ============================================
module riscv_top (
    input clk,
    input reset
);

// ── PC wires ──────────────────────────────────
wire [31:0] pc_current;
wire [31:0] branch_target;    
wire        branch_taken;
wire        pc_stall;

// ── Instruction memory wires ──────────────────
wire [31:0] instruction;

// ── IF/ID pipeline register wires ─────────────
wire [31:0] if_id_pc;
wire [31:0] if_id_instruction;

// ── Register file wires ───────────────────────
wire [4:0]  rs1, rs2;         
wire [31:0] read_data1;
wire [31:0] read_data2;       
wire [4:0]  wb_rd;
wire        wb_reg_write;     
wire [31:0] wb_write_data;

// ── ID/EX pipeline register wires ─────────────
wire [31:0] id_ex_pc;
wire [31:0] id_ex_read_data1;
wire [31:0] id_ex_read_data2;
wire [31:0] id_ex_imm;
wire [4:0]  id_ex_rs1;
wire [4:0]  id_ex_rs2;
wire [4:0]  id_ex_rd;
wire [3:0]  id_ex_alu_ctrl;
wire        id_ex_alu_src;
wire        id_ex_mem_read;
wire        id_ex_mem_write;
wire        id_ex_reg_write;
wire        id_ex_mem_to_reg;
wire        id_ex_branch;

// ── EX/MEM pipeline register wires (Stage 3) ──
wire [31:0] ex_mem_pc_branch;
wire        ex_mem_branch;
wire        ex_mem_zero;
wire [31:0] ex_mem_alu_result;   // Correct EX/MEM pipeline stage output
wire [31:0] ex_mem_write_data;
wire [4:0]  ex_mem_rd;
wire        ex_mem_mem_read;
wire        ex_mem_mem_write;
wire        ex_mem_reg_write;
wire        ex_mem_mem_to_reg;

// ── MEM/WB pipeline register wires (Stage 4) ──
wire [31:0] mem_wb_read_data;
wire [31:0] mem_wb_alu_result;   // Correct MEM/WB pipeline stage output
wire [4:0]  mem_wb_rd;
wire        mem_wb_reg_write;
wire        mem_wb_mem_to_reg;

// ── Data memory wires ─────────────────────────
wire        mem_we;
wire [31:0] mem_addr;
wire [31:0] mem_write_data;
wire [31:0] mem_read_data;

// ── Hazard unit wires ─────────────────────────
wire        if_id_stall;
wire        id_ex_flush;
wire        if_id_flush;

// ── Forwarding unit wires ─────────────────────
wire [1:0]  fwd_a;
wire [1:0]  fwd_b;

// ── PC select ────────────────────────────────
wire        pc_sel = branch_taken;

// ── 1. Program Counter ────────────────────────
pc u_pc (
    .clk        (clk),
    .reset      (reset),
    .stall      (pc_stall),
    .pc_sel     (pc_sel),
    .pc_target  (branch_target),
    .pc_out     (pc_current)
);

// ── 2. Instruction Memory ─────────────────────
instr_mem u_instr_mem (
    .addr        (pc_current),
    .instruction (instruction)
);

// ── 3. IF Stage + IF/ID Register ─────────────
if_stage u_if_stage (
    .clk             (clk),
    .reset           (reset),
    .stall           (if_id_stall),
    .flush           (if_id_flush),
    .pc_current      (pc_current),
    .instruction     (instruction),
    .if_id_pc        (if_id_pc),
    .if_id_instruction(if_id_instruction)
);

// ── 4. Register File ──────────────────────────
register_file u_reg_file (
    .clk        (clk),
    .we         (wb_reg_write),
    .rs1        (rs1),
    .rs2        (rs2),
    .rd         (wb_rd),
    .write_data (wb_write_data),
    .read_data1 (read_data1),
    .read_data2 (read_data2)
);

// ── 5. ID Stage + ID/EX Register ─────────────
id_stage u_id_stage (
    .clk              (clk),
    .reset            (reset),
    .flush            (id_ex_flush),
    .if_id_pc         (if_id_pc),
    .if_id_instruction(if_id_instruction),
    .read_data1       (read_data1),
    .read_data2       (read_data2),
    .rs1              (rs1),
    .rs2              (rs2),
    .id_ex_pc         (id_ex_pc),
    .id_ex_read_data1 (id_ex_read_data1),
    .id_ex_read_data2 (id_ex_read_data2),
    .id_ex_imm        (id_ex_imm),
    .id_ex_rs1        (id_ex_rs1),
    .id_ex_rs2        (id_ex_rs2),
    .id_ex_rd         (id_ex_rd),
    .id_ex_alu_ctrl   (id_ex_alu_ctrl),
    .id_ex_alu_src    (id_ex_alu_src),
    .id_ex_mem_read   (id_ex_mem_read),
    .id_ex_mem_write  (id_ex_mem_write),
    .id_ex_reg_write  (id_ex_reg_write),
    .id_ex_mem_to_reg (id_ex_mem_to_reg),
    .id_ex_branch     (id_ex_branch)
);

// ── 6. Hazard Detection Unit ──────────────────
hazard_unit u_hazard (
    .if_id_rs1      (rs1),
    .if_id_rs2      (rs2),
    .id_ex_mem_read (id_ex_mem_read),
    .id_ex_rd       (id_ex_rd),
    .branch_taken   (branch_taken),
    .pc_stall       (pc_stall),
    .if_id_stall    (if_id_stall),
    .id_ex_flush    (id_ex_flush),
    .if_id_flush    (if_id_flush)
);

// ── 7. EX Stage + EX/MEM Register ────────────
ex_stage u_ex_stage (
    .clk                (clk),
    .reset              (reset),
    .id_ex_pc           (id_ex_pc),
    .id_ex_read_data1   (id_ex_read_data1),
    .id_ex_read_data2   (id_ex_read_data2),
    .id_ex_imm          (id_ex_imm),
    .id_ex_rs1          (id_ex_rs1),
    .id_ex_rs2          (id_ex_rs2),
    .id_ex_rd           (id_ex_rd),
    .id_ex_alu_ctrl     (id_ex_alu_ctrl),
    .id_ex_alu_src      (id_ex_alu_src),
    .id_ex_mem_read     (id_ex_mem_read),
    .id_ex_mem_write    (id_ex_mem_write),
    .id_ex_reg_write    (id_ex_reg_write),
    .id_ex_mem_to_reg   (id_ex_mem_to_reg),
    .id_ex_branch       (id_ex_branch),
    .fwd_a              (fwd_a),
    .fwd_b              (fwd_b),
    .ex_mem_alu_result  (ex_mem_alu_result),   // EX/MEM forwarding input path
    .wb_write_data      (wb_write_data),       // MEM/WB writeback bypass path
    .ex_mem_pc_branch   (ex_mem_pc_branch),
    .ex_mem_branch      (ex_mem_branch),
    .ex_mem_zero        (ex_mem_zero),
    .ex_mem_alu_result_r(ex_mem_alu_result),   // Stage 3 Register output path
    .ex_mem_write_data  (ex_mem_write_data),
    .ex_mem_rd          (ex_mem_rd),
    .ex_mem_mem_read    (ex_mem_mem_read),
    .ex_mem_mem_write   (ex_mem_mem_write),
    .ex_mem_reg_write   (ex_mem_reg_write),
    .ex_mem_mem_to_reg  (ex_mem_mem_to_reg),
    .ex_rd_out          ()
);

// ── 8. Forwarding Unit ────────────────────────
forwarding_unit u_fwd (
    .id_ex_rs1        (id_ex_rs1),
    .id_ex_rs2        (id_ex_rs2),
    .ex_mem_reg_write (ex_mem_reg_write),
    .ex_mem_rd        (ex_mem_rd),
    .mem_wb_reg_write (mem_wb_reg_write),
    .mem_wb_rd        (mem_wb_rd),
    .fwd_a            (fwd_a),
    .fwd_b            (fwd_b)
);

// ── 9. MEM Stage + MEM/WB Register ───────────
mem_stage u_mem_stage (
    .clk               (clk),
    .reset             (reset),
    .ex_mem_pc_branch  (ex_mem_pc_branch),
    .ex_mem_branch     (ex_mem_branch),
    .ex_mem_zero       (ex_mem_zero),
    .ex_mem_alu_result (ex_mem_alu_result),
    .ex_mem_write_data (ex_mem_write_data),
    .ex_mem_rd         (ex_mem_rd),
    .ex_mem_mem_read   (ex_mem_mem_read),
    .ex_mem_mem_write  (ex_mem_mem_write),
    .ex_mem_reg_write  (ex_mem_reg_write),
    .ex_mem_mem_to_reg (ex_mem_mem_to_reg),
    .mem_read_data     (mem_read_data),
    .mem_we            (mem_we),
    .mem_addr          (mem_addr),
    .mem_write_data    (mem_write_data),
    .branch_taken      (branch_taken),
    .branch_target     (branch_target),
    .mem_wb_read_data  (mem_wb_read_data),
    .mem_wb_alu_result (mem_wb_alu_result),   // Stage 4 Register output path
    .mem_wb_rd         (mem_wb_rd),
    .mem_wb_reg_write  (mem_wb_reg_write),
    .mem_wb_mem_to_reg (mem_wb_mem_to_reg)
);

// ── 10. Data Memory ───────────────────────────
data_mem u_data_mem (
    .clk        (clk),
    .we         (mem_we),
    .addr       (mem_addr),
    .write_data (mem_write_data),
    .read_data  (mem_read_data)
);

// ── 11. WB Stage ──────────────────────────────
wb_stage u_wb_stage (
    .mem_wb_read_data  (mem_wb_read_data),
    .mem_wb_alu_result (mem_wb_alu_result),   // Linked to Stage 4 output
    .mem_wb_rd         (mem_wb_rd),
    .mem_wb_reg_write  (mem_wb_reg_write),
    .mem_wb_mem_to_reg (mem_wb_mem_to_reg),
    .wb_rd             (wb_rd),
    .wb_reg_write      (wb_reg_write),
    .wb_write_data     (wb_write_data)
);

endmodule
