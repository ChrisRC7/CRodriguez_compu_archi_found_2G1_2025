module Spi_slave_module (
    input  logic clk,
    input  logic reset,
    input  logic sclk_in,
    input  logic mosi_in,
    input  logic ss_n_in,
    output logic [3:0] spi_data_out,     // Datos para los LEDs
    output logic spi_data_valid_out, 
    output logic miso_out            
);

    logic sclk_sync1, sclk_sync2;
    logic ss_n_sync1, ss_n_sync2;
    logic mosi_sync1, mosi_sync2;

    wire sclk_rising_edge_event;
    wire ss_n_falling_edge_event;
    wire ss_n_active;

    logic [3:0] shift_reg_mosi;
    wire  [3:0] d_shift_reg_mosi;
    logic [1:0] bit_count_reg;
    wire  [1:0] d_bit_count;
    logic [3:0] data_buffer_reg;
    wire  [3:0] d_data_buffer;
    logic data_valid_pulse_reg;
    wire  d_data_valid_pulse;

    logic [7:0] shift_reg_miso;    
    wire  [7:0] d_shift_reg_miso;

    logic has_loaded_mosi_data_this_frame_reg;
    wire  d_has_loaded_mosi_data_this_frame;

    //Sincronización y Eventos
    assign sclk_rising_edge_event = ~reset & sclk_sync1 & ~sclk_sync2;
    assign ss_n_falling_edge_event = ~reset & ~ss_n_sync1 & ss_n_sync2;
    assign ss_n_active = ~reset & ~ss_n_sync1;

    wire shift_enable;
    assign shift_enable = ss_n_active & sclk_rising_edge_event;

    //Lógica MOSI y Contador de Bits
    wire clear_mosi_shift_reg_condition;
    assign clear_mosi_shift_reg_condition = reset | ss_n_falling_edge_event;

    assign d_shift_reg_mosi[0] = ~clear_mosi_shift_reg_condition & ( (shift_enable & mosi_sync2)      | (~shift_enable & shift_reg_mosi[0]) );
    assign d_shift_reg_mosi[1] = ~clear_mosi_shift_reg_condition & ( (shift_enable & shift_reg_mosi[0]) | (~shift_enable & shift_reg_mosi[1]) );
    assign d_shift_reg_mosi[2] = ~clear_mosi_shift_reg_condition & ( (shift_enable & shift_reg_mosi[1]) | (~shift_enable & shift_reg_mosi[2]) );
    assign d_shift_reg_mosi[3] = ~clear_mosi_shift_reg_condition & ( (shift_enable & shift_reg_mosi[2]) | (~shift_enable & shift_reg_mosi[3]) );

    wire counter_is_3;
    assign counter_is_3 = bit_count_reg[1] & bit_count_reg[0];

    wire reset_counter_condition;
    assign reset_counter_condition = reset | ss_n_falling_edge_event;

    wire increment_counter_condition;
    assign increment_counter_condition = shift_enable & ~counter_is_3;

    wire bit_count_incremented_val_0;
    wire bit_count_incremented_val_1;
    assign bit_count_incremented_val_0 = ~bit_count_reg[0];
    assign bit_count_incremented_val_1 = bit_count_reg[1] ^ bit_count_reg[0];

    assign d_bit_count[0] = ~reset_counter_condition & ( (increment_counter_condition & bit_count_incremented_val_0) | (~increment_counter_condition & bit_count_reg[0]) );
    assign d_bit_count[1] = ~reset_counter_condition & ( (increment_counter_condition & bit_count_incremented_val_1) | (~increment_counter_condition & bit_count_reg[1]) );

    //Carga Única
    wire attempt_to_load_condition;
    assign attempt_to_load_condition = shift_enable & counter_is_3;
    wire actual_mosi_data_load_trigger;
    assign actual_mosi_data_load_trigger = attempt_to_load_condition & ~has_loaded_mosi_data_this_frame_reg;
    wire reset_load_flag;
    assign reset_load_flag = reset | ss_n_falling_edge_event;
    assign d_has_loaded_mosi_data_this_frame = ~reset_load_flag & ( (actual_mosi_data_load_trigger & 1'b1) | (~actual_mosi_data_load_trigger & has_loaded_mosi_data_this_frame_reg) );

    //Carga del Buffer de Datos MOSI
    assign d_data_buffer[0] = ~reset & ( (actual_mosi_data_load_trigger & d_shift_reg_mosi[0]) | (~actual_mosi_data_load_trigger & data_buffer_reg[0]) );
    assign d_data_buffer[1] = ~reset & ( (actual_mosi_data_load_trigger & d_shift_reg_mosi[1]) | (~actual_mosi_data_load_trigger & data_buffer_reg[1]) );
    assign d_data_buffer[2] = ~reset & ( (actual_mosi_data_load_trigger & d_shift_reg_mosi[2]) | (~actual_mosi_data_load_trigger & data_buffer_reg[2]) );
    assign d_data_buffer[3] = ~reset & ( (actual_mosi_data_load_trigger & d_shift_reg_mosi[3]) | (~actual_mosi_data_load_trigger & data_buffer_reg[3]) );

    assign d_data_valid_pulse = ~reset & actual_mosi_data_load_trigger;
	 
    //Registro
    //-------------------------------------------------------------------------
    wire load_miso_condition;
    wire [7:0] byte_to_send_on_miso;

    assign byte_to_send_on_miso = {data_buffer_reg[3:0], 4'b0000}; 


    assign load_miso_condition = reset | ss_n_falling_edge_event | actual_mosi_data_load_trigger;
    wire [7:0] miso_payload_setup;
    assign miso_payload_setup = {data_buffer_reg[3:0], 4'b0000}; 

    assign d_shift_reg_miso[7] = (ss_n_falling_edge_event & miso_payload_setup[7]) | (~ss_n_falling_edge_event & ((shift_enable & shift_reg_miso[6]) | (~shift_enable & shift_reg_miso[7])) ) | (reset & 1'b0);
    assign d_shift_reg_miso[6] = (ss_n_falling_edge_event & miso_payload_setup[6]) | (~ss_n_falling_edge_event & ((shift_enable & shift_reg_miso[5]) | (~shift_enable & shift_reg_miso[6])) ) | (reset & 1'b0);
    assign d_shift_reg_miso[5] = (ss_n_falling_edge_event & miso_payload_setup[5]) | (~ss_n_falling_edge_event & ((shift_enable & shift_reg_miso[4]) | (~shift_enable & shift_reg_miso[5])) ) | (reset & 1'b0);
    assign d_shift_reg_miso[4] = (ss_n_falling_edge_event & miso_payload_setup[4]) | (~ss_n_falling_edge_event & ((shift_enable & shift_reg_miso[3]) | (~shift_enable & shift_reg_miso[4])) ) | (reset & 1'b0);
    assign d_shift_reg_miso[3] = (ss_n_falling_edge_event & miso_payload_setup[3]) | (~ss_n_falling_edge_event & ((shift_enable & shift_reg_miso[2]) | (~shift_enable & shift_reg_miso[3])) ) | (reset & 1'b0);
    assign d_shift_reg_miso[2] = (ss_n_falling_edge_event & miso_payload_setup[2]) | (~ss_n_falling_edge_event & ((shift_enable & shift_reg_miso[1]) | (~shift_enable & shift_reg_miso[2])) ) | (reset & 1'b0);
    assign d_shift_reg_miso[1] = (ss_n_falling_edge_event & miso_payload_setup[1]) | (~ss_n_falling_edge_event & ((shift_enable & shift_reg_miso[0]) | (~shift_enable & shift_reg_miso[1])) ) | (reset & 1'b0);
    assign d_shift_reg_miso[0] = (ss_n_falling_edge_event & miso_payload_setup[0]) | (~ss_n_falling_edge_event & ((shift_enable & 1'b0)             | (~shift_enable & shift_reg_miso[0])) ) | (reset & 1'b0);
  

    //Salida del Módulo
    assign spi_data_out       = data_buffer_reg;    // Datos para los LEDs
    assign spi_data_valid_out = data_valid_pulse_reg; // Pulso cuando spi_data_out es válido
    assign miso_out           = shift_reg_miso[7];  // Envía el MSB del registro de MISO


    //Bloque de Registros Síncronos
    always_ff @(posedge clk) begin
        sclk_sync1 <= sclk_in;
        sclk_sync2 <= sclk_sync1;
        ss_n_sync1 <= ss_n_in;
        ss_n_sync2 <= ss_n_sync1;
        mosi_sync1 <= mosi_in;
        mosi_sync2 <= mosi_sync1;

        shift_reg_mosi <= d_shift_reg_mosi;
        bit_count_reg  <= d_bit_count;
        has_loaded_mosi_data_this_frame_reg <= d_has_loaded_mosi_data_this_frame;
        data_buffer_reg <= d_data_buffer;
        data_valid_pulse_reg <= d_data_valid_pulse;
        shift_reg_miso <= d_shift_reg_miso;
    end
endmodule