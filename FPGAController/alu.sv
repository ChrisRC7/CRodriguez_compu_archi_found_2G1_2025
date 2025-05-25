module alu (
    input  logic [3:0] A, B,
    input  logic [1:0] sel,     // selector de operación
    output logic [7:0] result,
	 output Z, C, V, S            // Banderas: Zero, Carry, Overflow, Signo
);

    // Resultados individuales
    logic [3:0] and_result, xor_result, sub_result;
    logic [7:0] mul_result;
	 logic [7:0] res;
	 
	 logic Ct;  // Acarreo (Carry)
	 
	 // Selector de operación
	 logic sel_mult, sel_sub, sel_and, sel_xor;
	 

    // Instancias de módulos externos
    and_4bits and_gate (
        .A(A),
        .B(B),
        .Y(and_result)
    );

    xor_4bits xor_gate (
        .A(A),
        .B(B),
        .Y(xor_result)
    );

    sub_4bit sub_module (
        .A(A),
        .B(B),
        .Y(sub_result),
		  .C(Ct)
    );

    multiplier mult_module (
        .A(A),
        .B(B),
        .P(mul_result)
    );
	 
	 // Multiplexor para seleccionar la operación
	 // 00 Multiplicacion
	 // 01 Resta
	 // 10 AND
	 // 11 XOR
	 assign sel_mult = ~sel[1] & ~sel[0];  // 00
	 assign sel_sub = ~sel[1] &  sel[0];   // 01
    assign sel_and =  sel[1] & ~sel[0];   // 10
    assign sel_xor  =  sel[1] &  sel[0];   // 11
	 
	 assign res = ({8{sel_mult}} & mul_result)   |
                ({8{sel_sub}} & {4'b0000, sub_result})  |
                ({8{sel_and}} & {4'b0000, and_result}) |
                ({8{sel_xor}}  & {4'b0000, xor_result});
					 
	 
	 // FLags de resultados
	 assign Z = (res == 8'b0);  // Zero: cuando el resultado es cero
	 assign S = sel_sub & sub_result[3];      //Signo: Se toma el bit más significativo del resultado de 4 bits
	 assign C = sel_sub & Ct;
	 assign V = sel_sub & ((A[3] & ~B[3] & ~sub_result[3]) | (~A[3] & B[3] & sub_result[3]));
	 
	 assign result = res;
	 

    // always_comb begin
        // case (sel)
            // 4'b0001: result = {4'b0000, and_result}; // AND
            // 4'b0010: result = {4'b0000, xor_result};  // OR
            // 4'b0100: result = {4'b0000, sub_result}; // SUB
            // 4'b1000: result = mul_result;            // MUL
            // default: result = 8'b00000000;           // Default: cero
        // endcase
    // end
	 
	 
	 
	 
	 
	 
	 

endmodule
