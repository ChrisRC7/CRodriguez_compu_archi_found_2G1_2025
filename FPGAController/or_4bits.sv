module or_4bits (
    input  logic [3:0] A,
    input  logic [3:0] B,
    output logic [3:0] Y
);
    assign Y = A ^ B;
	 
endmodule
