module xor (
    input  logic [3:0] A,
    input  logic [3:0] B,
    output logic [3:0] Y
);
    assign Y = A ^ B;
	 
endmodule
