module h264dc_transform_controller(
    input logic CLK,
    input logic RESET,
    input logic ENABLE,
    output logic en_pipeline1,en_pipeline2,en_pipeline3,en_pipeline4
);

logic [1:0] c_state,n_state;

parameter S0 = 2'b00 , S1 = 2'b01 , S2 = 2'b10 , S3 = 2'b11;
 
always_comb 
begin
    case(c_state)
    S0: 
    begin
        if (ENABLE) n_state = S1;
        else        n_state = S0;
    end
    S1: 
    begin
        if (ENABLE) n_state = S2;
        else        n_state = S1;
    end
    S2: 
    begin
        if (ENABLE) n_state = S3;
        else        n_state = S2;
    end
    S3: 
    begin
        if (ENABLE) n_state = S0;
        else        n_state = S3;
    end

    endcase

    case(c_state)
    S0: begin
         en_pipeline1 = 1'b1;
         en_pipeline2 = 1'b0;
         en_pipeline3 = 1'b0;
         en_pipeline4 = 1'b0;
    end
    S1: begin
        en_pipeline1 = 1'b1;
        en_pipeline2 = 1'b1;
        en_pipeline3 = 1'b0;
        en_pipeline4 = 1'b0;
    end
    S2: begin
        en_pipeline1 = 1'b0;
        en_pipeline2 = 1'b0;
        en_pipeline3 = 1'b1;
        en_pipeline4 = 1'b0;
    end
    S3: begin
        en_pipeline1 = 1'b0;
        en_pipeline2 = 1'b0;
        en_pipeline3 = 1'b1;
        en_pipeline4 = 1'b1;
    end
endcase
end

always_ff @ (posedge CLK)
begin
    if(RESET)
       c_state <= S0;
    else
       c_state <= n_state;    
end

endmodule
