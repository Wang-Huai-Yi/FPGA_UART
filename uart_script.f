// -----------------------------------------------------------------------------
// Simulation: CVSD 2024 Spring Final Project
// -----------------------------------------------------------------------------

// Simulation Settings
// -----------------------------------------------------------------------------
+v2k
-sverilog
-debug_access+all
+notimingcheck
+fsdbon 

// Verilog Library Extensions
// -----------------------------------------------------------------------------
+libext+.v+.sv+.vlib

// Module Search Path
// -----------------------------------------------------------------------------
-y /usr/cad/synopsys/synthesis/cur/dw/sim_ver 
+incdir+/usr/cad/synopsys/synthesis/cur/dw/sim_ver/+

// Testbench File
// -----------------------------------------------------------------------------


// =============================================================================
//                  Your Can Only Modify The Below Part
// =============================================================================

// Your Design Files
// -----------------------------------------------------------------------------
./uart_sim.sv
./uart_dbg.sv
./FIFO_TOP.v
./ASYNC_FIFO_RAM.v
./FIFO_R_Pointer.v
./FIFO_Write_Pointer.v
./Sync_R2W.v
./Sync_W2R.v


// Define Flags
// -----------------------------------------------------------------------------
+define+VCS_SIM