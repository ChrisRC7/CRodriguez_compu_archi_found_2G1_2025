module FpgaController (
    input logic FPGA_clk,
    input logic FPGA_reset,
    input logic arduino_sclk,
    input logic arduino_mosi,
    input logic arduino_ss_n,
	 input logic A, B, C, D,
	 input logic M, //entrada de multiplicación
	 input logic S, //entrada de resta
	 input logic N, // entrada de AND
	 input logic X, // entrada de XOR
	 

 
    output logic fpga_physical_miso,
    output logic [3:0] led_outputs,
    output logic [6:0] seven_segment_pins,
	 output logic [3:0] leds    // LEDs para las banderas: Z, C, V, S
);

    wire [3:0] data_from_spi_to_fpga;
    wire        data_is_valid_from_spi;
    wire [6:0] segments_from_bcd_units;
	 
	 // Resultado del deco
	 logic [1:0] dec_result;
	 
	 // numero del 0 al 3 del deco pero con cuatro bits
	 logic [3:0] dec_4bits;
	 
	 // Resultado del deco de la alu
	 logic [1:0] alu_sel;
	 
	 // Resultado de la operacion de la alu
	 logic [7:0] alu_result;
	 
	 
	 
	 // Flags de la alu
	 logic Z, Carry, V, Sign;
	 
	 // Instancia del Decodificador de las fotoresistencias
    FirtsDecoder_4to2bits decoder_inst (
        .A(A),
        .B(B),
        .C(C),
        .D(D),
        .Y0(dec_result[0]),
        .Y1(dec_result[1])
    );
	 
	 // Instancia del Decodificador de eleccion de operacion 
    FirtsDecoder_4to2bits alu_controller (
        .A(M),
        .B(S),
        .C(N),
        .D(X),
        .Y0(alu_sel[0]),
        .Y1(alu_sel[1])
    );


// asignar dos ceros a la izquierda
	assign dec_4bits = {2'b00, dec_result};
	 
	alu aluu (
	     .A(data_from_spi_to_fpga),
        .B(dec_4bits),
		  .sel(alu_sel),
        .result(alu_result),
        .Z(Z), .C(Carry), .V(V), .S(Sign)
    );
	 
	

	// Conexion SPI a Arduino
    Spi_slave_module spi_unit (
        .clk(FPGA_clk),
        .reset(FPGA_reset),
        .sclk_in(arduino_sclk),
        .mosi_in(arduino_mosi),
        .ss_n_in(arduino_ss_n),
        .spi_data_out(data_from_spi_to_fpga),
        .spi_data_valid_out(data_is_valid_from_spi),
        .miso_out(fpga_physical_miso)
    );

    assign led_outputs = data_from_spi_to_fpga;


    Hex_to_7seg_decoder bcd_decoder_unit (
        .hex_in(data_from_spi_to_fpga),
        .segments_out(segments_from_bcd_units) // Conectar a un wire interno
    );

    assign seven_segment_pins[0] = ~segments_from_bcd_units[0]; // a
    assign seven_segment_pins[1] = ~segments_from_bcd_units[1]; // b
    assign seven_segment_pins[2] = ~segments_from_bcd_units[2]; // c
    assign seven_segment_pins[3] = ~segments_from_bcd_units[3]; // d
    assign seven_segment_pins[4] = ~segments_from_bcd_units[4]; // e
    assign seven_segment_pins[5] = ~segments_from_bcd_units[5]; // f
    assign seven_segment_pins[6] = ~segments_from_bcd_units[6]; // g

endmodule