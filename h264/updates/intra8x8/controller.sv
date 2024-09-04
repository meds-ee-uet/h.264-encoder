
// Description: State machine controller for enabling signals based on input 
//              conditions and state transitions.
//
// Author: Muhammad Ramzan EED, UET Lahore
// Date: 25-08-2024
//------------------------------------------------------------------------------

//============================ Controller Module ============================//
module controller(
    input  logic CLK2,
    input  logic NEWLINE,
    input  logic STROBEI,
    input  logic READYO,
    input  logic FBSTROBE,
    //
    input logic crcb,			//which of cr/cb
    input logic [1:0] quad,	    //which of 4 blocks
    input logic [1:0] oquad,    //which of 4 blocks output
    input logic [4:0] istate,	//which input word
    input logic fbpending,	    //wait for feedback

    //
    output logic enable_S0,
    output logic enable_S1,
    output logic enable_S2,
    output logic enable_S3,
    output logic enable_S4,
    output logic enable_S5,
    output logic enable_S6,
    output logic enable_S7,
    output logic enable_S8,
    output logic enable_S9,
    output logic enable_S10,
    output logic enable_S11,
    output logic enable_S12,
    output logic enable_S13,
    output logic enable_S14,
    output logic enable_S15
);
//============================ Parameter Definitions ============================//
parameter IDLE = 4'b0000;
parameter S1   = 4'b0001;
parameter S2   = 4'b0010;
parameter S3   = 4'b0011;
parameter S4   = 4'b0100;
parameter S5   = 4'b0101;
parameter S6   = 4'b0110;
parameter S7   = 4'b0111;
parameter S8   = 4'b1000;
parameter S9   = 4'b1001;
parameter S10  = 4'b1010;
parameter S11  = 4'b1011;
parameter S12  = 4'b1100;
parameter S13  = 4'b1101;
parameter S14  = 4'b1110;
parameter S15  = 4'b1111;

logic [3:0] c_state;
logic [3:0] n_state;
//============================ State Register ============================//
always_ff @(posedge CLK2 or negedge NEWLINE) 
begin
    if (NEWLINE) begin
        c_state <= IDLE;
    end else begin
        c_state <= n_state;
    end
end
//============================ Next State Logic ============================//
always_comb
begin
    enable_S0  = 1'b0;
    enable_S1  = 1'b0;
    enable_S2  = 1'b0;
    enable_S3  = 1'b0;
    enable_S4  = 1'b0;
    enable_S5  = 1'b0;
    enable_S6  = 1'b0;
    enable_S7  = 1'b0;
    enable_S8  = 1'b0;
    enable_S9  = 1'b0;
    enable_S10 = 1'b0;
    enable_S11 = 1'b0;
    enable_S12 = 1'b0;
    enable_S13 = 1'b0;
    enable_S14 = 1'b0;
    enable_S15 = 1'b0;


    // Next state logic and enable signal generation
    case (c_state)
        IDLE: begin
            if (istate[4] != crcb) 
            begin
                enable_S0 = 1'b1;
                n_state = IDLE;
            end 
            else 
            begin
                n_state = S1;
            end
            //end
        end
        S1: begin
            enable_S1 = 1'b1;
            n_state = S2;
        end
        S2: begin
            enable_S2 = 1'b1;
            n_state = S3;
        end
        S3: begin
            enable_S3 = 1'b1;
            n_state = S4;
        end
        S4: begin
            enable_S4 = 1'b1;
            n_state = S5;
        end
        S5: begin
            enable_S5 = 1'b1;
            n_state = S6;
        end
        S6: begin
            enable_S6 = 1'b1;
            n_state = S7;
        end
        S7: begin
            enable_S7 = 1'b1;
            if (oquad != 2'd3) begin
                n_state = S4; // Loop back to S4
            end else begin
                n_state = S8;
            end
        end
        S8: begin
            enable_S8 = 1'b1;
            if (READYO == 1'b0) begin
                n_state = S8; // Stay in S8 until READY is high
            end else begin
                n_state = S9;
            end
        end
        S9: begin
            enable_S9 = 1'b1;
            n_state = S10;
        end
        S10: begin
            enable_S10 = 1'b1;
            n_state = S11;
        end
        S11: begin
            enable_S11 = 1'b1;
            n_state = S12;
        end
        S12: begin
            enable_S12 = 1'b1;
            n_state = S13;
        end
        S13: begin
            enable_S13 = 1'b1;
            n_state = S14;
        end
        S14: begin
            enable_S14 = 1'b1;
            if (fbpending == 1'b1 || FBSTROBE == 1'b1) begin
                // Stay in S14 if feedback is pending or strobe is active
                n_state = S14;
            end else if (quad != 2'd0) begin
                n_state = S8; // Loop back to S8 for all blocks
            end else begin
                n_state = S15;
            end
        end
        S15: begin
            enable_S15 = 1'b1;
            n_state = IDLE; // Loop back to IDLE
        end
        default: begin
            n_state = IDLE; // Default to IDLE if no match
        end
        //end
    endcase
end

endmodule
