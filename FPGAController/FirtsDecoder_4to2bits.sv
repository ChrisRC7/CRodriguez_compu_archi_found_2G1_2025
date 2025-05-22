// deco
//1000 -> 00
//0100 -> 01
//0010 -> 10
//0001 -> 11

module FirtsDecoder_4to2bits(
    input logic A, B, C, D,
    output logic Y1, Y0
);

    or (Y1, C, D);
    or (Y0, B, D);


endmodule