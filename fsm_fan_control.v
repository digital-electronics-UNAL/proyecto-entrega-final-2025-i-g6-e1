module fsm_fan_control(
    input wire clk,
    input wire rst,
    input wire [7:0] temperature,
    output reg fan_on
);

    // Definición de estados
    typedef enum logic [1:0] {
        OFF = 2'b00,
        WAIT = 2'b01,
        ON = 2'b10
    } state_t;

    state_t state, next_state;

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
            OFF:
                next_state = (temperature >= 20) ? ON : OFF;
            ON:
                next_state = (temperature <= 15) ? OFF : ON;
            default:
                next_state = OFF;
        endcase
    end

    // Lógica de salida
    always @(*) begin
        case (state)
            ON:  fan_on = 1;
            OFF: fan_on = 0;
            default: fan_on = 0;
        endcase
    end
endmodule
