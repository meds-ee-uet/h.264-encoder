module mc_cr #(
    parameter MB_SIZE = 8,      // Macroblock size (default 8x8)
    parameter PIXEL_WIDTH = 8   // Pixel bit-width (default 8 bits)
)(
    input logic clk,
    input logic reset,

    // Inputs
    input var logic [PIXEL_WIDTH-1:0] ref_frame [0:MB_SIZE-1][0:MB_SIZE-1], // Reference frame (8x8)
    input var logic [PIXEL_WIDTH-1:0] curr_mb [0:MB_SIZE-1][0:MB_SIZE-1],   // Current macroblock (8x8)

    input logic src_valid,              // Source valid signal
    output logic src_ready,             // Source ready signal
    input logic dst_ready,              // Destination ready signal
    output logic dst_valid,             // Destination valid signal

    // Outputs
    output logic [PIXEL_WIDTH-1:0] residual [0:MB_SIZE-1][0:MB_SIZE-1], // Full residual block (8x8)
    output logic [PIXEL_WIDTH-1:0] residual_out [0:1]                   // Residual block output (2 pixels)
);

    logic processing;                  // Indicates if the module is currently processing
    logic [PIXEL_WIDTH-1:0] temp_residual [0:MB_SIZE-1][0:MB_SIZE-1]; // Temporary residual storage
    logic [5:0] pixel_counter;         // Counter to track which 2 pixels to output (64 pixels total)

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset outputs and internal state
            for (int i = 0; i < MB_SIZE; i++) begin
                for (int j = 0; j < MB_SIZE; j++) begin
                    temp_residual[i][j] <= 0;
                    residual[i][j] <= 0;
                end
            end
            processing <= 0;
            dst_valid <= 0;
            src_ready <= 0;
            pixel_counter <= 0;
            residual_out[0] <= 0;
            residual_out[1] <= 0;
        end else begin
            // Ready/Valid Handshake Logic
            if (!processing && src_valid && src_ready) begin
                // Start processing when source is valid and ready
                processing <= 1;
                dst_valid <= 0;

                // Compute residual row by row
                for (int i = 0; i < MB_SIZE; i++) begin
                    for (int j = 0; j < MB_SIZE; j++) begin
                        temp_residual[i][j] <= curr_mb[i][j] - ref_frame[i][j];
                        residual[i][j] <= curr_mb[i][j] - ref_frame[i][j];
                    end
                end
            end else if (processing && dst_ready) begin
                // Output 2 pixels at a time
                if (pixel_counter < 64) begin
                    dst_valid <= 1; // Indicate output is valid
                    residual_out[0] <= temp_residual[pixel_counter / MB_SIZE][(pixel_counter % MB_SIZE)];
                    residual_out[1] <= temp_residual[pixel_counter / MB_SIZE][(pixel_counter % MB_SIZE) + 1];
                    pixel_counter <= pixel_counter + 2; // Move to the next 2 pixels
                end else begin
                    // Done with all outputs
                    dst_valid <= 0;
                    processing <= 0;
                    pixel_counter <= 0; // Reset counter
                end
            end else begin
                // Default behavior
                src_ready <= !processing; // Ready to accept new data only when not processing
            end
        end
    end

endmodule
