module tb_motion_compensation;

    parameter MB_SIZE = 4;
    parameter PIXEL_WIDTH = 8;

    logic clk;
    logic reset;
    logic [(PIXEL_WIDTH*MB_SIZE)-1:0] ref_frame; // Reference frame (array)
    logic [(PIXEL_WIDTH*MB_SIZE)-1:0] curr_mb;   // Current macroblock (array)
    logic src_valid;
    logic src_ready;
    logic dst_valid;
    logic dst_ready;
    logic [(PIXEL_WIDTH*MB_SIZE)-1:0] residual; // Residual block (array)

    // Instantiate the motion compensation module
    motion_compensation #(
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
        ref_frame = {8'd55, 8'd23, 8'd1, 8'd2};   // Array: {55, 23, 1, 2}
        curr_mb = {8'd60, 8'd30, 8'd5, 8'd10};    // Array: {60, 30, 5, 10}

        // Display inputs
        $display("\nReference Frame:");
        $write("{");
        for (int i = 0; i < MB_SIZE; i++) begin
            $write("%d", ref_frame[(i+1)*PIXEL_WIDTH-1 -: PIXEL_WIDTH]);
            if (i != MB_SIZE - 1) $write(", ");
        end
        $display("}");

        $display("\nCurrent Macroblock:");
        $write("{");
        for (int i = 0; i < MB_SIZE; i++) begin
            $write("%d", curr_mb[(i+1)*PIXEL_WIDTH-1 -: PIXEL_WIDTH]);
            if (i != MB_SIZE - 1) $write(", ");
        end
        $display("}");

        // Release reset
        #10 reset = 0;

        // Drive the handshake signals
        #10 src_valid = 1;
        #20 dst_ready = 1;

        // Wait for computation to finish
        repeat (10) @(posedge clk);

        // Display residual block
        $display("\nResidual Block:");
        $write("{");
        for (int i = 0; i < MB_SIZE; i++) begin
            $write("%d", residual[(i+1)*PIXEL_WIDTH-1 -: PIXEL_WIDTH]);
            if (i != MB_SIZE - 1) $write(", ");
        end
        $display("}");

        $finish;
    end

endmodule
