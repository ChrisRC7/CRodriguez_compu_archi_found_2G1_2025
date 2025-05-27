module FlipFlop (
    input  logic reset,
    input  logic button_stable,      // Entrada debounced usada como "clk manual"
    input  logic [1:0] num,          // Entrada de número
    output logic [1:0] accumulated_value,
    output logic signal_out
);

    logic [1:0] acc; // = 2'b00; // La inicialización aquí es más para simulación, el reset la define para síntesis.
    logic [1:0] sum;

    // Instanciación del sumador (DecoderToBcd se asume como un sumador de 2 bits)
    // sum = num + acc
    DecoderToBcd sumador (
        .A1(num[1]), .A0(num[0]),   // Entrada num
        .B1(acc[1]), .B0(acc[0]),   // Entrada acc (valor actual del acumulador)
        .S(sum)                     // Salida sum = num + acc
    );

    // Lógica secuencial para el acumulador 'acc'
    // Sensible al flanco de bajada de button_stable (reloj) o al flanco de subida de reset
    always_ff @(negedge button_stable or posedge reset) begin
        // Lógica original:
        // if (reset)
        //     acc <= 2'b00;
        // else
        //     acc <= sum;
        //
        // Reescrito sin 'if', usando una estructura de multiplexor con AND-OR:
        // acc_siguiente = (condicion_reset & valor_en_reset) | (condicion_normal & valor_en_operacion_normal);
        // Donde condicion_reset es 'reset' y condicion_normal es '~reset'.
        // Se replica 'reset' y '~reset' para que coincidan con el ancho de 'acc' (2 bits).
        acc <= ( {2{reset}} & 2'b00 ) | ( {2{~reset}} & sum );
    end

    // Asignación de salida para el valor acumulado
    assign accumulated_value = acc;

    // Asignación de salida para signal_out
    // Lógica original: signal_out = (acc == 2'd1 || acc == 2'd2) ? 1 : 0;
    //
    // Reescrito sin operador ternario:
    // signal_out es '1' si acc es 1 (binario 01) O si acc es 2 (binario 10).

    // Comprueba si acc es igual a 2'b01 (decimal 1)
    wire acc_es_uno = (~acc[1] & acc[0]);

    // Comprueba si acc es igual a 2'b10 (decimal 2)
    wire acc_es_dos = (acc[1] & ~acc[0]);

    // signal_out es verdadero (1) si cualquiera de las condiciones anteriores es verdadera.
    assign signal_out = acc_es_uno | acc_es_dos;

endmodule