module tb_motion_compensation;

    parameter MB_SIZE = 4;
    parameter PIXEL_WIDTH = 8;
    parameter REF_FRAME_SIZE = 8;

    logic clk;
    logic reset;
    logic [5:0] mv_x, mv_y;
    logic [PIXEL_WIDTH-1:0] ref_frame [0:REF_FRAME_SIZE-1][0:REF_FRAME_SIZE-1];
    logic [PIXEL_WIDTH-1:0] curr_mb [0:MB_SIZE-1][0:MB_SIZE-1];
    logic [PIXEL_WIDTH-1:0] residual [0:MB_SIZE-1][0:MB_SIZE-1];

    // Instantiate the motion compensation module
    motion_compensation #(.MB_SIZE(MB_SIZE), .PIXEL_WIDTH(PIXEL_WIDTH), .REF_FRAME_SIZE(REF_FRAME_SIZE)) uut (
        .clk(clk),
        .reset(reset),
        .mv_x(mv_x),
        .mv_y(mv_y),
        .ref_frame(ref_frame),
        .curr_mb(curr_mb),
        .residual(residual)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        // Initialize inputs
        clk = 0;
        reset = 1;
        mv_x = 1; // Example motion vector
        mv_y = 3;

        // Initialize reference frame and current macroblock
        for (int i = 0; i < REF_FRAME_SIZE; i++) begin
            for (int j = 0; j < REF_FRAME_SIZE; j++) begin
                ref_frame[i][j] = $random % 256; // Random pixel values
            end
        end

        for (int i = 0; i < MB_SIZE; i++) begin
            for (int j = 0; j < MB_SIZE; j++) begin
                curr_mb[i][j] = $random % 256;
            end
        end

        // Release reset
        #10 reset = 0;

        // Wait for computation
        #20;

        // Display results
        $display("Residual Block:");
        for (int i = 0; i < MB_SIZE; i++) begin
            for (int j = 0; j < MB_SIZE; j++) begin
                $write("%d ", residual[i][j]);
            end
            $display();
        end

        $finish;
    end

endmodule
