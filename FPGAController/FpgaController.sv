// Nombre del archivo: FpgaController.sv (o como lo tengas)
// Módulo de NIVEL SUPERIOR ACTUALIZADO para handshake

module FpgaController (
    // --- Entradas FÍSICAS a la FPGA ---
    input logic FPGA_clk,         // Reloj principal de tu placa FPGA
    input logic FPGA_reset,       // Reset de tu placa FPGA
    input logic arduino_sclk,     // Conectado al SCK del Arduino
    input logic arduino_mosi,     // Conectado al MOSI del Arduino
    input logic arduino_ss_n,     // Conectado al SS del Arduino

    // --- Salidas FÍSICAS de la FPGA ---
    output logic fpga_physical_miso, // <--- ESTA ES TU SALIDA MISO FÍSICA HACIA EL ARDUINO
                                     //      Le das un nombre claro. En el Pin Planner, asignas
                                     //      ESTE puerto a un pin físico de la FPGA.
    output logic motor_pwm_signal,   // Hacia el driver del motor
    output logic [6:0] seven_segment_display // Hacia los segmentos del display
);

    // --- Señales INTERNAS para conectar los módulos ---
    // Estas NO son pines físicos. Son "cables" dentro de la FPGA.
    wire [3:0] data_from_spi_module;          // Datos recibidos del Arduino via SPI
    wire       data_is_valid_from_spi_module; // Pulso que indica que data_from_spi_module es válida
                                              // (Esta es la conexión interna para tu spi_data_valid_out)

    // --- Instancia del Módulo Esclavo SPI ---
    // Asegúrate de que 'Spi_slave_module' es el nombre exacto de tu archivo/módulo SPI
    // y que este módulo tiene un puerto de salida llamado 'miso_out'.
    Spi_slave_module spi_unit (
        .clk(FPGA_clk),
        .reset(FPGA_reset),
        .sclk_in(arduino_sclk),
        .mosi_in(arduino_mosi),
        .ss_n_in(arduino_ss_n),
        .spi_data_out(data_from_spi_module),         // Salida interna del SPI
        .spi_data_valid_out(data_is_valid_from_spi_module), // Salida interna del SPI
        .miso_out(fpga_physical_miso)                // La salida MISO del módulo SPI
                                                     // se conecta DIRECTAMENTE al puerto
                                                     // de salida físico del FpgaController.
    );

    // --- Instancia del Módulo PWM y Display ---
    // Asegúrate de que 'fpga_slave_pwm_display' es el nombre exacto de tu módulo
    // para PWM/display y que sus puertos internos son correctos.
    //fpga_slave_pwm_display pwm_and_display_unit (
    //    .clk(FPGA_clk),
    //    .reset(FPGA_reset),
    //    .arduino_data_in(data_from_spi_module),
    //    .arduino_write_enable(data_is_valid_from_spi_module),
    //    .pwm_out(motor_pwm_signal),
    //    .seg(seven_segment_display)
    //);

endmodule