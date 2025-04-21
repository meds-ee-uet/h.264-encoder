module controller_mc_lc (
    input logic clk,
    input logic reset,

    // Inputs from datapath
    input logic src_ready,
    output logic src_valid,
    input logic dst_ready,
    output logic dst_valid
);

    // State machine states
    typedef enum logic [1:0] {
        IDLE,
        PROCESSING,
        DONE
    } state_t;

    state_t state, next_state;

    // State transition logic
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    // Next state logic
    always_comb begin
        case (state)
            IDLE: begin
                if (src_ready && src_valid) begin
                    next_state = PROCESSING;
                end else begin
                    next_state = IDLE;
                end
            end
            PROCESSING: begin
                if (dst_ready) begin
                    next_state = DONE;
                end else begin
                    next_state = PROCESSING;
                end
            end
            DONE: begin
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end

    // Output logic
    always_comb begin
        case (state)
            IDLE: begin
                src_valid = 1'b0;
                dst_valid = 1'b0;
            end
            PROCESSING: begin
                src_valid = 1'b1;
                dst_valid = 1'b0;
            end
            DONE: begin
                src_valid = 1'b0;
                dst_valid = 1'b1;
            end
            default: begin
                src_valid = 1'b0;
                dst_valid = 1'b0;
            end
        endcase
    end

endmodule
