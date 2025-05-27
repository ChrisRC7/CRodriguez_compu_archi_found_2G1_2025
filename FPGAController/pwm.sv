module pwm (
    input  logic clk,
    input  logic rst,
    input  logic [3:0] hex_in,
    output logic motor_pwm
);

    reg [7:0] count;
    logic [7:0] motor_speed;

    // Conversión hex_in a PWM (hex_in * 17)
    assign motor_speed = (hex_in << 4) + hex_in;

    // Contador con reset asíncrono (sin if/case/?)
    always_ff @(posedge clk) begin
        count <= {8{~rst}} & (count + 8'h01);  // rst=1 -> count=0; rst=0 -> count+1
    end

    // Generación de PWM
    assign motor_pwm = (count < motor_speed);

endmodule