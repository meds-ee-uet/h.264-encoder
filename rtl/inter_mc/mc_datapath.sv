module mc_datapath #(
    parameter MB_SIZE     = 4,
    parameter N_DC        = 4,
    parameter PIXEL_WIDTH = 8
)(
    input  logic clk,
    input  logic reset,

    input  logic load_curr,
    input  logic load_ref,
    input  logic output_residual_row,
    input  logic start_dc_calc,
    input  logic output_dcco,

    input  logic ccin,  // Raw input

    input  var logic [(PIXEL_WIDTH*MB_SIZE)-1:0] ref_frame,
    input  var logic [(PIXEL_WIDTH*MB_SIZE)-1:0] curr_mb,

    output logic [3:0]  row_count,
    output logic [15:0] dcco,
    output logic        dcco_valid,
    input  logic [3:0]  dc_count,
    output logic [3:0]  dcco_count,
    output logic [(PIXEL_WIDTH*MB_SIZE)-1:0] residual,

    output logic ccin_reg  // <-- New output
);

    //-------------------------------------
    // Data Buffers
    //-------------------------------------

    logic [PIXEL_WIDTH-1:0] curr_block [0:MB_SIZE-1][0:MB_SIZE-1];
    logic [PIXEL_WIDTH-1:0] ref_block [0:MB_SIZE-1][0:MB_SIZE-1];

    //-------------------------------------
    // DC Coefficient Storage
    //-------------------------------------

    logic [15:0] dc_coeff [0:N_DC-1];
    logic [15:0] curr_sum;
    logic [15:0] ref_sum;

    //-------------------------------------
    // Main Logic
    //-------------------------------------

    always_comb
    begin
        //-------------------------------------
            // Compute Residual Row
            //-------------------------------------

            if (output_residual_row) 
            begin
                // for (int i = 0; i < MB_SIZE; i++) 
                // begin
                //     residual[(i+1)*PIXEL_WIDTH - 1 -: PIXEL_WIDTH] <=
                //         curr_block[row_count][i] - ref_block[row_count][i];
                // end
                residual[7:0]   <= curr_block[row_count][0] - ref_block[row_count][0];
                residual[15:8]  <= curr_block[row_count][1] - ref_block[row_count][1];
                residual[23:16] <= curr_block[row_count][2] - ref_block[row_count][2];    
                residual[32:24] <= curr_block[row_count][3] - ref_block[row_count][3];    
            end
    end

    always_ff @(posedge clk or posedge reset) 
    begin
    if (reset) 
    begin
        ccin_reg <= 0;
    end 
    else 
    begin
        if (load_curr && row_count == 0) 
        begin
            ccin_reg <= ccin;
        end
    end
    end

    always_ff @(posedge clk or posedge reset) 
    begin
        if (reset) 
        begin
            curr_sum     <= 0;
            ref_sum      <= 0;
            dcco_valid   <= 0;
            dcco_count     <= 0;
            row_count    <= 0;
        end 
        else 
        begin
            dcco_valid <= 0;

            //-------------------------------------
            // Load Current Block
            //-------------------------------------

            if (load_curr) 
            begin
                for (int i = 0; i < MB_SIZE; i++) 
                begin
                    curr_block[row_count][i] <= curr_mb[(i+1)*PIXEL_WIDTH - 1 -: PIXEL_WIDTH];
                end
                curr_sum <= curr_sum + curr_mb;
            end

            //-------------------------------------
            // Load Reference Block
            //-------------------------------------

            if (load_ref) 
            begin
                for (int i = 0; i < MB_SIZE; i++) 
                begin
                    ref_block[row_count][i] <= ref_frame[(i+1)*PIXEL_WIDTH - 1 -: PIXEL_WIDTH];
                end
                ref_sum <= ref_sum + ref_frame;
            end

            //-------------------------------------
            // Output DC Coefficients
            //-------------------------------------

            if (output_dcco) 
            begin
                dcco_valid <= 1;
                dcco <= dc_coeff[dcco_count];
                if (dcco_count < N_DC - 1) 
                begin
                    dcco_count <= dcco_count + 1;
                end 
                else 
                begin
                    dcco_count <= 0;
                end
            end
            else
            begin
                dcco_count <= 0;
            end

            //-------------------------------------
            // Start DC Calculation
            //-------------------------------------

            if (start_dc_calc && row_count == MB_SIZE - 1) 
            begin
                dc_coeff[dc_count] <= curr_sum - ref_sum;
            end

            //-------------------------------------
            // Row Counter
            //-------------------------------------

            if (load_curr || load_ref || output_residual_row)
            begin
                if (row_count < MB_SIZE - 1) 
                    begin
                        row_count <= row_count + 1;
                    end
                else
                    begin
                        row_count <= '0;
                    end
            end
            else
            begin
                if (row_count == MB_SIZE)
                begin
                    row_count <= '0;
                end
            end
        end
    end

endmodule