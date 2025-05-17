//-----------------------------------------------------------------------------
// Modulo Spi_slave_module (con MISO para Handshake ACK y CORRECCIÓN FINAL en load condition)
//
// Descripcion:
//   Modulo esclavo SPI estructural para recibir 4 bits de datos (MOSI)
//   y enviar un byte de acknowledgement (MISO).
//   Cumple con restricciones de no usar 'if', 'case', operador ternario.
//   Opera con el reloj 'clk' del sistema FPGA.
//-----------------------------------------------------------------------------
module Spi_slave_module ( // Asegúrate que este nombre coincida con tu archivo y las instancias
    input  logic clk,
    input  logic reset,
    input  logic sclk_in,
    input  logic mosi_in,
    input  logic ss_n_in,
    output logic [3:0] spi_data_out,
    output logic spi_data_valid_out,
    output logic miso_out
);

    // Definición del byte de Acknowledgement que la FPGA enviará
    localparam ACK_BYTE = 8'hA5;

    // Registros para sincronizar entradas asíncronas SPI con 'clk'
    logic sclk_sync1, sclk_sync2;
    logic ss_n_sync1, ss_n_sync2;
    logic mosi_sync1, mosi_sync2;

    // Wires para eventos y estados derivados
    wire sclk_rising_edge_event;
    wire ss_n_falling_edge_event;
    wire ss_n_active;

    // --- Lógica MOSI (Recepción de datos) ---
    logic [3:0] shift_reg_mosi;
    wire  [3:0] d_shift_reg_mosi;
    logic [1:0] bit_count_reg;      // Cuenta los bits recibidos: 0, 1, 2, 3
    wire  [1:0] d_bit_count;
    logic [3:0] data_buffer_reg;
    wire  [3:0] d_data_buffer;
    logic data_valid_pulse_reg;
    wire  d_data_valid_pulse;

    // --- Lógica MISO (Envío de ACK) ---
    logic [7:0] shift_reg_miso;
    wire  [7:0] d_shift_reg_miso;

    //-------------------------------------------------------------------------
    // 1. Sincronización y Detección de Eventos
    //-------------------------------------------------------------------------
    assign sclk_rising_edge_event = ~reset & sclk_sync1 & ~sclk_sync2;
    assign ss_n_falling_edge_event = ~reset & ~ss_n_sync1 & ss_n_sync2;
    assign ss_n_active = ~reset & ~ss_n_sync1;

    //-------------------------------------------------------------------------
    // 2. Lógica del Registro de Desplazamiento MOSI
    //-------------------------------------------------------------------------
    wire shift_enable;
    assign shift_enable = ss_n_active & sclk_rising_edge_event;

    wire clear_mosi_logic_condition;
    assign clear_mosi_logic_condition = reset | ss_n_falling_edge_event;

    assign d_shift_reg_mosi[0] = ~clear_mosi_logic_condition & ( (shift_enable & mosi_sync2)      | (~shift_enable & shift_reg_mosi[0]) );
    assign d_shift_reg_mosi[1] = ~clear_mosi_logic_condition & ( (shift_enable & shift_reg_mosi[0]) | (~shift_enable & shift_reg_mosi[1]) );
    assign d_shift_reg_mosi[2] = ~clear_mosi_logic_condition & ( (shift_enable & shift_reg_mosi[1]) | (~shift_enable & shift_reg_mosi[2]) );
    assign d_shift_reg_mosi[3] = ~clear_mosi_logic_condition & ( (shift_enable & shift_reg_mosi[2]) | (~shift_enable & shift_reg_mosi[3]) );

    //-------------------------------------------------------------------------
    // 3. Lógica del Contador de Bits (para los 4 bits de MOSI)
    //-------------------------------------------------------------------------
    wire counter_is_3; // Verdadero si bit_count_reg es 3 (11_binary)
    assign counter_is_3 = bit_count_reg[1] & bit_count_reg[0];

    wire reset_counter_condition;
    assign reset_counter_condition = reset | ss_n_falling_edge_event;

    // El contador incrementa si shift_enable es verdadero Y el contador no es actualmente 3.
    // Esto asegura que cuente 0->1, 1->2, 2->3.
    // Cuando está en 3 y ocurre shift_enable, increment_counter_condition es falso,
    // por lo que d_bit_count se queda en 3.
    wire increment_counter_condition;
    assign increment_counter_condition = shift_enable & ~counter_is_3;

    wire bit_count_incremented_val_0;
    wire bit_count_incremented_val_1;
    assign bit_count_incremented_val_0 = ~bit_count_reg[0];
    assign bit_count_incremented_val_1 = bit_count_reg[1] ^ bit_count_reg[0];

    assign d_bit_count[0] = ~reset_counter_condition & ( (increment_counter_condition & bit_count_incremented_val_0) | (~increment_counter_condition & bit_count_reg[0]) );
    assign d_bit_count[1] = ~reset_counter_condition & ( (increment_counter_condition & bit_count_incremented_val_1) | (~increment_counter_condition & bit_count_reg[1]) );

    //-------------------------------------------------------------------------
    // 4. Lógica del Buffer de Datos MOSI y Pulso de Validez -- CONDICIÓN DE CARGA CORREGIDA
    //-------------------------------------------------------------------------
    wire final_load_data_buffer_condition;
    // La condición de carga es verdadera cuando:
    //   'shift_enable' está activo (se está procesando un bit SPI)
    //   Y 'counter_is_3' es verdadero (el bit_count_reg *actualmente* es 3, lo que significa
    //    que este 'shift_enable' está procesando el 4to y último bit de datos).
    assign final_load_data_buffer_condition = shift_enable & counter_is_3;

    // Se carga con d_shift_reg_mosi para capturar el valor que shift_reg_mosi
    // tendrá DESPUÉS del flanco de reloj actual (es decir, el valor completo de 4 bits).
    assign d_data_buffer[0] = ~reset & (
                                (final_load_data_buffer_condition & d_shift_reg_mosi[0]) |
                                (~final_load_data_buffer_condition & data_buffer_reg[0])
                              );
    assign d_data_buffer[1] = ~reset & (
                                (final_load_data_buffer_condition & d_shift_reg_mosi[1]) |
                                (~final_load_data_buffer_condition & data_buffer_reg[1])
                              );
    assign d_data_buffer[2] = ~reset & (
                                (final_load_data_buffer_condition & d_shift_reg_mosi[2]) |
                                (~final_load_data_buffer_condition & data_buffer_reg[2])
                              );
    assign d_data_buffer[3] = ~reset & (
                                (final_load_data_buffer_condition & d_shift_reg_mosi[3]) |
                                (~final_load_data_buffer_condition & data_buffer_reg[3])
                              );

    // El pulso de validez se genera cuando la nueva condición de carga es verdadera.
    assign d_data_valid_pulse = ~reset & final_load_data_buffer_condition;

    //-------------------------------------------------------------------------
    // 5. Lógica del Registro de Desplazamiento MISO (para enviar ACK_BYTE)
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