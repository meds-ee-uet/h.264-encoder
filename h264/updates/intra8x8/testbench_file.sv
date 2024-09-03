module testbench_file();
    // Inputs
    logic CLK2;
    logic NEWSLICE;
    logic NEWLINE; 
    logic STROBEI; 
    logic FBSTROBE;
    logic READYO;
    logic [7:0] FEEDBI; 
    logic [31:0] DATAI; 
    logic [31:0] TOPI;

    // Outputs
    logic STROBEO;
    logic DCSTROBEO;
    logic READYI;
    logic XXC;
    logic XXINC;
    logic [1:0] XXO;
    logic [1:0] CMODEO;
    logic [15:0] DCDATAO;
    logic [31:0] BASEO;
    logic [35:0] DATAO;

    // Instantiate the DUT
    datapath dut (
        .CLK2(CLK2),
        .NEWSLICE(NEWSLICE),
        .NEWLINE(NEWLINE),
        .STROBEI(STROBEI),
        .FBSTROBE(FBSTROBE),
        .FEEDBI(FEEDBI),
        .READYO(READYO),
        .DATAI(DATAI),
        .TOPI(TOPI),
        .STROBEO(STROBEO),
        .DCSTROBEO(DCSTROBEO),
        .READYI(READYI),
        .XXC(XXC),
        .XXINC(XXINC),
        .XXO(XXO),
        .CMODEO(CMODEO),
        .DCDATAO(DCDATAO),
        .BASEO(BASEO),
        .DATAO(DATAO)
    );

    // Clock generation
    initial begin
        CLK2 = 0;
        forever #10 CLK2 = ~CLK2;
    end

    // Reset and stimulus generation
    initial begin
        // Initialize inputs
        NEWLINE   <= #1 1;
        NEWSLICE  <= #1 0;
        STROBEI   <= #1 0;
        FBSTROBE  <= #1 0;
        READYO    <= #1 0;
        FEEDBI    <= #1 0;
        DATAI     <= #1 0;
        TOPI      <= #1 0;
        @(posedge CLK2);
        NEWLINE   <= #1 0;
    end
    initial
    begin
        // Deassert reset after some cycles
        @(posedge CLK2);
        //NEWLINE   <= #1 0;
        NEWSLICE  <= #1 1;
        STROBEI   <= #1 1;
        FBSTROBE  <= #1 1;
        READYO    <= #1 1;
        FEEDBI    <= #1 8'hAA;
        DATAI     <= #1 32'h87654321;
        TOPI      <= #1 32'h65432345;

        // Apply test stimulus
        @(posedge CLK2);
        NEWSLICE  <= #1 1;
        STROBEI   <= #1 0;
        FBSTROBE  <= #1 1;
        READYO    <= #1 0;
        FEEDBI    <= #1 8'hAA;
        DATAI     <= #1 32'h12345678;
        TOPI      <= #1 32'h87654321;

        @(posedge CLK2);
        NEWSLICE  <= #1 0;
        STROBEI   <= #1 1;
        FBSTROBE  <= #1 0;
        READYO    <= #1 1;
        FEEDBI    <= #1 8'h55;
        DATAI     <= #1 32'h9ABCDEF0;
        TOPI      <= #1 32'h0FEDCBA9;

        @(posedge CLK2);
        // we can apply more stimulus or assertions here as needed

        // Finish simulation after some time
        $finish;
    end
    // Monitor and display output
    initial begin
        $monitor("At time %t, STROBEO = %b, DCSTROBEO = %b, READYI = %b, DATAO = %h", 
                 $time, STROBEO, DCSTROBEO, READYI, DATAO);
    end

endmodule
