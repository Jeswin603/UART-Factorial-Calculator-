module uart_rx 
#( 
    parameter DBIT = 8,     // Number of data bits 
    parameter SB_TICK = 16  // Number of ticks for stop bits
) 
( 
    input wire clk, 
    input wire reset, 
    input wire rx, 
    input wire s_tick, 
    output reg rx_done_tick, 
    output wire [7:0] dout, 
    output reg [31:0] factorial_result, 
    output reg [7:0] final_result 
); 
    integer i;
    // Symbolic state declaration 
    localparam [1:0] 
        idle  = 2'b00,
        start = 2'b01,
        data  = 2'b10,
        stop  = 2'b11;

    // Signal declarations 
    reg [1:0] state_reg, state_next; 
    reg [3:0] s_reg, s_next; 
    reg [2:0] n_reg, n_next; 
    reg [7:0] b_reg, b_next; 


    // Body 
    // FSMD state & data registers 
    always @(posedge clk or posedge reset) 
        if (reset) begin 
            state_reg <= idle; 
            s_reg <= 0; 
            n_reg <= 0; 
            b_reg <= 0; 
            final_result <= 0; // Initialize final_result
            factorial_result <=0;
        end else begin 
            state_reg <= state_next; 
            s_reg <= s_next; 
            n_reg <= n_next; 
            b_reg <= b_next; 
            if (rx_done_tick) 
            final_result <= b_reg; 
            begin
                factorial_result =1;
                for(i=1;i<=final_result;i=i+1)
                    factorial_result=factorial_result*i;
                end


        end 

    // FSMD next-state logic 
    always @* begin 
        // Default values for next state and outputs 
        state_next = state_reg; 
        rx_done_tick = 1'b0; 
        s_next = s_reg; 
        n_next = n_reg; 
        b_next = b_reg; 

        case (state_reg)
            idle: begin 
                if (~rx) begin // Detect start bit
                    state_next = start; 
                    s_next = 0; 
                end 
            end 

            start: begin 
                if (s_tick) begin 
                    if (s_reg == 7) begin // Middle of start bit
                        state_next = data; 
                        s_next = 0; 
                        n_next = 0; 
                    end else begin 
                        s_next = s_reg + 1; 
                    end 
                end 
            end 

            data: begin 
                if (s_tick) begin 
                    if (s_reg == 15) begin // Middle of a data bit
                        s_next = 0; 
                        b_next = {rx, b_reg[7:1]}; // Shift in received bit
                        if (n_reg == (DBIT - 1)) 
                            state_next = stop; 
                        else 
                            n_next = n_reg + 1; 
                    end else begin 
                        s_next = s_reg + 1; 
                    end 
                end 
            end 

            stop: begin 
                if (s_tick) begin 
                    if (s_reg == (SB_TICK - 1)) begin // End of stop bit(s)
                        state_next = idle; 
                        rx_done_tick = 1'b1; 
                    end else begin 
                        s_next = s_reg + 1; 
                    end 
                end 
            end 

            default: state_next = idle; 
        endcase 
    end 

    // Output assignment 
assign dout = b_reg;

endmodule
