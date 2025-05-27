module Registro4bits (
    input  logic clk,
    input  logic rst,        // Señal de reset
    input  logic [3:0] d,    // Entrada de datos
    output logic [3:0] q     // Salida del registro
);

    always_ff @(posedge clk ) begin
        q[0] <=  (~rst & d[0]);
        q[1] <= (~rst & d[1]);
        q[2] <= (~rst & d[2]);
        q[3] <= (~rst & d[3]);
    end

endmodule