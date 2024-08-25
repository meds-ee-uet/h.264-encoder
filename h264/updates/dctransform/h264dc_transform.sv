module h264dc_transform #(
    parameter int TOGETHER = 0 // 1 if output kept together as one block
)(
    input logic CLK,                  // fast clock
    input logic RESET,                // reset when 1
    output logic READYI = '0,         // set when ready for ENABLE
    input logic ENABLE,               // values input only when this is 1
    input logic [15:0] XXIN,          // input data values (reverse order)
    output logic VALID = '0,          // values output only when this is 1
    output logic [15:0] YYOUT = '0,  // output values (reverse order)
    input logic READYO                // set when ready for ENABLE
);

    // Internal signals
    logic [15:0] xxii = 16'd0;
    logic enablei = 1'b0;
    logic [15:0] xx00 = 16'd0;
    logic [15:0] xx00_out = 16'd0;
    logic [15:0] xx01 = 16'd0;
    logic [15:0] xx01_out = 16'd0;
    logic [15:0] xx10 = 16'd0;
    logic [15:0] xx10_out = 16'd0;
    logic [15:0] xx11 = 16'd0;
    logic [15:0] xx11_out = 16'd0;
    logic [15:0] YYOUT_OUT = 16'd0;
    logic [1:0] ixx = 2'd0;
    logic iout = 1'b0;
    logic valid_next;
    logic iout_in;
    logic [1:0] en_mux;
    logic en_pipeline1,en_pipeline2,en_pipeline3,en_pipeline4; 

    assign en_counter1 = (enablei==1'b1 && RESET==1'b0);
    assign en_counter2 = (iout==1'b1 && (READYO==1'b1 || (TOGETHER==8'd1 && ixx!==0)) && RESET==1'b0);
    assign en_mux = {en_counter1,en_counter2};

    h264dc_transform_controller controller(
                            .CLK(CLK),
                            .RESET(RESET),
                            .ENABLE(ENABLE),
                            .en_pipeline1(en_pipeline1),
                            .en_pipeline2(en_pipeline2),
                            .en_pipeline3(en_pipeline3),
                            .en_pipeline4(en_pipeline4)
                            );

    always_ff @(posedge CLK)
        begin
        enablei <= ENABLE;
        xxii <= XXIN;
        end
        always_comb 
        begin
            READYI = ~iout;
            if (ixx == 2'd0) begin
                xx00 = xxii;
            end
            else begin
                xx00 = xx00 + xxii;
            end
            if (ixx == 2'd1) begin
                xx01 = xx00 - xxii;
            end
            else begin
                xx01 = xx01;
            end
            if (ixx == 2'd2) begin
                xx10 = xxii;
            end
            else begin
                xx10 = xx10 + xxii;
            end
            if (ixx == 2'd3) begin
                xx11 = xx10 - xxii;
            end
            else begin
                xx11 = xx11;
            end
        end   
        always_ff @(posedge CLK) begin
            if ((en_counter1) || (en_counter2)) begin	
                ixx  <= ixx + 1;
            end
        end

        always_ff @(posedge CLK) 
        begin
             if (en_pipeline1 & en_counter1) begin
                xx00_out <= xx00;
             end
             if (en_pipeline2 & en_counter1) begin
                xx01_out <= xx01;
             end
             if (en_pipeline3 & en_counter1) begin
                xx10_out <= xx10;
             end
             if (en_pipeline4 & en_counter1) begin
                xx11_out <= xx11;
            end
        end
        always_comb
        begin
            if (iout==1'b1 && (READYO==1'b1 || (TOGETHER==8'd1 && ixx!==0)) && RESET==1'b0) begin
                if (ixx==2'd0)begin
                    YYOUT_OUT = xx00_out + xx10_out;	//--out in raster scan order
            end
                else if (ixx==2'd1) begin
                    YYOUT_OUT = xx01_out + xx11_out;
                end
                else if (ixx==2'd2) begin
                    YYOUT_OUT = xx00_out - xx10_out;
                end
                else begin
                    YYOUT_OUT = xx01_out - xx11_out;
                end 
                valid_next = 1'b1;
            end
            else begin
                valid_next = 1'b0;
            end 
        end
        always_comb 
        begin
            case(en_mux)
            2'b01: iout_in = 1'b0;
            2'b10: iout_in = 1'b1;
            default:iout_in = iout;
            endcase
        end

        always_ff @(posedge CLK) begin
            if (RESET) begin
                YYOUT <= 16'd0;
                iout <= 1'b0;
                VALID <=1'b0;
            end
            else begin
                YYOUT <= YYOUT_OUT;
                iout <= iout_in;
                VALID <= valid_next;
            end
        end
endmodule




















































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































