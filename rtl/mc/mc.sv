module mc #(
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

    input logic src_valid,              // Source valid signal
    output logic src_ready,             // Source ready signal
    input logic dst_ready,              // Destination ready signal
    output logic dst_valid,             // Destination valid signal

    // Outputs
    output logic [PIXEL_WIDTH-1:0] residual [0:MB_SIZE-1][0:MB_SIZE-1] // Residual block (4x4)
);

    // Internal state for processing
    logic processing;                  // Indicates if the module is currently processing
    logic [PIXEL_WIDTH-1:0] temp_residual [0:MB_SIZE-1][0:MB_SIZE-1]; // Temporary residual storage

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset outputs and internal state
            for (int i = 0; i < MB_SIZE; i++) begin
                for (int j = 0; j < MB_SIZE; j++) begin
                    residual[i][j] <= 0;
                end
            end
            processing <= 0;
            dst_valid <= 0;
            src_ready <= 0;
        end else begin
            // Ready/Valid Handshake Logic
            if (!processing && src_valid && src_ready) begin
                // Start processing when source is valid and ready
                processing <= 1;
                dst_valid <= 0;

                // Compute residual row by row
                for (int i = 0; i < MB_SIZE; i++) begin
                    for (int j = 0; j < MB_SIZE; j++) begin
                        temp_residual[i][j] <= curr_mb[i][j] - ref_frame[i + mv_y][j + mv_x];
                    end
                end
            end else if (processing && dst_ready) begin
                // Transfer residual data to output when destination is ready
                for (int i = 0; i < MB_SIZE; i++) begin
                    for (int j = 0; j < MB_SIZE; j++) begin
                        residual[i][j] <= temp_residual[i][j];
                    end
                end
                dst_valid <= 1; // Indicate that the output is valid
                processing <= 0; // Reset processing flag
            end else begin
                // Default behavior
                src_ready <= !processing; // Ready to accept new data only when not processing
            end
        end
    end

endmodule
