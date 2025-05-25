module alu (
    input  logic [3:0] A, B,
    input  logic [3:0] sel,     // selector tipo 1-hot (diagonal)
    output logic [7:0] result
);

    // Resultados individuales
    logic [3:0] and_result, xor_result, sub_result;
    logic [7:0] mul_result;

    // Instancia del multiplicador estructural
    multiplier multiplier (
        .A(A),
        .B(B),
        .P(mul_result)
    );

    // Operaciones básicas
    assign and_result = A & B;
    assign xor_result = A ^ B;
    assign sub_result = A - B;

    always_comb begin
        case (sel)
            4'b1000: result = mul_result;            // MUL
            default: result = 8'b00000000;           // Default: cero
        endcase
    end

endmodule
