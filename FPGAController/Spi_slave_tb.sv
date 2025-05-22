// Testbench for FpgaController
`timescale 1ns / 1ps

module Spi_slave_tb;

    // Testbench Parameters
    localparam CLK_PERIOD_FPGA = 20;  // Period for FPGA_clk (e.g., 50MHz)
    localparam SCLK_PERIOD_SPI = 200; // Period for SPI SCLK (e.g., 5MHz)
                                      // Must be multiple of CLK_PERIOD_FPGA for simple relation
                                      // and significantly slower. SCLK_PERIOD_SPI should be >= 2*CLK_PERIOD_FPGA * 8 (for 8 bits minimum)
                                      // Let's make SCLK much slower: 200ns (5MHz) vs FPGA clk 20ns (50MHz)

    // Signals to connect to the DUT (FpgaController)
    logic FPGA_clk_tb;
    logic FPGA_reset_tb;
    logic arduino_sclk_tb;
    logic arduino_mosi_tb;
    logic arduino_ss_n_tb;

    logic fpga_physical_miso_dut;
    logic [3:0] led_outputs_dut;
    logic [6:0] seven_segment_pins_dut;

    // Internal Testbench signals
    logic [3:0] data_to_send_mcu;         // 4-bit data MCU intends to send
    logic [7:0] byte_to_send_mosi_tb;     // 8-bit MOSI data (4-bit data in MSBs)
    logic [7:0] byte_received_miso_tb;    // 8-bit MISO data received by MCU
    logic [3:0] previous_led_data_tb;     // Stores LED data from the PREVIOUS transaction for MISO check
    string      current_test_case_name;

    // For capturing the data_valid pulse from the SPI slave within FpgaController
    // The FpgaController doesn't directly output the spi_data_valid_out,
    // but we can infer its occurrence by checking led_outputs_dut.
    // If precise checking of data_is_valid_from_spi (internal to FpgaController) is needed,
    // that signal would need to be an output of FpgaController or use $root.path.to.signal.

    // Instantiation of the Device Under Test (DUT)
    FpgaController dut (
        .FPGA_clk(FPGA_clk_tb),
        .FPGA_reset(FPGA_reset_tb),
        .arduino_sclk(arduino_sclk_tb),
        .arduino_mosi(arduino_mosi_tb),
        .arduino_ss_n(arduino_ss_n_tb),
        .fpga_physical_miso(fpga_physical_miso_dut),
        .led_outputs(led_outputs_dut),
        .seven_segment_pins(seven_segment_pins_dut)
    );

    // FPGA Clock Generator
    always begin
        FPGA_clk_tb = 1'b0;
        #(CLK_PERIOD_FPGA / 2);
        FPGA_clk_tb = 1'b1;
        #(CLK_PERIOD_FPGA / 2);
    end

    // SPI Transfer Task (Master perspective: sends 8 bits, receives 8 bits)
    // Assumes SPI Mode 0 (CPOL=0, CPHA=0)
    task spi_transfer_byte;
        input  [7:0] data_to_send_master;
        output [7:0] data_received_master;
        integer i;

        data_received_master = 8'b0;
        arduino_sclk_tb = 1'b0; // Ensure SCLK starts low

        for (i = 0; i < 8; i = i + 1) begin
            // Set MOSI: Data is stable before SCLK rising edge
            arduino_mosi_tb = data_to_send_master[7-i]; // MSB first

            #(SCLK_PERIOD_SPI / 2); // Half period for setup

            // SCLK Rising Edge: Slave samples MOSI, Master samples MISO
            arduino_sclk_tb = 1'b1;
            #1; // Small delay for MISO to be valid from slave
            data_received_master = (data_received_master << 1) | fpga_physical_miso_dut;
            #(SCLK_PERIOD_SPI / 2 - 1);

            // SCLK Falling Edge
            arduino_sclk_tb = 1'b0;
        end
        arduino_mosi_tb = 1'bz; // MOSI high-Z after transfer
    endtask

    // Function to decode 4-bit hex to 7-segment common anode (0 = ON)
    // Uses standard 7-segment mapping: (a,b,c,d,e,f,g)
	 function automatic logic [6:0] decode_hex_to_7seg_common_anode (input logic [3:0] hex_in);
		 logic [6:0] segments_cc; // Common Cathode (1=ON)

		 case (hex_in)
			  // Formato del literal: 7'b<g><f><e><d><c><b><a>
			  4'h0: segments_cc = 7'b0111111; // a,b,c,d,e,f
			  4'h1: segments_cc = 7'b0000110; // b,c
			  4'h2: segments_cc = 7'b1011011; // a,b,d,e,g
			  4'h3: segments_cc = 7'b1001111; // a,b,c,d,g
			  4'h4: segments_cc = 7'b1100110; // b,c,f,g
			  4'h5: segments_cc = 7'b1101101; // a,c,d,f,g
			  4'h6: segments_cc = 7'b1111101; // a,c,d,e,f,g (o b,c,d,e,f,g para algunos '6')
			  4'h7: segments_cc = 7'b0000111; // a,b,c
			  4'h8: segments_cc = 7'b1111111; // a,b,c,d,e,f,g
			  4'h9: segments_cc = 7'b1101111; // a,b,c,d,f,g
			  4'hA: segments_cc = 7'b1110111; // a,b,c,e,f,g ('A')
			  4'hB: segments_cc = 7'b1111100; // c,d,e,f,g   ('b')
			  4'hC: segments_cc = 7'b0111001; // a,d,e,f     ('C' - forma clásica, o L-shape 7'b1001110)
			  4'hD: segments_cc = 7'b1011110; // b,c,d,e,g   ('d')
			  4'hE: segments_cc = 7'b1111001; // a,d,e,f,g   ('E')
			  4'hF: segments_cc = 7'b1110001; // a,e,f,g     ('F')
			  default: segments_cc = 7'b0000000; // Apagado
		 endcase
		 return ~segments_cc; // Invertir para común ánodo (0=ON)
	endfunction

    // Task to check transaction results
    task check_transaction;
        input string    test_name;
        input logic [3:0] sent_data_4bit_current; // Data sent in current MOSI
        input logic [7:0] full_mosi_byte_sent_current;
        input logic [3:0] prev_led_data_for_miso_exp; // LED data from PREVIOUS transaction

        // DUT outputs are read directly for check after settling
        logic [7:0] expected_miso_byte;
        logic [3:0] expected_led_outputs;
        logic [6:0] expected_7seg_pins;
        automatic bit error_found = 0;

        $display("\n--- Test Case: %s ---", test_name);
        $display("Time: %0t ns", $time);
        $display("MCU Sent MOSI (4-bit data): 4'b%b (0x%h)", sent_data_4bit_current, sent_data_4bit_current);
        $display("MCU Sent MOSI (full byte):  8'b%b (0x%h)", full_mosi_byte_sent_current, full_mosi_byte_sent_current);

        // 1. Check MISO (echo of previous LED data)
        expected_miso_byte = {prev_led_data_for_miso_exp, 4'b0000};
        $display("MISO Expected by MCU (based on prev LED %h): 8'b%b (0x%h)", prev_led_data_for_miso_exp, expected_miso_byte, expected_miso_byte);
        $display("MISO Received by MCU:                     8'b%b (0x%h)", byte_received_miso_tb, byte_received_miso_tb);
        if (byte_received_miso_tb === expected_miso_byte) begin
            $display("MISO Check: PASSED");
        end else begin
            $error("MISO Check: FAILED");
            error_found = 1;
        end

        // 2. Check LED Outputs (should reflect current MOSI data)
        expected_led_outputs = sent_data_4bit_current;
        $display("LED Output Expected (current data): 4'b%b (0x%h)", expected_led_outputs, expected_led_outputs);
        $display("LED Output Actual from DUT:         4'b%b (0x%h)", led_outputs_dut, led_outputs_dut);
        if (led_outputs_dut === expected_led_outputs) begin
            $display("LED Output Check: PASSED");
        end else begin
            $error("LED Output Check: FAILED");
            error_found = 1;
        end

        // 3. Check 7-Segment Display Pins (based on current LED/MOSI data)
        expected_7seg_pins = decode_hex_to_7seg_common_anode(led_outputs_dut); // Use actual led_outputs_dut for decoder input
        $display("7-Seg Pins Expected (for 0x%h CA): 7'b%b (a=%b,b=%b,c=%b,d=%b,e=%b,f=%b,g=%b)",
                               led_outputs_dut, expected_7seg_pins,
                               expected_7seg_pins[0], expected_7seg_pins[1], expected_7seg_pins[2],
                               expected_7seg_pins[3], expected_7seg_pins[4], expected_7seg_pins[5],
                               expected_7seg_pins[6]);
        $display("7-Seg Pins Actual from DUT:        7'b%b (a=%b,b=%b,c=%b,d=%b,e=%b,f=%b,g=%b)",
                               seven_segment_pins_dut,
                               seven_segment_pins_dut[0], seven_segment_pins_dut[1], seven_segment_pins_dut[2],
                               seven_segment_pins_dut[3], seven_segment_pins_dut[4], seven_segment_pins_dut[5],
                               seven_segment_pins_dut[6]);
        if (seven_segment_pins_dut === expected_7seg_pins) begin
            $display("7-Segment Pins Check: PASSED");
        end else begin
            $error("7-Segment Pins Check: FAILED");
            error_found = 1;
        end

        // Note: Checking the 'spi_data_valid_out' pulse directly is tricky without making it an output
        // or using hierarchical references. Correctness of 'led_outputs_dut' implies it pulsed.
        if(error_found) begin
            $display("--- Test Case: %s FAILED ---", test_name);
        end else begin
            $display("--- Test Case: %s PASSED ---", test_name);
        end

    endtask

    // Main Test Procedure
    initial begin
        $display("===================================================");
        $display("  STARTING SIMULATION for FpgaController ");
        $display("===================================================");

        // Initialize signals
        FPGA_clk_tb     = 1'b0;
        FPGA_reset_tb   = 1'b1; // Assert reset
        arduino_sclk_tb = 1'b0; // SPI Clock idle low
        arduino_mosi_tb = 1'bz; // MOSI high-Z
        arduino_ss_n_tb = 1'b1; // Slave Select inactive high
        previous_led_data_tb = 4'b0000; // LEDs are off (or 0) after reset

        #(CLK_PERIOD_FPGA * 10); // Hold reset for some cycles
        FPGA_reset_tb = 1'b0;   // De-assert reset
        $display("Time: %0t ns - Reset Released.", $time);
        #(CLK_PERIOD_FPGA * 10); // Wait for reset to propagate

        // --- Test Case 1: Send 4'h5 (0101) ---
        current_test_case_name = "Send 4'h5 (0101)";
        data_to_send_mcu = 4'h5;
        byte_to_send_mosi_tb = {data_to_send_mcu, 4'b0000}; // MOSI format LLLL0000

        arduino_ss_n_tb = 1'b0; // Activate Slave Select
        $display("Time: %0t ns - %s: SS_n LOW, MOSI byte 8'b%b", $time, current_test_case_name, byte_to_send_mosi_tb);
        #(CLK_PERIOD_FPGA); // Ensure slave sees SS_n active

        spi_transfer_byte(byte_to_send_mosi_tb, byte_received_miso_tb);

        arduino_ss_n_tb = 1'b1; // Deactivate Slave Select
        $display("Time: %0t ns - %s: SS_n HIGH, MISO byte received 8'b%b", $time, current_test_case_name, byte_received_miso_tb);
        #(CLK_PERIOD_FPGA * 5); // Allow outputs to settle

        check_transaction(current_test_case_name, data_to_send_mcu, byte_to_send_mosi_tb, previous_led_data_tb);
        previous_led_data_tb = data_to_send_mcu; // Update for next MISO check
        #(SCLK_PERIOD_SPI * 2); // Delay between tests


        // --- Test Case 2: Send 4'hA (1010) ---
        current_test_case_name = "Send 4'hA (1010)";
        data_to_send_mcu = 4'hA;
        byte_to_send_mosi_tb = {data_to_send_mcu, 4'b0000};

        arduino_ss_n_tb = 1'b0;
        $display("Time: %0t ns - %s: SS_n LOW, MOSI byte 8'b%b", $time, current_test_case_name, byte_to_send_mosi_tb);
        #(CLK_PERIOD_FPGA);

        spi_transfer_byte(byte_to_send_mosi_tb, byte_received_miso_tb);

        arduino_ss_n_tb = 1'b1;
        $display("Time: %0t ns - %s: SS_n HIGH, MISO byte received 8'b%b", $time, current_test_case_name, byte_received_miso_tb);
        #(CLK_PERIOD_FPGA * 5);

        check_transaction(current_test_case_name, data_to_send_mcu, byte_to_send_mosi_tb, previous_led_data_tb);
        previous_led_data_tb = data_to_send_mcu;
        #(SCLK_PERIOD_SPI * 2);


        // --- Test Case 3: Send 4'hF (1111) ---
        current_test_case_name = "Send 4'hF (1111)";
        data_to_send_mcu = 4'hF;
        byte_to_send_mosi_tb = {data_to_send_mcu, 4'b0000};

        arduino_ss_n_tb = 1'b0;
        $display("Time: %0t ns - %s: SS_n LOW, MOSI byte 8'b%b", $time, current_test_case_name, byte_to_send_mosi_tb);
        #(CLK_PERIOD_FPGA);

        spi_transfer_byte(byte_to_send_mosi_tb, byte_received_miso_tb);

        arduino_ss_n_tb = 1'b1;
        $display("Time: %0t ns - %s: SS_n HIGH, MISO byte received 8'b%b", $time, current_test_case_name, byte_received_miso_tb);
        #(CLK_PERIOD_FPGA * 5);

        check_transaction(current_test_case_name, data_to_send_mcu, byte_to_send_mosi_tb, previous_led_data_tb);
        previous_led_data_tb = data_to_send_mcu;
        #(SCLK_PERIOD_SPI * 2);


        // --- Test Case 4: Send 4'h0 (0000) ---
        current_test_case_name = "Send 4'h0 (0000)";
        data_to_send_mcu = 4'h0;
        byte_to_send_mosi_tb = {data_to_send_mcu, 4'b0000};

        arduino_ss_n_tb = 1'b0;
        $display("Time: %0t ns - %s: SS_n LOW, MOSI byte 8'b%b", $time, current_test_case_name, byte_to_send_mosi_tb);
        #(CLK_PERIOD_FPGA);

        spi_transfer_byte(byte_to_send_mosi_tb, byte_received_miso_tb);

        arduino_ss_n_tb = 1'b1;
        $display("Time: %0t ns - %s: SS_n HIGH, MISO byte received 8'b%b", $time, current_test_case_name, byte_received_miso_tb);
        #(CLK_PERIOD_FPGA * 5);

        check_transaction(current_test_case_name, data_to_send_mcu, byte_to_send_mosi_tb, previous_led_data_tb);
        previous_led_data_tb = data_to_send_mcu;
        #(SCLK_PERIOD_SPI * 2);


        $display("\n===================================================");
        $display("  SIMULATION FINISHED for FpgaController ");
        $display("===================================================");
        $finish;
    end

endmodule