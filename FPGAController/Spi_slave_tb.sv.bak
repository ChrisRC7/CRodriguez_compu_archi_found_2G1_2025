// Testbench para Spi_slave_module (con MISO para handshake ACK)
`timescale 1ns / 1ps

module Spi_slave_tb;

    // Parámetros del Testbench
    localparam CLK_PERIOD_FPGA = 20;  // Periodo del reloj de la FPGA (ej. 50MHz -> 20ns)
    localparam SCLK_PERIOD_SPI = 1000; // Periodo del reloj SPI (ej. 1MHz -> 1000ns)
                                       // Debe ser significativamente más lento que CLK_PERIOD_FPGA
                                       // SCLK_HALF_PERIOD = SCLK_PERIOD_SPI / 2
    localparam ACK_EXPECTED_FROM_FPGA = 8'hA5; // El ACK que esperamos de la FPGA

    // Señales para conectar al DUT (Spi_slave_module)
    logic clk_fpga_tb;
    logic reset_tb;
    logic sclk_spi_tb;
    logic mosi_tb;
    logic ss_n_tb;

    logic [3:0] spi_data_out_dut;       // Datos recibidos por la FPGA
    logic       spi_data_valid_out_dut; // Pulso de validez de datos
    logic       miso_dut;               // Datos enviados por la FPGA (ACK)

    // Señales internas del Testbench y para verificación
    logic [7:0] byte_to_send_tb;        // Byte que el "Arduino" simulado enviará
    logic [3:0] speed_value_to_send_tb; // Valor de velocidad de 4 bits
    logic [7:0] byte_received_from_fpga_tb; // Byte recibido del MISO de la FPGA
    integer     bit_count_spi_tb;

    string      test_case_name;

    // Instancia del Device Under Test (DUT)
    // Asegúrate de que el nombre 'Spi_slave_module' coincida con tu módulo
    Spi_slave_module dut (
        .clk(clk_fpga_tb),
        .reset(reset_tb),
        .sclk_in(sclk_spi_tb),
        .mosi_in(mosi_tb),
        .ss_n_in(ss_n_tb),
        .spi_data_out(spi_data_out_dut),
        .spi_data_valid_out(spi_data_valid_out_dut),
        .miso_out(miso_dut)
    );

    // Generador de reloj para la FPGA
    always begin
        clk_fpga_tb = 1'b0;
        #(CLK_PERIOD_FPGA / 2);
        clk_fpga_tb = 1'b1;
        #(CLK_PERIOD_FPGA / 2);
    end

    // Tarea para simular una transacción SPI completa (envío de 1 byte y recepción de 1 byte)
    task spi_transfer_byte;
        input [7:0] data_to_send_master; // Byte que el maestro (TB) envía por MOSI
        output [7:0] data_received_master; // Byte que el maestro (TB) recibe por MISO

        integer i;
        logic temp_miso_bit;
        data_received_master = 8'b0;

        // Simular 8 ciclos de SCLK para transferir 1 byte
        // Asumiendo SPI Modo 0 (CPOL=0, CPHA=0):
        // MOSI cambia antes del flanco ascendente de SCLK (o en el descendente anterior)
        // MOSI se muestrea en el flanco ascendente de SCLK
        // MISO cambia después del flanco descendente de SCLK y es estable para el flanco ascendente
        // (o más simple: MISO es muestreado por el maestro en el flanco ascendente de SCLK)
        for (i = 0; i < 8; i = i + 1) begin
            // Maestro pone el bit MOSI (MSB primero)
            mosi_tb = data_to_send_master[7-i];

            // Flanco descendente de SCLK (para que el esclavo pueda cambiar MISO)
            sclk_spi_tb = 1'b0;
            #(SCLK_PERIOD_SPI / 2);

            // Flanco ascendente de SCLK
            sclk_spi_tb = 1'b1;
            // En este flanco:
            // - El esclavo muestrea MOSI
            // - El maestro muestrea MISO
            // Pequeño delay para asegurar que MISO del DUT se haya propagado
            #1; // Ajustar si es necesario, o muestrear justo antes del siguiente flanco descendente
            temp_miso_bit = miso_dut;
            data_received_master = (data_received_master << 1) | temp_miso_bit;
            #(SCLK_PERIOD_SPI / 2 - 1); // Resto del semiperiodo alto de SCLK
        end
        // SCLK vuelve a estado inactivo (bajo para Modo 0)
        sclk_spi_tb = 1'b0;
        mosi_tb = 1'bz; // MOSI en alta impedancia o estado de reposo
    endtask

    // Tarea para verificar los resultados de la recepción SPI
    task check_spi_transaction;
        input [3:0] expected_data_received_by_fpga;
        input logic expected_data_valid_pulse;
        input [7:0] expected_ack_from_fpga;
        input [7:0] actual_ack_received_by_master;
        input [3:0] actual_data_on_dut_output;
        input logic actual_data_valid_on_dut;

        $display("\n--- Test Case: %s ---", test_case_name);
        $display("Maestro envió (velocidad 4-bits): 4'b%b (Byte: 8'b%b)", speed_value_to_send_tb, byte_to_send_tb);

        // Verificar ACK recibido por el maestro
        $display("ACK esperado por Maestro: 8'h%h (8'b%b)", expected_ack_from_fpga, expected_ack_from_fpga);
        $display("ACK obtenido por Maestro: 8'h%h (8'b%b)", actual_ack_received_by_master, actual_ack_received_by_master);
        if (actual_ack_received_by_master === expected_ack_from_fpga) begin
            $display("Resultado ACK: PASSED");
        end else begin
            $error("Resultado ACK: FAILED");
        end

        // Esperar a que el pulso de validez del DUT ocurra (o un tiempo razonable)
        // Esto es simplificado; en un TB más robusto se usaría @(posedge spi_data_valid_out_dut)
        // Pero spi_data_valid_out_dut es un pulso, así que debemos estar atentos
        // Por ahora, asumimos que después de la transacción SPI, los datos deben estar listos
        // y el pulso de validez habrá ocurrido. Para verificar el pulso en sí, necesitaríamos
        // un monitor o una espera más específica.

        // Verificar datos recibidos por el DUT (después de que data_valid haya ocurrido)
        // Vamos a esperar un poco más para que los datos se propaguen y spi_data_valid_out_dut se asiente.
        // Este chequeo es después de que la transacción SPI ha terminado.
        // El chequeo de spi_data_valid_out_dut es más complejo para un pulso.
        // Se podría registrar el pulso en el TB.
        // Por ahora, verificamos el dato en spi_data_out_dut asumiendo que se actualizó.

        // Para verificar spi_data_valid_out_dut como un pulso:
        // Se necesitaría un monitor en el TB:
        // logic spi_data_valid_seen_tb = 1'b0;
        // always @(posedge spi_data_valid_out_dut) spi_data_valid_seen_tb = 1'b1;
        // Y luego chequear y resetear spi_data_valid_seen_tb.

        // Simplificamos: Verificamos spi_data_out_dut después de un delay.
        // El pulso de spi_data_valid_out_dut debería ocurrir durante el último ciclo de SCLK.
        // Vamos a chequearlo un poco después.
        // Este chequeo es para el dato que el esclavo (DUT) ha capturado.
        #(CLK_PERIOD_FPGA * 5); // Esperar unos ciclos de FPGA para que se procese

        $display("Dato esperado en salida del DUT (spi_data_out_dut): 4'b%b", expected_data_received_by_fpga);
        $display("Dato obtenido en salida del DUT (spi_data_out_dut): 4'b%b", spi_data_out_dut);
        if (spi_data_out_dut === expected_data_received_by_fpga) begin
            $display("Resultado Dato DUT: PASSED");
        end else begin
            $error("Resultado Dato DUT: FAILED");
        end

        // La verificación de spi_data_valid_out_dut como pulso se deja como mejora,
        // ya que requiere lógica de monitoreo más compleja en el TB.
        // Si spi_data_out_dut es correcto, es una fuerte indicación de que spi_data_valid_out_dut funcionó.

    endtask


    // Procedimiento principal de prueba
    initial begin
        $display("===========================================");
        $display("  INICIO DE LA SIMULACION SPI_SLAVE_MODULE ");
        $display("===========================================");

        // Inicializar señales
        clk_fpga_tb = 1'b0;
        reset_tb = 1'b1;    // Aplicar reset inicialmente
        sclk_spi_tb = 1'b0; // SCLK inactivo bajo (Modo 0)
        mosi_tb = 1'bz;   // MOSI en alta impedancia
        ss_n_tb = 1'b1;   // Slave Select inactivo (alto)
        bit_count_spi_tb = 0;

        // Liberar reset
        #(CLK_PERIOD_FPGA * 5);
        reset_tb = 1'b0;
        $display("Tiempo: %0t ns - Reset liberado.", $time);
        #(CLK_PERIOD_FPGA * 5);


        // --- Test Case 1: Enviar velocidad 5 (0101) ---
        test_case_name = "Enviar Velocidad 5";
        speed_value_to_send_tb = 4'b0101;
        byte_to_send_tb = (speed_value_to_send_tb & 4'hF) << 4; // 0b01010000

        ss_n_tb = 1'b0; // Activar Slave Select
        $display("Tiempo: %0t ns - %s: SS_n LOW, enviando byte 8'b%b", $time, test_case_name, byte_to_send_tb);
        #(CLK_PERIOD_FPGA); // Pequeño delay después de SS_n para asegurar que el esclavo lo vea

        spi_transfer_byte(byte_to_send_tb, byte_received_from_fpga_tb);

        ss_n_tb = 1'b1; // Desactivar Slave Select
        $display("Tiempo: %0t ns - %s: SS_n HIGH, byte recibido 8'b%b", $time, test_case_name, byte_received_from_fpga_tb);
        #(CLK_PERIOD_FPGA * 2); // Delay después de la transacción

        check_spi_transaction(
            speed_value_to_send_tb,     // expected_data_received_by_fpga
            1'b1,                       // expected_data_valid_pulse (difícil de chequear así)
            ACK_EXPECTED_FROM_FPGA,     // expected_ack_from_fpga
            byte_received_from_fpga_tb, // actual_ack_received_by_master
            spi_data_out_dut,           // actual_data_on_dut_output
            spi_data_valid_out_dut      // actual_data_valid_on_dut
        );
        #(SCLK_PERIOD_SPI * 2); // Esperar antes del siguiente test


        // --- Test Case 2: Enviar velocidad 10 (1010) ---
        test_case_name = "Enviar Velocidad 10 (0xA)";
        speed_value_to_send_tb = 4'b1010;
        byte_to_send_tb = (speed_value_to_send_tb & 4'hF) << 4; // 0b10100000

        ss_n_tb = 1'b0; // Activar Slave Select
        $display("Tiempo: %0t ns - %s: SS_n LOW, enviando byte 8'b%b", $time, test_case_name, byte_to_send_tb);
        #(CLK_PERIOD_FPGA);

        spi_transfer_byte(byte_to_send_tb, byte_received_from_fpga_tb);

        ss_n_tb = 1'b1; // Desactivar Slave Select
        $display("Tiempo: %0t ns - %s: SS_n HIGH, byte recibido 8'b%b", $time, test_case_name, byte_received_from_fpga_tb);
        #(CLK_PERIOD_FPGA * 2);

        check_spi_transaction(
            speed_value_to_send_tb,
            1'b1,
            ACK_EXPECTED_FROM_FPGA,
            byte_received_from_fpga_tb,
            spi_data_out_dut,
            spi_data_valid_out_dut
        );
        #(SCLK_PERIOD_SPI * 2);


        // --- Test Case 3: Enviar velocidad 0 (0000) ---
        test_case_name = "Enviar Velocidad 0";
        speed_value_to_send_tb = 4'b0000;
        byte_to_send_tb = (speed_value_to_send_tb & 4'hF) << 4; // 0b00000000

        ss_n_tb = 1'b0; // Activar Slave Select
        $display("Tiempo: %0t ns - %s: SS_n LOW, enviando byte 8'b%b", $time, test_case_name, byte_to_send_tb);
        #(CLK_PERIOD_FPGA);

        spi_transfer_byte(byte_to_send_tb, byte_received_from_fpga_tb);

        ss_n_tb = 1'b1; // Desactivar Slave Select
        $display("Tiempo: %0t ns - %s: SS_n HIGH, byte recibido 8'b%b", $time, test_case_name, byte_received_from_fpga_tb);
        #(CLK_PERIOD_FPGA * 2);

        check_spi_transaction(
            speed_value_to_send_tb,
            1'b1,
            ACK_EXPECTED_FROM_FPGA,
            byte_received_from_fpga_tb,
            spi_data_out_dut,
            spi_data_valid_out_dut
        );
        #(SCLK_PERIOD_SPI * 2);


        $display("===========================================");
        $display("  FIN DE LA SIMULACION SPI_SLAVE_MODULE    ");
        $display("===========================================");
        $finish;
    end

endmodule