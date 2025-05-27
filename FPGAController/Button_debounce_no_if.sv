////////////////////////////////////////////////////////////////////////
// Modulo Debounce Simple Basado en Contador (Sin if, case, ?:)
////////////////////////////////////////////////////////////////////////
module Button_debounce_no_if #(
    parameter CLK_FREQ       = 50_000_000, // Frecuencia del reloj de entrada (Hz) - ¡AJUSTAR!
    parameter STABLE_TIME_MS = 10          // Tiempo de estabilidad deseado (ms)
) (
    input  logic clk,          // Reloj del sistema
    input  logic rst,          // Reset (activo alto)
    input  logic button_in,    // Entrada directa del botón (ruidosa)
    output logic button_out    // Salida estable del botón
);

    // --- Cálculos de Parámetros Locales ---
    localparam COUNT_TARGET_VAL  = STABLE_TIME_MS * (CLK_FREQ / 1000);
    // $clog2(1) es 0. Si COUNT_TARGET_VAL es 1, COUNTER_BITS es 0.
    localparam COUNTER_BITS      = (COUNT_TARGET_VAL == 0) ? 0 : $clog2(COUNT_TARGET_VAL); 

    // SAFE_COUNTER_BITS para asegurar que el contador tenga al menos 1 bit
    // Original: (COUNTER_BITS == 0 && COUNT_TARGET_VAL > 0) ? 1 : COUNTER_BITS; (Más preciso si COUNT_TARGET_VAL=1)
    // Si COUNT_TARGET_VAL es 1, $clog2(1)=0. MAX_COUNT será 0. Necesitamos 1 bit para contar hasta 0.
    // Si COUNT_TARGET_VAL es 0 (no debería pasar si STABLE_TIME_MS > 0), $clog2(0) es problemático. Asumimos COUNT_TARGET_VAL >= 1.
    localparam IS_CB_ZERO_FOR_SAFE      = (COUNTER_BITS == 0 && COUNT_TARGET_VAL >= 1); // Si $clog2(COUNT_TARGET_VAL)=0 pero necesitamos contar.
                                                                                    // ej: COUNT_TARGET_VAL=1, $clog2(1)=0. MAX_COUNT=0. Counter needs 1 bit.
    localparam IS_CB_NONZERO_FOR_SAFE   = ~(IS_CB_ZERO_FOR_SAFE); // Complemento
    localparam SAFE_COUNTER_BITS =  (IS_CB_ZERO_FOR_SAFE * 1) + 
                                    (IS_CB_NONZERO_FOR_SAFE * COUNTER_BITS);

    // MAX_COUNT es el valor que el contador debe alcanzar. Si es 0, el cambio es casi inmediato.
    localparam MAX_COUNT         = (COUNT_TARGET_VAL == 0) ? 0 : COUNT_TARGET_VAL - 1;

    // --- Señales Internas ---
    logic [SAFE_COUNTER_BITS-1:0] count;
    logic sync_ff1, sync_ff2;      // Sincronizadores de entrada
    logic debounced_state_reg;

    // --- Lógica Combinacional para Próximos Estados (sin reset) ---
    // Estas señales representan cómo serían los valores en la operación normal (no reset)

    // cond1_w: ¿La entrada sincronizada (sync_ff2) es diferente del estado estable (debounced_state_reg)?
    wire cond1_w = sync_ff2 ^ debounced_state_reg; // XOR es true si son diferentes

    // count_lt_max_w: ¿El contador actual es menor que MAX_COUNT?
    wire count_lt_max_w = count < MAX_COUNT;

    // count_is_max_w: ¿El contador actual ha alcanzado MAX_COUNT?
    wire count_is_max_w = count == MAX_COUNT;

    // sel_increment_count_w: Selector para cuando el contador debe incrementar.
    // (Entrada cambió Y el contador aún no ha llegado a MAX_COUNT)
    wire sel_increment_count_w = cond1_w & count_lt_max_w;

    // sel_update_dsr_w: Selector para cuando el estado estable (debounced_state_reg) debe actualizarse.
    // (Entrada cambió Y el contador ha llegado a MAX_COUNT)
    wire sel_update_dsr_w = cond1_w & count_is_max_w;

    // --- Cálculo del próximo valor del contador (sin considerar el reset) ---
    // count_normal_op_w será count + 1 si sel_increment_count_w es verdadero,
    // de lo contrario (si la entrada coincide con el estado estable, o si el contador llegó al máximo y la entrada cambió),
    // el contador se resetea a 0.
    wire [SAFE_COUNTER_BITS-1:0] count_plus_1_w = count + 1;
    wire [SAFE_COUNTER_BITS-1:0] count_zero_w   = {SAFE_COUNTER_BITS{1'b0}}; // Constante cero

    // Si sel_increment_count_w es 1, count_normal_op_w = count_plus_1_w.
    // Si sel_increment_count_w es 0, count_normal_op_w = count_zero_w.
    wire [SAFE_COUNTER_BITS-1:0] count_normal_op_w =
        ( {SAFE_COUNTER_BITS{sel_increment_count_w}} & count_plus_1_w ) |
        ( {SAFE_COUNTER_BITS{~sel_increment_count_w}} & count_zero_w  ); // O simplemente: {SAFE_COUNTER_BITS{~sel_increment_count_w}} & '0

    // --- Cálculo del próximo valor de debounced_state_reg (sin considerar el reset) ---
    // debounced_state_reg_normal_op_w será sync_ff2 si sel_update_dsr_w es verdadero,
    // de lo contrario, mantendrá su valor actual (debounced_state_reg).
    wire debounced_state_reg_normal_op_w =
        ( sel_update_dsr_w & sync_ff2 ) |
        ( {1{~sel_update_dsr_w}} & debounced_state_reg ); // {1{...}} para claridad, no estrictamente necesario si ~sel_update_dsr_w es 1 bit


    // --- Sincronizador de Entrada ---
    // Asigna button_in a sync_ff1 y sync_ff1 a sync_ff2.
    // Si rst es '1', las salidas son '0'.
    always_ff @(posedge clk or posedge rst) begin
        // sync_ff1 <= rst ? 1'b0 : button_in;
        sync_ff1 <= (rst & 1'b0) | (~rst & button_in);
        // sync_ff2 <= rst ? 1'b0 : sync_ff1; (sync_ff1 es el valor registrado anterior)
        sync_ff2 <= (rst & 1'b0) | (~rst & sync_ff1);
    end

    // --- Lógica Principal del Debounce (Registros) ---
    always_ff @(posedge clk or posedge rst) begin
        // Actualización de debounced_state_reg
        // debounced_state_reg <= rst ? 1'b0 : debounced_state_reg_normal_op_w;
        debounced_state_reg <= (rst & 1'b0) | (~rst & debounced_state_reg_normal_op_w);

        // Actualización del contador
        // count <= rst ? '0 : count_normal_op_w;
        count <= ( {SAFE_COUNTER_BITS{rst}} & count_zero_w ) | // Si rst, count = 0
                 ( {SAFE_COUNTER_BITS{~rst}} & count_normal_op_w ); // Si no rst, count = count_normal_op_w
    end

    // --- Salida ---
    assign button_out = debounced_state_reg;

endmodule