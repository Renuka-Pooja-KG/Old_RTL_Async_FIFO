package verification_pkg;

import uvm_pkg::*;
`include "uvm_macros.svh"

// Include all the files in the package
//`include "./../UVME/top/interface/wr_interface.sv"
//`include "./../UVME/top/interface/rd_interface.sv"

`include "./../UVME/sequence/write_sequence_item.sv"
`include "./../UVME/sequence/read_sequence_item.sv"

`include "./../UVME/write_agent/write_driver.sv"
`include "./../UVME/read_agent/read_driver.sv"

`include "./../UVME/write_agent/write_sequencer.sv"
`include "./../UVME/read_agent/read_sequencer.sv"

`include "./../UVME/write_agent/write_monitor.sv"
`include "./../UVME/read_agent/read_monitor.sv"

`include "./../UVME/write_agent/write_agent.sv"
`include "./../UVME/read_agent/read_agent.sv"

`include "./../UVME/env/scoreboard.sv"
`include "./../UVME/env/write_coverage.sv"
`include "./../UVME/env/read_coverage.sv"

`include "./../UVME/env/env.sv"

`include "./../UVME/sequence/write_base_sequence.sv"
`include "./../UVME/sequence/read_base_sequence.sv"

`include "./../UVME/test/base_test.sv"
`include "./../UVME/test/write_only_test.sv"
`include "./../UVME/test/read_only_test.sv"
`include "./../UVME/test/random_test.sv"
`include "./../UVME/test/reset_test.sv"
`include "./../UVME/test/simultaneous_test.sv"
`include "./../UVME/test/reset_write_read_test.sv"

// New test cases for comprehensive FIFO verification
`include "./../UVME/test/write_conditions_test.sv"
`include "./../UVME/test/read_conditions_test.sv"
`include "./../UVME/test/memory_access_test.sv"
`include "./../UVME/test/full_condition_test.sv"
`include "./../UVME/test/empty_condition_test.sv"
`include "./../UVME/test/almost_full_test.sv"
`include "./../UVME/test/almost_empty_test.sv"
`include "./../UVME/test/overflow_test.sv"
`include "./../UVME/test/underflow_test.sv"
`include "./../UVME/test/write_read_level_test.sv"
`include "./../UVME/test/faster_write_clock_test.sv"
`include "./../UVME/test/faster_read_clock_test.sv"

// Data integrity focused test cases
`include "./../UVME/test/strict_level_test.sv"
`include "./../UVME/test/data_integrity_focused_test.sv"


endpackage