module tb_mc;

    parameter MB_SIZE = 4;
    parameter PIXEL_WIDTH = 8;
    parameter REF_FRAME_SIZE = 8;

    logic clk;
    logic reset;
    logic [5:0] mv_x, mv_y;
    logic [PIXEL_WIDTH-1:0] ref_frame [0:REF_FRAME_SIZE-1][0:REF_FRAME_SIZE-1];
    logic [PIXEL_WIDTH-1:0] curr_mb [0:MB_SIZE-1][0:MB_SIZE-1];
    logic src_valid;
    logic src_ready;
    logic dst_valid;
    logic dst_ready;
    logic [PIXEL_WIDTH-1:0] residual [0:MB_SIZE-1][0:MB_SIZE-1];

    // Instantiate the motion compensation module
    mc #(
        .MB_SIZE(MB_SIZE),
        .PIXEL_WIDTH(PIXEL_WIDTH),
        .REF_FRAME_SIZE(REF_FRAME_SIZE)
    ) uut (
        .clk(clk),
        .reset(reset),
        .mv_x(mv_x),
        .mv_y(mv_y),
        .ref_frame(ref_frame),
        .curr_mb(curr_mb),
        .src_valid(src_valid),
        .src_ready(src_ready),
        .dst_valid(dst_valid),
        .dst_ready(dst_ready),
        .residual(residual)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        // Initialize inputs
        clk = 0;
        reset = 1;
        mv_x = 1; // Example motion vector
        mv_y = 1;
        src_valid = 0;
        dst_ready = 0;

        // Fill reference frame and current macroblock with random values
        for (int i = 0; i < REF_FRAME_SIZE; i++) begin
            for (int j = 0; j < REF_FRAME_SIZE; j++) begin
                ref_frame[i][j] = $random % 256;
            end
        end
        for (int i = 0; i < MB_SIZE; i++) begin
            for (int j = 0; j < MB_SIZE; j++) begin
                curr_mb[i][j] = $random % 256;
            end
        end
        
        // Display Current Macroblock
        $display("\nCurrent Macroblock:");
        for (int i = 0; i < MB_SIZE; i++) begin
            for (int j = 0; j < MB_SIZE; j++) begin
                $write("%3d ", curr_mb[i][j]);
            end
            $display();
        end

        // Display Reference Frame
        $display("\nReference Frame:");
        for (int i = 0; i < REF_FRAME_SIZE; i++) begin
            for (int j = 0; j < REF_FRAME_SIZE; j++) begin
                $write("%3d ", ref_frame[i][j]);
            end
            $display();
        end

        // Release reset
        #10 reset = 0;

        // Drive the handshake signals
        #10 src_valid = 1;
        #20 dst_ready = 1;

        // Wait for computation to finish
        repeat (10) @(posedge clk);

        // Display row-by-row residual values
        for (int i = 0; i < MB_SIZE; i++) begin
            $display("\nResidual Row %0d:", i);
            for (int j = 0; j < MB_SIZE; j++) begin
                $write("%3d ", residual[i][j]);
            end
            $display();
        end

        // Display full residual block
        $display("\nComplete Residual Block:");
        for (int i = 0; i < MB_SIZE; i++) begin
            for (int j = 0; j < MB_SIZE; j++) begin
                $write("%3d ", residual[i][j]);
            end
            $display();
        end

        $finish;
    end

endmodule
