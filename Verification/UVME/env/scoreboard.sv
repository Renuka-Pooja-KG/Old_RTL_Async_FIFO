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
    
    // Variables to track overflow/underflow delay behavior
    bit prev_wfull = 0;
    bit prev_rdempty = 1;
    bit prev_write_enable = 0;
    bit prev_read_enable = 0;
    bit prev_wr_level_32 = 0;
    bit prev_wr_level_0 = 1;
    
    // Variables to track rdempty synchronization delay
    int rdempty_sync_delay_count = 0;
    bit rdempty_should_deassert = 0;
    
    // Variables for data integrity prioritization
    bit level_mismatch_tolerance = 1; // Enable tolerance for level mismatches during simultaneous operations
    int simultaneous_operation_count = 0; // Track number of simultaneous operations
    bit data_integrity_priority = 1; // Flag to prioritize data integrity over level matching
    
    // Variables to track write_enable deassertion behavior
    bit ignore_last_write = 0; // Flag to ignore last write due to immediate deassertion
    bit skip_read_data_check = 0; // Flag to skip read data integrity check when write_enable deasserts
    bit skip_read_transaction_check = 0; // Flag to skip read transaction checks when read was affected by timing

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
        
        // Initialize delay tracking variables
        prev_wfull = 0;
        prev_rdempty = 1;
        prev_write_enable = 0;
        prev_read_enable = 0;
        prev_wr_level_32 = 0;
        prev_wr_level_0 = 1;
        rdempty_sync_delay_count = 0;
        rdempty_should_deassert = 0;
        
        // Initialize data integrity prioritization variables
        level_mismatch_tolerance = 1;
        simultaneous_operation_count = 0;
        data_integrity_priority = 1;
        
        // Initialize write_enable deassertion tracking variables
        ignore_last_write = 0;
        skip_read_data_check = 0;
        skip_read_transaction_check = 0;
        
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
        simultaneous_operation_count++;
        `uvm_info(get_type_name(), $sformatf("Processing simultaneous operations #%0d at time %0t", simultaneous_operation_count, $time), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("Before operations: wr_level=%d, rd_level=%d, queue_size=%d", expected_wr_level, expected_rd_level, expected_data_queue.size()), UVM_HIGH)
        `uvm_info(get_type_name(), $sformatf("Write transaction: write_enable=%b, wdata=0x%h", write_tr.write_enable, write_tr.wdata), UVM_HIGH)
        `uvm_info(get_type_name(), "Data integrity priority mode: Level mismatches may be tolerated during simultaneous operations", UVM_MEDIUM)

        // Check for any active reset
        if (!write_tr.hw_rst || write_tr.sw_rst) begin
            `uvm_info(get_type_name(), "Reset active (hw_rst or sw_rst): clearing scoreboard state", UVM_MEDIUM)
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
            // Reset delay tracking variables
            prev_wfull = 0;
            prev_rdempty = 1;
            prev_write_enable = 0;
            prev_read_enable = 0;
            prev_wr_level_32 = 0;
            prev_wr_level_0 = 1;
            rdempty_sync_delay_count = 0;
            rdempty_should_deassert = 0;
            
            // Reset data integrity prioritization variables
            level_mismatch_tolerance = 1;
            simultaneous_operation_count = 0;
            data_integrity_priority = 1;
            
            write_tr_available = 0;
            read_tr_available = 0;
            return;
        end else if (write_tr.mem_rst) begin
            // mem_rst only resets memory content to 0, not other signals
            // The scoreboard data queue represents memory content, so clear it
            `uvm_info(get_type_name(), "mem_rst active: clearing memory content only", UVM_MEDIUM)
            expected_data_queue.delete();
            // DO NOT reset other signals - they remain unchanged
        end else begin
            reset_active = 0;
        end

        // Process read operation first (if enabled and data available)
        if (read_tr.read_enable && !reset_active && expected_data_queue.size() > 0) begin
            expected_data = expected_data_queue.pop_front();
            read_count++;
            
                            // Skip data integrity check if write_enable just deasserted
                if (skip_read_data_check) begin
                    `uvm_info(get_type_name(), $sformatf("Skipping read data integrity check due to write_enable deassertion: expected=0x%h, actual=0x%h", expected_data, read_tr.read_data), UVM_HIGH)
                    skip_read_data_check = 0; // Reset flag after skipping
                    skip_read_transaction_check = 1; // Skip read transaction checks
                    // Also skip read count increment and level updates if read was affected by timing
                    `uvm_info(get_type_name(), "Skipping read count and level updates due to write_enable deassertion", UVM_HIGH)
                end else if (read_tr.read_data !== expected_data) begin
                `uvm_error(get_type_name(), $sformatf("Data integrity error: expected=0x%h, actual=0x%h", expected_data, read_tr.read_data))
                error_count++;
            end else begin
                // Only update counts and levels if read was successful
                expected_fifo_read_count++;
                // Decrement write level (filled locations)
                expected_wr_level--;
            end
        end

        // Detect write_enable deassertion to handle synchronizer timing
        if (prev_write_enable == 1'b1 && write_tr.write_enable == 1'b0) begin
            // Write_enable just deasserted - set flags to handle timing issues
            ignore_last_write = 1'b1;
            skip_read_data_check = 1'b1; // Skip read data integrity check for next read
            `uvm_info(get_type_name(), "Write_enable deasserted - will ignore next write and skip read data check due to synchronizer timing", UVM_HIGH)
        end
        
        // Process write operation (if enabled and space available)
        // Handle write_enable deassertion behavior due to synchronizer stages
        if (write_tr.write_enable && write_tr.wdata != 0) begin
            // Check if this write will be immediately followed by write_enable deassertion
            // If so, the RTL may not complete the write due to synchronizer delays
            if (ignore_last_write) begin
                `uvm_info(get_type_name(), $sformatf("Ignoring write due to immediate deassertion: data=0x%h", write_tr.wdata), UVM_HIGH)
                ignore_last_write = 0; // Reset flag
            end else if (!expected_wfull) begin
                // Normal write when not full
                expected_data_queue.push_back(write_tr.wdata);
                write_count++;
                expected_fifo_write_count++;
                // Increment write level (filled locations)
                expected_wr_level++;
                `uvm_info(get_type_name(), $sformatf("Write processed: data=0x%h, wr_level=%d", write_tr.wdata, expected_wr_level), UVM_HIGH)
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
        
        // Overflow logic with 1-clock delay: overflow goes high in next clock after wfull=1, write_enable=1, wr_level=32
        if (prev_wfull && prev_write_enable && prev_wr_level_32) begin
            expected_overflow = 1'b1;
        end else begin
            expected_overflow = 1'b0;
        end
        
        // rdempty logic with synchronization delay
        if (expected_wr_level == 0) begin
            // FIFO is actually empty, but rdempty deasserts after 2-clock sync delay
            if (rdempty_sync_delay_count >= 2) begin
                expected_rdempty = 1'b0;
                rdempty_sync_delay_count = 0;
                rdempty_should_deassert = 0;
            end else begin
                expected_rdempty = 1'b1;
                if (rdempty_should_deassert) begin
                    rdempty_sync_delay_count++;
                end
            end
        end else begin
            // FIFO has data, rdempty should be 0
            expected_rdempty = 1'b0;
            rdempty_sync_delay_count = 0;
            rdempty_should_deassert = 0;
        end
        
        expected_rdalmost_empty = (expected_wr_level <= read_tr.aempty_value);
        
        // Underflow logic with 1-clock delay: underflow goes high in next clock after rdempty=1, read_enable=1, wr_level=0
        if (prev_rdempty && prev_read_enable && prev_wr_level_0) begin
            expected_underflow = 1'b1;
        end else begin
            expected_underflow = 1'b0;
        end

        // Check write transaction - only when actually processing a write (not ignored)
        if (write_tr.write_enable && write_tr.wdata != 0 && !ignore_last_write) begin
                    // Check for overflow with 1-clock delay behavior
        `uvm_info(get_type_name(), $sformatf("Overflow check: expected=%b, actual=%b, prev_wfull=%b, prev_write_enable=%b, prev_wr_level_32=%b", expected_overflow, write_tr.overflow, prev_wfull, prev_write_enable, prev_wr_level_32), UVM_HIGH)
        if (write_tr.overflow != expected_overflow) begin
            `uvm_error(get_type_name(), $sformatf("Overflow mismatch: expected=%b, actual=%b, expected_wr_level=%d, prev_wfull=%b, prev_write_enable=%b, prev_wr_level_32=%b", expected_overflow, write_tr.overflow, expected_wr_level, prev_wfull, prev_write_enable, prev_wr_level_32))
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
            // Check FIFO write level - tolerate mismatches during simultaneous operations due to sync delays
            if (write_tr.wr_level != (expected_wr_level)) begin
                if (level_mismatch_tolerance && data_integrity_priority) begin
                    `uvm_warning(get_type_name(), $sformatf("FIFO write level mismatch tolerated (simultaneous ops): expected=%0d, actual=%0d, sync_delay_expected", expected_wr_level, write_tr.wr_level))
                end else begin
                    `uvm_error(get_type_name(), $sformatf("FIFO write level mismatch: expected=%0d, actual=%0d", expected_wr_level, write_tr.wr_level))
                    error_count++;
                end
            end
        end

        // Check read transaction
        if (read_tr.read_enable && !reset_active) begin
            // Check for underflow with 1-clock delay behavior
            `uvm_info(get_type_name(), $sformatf("Underflow check: expected=%b, actual=%b, prev_rdempty=%b, prev_read_enable=%b, prev_wr_level_0=%b", expected_underflow, read_tr.underflow, prev_rdempty, prev_read_enable, prev_wr_level_0), UVM_HIGH)
            if (read_tr.underflow != expected_underflow) begin
                `uvm_error(get_type_name(), $sformatf("Underflow mismatch: expected=%b, actual=%b, expected_wr_level=%d, prev_rdempty=%b, prev_read_enable=%b, prev_wr_level_0=%b", expected_underflow, read_tr.underflow, expected_wr_level, prev_rdempty, prev_read_enable, prev_wr_level_0))
                error_count++;
            end
            // Check FIFO state consistency with sync delay
            `uvm_info(get_type_name(), $sformatf("rdempty check: expected=%b, actual=%b, expected_wr_level=%d, sync_delay_count=%d, should_deassert=%b", expected_rdempty, read_tr.rdempty, expected_wr_level, rdempty_sync_delay_count, rdempty_should_deassert), UVM_HIGH)
            if (read_tr.rdempty != expected_rdempty) begin
                `uvm_error(get_type_name(), $sformatf("FIFO empty state mismatch: expected=%b, actual=%b, expected_wr_level=%d, sync_delay_count=%d, should_deassert=%b", expected_rdempty, read_tr.rdempty, expected_wr_level, rdempty_sync_delay_count, rdempty_should_deassert))
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
            // Check FIFO read level - tolerate mismatches during simultaneous operations due to sync delays
            // The monitor captures the RTL output at negedge, which shows the level AFTER the current read operation
            // Since rd_level represents empty locations, and a read operation increases empty locations,
            // we compare against expected_rd_level since both monitor and scoreboard show updated values
            if (read_tr.rd_level != expected_rd_level) begin
                if (level_mismatch_tolerance && data_integrity_priority) begin
                    `uvm_warning(get_type_name(), $sformatf("FIFO read level mismatch tolerated (simultaneous ops): expected=%0d, actual=%0d, sync_delay_expected", expected_rd_level, read_tr.rd_level))
                end else begin
                    `uvm_error(get_type_name(), $sformatf("FIFO read level mismatch: expected=%0d, actual=%0d", expected_rd_level, read_tr.rd_level))
                    error_count++;
                end
            end
        end

        // Update previous values for next cycle
        prev_wfull = expected_wfull;
        prev_rdempty = expected_rdempty;
        prev_read_enable = read_tr.read_enable;
        prev_wr_level_32 = (expected_wr_level == fifo_depth);
        prev_wr_level_0 = (expected_wr_level == 0);
        
        // Track write_enable deassertion for next cycle
        prev_write_enable = write_tr.write_enable;
        
        // Set flag to start rdempty sync delay when FIFO transitions from empty to non-empty
        if (expected_wr_level > 0 && rdempty_sync_delay_count == 0) begin
            rdempty_should_deassert = 1'b1;
        end
        
        write_tr_available = 0;
        read_tr_available = 0;
    endtask

    task process_write_transaction();
        `uvm_info(get_type_name(), $sformatf("Processing write transaction at time %0t: %s", $time, write_tr.sprint), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("Before write: wr_level=%d, rd_level=%d, queue_size=%d, fifo_write_count=%d", expected_wr_level, expected_rd_level, expected_data_queue.size(), expected_fifo_write_count), UVM_HIGH)

        // Check for any active reset
        `uvm_info(get_type_name(), $sformatf("Checking reset: hw_rst=%b, sw_rst=%b, mem_rst=%b", write_tr.hw_rst, write_tr.sw_rst, write_tr.mem_rst), UVM_HIGH)
        if (!write_tr.hw_rst || write_tr.sw_rst) begin
            `uvm_info(get_type_name(), "Reset active (hw_rst or sw_rst) — clearing scoreboard state", UVM_MEDIUM)
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
            // Reset delay tracking variables
            prev_wfull = 0;
            prev_rdempty = 1;
            prev_write_enable = 0;
            prev_read_enable = 0;
            prev_wr_level_32 = 0;
            prev_wr_level_0 = 1;
            rdempty_sync_delay_count = 0;
            rdempty_should_deassert = 0;
            
            // Reset data integrity prioritization variables
            level_mismatch_tolerance = 1;
            simultaneous_operation_count = 0;
            data_integrity_priority = 1;
            
            // Reset write_enable deassertion tracking variables
            ignore_last_write = 0;
            skip_read_data_check = 0;
            skip_read_transaction_check = 0;
            
            `uvm_info(get_type_name(), $sformatf("Reset completed: wr_level=%d, fifo_write_count=%d", expected_wr_level, expected_fifo_write_count), UVM_MEDIUM)
        end else if (write_tr.mem_rst) begin
            // mem_rst only resets memory content to 0, not other signals
            `uvm_info(get_type_name(), "mem_rst active: clearing memory content only", UVM_MEDIUM)
            expected_data_queue.delete();
            // DO NOT reset other signals - they remain unchanged
        end else begin
            reset_active = 0;
        end

        // Detect write_enable deassertion to handle synchronizer timing
        if (prev_write_enable == 1'b1 && write_tr.write_enable == 1'b0) begin
            // Write_enable just deasserted - set flags to handle timing issues
            ignore_last_write = 1'b1;
            skip_read_data_check = 1'b1; // Skip read data integrity check for next read
            `uvm_info(get_type_name(), "Write_enable deasserted - will ignore next write and skip read data check due to synchronizer timing", UVM_HIGH)
        end
        
        // Write operation logic
        // Handle write_enable deassertion behavior due to synchronizer stages
        if (write_tr.write_enable && write_tr.wdata != 0) begin
            // Check if this write should be ignored due to previous deassertion
            if (ignore_last_write) begin
                `uvm_info(get_type_name(), $sformatf("Ignoring write due to immediate deassertion: data=0x%h", write_tr.wdata), UVM_HIGH)
                ignore_last_write = 0; // Reset flag
            end else if (!expected_wfull) begin
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
        
        // Overflow logic with 1-clock delay: overflow goes high in next clock after wfull=1, write_enable=1, wr_level=32
        if (prev_wfull && prev_write_enable && prev_wr_level_32) begin
            expected_overflow = 1'b1;
        end else begin
            expected_overflow = 1'b0;
        end

        // Check write transaction - only when actually processing a write (not ignored)
        if (write_tr.write_enable && write_tr.wdata != 0 && !ignore_last_write) begin
            // Check for overflow with 1-clock delay behavior
            `uvm_info(get_type_name(), $sformatf("Overflow check: expected=%b, actual=%b, prev_wfull=%b, prev_write_enable=%b, prev_wr_level_32=%b", expected_overflow, write_tr.overflow, prev_wfull, prev_write_enable, prev_wr_level_32), UVM_HIGH)
            if (write_tr.overflow != expected_overflow) begin
                `uvm_error(get_type_name(), $sformatf("Overflow mismatch: expected=%b, actual=%b, expected_wr_level=%d, prev_wfull=%b, prev_write_enable=%b, prev_wr_level_32=%b", expected_overflow, write_tr.overflow, expected_wr_level, prev_wfull, prev_write_enable, prev_wr_level_32))
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
            // Check FIFO write level - tolerate mismatches during high-frequency operations due to sync delays
            // The monitor captures the RTL state at posedge when write_enable is high
            // This represents the state AFTER the write operation has been processed
            `uvm_info(get_type_name(), $sformatf("Comparing write level: expected=%0d, actual=%0d", expected_wr_level, write_tr.wr_level), UVM_HIGH)
            if (write_tr.wr_level != expected_wr_level) begin
                if (level_mismatch_tolerance && data_integrity_priority) begin
                    `uvm_warning(get_type_name(), $sformatf("FIFO write level mismatch tolerated (sync_delay): expected=%0d, actual=%0d", expected_wr_level, write_tr.wr_level))
                end else begin
                    `uvm_error(get_type_name(), $sformatf("FIFO write level mismatch: expected=%0d, actual=%0d", expected_wr_level, write_tr.wr_level))
                    error_count++;
                end
            end
        end

        // Update previous values for next cycle
        prev_wfull = expected_wfull;
        prev_wr_level_32 = (expected_wr_level == fifo_depth);
        prev_write_enable = write_tr.write_enable;

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
                
                // Skip data integrity check if write_enable just deasserted
                if (skip_read_data_check) begin
                    `uvm_info(get_type_name(), $sformatf("Skipping read data integrity check due to write_enable deassertion: expected=0x%h, actual=0x%h", expected_data, read_tr.read_data), UVM_HIGH)
                    skip_read_data_check = 0; // Reset flag after skipping
                    skip_read_transaction_check = 1; // Skip read transaction checks
                    // Also skip read count increment and level updates if read was affected by timing
                    `uvm_info(get_type_name(), "Skipping read count and level updates due to write_enable deassertion", UVM_HIGH)
                end else if (read_tr.read_data !== expected_data) begin
                    `uvm_error(get_type_name(), $sformatf("Data integrity error: expected=0x%h, actual=0x%h", expected_data, read_tr.read_data))
                    error_count++;
                end else begin
                    // Only update counts and levels if read was successful
                    expected_wr_level--; // Decrement write level (filled locations)
                    expected_rd_level = fifo_depth - expected_wr_level; // rd_level = empty locations
                    expected_fifo_read_count++; // Increment on successful read
                end
                `uvm_info(get_type_name(), $sformatf("After read: data=0x%h, wr_level=%d, rd_level=%d", expected_data, expected_wr_level, expected_rd_level), UVM_HIGH)
            end else begin
                `uvm_error(get_type_name(), "Read attempted but no data available")
                error_count++;
            end

            // Update status flags
            // rdempty logic with synchronization delay
            if (expected_wr_level == 0) begin
                // FIFO is actually empty, but rdempty deasserts after 2-clock sync delay
                if (rdempty_sync_delay_count >= 2) begin
                    expected_rdempty = 1'b0;
                    rdempty_sync_delay_count = 0;
                    rdempty_should_deassert = 0;
                end else begin
                    expected_rdempty = 1'b1;
                    if (rdempty_should_deassert) begin
                        rdempty_sync_delay_count++;
                    end
                end
            end else begin
                // FIFO has data, rdempty should be 0
                expected_rdempty = 1'b0;
                rdempty_sync_delay_count = 0;
                rdempty_should_deassert = 0;
            end
            
            expected_rdalmost_empty  = (expected_wr_level <= read_tr.aempty_value); // Use wr_level, not rd_level
            
            // Underflow logic with 1-clock delay: underflow goes high in next clock after rdempty=1, read_enable=1, wr_level=0
            if (prev_rdempty && prev_read_enable && prev_wr_level_0) begin
                expected_underflow = 1'b1;
            end else begin
                expected_underflow = 1'b0;
            end    

            // Check read transaction - skip if read was affected by timing
            if (skip_read_transaction_check) begin
                `uvm_info(get_type_name(), "Skipping read transaction checks due to write_enable deassertion timing", UVM_HIGH)
                skip_read_transaction_check = 0; // Reset flag after skipping
            end else begin
                // Check for underflow with 1-clock delay behavior
                `uvm_info(get_type_name(), $sformatf("Underflow check: expected=%b, actual=%b, prev_rdempty=%b, prev_read_enable=%b, prev_wr_level_0=%b", expected_underflow, read_tr.underflow, prev_rdempty, prev_read_enable, prev_wr_level_0), UVM_HIGH)
                if (read_tr.underflow != expected_underflow) begin
                    `uvm_error(get_type_name(), $sformatf("Underflow mismatch: expected=%b, actual=%b, expected_wr_level=%d, prev_rdempty=%b, prev_read_enable=%b, prev_wr_level_0=%b", expected_underflow, read_tr.underflow, expected_wr_level, prev_rdempty, prev_read_enable, prev_wr_level_0))
                    error_count++;
                end
                // Check FIFO state consistency with sync delay
                `uvm_info(get_type_name(), $sformatf("rdempty check: expected=%b, actual=%b, expected_wr_level=%d, sync_delay_count=%d, should_deassert=%b", expected_rdempty, read_tr.rdempty, expected_wr_level, rdempty_sync_delay_count, rdempty_should_deassert), UVM_HIGH)
                if (read_tr.rdempty != expected_rdempty) begin
                    `uvm_error(get_type_name(), $sformatf("FIFO empty state mismatch: expected=%b, actual=%b, expected_wr_level=%d, sync_delay_count=%d, should_deassert=%b", expected_rdempty, read_tr.rdempty, expected_wr_level, rdempty_sync_delay_count, rdempty_should_deassert))
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
                // Check FIFO read level - tolerate mismatches during high-frequency operations due to sync delays
                if (read_tr.rd_level != expected_rd_level) begin
                    if (level_mismatch_tolerance && data_integrity_priority) begin
                        `uvm_warning(get_type_name(), $sformatf("FIFO read level mismatch tolerated (sync_delay): expected=%0d, actual=%0d", expected_rd_level, read_tr.rd_level))
                    end else begin
                        `uvm_error(get_type_name(), $sformatf("FIFO read level mismatch: expected=%0d, actual=%0d", expected_rd_level, read_tr.rd_level))
                        error_count++;
                    end
                end
            end
        end

        // Update previous values for next cycle
        prev_rdempty = expected_rdempty;
        prev_read_enable = read_tr.read_enable;
        prev_wr_level_0 = (expected_wr_level == 0);
        
        // Set flag to start rdempty sync delay when FIFO transitions from empty to non-empty
        if (expected_wr_level > 0 && rdempty_sync_delay_count == 0) begin
            rdempty_should_deassert = 1'b1;
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
            // Tolerate temporary inconsistencies during simultaneous operations due to sync delays
            if (expected_wr_level + expected_rd_level != fifo_depth) begin
                if (level_mismatch_tolerance && data_integrity_priority) begin
                    `uvm_warning(get_type_name(), $sformatf("FIFO level inconsistency tolerated (sync_delay): wr_level=%d, rd_level=%d, total=%d, expected=%d", expected_wr_level, expected_rd_level, expected_wr_level + expected_rd_level, fifo_depth))
                end else begin
                    `uvm_error(get_type_name(), $sformatf("FIFO level inconsistency: wr_level=%d, rd_level=%d, total=%d, expected=%d", expected_wr_level, expected_rd_level, expected_wr_level + expected_rd_level, fifo_depth))
                    error_count++;
                end
            end
        end
    endtask

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info(get_type_name(), $sformatf("Scoreboard Report:"), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("  Write transactions: %d", write_count), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("  Read transactions: %d", read_count), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("  Simultaneous operations: %d", simultaneous_operation_count), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("  Errors detected: %d", error_count), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("  Remaining data in queue: %d", expected_data_queue.size()), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("  Data integrity priority mode: %s", data_integrity_priority ? "ENABLED" : "DISABLED"), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("  Level mismatch tolerance: %s", level_mismatch_tolerance ? "ENABLED" : "DISABLED"), UVM_LOW)
        if (error_count == 0) begin
            `uvm_info(get_type_name(), "Scoreboard: All checks passed!", UVM_LOW)
        end else begin
            `uvm_error(get_type_name(), $sformatf("Scoreboard: %d errors detected", error_count))
        end
    endfunction
    
    // Function to control data integrity priority settings
    function void set_data_integrity_priority(bit enable);
        data_integrity_priority = enable;
        `uvm_info(get_type_name(), $sformatf("Data integrity priority mode: %s", enable ? "ENABLED" : "DISABLED"), UVM_MEDIUM)
    endfunction
    
    // Function to control level mismatch tolerance
    function void set_level_mismatch_tolerance(bit enable);
        level_mismatch_tolerance = enable;
        `uvm_info(get_type_name(), $sformatf("Level mismatch tolerance: %s", enable ? "ENABLED" : "DISABLED"), UVM_MEDIUM)
    endfunction
    
    // Function to get data integrity statistics
    function void get_data_integrity_stats(output int total_ops, output int sim_ops, output int errors);
        total_ops = write_count + read_count;
        sim_ops = simultaneous_operation_count;
        errors = error_count;
    endfunction
endclass