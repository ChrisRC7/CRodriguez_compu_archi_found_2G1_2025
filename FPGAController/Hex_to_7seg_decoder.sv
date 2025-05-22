module Hex_to_7seg_decoder (
    input  logic [3:0] hex_in,      // Entrada de 4 bits (0-F)
    output logic [6:0] segments_out // Salida para 7 segmentos (g,f,e,d,c,b,a)
                                    // segments_out[0] = a, segments_out[6] = g
);

    // Asignación de bits de entrada para facilidad de lectura en ecuaciones
    logic s3, s2, s1, s0;
    assign s3 = hex_in[3];
    assign s2 = hex_in[2];
    assign s1 = hex_in[1];
    assign s0 = hex_in[0];

    // Lógica combinacional para decodificar hex_in a segments_out
    // Patrones para cátodo común (1 = segmento ENCENDIDO)
    // segments_out[0] = a, segments_out[1] = b, ..., segments_out[6] = g

    // Segmento 'a' (segments_out[0])
    // ON para: 0, 2, 3, 5, 6, 7, 8, 9, A, C, E, F
    assign segments_out[0] = (~s3 & ~s2 & ~s1 & ~s0) | // 0
                             (~s3 & ~s2 &  s1 & ~s0) | // 2
                             (~s3 & ~s2 &  s1 &  s0) | // 3
                             (~s3 &  s2 & ~s1 &  s0) | // 5
                             (~s3 &  s2 &  s1 & ~s0) | // 6
                             (~s3 &  s2 &  s1 &  s0) | // 7
                             ( s3 & ~s2 & ~s1 & ~s0) | // 8
                             ( s3 & ~s2 & ~s1 &  s0) | // 9
                             ( s3 & ~s2 &  s1 & ~s0) | // A (10)
                             ( s3 &  s2 & ~s1 & ~s0) | // C (12)
                             ( s3 &  s2 &  s1 & ~s0) | // E (14)
                             ( s3 &  s2 &  s1 &  s0);  // F (15)

    // Segmento 'b' (segments_out[1])
    // ON para: 0, 1, 2, 3, 4, 7, 8, 9, A, D
    assign segments_out[1] = (~s3 & ~s2 & ~s1 & ~s0) | // 0
                             (~s3 & ~s2 & ~s1 &  s0) | // 1
                             (~s3 & ~s2 &  s1 & ~s0) | // 2
                             (~s3 & ~s2 &  s1 &  s0) | // 3
                             (~s3 &  s2 & ~s1 & ~s0) | // 4
                             (~s3 &  s2 &  s1 &  s0) | // 7
                             ( s3 & ~s2 & ~s1 & ~s0) | // 8
                             ( s3 & ~s2 & ~s1 &  s0) | // 9
                             ( s3 & ~s2 &  s1 & ~s0) | // A (10)
                             ( s3 &  s2 & ~s1 &  s0);  // D (13)

    // Segmento 'c' (segments_out[2]) - CORREGIDO
    // ON para: 0, 1, 3, 4, 5, 6, 7, 8, 9, A, B, D
    assign segments_out[2] = (~s3 & ~s2 & ~s1 & ~s0) | // 0
                             (~s3 & ~s2 & ~s1 &  s0) | // 1
                             (~s3 & ~s2 &  s1 &  s0) | // 3
                             (~s3 &  s2 & ~s1 & ~s0) | // 4
                             (~s3 &  s2 & ~s1 &  s0) | // 5
                             (~s3 &  s2 &  s1 & ~s0) | // 6
                             (~s3 &  s2 &  s1 &  s0) | // 7
                             ( s3 & ~s2 & ~s1 & ~s0) | // 8
                             ( s3 & ~s2 & ~s1 &  s0) | // 9
                             ( s3 & ~s2 &  s1 & ~s0) | // A (10)
                             ( s3 & ~s2 &  s1 &  s0) | // B (11)
                             ( s3 &  s2 & ~s1 &  s0);  // D (13) <-- TÉRMINO AÑADIDO

    // Segmento 'd' (segments_out[3])
    // ON para: 0, 2, 3, 5, 6, 8, B, C, D, E
    assign segments_out[3] = (~s3 & ~s2 & ~s1 & ~s0) | // 0
                             (~s3 & ~s2 &  s1 & ~s0) | // 2
                             (~s3 & ~s2 &  s1 &  s0) | // 3
                             (~s3 &  s2 & ~s1 &  s0) | // 5
                             (~s3 &  s2 &  s1 & ~s0) | // 6
                             ( s3 & ~s2 & ~s1 & ~s0) | // 8
                             ( s3 & ~s2 &  s1 &  s0) | // B (11)
                             ( s3 &  s2 & ~s1 & ~s0) | // C (12)
                             ( s3 &  s2 & ~s1 &  s0) | // D (13)
                             ( s3 &  s2 &  s1 & ~s0);  // E (14)

    // Segmento 'e' (segments_out[4]) - CORREGIDO
    // ON para: 0, 2, 6, 8, A, B, C, D, E, F
    assign segments_out[4] = (~s3 & ~s2 & ~s1 & ~s0) | // 0
                             (~s3 & ~s2 &  s1 & ~s0) | // 2
                             (~s3 &  s2 &  s1 & ~s0) | // 6
                             ( s3 & ~s2 & ~s1 & ~s0) | // 8
                             ( s3 & ~s2 &  s1 & ~s0) | // A (10)
                             ( s3 & ~s2 &  s1 &  s0) | // B (11) <-- TÉRMINO AÑADIDO
                             ( s3 &  s2 & ~s1 & ~s0) | // C (12)
                             ( s3 &  s2 & ~s1 &  s0) | // D (13)
                             ( s3 &  s2 &  s1 & ~s0) | // E (14)
                             ( s3 &  s2 &  s1 &  s0);  // F (15)

    // Segmento 'f' (segments_out[5])
    // ON para: 0, 4, 5, 6, 8, 9, A, B, C, E, F
    assign segments_out[5] = (~s3 & ~s2 & ~s1 & ~s0) | // 0
                             (~s3 &  s2 & ~s1 & ~s0) | // 4
                             (~s3 &  s2 & ~s1 &  s0) | // 5
                             (~s3 &  s2 &  s1 & ~s0) | // 6
                             ( s3 & ~s2 & ~s1 & ~s0) | // 8
                             ( s3 & ~s2 & ~s1 &  s0) | // 9
                             ( s3 & ~s2 &  s1 & ~s0) | // A (10)
                             ( s3 & ~s2 &  s1 &  s0) | // B (11)
                             ( s3 &  s2 & ~s1 & ~s0) | // C (12)
                             ( s3 &  s2 &  s1 & ~s0) | // E (14)
                             ( s3 &  s2 &  s1 &  s0);  // F (15)

    // Segmento 'g' (segments_out[6])
    // ON para: 2, 3, 4, 5, 6, 8, 9, A, B, D, E, F
    assign segments_out[6] = (~s3 & ~s2 &  s1 & ~s0) | // 2
                             (~s3 & ~s2 &  s1 &  s0) | // 3
                             (~s3 &  s2 & ~s1 & ~s0) | // 4
                             (~s3 &  s2 & ~s1 &  s0) | // 5
                             (~s3 &  s2 &  s1 & ~s0) | // 6
                             ( s3 & ~s2 & ~s1 & ~s0) | // 8
                             ( s3 & ~s2 & ~s1 &  s0) | // 9
                             ( s3 & ~s2 &  s1 & ~s0) | // A (10)
                             ( s3 & ~s2 &  s1 &  s0) | // B (11)
                             ( s3 &  s2 & ~s1 &  s0) | // D (13)
                             ( s3 &  s2 &  s1 & ~s0) | // E (14)
                             ( s3 &  s2 &  s1 &  s0);  // F (15)

endmodule