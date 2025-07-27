module fsm_fan_control(
    input wire clk,
    input wire rst,
    input wire [7:0] temp,
    //input wire valid,
    output reg fan_enable
);

    // Definición de estados
    localparam OFF = 2'b00;
    localparam WAIT = 2'b01;
    localparam ON = 2'b10;

    reg [1:0] state, next_state;

    // Lógica de transición de estado
    always @(posedge clk or posedge rst) begin
        if (rst)
            state <= OFF;
        else
            state <= next_state;
    end

    // Lógica de próximo estado
    always @(*) begin
        case (state)
            OFF: begin
                if (temp > 8'd25)
                    next_state = ON;
                else if ( temp >= 8'd23)
                    next_state = WAIT;
                else
                    next_state = OFF;
            end
            WAIT: begin
                if ( temp > 8'd25)
                    next_state = ON;
                else if (temp < 8'd23)
                    next_state = OFF;
                else
                    next_state = WAIT;
            end
            ON: begin
                if (temp < 8'd23)
                    next_state = OFF;
                else if(temp <= 8'd25)

                    next_state = WAIT;
                else
                    next_state = ON;
            end
            // Estado por defecto
            default: next_state = OFF;
        endcase
    end

    // Lógica de salida
    always @(*) begin
        case (state)
            ON:  fan_enable = 1'b1;
            OFF: fan_enable = 1'b0;
            WAIT: fan_enable = 1'b0; 
            default: fan_enable = 1'b0;
        endcase
    end
endmodule
