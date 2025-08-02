class read_sequence_item extends uvm_sequence_item;

  rand bit read_enable;
  rand bit [4:0] aempty_value;
  // rand bit sw_rst; // Synchronous reset signal
  // rand bit hw_rst; // Asynchronous reset signal
  bit rdempty;
  bit rd_almost_empty;
  bit [5:0] fifo_read_count;
  bit underflow;
  bit [5:0] rd_level;
  bit [31:0] read_data;

  // FIFO level constraints
  constraint rd_level_constraint {
    rd_level <= 32;     // Read level cannot exceed FIFO depth
    rd_level >= 0;      // Read level cannot be negative
  }

  // Almost empty value constraint
  constraint aempty_value_constraint {
    aempty_value <= 31; // Almost empty value cannot exceed FIFO depth
    aempty_value >= 1;  // Almost empty value should be at least 1
  }

  // // Underflow prevention constraints
  // constraint read_when_empty_constraint {
  //   (rdempty == 1) -> (read_enable == 0);
  // }

  // Underflow testing constraint (for specific test scenarios)
  constraint underflow_testing_constraint {
    // When testing underflow, allow read even when empty
    (underflow == 1) -> (rdempty == 1 && read_enable == 1);
  }

  // // Data validation constraints
  // constraint read_data_constraint {
  //   (read_enable == 1 && rdempty == 0) -> (read_data != 32'hx);
  //   (rdempty == 1) -> (read_data == 32'h0);  // Default value when empty
  // }

  // // Read enable constraints for normal operation
  // constraint read_enable_normal_constraint {
  //   (rdempty == 0) -> (read_enable dist {0:=70, 1:=30}); // 70% disable, 30% enable when not empty
  // }

  `uvm_object_utils_begin(read_sequence_item)
    `uvm_field_int(read_enable, UVM_ALL_ON)
    `uvm_field_int(aempty_value, UVM_ALL_ON)
    // `uvm_field_int(sw_rst, UVM_ALL_ON)
    // `uvm_field_int(hw_rst, UVM_ALL_ON)
    `uvm_field_int(rdempty, UVM_ALL_ON)
    `uvm_field_int(rd_almost_empty, UVM_ALL_ON)
    `uvm_field_int(fifo_read_count, UVM_ALL_ON)
    `uvm_field_int(underflow, UVM_ALL_ON)
    `uvm_field_int(rd_level, UVM_ALL_ON)
    `uvm_field_int(read_data, UVM_ALL_ON)
  `uvm_object_utils_end
  
  function new(string name = "read_sequence_item");
    super.new(name);
  endfunction

  function void do_copy(uvm_object rhs);
    read_sequence_item rhs_;
    if (!$cast(rhs_, rhs)) begin
      `uvm_fatal("COPY_FAIL", "Type mismatch in do_copy")
    end
    super.do_copy(rhs);
    read_enable = rhs_.read_enable;
    aempty_value = rhs_.aempty_value;
    // sw_rst = rhs_.sw_rst;
    // hw_rst = rhs_.hw_rst;
    rdempty = rhs_.rdempty;
    rd_almost_empty = rhs_.rd_almost_empty;
    fifo_read_count = rhs_.fifo_read_count;
    underflow = rhs_.underflow;
    rd_level = rhs_.rd_level;
    read_data = rhs_.read_data;
  endfunction

  function string convert2string();
    return $sformatf("read_sequence_item: read_enable=%0b aempty_value=%0d rdempty=%0b rd_almost_empty=%0b fifo_read_count=%0d underflow=%0b rd_level=%0d read_data=%0d",
      read_enable, aempty_value, 
      rdempty, rd_almost_empty, fifo_read_count, underflow, rd_level, read_data);
  endfunction

 
endclass 