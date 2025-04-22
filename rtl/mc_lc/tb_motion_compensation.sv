module tb_motion_compensation;

    parameter MB_SIZE = 4;       // Macroblock size (default 4x4)
    parameter PIXEL_WIDTH = 8;   // Pixel bit-width (default 8 bits)
    parameter NUM_ARRAYS = 4;    // Number of input arrays to process

    logic clk;
    logic reset;
    logic [(PIXEL_WIDTH*MB_SIZE)-1:0] ref_frame; // Reference frame (array)
    logic [(PIXEL_WIDTH*MB_SIZE)-1:0] curr_mb;   // Current macroblock (array)
    logic src_valid;
    logic src_ready;
    logic dst_valid;
    logic dst_ready;
    logic [(PIXEL_WIDTH*MB_SIZE)-1:0] residual; // Residual block (array)

    // Array of reference frames and current macroblocks
    logic [(PIXEL_WIDTH*MB_SIZE)-1:0] ref_frames [0:NUM_ARRAYS-1];
    logic [(PIXEL_WIDTH*MB_SIZE)-1:0] curr_mbs [0:NUM_ARRAYS-1];

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

        // Fill reference frames and current macroblocks with fixed values
        ref_frames[0] = {8'd55, 8'd23, 8'd1, 8'd2};   // Array 1: {55, 23, 1, 2}
        ref_frames[1] = {8'd10, 8'd15, 8'd20, 8'd25}; // Array 2: {10, 15, 20, 25}
        ref_frames[2] = {8'd30, 8'd35, 8'd40, 8'd45}; // Array 3: {30, 35, 40, 45}
        ref_frames[3] = {8'd50, 8'd55, 8'd60, 8'd65}; // Array 4: {50, 55, 60, 65}

        curr_mbs[0] = {8'd60, 8'd30, 8'd5, 8'd10};    // Array 1: {60, 30, 5, 10}
        curr_mbs[1] = {8'd15, 8'd20, 8'd25, 8'd30};   // Array 2: {15, 20, 25, 30}
        curr_mbs[2] = {8'd35, 8'd40, 8'd45, 8'd50};   // Array 3: {35, 40, 45, 50}
        curr_mbs[3] = {8'd55, 8'd60, 8'd65, 8'd70};   // Array 4: {55, 60, 65, 70}

        // Release reset
        #10 reset = 0;

        // Process arrays sequentially
        for (int arr_idx = 0; arr_idx < NUM_ARRAYS; arr_idx++) begin
            // Load the current array
            ref_frame = ref_frames[arr_idx];
            curr_mb = curr_mbs[arr_idx];

            // Display inputs
            $display("\nProcessing Array %d:", arr_idx);
            $display("Reference Frame: {");
            for (int i = 0; i < MB_SIZE; i++) begin
                $write("%d", ref_frame[(i+1)*PIXEL_WIDTH-1 -: PIXEL_WIDTH]);
                if (i != MB_SIZE - 1) $write(", ");
            end
            $display("}");

            $display("Current Macroblock: {");
            for (int i = 0; i < MB_SIZE; i++) begin
                $write("%d", curr_mb[(i+1)*PIXEL_WIDTH-1 -: PIXEL_WIDTH]);
                if (i != MB_SIZE - 1) $write(", ");
            end
            $display("}");

            // Drive the handshake signals
            src_valid = 1;
            #10 dst_ready = 1;

            // Wait for computation to finish
            while (!dst_valid) @(posedge clk);

            // Display residual block
            $display("Residual Block: {");
            for (int i = 0; i < MB_SIZE; i++) begin
                $write("%d", residual[(i+1)*PIXEL_WIDTH-1 -: PIXEL_WIDTH]);
                if (i != MB_SIZE - 1) $write(", ");
            end
            $display("}");

            // Reset handshake signals for the next array
            src_valid = 0;
            dst_ready = 0;
            #10; // Small delay before processing the next array
        end

        $finish;
    end

endmodule
