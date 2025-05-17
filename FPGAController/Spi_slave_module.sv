//-----------------------------------------------------------------------------
// Modulo Spi_slave_module (CORRECCIÓN FINAL con FLAG para CARGA ÚNICA)
//
// Descripcion:
//   Modulo esclavo SPI estructural para recibir 4 bits de datos (MOSI)
//   y enviar un byte de acknowledgement (MISO). Evita la sobrescritura
//   del buffer de datos MOSI.
//-----------------------------------------------------------------------------
module Spi_slave_module (
    input  logic clk,
    input  logic reset,
    input  logic sclk_in,
    input  logic mosi_in,
    input  logic ss_n_in,
    output logic [3:0] spi_data_out,
    output logic spi_data_valid_out,
    output logic miso_out
);

    localparam ACK_BYTE = 8'h00;

    // Sincronizadores
    logic sclk_sync1, sclk_sync2;
    logic ss_n_sync1, ss_n_sync2;
    logic mosi_sync1, mosi_sync2;

    // Eventos y estados
    wire sclk_rising_edge_event;
    wire ss_n_falling_edge_event; // Pulso cuando ss_n baja
    wire ss_n_active;             // Nivel, ss_n está bajo

    // Lógica MOSI
    logic [3:0] shift_reg_mosi;
    wire  [3:0] d_shift_reg_mosi;
    logic [1:0] bit_count_reg;      // Cuenta 0, 1, 2, 3 para los 4 bits de datos MOSI
    wire  [1:0] d_bit_count;
    logic [3:0] data_buffer_reg;
    wire  [3:0] d_data_buffer;
    logic data_valid_pulse_reg;     // Se convertirá en spi_data_valid_out
    wire  d_data_valid_pulse;

    // Lógica MISO
    logic [7:0] shift_reg_miso;
    wire  [7:0] d_shift_reg_miso;

    // --- NUEVO: Flag para asegurar una sola carga del data_buffer_reg por transacción SS_n ---
    logic has_loaded_mosi_data_this_frame_reg;
    wire  d_has_loaded_mosi_data_this_frame;

    //-------------------------------------------------------------------------
    // 1. Sincronización y Detección de Eventos
    //-------------------------------------------------------------------------
    assign sclk_rising_edge_event = ~reset & sclk_sync1 & ~sclk_sync2;
    assign ss_n_falling_edge_event = ~reset & ~ss_n_sync1 & ss_n_sync2; // Pulso en flanco de bajada de ss_n
    assign ss_n_active = ~reset & ~ss_n_sync1;                         // Nivel (ss_n está bajo)

    //-------------------------------------------------------------------------
    // 2. Lógica del Registro de Desplazamiento MOSI (igual que antes)
    //-------------------------------------------------------------------------
    wire shift_enable;
    assign shift_enable = ss_n_active & sclk_rising_edge_event;

    wire clear_mosi_shift_reg_condition; // Renombrado para claridad
    assign clear_mosi_shift_reg_condition = reset | ss_n_falling_edge_event;

    assign d_shift_reg_mosi[0] = ~clear_mosi_shift_reg_condition & ( (shift_enable & mosi_sync2)      | (~shift_enable & shift_reg_mosi[0]) );
    assign d_shift_reg_mosi[1] = ~clear_mosi_shift_reg_condition & ( (shift_enable & shift_reg_mosi[0]) | (~shift_enable & shift_reg_mosi[1]) );
    assign d_shift_reg_mosi[2] = ~clear_mosi_shift_reg_condition & ( (shift_enable & shift_reg_mosi[1]) | (~shift_enable & shift_reg_mosi[2]) );
    assign d_shift_reg_mosi[3] = ~clear_mosi_shift_reg_condition & ( (shift_enable & shift_reg_mosi[2]) | (~shift_enable & shift_reg_mosi[3]) );

    //-------------------------------------------------------------------------
    // 3. Lógica del Contador de Bits (para los 4 bits de MOSI)
    //-------------------------------------------------------------------------
    wire counter_is_3; // Verdadero si bit_count_reg es 3 (11_binary)
    assign counter_is_3 = bit_count_reg[1] & bit_count_reg[0];

    wire reset_counter_condition;
    assign reset_counter_condition = reset | ss_n_falling_edge_event;

    // El contador incrementa si shift_enable es verdadero Y el contador no es actualmente 3.
    // Se detiene en 3.
    wire increment_counter_condition;
    assign increment_counter_condition = shift_enable & ~counter_is_3;

    wire bit_count_incremented_val_0;
    wire bit_count_incremented_val_1;
    assign bit_count_incremented_val_0 = ~bit_count_reg[0];
    assign bit_count_incremented_val_1 = bit_count_reg[1] ^ bit_count_reg[0];

    assign d_bit_count[0] = ~reset_counter_condition & ( (increment_counter_condition & bit_count_incremented_val_0) | (~increment_counter_condition & bit_count_reg[0]) );
    assign d_bit_count[1] = ~reset_counter_condition & ( (increment_counter_condition & bit_count_incremented_val_1) | (~increment_counter_condition & bit_count_reg[1]) );

    //-------------------------------------------------------------------------
    // 4. Lógica del Buffer de Datos MOSI y Pulso de Validez -- CON FLAG DE CARGA ÚNICA
    //-------------------------------------------------------------------------
    wire attempt_to_load_condition; // Condición base para cargar (4to bit)
    assign attempt_to_load_condition = shift_enable & counter_is_3;

    wire actual_mosi_data_load_trigger; // Condición final para cargar el buffer MOSI
    // Carga solo si es el momento correcto (attempt_to_load) Y no se ha cargado ya en esta trama.
    assign actual_mosi_data_load_trigger = attempt_to_load_condition & ~has_loaded_mosi_data_this_frame_reg;

    // Lógica para el flag 'has_loaded_mosi_data_this_frame_reg'
    // Se resetea a 0 con el reset global o cuando ss_n baja (inicio de nueva trama).
    // Se pone a 1 cuando ocurre 'actual_mosi_data_load_trigger'.
    wire reset_load_flag;
    assign reset_load_flag = reset | ss_n_falling_edge_event;

    assign d_has_loaded_mosi_data_this_frame = ~reset_load_flag & ( // Si no hay reset del flag...
                                                 (actual_mosi_data_load_trigger & 1'b1) | // ...ponlo a 1 si ocurre el trigger de carga
                                                 (~actual_mosi_data_load_trigger & has_loaded_mosi_data_this_frame_reg) // ...o mantenlo
                                               );
    // Si reset_load_flag es 1, entonces d_has_loaded_mosi_data_this_frame será 0.

    // Carga data_buffer_reg usando el trigger de carga única
    assign d_data_buffer[0] = ~reset & ( (actual_mosi_data_load_trigger & d_shift_reg_mosi[0]) | (~actual_mosi_data_load_trigger & data_buffer_reg[0]) );
    assign d_data_buffer[1] = ~reset & ( (actual_mosi_data_load_trigger & d_shift_reg_mosi[1]) | (~actual_mosi_data_load_trigger & data_buffer_reg[1]) );
    assign d_data_buffer[2] = ~reset & ( (actual_mosi_data_load_trigger & d_shift_reg_mosi[2]) | (~actual_mosi_data_load_trigger & data_buffer_reg[2]) );
    assign d_data_buffer[3] = ~reset & ( (actual_mosi_data_load_trigger & d_shift_reg_mosi[3]) | (~actual_mosi_data_load_trigger & data_buffer_reg[3]) );

    // El pulso de validez también se genera con el trigger de carga única.
    assign d_data_valid_pulse = ~reset & actual_mosi_data_load_trigger;

    //-------------------------------------------------------------------------
    // 5. Lógica del Registro de Desplazamiento MISO (para enviar ACK_BYTE) - Sin cambios
    //-------------------------------------------------------------------------
    wire load_ack_condition;
    assign load_ack_condition = reset | ss_n_falling_edge_event;

    assign d_shift_reg_miso[7] = (load_ack_condition & ACK_BYTE[7]) | (~load_ack_condition & ((shift_enable & shift_reg_miso[6]) | (~shift_enable & shift_reg_miso[7])) );
    assign d_shift_reg_miso[6] = (load_ack_condition & ACK_BYTE[6]) | (~load_ack_condition & ((shift_enable & shift_reg_miso[5]) | (~shift_enable & shift_reg_miso[6])) );
    assign d_shift_reg_miso[5] = (load_ack_condition & ACK_BYTE[5]) | (~load_ack_condition & ((shift_enable & shift_reg_miso[4]) | (~shift_enable & shift_reg_miso[5])) );
    assign d_shift_reg_miso[4] = (load_ack_condition & ACK_BYTE[4]) | (~load_ack_condition & ((shift_enable & shift_reg_miso[3]) | (~shift_enable & shift_reg_miso[4])) );
    assign d_shift_reg_miso[3] = (load_ack_condition & ACK_BYTE[3]) | (~load_ack_condition & ((shift_enable & shift_reg_miso[2]) | (~shift_enable & shift_reg_miso[3])) );
    assign d_shift_reg_miso[2] = (load_ack_condition & ACK_BYTE[2]) | (~load_ack_condition & ((shift_enable & shift_reg_miso[1]) | (~shift_enable & shift_reg_miso[2])) );
    assign d_shift_reg_miso[1] = (load_ack_condition & ACK_BYTE[1]) | (~load_ack_condition & ((shift_enable & shift_reg_miso[0]) | (~shift_enable & shift_reg_miso[1])) );
    assign d_shift_reg_miso[0] = (load_ack_condition & ACK_BYTE[0]) | (~load_ack_condition & ((shift_enable & 1'b0)            | (~shift_enable & shift_reg_miso[0])) );

    //-------------------------------------------------------------------------
    // 6. Asignaciones de Salida del Módulo
    //-------------------------------------------------------------------------
    assign spi_data_out       = data_buffer_reg;
    assign spi_data_valid_out = data_valid_pulse_reg;
    assign miso_out           = shift_reg_miso[7];

    //-------------------------------------------------------------------------
    // 7. Bloque de Registros Síncronos
    //-------------------------------------------------------------------------
    always_ff @(posedge clk) begin
        // Sincronizadores de entrada
        sclk_sync1 <= sclk_in;
        sclk_sync2 <= sclk_sync1;
        ss_n_sync1 <= ss_n_in;
        ss_n_sync2 <= ss_n_sync1;
        mosi_sync1 <= mosi_in;
        mosi_sync2 <= mosi_sync1;

        // Actualización de registros MOSI
        shift_reg_mosi[0] <= d_shift_reg_mosi[0];
        shift_reg_mosi[1] <= d_shift_reg_mosi[1];
        shift_reg_mosi[2] <= d_shift_reg_mosi[2];
        shift_reg_mosi[3] <= d_shift_reg_mosi[3];

        bit_count_reg[0] <= d_bit_count[0];
        bit_count_reg[1] <= d_bit_count[1];
        
        has_loaded_mosi_data_this_frame_reg <= d_has_loaded_mosi_data_this_frame; // Actualizar el flag

        data_buffer_reg[0] <= d_data_buffer[0];
        data_buffer_reg[1] <= d_data_buffer[1];
        data_buffer_reg[2] <= d_data_buffer[2];
        data_buffer_reg[3] <= d_data_buffer[3];

        data_valid_pulse_reg <= d_data_valid_pulse;

        // Actualización de registro MISO
        shift_reg_miso[0] <= d_shift_reg_miso[0];
        shift_reg_miso[1] <= d_shift_reg_miso[1];
        shift_reg_miso[2] <= d_shift_reg_miso[2];
        shift_reg_miso[3] <= d_shift_reg_miso[3];
        shift_reg_miso[4] <= d_shift_reg_miso[4];
        shift_reg_miso[5] <= d_shift_reg_miso[5];
        shift_reg_miso[6] <= d_shift_reg_miso[6];
        shift_reg_miso[7] <= d_shift_reg_miso[7];
    end

endmodule