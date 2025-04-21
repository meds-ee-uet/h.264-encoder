module tb_mc_cr;

    parameter MB_SIZE = 8;        // Macroblock size (8x8)
    parameter PIXEL_WIDTH = 8;    // Pixel bit-width (8 bits)

    logic clk;
    logic reset;
    logic [PIXEL_WIDTH-1:0] ref_frame [0:MB_SIZE-1][0:MB_SIZE-1]; // Reference frame (8x8)
    logic [PIXEL_WIDTH-1:0] curr_mb [0:MB_SIZE-1][0:MB_SIZE-1];   // Current macroblock (8x8)
    logic src_valid;
    logic src_ready;
    logic dst_valid;
    logic dst_ready;
    logic [PIXEL_WIDTH-1:0] residual [0:MB_SIZE-1][0:MB_SIZE-1]; // Full residual block
    logic [PIXEL_WIDTH-1:0] residual_out [0:1]; // Residual block output (2 pixels)

    // Instantiate the motion compensation module
    mc_cr #(
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
        .residual(residual),       // Connect the full residual block
        .residual_out(residual_out)
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
        ref_frame = '{
            '{1, 2, 3, 4, 5, 6, 7, 8},
            '{9, 10, 11, 12, 13, 14, 15, 16},
            '{17, 18, 19, 20, 21, 22, 23, 24},
            '{25, 26, 27, 28, 29, 30, 31, 32},
            '{33, 34, 35, 36, 37, 38, 39, 40},
            '{41, 42, 43, 44, 45, 46, 47, 48},
            '{49, 50, 51, 52, 53, 54, 55, 56},
            '{57, 58, 59, 60, 61, 62, 63, 64}
        };

        curr_mb = '{
            '{64, 63, 62, 61, 60, 59, 58, 57},
            '{56, 55, 54, 53, 52, 51, 50, 49},
            '{48, 47, 46, 45, 44, 43, 42, 41},
            '{40, 39, 38, 37, 36, 35, 34, 33},
            '{32, 31, 30, 29, 28, 27, 26, 25},
            '{24, 23, 22, 21, 20, 19, 18, 17},
            '{16, 15, 14, 13, 12, 11, 10, 9},
            '{8, 7, 6, 5, 4, 3, 2, 1}
        };

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
        repeat (20) @(posedge clk);

        // Display full residual block
        $display("\nFull Residual Block:");
        for (int i = 0; i < MB_SIZE; i++) begin
            for (int j = 0; j < MB_SIZE; j++) begin
                $write("%3d ", residual[i][j]);
            end
            $display();
        end

        // Display residual block output (2 pixels at a time)
        $display("\nResidual Block Output (2 pixels at a time):");
        repeat (32) @(posedge clk) begin
            if (dst_valid) begin
                $display("Pixels: %3d, %3d", residual_out[0], residual_out[1]);
            end
        end

        $finish;
    end

endmodule
