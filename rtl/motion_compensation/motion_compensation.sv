module motion_compensation #(
    parameter MB_SIZE = 4,      // Macroblock size (default 4x4)
    parameter PIXEL_WIDTH = 8,  // Pixel bit-width (default 8 bits)
    parameter REF_FRAME_SIZE = 8 // Reference frame size (default 8x8)
)(
    input logic clk,
    input logic reset,

    // Inputs
    input logic [5:0] mv_x,             // Motion vector x (6 bits)
    input logic [5:0] mv_y,             // Motion vector y (6 bits)
    input var logic [PIXEL_WIDTH-1:0] ref_frame [0:REF_FRAME_SIZE-1][0:REF_FRAME_SIZE-1], // Reference frame (8x8)
    input var logic [PIXEL_WIDTH-1:0] curr_mb [0:MB_SIZE-1][0:MB_SIZE-1],  // Current macroblock (4x4)

    // Outputs
    output logic [PIXEL_WIDTH-1:0] residual [0:MB_SIZE-1][0:MB_SIZE-1] // Residual block (4x4)
);

    // Internal signals
    logic [PIXEL_WIDTH-1:0] ref_mb [0:MB_SIZE-1][0:MB_SIZE-1]; // Reference macroblock fetched using MVs

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset all outputs
            for (int i = 0; i < MB_SIZE; i++) begin
                for (int j = 0; j < MB_SIZE; j++) begin
                    residual[i][j] <= 0;
                end
            end
        end else begin
            // Step 1: Fetch reference macroblock from reference frame using motion vectors
            for (int i = 0; i < MB_SIZE; i++) begin
                for (int j = 0; j < MB_SIZE; j++) begin
                    // Directly fetch the pixel from the reference frame without boundary checking
                    ref_mb[i][j] <= ref_frame[i + mv_y][j + mv_x];
                end
            end

            // Step 2: Compute residual by subtracting reference macroblock from current macroblock
            for (int i = 0; i < MB_SIZE; i++) begin
                for (int j = 0; j < MB_SIZE; j++) begin
                    residual[i][j] <= curr_mb[i][j] - ref_mb[i][j];
                end
            end
        end
    end

endmodule
