class write_coverage extends uvm_subscriber #(write_sequence_item);

  `uvm_component_utils(write_coverage)
  write_sequence_item cov_item;

  covergroup write_cg ();
    option.per_instance = 1;
    option.name = "write_cg";
    option.comment = "Write coverage group";

    write_enable_cp: coverpoint cov_item.write_enable {
      bins zero = {0};
      bins one = {1};
    }
    wdata_cp: coverpoint cov_item.wdata {
      option.auto_bin_max = 32;
    }
    afull_value_cp: coverpoint cov_item.afull_value {
      bins low = {[1:10]};
      bins med = {[11:20]};
      bins high = {[21:31]};
      bins full = {32};
    }
    wr_sw_rst_cp: coverpoint cov_item.sw_rst {
      bins zero = {0};
      bins one = {1};
    }
    wfull_cp: coverpoint cov_item.wfull {
      bins zero = {0};
      bins one = {1};
    }
    wr_almost_ful_cp: coverpoint cov_item.wr_almost_ful {
      bins zero = {0};
      bins one = {1};
    }
    fifo_write_count_cp: coverpoint cov_item.fifo_write_count {
      bins zero = {0};
      bins low = {[1:10]};
      bins med = {[11:20]};
      bins high = {[21:31]};
      bins full = {32};
    }
    wr_level_cp: coverpoint cov_item.wr_level {
      bins empty = {0};
      bins low = {[1:10]};
      bins med = {[11:20]};
      bins high = {[21:31]};
      bins full = {32};
    }
    overflow_cp: coverpoint cov_item.overflow {
      bins zero = {0};
      bins one = {1};
    }
    // Example cross coverage
    cross_write_enable_wdata: cross write_enable_cp, wdata_cp {
      ignore_bins write_enable_zero_wdata = binsof(write_enable_cp.zero) && binsof(wdata_cp);
    }
  endgroup: write_cg

  int count = 0;
  uvm_analysis_imp #(write_sequence_item, write_coverage) wr_analysis_imp;


  function new(string name = "write_coverage", uvm_component parent = null);
    super.new(name, parent);
    write_cg = new();
    wr_analysis_imp = new("wr_analysis_imp", this);
  endfunction

  function void write(write_sequence_item t);
    cov_item = new();
    cov_item.copy(t);
    write_cg.sample();
    count++;
  endfunction

  virtual function void extract_phase(uvm_phase phase);
    super.extract_phase(phase);
    `uvm_info(get_type_name(), $sformatf("write_coverage: count = %d", count), UVM_LOW)
    `uvm_info(get_type_name(), $sformatf("write_coverage: write_cg = %s", write_cg.get_coverage()), UVM_LOW)
  endfunction

endclass 