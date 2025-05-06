module h264buffer_inter (
    input logic CLK,
    input logic NEWSLICE,
    input logic NEWLINE,
    input logic VALIDI,
    input logic [11:0] ZIN,

    output logic READYI = 1'b0,
    output logic CCIN = 1'b0,
    output logic DONE = 1'b0,

    output logic [11:0] VOUT = 12'd0,
    output logic VALIDO = 1'b0,

    output logic NLOAD = 1'b0,
    output logic [2:0] NX = 3'b000,
    output logic [2:0] NY = 3'b000,
    output logic [1:0] NV = 2'b00,
    output logic NXINC = 1'b0,

    input logic READYO,
    input logic TREADYO,
    input logic HVALID
);

// Buffer memory
logic [11:0] buff [511:0];

// Input counters and flags
logic [3:0] ix = 4'h0;
logic [3:0] isubmb = 4'h0;        // Luma block index
logic [2:0] ichsubmb = 3'b000;    // Chroma sub-block index
logic ichf = 1'b0;                // Chroma flag
logic ichdc = 1'b0;               // Chroma DC flag
logic [1:0] imb = 2'b00;          // Chroma macroblock selector

// Output counters and flags
logic [3:0] ox = 4'h0;
logic [3:0] osubmb = 4'h0;
logic ochf = 1'b0;
logic ochdc = 1'b0;               // Output chroma DC flag
logic [1:0] omb = 2'b00;

// Flags for NLOAD/NXINC
logic nloadi = 1'b0;
logic nxinci = 1'b0;

// Validity flags
logic nv0 = 1'b0;
logic nv1 = 1'b0;
logic nlvalid = 1'b0;
logic ntvalid = 1'b0;

// Address calculation
logic [8:0] addr;

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

always_ff @(posedge CLK) begin
    if (NEWSLICE) begin
        ix <= 4'h0;
        isubmb <= 4'h0;
        ichsubmb <= 3'b000;
        ichf <= 1'b0;
        ichdc <= 1'b0;
        imb <= 2'b00;
        ox <= 4'h0;
        osubmb <= 4'h0;
        ochf <= 1'b0;
        ochdc <= 1'b0;
        omb <= 2'b00;
        nloadi <= 1'b0;
        nxinci <= 1'b0;
        nlvalid <= 1'b0;
        ntvalid <= 1'b0;
    end else if (NEWLINE) begin
        nlvalid <= 1'b0;
        ntvalid <= 1'b1;
    end

    // Input process
    if (VALIDI && !NEWSLICE) begin
        if (!ichf) begin
            addr = {1'b0, isubmb, ix}; // Luma
        end else if (ichdc) begin
            addr = {1'b1, imb[0], ichsubmb[2], ix[1:0], 4'hf}; // DC chroma
        end else begin
            addr = {1'b1, imb[0], ichsubmb, ix}; // AC chroma
        end

        assert (!$isunknown(ZIN)) else $warning("ZIN has unknown value");

        buff[addr] <= ZIN;

        if (!ichf) begin // Luma
            ix <= ix + 1;
            if (ix == 15) begin
                ix <= 4'h0;
                isubmb <= isubmb + 1;
                if (isubmb == 15) begin
                    ichf <= 1'b1;
                    ichdc <= 1'b1;
                    ichsubmb <= 3'b000;
                    imb <= imb + 1;
                end
            end
        end else if (ichdc) begin // Chroma DC
            ix <= ix + 1;
            if (ix == 3) begin
                ix <= 4'h0;
                ichdc <= 1'b0;
                ichsubmb <= 3'b000;
            end
        end else begin // Chroma AC
            ix <= ix + 1;
            if (ix == 15) begin
                ix <= 4'h0;
                ichsubmb <= ichsubmb + 1;
                if (ichsubmb == 3) begin
                    ichf <= 1'b0;
                    ichsubmb <= 3'b000;
                    imb <= imb + 1;
                end
            end
        end
    end

    // Output process
    if (!NEWSLICE && !HVALID && ((TREADYO && READYO) || ox != 0)) begin
        if (!ochf) begin
            addr = {1'b0, osubmb, ox};
        end else if (ochdc) begin
            addr = {1'b1, omb[0], osubmb[2], ox[1:0], 4'hf}; // DC chroma
        end else begin
            addr = {1'b1, omb[0], osubmb[2:0], ox}; // AC chroma
        end

        VOUT <= buff[addr];
        VALIDO <= 1'b1;

        if (!ochf) begin
            NX <= {1'b0, osubmb[2], osubmb[0]};
            NY <= {1'b0, osubmb[3], osubmb[1]};
        end else begin
            NX <= {1'b1, osubmb[2], osubmb[0]};
            NY <= {1'b1, osubmb[2], osubmb[1]};
        end

        if (!ochf) begin
            ox <= ox + 1;
            if (ox == 15) begin
                ox <= 4'h0;
                osubmb <= osubmb + 1;
                if (osubmb == 15) begin
                    ochf <= 1'b1;
                    ochdc <= 1'b1;
                    omb <= omb + 1;
                    nxinci <= 1'b1;
                end
                nloadi <= 1'b1;
            end
        end else if (ochdc) begin
            if (ox != 3) begin
                ox <= ox + 1;
            end else begin
                ox <= 4'h0;
                ochdc <= 1'b0;
                osubmb[2:0] <= 3'b000;
            end
        end else begin
            ox <= ox + 1;
            if (ox == 15) begin
                ox <= 4'h0;
                osubmb[2:0] <= osubmb[2:0] + 1;
                if (osubmb[2:0] == 3) begin
                    osubmb[2:0] <= 3'b000;
                    omb <= omb + 1;
                    if (omb == 2'b11) begin
                        ochf <= 1'b0;
                    end
                    nxinci <= 1'b1;
                end
                nloadi <= 1'b1;
            end
        end
    end else begin
        VALIDO <= 1'b0;
    end

    // Flag updates
    NLOAD <= nloadi;
    NXINC <= nxinci;
    NV <= {nv1, nv0};

    if (nloadi) nloadi <= 1'b0;
    if (nxinci) nxinci <= 1'b0;

    CCIN <= ichf & VALIDI;
end

endmodule