class write_sequencer extends uvm_sequencer #(write_sequence_item);
  `uvm_component_utils(write_sequencer)

  function new(string name = "write_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info(get_type_name(), "write_sequencer build_phase completed", UVM_LOW)
  endfunction

endclass 