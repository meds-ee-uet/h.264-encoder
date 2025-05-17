module mc_controller #(
    parameter MB_SIZE = 4,
    parameter N_DC    = 4
)(
    input  logic clk,
    input  logic reset,

    input  logic ccin_reg,

    input  logic src_valid,
    input  logic dst_ready,

    input  logic [3:0] row_count,
    input  logic [3:0] dcco_count,
    output logic [3:0] dc_count,

    output logic src_ready,
    output logic dst_valid,

    output logic load_curr,
    output logic load_ref,
    output logic output_residual_row,

    output logic start_dc_calc,
    output logic output_dcco,

    output logic XXINC,
    output logic CC_XXINC
);

    typedef enum logic [2:0] {
        IDLE,
        RECEIVE_ROWS,
        OUTPUT_RESIDUALS,
        OUTPUT_DC_COEFFS
    } state_t;

    state_t state_reg, state_next;

    logic xxinc_pulse;
    logic cc_xxinc_pulse;

    logic [3:0] luma_block_counter;     // 16 x 4x4 blocks = 16x16 luma
    logic [3:0] chroma_block_counter;   // 8 x 4x4 blocks = 2×8x8 chroma

    //-------------------------------------
    // State Register + Counter Updates
    //-------------------------------------

    always_ff @(posedge clk or posedge reset) 
    begin
        if (reset) 
        begin
            state_reg            <= IDLE;
            luma_block_counter   <= 0;
            chroma_block_counter <= 0;
            xxinc_pulse          <= 0;
            cc_xxinc_pulse       <= 0;
        end 
        else 
        begin
            state_reg <= state_next;

            if (xxinc_pulse || cc_xxinc_pulse)
            begin
                xxinc_pulse <= 0;
                cc_xxinc_pulse <= 0;
            end

            case (state_reg)
                OUTPUT_RESIDUALS: 
                begin
                    if (row_count == MB_SIZE - 1 && dst_ready) 
                    begin
                        if (!ccin_reg) begin
                            if (luma_block_counter == 15) 
                            begin
                                xxinc_pulse <= 1;
                                luma_block_counter <= 0;
                            end 
                            else 
                            begin
                                luma_block_counter <= luma_block_counter + 1;
                            end
                        end 
                        else 
                        begin
                            if (chroma_block_counter == 7) 
                            begin
                                cc_xxinc_pulse <= 1;
                                chroma_block_counter <= 0;
                            end 
                            else 
                            begin
                                chroma_block_counter <= chroma_block_counter + 1;
                            end
                        end
                    end

                    if (row_count == MB_SIZE - 1 && dst_ready)
                    begin
                        if (ccin_reg)
                            dc_count <= dc_count + 1;
                    end
                    else
                    begin
                        if (dc_count >= N_DC || !ccin_reg)
                            dc_count <= 0;
                        else
                            dc_count <= dc_count;
                    end
                end
            endcase
        end
    end

    //-------------------------------------
    // Next State Logic
    //-------------------------------------

    always_comb begin
        state_next = state_reg;

        case (state_reg)
            IDLE:
                if (row_count == MB_SIZE - 1 && src_valid)
                    state_next = OUTPUT_RESIDUALS;

            OUTPUT_RESIDUALS:
            begin
                if (row_count == MB_SIZE - 1 && dst_ready)
                begin
                    if (dc_count == MB_SIZE - 1)
                        state_next = OUTPUT_DC_COEFFS;
                    else
                        state_next = IDLE;
                end
            end

            OUTPUT_DC_COEFFS:
                if (dcco_count == N_DC - 1 && dst_ready)
                    state_next = IDLE;
                else
                    state_next = OUTPUT_DC_COEFFS;

            default: 
                state_next = IDLE;
        endcase
    end

    //-------------------------------------
    // Output Control Logic
    //-------------------------------------

    always_comb begin
        src_ready           = 0;
        dst_valid           = 0;
        load_curr           = 0;
        load_ref            = 0;
        output_residual_row = 0;
        start_dc_calc       = 0;
        output_dcco         = 0;

        case (state_reg)
            IDLE: 
            begin
                src_ready = 1;
                if (src_valid)
                begin
                    load_curr = 1;
                    load_ref  = 1;
                end
            end

            OUTPUT_RESIDUALS: 
            begin
                if (dst_ready)
                begin
                    dst_valid           = 1;
                    output_residual_row = 1;
                    start_dc_calc       = 1;
                end
            end

            OUTPUT_DC_COEFFS: 
            begin
                dst_valid   = 0;
                // output_dcco = 1;
                // start_dc_calc = 1;
                if (dst_ready)
                begin
                    output_dcco = 1;
                end
            end
        endcase
    end

    //-------------------------------------
    // Pulse Outputs
    //-------------------------------------

    always_ff @(posedge clk or posedge reset) 
    begin
        if (reset) 
        begin
            XXINC     <= 0;
            CC_XXINC  <= 0;
        end 
        else 
        begin
            XXINC     <= xxinc_pulse;
            CC_XXINC  <= cc_xxinc_pulse;
        end
    end

endmodule