module motion_compensation #(
    parameter MB_SIZE = 4,      // Macroblock size (default 4x4)
    parameter PIXEL_WIDTH = 8   // Pixel bit-width (default 8 bits)
)(
    input logic clk,
    input logic reset,

    // Inputs
    input var logic [(PIXEL_WIDTH*MB_SIZE) - 1:0] ref_frame, // Reference frame (array)
    input var logic [(PIXEL_WIDTH*MB_SIZE) - 1:0] curr_mb,   // Current macroblock (array)

    input logic src_valid,              // Source valid signal
    output logic src_ready,             // Source ready signal
    input logic dst_ready,              // Destination ready signal
    output logic dst_valid,             // Destination valid signal

    // Outputs
    output logic [(PIXEL_WIDTH*MB_SIZE) - 1:0] residual // Residual block (array)
);

    logic processing; // Indicates if the module is currently processing

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset outputs and internal state
            residual <= 0;
            processing <= 0;
            dst_valid <= 0;
            src_ready <= 0;
        end else begin
            // Ready/Valid Handshake Logic
            if (!processing && src_valid && src_ready) begin
                // Start processing when source is valid and ready
                processing <= 1;
                dst_valid <= 0;

                // Compute residual for each segment of the array
                for (int i = 0; i < MB_SIZE; i++) begin
                    residual[(PIXEL_WIDTH*(i+1))-1 -: PIXEL_WIDTH] <= 
                        curr_mb[(PIXEL_WIDTH*(i+1))-1 -: PIXEL_WIDTH] - 
                        ref_frame[(PIXEL_WIDTH*(i+1))-1 -: PIXEL_WIDTH];
                end
            end else if (processing && dst_ready) begin
                // Transfer residual data to output when destination is ready
                dst_valid <= 1; // Indicate that the output is valid
                processing <= 0; // Reset processing flag
            end else begin
                // Default behavior
                src_ready <= !processing; // Ready to accept new data only when not processing
            end
        end
    end

endmodule
