module tb_mc_lc;

    parameter MB_SIZE = 4;
    parameter PIXEL_WIDTH = 8;

    logic clk;
    logic reset;
    logic [PIXEL_WIDTH-1:0] ref_frame [0:MB_SIZE-1][0:MB_SIZE-1]; // Reference frame (4x4)
    logic [PIXEL_WIDTH-1:0] curr_mb [0:MB_SIZE-1][0:MB_SIZE-1];   // Current macroblock (4x4)
    logic src_valid;
    logic src_ready;
    logic dst_valid;
    logic dst_ready;
    logic [PIXEL_WIDTH-1:0] residual [0:MB_SIZE-1][0:MB_SIZE-1]; // Residual block (4x4)

    // Instantiate the motion compensation module
    mc_lc #(
        .MB_SIZE(MB_SIZE),
        .PIXEL_WIDTH(PIXEL_WIDTH)
    ) uut (
        .clk(clk),
        .reset(reset),
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
        src_valid = 0;
        dst_ready = 0;

        // Fill reference frame and current macroblock with fixed values
        ref_frame = '{'{1, 2, 3, 4}, '{5, 6, 7, 8}, '{9, 10, 11, 12}, '{13, 14, 15, 16}};
        curr_mb = '{'{16, 15, 14, 13}, '{12, 11, 10, 9}, '{8, 7, 6, 5}, '{4, 3, 2, 1}};

        // Display inputs
        $display("\nReference Frame:");
        for (int i = 0; i < MB_SIZE; i++) begin
            for (int j = 0; j < MB_SIZE; j++) begin
                $write("%3d ", ref_frame[i][j]);
            end
            $display();
        end

        $display("\nCurrent Macroblock:");
        for (int i = 0; i < MB_SIZE; i++) begin
            for (int j = 0; j < MB_SIZE; j++) begin
                $write("%3d ", curr_mb[i][j]);
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

        // Display residual block
        $display("\nResidual Block:");
        for (int i = 0; i < MB_SIZE; i++) begin
            for (int j = 0; j < MB_SIZE; j++) begin
                $write("%3d ", residual[i][j]);
            end
            $display();
        end

        $finish;
    end

endmodule
