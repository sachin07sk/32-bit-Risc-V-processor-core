// ============================================
// ALU — Arithmetic Logic Unit
// Supports: ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT
// ============================================
module alu (
    input  [31:0] a,           // Operand A
    input  [31:0] b,           // Operand B
    input  [3:0]  alu_ctrl,    // Operation select
    output reg [31:0] result,  // Output result
    output        zero         // 1 if result == 0 (used for branches)
);

    // ALU control codes — memorize these for interview
    localparam ALU_ADD  = 4'b0000;
    localparam ALU_SUB  = 4'b0001;
    localparam ALU_AND  = 4'b0010;
    localparam ALU_OR   = 4'b0011;
    localparam ALU_XOR  = 4'b0100;
    localparam ALU_SLL  = 4'b0101;  // Shift Left Logical
    localparam ALU_SRL  = 4'b0110;  // Shift Right Logical
    localparam ALU_SRA  = 4'b0111;  // Shift Right Arithmetic
    localparam ALU_SLT  = 4'b1000;  // Set Less Than (signed)
    localparam ALU_SLTU = 4'b1001;  // Set Less Than Unsigned

    always @(*) begin
        case (alu_ctrl)
            ALU_ADD  : result = a + b;
            ALU_SUB  : result = a - b;
            ALU_AND  : result = a & b;
            ALU_OR   : result = a | b;
            ALU_XOR  : result = a ^ b;
            ALU_SLL  : result = a << b[4:0];
            ALU_SRL  : result = a >> b[4:0];
            ALU_SRA  : result = $signed(a) >>> b[4:0];
            ALU_SLT  : result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            ALU_SLTU : result = (a < b) ? 32'd1 : 32'd0;
            default  : result = 32'd0;
        endcase
    end

    // Zero flag — used by BEQ: if A-B == 0, they are equal
    assign zero = (result == 32'd0);

endmodule
