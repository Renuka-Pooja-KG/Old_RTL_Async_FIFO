class read_base_sequence extends uvm_sequence #(read_sequence_item);
  `uvm_object_utils(read_base_sequence)

  // Configuration parameters
  int num_transactions = 10;
  int scenario = 0; // 0: random, 1: reset, 2: write_only, 3: read_only, 4: simultaneous, 5: reset-write-read
                    // 6: read_conditions, 7: empty_condition, 8: almost_empty, 9: underflow
                    // 10: write_conditions_support, 11: memory_access_support, 12: full_condition_support, 13: almost_full_support, 14: overflow_support

  function new(string name = "read_base_sequence");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(get_type_name(), $sformatf("Starting read_base_sequence with %0d transactions, scenario=%0d", num_transactions, scenario), UVM_LOW)
    case (scenario)
      0: random_scenario();
      1: reset_scenario();
      2: write_only_scenario();
      3: read_only_scenario();
      4: simultaneous_scenario();
      5: reset_write_read_scenario();
      6: read_conditions_scenario();
      7: empty_condition_scenario();
      8: almost_empty_scenario();
      9: underflow_scenario();
      10: write_conditions_support_scenario();
      11: memory_access_support_scenario();
      12: full_condition_support_scenario();
      13: almost_full_support_scenario();
      14: overflow_support_scenario();
      default: random_scenario();
    endcase
    `uvm_info(get_type_name(), "read_base_sequence completed", UVM_LOW)
  endtask

  // Random scenario
  task random_scenario();
    read_sequence_item req;
       
    // Reset phase - ensure clean FIFO state
    repeat (7) begin
      req = read_sequence_item::type_id::create("req");
      start_item(req);
      req.read_enable = 0; // Keep read disabled during reset
      req.aempty_value = 4;
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Reset Phase: %s", req.sprint), UVM_HIGH)
    end
    
    repeat (num_transactions) begin
      req = read_sequence_item::type_id::create("req");
      if (!req.randomize()) begin
        `uvm_fatal(get_type_name(), "Failed to randomize transaction")
      end
      start_item(req);
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Random: %s", req.sprint), UVM_HIGH)
    end
  endtask

  // Reset scenario
  task reset_scenario();
    read_sequence_item req;
    // Hardware reset for 3 cycles
    repeat (20) begin
      req = read_sequence_item::type_id::create("req");
      start_item(req);
        // hw_rst == 0; // Assert hardware reset
        // sw_rst == 0; // Ensure software reset is low
      req.read_enable = 0;
      req.aempty_value = 2;
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Hardware Reset: %s", req.sprint), UVM_HIGH)
    end
  endtask

  // Write-only scenario: read_enable is always low
  task write_only_scenario();
    read_sequence_item req;
       
    // Reset phase - ensure clean FIFO state
    repeat (4) begin
      req = read_sequence_item::type_id::create("req");
      start_item(req);
      req.read_enable = 0; // Keep read disabled during reset
      req.aempty_value = 4;
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Reset Phase: %s", req.sprint), UVM_HIGH)
    end
    
    repeat (num_transactions) begin
      req = read_sequence_item::type_id::create("req");
      start_item(req);
      req.read_enable = 0; // Ensure read_enable is low
      // req.sw_rst      = 0; // Ensure software reset is low
      // req.hw_rst    = 1; // Ensure hardware reset is de-asserted
      req.aempty_value = 4;
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Write-only: %s", req.sprint), UVM_HIGH)
    end
  endtask

  // Read-only scenario: read_enable is always high
  task read_only_scenario();
    read_sequence_item req;
       
    // Reset phase - ensure clean FIFO state
    repeat (14) begin
      req = read_sequence_item::type_id::create("req");
      start_item(req);
      req.read_enable = 0; // Keep read disabled during reset
      req.aempty_value = 4;
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Reset Phase: %s", req.sprint), UVM_HIGH)
    end
    
    repeat (num_transactions) begin
      req = read_sequence_item::type_id::create("req");
      start_item(req);
      req.read_enable = 1;
      // req.sw_rst      = 0; // Ensure software reset is low
      // req.hw_rst    = 1; // Ensure hardware reset is de-asserted
      req.aempty_value = 4;
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Read-only: %s", req.sprint), UVM_HIGH)
    end
  endtask

  // Simultaneous scenario: read_enable is always high (for read side)
  task simultaneous_scenario();
    read_sequence_item req;
       
    // Reset phase - ensure clean FIFO state
    repeat (7) begin
      req = read_sequence_item::type_id::create("req");
      start_item(req);
      req.read_enable = 0; // Keep read disabled during reset
      req.aempty_value = 4;
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Reset Phase: %s", req.sprint), UVM_HIGH)
    end
    
    repeat (num_transactions) begin
      req = read_sequence_item::type_id::create("req");
      start_item(req);
      req.read_enable = 1; // Ensure read_enable is high
      req.aempty_value = 4; // Set aempty_value to a valid state
      // Simulate simultaneous reset conditions
      // req.hw_rst    = 1; // Ensure hardware reset is de-asserted
      // req.sw_rst      = 0; // Ensure software reset is de-asserted
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Simultaneous: %s", req.sprint), UVM_HIGH)
    end
  endtask

  // Reset-write-read-wite-read scenario
  task reset_write_read_scenario();
    read_sequence_item req;
    // Hardware reset for 3 cycles
    repeat (3) begin
      req = read_sequence_item::type_id::create("req");
      start_item(req);
      // hw_rst == 0; // Assert hardware reset
      // sw_rst == 0; // Ensure software reset is low
      req.read_enable = 0;
      req.aempty_value = 2;
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Hardware Reset: %s", req.sprint), UVM_HIGH)
    end
    // De-assert hardware reset
    req = read_sequence_item::type_id::create("req");
    start_item(req);
    // hw_rst == 1; // De-assert hardware reset
    // sw_rst == 0; // Ensure software reset is low
    req.read_enable = 0;
    req.aempty_value = 2;
    finish_item(req);
    `uvm_info(get_type_name(), $sformatf("De-assert Hardware Reset: %s", req.sprint), UVM_HIGH)
    // Write operation for 10 cycles
    repeat (10) begin
      req = read_sequence_item::type_id::create("req");
      start_item(req);
      req.read_enable = 0; // Ensure read_enable is low
      req.aempty_value = 2; // Set aempty_value to a valid state
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Write Operation: %s", req.sprint), UVM_HIGH)
    end
    // Read operation for 5 cycles
    repeat (5) begin
        req = read_sequence_item::type_id::create("req");
      start_item(req);
      req.read_enable = 1; // Ensure read_enable is high
      req.aempty_value = 4; // Set aempty_value to a valid state
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Read Operation: %s", req.sprint), UVM_HIGH)
    end
    // Write operation for 10 cycles
    repeat (10) begin
      req = read_sequence_item::type_id::create("req");
      start_item(req);
      req.read_enable = 0; // Ensure read_enable is low
      req.aempty_value = 2; // Set aempty_value to a valid state
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Write Operation: %s", req.sprint), UVM_HIGH)
    end
    // Read operation for 5 cycles
    repeat (5) begin
      req = read_sequence_item::type_id::create("req");
      start_item(req);
      req.read_enable = 1; // Ensure read_enable is high
      req.aempty_value = 4; // Set aempty_value to a valid state
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Read Operation: %s", req.sprint), UVM_HIGH)
    end
  endtask

  // Test Case 2: Check the conditions to read the data from fifo when read enable =1
  task read_conditions_scenario();
    read_sequence_item req;
    
    // Reset phase - ensure clean FIFO state
    repeat (10) begin
      req = read_sequence_item::type_id::create("req");
      start_item(req);
      req.read_enable = 0; // Keep read disabled during reset
      req.aempty_value = 4;
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Reset Phase: %s", req.sprint), UVM_HIGH)
    end
    
    // Read with read_enable = 1
    repeat (num_transactions) begin
      req = read_sequence_item::type_id::create("req");
      start_item(req);
      req.read_enable = 1; // Enable read
      req.aempty_value = 4;
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Read Conditions: %s", req.sprint), UVM_HIGH)
    end
  endtask

  // Test Case 5: Check the empty condition without writing the data
  task empty_condition_scenario();
    read_sequence_item req;
    
    // Reset phase - ensure clean FIFO state
    repeat (36) begin
      req = read_sequence_item::type_id::create("req");
      start_item(req);
      req.read_enable = 0; // Keep read disabled during reset
      req.aempty_value = 4;
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Reset Phase: %s", req.sprint), UVM_HIGH)
    end
    
    // 30 reads and one more read for underflow
    repeat (31) begin
      req = read_sequence_item::type_id::create("req");
      start_item(req);
      req.read_enable = 1; // Keep reading even when empty
      req.aempty_value = 4;
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Empty Condition: %s", req.sprint), UVM_HIGH)
    end
  endtask

  // Test Case 7: Check the almost empty condition based on almost_empty_value
  task almost_empty_scenario();
    read_sequence_item req;
    
    // Reset phase - ensure clean FIFO state
    repeat (10) begin
      req = read_sequence_item::type_id::create("req");
      start_item(req);
      req.read_enable = 0; // Keep read disabled during reset
      req.aempty_value = 4;
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Reset Phase: %s", req.sprint), UVM_HIGH)
    end
    
    // Read until almost empty condition is reached
    repeat (8) begin // Read enough to trigger almost empty
      req = read_sequence_item::type_id::create("req");
      start_item(req);
      req.read_enable = 1;
      req.aempty_value = 4; // Set almost empty threshold
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Almost Empty: %s", req.sprint), UVM_HIGH)
    end

      // Read until almost empty condition is reached
    repeat (2) begin // Read enough to trigger almost empty
      req = read_sequence_item::type_id::create("req");
      start_item(req);
      req.read_enable = 0;
      req.aempty_value = 4; // Set almost empty threshold
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Almost Empty: %s", req.sprint), UVM_HIGH)
    end
  endtask

  // Test Case 9: Check underflow condition when read enable and read empty signals are asserted
  task underflow_scenario();
    read_sequence_item req;
    
    // Reset phase - ensure clean FIFO state
    repeat (7) begin
      req = read_sequence_item::type_id::create("req");
      start_item(req);
      req.read_enable = 0; // Keep read disabled during reset
      req.aempty_value = 4;
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Reset Phase: %s", req.sprint), UVM_HIGH)
    end
     // Read disabled when writing
    repeat (5) begin
      req = read_sequence_item::type_id::create("req");
      start_item(req);
      req.read_enable = 0; // Keep read disabled during reset
      req.aempty_value = 4;
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Reset Phase: %s", req.sprint), UVM_HIGH)
    end
    // Try to read from empty FIFO to trigger underflow
    repeat (6) begin
      req = read_sequence_item::type_id::create("req");
      start_item(req);
      req.read_enable = 1; // Keep reading even when empty
      req.aempty_value = 4;
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Underflow: %s", req.sprint), UVM_HIGH)
    end
     // Read disabled 
    repeat (2) begin
      req = read_sequence_item::type_id::create("req");
      start_item(req);
      req.read_enable = 0; // Keep read disabled during reset
      req.aempty_value = 4;
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Reset Phase: %s", req.sprint), UVM_HIGH)
    end
  endtask

  // Support scenario for Test Case 1: Write conditions - read domain provides minimal activity
  task write_conditions_support_scenario();
    read_sequence_item req;
    
    // Reset phase - ensure clean FIFO state
    repeat (4) begin
      req = read_sequence_item::type_id::create("req");
      start_item(req);
      req.read_enable = 0; // Keep read disabled during reset
      req.aempty_value = 4;
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Reset Phase: %s", req.sprint), UVM_HIGH)
    end
    
    // Keep read disabled to let write domain test write conditions
    repeat (15) begin
      req = read_sequence_item::type_id::create("req");
      start_item(req);
      req.read_enable = 0; // Keep read disabled
      req.aempty_value = 4;
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Write Conditions Support: %s", req.sprint), UVM_HIGH)
    end
  endtask

  // Support scenario for Test Case 3: Memory access - read domain provides some activity
  task memory_access_support_scenario();
    read_sequence_item req;
    
    // Reset phase - ensure clean FIFO state
    repeat (7) begin
      req = read_sequence_item::type_id::create("req");
      start_item(req);
      req.read_enable = 0; // Keep read disabled during reset
      req.aempty_value = 4;
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Reset Phase: %s", req.sprint), UVM_HIGH)
    end
    
    // Provide some read activity to test memory access
    repeat (5) begin
      req = read_sequence_item::type_id::create("req");
      start_item(req);
      req.read_enable = 1; // Enable read to test memory access
      req.aempty_value = 4;
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Memory Access Support: %s", req.sprint), UVM_HIGH)
    end
  endtask

  // Support scenario for Test Case 4: Full condition - read domain provides minimal activity
  task full_condition_support_scenario();
    read_sequence_item req;
    
    // Reset phase - ensure clean FIFO state
    repeat (7) begin
      req = read_sequence_item::type_id::create("req");
      start_item(req);
      req.read_enable = 0; // Keep read disabled during reset
      req.aempty_value = 4;
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Reset Phase: %s", req.sprint), UVM_HIGH)
    end
    
    // Keep read disabled to let FIFO fill up
    repeat (40) begin
      req = read_sequence_item::type_id::create("req");
      start_item(req);
      req.read_enable = 0; // Keep read disabled
      req.aempty_value = 4;
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Full Condition Support: %s", req.sprint), UVM_HIGH)
    end
  endtask

  // Support scenario for Test Case 6: Almost full - read domain provides minimal activity
  task almost_full_support_scenario();
    read_sequence_item req;
    
    // Reset phase - ensure clean FIFO state
    repeat (7) begin
      req = read_sequence_item::type_id::create("req");
      start_item(req);
      req.read_enable = 0; // Keep read disabled during reset
      req.aempty_value = 4;
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Reset Phase: %s", req.sprint), UVM_HIGH)
    end
    
    // Keep read disabled to let FIFO reach almost full
    repeat (30) begin
      req = read_sequence_item::type_id::create("req");
      start_item(req);
      req.read_enable = 0; // Keep read disabled
      req.aempty_value = 4;
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Almost Full Support: %s", req.sprint), UVM_HIGH)
    end
  endtask

  // Support scenario for Test Case 8: Overflow - read domain provides minimal activity
  task overflow_support_scenario();
    read_sequence_item req;
    
    // Reset phase - ensure clean FIFO state
    repeat (7) begin
      req = read_sequence_item::type_id::create("req");
      start_item(req);
      req.read_enable = 0; // Keep read disabled during reset
      req.aempty_value = 4;
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Reset Phase: %s", req.sprint), UVM_HIGH)
    end
    
    // Keep read disabled to let FIFO overflow
    repeat (40) begin
      req = read_sequence_item::type_id::create("req");
      start_item(req);
      req.read_enable = 0; // Keep read disabled
      req.aempty_value = 4;
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Overflow Support: %s", req.sprint), UVM_HIGH)
    end
  endtask

endclass
