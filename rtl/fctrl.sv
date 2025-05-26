module fctrl #(
    MAX_COUNT,
    DATA_WIDTH
) (
    input   logic                   clk,
    input   logic                   RESET,
    input   logic                   VALIDI,
    input   logic                   DC,
    input   logic                   inter_flag_valid,
    output  logic                   VALIDO,
    input   logic [DATA_WIDTH-1:0]  DATAI,
    output  logic [DATA_WIDTH-1:0]  DATAO,
    output  logic                   ENABLE
);

logic [$clog2(MAX_COUNT) + 1 : 0] count = '0;
logic dump_flag = '0;

assign ENABLE = (count < MAX_COUNT) && inter_flag_valid;

always_ff @(posedge clk)
begin
    if (RESET)
    begin
        count <= 0;
    end
    else if (inter_flag_valid)
    begin
        if (DC)
        begin
            dump_flag <= '0;
            if (count < MAX_COUNT && VALIDI)
            begin
                count <= count + 1;
            end
            else
            begin
                count <= count;
            end
        end
        else if (VALIDI)
        begin
            count <= count;
            if (count < MAX_COUNT)
            begin
                if (!dump_flag)
                begin
                    dump_flag <= '1;
                end
                else if (dump_flag)
                begin
                    dump_flag <= dump_flag;
                end
            end
            else
            begin
                dump_flag <= '0;
            end
        end
        else
        begin
            if (dump_flag)
            begin
                dump_flag <= '0;
                count <= count + 1;
            end
            else
            begin
                dump_flag <= dump_flag;
                count <= count;
            end
        end
    end
end

always_comb 
begin
    if (ENABLE)
    begin
        VALIDO = VALIDI;
        DATAO = DATAI;
    end
    else
    begin
        VALIDO = '0;
        DATAO = '0;
    end
end
endmodule