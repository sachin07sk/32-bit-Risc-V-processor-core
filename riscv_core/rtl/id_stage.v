// ============================================
// ID Stage — Instruction Decode
// + Control Signal Generation
// + ID/EX Pipeline Register
// ============================================
module id_stage (
    input         clk,
    input         reset,
    input         flush,         // Insert NOP bubble (load-use or branch)

    // From IF/ID register
    input  [31:0] if_id_pc,
    input  [31:0] if_id_instruction,

    // From register file
    input  [31:0] read_data1,    // Value of rs1
    input  [31:0] read_data2,    // Value of rs2

    // Register addresses (go to register file and hazard unit)
    output [4:0]  rs1,
    output [4:0]  rs2,

    // ID/EX pipeline register outputs
    output reg [31:0] id_ex_pc,
    output reg [31:0] id_ex_read_data1,
    output reg [31:0] id_ex_read_data2,
    output reg [31:0] id_ex_imm,         // Sign-extended immediate
    output reg [4:0]  id_ex_rs1,
    output reg [4:0]  id_ex_rs2,
    output reg [4:0]  id_ex_rd,
    output reg [3:0]  id_ex_alu_ctrl,    // ALU operation
    output reg        id_ex_alu_src,     // 0=register, 1=immediate
    output reg        id_ex_mem_read,    // 1=LW instruction
    output reg        id_ex_mem_write,   // 1=SW instruction
    output reg        id_ex_reg_write,   // 1=write result to register
    output reg        id_ex_mem_to_reg,  // 1=WB data from memory
    output reg        id_ex_branch       // 1=branch instruction
);

    // ── Extract instruction fields ──────────────────
    wire [6:0]  opcode = if_id_instruction[6:0];
    wire [4:0]  rd_w   = if_id_instruction[11:7];
    wire [2:0]  funct3 = if_id_instruction[14:12];
    wire [4:0]  rs1_w  = if_id_instruction[19:15];
    wire [4:0]  rs2_w  = if_id_instruction[24:20];
    wire [6:0]  funct7 = if_id_instruction[31:25];

    assign rs1 = rs1_w;
    assign rs2 = rs2_w;

    // ── Immediate Sign Extension ────────────────────
    wire [31:0] imm_i = {{20{if_id_instruction[31]}}, if_id_instruction[31:20]};
    wire [31:0] imm_s = {{20{if_id_instruction[31]}}, if_id_instruction[31:25], if_id_instruction[11:7]};
    wire [31:0] imm_b = {{19{if_id_instruction[31]}}, if_id_instruction[31], if_id_instruction[7], if_id_instruction[30:25], if_id_instruction[11:8], 1'b0};

    // ── Control Signal Decode ───────────────────────
    // Opcode values (RISC-V standard)
    localparam OP_R      = 7'b0110011;  // R-type: ADD, SUB, AND, OR...
    localparam OP_I_ALU  = 7'b0010011;  // I-type ALU: ADDI, ANDI...
    localparam OP_LOAD   = 7'b0000011;  // LW
    localparam OP_STORE  = 7'b0100011;  // SW
    localparam OP_BRANCH = 7'b1100011;  // BEQ, BNE

    reg        ctrl_alu_src;
    reg        ctrl_mem_read;
    reg        ctrl_mem_write;
    reg        ctrl_reg_write;
    reg        ctrl_mem_to_reg;
    reg        ctrl_branch;
    reg [3:0]  ctrl_alu_ctrl;
    reg [31:0] imm_sel;

    always @(*) begin
        // Default — safe NOP values
        ctrl_alu_src   = 0;
        ctrl_mem_read  = 0;
        ctrl_mem_write = 0;
        ctrl_reg_write = 0;
        ctrl_mem_to_reg= 0;
        ctrl_branch    = 0;
        ctrl_alu_ctrl  = 4'b0000; // ADD by default
        imm_sel        = imm_i;

        case (opcode)
            OP_R: begin
                ctrl_reg_write = 1;
                // Decode funct3 + funct7 to ALU operation
                case (funct3)
                    3'b000: ctrl_alu_ctrl = (funct7[5]) ? 4'b0001 : 4'b0000; // SUB : ADD
                    3'b111: ctrl_alu_ctrl = 4'b0010; // AND
                    3'b110: ctrl_alu_ctrl = 4'b0011; // OR
                    3'b100: ctrl_alu_ctrl = 4'b0100; // XOR
                    3'b001: ctrl_alu_ctrl = 4'b0101; // SLL
                    3'b101: ctrl_alu_ctrl = (funct7[5]) ? 4'b0111 : 4'b0110; // SRA : SRL
                    3'b010: ctrl_alu_ctrl = 4'b1000; // SLT
                    default: ctrl_alu_ctrl = 4'b0000;
                endcase
            end

            OP_I_ALU: begin
                ctrl_alu_src   = 1;   // Use immediate
                ctrl_reg_write = 1;
                imm_sel        = imm_i;
                case (funct3)
                    3'b000: ctrl_alu_ctrl = 4'b0000; // ADDI
                    3'b111: ctrl_alu_ctrl = 4'b0010; // ANDI
                    3'b110: ctrl_alu_ctrl = 4'b0011; // ORI
                    3'b100: ctrl_alu_ctrl = 4'b0100; // XORI
                    3'b010: ctrl_alu_ctrl = 4'b1000; // SLTI
                    default: ctrl_alu_ctrl = 4'b0000;
                endcase
            end

            OP_LOAD: begin
                ctrl_alu_src    = 1;  // base + offset
                ctrl_mem_read   = 1;
                ctrl_reg_write  = 1;
                ctrl_mem_to_reg = 1;
                imm_sel         = imm_i;
                ctrl_alu_ctrl   = 4'b0000; // ADD for address
            end

            OP_STORE: begin
                ctrl_alu_src   = 1;  // base + offset
                ctrl_mem_write = 1;
                imm_sel        = imm_s;
                ctrl_alu_ctrl  = 4'b0000; // ADD for address
            end

            OP_BRANCH: begin
                ctrl_branch   = 1;
                imm_sel       = imm_b;
                ctrl_alu_ctrl = 4'b0001; // SUB — compare rs1-rs2
            end
        endcase
    end

    // ── ID/EX Pipeline Register ─────────────────────
    always @(posedge clk) begin
        if (reset || flush) begin
            // Insert NOP — clear all control signals
            id_ex_pc          <= 32'd0;
            id_ex_read_data1  <= 32'd0;
            id_ex_read_data2  <= 32'd0;
            id_ex_imm         <= 32'd0;
            id_ex_rs1         <= 5'd0;
            id_ex_rs2         <= 5'd0;
            id_ex_rd          <= 5'd0;
            id_ex_alu_ctrl    <= 4'd0;
            id_ex_alu_src     <= 0;
            id_ex_mem_read    <= 0;
            id_ex_mem_write   <= 0;
            id_ex_reg_write   <= 0;
            id_ex_mem_to_reg  <= 0;
            id_ex_branch      <= 0;
        end
        else begin
            id_ex_pc          <= if_id_pc;
            id_ex_read_data1  <= read_data1;
            id_ex_read_data2  <= read_data2;
            id_ex_imm         <= imm_sel;
            id_ex_rs1         <= rs1_w;
            id_ex_rs2         <= rs2_w;
            id_ex_rd          <= rd_w;
            id_ex_alu_ctrl    <= ctrl_alu_ctrl;
            id_ex_alu_src     <= ctrl_alu_src;
            id_ex_mem_read    <= ctrl_mem_read;
            id_ex_mem_write   <= ctrl_mem_write;
            id_ex_reg_write   <= ctrl_reg_write;
            id_ex_mem_to_reg  <= ctrl_mem_to_reg;
            id_ex_branch      <= ctrl_branch;
        end
    end

endmodule
