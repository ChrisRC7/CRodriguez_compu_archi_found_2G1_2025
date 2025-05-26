module Registro4bits (
    input  logic clk,
    input  logic rst,        // Señal de reset
    input  logic [3:0] d,    // Entrada de datos
    output logic [3:0] q     // Salida del registro
);

    always_ff @(posedge clk or posedge rst) begin
        q[0] <= (rst & 1'b0) | (~rst & d[0]);
        q[1] <= (rst & 1'b0) | (~rst & d[1]);
        q[2] <= (rst & 1'b0) | (~rst & d[2]);
        q[3] <= (rst & 1'b0) | (~rst & d[3]);
    end

endmodule