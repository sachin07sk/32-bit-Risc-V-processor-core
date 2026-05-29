// ============================================
// Testbench — RISC-V RV32I Processor
// Self-checking: prints PASS or FAIL for each test
// Author: Saravana Kumar T J A
// ============================================
`timescale 1ns/1ps

module riscv_tb;

    // ── Clock and Reset ───────────────────────
    reg clk;
    reg reset;

    // Clock: 10ns period = 100MHz
    initial clk = 0;
    always #5 clk = ~clk;

    // ── DUT Instantiation ─────────────────────
    riscv_top dut (
        .clk   (clk),
        .reset (reset)
    );

    // ── Test Variables ────────────────────────
    integer pass_count = 0;
    integer fail_count = 0;

    // ── Task: Check Register Value ────────────
    // Peeks inside the register file and checks expected value
    task check_reg;
        input [4:0]  reg_num;
        input [31:0] expected;
        input [63:0] test_name; // 8-char ASCII label
        begin
            if (dut.u_reg_file.regs[reg_num] === expected) begin
                $display("PASS | %s | x%0d = %0d (expected %0d)",
                         test_name, reg_num,
                         dut.u_reg_file.regs[reg_num], expected);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL | %s | x%0d = %0d (expected %0d)",
                         test_name, reg_num,
                         dut.u_reg_file.regs[reg_num], expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // ── Main Test Sequence ────────────────────
    initial begin
        // Create waveform dump for QuestaSim
        $dumpfile("sim/riscv_wave.vcd");
        $dumpvars(0, riscv_tb);

        // ── Apply Reset ───────────────────────
        $display("===========================================");
        $display(" RISC-V RV32I Processor — Simulation Start");
        $display("===========================================");
        reset = 1;
        repeat(3) @(posedge clk);  // Hold reset for 3 cycles
        reset = 0;
        $display("[%0t] Reset released — processor running", $time);

        // ── Wait for program to execute ───────
        // 6 instructions × ~2 cycles each + pipeline drain = 30 cycles
        repeat(30) @(posedge clk);

        // ── Check Results ─────────────────────
        $display("");
        $display("--- Register Checks ---");
        check_reg(1,  32'd10, "ADDI_x1 ");  // x1 = 10
        check_reg(2,  32'd20, "ADDI_x2 ");  // x2 = 20
        check_reg(3,  32'd30, "ADD_x3  ");  // x3 = x1+x2 = 30
        check_reg(4,  32'd30, "LW_x4   ");  // x4 = mem[0] = 30
        check_reg(6,  32'd1,  "ADDI_x6 ");  // x6 = 1

        // x0 must always be 0 (hardwired)
        check_reg(0,  32'd0,  "x0_zero ");

        // ── Final Summary ─────────────────────
        $display("");
        $display("===========================================");
        $display(" Results: %0d PASSED | %0d FAILED",
                 pass_count, fail_count);
        if (fail_count == 0)
            $display(" STATUS: ALL TESTS PASSED ✓");
        else
            $display(" STATUS: SOME TESTS FAILED ✗");
        $display("===========================================");

        $finish;
    end

    // ── Timeout Watchdog ──────────────────────
    // Stops simulation if it runs too long (infinite loop guard)
    initial begin
        #10000;
        $display("TIMEOUT — simulation exceeded 10000ns");
        $finish;
    end

    // ── Cycle Monitor ─────────────────────────
    // Prints pipeline state every cycle for debugging
    initial begin
        $display("");
        $display("Cycle | PC       | Instruction | x1  | x2  | x3  | x4");
        $display("------|----------|-------------|-----|-----|-----|----");
    end

    always @(posedge clk) begin
        if (!reset) begin
            $display("%5d | %08h | %08h    | %3d | %3d | %3d | %3d",
                $time/10,
                dut.pc_current,
                dut.if_id_instruction,
                dut.u_reg_file.regs[1],
                dut.u_reg_file.regs[2],
                dut.u_reg_file.regs[3],
                dut.u_reg_file.regs[4]);
        end
    end

endmodule
