module sub_4bit (
    input  logic [3:0] A,
    input  logic [3:0] B,
    output logic [3:0] Y,
	 output logic C    // <- Acarreo (Carry)
);

    logic [3:0] B_comp;  // complemento a 1
    logic       carry;
    logic [3:0] sum;

    // Complemento a 1 de B
    not n0 (B_comp[0], B[0]);
    not n1 (B_comp[1], B[1]);
    not n2 (B_comp[2], B[2]);
    not n3 (B_comp[3], B[3]);

    // Suma A + (~B + 1) = A - B
    logic c1, c2, c3;

    full_adder fa0 (.a(A[0]), .b(B_comp[0]), .cin(1'b1), .sum(Y[0]), .cout(c1));
    full_adder fa1 (.a(A[1]), .b(B_comp[1]), .cin(c1),    .sum(Y[1]), .cout(c2));
    full_adder fa2 (.a(A[2]), .b(B_comp[2]), .cin(c2),    .sum(Y[2]), .cout(c3));
    full_adder fa3 (.a(A[3]), .b(B_comp[3]), .cin(c3),    .sum(Y[3]), .cout(C));

endmodule
