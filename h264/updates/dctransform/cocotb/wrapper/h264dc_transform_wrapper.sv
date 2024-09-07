module h264dc_transform_wrapper(
    // Variable/Signals Declaration
    input  logic CLK,                  // fast clock
    input  logic RESET,                // reset when 1
    output logic READYI,         // set when ready for ENABLE
    input  logic ENABLE,               // values input only when th
    input  logic [15:0] XXIN,          // input data values (revers
    output logic VALID,          // values output only when t
    output logic [15:0] YYOUT,  // output values (reverse ord
    input  logic READYO                // set when ready for ENABLE
);

    parameter int TOGETHER = 0; // Can be changed to 1 for testing the together output case



    // Call Module
    h264dc_transform #(
        .TOGETHER(TOGETHER)
    ) DUT(
        .CLK(CLK),
        .RESET(RESET),
        .READYI(READYI),
        .ENABLE(ENABLE),
        .XXIN(XXIN),
        .VALID(VALID),
        .YYOUT(YYOUT),
        .READYO(READYO)
    );

initial
begin
    $dumpfile ("wave.vcd");
    $dumpvars;
end

endmodule