# ============================================
# run.do — QuestaSim simulation script
# Run this from QuestaSim transcript:
#   do run.do
# ============================================

# Step 1: Create work library (first time only)
vlib work

# Step 2: Compile all RTL files bottom-up
vlog ../rtl/alu.v
vlog ../rtl/register_file.v
vlog ../rtl/pc.v
vlog ../rtl/instr_mem.v
vlog ../rtl/data_mem.v
vlog ../rtl/hazard_unit.v
vlog ../rtl/forwarding_unit.v
vlog ../rtl/if_stage.v
vlog ../rtl/id_stage.v
vlog ../rtl/ex_stage.v
vlog ../rtl/mem_stage.v
vlog ../rtl/wb_stage.v
vlog ../rtl/riscv_top.v
vlog ../tb/riscv_tb.v

# Step 3: Load simulation
vsim -novopt work.riscv_tb

# Step 4: Add all signals to wave window
add wave -r /*

# Step 5: Run simulation
run -all

echo "============================================"
echo "Simulation complete — check transcript above"
echo "============================================"
