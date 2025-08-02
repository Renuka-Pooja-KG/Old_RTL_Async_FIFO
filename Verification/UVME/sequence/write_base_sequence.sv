class write_base_sequence extends uvm_sequence #(write_sequence_item);
  `uvm_object_utils(write_base_sequence)

  // Configuration parameters
  int num_transactions = 10;
  int scenario = 0; // 0: random, 1: reset, 2: write_only, 3: read_only, 4: simultaneous, 5: reset-write-read
                    // 6: write_conditions, 7: memory_access, 8: full_condition, 9: almost_full, 10: overflow
                    // 11: read_conditions_support, 12: empty_condition_support, 13: almost_empty_support, 14: underflow_support

  function new(string name = "write_base_sequence");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(get_type_name(), $sformatf("Starting write_base_sequence with %0d transactions, scenario=%0d", num_transactions, scenario), UVM_LOW)
    case (scenario)
      0: random_scenario();
      1: reset_scenario();
      2: write_only_scenario();
      3: read_only_scenario();
      4: simultaneous_scenario();
      5: reset_write_read_scenario();
      6: write_conditions_scenario();
      7: memory_access_scenario();
      8: full_condition_scenario();
      9: almost_full_scenario();
      10: overflow_scenario();
      11: read_conditions_support_scenario();
      12: empty_condition_support_scenario();
      13: almost_empty_support_scenario();
      14: underflow_support_scenario();
      default: random_scenario();
    endcase
    `uvm_info(get_type_name(), "write_base_sequence completed", UVM_LOW)
  endtask

  // Random scenario
  task random_scenario();
    write_sequence_item req;
        
    // Reset phase - ensure clean FIFO state
    repeat (3) begin
      req = write_sequence_item::type_id::create("req");
      start_item(req);
      req.hw_rst = 0; // Assert hardware reset
      req.sw_rst = 0;
      req.mem_rst = 0;
      req.write_enable = 0;
      req.wdata = 0;
      req.afull_value = 28;
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Reset Phase: %s", req.sprint), UVM_HIGH)
    end
    
    // De-assert reset
    req = write_sequence_item::type_id::create("req");
    start_item(req);
    req.hw_rst = 1; // De-assert hardware reset
    req.sw_rst = 0;
    req.mem_rst = 0;
    req.write_enable = 0;
    req.wdata = 0;
    req.afull_value = 28;
    finish_item(req);
    `uvm_info(get_type_name(), $sformatf("De-assert Reset: %s", req.sprint), UVM_HIGH)
    
    repeat (num_transactions) begin
      req = write_sequence_item::type_id::create("req");
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
    write_sequence_item req;
    // Hardware reset for 3 cycles
    repeat (3) begin
      req = write_sequence_item::type_id::create("req");
      start_item(req);
      req.hw_rst = 0; // Assert hardware reset
      req.sw_rst = 0; // Ensure software reset is low
      req.mem_rst = 0; // Ensure memory reset is low
      req.write_enable = 0;
      req.wdata = 0;
      req.afull_value = 28;
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Hardware Reset: %s", req.sprint), UVM_HIGH)
    end
    // De-assert hardware reset
    req = write_sequence_item::type_id::create("req");
    start_item(req);
    req.hw_rst = 1; // De-assert hardware reset
    req.sw_rst = 0; // Ensure software reset is low
    req.mem_rst = 0; // Ensure memory reset is low
    req.write_enable = 0;
    req.wdata = 0;
    req.afull_value = 28;
    finish_item(req);
    `uvm_info(get_type_name(), $sformatf("De-assert Hardware Reset: %s", req.sprint), UVM_HIGH)

    // Write operation for 3 cycles
    repeat (3) begin
      req = write_sequence_item::type_id::create("req");
      start_item(req);
      req.hw_rst = 1; // Ensure hardware reset is de-asserted
      req.sw_rst = 0; // Ensure software reset is low
      req.mem_rst = 0; // Ensure memory reset is low
      req.write_enable = 1;
      req.wdata = $urandom_range(0, 32'hFFFFFFFF);
      req.afull_value = 28;
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Write Operation: %s", req.sprint), UVM_HIGH)
    end

//Hardware reset for 3 cycles
    repeat (3) begin
      req = write_sequence_item::type_id::create("req");
      start_item(req);
      req.hw_rst = 0; // Assert hardware reset
      req.sw_rst = 0; // Ensure software reset is low
      req.mem_rst = 0; // Ensure memory reset is low
      req.write_enable = 0;
      req.wdata = 0;
      req.afull_value = 28;
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Hardware Reset: %s", req.sprint), UVM_HIGH)
    end

    // De-assert hardware reset 
    req = write_sequence_item::type_id::create("req");
    start_item(req);
    req.hw_rst = 1; // De-assert hardware reset
    req.sw_rst = 0; // Ensure software reset is low
    req.mem_rst = 0; // Ensure memory reset is low
    req.write_enable = 0;
    req.wdata = 0;
    req.afull_value = 28;
    finish_item(req);
    `uvm_info(get_type_name(), $sformatf("De-assert Hardware Reset: %s", req.sprint), UVM_HIGH)

    // Write operation for 3 cycles
    repeat (3) begin
      req = write_sequence_item::type_id::create("req");
      start_item(req);
      req.hw_rst = 1; // Ensure hardware reset is de-asserted
      req.sw_rst = 0; // Ensure software reset is low
      req.mem_rst = 0; // Ensure memory reset is low
      req.write_enable = 1;
      req.wdata = $urandom_range(0, 32'hFFFFFFFF);
      req.afull_value = 28;
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Write Operation: %s", req.sprint), UVM_HIGH)
    end
    // Software reset for 2 cycles
    repeat (2) begin
      req = write_sequence_item::type_id::create("req");
      start_item(req);
      req.hw_rst = 1; // Ensure hardware reset is de-asserted
      req.sw_rst = 1; // Assert software reset
      req.mem_rst = 0; // Ensure memory reset is low
      req.write_enable = 0;
      req.wdata = 0;
      req.afull_value = 28;
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Software Reset: %s", req.sprint), UVM_HIGH)
    end
    // De-assert software reset
    req = write_sequence_item::type_id::create("req");
    start_item(req);
    req.hw_rst = 1; // Ensure hardware reset is de-asserted
    req.sw_rst = 0; // De-assert software reset
    req.mem_rst = 0;
    req.write_enable = 0;
    req.wdata = 0;
    req.afull_value = 28;
    finish_item(req);
    `uvm_info(get_type_name(), $sformatf("Normal Operation: %s", req.sprint), UVM_HIGH)
    // Write operation for 3 cycles
    repeat (3) begin
      req = write_sequence_item::type_id::create("req");
      start_item(req);
      req.hw_rst = 1; // Ensure hardware reset is de-asserted
      req.sw_rst = 0; // Ensure software reset is low
      req.mem_rst = 0; // Ensure memory reset is low
      req.write_enable = 1;
      req.wdata = $urandom_range(0, 32'hFFFFFFFF);
      req.afull_value = 28;
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Write Operation: %s", req.sprint), UVM_HIGH)
    end

    // Memory reset for 3 cycles
    repeat (3) begin
      req = write_sequence_item::type_id::create("req");
      start_item(req);
      req.hw_rst = 1; // De-assert hardware reset
      req.sw_rst = 0; // Ensure software reset is low
      req.mem_rst = 1; // Memory reset asserted
      req.write_enable = 0;
      req.wdata = 0;
      req.afull_value = 28;
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Hardware Reset: %s", req.sprint), UVM_HIGH)
    end
    // De-assert hardware reset
    req = write_sequence_item::type_id::create("req");
    start_item(req);
    req.hw_rst = 1; // De-assert hardware reset
    req.sw_rst = 0; // Ensure software reset is low
    req.mem_rst = 0; // Ensure memory reset is low
    req.write_enable = 0;
    req.wdata = 0;
    req.afull_value = 28;
    finish_item(req);
    `uvm_info(get_type_name(), $sformatf("De-assert Hardware Reset: %s", req.sprint), UVM_HIGH)
   
  endtask

  // Write-only scenario: write_enable is always high
  task write_only_scenario();
    write_sequence_item req;
        
    // Reset phase - ensure clean FIFO state
    repeat (3) begin
      req = write_sequence_item::type_id::create("req");
      start_item(req);
      req.hw_rst = 0; // Assert hardware reset
      req.sw_rst = 0;
      req.mem_rst = 0;
      req.write_enable = 0;
      req.wdata = 0;
      req.afull_value = 28;
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Reset Phase: %s", req.sprint), UVM_HIGH)
    end
    
    // De-assert reset
    req = write_sequence_item::type_id::create("req");
    start_item(req);
    req.hw_rst = 1; // De-assert hardware reset
    req.sw_rst = 0;
    req.mem_rst = 0;
    req.write_enable = 0;
    req.wdata = 0;
    req.afull_value = 28;
    finish_item(req);
    `uvm_info(get_type_name(), $sformatf("De-assert Reset: %s", req.sprint), UVM_HIGH)
    
    repeat (num_transactions) begin
      req = write_sequence_item::type_id::create("req");
      start_item(req);
      req.write_enable = 1;
      req.sw_rst      = 0;
      req.hw_rst    = 1;
      req.mem_rst     = 0;
      req.wdata       = $urandom_range(0, 32'hFFFFFFFF);
      req.afull_value = 28;
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Write-only: %s", req.sprint), UVM_HIGH)
    end
  endtask

  // Read-only scenario: write_enable is always low
  task read_only_scenario();
    write_sequence_item req;
        
    // Reset phase - ensure clean FIFO state
    repeat (3) begin
      req = write_sequence_item::type_id::create("req");
      start_item(req);
      req.hw_rst = 0; // Assert hardware reset
      req.sw_rst = 0;
      req.mem_rst = 0;
      req.write_enable = 0;
      req.wdata = 0;
      req.afull_value = 28;
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Reset Phase: %s", req.sprint), UVM_HIGH)
    end
    
    // De-assert reset
    req = write_sequence_item::type_id::create("req");
    start_item(req);
    req.hw_rst = 1; // De-assert hardware reset
    req.sw_rst = 0;
    req.mem_rst = 0;
    req.write_enable = 0;
    req.wdata = 0;
    req.afull_value = 28;
    finish_item(req);
    `uvm_info(get_type_name(), $sformatf("De-assert Reset: %s", req.sprint), UVM_HIGH)

    // Write operation for 10 cycles
    repeat (10) begin
      req = write_sequence_item::type_id::create("req");
      start_item(req);
      req.write_enable = 1; // Ensure write_enable is high
      req.sw_rst      = 0; // Ensure software reset is low
      req.hw_rst    = 1; // Ensure hardware reset is de-asserted
      req.mem_rst     = 0; // Ensure memory reset is low
      req.wdata       = $urandom_range(0, 32'hFFFFFFFF);
      req.afull_value = 28; // Set afull_value to a valid state
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Simultaneous: %s", req.sprint), UVM_HIGH)
    end
    
    repeat (num_transactions) begin
      req = write_sequence_item::type_id::create("req");
      start_item(req);
      req.write_enable = 0; // Ensure write_enable is low
      req.sw_rst      = 0; // Ensure software reset is low
      req.hw_rst    = 1; // Ensure hardware reset is de-asserted
      req.mem_rst     = 0; // Ensure memory reset is low
      req.wdata       = 0;
      req.afull_value = 28;
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Read-only: %s", req.sprint), UVM_HIGH)
    end
  endtask

  // Simultaneous scenario: write_enable is always high
  task simultaneous_scenario();
    write_sequence_item req;
 
    // Reset phase - ensure clean FIFO state
    repeat (3) begin
      req = write_sequence_item::type_id::create("req");
      start_item(req);
      req.hw_rst = 0; // Assert hardware reset
      req.sw_rst = 0;
      req.mem_rst = 0;
      req.write_enable = 0;
      req.wdata = 0;
      req.afull_value = 28;
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Reset Phase: %s", req.sprint), UVM_HIGH)
    end
    
    // De-assert reset
    req = write_sequence_item::type_id::create("req");
    start_item(req);
    req.hw_rst = 1; // De-assert hardware reset
    req.sw_rst = 0;
    req.mem_rst = 0;
    req.write_enable = 0;
    req.wdata = 0;
    req.afull_value = 28;
    finish_item(req);
    `uvm_info(get_type_name(), $sformatf("De-assert Reset: %s", req.sprint), UVM_HIGH)
    
    repeat (num_transactions) begin
      req = write_sequence_item::type_id::create("req");
      start_item(req);
      req.write_enable = 1; // Ensure write_enable is high
      req.sw_rst      = 0; // Ensure software reset is low
      req.hw_rst    = 1; // Ensure hardware reset is de-asserted
      req.mem_rst     = 0; // Ensure memory reset is low
      req.wdata       = $urandom_range(0, 32'hFFFFFFFF);
      req.afull_value = 28; // Set afull_value to a valid state
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Simultaneous: %s", req.sprint), UVM_HIGH)
    end
  endtask

  // Reset - write  - read - write - read
  task reset_write_read_scenario();
    write_sequence_item req;
    // Hardware reset for 3 cycles
    repeat (3) begin
      req = write_sequence_item::type_id::create("req");
      start_item(req);
      req.hw_rst = 0; // Assert hardware reset
      req.sw_rst = 0; // Ensure software reset is low
      req.mem_rst = 0; // Ensure memory reset is low
      req.write_enable = 0;
      req.wdata = 0;
      req.afull_value = 28;
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Hardware Reset: %s", req.sprint), UVM_HIGH)
    end
    // De-assert hardware reset
    req = write_sequence_item::type_id::create("req");
    start_item(req);
    req.hw_rst = 1; // De-assert hardware reset
    req.sw_rst = 0; // Ensure software reset is low
    req.mem_rst = 0; // Ensure memory reset is low
    req.write_enable = 0;
    req.wdata = 0;
    req.afull_value = 28;
    finish_item(req);
    `uvm_info(get_type_name(), $sformatf("De-assert Hardware Reset: %s", req.sprint), UVM_HIGH)
    // Write operation for 10 cycles
    repeat (10) begin
      req = write_sequence_item::type_id::create("req");
      start_item(req);
      req.write_enable = 1;
      req.sw_rst      = 0;
      req.hw_rst    = 1;
      req.mem_rst     = 0;
      req.wdata       = $urandom_range(0, 32'hFFFFFFFF);
      req.afull_value = 28;
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Write-only: %s", req.sprint), UVM_HIGH)
    end
    // Read operation for 5 cycles
    repeat (5) begin    
      req = write_sequence_item::type_id::create("req");
      start_item(req);
      req.hw_rst = 1; // Ensure hardware reset is de-asserted
      req.sw_rst = 0; // Ensure software reset is low
      req.mem_rst = 0; // Ensure memory reset is low
      req.write_enable = 0; // Disable write operation
      req.wdata = 0; // No data for read operation
      req.afull_value = 28; // Set afull_value to a valid state
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Read Operation: %s", req.sprint), UVM_HIGH)
    end
    // Write operation for 10 cycles
    repeat (10) begin
      req = write_sequence_item::type_id::create("req");
      start_item(req);
      req.write_enable = 1;
      req.sw_rst      = 0;
      req.hw_rst    = 1;
      req.mem_rst     = 0;
      req.wdata       = $urandom_range(0, 32'hFFFFFFFF);
      req.afull_value = 28;
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Write-only: %s", req.sprint), UVM_HIGH)
    end
    // Read operation for 5 cycles
    repeat (5) begin
      req = write_sequence_item::type_id::create("req");
      start_item(req);
      req.hw_rst = 1; // Ensure hardware reset is de-asserted
      req.sw_rst = 0; // Ensure software reset is low
      req.mem_rst = 0; // Ensure memory reset is low
      req.write_enable = 0; // Disable write operation
      req.wdata = 0; // No data for read operation
      req.afull_value = 28; // Set afull_value to a valid state
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Read Operation: %s", req.sprint), UVM_HIGH)
    end
    endtask

  // Test Case 1: Check the conditions to write the data into fifo when write enable =1
  task write_conditions_scenario();
    write_sequence_item req;
    
    // Reset phase - ensure clean FIFO state
    repeat (3) begin
      req = write_sequence_item::type_id::create("req");
      start_item(req);
      req.hw_rst = 0; // Assert hardware reset
      req.sw_rst = 0;
      req.mem_rst = 0;
      req.write_enable = 0;
      req.wdata = 0;
      req.afull_value = 28;
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Reset Phase: %s", req.sprint), UVM_HIGH)
    end
    
    // De-assert reset
    req = write_sequence_item::type_id::create("req");
    start_item(req);
    req.hw_rst = 1; // De-assert hardware reset
    req.sw_rst = 0;
    req.mem_rst = 0;
    req.write_enable = 0;
    req.wdata = 0;
    req.afull_value = 28;
    finish_item(req);
    `uvm_info(get_type_name(), $sformatf("De-assert Reset: %s", req.sprint), UVM_HIGH)
    
    // Write with write_enable = 1
    repeat (num_transactions) begin
      req = write_sequence_item::type_id::create("req");
      start_item(req);
      req.write_enable = 1; // Enable write
      req.sw_rst      = 0;
      req.hw_rst    = 1;
      req.mem_rst     = 0;
      req.wdata       = $urandom_range(0, 32'hFFFFFFFF);
      req.afull_value = 28;
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Write Conditions: %s", req.sprint), UVM_HIGH)
    end
  endtask

  // Test Case 3: Check the memory that the data is accessing correct location or not in both write and read operations
  task memory_access_scenario();
    write_sequence_item req;
    
    // Reset phase - ensure clean FIFO state
    repeat (3) begin
      req = write_sequence_item::type_id::create("req");
      start_item(req);
      req.hw_rst = 0; // Assert hardware reset
      req.sw_rst = 0;
      req.mem_rst = 0;
      req.write_enable = 0;
      req.wdata = 0;
      req.afull_value = 28;
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Reset Phase: %s", req.sprint), UVM_HIGH)
    end
    
    // De-assert reset
    req = write_sequence_item::type_id::create("req");
    start_item(req);
    req.hw_rst = 1; // De-assert hardware reset
    req.sw_rst = 0;
    req.mem_rst = 0;
    req.write_enable = 0;
    req.wdata = 0;
    req.afull_value = 28;
    finish_item(req);
    `uvm_info(get_type_name(), $sformatf("De-assert Reset: %s", req.sprint), UVM_HIGH)
    
    // Write data to specific memory locations
    repeat (num_transactions) begin
      req = write_sequence_item::type_id::create("req");
      start_item(req);
      req.write_enable = 1;
      req.sw_rst      = 0;
      req.hw_rst    = 1;
      req.mem_rst     = 0;
      req.wdata       = $urandom_range(0, 32'hFFFFFFFF); // Random data to test memory access
      req.afull_value = 28;
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Memory Access: %s", req.sprint), UVM_HIGH)
    end
  endtask

  // Test Case 4: Check the full condition without reading the data
  task full_condition_scenario();
    write_sequence_item req;
    
    // Reset phase - ensure clean FIFO state
    repeat (3) begin
      req = write_sequence_item::type_id::create("req");
      start_item(req);
      req.hw_rst = 0; // Assert hardware reset
      req.sw_rst = 0;
      req.mem_rst = 0;
      req.write_enable = 0;
      req.wdata = 0;
      req.afull_value = 28;
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Reset Phase: %s", req.sprint), UVM_HIGH)
    end
    
    // De-assert reset
    req = write_sequence_item::type_id::create("req");
    start_item(req);
    req.hw_rst = 1; // De-assert hardware reset
    req.sw_rst = 0;
    req.mem_rst = 0;
    req.write_enable = 0;
    req.wdata = 0;
    req.afull_value = 28;
    finish_item(req);
    `uvm_info(get_type_name(), $sformatf("De-assert Reset: %s", req.sprint), UVM_HIGH)
    
    // Write continuously until FIFO is full (32 locations)
    repeat (35) begin // Write more than FIFO depth to trigger full condition
      req = write_sequence_item::type_id::create("req");
      start_item(req);
      req.write_enable = 1;
      req.sw_rst      = 0;
      req.hw_rst    = 1;
      req.mem_rst     = 0;
      req.wdata       = $urandom_range(0, 32'hFFFFFFFF);
      req.afull_value = 28;
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Full Condition: %s", req.sprint), UVM_HIGH)
    end
  endtask

  // Test Case 6: Check the almost full condition based on almost_full_value
  task almost_full_scenario();
    write_sequence_item req;
    
    // Reset phase - ensure clean FIFO state
    repeat (3) begin
      req = write_sequence_item::type_id::create("req");
      start_item(req);
      req.hw_rst = 0; // Assert hardware reset
      req.sw_rst = 0;
      req.mem_rst = 0;
      req.write_enable = 0;
      req.wdata = 0;
      req.afull_value = 28;
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Reset Phase: %s", req.sprint), UVM_HIGH)
    end
    
    // De-assert reset
    req = write_sequence_item::type_id::create("req");
    start_item(req);
    req.hw_rst = 1; // De-assert hardware reset
    req.sw_rst = 0;
    req.mem_rst = 0;
    req.write_enable = 0;
    req.wdata = 0;
    req.afull_value = 28;
    finish_item(req);
    `uvm_info(get_type_name(), $sformatf("De-assert Reset: %s", req.sprint), UVM_HIGH)
    
    // Write until almost full condition is reached
    repeat (29) begin // Write enough to trigger almost full (afull_value = 28)
      req = write_sequence_item::type_id::create("req");
      start_item(req);
      req.write_enable = 1;
      req.sw_rst      = 0;
      req.hw_rst    = 1;
      req.mem_rst     = 0;
      req.wdata       = $urandom_range(0, 32'hFFFFFFFF);
      req.afull_value = 28; // Set almost full threshold
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Almost Full: %s", req.sprint), UVM_HIGH)
    end

     // De-assert reset
    req = write_sequence_item::type_id::create("req");
    start_item(req);
    req.hw_rst = 1; // De-assert hardware reset
    req.sw_rst = 0;
    req.mem_rst = 0;
    req.write_enable = 0;
    req.wdata = 0;
    req.afull_value = 28;
    finish_item(req);
    `uvm_info(get_type_name(), $sformatf("De-assert Reset: %s", req.sprint), UVM_HIGH)
    
  endtask

  // Test Case 8: Check overflow condition when write enable and write full signals are asserted
  task overflow_scenario();
    write_sequence_item req;
    
    // Reset phase - ensure clean FIFO state
    repeat (3) begin
      req = write_sequence_item::type_id::create("req");
      start_item(req);
      req.hw_rst = 0; // Assert hardware reset
      req.sw_rst = 0;
      req.mem_rst = 0;
      req.write_enable = 0;
      req.wdata = 0;
      req.afull_value = 28;
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Reset Phase: %s", req.sprint), UVM_HIGH)
    end
    
    // De-assert reset
    req = write_sequence_item::type_id::create("req");
    start_item(req);
    req.hw_rst = 1; // De-assert hardware reset
    req.sw_rst = 0;
    req.mem_rst = 0;
    req.write_enable = 0;
    req.wdata = 0;
    req.afull_value = 28;
    finish_item(req);
    `uvm_info(get_type_name(), $sformatf("De-assert Reset: %s", req.sprint), UVM_HIGH)
    
    // First fill the FIFO completely
    repeat (32) begin
      req = write_sequence_item::type_id::create("req");
      start_item(req);
      req.write_enable = 1;
      req.sw_rst      = 0;
      req.hw_rst    = 1;
      req.mem_rst     = 0;
      req.wdata       = $urandom_range(0, 32'hFFFFFFFF);
      req.afull_value = 28;
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Fill FIFO: %s", req.sprint), UVM_HIGH)
    end
    // Now try to write more to trigger overflow
    repeat (5) begin
      req = write_sequence_item::type_id::create("req");
      start_item(req);
      req.write_enable = 1; // Keep writing even when full
      req.sw_rst      = 0;
      req.hw_rst    = 1;
      req.mem_rst     = 0;
      req.wdata       = $urandom_range(0, 32'hFFFFFFFF);
      req.afull_value = 28;
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Overflow: %s", req.sprint), UVM_HIGH)
    end
  endtask

  // Support scenario for Test Case 2: Read conditions - write domain provides minimal activity
  task read_conditions_support_scenario();
    write_sequence_item req;
    
    // Reset phase - ensure clean FIFO state
    repeat (3) begin
      req = write_sequence_item::type_id::create("req");
      start_item(req);
      req.hw_rst = 0; // Assert hardware reset
      req.sw_rst = 0;
      req.mem_rst = 0;
      req.write_enable = 0;
      req.wdata = 0;
      req.afull_value = 28;
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Reset Phase: %s", req.sprint), UVM_HIGH)
    end
    
    // De-assert reset
    req = write_sequence_item::type_id::create("req");
    start_item(req);
    req.hw_rst = 1; // De-assert hardware reset
    req.sw_rst = 0;
    req.mem_rst = 0;
    req.write_enable = 0;
    req.wdata = 0;
    req.afull_value = 28;
    finish_item(req);
    `uvm_info(get_type_name(), $sformatf("De-assert Reset: %s", req.sprint), UVM_HIGH)
    
    // Provide some data for reading, but keep write activity minimal
    repeat (5) begin
      req = write_sequence_item::type_id::create("req");
      start_item(req);
      req.write_enable = 1; // Enable write to provide data
      req.sw_rst      = 0;
      req.hw_rst    = 1;
      req.mem_rst     = 0;
      req.wdata       = $urandom_range(0, 32'hFFFFFFFF);
      req.afull_value = 28;
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Read Conditions Support: %s", req.sprint), UVM_HIGH)
    end
    // Then disable writes to let read domain test read conditions
    repeat (10) begin
      req = write_sequence_item::type_id::create("req");
      start_item(req);
      req.write_enable = 0; // Disable write
      req.sw_rst      = 0;
      req.hw_rst    = 1;
      req.mem_rst     = 0;
      req.wdata       = 0;
      req.afull_value = 28;
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Read Conditions Support (no write): %s", req.sprint), UVM_HIGH)
    end
  endtask

  // Support scenario for Test Case 5: Empty condition - write domain provides no data
  task empty_condition_support_scenario();
    write_sequence_item req;
    
    // Reset phase - ensure clean FIFO state
    repeat (3) begin
      req = write_sequence_item::type_id::create("req");
      start_item(req);
      req.hw_rst = 0; // Assert hardware reset
      req.sw_rst = 0;
      req.mem_rst = 0;
      req.write_enable = 0;
      req.wdata = 0;
      req.afull_value = 28;
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Reset Phase: %s", req.sprint), UVM_HIGH)
    end
    
    // De-assert reset
    req = write_sequence_item::type_id::create("req");
    start_item(req);
    req.hw_rst = 1; // De-assert hardware reset
    req.sw_rst = 0;
    req.mem_rst = 0;
    req.write_enable = 0;
    req.wdata = 0;
    req.afull_value = 28;
    finish_item(req);
    `uvm_info(get_type_name(), $sformatf("De-assert Reset: %s", req.sprint), UVM_HIGH)
    
    // Write operation for 32 cycles
    repeat (30) begin
      req = write_sequence_item::type_id::create("req");
      start_item(req);
      req.write_enable = 1; // Ensure write_enable is high
      req.sw_rst      = 0; // Ensure software reset is low
      req.hw_rst    = 1; // Ensure hardware reset is de-asserted
      req.mem_rst     = 0; // Ensure memory reset is low
      req.wdata       = $urandom_range(0, 32'hFFFFFFFF);
      req.afull_value = 28; // Set afull_value to a valid state
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Simultaneous: %s", req.sprint), UVM_HIGH)
    end
    // Keep write disabled to maintain empty FIFO
    repeat (32) begin
      req = write_sequence_item::type_id::create("req");
      start_item(req);
      req.write_enable = 0; // Keep write disabled
      req.sw_rst      = 0;
      req.hw_rst    = 1;
      req.mem_rst     = 0;
      req.wdata       = 0;
      req.afull_value = 28;
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Empty Condition Support: %s", req.sprint), UVM_HIGH)
    end
  endtask

  // Support scenario for Test Case 7: Almost empty - write domain provides some data then stops
  task almost_empty_support_scenario();
    write_sequence_item req;
    
    // Reset phase - ensure clean FIFO state
    repeat (3) begin
      req = write_sequence_item::type_id::create("req");
      start_item(req);
      req.hw_rst = 0; // Assert hardware reset
      req.sw_rst = 0;
      req.mem_rst = 0;
      req.write_enable = 0;
      req.wdata = 0;
      req.afull_value = 28;
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Reset Phase: %s", req.sprint), UVM_HIGH)
    end
    
    // De-assert reset
    req = write_sequence_item::type_id::create("req");
    start_item(req);
    req.hw_rst = 1; // De-assert hardware reset
    req.sw_rst = 0;
    req.mem_rst = 0;
    req.write_enable = 0;
    req.wdata = 0;
    req.afull_value = 28;
    finish_item(req);
    `uvm_info(get_type_name(), $sformatf("De-assert Reset: %s", req.sprint), UVM_HIGH)
    
    // First provide some data
    repeat (8) begin
      req = write_sequence_item::type_id::create("req");
      start_item(req);
      req.write_enable = 1; // Enable write to provide data
      req.sw_rst      = 0;
      req.hw_rst    = 1;
      req.mem_rst     = 0;
      req.wdata       = $urandom_range(0, 32'hFFFFFFFF);
      req.afull_value = 28;
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Almost Empty Support (write): %s", req.sprint), UVM_HIGH)
    end
    // Then stop writing to let read domain test almost empty
    repeat (20) begin
      req = write_sequence_item::type_id::create("req");
      start_item(req);
      req.write_enable = 0; // Disable write
      req.sw_rst      = 0;
      req.hw_rst    = 1;
      req.mem_rst     = 0;
      req.wdata       = 0;
      req.afull_value = 28;
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Almost Empty Support (no write): %s", req.sprint), UVM_HIGH)
    end
  endtask

  // Support scenario for Test Case 9: Underflow - write domain provides no data
  task underflow_support_scenario();
    write_sequence_item req;
    
    // Reset phase - ensure clean FIFO state
    repeat (3) begin
      req = write_sequence_item::type_id::create("req");
      start_item(req);
      req.hw_rst = 0; // Assert hardware reset
      req.sw_rst = 0;
      req.mem_rst = 0;
      req.write_enable = 0;
      req.wdata = 0;
      req.afull_value = 28;
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Reset Phase: %s", req.sprint), UVM_HIGH)
    end
    
    // De-assert reset
    req = write_sequence_item::type_id::create("req");
    start_item(req);
    req.hw_rst = 1; // De-assert hardware reset
    req.sw_rst = 0;
    req.mem_rst = 0;
    req.write_enable = 0;
    req.wdata = 0;
    req.afull_value = 28;
    finish_item(req);
    `uvm_info(get_type_name(), $sformatf("De-assert Reset: %s", req.sprint), UVM_HIGH)
    
     // First provide some data
    repeat (5) begin
      req = write_sequence_item::type_id::create("req");
      start_item(req);
      req.write_enable = 1; // Enable write to provide data
      req.sw_rst      = 0;
      req.hw_rst    = 1;
      req.mem_rst     = 0;
      req.wdata       = $urandom_range(0, 32'hFFFFFFFF);
      req.afull_value = 28;
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Almost Empty Support (write): %s", req.sprint), UVM_HIGH)
    end
    
    // Keep write disabled to maintain empty FIFO for underflow testing
    repeat (15) begin
      req = write_sequence_item::type_id::create("req");
      start_item(req);
      req.write_enable = 0; // Keep write disabled
      req.sw_rst      = 0;
      req.hw_rst    = 1;
      req.mem_rst     = 0;
      req.wdata       = 0;
      req.afull_value = 28;
      finish_item(req);
      `uvm_info(get_type_name(), $sformatf("Underflow Support: %s", req.sprint), UVM_HIGH)
    end
  endtask

endclass
