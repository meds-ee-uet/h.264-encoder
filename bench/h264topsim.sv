module h264topsim(input bit clk2);

    localparam IMGWIDTH     = 352;
    localparam IMGHEIGHT    = 288;
    localparam MAXFRAMES    = 300;
    localparam MAXQP        = 28;
    localparam IWBITS       = 9;
    localparam IMGBITS      = 8;
    localparam INITQP       = 28;

    import "DPI-C" context task dpi_open_file(input string filename);
    import "DPI-C" context task dpi_write_byte(input byte c);
    import "DPI-C" context task dpi_close_file();

	// Verbose Switches

	bit computesnr = 1;
	bit dumprecon  = 1;
    
    int count_fram = 0;
    int random_range;
	// File Handles
    
	integer inb, outb, recb;
	
	// Variables

    integer framenum = 0;
    integer x, y, cx, cy, cuv, i, j, w, count;
    // Variables to track macroblock and search block positions
    integer mb_x, mb_y; // Current macroblock position (top-left corner)
    integer search_block_addr; // Absolute address of the search block in the buffer
    reg [IMGBITS-1:0] c;

    integer y_processed = 0;
	
	// Signals

    logic clk = 0;//clk2;

    logic [5:0] qp = INITQP;

    logic [IMGBITS-1:0] yvideo [0:IMGWIDTH-1][0:IMGHEIGHT-1];
    logic [IMGBITS-1:0] uvideo [0:IMGWIDTH/2-1][0:IMGHEIGHT/2-1];
    logic [IMGBITS-1:0] vvideo [0:IMGWIDTH/2-1][0:IMGHEIGHT/2-1];

    logic [IMGBITS-1:0] yrvideo_curr [0:IMGWIDTH-1  ][0:IMGHEIGHT-1  ];
    logic [IMGBITS-1:0] urvideo_curr [0:IMGWIDTH/2-1][0:IMGHEIGHT/2-1];
    logic [IMGBITS-1:0] vrvideo_curr [0:IMGWIDTH/2-1][0:IMGHEIGHT/2-1];

    logic [IMGBITS-1:0] yrvideo_ref [0:IMGWIDTH-1  ][0:IMGHEIGHT-1  ];
    logic [IMGBITS-1:0] urvideo_ref [0:IMGWIDTH/2-1][0:IMGHEIGHT/2-1];
    logic [IMGBITS-1:0] vrvideo_ref [0:IMGWIDTH/2-1][0:IMGHEIGHT/2-1];

    // Intra4x4 Wires
    logic top_NEWSLICE = 1'b1;			      
	logic top_NEWLINE = 1'b0;			        
	logic intra4x4_READYI;				
	logic intra4x4_STROBEI = 1'b0;				
	logic [31:0] intra4x4_DATAI;
	logic [31:0] intra4x4_TOPI;
	logic [3:0] intra4x4_TOPMI;
	logic intra4x4_STROBEO;			 
	logic intra4x4_READYO;				
	logic [35:0] intra4x4_DATAO;
	logic [31:0] intra4x4_BASEO;
	logic intra4x4_MSTROBEO;		       	
	logic [3:0] intra4x4_MODEO;	       
	logic intra4x4_PMODEO;              
	logic [2:0] intra4x4_RMODEO;	      
	logic [1:0] intra4x4_XXO;
	logic intra4x4_XXINC;
	logic intra4x4_CHREADY;

    //Intra8x8cc Wires
    logic intra8x8cc_READYI;
	logic intra8x8cc_STROBEI;				
	logic [31:0] intra8x8cc_DATAI;
	logic [31:0] intra8x8cc_TOPI;
	logic intra8x8cc_STROBEO;
	logic intra8x8cc_READYO = 1'b0;
	logic [35:0] intra8x8cc_DATAO;
	logic [31:0] intra8x8cc_BASEO;
	logic intra8x8cc_DCSTROBEO;			
	logic [15:0] intra8x8cc_DCDATAO;
	logic [1:0] intra8x8cc_CMODEO;
	logic [1:0] intra8x8cc_XXO;
	logic intra8x8cc_XXC;
	logic intra8x8cc_XXINC;

    logic [1:0] header_CMODE = 2'b00;
    logic [19:0] header_VE;
    logic [4:0] header_VL;
    logic header_VALID;

    logic coretransform_READY;
    logic coretransform_ENABLE;
    logic [35:0] coretransform_XXIN;
    logic coretransform_VALID;
    logic [13:0] coretransform_YNOUT;

    logic dctransform_VALID;
    logic [15:0] dctransform_YYOUT;
    logic dctransform_READYO;

    logic quantise_ENABLE;
    logic [15:0] quantise_YNIN;
    logic quantise_VALID;
    logic [11:0] quantise_ZOUT;
    logic quantise_DCCO;

    logic dequantise_ENABLE;
    logic [15:0] dequantise_ZIN;
    logic dequantise_LAST;
    logic dequantise_VALID;
    logic dequantise_DCCO = 1'b0;
    logic [15:0] dequantise_WOUT;

    logic invdctransform_ENABLE;
	logic [15:0] invdctransform_ZIN;
	logic invdctransform_VALID;
	logic [15:0] invdctransform_YYOUT;
	logic invdctransform_READY;

    logic invtransform_VALID;
    logic [39:0] invtransform_XOUT;

    logic recon_BSTROBEI;
    logic [31:0] recon_BASEI;
    logic recon_FBSTROBE;
    logic recon_FBCSTROBE;
    logic [31:0] recon_FEEDB;

    logic xbuffer_NLOAD_intra;
	logic [2:0] xbuffer_NX_intra;
	logic [2:0] xbuffer_NY_intra;	
	logic [1:0] xbuffer_NV_intra;
	logic xbuffer_NXINC_intra;		
	logic xbuffer_READYI_intra;
	logic xbuffer_CCIN_intra;
	logic xbuffer_DONE_intra;
    logic xbuffer_VOUT_intra;
    logic xbuffer_VALIDO_intra;

    logic xbuffer_NLOAD_inter;
	logic [2:0] xbuffer_NX_inter;
	logic [2:0] xbuffer_NY_inter;	
	logic [1:0] xbuffer_NV_inter;
	logic xbuffer_NXINC_inter;		
	logic xbuffer_READYI_inter;
	logic xbuffer_CCIN_inter;
	logic xbuffer_DONE_inter;
    logic xbuffer_VOUT_inter;
    logic xbuffer_VALIDO_inter;

    logic xbuffer_NLOAD;
	logic [2:0] xbuffer_NX;
	logic [2:0] xbuffer_NY;	
	logic [1:0] xbuffer_NV;
	logic xbuffer_NXINC;		
	logic xbuffer_READYI;
	logic xbuffer_CCIN;
	logic xbuffer_DONE;
    logic [11:0] xbuffer_VOUT;
    logic xbuffer_VALIDO;

    logic cavlc_ENABLE;
	logic cavlc_READY;
	logic [11:0] cavlc_VIN;
	logic [4:0] cavlc_NIN;
	logic [24:0] cavlc_VE;
	logic [4:0] cavlc_VL;
	logic cavlc_VALID;
	logic [2:0] cavlc_XSTATE;
	logic [4:0] cavlc_NOUT;

    logic tobytes_READY;		
	logic [24:0] tobytes_VE;
	logic [4:0] tobytes_VL;
	logic tobytes_VALID;
	logic [7:0] tobytes_BYTE;
	logic tobytes_STROBE;
	logic tobytes_DONE;

    logic align_VALID = 1'b0;
    logic [5:0] QP = INITQP;

    logic [7:0] ninx = 8'h00;
    logic [4:0] ninl = 5'b00000;
    logic [4:0] nint = 5'b00000;
    logic [5:0] ninsum;

    logic [4:0] ninleft [7:0] = '{default: '0};
    logic [4:0] nintop [2047:0] = '{default: '0};

    logic [31:0] toppix [0:IMGWIDTH-1] = '{default: '0};
    logic [31:0] toppixcc [0:IMGWIDTH-1] = '{default: '0};

    logic [3:0] topmode [0:IMGWIDTH-1] = '{default: '0};

    logic [IWBITS-1:0] mbx = '0;
    logic [IWBITS-1:0] mbxcc = '0;

    logic nop1; //No operation
    logic nop2; //No operation
    logic nop3; //No operation
    logic nop4; //No operation

    /////////////////////////////////////
    // Dump VCD
    /////////////////////////////////////
    `ifdef vcd
        initial
        begin    
            $display("VCD logging started");
            $dumpfile("dump.vcd");
            $dumpvars(0, tb);
        end
    `endif

    // Mode Decision
    integer frame_distance = 3;
    logic pred_type; // 0->I, 1->P
    assign pred_type = ((framenum % (frame_distance + 1)) == 0) ? 0 : 1;

    h264intra4x4 intra4x4
    (
        .CLK                ( clk2                  ), 
        .NEWSLICE           ( top_NEWSLICE          ), 
        .NEWLINE            ( top_NEWLINE           ),
        .STROBEI            ( intra4x4_STROBEI      ),
        .DATAI              ( intra4x4_DATAI        ), 
        .READYI             ( intra4x4_READYI       ),
        .TOPI               ( intra4x4_TOPI         ), 
        .TOPMI              ( intra4x4_TOPMI        ), 
        .XXO                ( intra4x4_XXO          ),
        .XXINC              ( intra4x4_XXINC        ), 
        .FEEDBI             ( recon_FEEDB[31:24]    ), 
        .FBSTROBE           ( recon_FBSTROBE        ),
        .STROBEO            ( intra4x4_STROBEO      ), 
        .DATAO              ( intra4x4_DATAO        ), 
        .BASEO              ( intra4x4_BASEO        ),
        .READYO             ( intra4x4_READYO       ),
        .MSTROBEO           ( intra4x4_MSTROBEO     ),
        .MODEO              ( intra4x4_MODEO        ), 
        .PMODEO             ( intra4x4_PMODEO       ),
        .RMODEO             ( intra4x4_RMODEO       ), 
        .CHREADY            ( intra4x4_CHREADY      )
    );

    assign intra4x4_READYO = inter_flag_valid ? coretransform_READY && xbuffer_READYI && !inter_flag : 1'b0;
    assign intra4x4_TOPI   = toppix[{mbx, intra4x4_XXO}];
    assign intra4x4_TOPMI  = topmode[{mbx, intra4x4_XXO}];

    h264intra8x8cc intra8x8cc
    (
        .CLK2               ( clk2                  ),
        .NEWSLICE           ( top_NEWSLICE          ), 
        .NEWLINE            ( top_NEWLINE           ), 
        .STROBEI            ( intra8x8cc_STROBEI    ), 
        .DATAI              ( intra8x8cc_DATAI      ), 
        .READYI             ( intra8x8cc_READYI     ),
        .TOPI               ( intra8x8cc_TOPI       ), 
        .XXO                ( intra8x8cc_XXO        ), 
        .XXC                ( intra8x8cc_XXC        ),
        .XXINC              ( intra8x8cc_XXINC      ), 
        .FEEDBI             ( recon_FEEDB[31:24]    ), 
        .FBSTROBE           ( recon_FBCSTROBE       ),
        .STROBEO            ( intra8x8cc_STROBEO    ), 
        .DATAO              ( intra8x8cc_DATAO      ), 
        .BASEO              ( intra8x8cc_BASEO      ),
        .READYO             ( intra4x4_CHREADY      ), 
        .DCSTROBEO          ( intra8x8cc_DCSTROBEO  ), 
        .DCDATAO            ( intra8x8cc_DCDATAO    ), 
        .CMODEO             ( intra8x8cc_CMODEO     )
    );

    assign intra8x8cc_TOPI = toppixcc[{mbxcc, intra8x8cc_XXO}];


    // Inter-Prediction
    localparam MACRO_DIM  = 16;
    localparam SEARCH_DIM = 18;
    localparam PORT_WIDTH = MACRO_DIM + 1;

    logic        rst_n;
    //logic        clk;
    logic        start;
    logic        en_ram;
    logic        done;
    logic [5:0]  addr;
    logic [5:0]  amt;
    logic [5:0]  mv_y;
    logic [5:0]  mv_x;
    logic [7:0]  pixel_spr_in [0:MACRO_DIM];
    logic [7:0]  pixel_cpr_in [0:MACRO_DIM-1];
    logic [15:0] min_sad;

    logic [15:0] trans_addr [MACRO_DIM:0];

    me # 
    (
        .MACRO_DIM  ( MACRO_DIM  ),
        .SEARCH_DIM ( SEARCH_DIM )
    )
    ins_me
    (
        .rst_n              ( rst_n              ),
        .clk                ( clk2               ),
        .start              ( start              ),
        .pixel_spr_in       ( pixel_spr_in       ),
        .pixel_cpr_in       ( pixel_cpr_in       ),
        .ready              ( ready              ),
        .valid              ( valid              ),
        .en_ram             ( en_ram             ),
        .done               ( done               ),
        .addr               ( addr               ),
        .amt                ( amt                ),
        .mv_x               ( mv_x               ),
        .mv_y               ( mv_y               ),
        .min_sad            ( min_sad            )
    );

    logic [31:0] inter_mc_REF;
    logic [31:0] inter_mc_CURR;
    logic [31:0] inter_mc_residual;

    logic inter_mc_READYI;
    logic inter_mc_VALIDI;
    logic inter_mc_READYO;
    logic inter_mc_VALIDO;

    assign inter_mc_READYO = inter_flag_valid ? coretransform_READY && xbuffer_READYI && inter_flag : 1'b0;

    mc #
    (
        .MB_SIZE            (4),
        .PIXEL_WIDTH        (IMGBITS)
    )
    ins_mc
    (
        .ref_frame          ( inter_mc_REF      ),
        .curr_mb            ( inter_mc_CURR     ),
        .src_ready          ( inter_mc_READYI   ),
        .src_valid          ( inter_mc_VALIDI   ),
        .dst_ready          ( inter_mc_READYO   ),
        .dst_valid          ( inter_mc_VALIDO   ),
        .residual           ( inter_mc_residual )
    );

    // --- ADD LOGIC FOR MINTRA SINTRA AND IF NOT, THEN PMODE IS THE FINAL ONE

    logic inter_flag_valid;
    // logic inter_flag_reset;
    logic inter_flag;
    logic [11:0] inter_mvx;
    logic [11:0] inter_mvy;

    logic header_LSTROBE;
    logic header_CSTROBE;
    logic header_SINTRA;
    logic header_MINTRA;
    logic [11:0] header_MVDX;
    logic [11:0] header_MVDY;

    // input to MC module is through these registers
    logic [7:0] search_block_reg_y[0:SEARCH_DIM-1][0:SEARCH_DIM-1];
    logic [7:0] search_block_reg_u[0:SEARCH_DIM/2-1][0:SEARCH_DIM/2-1];
    logic [7:0] search_block_reg_v[0:SEARCH_DIM/2-1][0:SEARCH_DIM/2-1];

    always_ff @(posedge clk)
        begin
            if (valid)
                begin
                    inter_flag_valid <= 1;
                    inter_flag <= (min_sad <= 1000);
                    inter_mvx  <= mv_x;
                    inter_mvy  <= mv_y;
                end
        end

    assign header_LSTROBE = (inter_flag_valid) ? (intra4x4_STROBEO && intra4x4_READYO) || (inter_mc_VALIDO && inter_mc_READYO) : 1'b0;
    // cstrobe only required in intra mb
    assign header_CSTROBE = (inter_flag_valid) ? (intra4x4_STROBEO && intra4x4_READYO) : 1'b0;
    // SINTRA >> SLICE INTRA >> Only first frame will be IDR, rest are non-IDR
    assign header_SINTRA  = (framenum == 1);
    // MINTRA >> MACROBLOCK INTRA >> can be inter mode or intra mode
    assign header_MINTRA  = (inter_flag_valid) ? inter_flag : 1'b0;
    assign header_MVDX = MACRO_DIM - inter_mvx;
    assign header_MVDY = MACRO_DIM - inter_mvy;

    h264header header
    (
		.CLK                ( clk                   ),
		.NEWSLICE           ( top_NEWSLICE          ),
        .LASTSLICE          ( 1'b0                  ), //Not Used
		.SINTRA             ( header_SINTRA         ),	
		.MINTRA             ( header_MINTRA         ),
		.LSTROBE            ( header_LSTROBE        ), // Was intra4x4_STROBEO
		.CSTROBE            ( header_CSTROBE        ), // Was intra4x4_STROBEO
		.QP                 ( qp                    ),
		.PMODE              ( intra4x4_PMODEO       ),
		.RMODE              ( intra4x4_RMODEO       ),
		.CMODE              ( header_CMODE          ),
		.PTYPE              ( 2'b00                 ), // P_16x16 = 0
		.PSUBTYPE           ( 2'b00                 ),   // Not required for P_16x16
		.MVDX               ( header_MVDX           ),
		.MVDY               ( header_MVDY           ),
		.VE                 ( header_VE             ),
		.VL                 ( header_VL             ),
		.VALID              ( header_VALID          )
	);

    h264coretransform coretransform
    (
        .CLK                ( clk2                  ), 
        .RESET              ( top_NEWSLICE          ),
        .READY              ( coretransform_READY   ), 
        .ENABLE             ( coretransform_ENABLE  ),
        .XXIN               ( coretransform_XXIN    ), 
        .VALID              ( coretransform_VALID   ), 
        .YNOUT              ( coretransform_YNOUT   )
    );

    assign coretransform_ENABLE = intra4x4_STROBEO || intra8x8cc_STROBEO || inter_mc_VAL;
	// assign coretransform_XXIN = intra4x4_STROBEO ? intra4x4_DATAO : intra8x8cc_DATAO;
	assign recon_BSTROBEI = intra4x4_STROBEO | intra8x8cc_STROBEO;
	assign recon_BASEI = intra4x4_STROBEO ? intra4x4_BASEO : intra8x8cc_BASEO;

    always_comb 
        begin
            if (inter_flag_valid)
                begin
                    if (inter_flag)
                        begin
                            coretransform_XXIN = inter_mc_residual;
                        end
                    else
                        begin
                            coretransform_XXIN = intra4x4_STROBEO ? intra4x4_DATAO : intra8x8cc_DATAO;
                        end
                end
        end

    h264dctransform #
    (
        .TOGETHER(1)
    )
    dctransform
    (
        .CLK                ( clk2                      ), 
        .RESET              ( ~top_NEWSLICE             ),
        .READYI             ( nop3                      ),
        .ENABLE             ( intra8x8cc_DCSTROBEO      ),
        .XXIN               ( intra8x8cc_DCDATAO        ), 
        .VALID              ( dctransform_VALID         ), 
        .YYOUT              ( dctransform_YYOUT         ),
        .READYO             ( dctransform_READYO        )
    );

    assign dctransform_READYO = (inter_flag_valid) ? (intra4x4_CHREADY && ~coretransform_VALID) && (!inter_flag) : 1'b0;

    h264quantise quantise
    (
		.CLK                ( clk2                      ),
		.ENABLE             ( quantise_ENABLE           ), 
		.QP                 ( qp                        ),
		.DCCI               ( dctransform_VALID         ),
		.YNIN               ( quantise_YNIN             ),
		.ZOUT               ( quantise_ZOUT             ),
		.DCCO               ( quantise_DCCO             ),
		.VALID              ( quantise_VALID            )
	);

	assign quantise_YNIN = coretransform_VALID ? $signed(coretransform_YNOUT) : $signed(dctransform_YYOUT);
	assign quantise_ENABLE = coretransform_VALID | dctransform_VALID;

    h264dctransform invdctransform
    (
        .CLK                ( clk2                      ), 
        .RESET              ( ~top_NEWSLICE             ), 
        .READYI             ( nop4                      ),
        .ENABLE             ( invdctransform_ENABLE     ),
        .XXIN               ( invdctransform_ZIN        ), 
        .VALID              ( invdctransform_VALID      ), 
        .YYOUT              ( invdctransform_YYOUT      ),
        .READYO             ( invdctransform_READY      )
    );

    assign invdctransform_ENABLE = quantise_VALID & quantise_DCCO;
	assign invdctransform_READY = dequantise_LAST & xbuffer_CCIN;
	assign invdctransform_ZIN = $signed(quantise_ZOUT);

    h264dequantise #
    (
        .LASTADVANCE(2)
    )
    h264dequantise
	(
		.CLK                ( clk2                      ),
		.ENABLE             ( dequantise_ENABLE         ),
		.QP                 ( qp                        ),
		.ZIN                ( dequantise_ZIN            ),
		.DCCI               ( invdctransform_VALID      ),
        .DCCO               ( nop1                      ),
		.LAST               ( dequantise_LAST           ),
		.WOUT               ( dequantise_WOUT           ),
		.VALID              ( dequantise_VALID          )
	);

	assign dequantise_ENABLE = quantise_VALID & ~quantise_DCCO;
	assign dequantise_ZIN = !invdctransform_VALID ? $signed(quantise_ZOUT) : $signed(invdctransform_YYOUT);

    h264invtransform invtransform
	(
		.CLK                ( clk2                      ),
		.ENABLE             ( dequantise_VALID          ),
		.WIN                ( dequantise_WOUT           ),
		.VALID              ( invtransform_VALID        ),
		.XOUT               ( invtransform_XOU          )
	);

    h264recon recon
    (
        .CLK2               ( clk2                      ), 
        .NEWSLICE           ( top_NEWSLICE              ), 
        .STROBEI            ( invtransform_VALID        ), 
        .DATAI              ( invtransform_XOUT         ),
        .BSTROBEI           ( recon_BSTROBEI            ),
        .BCHROMAI           ( intra8x8cc_STROBEO        ), 
        .BASEI              ( recon_BASEI               ),
        .STROBEO            ( recon_FBSTROBE            ), 
        .CSTROBEO           ( recon_FBCSTROBE           ), 
        .DATAO              ( recon_FEEDB               )
    );

    assign xbuffer_NLOAD  = inter_flag ? xbuffer_NLOAD_inter  : xbuffer_NLOAD_intra;
    assign xbuffer_NX     = inter_flag ? xbuffer_NX_inter     : xbuffer_NX_intra;
    assign xbuffer_NY     = inter_flag ? xbuffer_NY_inter     : xbuffer_NY_intra;
    assign xbuffer_NV     = inter_flag ? xbuffer_NV_inter     : xbuffer_NV_intra;
    assign xbuffer_NXINC  = inter_flag ? xbuffer_NXINC_inter  : xbuffer_NXINC_intra;
    assign xbuffer_READYI = inter_flag ? xbuffer_READYI_inter : xbuffer_READYI_intra;
    assign xbuffer_CCIN   = inter_flag ? xbuffer_CCIN_inter   : xbuffer_CCIN_intra;
    assign xbuffer_DONE   = inter_flag ? xbuffer_DONE_inter   : xbuffer_DONE_intra;
    assign xbuffer_VOUT   = inter_flag ? xbuffer_VOUT_inter   : xbuffer_VOUT_intra;
    assign xbuffer_VALIDO = inter_flag ? xbuffer_VALIDO_inter : xbuffer_VALIDO_intra;

    h264buffer_intra xbuffer_intra
    (
        .CLK                ( clk2                                                  ), 
        .NEWSLICE           ( top_NEWSLICE                                          ), 
        .NEWLINE            ( top_NEWLINE                                           ), 
        .VALIDI             ( quantise_VALID && !inter_flag && inter_flag_valid     ),
        .ZIN                ( quantise_ZOUT                                         ), 
        .READYI             ( xbuffer_READYI_intra                                  ), 
        .CCIN               ( xbuffer_CCIN_intra                                    ), 
        .DONE               ( xbuffer_DONE_intra                                    ),
        .VOUT               ( xbuffer_VOUT_intra                                    ), 
        .VALIDO             ( xbuffer_VALIDO_intra                                  ), 
        .NLOAD              ( xbuffer_NLOAD_intra                                   ), 
        .NX                 ( xbuffer_NX_intra                                      ),
        .NY                 ( xbuffer_NY_intra                                      ), 
        .NV                 ( xbuffer_NV_intra                                      ), 
        .NXINC              ( xbuffer_NXINC_intra                                   ), 
        .READYO             ( cavlc_READY                                           ),
        .TREADYO            ( tobytes_READY                                         ), 
        .HVALID             ( header_VALID                                          ) 
    );

    h264buffer_inter xbuffer_inter
    (
        .CLK                ( clk2                                                  ), 
        .NEWSLICE           ( top_NEWSLICE                                          ), 
        .NEWLINE            ( top_NEWLINE                                           ), 
        .VALIDI             ( quantise_VALID && inter_flag && inter_flag_valid      ),
        .ZIN                ( quantise_ZOUT                                         ), 
        .READYI             ( xbuffer_READYI_inter                                  ), 
        .CCIN               ( xbuffer_CCIN_inter                                    ), 
        .DONE               ( xbuffer_DONE_inter                                    ),
        .VOUT               ( xbuffer_VOUT_inter                                    ), 
        .VALIDO             ( xbuffer_VALIDO_inter                                  ), 
        .NLOAD              ( xbuffer_NLOAD_inter                                   ), 
        .NX                 ( xbuffer_NX_inter                                      ),
        .NY                 ( xbuffer_NY_inter                                      ), 
        .NV                 ( xbuffer_NV_inter                                      ), 
        .NXINC              ( xbuffer_NXINC_inter                                   ), 
        .READYO             ( cavlc_READY                                           ),
        .TREADYO            ( tobytes_READY                                         ), 
        .HVALID             ( header_VALID                                          ) 
    );

    assign cavlc_VIN      = xbuffer_VOUT;
    assign cavlc_ENABLE   = xbuffer_VALIDO;

    h264cavlc cavlc
    (
        .CLK                ( clk                   ), 
        .CLK2               ( clk2                  ), 
        .VS                 ( nop2                  ),
        .ENABLE             ( cavlc_ENABLE          ), 
        .READY              ( cavlc_READY           ), 
        .VIN                ( cavlc_VIN             ),
        .NIN                ( cavlc_NIN             ), 
        .SIN                ( 1'b0                  ),  
        .VE                 ( cavlc_VE              ), 
        .VL                 ( cavlc_VL              ), 
        .VALID              ( cavlc_VALID           ),
        .XSTATE             ( cavlc_XSTATE          ), 
        .NOUT               ( cavlc_NOUT            )
    );

    h264tobytes tobytes
    (
        .CLK                ( clk                   ), 
        .VALID              ( tobytes_VALID         ), 
        .READY              ( tobytes_READY         ), 
        .VE                 ( tobytes_VE            ), 
        .VL                 ( tobytes_VL            ), 
        .BYTE               ( tobytes_BYTE          ), 
        .STROBE             ( tobytes_STROBE        ), 
        .DONE               ( tobytes_DONE          )
    );

   	assign tobytes_VE = header_VALID ? {5'b00000, header_VE} : cavlc_VALID ? cavlc_VE : {1'b0, 24'h030080};
	assign tobytes_VL = header_VALID ? header_VL : cavlc_VALID ? cavlc_VL : 5'b01000;
	assign tobytes_VALID = header_VALID | align_VALID | cavlc_VALID;

    always_ff @(posedge clk2)
    begin
        if (xbuffer_NLOAD)
        begin
			ninleft[xbuffer_NY] <= cavlc_NOUT;
			nintop[{ninx, xbuffer_NX}] <= cavlc_NOUT;
        end
		else
        begin
			ninl <= ninleft[xbuffer_NY];
			nint <= nintop[{ninx, xbuffer_NX}];
		end
		if (top_NEWLINE)
        begin
			ninx <= '0;
        end
		else if (xbuffer_NXINC)
        begin
			ninx <= ninx + 1;
		end
        if (recon_FBSTROBE)
        begin
            toppix[{mbx, intra4x4_XXO}] <= recon_FEEDB;
        end 
        if (intra4x4_MSTROBEO)
        begin
            topmode[{mbx, intra4x4_XXO}] <= intra4x4_MODEO;
        end
        if (top_NEWLINE) 
        begin
            mbx <= '0;
        end
        else if (intra4x4_XXINC) 
        begin
            mbx <= mbx + 1;
        end 
        if (recon_FBCSTROBE)
        begin
            toppixcc[{mbxcc, intra8x8cc_XXO}] <= recon_FEEDB;
        end
        if (top_NEWLINE)
        begin
            mbxcc <= '0;
        end
        else if (intra8x8cc_XXINC) 
        begin
            mbxcc <= mbxcc + 1;
        end
    end

    assign cavlc_NIN = xbuffer_NV==1 ? ninl : xbuffer_NV==2 ? nint : xbuffer_NV==3 ? ninsum[5:1] : '0;
	assign ninsum = {1'b0, ninl} + {1'b0, nint} + 1;

    // initial
    // begin
    //     forever 
    //     begin
        always_ff @(posedge clk2 ) 
        begin
            clk <= ~clk;
        end
    //     end
       
    // end

    initial
    begin
        inb = $fopen("sample_int.yuv", "rb");

        if(inb)
        begin
            $display("File Opened Successfully");
        end
        else
        begin
            $display("File Opening Failed");
        end

        while (!$feof(inb) && framenum < MAXFRAMES)
        begin
            for (y = 0; y < IMGHEIGHT; y++)
            begin
                for(x = 0; x < IMGWIDTH; x++)
                begin
                    $fread(c, inb); 
                    yvideo[x][y] = c;
                end
            end

            for (y = 0; y < IMGHEIGHT/2; y++)
            begin
                for(x = 0; x < IMGWIDTH/2; x++)
                begin
                    $fread(c, inb);
                    uvideo[x][y] = c;
                end
            end

            for (y = 0; y < IMGHEIGHT/2; y++)
            begin
                for(x = 0; x < IMGWIDTH/2; x++)
                begin
                    $fread(c, inb);
                    vvideo[x][y] = c;
                end
            end

            for (y_copy = 0; y_copy < IMGHEIGHT; y_copy++) begin
                for (x_copy = 0; x_copy < IMGWIDTH; x_copy++) begin
                    yrvideo_ref[x_copy][y_copy] = yrvideo_curr[x_copy][y_copy];
                end
            end

            for (y_copy = 0; y_copy < IMGHEIGHT/2; y_copy++) begin
                for (x_copy = 0; x_copy < IMGWIDTH/2; x_copy++) begin
                    urvideo_ref[x_copy][y_copy] <= urvideo_curr[x_copy][y_copy];
                    vrvideo_ref[x_copy][y_copy] <= vrvideo_curr[x_copy][y_copy];
                end
            end

            @(posedge clk2);

            framenum++;

            $display("Frame %2d read succesfully", framenum);
            $display("Using QP: %2d", qp);

            top_NEWLINE = 1;
            top_NEWSLICE = 1;
            x = 0;
            y = 0;
            cx = 0;
            cy = 0;
            cuv = 0;

            @(posedge clk2);

            while((y < IMGHEIGHT) || (cy < IMGHEIGHT/2))
            begin
                if (top_NEWLINE)
                begin
                    cx = 0;
                    cy = cy - (cy % 8);
                    cuv = 0;
                end
                if ((intra4x4_READYI || inter_mc_READYI) && (y < IMGHEIGHT) && inter_flag_valid )
                begin
                    @(posedge clk2);

                    top_NEWLINE = 0;
                    top_NEWSLICE = 0;

                    if (inter_flag == 0) 
                    begin
                        // INTRA mode selected
                        intra4x4_STROBEI = 1;

                        for (i = 0; i <= 1; i++)
                        begin
                            for (j = 0; j <= 3; j++)
                            begin
                                intra4x4_DATAI = {
                                    yvideo[x+3][y], 
                                    yvideo[x+2][y], 
                                    yvideo[x+1][y], 
                                    yvideo[x][y]
                                };
                                @(posedge clk2);
                                x = x + 4;
                            end
                            x = x - 16;	
                            y = y + 1;
                        end
                        intra4x4_STROBEI = 0;
                    end 
                    else if ( (inter_flag == 1) && (!y_processed) )
                    begin
                        // INTER mode selected
                        inter_mc_VALIDI = 1;

                        for (j = 0; j <= 3; j++)
                        begin
                            inter_mc_CURR = {
                                yvideo[x+3][y], 
                                yvideo[x+2][y], 
                                yvideo[x+1][y], 
                                yvideo[x][y]
                            };
                            inter_mc_REF = {
                                search_block_reg_y[inter_mvx+3][inter_mvy], 
                                search_block_reg_y[inter_mvx+2][inter_mvy], 
                                search_block_reg_y[inter_mvx+1][inter_mvy], 
                                search_block_reg_y[inter_mvx][inter_mvy]
                            };
                            @(posedge clk2);
                            x = x + 4;
                        end
                        x = x - 16;	
                        y = y + 1;
                        inter_mc_VALIDI = 0;
                    end

                    // Advance block position after processing
                    if ((y % 16) == 0)
                    begin
                        x = x + 16;
                        y = y - 16;			
                        if (x == IMGWIDTH)
                        begin
                            x = 0;			
                            y = y + 16;
                            if (xbuffer_DONE == 0)
                                wait (xbuffer_DONE == 1);
                            top_NEWLINE = 1;
                            $display("Newline pulsed Line: %2d Progress: %2d%%", y, y*100/IMGHEIGHT);
                        end

                        if (inter_flag)
                            begin
                                y_processed = 1;
                            end
                    end
                end

                if ((intra8x8cc_READYI || inter_mc_READYI) && (cy < IMGHEIGHT/2) && inter_flag_valid)
                    begin
                        @(posedge clk2);

                        if (inter_flag == 0) 
                        begin
                            // INTRA mode selected
                            intra8x8cc_STROBEI = 1;

                            for (j = 0; j <= 3; j++)
                                begin
                                    for (i = 0; i <= 1; i++)
                                    begin
                                        if (cuv == 0)
                                        begin
                                            intra8x8cc_DATAI = {
                                                uvideo[cx+i*4+3][cy], 
                                                uvideo[cx+i*4+2][cy], 
                                                uvideo[cx+i*4+1][cy], 
                                                uvideo[cx+i*4][cy]
                                            };
                                        end
                                        else
                                        begin
                                            intra8x8cc_DATAI = {
                                                vvideo[cx+i*4+3][cy], 
                                                vvideo[cx+i*4+2][cy], 
                                                vvideo[cx+i*4+1][cy], 
                                                vvideo[cx+i*4][cy]
                                            };
                                        end
                                        @(posedge clk2);
                                    end
                                    cy = cy + 1;
                                end
                            intra8x8cc_STROBEI = 0;
                        end
                        else if ( (inter_flag == 1) && y_processed)
                        begin
                            // INTER mode selected
                            inter_mc_VALIDI = 1;

                            for (j = 0; j <= 3; j++)
                                begin
                                    if (cuv == 0)
                                    begin
                                        inter_mc_CURR = {
                                            uvideo[cx + (j*4) + 3 ][cy], 
                                            uvideo[cx + (j*4) + 2 ][cy], 
                                            uvideo[cx + (j*4) + 1 ][cy], 
                                            uvideo[cx + (j*4)][cy]
                                        };
                                        inter_mc_REF = {
                                            search_block_reg_u[(inter_mvx / 2 ) + (j*4) + 3][(inter_mvy / 2 )], 
                                            search_block_reg_u[(inter_mvx / 2 ) + (j*4) + 2][(inter_mvy / 2 )], 
                                            search_block_reg_u[(inter_mvx / 2 ) + (j*4) + 1][(inter_mvy / 2 )], 
                                            search_block_reg_u[(inter_mvx / 2 ) + (j*4)][(inter_mvy / 2 )]
                                        };
                                    end
                                    else
                                    begin
                                        inter_mc_CURR = {
                                            vvideo[cx + (j*4) + 3][cy], 
                                            vvideo[cx + (j*4) + 2][cy], 
                                            vvideo[cx + (j*4) + 1][cy], 
                                            vvideo[cx + (j*4) ][cy]
                                        };
                                        inter_mc_REF = {
                                            search_block_reg_v[(inter_mvx / 2 ) + (j*4) + 3][(inter_mvy / 2 )], 
                                            search_block_reg_v[(inter_mvx / 2 ) + (j*4) + 2][(inter_mvy / 2 )], 
                                            search_block_reg_v[(inter_mvx / 2 ) + (j*4) + 1][(inter_mvy / 2 )], 
                                            search_block_reg_v[(inter_mvx / 2 ) + (j*4)][(inter_mvy / 2 )]
                                        };
                                    end
                                    @(posedge clk2);
                                    cy += 1;
                                end    
                            inter_mc_VALIDI = 0;
                        end

                        if ((cy % 8) == 0) 
                        begin
                            if (cuv == 0) 
                            begin
                                cy = cy-8;
                                cuv = 1;
                            end
                            else
                            begin
                                cuv = 0;
                                cy = cy - 8;
                                cx = cx + 8;
                                if (cx == IMGWIDTH/2)
                                begin
                                    cx = 0;	
                                    cy = cy + 8;
                                end
                                if (inter_flag)
                                begin
                                    y_processed = 0;
                                end
                            end
                        end
                    end
                
                // Update macroblock position and search block address after inter-prediction completes
                if (valid == 1) 
                    begin
                        // Calculate the absolute address of the search block in yrvideo_curr
                        search_block_addr = (mb_y - SEARCH_DIM / 2) * IMGWIDTH + (mb_x - SEARCH_DIM / 2);
                
                        // Ensure the search block stays within bounds using zero-padding
                        if (mb_x - SEARCH_DIM / 2 < 0 || mb_y - SEARCH_DIM / 2 < 0 ||
                            mb_x + SEARCH_DIM / 2 >= IMGWIDTH || mb_y + SEARCH_DIM / 2 >= IMGHEIGHT) begin
                            $display("Zero-padding applied for macroblock at (%d, %d)", mb_x, mb_y);
                        end
                
                        // Update macroblock position for the next iteration
                        mb_x <= mb_x + 16; // Move to the next macroblock in the row
                        if (mb_x + 16 >= IMGWIDTH) begin
                            mb_x = 0; // Reset to the first column
                            mb_y = mb_y + 16; // Move to the next row
                        end

                        @(posedge clk2);
                    end
                
                // Inter-Prediction Logic
                if (ready == 1 && !inter_flag_valid) 
                    begin
                        integer l, f;
                    
                        // Load macroblock data into pixel_cpr_in
                        for (l = 0; l < MACRO_DIM; l++) 
                            begin
                                if (en_ram) 
                                    begin
                                        pixel_cpr_in[l] = yvideo[l + x][addr + y];
                                    end
                            end
                    
                        // Load the search block data into pixel_spr_in and simultaneously store it in search_block_reg_y with zero-padding
                        for (l = 0; l < PORT_WIDTH; l++) 
                            begin
                                if (en_ram) 
                                    begin
                                        integer x_idx, y_idx;
                                        x_idx = (search_block_addr % IMGWIDTH) + l + amt;
                                        y_idx = (search_block_addr / IMGWIDTH);
                            
                                        // Apply zero-padding for out-of-bounds indices
                                        if (x_idx < 0 || x_idx >= IMGWIDTH || y_idx < 0 || y_idx >= IMGHEIGHT) 
                                            begin
                                                pixel_spr_in[l] = 0; // Zero-pad out-of-bounds pixels
                                            end 
                                        else 
                                            begin
                                                pixel_spr_in[l] = yrvideo_curr[x_idx][y_idx]; // Load pixel into pixel_spr_in
                                            end
                            
                                        // Store the corresponding pixel in search_block_reg_y
                                        integer row, col;
                                        row = l / SEARCH_DIM;
                                        col = l % SEARCH_DIM;
                            
                                        if (x_idx < 0 || x_idx >= IMGWIDTH || y_idx < 0 || y_idx >= IMGHEIGHT) 
                                            begin
                                                search_block_reg_y[row][col] = 0; // Zero-pad out-of-bounds pixels
                                            end 
                                        else 
                                            begin
                                                search_block_reg_y[row][col] = yrvideo_curr[x_idx][y_idx]; // Store pixel in search_block_reg_y
                                            end
                            
                                        // Chroma-specific logic for U and V components (YUV 4:2:0 FORMAT)
                                        integer x_idx_chroma, y_idx_chroma;
                                        x_idx_chroma = (search_block_addr % (IMGWIDTH / 2)) + (l / 2) + (amt / 2);
                                        y_idx_chroma = (search_block_addr / (IMGWIDTH / 2));
                            
                                        // Store U component in search_block_reg_u
                                        if (x_idx_chroma < 0 || x_idx_chroma >= IMGWIDTH / 2 || y_idx_chroma < 0 || y_idx_chroma >= IMGHEIGHT / 2) 
                                            begin
                                                search_block_reg_u[row / 2][col / 2] = 0; // Zero-pad out-of-bounds pixels
                                            end 
                                        else 
                                            begin
                                                search_block_reg_u[row / 2][col / 2] = urvideo_curr[x_idx_chroma][y_idx_chroma]; // Store pixel in search_block_reg_u
                                            end
                            
                                        // Store V component in search_block_reg_v
                                        if (x_idx_chroma < 0 || x_idx_chroma >= IMGWIDTH / 2 || y_idx_chroma < 0 || y_idx_chroma >= IMGHEIGHT / 2) 
                                            begin
                                                search_block_reg_v[row / 2][col / 2] = 0; // Zero-pad out-of-bounds pixels
                                            end 
                                        else 
                                            begin
                                                search_block_reg_v[row / 2][col / 2] = vrvideo_curr[x_idx_chroma][y_idx_chroma]; // Store pixel in search_block_reg_v
                                            end
                                    end
                            end
                    
                        // Update trans_addr based on amt
                        for (f = 0; f < PORT_WIDTH; f++) 
                            begin
                                if (f < amt) 
                                    begin
                                        trans_addr[f] = search_block_addr + SEARCH_DIM;
                                    end 
                                else 
                                    begin
                                        trans_addr[f] = search_block_addr;
                                    end
                            end
                    
                        @(posedge clk2);
                        start = 1;
                    end
                else
                    begin
                        start = 0;
                    end
                @(posedge clk2);
            end


            $display("Done push of data into intra4x4 and intra8x8cc");
            if (!xbuffer_DONE)
            begin
                wait (xbuffer_DONE == 1);
            end
            for (w = 1; w <= 32; w++)
            begin
			    @(posedge clk);
            end
            @(posedge clk);
            align_VALID = 1;	
            @(posedge clk);
            align_VALID = 0;
            @(posedge clk);
            $display("Done align at end of NAL");
            if (!tobytes_DONE)
            begin
			    wait (tobytes_DONE == 1);
		    end
            @(posedge clk);
            @(posedge clk);
		end

		$display("%2d frames processed", framenum);

		$fclose(inb);
        `ifdef VERILATOR
            dpi_close_file();
        `else
            $fclose(outb);
        `endif
		$fclose(recb);

		$finish;   
    end

    localparam hd = 200'haa0000000167420028da0582590000000168ce388000000001;
    localparam hdsize = 24;


`ifdef VERILATOR
    initial 
    begin
        dpi_open_file("sample_out.264");

        // Write header
        for (int i = hdsize-1; i >= 0; i--) 
        begin
            c = hd[8*i +: 8];
            dpi_write_byte(c);
        end

        // Loop to write runtime bytes
        forever 
        begin
            if (tobytes_STROBE) 
            begin
                dpi_write_byte(tobytes_BYTE);
                count = count + 1;
            end

            if (tobytes_DONE) 
            begin
                count = 0;
                dpi_write_byte(8'b00000000);
                dpi_write_byte(8'b00000000);
                dpi_write_byte(8'b00000000);
                dpi_write_byte(8'b00000001);
            end

            @(posedge clk);
        end
    end
`else
    initial
    begin
        outb = $fopen("sample_out.264", "wb");

        for (i = hdsize-1; i >= 0; i--)
        begin
            c = hd[ 8*i +: 8 ];
            $fwrite(outb, "%c", c);
        end

        forever
        begin
            if (tobytes_STROBE)
            begin
                $fwrite(outb, "%c", tobytes_BYTE);
                count = count + 1;
            end

            if (tobytes_DONE)
            begin
                count = 0;
                $fwrite(outb, "%c", 8'b00000000);
                $fwrite(outb, "%c", 8'b00000000);
                $fwrite(outb, "%c", 8'b00000000);
                $fwrite(outb, "%c", 8'b00000001);
		    end

            @(posedge clk);
	    end
    end
`endif

	always_ff @(posedge clk2)
	begin
		assert (!(header_VALID && cavlc_VALID)) else $error("Two strobes clash.");
		assert (!(coretransform_VALID && dctransform_VALID)) else $error("Two strobes clash.");
		assert (!(intra4x4_STROBEO && intra8x8cc_STROBEO)) else $error("Two strobes clash.");
		assert (!($isunknown(cavlc_VIN)));
	end



	integer xr     = 0; 
	integer yr     = 0;
	integer cxr    = 0;  
	integer cyr    = 0;
	integer cuvr   = 0;
	integer diff   = 0;

	real ssqdiff   = 0.0;
	real sqmaxval  = 255*255;
	real planesize = 0.0;
	real snr       = 0.0;

	initial 
	begin
		recb = $fopen("recon_out.yuv", "wb");
        if(recb)
        begin
            $display("File Opened Successfully");
        end
        else
        begin
            $display("File Opening Failed");
        end
	end

	always_ff @(posedge clk2)
	begin
		if (dumprecon || computesnr)
		begin
			if ( recon_FBSTROBE )
			begin
				yrvideo_curr[xr  ][yr] = recon_FEEDB[ 7: 0];
				yrvideo_curr[xr+1][yr] = recon_FEEDB[15: 8];
				yrvideo_curr[xr+2][yr] = recon_FEEDB[23:16]; 
				yrvideo_curr[xr+3][yr] = recon_FEEDB[31:24];
				yr = yr + 1;
				if (yr % 4 == 0)
				begin
					yr = yr - 4;
					xr = xr + 4;
					if (xr % 8 == 0)
					begin
						xr = xr - 8;
						yr = yr + 4;
						if (yr % 8 == 0)
						begin
							yr = yr - 8;
							xr = xr + 8;
							if (xr % 16 == 0)
							begin
								xr = xr - 16;
								yr = yr + 8;
								if (yr % 16 == 0)
								begin
									yr = yr - 16;
									xr = xr + 16;
									if (xr == IMGWIDTH)
									begin
										xr = 0;
										yr = yr + 16;
									end
								end
							end
						end
					end
				end
			end

			if ( recon_FBCSTROBE )
			begin
				if ( cuvr == 0 )
				begin
					urvideo_curr[cxr  ][cyr] = recon_FEEDB[ 7: 0];
					urvideo_curr[cxr+1][cyr] = recon_FEEDB[15: 8];
					urvideo_curr[cxr+2][cyr] = recon_FEEDB[23:16];
					urvideo_curr[cxr+3][cyr] = recon_FEEDB[31:24];
				end
				else
				begin
					vrvideo_curr[cxr  ][cyr] = recon_FEEDB[ 7: 0];
					vrvideo_curr[cxr+1][cyr] = recon_FEEDB[15: 8];
					vrvideo_curr[cxr+2][cyr] = recon_FEEDB[23:16];
					vrvideo_curr[cxr+3][cyr] = recon_FEEDB[31:24];
				end
				cyr = cyr + 1;
				if (cyr % 4 == 0)
				begin
					cyr = cyr - 4;
					cxr = cxr + 4;
					if (cxr % 8 == 0)
					begin
						cxr = cxr - 8;
						cyr = cyr + 4;
						if (cyr % 8 == 0)
						begin
							cyr  = cyr - 8;
							cuvr = cuvr + 1;
							if (cuvr == 2)
							begin
								cuvr = 0;
								cxr  = cxr + 8;
								if (cxr == IMGWIDTH/2)
								begin
									cxr = 0;
									cyr = cyr + 8;
								end
							end
						end
					end
				end
			end

			if ( ((yr == IMGHEIGHT) && (cyr == IMGHEIGHT/2)) && tobytes_DONE )
			begin

				if (dumprecon)
				begin
					for (yr = 0; yr < IMGHEIGHT; yr++)
					begin
						for (xr = 0; xr < IMGWIDTH; xr++)
						begin
							$fwrite(recb, "%c", yrvideo_curr[xr][yr]);
						end
					end
					for (cyr = 0; cyr < IMGHEIGHT/2; cyr++)
					begin
						for (cxr = 0; cxr < IMGWIDTH/2; cxr++)
						begin
							$fwrite(recb, "%c", urvideo_curr[cxr][cyr]);
						end
					end
					for (cyr = 0; cyr < IMGHEIGHT/2; cyr++)
					begin
						for (cxr = 0; cxr < IMGWIDTH/2; cxr++)
						begin
							$fwrite(recb, "%c", vrvideo_curr[cxr][cyr]);
						end
					end
					$display("%0d bytes written to recon_out.yuv", IMGHEIGHT*IMGWIDTH*3/2);
				end

				if (computesnr)
				begin
					// Y Video SnR Computation

					ssqdiff = 0.0;

					for (yr = 0; yr < IMGHEIGHT; yr++)
					begin
						for (xr = 0; xr < IMGWIDTH; xr++)
						begin
							diff    = yrvideo_curr[xr][yr] - yvideo[xr][yr];
							ssqdiff = diff*diff + ssqdiff;
						end
					end
					
					planesize = IMGHEIGHT*IMGWIDTH;

					if (ssqdiff != 0.0)
					begin
						snr  = 10.0 * $log10(sqmaxval*planesize/ssqdiff);
						$display("SNR Y: %2.3f dB.", snr);
					end
					else
					begin
						$display("SNR Y: %2.3f dB.", 0);
					end

					// U Video SnR Computation

					ssqdiff = 0.0;

					for (cyr = 0; cyr < IMGHEIGHT/2-1; cyr++)
					begin
						for (cxr = 0; cxr < IMGWIDTH/2-1; cxr++)
						begin
							diff    = urvideo_curr[cxr][cyr] - uvideo[cxr][cyr];
							ssqdiff = diff*diff + ssqdiff;
						end
					end
					
					planesize = IMGHEIGHT*IMGWIDTH/4;

					if (ssqdiff != 0.0)
					begin
						snr  = 10.0 * $log10(sqmaxval*planesize/ssqdiff);
						$display("SNR U: %2.3f dB.", snr);
					end
					else
					begin
						$display("SNR U: %2.3f dB.", 0);
					end

					// V Video SnR Computation

					ssqdiff = 0.0;

					for (cyr = 0; cyr < IMGHEIGHT/2-1; cyr++)
					begin
						for (cxr = 0; cxr < IMGWIDTH/2-1; cxr++)
						begin
							diff    = vrvideo_curr[cxr][cyr] - vvideo[cxr][cyr];
							ssqdiff = diff*diff + ssqdiff;
						end
					end
					
					planesize = IMGHEIGHT*IMGWIDTH/4;

					if (ssqdiff != 0.0)
					begin
						snr  = 10.0 * $log10(sqmaxval*planesize/ssqdiff);
						$display("SNR V: %2.3f dB; ", snr);
					end
					else
					begin
						$display("SNR V: %2.3f dB; ", 0);
					end
				end

				xr   = 0;
				yr   = 0;
				cxr  = 0;
				cyr  = 0;
				cuvr = 0;

			end
		end
	end

endmodule
