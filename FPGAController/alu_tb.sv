`timescale 1ns/1ps

module alu_tb;

    // Señales para conectar con el DUT (Device Under Test)
    logic [3:0] A, B;
    logic [1:0] sel;
    logic [7:0] result;
    logic Z, C, V, S;

    // Instanciar el módulo ALU
    alu dut (
        .A(A),
        .B(B),
        .sel(sel),
        .result(result),
        .Z(Z),
        .C(C),
        .V(V),
        .S(S)
    );

    // Procedimiento para imprimir resultados
    task print_output;
        $display("Time=%0t | sel=%b | A=%b B=%b | result=%b | Z=%b C=%b V=%b S=%b", 
                  $time, sel, A, B, result, Z, C, V, S);
    endtask

    initial begin
        // Test Multiplicacion (sel = 00)
        A = 4'd15; B = 4'd3; sel = 2'b00; #10;
        print_output();

        A = 4'd7; B = 4'd2; sel = 2'b00; #10;
        print_output();

        // Test Resta (sel = 01)
        A = 4'd10; B = 4'd3; sel = 2'b01; #10;
        print_output();

        A = 4'd3; B = 4'd2; sel = 2'b01; #10;
        print_output();

        // Test AND (sel = 10)
        A = 4'b1100; B = 4'b0010; sel = 2'b10; #10;
        print_output();

        // Test XOR (sel = 11)
        A = 4'b1100; B = 4'b0010; sel = 2'b11; #10;
        print_output();

        // Test Zero flag
        A = 4'd3; B = 4'd3; sel = 2'b01; #10;  // 5-5=0
        print_output();

        $stop;  // Terminar simulacion
    end

endmodule