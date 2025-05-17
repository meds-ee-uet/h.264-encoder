module mc #(
    parameter MB_SIZE     = 4,
    parameter N_DC        = 4,
    parameter PIXEL_WIDTH = 8
)(
    input  logic clk,
    input  logic reset,

    input  logic ccin,

    // Inputs
    input  var logic [(PIXEL_WIDTH*MB_SIZE)-1:0] ref_frame,
    input  var logic [(PIXEL_WIDTH*MB_SIZE)-1:0] curr_mb,

    input  logic src_valid,
    output logic src_ready,
    input  logic dst_ready,
    output logic dst_valid,

    // Outputs
    output logic [(PIXEL_WIDTH*MB_SIZE)-1:0] residual,

    output logic [15:0] dcco,
    output logic        dcco_valid,
    output logic        XXINC,
    output logic        CC_XXINC
);

    //-------------------------------------
    // Internal Control Signals
    //-------------------------------------

    logic load_curr;
    logic load_ref;
    logic output_residual_row;
    logic start_dc_calc;
    logic output_dcco;

    logic [3:0] row_count;
    logic [3:0] dc_count;
    logic [3:0] dcco_count;

    logic ccin_reg;

    //-------------------------------------
    // Instantiate Controller
    //-------------------------------------

    mc_controller #(
        .MB_SIZE(MB_SIZE),
        .N_DC(N_DC)
    ) controller_inst (
        .clk              (clk),
        .reset            (reset),
        .src_valid        (src_valid),
        .dst_ready        (dst_ready),
        .row_count        (row_count),
        .dc_count         (dc_count),
        .dcco_count       (dcco_count),

        .src_ready        (src_ready),
        .dst_valid        (dst_valid),
        .load_curr        (load_curr),
        .load_ref         (load_ref),
        .output_residual_row(output_residual_row),
        .start_dc_calc    (start_dc_calc),
        .output_dcco      (output_dcco),

        .XXINC            (XXINC),
        .CC_XXINC         (CC_XXINC),
        .ccin_reg         (ccin_reg)
    );

    //-------------------------------------
    // Instantiate Datapath
    //-------------------------------------

    mc_datapath #(
        .MB_SIZE(MB_SIZE),
        .N_DC(N_DC),
        .PIXEL_WIDTH(PIXEL_WIDTH)
    ) datapath_inst (
        .clk              (clk),
        .reset            (reset),

        .load_curr        (load_curr),
        .load_ref         (load_ref),
        .output_residual_row(output_residual_row),
        .start_dc_calc    (start_dc_calc),
        .output_dcco      (output_dcco),

        .ccin_reg         (ccin_reg),
        .ccin             (ccin),

        .ref_frame        (ref_frame),
        .curr_mb          (curr_mb),
        .row_count        (row_count),

        .residual         (residual),
        .dcco             (dcco),
        .dcco_valid       (dcco_valid),
        .dc_count         (dc_count),
        .dcco_count       (dcco_count)
    );

endmodule