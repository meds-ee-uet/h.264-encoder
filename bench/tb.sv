module tb;

    // Clock signal
    bit clk2;

    // DUT instantiation
    h264topsim dut ( .clk2(clk2) );

    // Clock generation: toggle every 5ns (10ns period)
    initial begin
        clk2 = 0;
        forever #5 clk2 = ~clk2;
    end

endmodule

