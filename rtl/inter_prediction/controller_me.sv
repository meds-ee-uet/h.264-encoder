module controller_me
#
(
    parameter MACRO_DIM,
    parameter SEARCH_DIM
) 
(
    input  logic       rst_n, 
    input  logic       clk, 
    input  logic       start,
    output logic       readyi,
    output logic       comp_en,
    output logic       en_cpr, 
    output logic       en_spr,
    output logic       en_ram,
    input  logic       readyo,
    output logic       valido,
    output logic [5:0] addr, //output logic [5:0] addr [MACRO_DIM:0] Try
    output logic [5:0] amt,
    output logic [1:0] sel
);

    localparam S0 = 4'b0000;
    localparam S1 = 4'b0001;
    localparam S2 = 4'b0010;
    localparam S3 = 4'b0011;
    localparam S4 = 4'b0100;
    localparam S5 = 4'b0101;
    localparam S6 = 4'b0110;
    localparam S7 = 4'b0111;
    localparam S8 = 4'b1000;

    logic [5:0] count;
    logic       en_count_inc;
    logic       en_count_dec;
    logic       sel_to_start;
    logic       sel_to_end;
    logic       rst_count;

    logic [3:0] state;
    logic [3:0] next_state;

    //State Machine

    always_ff@(posedge clk or negedge rst_n) 
    begin
        if(~rst_n)
        begin
            state <= S0;
        end
        else
        begin
            state <= next_state;
        end
    end

    always_comb 
    begin
        next_state = S0;
        case(state)
            S0: 
            begin
                if(start)
                begin
                    next_state = S1;
                end
                else
                begin
                    next_state = S0;
                end
            end
            S1: 
            begin
                if(count == MACRO_DIM-1)
                begin
                    next_state = S2;
                end
                else
                begin
                    next_state = S1;
                end
            end
            S2: 
            begin
                next_state = S3;
            end
            S3:
            begin
                if(count == MACRO_DIM-1)
                begin
                    next_state = S4;
                end
                else
                begin
                    next_state = S3;
                end
            end
            S4:
            begin
                if(count == SEARCH_DIM-1)
                begin
                    next_state = S5;
                end
                else
                begin
                    next_state = S4;
                end
            end
            S5:
            begin
                if(amt > SEARCH_DIM - MACRO_DIM)
                begin
                    next_state = S8;
                end
                else
                begin
                    next_state = S6;
                end
            end
            S6:
            begin
                if(count == 0)
                begin
                    next_state = S7;
                end
                else
                begin
                    next_state = S6;
                end
            end
            S7:
            begin
                if(amt > SEARCH_DIM - MACRO_DIM)
                begin
                    next_state = S8;
                end
                else
                begin
                    next_state = S4;
                end
            end
            S8:
            begin
                if (readyo)
                begin
                    next_state = S0;
                end
                else
                begin
                    next_state = S8;
                end
            end
            default:
            begin
                next_state = S0;
            end
        endcase
    end

    always_comb 
    begin
        case(state)
            S0: // Reset State
            begin
                valido    = 0;
                readyi    = 1;
                comp_en   = 0;
                en_cpr    = 0;
                en_spr    = 0;
                rst_count = 1;
                amt       = 0;
                en_ram    = 0;
            end
            S1: // CPR Load State
            begin
                valido       = 0;
                readyi       = 0;
                comp_en      = 0;
                en_cpr       = 1;
                en_spr       = 0;
                rst_count    = 0;
                en_count_inc = 1;
                en_count_dec = 0;
                sel          = 1;
                en_ram       = 1;
            end
            S2: // Counter Reset State
            begin 
                valido    = 0;
                readyi    = 0;
                comp_en   = 0;
                en_cpr    = 0;
                en_spr    = 0;
                rst_count = 1;
                en_ram    = 0;
            end
            S3: // SPR Load State
            begin 
                valido       = 0;
                readyi       = 0;
                comp_en      = 0;
                en_cpr       = 0;
                en_spr       = 1;
                rst_count    = 0;
                en_count_inc = 1;
                en_count_dec = 0;
                sel          = 1;
                en_ram       = 1;
            end
            S4: // Upshift State
            begin 
                valido          = 0;
                readyi          = 0;
                comp_en         = 1;
                en_cpr          = 0;
                en_spr          = 1;
                rst_count       = 0;
                en_count_inc    = 1;
                en_count_dec    = 0;
                sel_to_start    = 0;
                sel_to_end   = 0;
                sel             = 1;
                en_ram          = 1;
            end
            S5: // Leftshift after Up State 
            begin
                readyi        = 0;
                comp_en        = 1;
                en_cpr       = 0;
                en_spr       = 1;
                rst_count    = 0;
                en_count_inc = 0;
                en_count_dec = 0;
                sel_to_start    = 0;
                sel_to_end    = 1;
                sel          = 2;
                amt          = amt + 1;
                en_ram       = 0;
            end
            S6: // Downshift State
            begin
                readyi       = 0;
                valido       = 0;
                comp_en      = 1;
                en_cpr       = 0;
                en_spr       = 1;
                rst_count    = 0;
                en_count_inc = 0;
                en_count_dec = 1;
                sel          = 0;
                en_ram       = 1;
            end
            S7: // Leftshift after Down State
            begin
                readyi       = 0;
                valido       = 0;
                comp_en      = 1;
                en_cpr       = 0;
                en_spr       = 1;
                rst_count    = 0;
                en_count_inc = 0;
                en_count_dec = 0;
                sel_to_start = 1;
                sel_to_end = 0;
                sel          = 2;
                amt          = amt + 1;
                en_ram       = 0;
            end

            S8:
            begin
                valido              = 1;
                readyi              = 0;
                comp_en             = 0;
                en_cpr              = 0;
                en_spr              = 0;
                rst_count           = 0;
                en_count_inc        = 0;
                en_count_dec        = 0;
                sel_to_start        = 0;
                sel_to_end       = 0;
                amt                 = amt;
                en_ram              = 0;
            end
        endcase
    end

    always_ff@(posedge clk or negedge rst_n)
    begin
        if(~rst_n | rst_count)
        begin
            count <= 0;
        end
        else if(en_count_inc)
        begin
            count <= count + 1;
        end
        else if(en_count_dec)
        begin
            count <= count - 1;
        end
        else if(sel_to_start)
        begin
            count <= MACRO_DIM;
        end
        else if(sel_to_end)
        begin
            count <= SEARCH_DIM - 1;
        end
    end

    assign addr = count;

endmodule