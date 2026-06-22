// ============================================
// EX Stage — Execute
// + Forwarding MUXes
// + EX/MEM Pipeline Register
// ============================================
module ex_stage (
    input         clk,
    input         reset,

    // From ID/EX register
    input  [31:0] id_ex_pc,
    input  [31:0] id_ex_read_data1,
    input  [31:0] id_ex_read_data2,
    input  [31:0] id_ex_imm,
    input  [4:0]  id_ex_rs1,
    input  [4:0]  id_ex_rs2,
    input  [4:0]  id_ex_rd,
    input  [3:0]  id_ex_alu_ctrl,
    input         id_ex_alu_src,
    input         id_ex_mem_read,
    input         id_ex_mem_write,
    input         id_ex_reg_write,
    input         id_ex_mem_to_reg,
    input         id_ex_branch,

    // From forwarding unit
    input  [1:0]  fwd_a,           // Forward select for operand A
    input  [1:0]  fwd_b,           // Forward select for operand B

    // Forwarded values from later stages
    input  [31:0] ex_mem_alu_result,  // From EX/MEM register
    input  [31:0] wb_write_data,      // From WB stage

    // EX/MEM pipeline register outputs
    output reg [31:0] ex_mem_pc_branch,   // Branch target address
    output reg        ex_mem_branch,
    output reg        ex_mem_zero,         // ALU zero flag
    output reg [31:0] ex_mem_alu_result_r,
    output reg [31:0] ex_mem_write_data,
    output reg [4:0]  ex_mem_rd,
    output reg        ex_mem_mem_read,
    output reg        ex_mem_mem_write,
    output reg        ex_mem_reg_write,
    output reg        ex_mem_mem_to_reg,

    // For hazard unit
    output [4:0]  ex_rd_out
);

    assign ex_rd_out = id_ex_rd;

    // ── Forwarding MUXes ────────────────────────────
    // fwd_a/fwd_b: 00=register file, 10=EX/MEM bypass, 01=MEM/WB bypass
    reg [31:0] alu_operand_a;
    reg [31:0] alu_operand_b_reg; // before immediate mux

    always @(*) begin
        case (fwd_a)
            2'b00: alu_operand_a   = id_ex_read_data1;    // From register file
            2'b10: alu_operand_a   = ex_mem_alu_result;   // EX/MEM bypass
            2'b01: alu_operand_a   = wb_write_data;       // MEM/WB bypass
            default: alu_operand_a = id_ex_read_data1;
        endcase

        case (fwd_b)
            2'b00: alu_operand_b_reg = id_ex_read_data2;  // From register file
            2'b10: alu_operand_b_reg = ex_mem_alu_result; // EX/MEM bypass
            2'b01: alu_operand_b_reg = wb_write_data;     // MEM/WB bypass
            default: alu_operand_b_reg = id_ex_read_data2;
        endcase
    end

    // ── ALU Source MUX ──────────────────────────────
    // alu_src=0 → use register, alu_src=1 → use immediate
    wire [31:0] alu_operand_b = id_ex_alu_src ?
                                id_ex_imm :
                                alu_operand_b_reg;

    // ── ALU Instance ────────────────────────────────
    wire [31:0] alu_result;
    wire        alu_zero;

    alu u_alu (
        .a        (alu_operand_a),
        .b        (alu_operand_b),
        .alu_ctrl (id_ex_alu_ctrl),
        .result   (alu_result),
        .zero     (alu_zero)
    );

    // ── Branch Target: PC + (immediate × 1) ─────────
    wire [31:0] branch_target = id_ex_pc + id_ex_imm;

    // ── EX/MEM Pipeline Register ────────────────────
    always @(posedge clk) begin
        if (reset) begin
            ex_mem_pc_branch    <= 32'd0;
            ex_mem_branch       <= 0;
            ex_mem_zero         <= 0;
            ex_mem_alu_result_r <= 32'd0;
            ex_mem_write_data   <= 32'd0;
            ex_mem_rd           <= 5'd0;
            ex_mem_mem_read     <= 0;
            ex_mem_mem_write    <= 0;
            ex_mem_reg_write    <= 0;
            ex_mem_mem_to_reg   <= 0;
        end
        else begin
            ex_mem_pc_branch    <= branch_target;
            ex_mem_branch       <= id_ex_branch;
            ex_mem_zero         <= alu_zero;
            ex_mem_alu_result_r <= alu_result;
            ex_mem_write_data   <= alu_operand_b_reg; // rs2 value for SW
            ex_mem_rd           <= id_ex_rd;
            ex_mem_mem_read     <= id_ex_mem_read;
            ex_mem_mem_write    <= id_ex_mem_write;
            ex_mem_reg_write    <= id_ex_reg_write;
            ex_mem_mem_to_reg   <= id_ex_mem_to_reg;
        end
    end

endmodule
