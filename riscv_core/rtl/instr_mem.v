// ============================================
// Instruction Memory — Read-only ROM
// 256 words × 32-bit = 1KB program space
// Loaded from instructions.mem file
// ============================================
module instr_mem (
    input  [31:0] addr,        // PC value comes in here
    output [31:0] instruction  // 32-bit instruction goes out
);

    reg [31:0] mem [0:255];    // 256 instruction slots

    // Load program from file at simulation start
    initial begin
        $readmemh("instructions.mem", mem);
    end

    // Read is combinational — address divided by 4 = word index
    assign instruction = mem[addr[9:2]];  // addr[9:2] = addr/4

endmodule
