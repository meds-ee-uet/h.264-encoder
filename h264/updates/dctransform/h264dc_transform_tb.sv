module h264dc_transform_tb;

    // Parameters
    parameter int TOGETHER = 0; // Can be changed to 1 for testing the together output case

    // Testbench signals
    logic CLK;
    logic RESET;
    logic READYI;
    logic ENABLE;
    logic [15:0] XXIN;
    logic VALID;
    logic [15:0] YYOUT;
    logic READYO;

    // Instantiate the DUT (Device Under Test)
    h264dc_transform #(
        .TOGETHER(TOGETHER)
    ) dut (
        .CLK(CLK),
        .RESET(RESET),
        .READYI(READYI),
        .ENABLE(ENABLE),
        .XXIN(XXIN),
        .VALID(VALID),
        .YYOUT(YYOUT),
        .READYO(READYO)
    );

    // Clock generation
    initial begin
        CLK = 0;
        forever #5 CLK = ~CLK; // 100 MHz clock
    end

    // Reset procedure
    initial begin
        RESET = 1;
        ENABLE = 0;
        XXIN = 16'd0;
        READYO = 0;
        @(posedge CLK);
        RESET = 0;
        @(posedge CLK);
        RESET = 0;
        @(posedge CLK);
        RESET = 0;
        @(posedge CLK);
        RESET = 0;
        @(posedge CLK);
        RESET = 0;
        @(posedge CLK);
        RESET = 0;
        @(posedge CLK);
        ENABLE = 1;
        // Apply test vectors
        apply_test_vectors();

        // Finish the simulation after some time
        repeat(20)@(posedge CLK);
        $stop;
    end

    // Task to apply test vectors
    task apply_test_vectors;
        begin
            // Test Vector 1
            XXIN = 16'd1; READYO = 1; @(posedge CLK);
            XXIN = 16'd2; READYO = 1; @(posedge CLK);
            XXIN = 16'd3; READYO = 1; @(posedge CLK);
            XXIN = 16'd4; READYO = 1; @(posedge CLK);

            // Test Vector 2
            ENABLE = 0; @(posedge CLK);
            ENABLE = 1;
            XXIN = 16'd5; READYO = 1; @(posedge CLK);
            XXIN = 16'd6; READYO = 1; @(posedge CLK);
            XXIN = 16'd7; READYO = 1; @(posedge CLK);
            XXIN = 16'd8; READYO = 1; @(posedge CLK);
        end
    endtask

    // Monitor outputs
    initial begin
        $monitor("Time: %0t | ENABLE: %b | XXIN: %h | VALID: %b | YYOUT: %h | READYI: %b | READYO: %b",
                 $time, ENABLE, XXIN, VALID, YYOUT, READYI, READYO);
    end

endmodule
