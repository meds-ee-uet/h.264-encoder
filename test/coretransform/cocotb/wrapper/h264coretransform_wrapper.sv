module h264coretransform_wrapper(
    // Variable/Signals Declaration
    input  logic CLK,
    input  logic [35:0] XXIN,
    input  logic RESET,
    input  logic ENABLE,
    output logic READY,
    output logic VALID,
    output logic [13:0] YNOUT
);


    // Call Module
    h264coretransform DUT(
        .CLK(CLK),
        .XXIN(XXIN),
        .RESET(RESET),
        .ENABLE(ENABLE),
        .READY(READY),
        .VALID(VALID),
        .YNOUT(YNOUT)
    );

initial
begin
    $dumpfile ("wave.vcd");
    $dumpvars;
end

endmodule