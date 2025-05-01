module h264recon
(
    input logic CLK2,				// x2 clock
    // interface for inter
    input logic inter_flag_valid,
    input logic inter_flag,
    // in interface:
    input logic NEWSLICE,			// reset
    input logic STROBEI,		    // data here
    input logic [39:0] DATAI,       // 4x10bit
    input logic BSTROBEI,           // base data here
    input logic BCHROMAI,           // set if base is chroma
    input logic [31:0] BASEI,       // 4x8bit
    // out interface:
    output logic STROBEO = 0,	        // data here (luma)
    output logic CSTROBEO = 0,	        // data here (chroma)
    output logic [31:0] DATAO = '0
);

    logic [31:0] basevec [63:0] = '{default: '0};

    logic [63:0] chromaf;
    logic [31:0] basex;
    logic [5:0] basein = '0;
    logic [5:0] baseout = '0;
    logic [9:0] byte0 = '0;
    logic [9:0] byte1 = '0;
    logic [9:0] byte2 = '0;
    logic [9:0] byte3 = '0;
    logic strobex = 0;
    logic chromax = 0;

    logic basein_rst;
    logic baseout_rst;

    assign basein_rst = (basein == 6'b111111);
    assign baseout_rst = (baseout == 6'b111111);

    // assign basex = basevec[baseout[2:0]];
    always_comb 
    begin
        if (inter_flag_valid)
        begin
            if (inter_flag)
                basex = basevec[baseout[5:0]];
            else
                basex = basevec[baseout[2:0]];
        end
    end
    
    always@(posedge CLK2) 
    begin

        if (NEWSLICE || !inter_flag_valid) 
        begin    // reset
			basein <= 6'd0;
			baseout <= 6'd0;
		end

        // -- Counter Reset on Limit --
        if (basein_rst)
        begin
            basein <= 6'd0;
        end

        if (baseout_rst)
        begin
            baseout <= 6'd0;
        end
        // -----------------------------

		// -- Load LUMA/CHROMA BASE (REFERENCE) -- 
		if (BSTROBEI && !NEWSLICE) 
        begin
            if (inter_flag)
            begin
                basevec[basein] <= BASEI;
                chromaf[basein] <= BCHROMAI;
                basein <= basein + 1;
            end
            else
            begin
                basevec[basein[2:0]] <= BASEI;
                chromaf[basein[2]] <= BCHROMAI;
                basein <= basein + 1;
                assert (basein+8 != baseout) else $error("basein wrapped");
            end
        end
		else
			assert (basein[1:0] == '0) else $error("basein not aligned when strobe falls");
        // -----------------------------

        // -- RECONSTRUCT: REFERENCE(BASE) + RESIDUAL(DATA) --
        byte0 <= {2'b00, basex[7:0]} + DATAI[9:0];
		byte1 <= {2'b00, basex[15:8]} + DATAI[19:10];
		byte2 <= {2'b00, basex[23:16]} + DATAI[29:20];
		byte3 <= {2'b00, basex[31:24]} + DATAI[39:30];
        // -----------------------------


        // Select if CHROMA PIXELS
        if (inter_flag)
        begin
            chromax <= chromaf[baseout];
        end
        else
        begin
            chromax <= chromaf[baseout[2]];
        end

        strobex <= STROBEI;

        if (STROBEI && !NEWSLICE) 
        begin
            baseout <= baseout + 1;
            assert (baseout != basein) else $error("baseout wrapped");
        end
        else 
        begin
            assert (baseout[1:0] == 2'b00) else $error("baseout not aligned when strobe falls");
        end

        // reconstruct +1: clip to [0,255]
        if (byte0[9:8] == 2'b01 || byte0[9:7] == 3'b100)
        begin
            DATAO[7:0] <= 8'hFF;
        end
        else if (byte0[9] && byte0[9:7] != 3'b100)
        begin
            DATAO[7:0] <= 8'h00;
        end
        else
        begin
            DATAO[7:0] <= byte0[7:0];
        end


        if (byte1[9:8] == 2'b01 || byte1[9:7] == 3'b100)
        begin
            DATAO[15:8] <= 8'hFF;
        end
        else if (byte1[9] && byte1[9:7] != 3'b100)
        begin
            DATAO[15:8] <= 8'h00;
        end
        else
        begin
            DATAO[15:8] <= byte1[7:0];
        end


        if (byte2[9:8] == 2'b01 || byte2[9:7] == 3'b100)
        begin
            DATAO[23:16] <= 8'hFF;
        end
        else if (byte2[9] && byte2[9:7] != 3'b100)
        begin
            DATAO[23:16] <= 8'h00;
        end
        else
        begin
            DATAO[23:16] <= byte2[7:0];
        end

        if (byte3[9:8] == 2'b01 || byte3[9:7] == 3'b100)
        begin
            DATAO[31:24] <= 8'hFF;
        end
        else if (byte3[9] && byte3[9:7] != 3'b100)
        begin
            DATAO[31:24] <= 8'h00;
        end
        else
        begin
            DATAO[31:24] <= byte3[7:0];
        end

        STROBEO <= strobex & (~chromax);
        CSTROBEO <= strobex & chromax;
    end

endmodule