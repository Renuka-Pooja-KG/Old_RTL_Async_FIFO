class read_sequencer extends uvm_sequencer #(read_sequence_item);
  `uvm_component_utils(read_sequencer)

  function new(string name = "read_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info(get_type_name(), "read_sequencer build_phase completed", UVM_LOW)
  endfunction

endclass 