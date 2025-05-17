`timescale 1ns/1ps

module tb_mc;

    //-------------------------------------
    // Parameters
    //-------------------------------------

    parameter MB_SIZE     = 4;
    parameter N_DC        = 4;
    parameter PIXEL_WIDTH = 8;

    //-------------------------------------
    // Signals
    //-------------------------------------

    logic clk;
    logic reset;

    logic ccin;

    logic [(PIXEL_WIDTH*MB_SIZE)-1:0] ref_frame; // Reference frame
    logic [(PIXEL_WIDTH*MB_SIZE)-1:0] curr_mb;   // Current macroblock

    logic src_valid;
    logic src_ready;
    logic dst_ready;
    logic dst_valid;

    logic [(PIXEL_WIDTH*MB_SIZE)-1:0] residual;

    logic [15:0] dcco;
    logic dcco_valid;

    logic XXINC;
    logic CC_XXINC;

    //-------------------------------------
    // Clock generation
    //-------------------------------------

    always #5 clk = ~clk;

    //-------------------------------------
    // DUT Instantiation
    //-------------------------------------

    mc #(
        .MB_SIZE(MB_SIZE),
        .N_DC(N_DC),
        .PIXEL_WIDTH(PIXEL_WIDTH)
    ) uut (
        .clk(clk),
        .reset(reset),

        .ccin(ccin),

        .ref_frame(ref_frame),
        .curr_mb(curr_mb),

        .src_valid(src_valid),
        .src_ready(src_ready),
        .dst_ready(dst_ready),
        .dst_valid(dst_valid),

        .residual(residual),

        .dcco(dcco),
        .dcco_valid(dcco_valid),

        .XXINC(XXINC),
        .CC_XXINC(CC_XXINC)
    );

    //-------------------------------------
    // Test Sequence
    //-------------------------------------

    initial begin
        // Initialize signals
        clk       = 0;
        reset     = 1;
        src_valid = 0;
        curr_mb   = 0;
        ccin      = 0;
        dst_ready = 0;

        #20 reset = 0;

        dst_ready = 1;

        // Send 16 luma blocks (each 4x4) → one 16x16 block
        send_block(4, 1'b0);
        send_block(4, 1'b0);
        send_block(4, 1'b0);
        send_block(4, 1'b0);
        send_block(4, 1'b0);
        send_block(4, 1'b0);
        send_block(4, 1'b0);
        send_block(4, 1'b0);
        send_block(4, 1'b0);
        send_block(4, 1'b0);
        send_block(4, 1'b0);
        send_block(4, 1'b0);
        send_block(4, 1'b0);
        send_block(4, 1'b0);
        send_block(4, 1'b0);
        send_block(4, 1'b0);

        // Send 16 chroma blocks (each 4x4) → two 8x8 blocks
        send_block(4, 1'b1);
        send_block(4, 1'b1);
        send_block(4, 1'b1);
        send_block(4, 1'b1);
        send_block(4, 1'b1);
        send_block(4, 1'b1);
        send_block(4, 1'b1);
        send_block(4, 1'b1);


        repeat (10) @(posedge clk);
        dst_ready = 0;

        // Finish simulation
        #100 $finish;
    end

    //-------------------------------------
    // Task: send_block
    //-------------------------------------
    // Sends 'count' number of 4x4 blocks, each with 'cc' type (luma=0, chroma=1)
    task send_block(input int count, input logic cc);
        automatic int blk = 0;
        automatic int pix = 0;

        while (!src_ready)
            @(posedge clk);

        for (blk = 0; blk < count; blk++) begin
            ccin = cc;

            // Prepare current macroblock data
            for (pix = 0; pix < MB_SIZE; pix++) begin
                curr_mb[pix * PIXEL_WIDTH +: PIXEL_WIDTH] = blk * 16 + pix;
            end
            ref_frame = '0;

            // Assert valid
            src_valid = 1;

            @(posedge clk);
        end
        src_valid = 0;
        @(posedge clk);
    endtask

endmodule