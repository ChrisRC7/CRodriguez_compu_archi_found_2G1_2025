module multiplier (
    input  logic [3:0] A, B,
    output logic [7:0] P
);
    // Productos parciales
    logic pp00, pp01, pp02, pp03;
    logic pp10, pp11, pp12, pp13;
    logic pp20, pp21, pp22, pp23;
    logic pp30, pp31, pp32, pp33;

    // Intermedios
    logic s1, s2, s3, s4, s5, s6, s7;
    logic c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11;

    // Asignación de productos parciales
    assign pp00 = A[0] & B[0];
    assign pp01 = A[1] & B[0];
    assign pp02 = A[2] & B[0];
    assign pp03 = A[3] & B[0];

    assign pp10 = A[0] & B[1];
    assign pp11 = A[1] & B[1];
    assign pp12 = A[2] & B[1];
    assign pp13 = A[3] & B[1];

    assign pp20 = A[0] & B[2];
    assign pp21 = A[1] & B[2];
    assign pp22 = A[2] & B[2];
    assign pp23 = A[3] & B[2];

    assign pp30 = A[0] & B[3];
    assign pp31 = A[1] & B[3];
    assign pp32 = A[2] & B[3];
    assign pp33 = A[3] & B[3];

    // Bit 0
    assign P[0] = pp00;

    // Bit 1
    full_adder fa1 (.a(pp01), .b(pp10), .cin(1'b0), .sum(P[1]), .cout(c1));

    // Bit 2
    full_adder fa2 (.a(pp02), .b(pp11), .cin(pp20), .sum(s1), .cout(c2));
    full_adder fa3 (.a(s1), .b(c1), .cin(1'b0), .sum(P[2]), .cout(c3));

    // Bit 3
    full_adder fa4 (.a(pp03), .b(pp12), .cin(pp21), .sum(s2), .cout(c4));
    full_adder fa5 (.a(s2), .b(pp30), .cin(c2), .sum(s3), .cout(c5));
    full_adder fa6 (.a(s3), .b(c3), .cin(1'b0), .sum(P[3]), .cout(c6));

    // Bit 4
    full_adder fa7 (.a(pp13), .b(pp22), .cin(pp31), .sum(s4), .cout(c7));
    full_adder fa8 (.a(s4), .b(c4), .cin(c5), .sum(s5), .cout(c8));
    full_adder fa9 (.a(s5), .b(c6), .cin(1'b0), .sum(P[4]), .cout(c9));

    // Bit 5
    full_adder fa10 (.a(pp23), .b(pp32), .cin(c7), .sum(s6), .cout(c10));
    full_adder fa11 (.a(s6), .b(c8), .cin(c9), .sum(P[5]), .cout(c11));

    // Bit 6
    full_adder fa12 (.a(pp33), .b(c10), .cin(c11), .sum(P[6]), .cout(P[7]));

endmodule
