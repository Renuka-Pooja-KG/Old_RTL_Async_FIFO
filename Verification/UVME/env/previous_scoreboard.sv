class scoreboard extends uvm_scoreboard;
    `uvm_component_utils(scoreboard)

    uvm_analysis_export #(write_sequence_item) write_export;
    uvm_analysis_export #(read_sequence_item)  read_export;

    uvm_tlm_analysis_fifo #(write_sequence_item) write_fifo;
    uvm_tlm_analysis_fifo #(read_sequence_item)  read_fifo;

    // Data integrity checking
    bit [31:0] expected_data_queue[$];
    bit [31:0] expected_data;
    int write_count;
    int read_count;
    int error_count;
    int fifo_depth = 32; // Assuming FIFO depth is 32
    bit reset_active = 0; // Flag to track reset state
    //int i;

    // Write domain FIFO state tracking
    int expected_wr_level;
    int expected_rd_level; // FIFO depth
    int expected_fifo_write_count; // Added for checking fifo_write_count
    bit expected_wfull;
    bit expected_wr_almost_ful;
    bit expected_overflow;

    // Read domain FIFO state tracking
    int expected_fifo_read_count; // Added for checking fifo_read_count   
    bit expected_rdempty;
    bit expected_rdalmost_empty;
    bit expected_underflow;

    // Add new variables for transaction tracking
    write_sequence_item write_tr;
    read_sequence_item read_tr;
    bit write_tr_available = 0;
    bit read_tr_available = 0;
    time write_tr_time = 0;
    time read_tr_time = 0;

    function new(string name = "scoreboard", uvm_component parent = null);
        super.new(name, parent);
        write_export = new("write_export", this);
        read_export  = new("read_export", this);
        write_fifo = new("write_fifo", this);
        read_fifo  = new("read_fifo", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // Initialize the FIFO memory - START WITH EMPTY QUEUE
        expected_data_queue.delete();
        // Don't pre-populate with zeros - start with empty FIFO
        expected_data = 0;
        expected_wr_level = 0;
        expected_rd_level = fifo_depth; // Start with fifo_depth since rd_level = empty locations
        expected_fifo_write_count = 0;
        expected_wfull = 0;
        expected_wr_almost_ful = 0;
        expected_overflow = 0;
        expected_fifo_read_count = 0;
        expected_rdempty = 1; // FIFO starts empty
        expected_rdalmost_empty = 0;
        expected_underflow = 0;
        reset_active = 0;
        `uvm_info(get_type_name(), $sformatf("Scoreboard initialized: wr_level=%d, fifo_write_count=%d", expected_wr_level, expected_fifo_write_count), UVM_MEDIUM)
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        write_export.connect(write_fifo.analysis_export);
        read_export.connect(read_fifo.analysis_export);
    endfunction

    task run_phase(uvm_phase phase);
        fork
            collect_write_transactions();
            collect_read_transactions();
            process_transactions();
            check_fifo_behavior();
        join
    endtask

    task collect_write_transactions();
        forever begin
            write_fifo.get(write_tr);
            write_tr_available = 1;
            write_tr_time = $time;
            `uvm_info(get_type_name(), $sformatf("Collected write transaction at time %0t: %s", $time, write_tr.sprint), UVM_HIGH)
        end
    endtask

    task collect_read_transactions();
        forever begin
            read_fifo.get(read_tr);
            read_tr_available = 1;
            read_tr_time = $time;
            `uvm_info(get_type_name(), $sformatf("Collected read transaction at time %0t: %s", $time, read_tr.sprint), UVM_HIGH)
        end
    endtask

    task process_transactions();
        forever begin
            // Wait for at least one transaction to be available
            wait(write_tr_available || read_tr_available);
            
            // Process transactions in time order
            if (write_tr_available && read_tr_available) begin
                // Both transactions available - process them in time order
                if (write_tr_time == read_tr_time) begin
                    // Same time - process both operations but don't update levels until both are done
                    process_simultaneous_operations();
                end else if (read_tr_time < write_tr_time) begin
                    process_read_transaction();
                end else begin
                    process_write_transaction();
                end
            end else if (write_tr_available) begin
                process_write_transaction();
            end else if (read_tr_available) begin
                process_read_transaction();
            end
        end
    endtask

    task process_simultaneous_operations();
        `uvm_info(get_type_name(), $sformatf("Processing simultaneous operations at time %0t", $time), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("Before operations: wr_level=%d, rd_level=%d, queue_size=%d", expected_wr_level, expected_rd_level, expected_data_queue.size()), UVM_HIGH)

        // Check for any active reset
        if (!write_tr.hw_rst || write_tr.sw_rst || write_tr.mem_rst) begin
            `uvm_info(get_type_name(), "Reset active: clearing scoreboard state", UVM_MEDIUM)
            reset_active = 1;
            // Clear all expected values and queues
            expected_data_queue.delete();
            expected_wr_level           = 0;
            expected_rd_level           = fifo_depth; // Reset to fifo_depth since rd_level = empty locations
            expected_wfull              = 0;
            expected_rdempty            = 1;
            expected_wr_almost_ful      = 0;
            expected_rdalmost_empty     = 0;
            expected_underflow          = 0;
            expected_data               = 0;
            expected_overflow           = 0;
            expected_fifo_write_count   = 0; // Reset write count
            expected_fifo_read_count    = 0; // Reset read count
            write_tr_available = 0;
            read_tr_available = 0;
            return;
        end else begin
            reset_active = 0;
        end

        // Process read operation first (if enabled and data available)
        if (read_tr.read_enable && !reset_active && expected_data_queue.size() > 0) begin
            expected_data = expected_data_queue.pop_front();
            read_count++;
            if (read_tr.read_data !== expected_data) begin
                `uvm_error(get_type_name(), $sformatf("Data integrity error: expected=0x%h, actual=0x%h", expected_data, read_tr.read_data))
                error_count++;
            end
            expected_fifo_read_count++;
            // Decrement write level (filled locations)
            expected_wr_level--;
        end

        // Process write operation (if enabled and space available)
        if (write_tr.write_enable) begin
            if (!expected_wfull) begin
                // Normal write when not full
                expected_data_queue.push_back(write_tr.wdata);
                write_count++;
                expected_fifo_write_count++;
                // Increment write level (filled locations)
                expected_wr_level++;
            end else begin
                // Write attempted when full - this should trigger overflow
                `uvm_info(get_type_name(), $sformatf("Write attempted when full - overflow expected: data=0x%h, wr_level=%d", write_tr.wdata, expected_wr_level), UVM_HIGH)
            end
        end

        // Update read level based on write level
        expected_rd_level = fifo_depth - expected_wr_level;

        `uvm_info(get_type_name(), $sformatf("After simultaneous operations: wr_level=%d, rd_level=%d, queue_size=%d", expected_wr_level, expected_rd_level, expected_data_queue.size()), UVM_HIGH)
        `uvm_info(get_type_name(), $sformatf("Write transaction: fifo_write_count=%d, wr_level=%d", write_tr.fifo_write_count, write_tr.wr_level), UVM_HIGH)
        `uvm_info(get_type_name(), $sformatf("Read transaction: fifo_read_count=%d, rd_level=%d", read_tr.fifo_read_count, read_tr.rd_level), UVM_HIGH)

        // Update status flags
        expected_wfull         = (expected_wr_level == fifo_depth);
        expected_wr_almost_ful = (expected_wr_level >= write_tr.afull_value);
        expected_overflow      = (expected_wr_level == fifo_depth) && write_tr.write_enable;
        expected_rdempty       = (expected_wr_level == 0);
        expected_rdalmost_empty = (expected_wr_level <= read_tr.aempty_value);
        expected_underflow     = (expected_wr_level == 0) && read_tr.read_enable;

        // Check write transaction
        if (write_tr.write_enable) begin
            // Check for overflow - commented out due to RTL bug where overflow is only asserted for one clock cycle
            if (write_tr.overflow != expected_overflow) begin
                `uvm_error(get_type_name(), $sformatf("Overflow mismatch: expected=%b, actual=%b, expected_wr_level = %b", expected_overflow, write_tr.overflow, expected_wr_level))
                error_count++;
            end
            if (write_tr.wfull != expected_wfull) begin
                `uvm_error(get_type_name(), $sformatf("FIFO full state mismatch: expected=%b, actual=%b, expected_wr_level = %b", expected_wfull, write_tr.wfull, expected_wr_level))
                error_count++;
            end
            if (write_tr.wr_almost_ful != expected_wr_almost_ful) begin
                `uvm_error(get_type_name(), $sformatf("Almost full mismatch: expected=%b, actual=%b, expected_wr_level = %b", expected_wr_almost_ful, write_tr.wr_almost_ful, expected_wr_level))
                error_count++;
            end
            // Check FIFO write count - compare against value after this write operation
            if (write_tr.fifo_write_count != (expected_fifo_write_count)) begin
                `uvm_error(get_type_name(), $sformatf("FIFO write count mismatch: expected=%0d, actual=%0d", expected_fifo_write_count, write_tr.fifo_write_count))
                error_count++;
            end
            // Check FIFO write level - compare against value before this write operation
            if (write_tr.wr_level != (expected_wr_level)) begin
                `uvm_error(get_type_name(), $sformatf("FIFO write level mismatch: expected=%0d, actual=%0d", expected_wr_level, write_tr.wr_level))
                error_count++;
            end
        end

        // Check read transaction
        if (read_tr.read_enable && !reset_active) begin
            if (read_tr.underflow != expected_underflow) begin
                `uvm_error(get_type_name(), $sformatf("Underflow mismatch: expected=%b, actual=%b expected_wr_level = %b", expected_underflow, read_tr.underflow, expected_wr_level))
                error_count++;
            end
            if (read_tr.rdempty != expected_rdempty) begin
                `uvm_error(get_type_name(), $sformatf("FIFO empty state mismatch: expected=%b, actual=%b expected_wr_level = %b", expected_rdempty, read_tr.rdempty, expected_wr_level))
                error_count++;
            end
            if (read_tr.rd_almost_empty != expected_rdalmost_empty) begin
                `uvm_error(get_type_name(), $sformatf("Almost empty mismatch: expected=%b, actual=%b expected_wr_level = %b", expected_rdalmost_empty, read_tr.rd_almost_empty, expected_wr_level))
                error_count++;
            end
            // Check FIFO read count - compare against the expected value after this read operation
            // The monitor captures the RTL output at negedge, which shows the count AFTER the current read operation
            // So we compare against expected_fifo_read_count since both monitor and scoreboard show updated values
            if (read_tr.fifo_read_count != expected_fifo_read_count) begin
                `uvm_error(get_type_name(), $sformatf("FIFO read count mismatch: expected=%0d, actual=%0d", expected_fifo_read_count, read_tr.fifo_read_count))
                error_count++;
            end
            // Check FIFO read level - compare against the expected value after this read operation
            // The monitor captures the RTL output at negedge, which shows the level AFTER the current read operation
            // Since rd_level represents empty locations, and a read operation increases empty locations,
            // we compare against expected_rd_level since both monitor and scoreboard show updated values
            if (read_tr.rd_level != expected_rd_level) begin
                `uvm_error(get_type_name(), $sformatf("FIFO read level mismatch: expected=%0d, actual=%0d", expected_rd_level, read_tr.rd_level))
                error_count++;
            end
        end

        write_tr_available = 0;
        read_tr_available = 0;
    endtask

    task process_write_transaction();
        `uvm_info(get_type_name(), $sformatf("Processing write transaction at time %0t: %s", $time, write_tr.sprint), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("Before write: wr_level=%d, rd_level=%d, queue_size=%d, fifo_write_count=%d", expected_wr_level, expected_rd_level, expected_data_queue.size(), expected_fifo_write_count), UVM_HIGH)

        // Check for any active reset
        `uvm_info(get_type_name(), $sformatf("Checking reset: hw_rst=%b, sw_rst=%b, mem_rst=%b", write_tr.hw_rst, write_tr.sw_rst, write_tr.mem_rst), UVM_HIGH)
        if (!write_tr.hw_rst || write_tr.sw_rst || write_tr.mem_rst) begin
            `uvm_info(get_type_name(), "Reset active — clearing scoreboard state", UVM_MEDIUM)
            reset_active = 1;
            // Clear all expected values and queues
            expected_data_queue.delete();
            expected_wr_level           = 0;
            expected_rd_level           = fifo_depth; // Reset to fifo_depth since rd_level = empty locations
            expected_wfull              = 0;
            expected_rdempty            = 1;
            expected_wr_almost_ful      = 0;
            expected_rdalmost_empty     = 0;
            expected_underflow          = 0;
            expected_data               = 0;
            expected_overflow           = 0;
            expected_fifo_write_count   = 0; // Reset write count
            expected_fifo_read_count    = 0; // Reset read count
            `uvm_info(get_type_name(), $sformatf("Reset completed: wr_level=%d, fifo_write_count=%d", expected_wr_level, expected_fifo_write_count), UVM_MEDIUM)
        end else begin
            reset_active = 0;
        end

        // Write operation logic
        if (write_tr.write_enable) begin
            if (!expected_wfull) begin
                // Normal write when not full
                expected_data_queue.push_back(write_tr.wdata);
                write_count++;
                expected_wr_level++; // Increment write level (filled locations)
                expected_rd_level = fifo_depth - expected_wr_level; // Update read level
                expected_fifo_write_count++; // Increment on successful write
                
                `uvm_info(get_type_name(), $sformatf("After write: data=0x%h, wr_level=%d, rd_level=%d, wfull=%b, fifo_write_count=%d", write_tr.wdata, expected_wr_level, expected_rd_level, expected_wfull, expected_fifo_write_count), UVM_HIGH)
            end else begin
                // Write attempted when full - this should trigger overflow
                `uvm_info(get_type_name(), $sformatf("Write attempted when full - overflow expected: data=0x%h, wr_level=%d", write_tr.wdata, expected_wr_level), UVM_HIGH)
            end
        end

        // Update status flags
        expected_wfull         = (expected_wr_level == fifo_depth);
        expected_wr_almost_ful = (expected_wr_level >= write_tr.afull_value);
        expected_overflow      = (expected_wr_level == fifo_depth) && write_tr.write_enable;

        // Check write transaction
        if (write_tr.write_enable) begin
            // Check for overflow
            if (write_tr.overflow != expected_overflow) begin
                `uvm_error(get_type_name(), $sformatf("Overflow mismatch: expected=%b, actual=%b, expected_wr_level = %b", expected_overflow, write_tr.overflow, expected_wr_level))
                error_count++;
            end
            // Check FIFO state consistency
            if (write_tr.wfull != expected_wfull) begin
                `uvm_error(get_type_name(), $sformatf("FIFO full state mismatch: expected=%b, actual=%b, expected_wr_level = %b", expected_wfull, write_tr.wfull, expected_wr_level))
                error_count++;
            end
            // Check almost full
            if (write_tr.wr_almost_ful != expected_wr_almost_ful) begin
                `uvm_error(get_type_name(), $sformatf("Almost full mismatch: expected=%b, actual=%b, expected_wr_level = %b", expected_wr_almost_ful, write_tr.wr_almost_ful, expected_wr_level))
                error_count++;
            end
            // Check FIFO write count - compare against the expected value after this write operation
            // The monitor captures the RTL state at posedge when write_enable is high
            // This represents the state AFTER the write operation has been processed
            `uvm_info(get_type_name(), $sformatf("Comparing write count: expected=%0d, actual=%0d", expected_fifo_write_count, write_tr.fifo_write_count), UVM_HIGH)
            if (write_tr.fifo_write_count != expected_fifo_write_count) begin
                `uvm_error(get_type_name(), $sformatf("FIFO write count mismatch: expected=%0d, actual=%0d", expected_fifo_write_count, write_tr.fifo_write_count))
                error_count++;
            end
            // Check FIFO write level - compare against the expected value after this write operation
            // The monitor captures the RTL state at posedge when write_enable is high
            // This represents the state AFTER the write operation has been processed
            `uvm_info(get_type_name(), $sformatf("Comparing write level: expected=%0d, actual=%0d", expected_wr_level, write_tr.wr_level), UVM_HIGH)
            if (write_tr.wr_level != expected_wr_level) begin
                `uvm_error(get_type_name(), $sformatf("FIFO write level mismatch: expected=%0d, actual=%0d", expected_wr_level, write_tr.wr_level))
                error_count++;
            end
        end

        write_tr_available = 0;
    endtask

    task process_read_transaction();
        `uvm_info(get_type_name(), $sformatf("Processing read transaction at time %0t: %s", $time, read_tr.sprint), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("Before read: wr_level=%d, rd_level=%d, queue_size=%d", expected_wr_level, expected_rd_level, expected_data_queue.size()), UVM_HIGH)

        // Check for any active reset
        if (reset_active) begin
            `uvm_info(get_type_name(), "Reset active — skipping read check", UVM_MEDIUM)
            read_tr_available = 0;
            return;
        end

        if (read_tr.read_enable && !reset_active) begin
            if (expected_data_queue.size() > 0) begin
                expected_data = expected_data_queue.pop_front();
                read_count++;
                if (read_tr.read_data !== expected_data) begin
                    `uvm_error(get_type_name(), $sformatf("Data integrity error: expected=0x%h, actual=0x%h", expected_data, read_tr.read_data))
                    error_count++;
                end
                `uvm_info(get_type_name(), $sformatf("After read: data=0x%h, wr_level=%d, rd_level=%d", expected_data, expected_wr_level, expected_rd_level), UVM_HIGH)
                
                expected_wr_level--; // Decrement write level (filled locations)
                expected_rd_level = fifo_depth - expected_wr_level; // rd_level = empty locations
                expected_fifo_read_count++; // Increment on successful read
            end else begin
                `uvm_error(get_type_name(), "Read attempted but no data available")
                error_count++;
            end

            // Update status flags
            expected_rdempty         = (expected_wr_level == 0);
            expected_rdalmost_empty  = (expected_wr_level <= read_tr.aempty_value); // Use wr_level, not rd_level
            expected_underflow       = (expected_wr_level == 0) && read_tr.read_enable;    

            // Check read transaction
            // Check for underflow
            if (read_tr.underflow != expected_underflow) begin
                `uvm_error(get_type_name(), $sformatf("Underflow mismatch: expected=%b, actual=%b expected_wr_level = %b", expected_underflow, read_tr.underflow, expected_wr_level))
                error_count++;
            end
            // Check FIFO state consistency
            if (read_tr.rdempty != expected_rdempty) begin
                `uvm_error(get_type_name(), $sformatf("FIFO empty state mismatch: expected=%b, actual=%b expected_wr_level = %b", expected_rdempty, read_tr.rdempty, expected_wr_level))
                error_count++;
            end
            // Check almost empty
            if (read_tr.rd_almost_empty != expected_rdalmost_empty) begin
                `uvm_error(get_type_name(), $sformatf("Almost empty mismatch: expected=%b, actual=%b expected_wr_level = %b", expected_rdalmost_empty, read_tr.rd_almost_empty, expected_wr_level))
                error_count++;
            end
            if (read_tr.fifo_read_count != expected_fifo_read_count) begin
                `uvm_error(get_type_name(), $sformatf("FIFO read count mismatch: expected=%0d, actual=%0d", expected_fifo_read_count, read_tr.fifo_read_count))
                error_count++;
            end
            // Check FIFO read level - compare against the expected value after this read operation
            if (read_tr.rd_level != expected_rd_level) begin
                `uvm_error(get_type_name(), $sformatf("FIFO read level mismatch: expected=%0d, actual=%0d", expected_rd_level, read_tr.rd_level))
                error_count++;
            end
        end

        read_tr_available = 0;
    endtask

    task check_fifo_behavior();
        forever begin
            @(posedge $time);
            if (expected_wfull && expected_rdempty) begin
                `uvm_error(get_type_name(), "Invalid FIFO state: both full and empty")
                error_count++;
            end
            // wr_level + rd_level should equal fifo_depth (wr_level = filled, rd_level = empty)
            if (expected_wr_level + expected_rd_level != fifo_depth) begin
                `uvm_error(get_type_name(), $sformatf("FIFO level inconsistency: wr_level=%d, rd_level=%d, total=%d, expected=%d", expected_wr_level, expected_rd_level, expected_wr_level + expected_rd_level, fifo_depth))
                error_count++;
            end
        end
    endtask

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info(get_type_name(), $sformatf("Scoreboard Report:"), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("  Write transactions: %d", write_count), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("  Read transactions: %d", read_count), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("  Errors detected: %d", error_count), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("  Remaining data in queue: %d", expected_data_queue.size()), UVM_LOW)
        if (error_count == 0) begin
            `uvm_info(get_type_name(), "Scoreboard: All checks passed!", UVM_LOW)
        end else begin
            `uvm_error(get_type_name(), $sformatf("Scoreboard: %d errors detected", error_count))
        end
    endfunction
endclass
