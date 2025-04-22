module h264buffer_inter
(
    input logic CLK,                    // Clock
    input logic NEWSLICE,               // Reset: This is the first in a slice
    input logic NEWLINE,                // This is the first in a line

    input logic VALIDI,                 // Luma/chroma data here (16/15 of these)
    input logic [11:0] ZIN,             // Luma/chroma data
    output logic READYI = 1'b0,         // Set when ready for next luma/chroma
    output logic CCIN = 1'b0,           // Set when inputting chroma
    output logic DONE = 1'b0,           // Set when all done and quiescent

    output logic [11:0] VOUT = 12'd0,   // Luma/chroma data
    output logic VALIDO = 1'b0,         // Strobe for data out

    output logic NLOAD = 1'b0,          // Load for CAVLC NOUT
    output logic [2:0] NX = 3'b000,     // X value for NIN/NOUT
    output logic [2:0] NY = 3'b000,     // Y value for NIN/NOUT
    output logic [1:0] NV = 2'b00,      // Valid flags for NIN/NOUT (1=left, 2=top, 3=avg)
    output logic NXINC = 1'b0,          // Increment for X macroblock counter

    input logic READYO,                 // From CAVLC module (goes inactive after block starts)
    input logic TREADYO,                // From tobytes module: Tells it to freeze
    input logic HVALID                  // When header module outputting
);

    // Buffer memory
    logic [11:0] buff [511:0];

    // Input counters and flags
    logic [3:0] ix = 4'h0;              // Index inside block
    logic [3:0] isubmb = 4'h0;          // Index to blocks of luma
    logic [2:0] ichsubmb = 3'b000;      // Index to blocks of chroma
    logic ichf = 1'b0;                  // Chroma flag
    logic [1:0] imb = 2'b00;            // Odd/even MB for chroma

    // Output counters and flags
    logic [3:0] ox = 4'h0;              // Index inside block
    logic [3:0] osubmb = 4'h0;          // Index to blocks of luma
    logic ochf = 1'b0;                  // Chroma flag
    logic [1:0] omb = 2'b00;            // Odd/even MB for chroma

    // Flags for NLOAD and NXINC
    logic nloadi = 1'b0;
    logic nxinci = 1'b0;

    // Validity flags for neighboring blocks
    logic nv0 = 1'b0;
    logic nv1 = 1'b0;
    logic nlvalid = 1'b0;
    logic ntvalid = 1'b0;

    // Address calculation
    logic [8:0] addr;

    // Combinational logic
    always_comb begin
        if (omb == imb || (ochf && isubmb < 12) || (isubmb + 1 < osubmb && isubmb < 12)) begin
            READYI = 1'b1;
        end else begin
            READYI = 1'b0;
        end

        if (omb == imb && isubmb == 0 && osubmb == 0 && READYO) begin
            DONE = 1'b1;
        end else begin
            DONE = 1'b0;
        end

        if (nlvalid || (osubmb[2] && !ochf) || osubmb[0]) begin
            nv0 = 1'b1;
        end else begin
            nv0 = 1'b0;
        end

        if (ntvalid || (osubmb[3] && !ochf) || osubmb[1]) begin
            nv1 = 1'b1;
        end else begin
            nv1 = 1'b0;
        end
    end

    // Sequential logic
    always_ff @(posedge CLK) begin
        if (NEWSLICE) begin
            // Reset all counters and flags
            ix <= 4'h0;
            isubmb <= 4'h0;
            ichsubmb <= 3'b000;
            ichf <= 1'b0;
            imb <= 2'b00;
            ox <= 4'h0;
            osubmb <= 4'h0;
            ochf <= 1'b0;
            omb <= 2'b00;
            nloadi <= 1'b0;
            nlvalid <= 1'b0;
            ntvalid <= 1'b0;
        end else if (NEWLINE) begin
            nlvalid <= 1'b0;
            ntvalid <= 1'b1;
        end

        // Input process
        if (VALIDI && !NEWSLICE) begin
            if (!ichf) begin
                addr = {1'b0, isubmb, ix}; // Luma address
            end else begin
                // Skip the DC coefficient (ix == 0)
                if (ix != 0) begin
                    addr = {1'b1, imb[0], ichsubmb, ix - 1}; // Adjust index for AC coefficients
                end
            end

            assert (!$isunknown(ZIN)) else $warning("Problems with ZIN severity WARNING");

            if (!ichf || (ichf && ix != 0)) begin
                buff[addr] <= ZIN;
            end

            if (!ichf) begin // Luma
                ix <= ix + 1;
                if (ix == 15) begin
                    isubmb <= isubmb + 1;
                    if (isubmb == 15) begin
                        ichf <= 1'b1; // Switch to chroma after all luma blocks
                        ichsubmb <= 3'b000;
                        imb <= imb + 1;
                    end
                end
            end else begin // Chroma
                ix <= ix + 1;
                if (ix == 15) begin // Processed all 16 coefficients (skipping DC)
                    ichsubmb <= ichsubmb + 1;
                    ix <= 4'h0;
                    if (ichsubmb == 7) begin
                        ichf <= 1'b0; // Switch back to luma after all chroma blocks
                    end
                end
            end
        end

        // Output process
        if (!NEWSLICE && !HVALID && imb != omb && ((TREADYO && READYO) || ox != 0)) begin
            if (!ochf) begin
                addr = {1'b0, osubmb, ox}; // Luma address
            end else begin
                // Skip the DC coefficient (ox == 0)
                if (ox != 0) begin
                    addr = {1'b1, omb[0], osubmb[2:0], ox - 1}; // Adjust index for AC coefficients
                end
            end

            VOUT <= buff[addr];
            assert (!$isunknown(buff[addr])) else $warning("Problems with VOUT severity WARNING");

            VALIDO <= 1'b1;

            if (!ochf) begin
                NX <= {1'b0, osubmb[2], osubmb[0]};
                NY <= {1'b0, osubmb[3], osubmb[1]};
            end else begin
                NX <= {1'b1, osubmb[2], osubmb[0]}; // osubmb[2] is Cr/Cb flag
                NY <= {1'b1, osubmb[2], osubmb[1]};
            end

            if (!ochf) begin
                ox <= ox + 1;
                if (ox == 15) begin
                    osubmb <= osubmb + 1;
                    if (osubmb == 15) begin
                        ochf <= 1'b1; // Switch to chroma after all luma blocks
                        omb <= omb + 1;
                        nxinci <= 1'b1;
                    end
                    nloadi <= 1'b1;
                end
            end else begin
                ox <= ox + 1;
                if (ox == 15) begin
                    osubmb[2:0] <= osubmb[2:0] + 1;
                    ox <= 4'h0;
                    if (osubmb[2:0] == 7) begin
                        ochf <= 1'b0; // Switch back to luma after all chroma blocks
                    end
                    nloadi <= 1'b1;
                end
            end
        end else begin
            VALIDO <= 1'b0;
        end

        // Update flags
        NLOAD <= nloadi;
        NXINC <= nxinci;
        NV <= {nv1, nv0};

        if (nloadi) begin
            nloadi <= 1'b0;
        end

        if (nxinci) begin
            nxinci <= 1'b0;
            nlvalid <= 1'b1;
        end

        CCIN <= ichf & VALIDI;
    end
endmodule