module LCD1602_controller #(parameter NUM_COMMANDS = 4, 
                                      NUM_DATA_ALL = 32,  
                                      NUM_DATA_PERLINE = 16,
                                      DATA_BITS = 8,
                                      COUNT_MAX = 800000)(
    input clk,            
    input reset,          // reset activo en bajo
    input ready_i,
    input [7:0] temperatura,
    input [7:0] temperatura2,
    input [7:0] humedad,  // Nueva entrada para humedad
    output reg rs,        
    output reg rw,
    output enable,    
    output reg [DATA_BITS-1:0] data
);

// Definir los estados de la FSM
localparam IDLE = 5'b00000;
localparam CONFIG_CMD1 = 5'b00001;
localparam WR_STATIC_TEXT_1L = 5'b00010;
localparam CONFIG_CMD2 = 5'b00011;
localparam WR_STATIC_TEXT_2L = 5'b00100;
localparam SET_CURSOR_TEMP = 5'b00101;  // Nuevo estado para temperatura
localparam WR_TEMP_CENT = 5'b00110;
localparam WR_TEMP_DEC = 5'b00111;
localparam WR_TEMP_UNI = 5'b01000;
localparam WR_TEMP_P = 5'b01001;
localparam WR_TEMP_DEC_CENT = 5'b01010;
localparam WR_TEMP_DEC_DEC = 5'b01011;
localparam WR_TEMP_DEC_UNI = 5'b01100;
localparam SET_CURSOR_HUM = 5'b01101;    // Nuevo estado para humedad
localparam WR_HUM_CENT = 5'b01110;
localparam WR_HUM_DEC = 5'b01111;
localparam WR_HUM_UNI = 5'b10000;
localparam WR_HUM_P = 5'b10001; // Nuevo estado para humedad



reg [4:0] fsm_state;      // Ampliado a 4 bits
reg [4:0] next_state;

reg [2:0] flag;         
reg clk_16ms;

// Comandos de configuración
localparam CLEAR_DISPLAY = 8'h01;
localparam SHIFT_CURSOR_RIGHT = 8'h06;
localparam DISPON_CURSOROFF = 8'h0C;
localparam DISPON_CURSORBLINK = 8'h0E;
localparam LINES2_MATRIX5x8_MODE8bit = 8'h38;
localparam START_2LINE = 8'hC0;

// Definir un contador para el divisor de frecuencia
reg [$clog2(COUNT_MAX)-1:0] clk_counter;
// Definir un contador para controlar el envío de comandos
reg [$clog2(NUM_COMMANDS):0] command_counter;
// Definir un contador para controlar el envío de datos
reg [$clog2(NUM_DATA_PERLINE):0] data_counter;

// Banco de registros
reg [DATA_BITS-1:0] static_data_mem [0: NUM_DATA_ALL-1];
reg [DATA_BITS-1:0] config_mem [0:NUM_COMMANDS-1]; 

// Registros para los dígitos
reg [7:0] temp_cent, temp_dec, temp_uni, temp_cent2, temp_dec2, temp_uni2;
reg [7:0] hum_cent, hum_dec, hum_uni;

initial begin
    fsm_state <= IDLE;
    command_counter <= 'b0;
    data_counter <= 'b0;
    rs <= 1'b0;
    rw <= 1'b0;
    data <= 8'b0;
    clk_16ms <= 1'b0;
    clk_counter <= 'b0;
    $readmemh("/home/rustam/proyecto thermogrow/data.txt", static_data_mem);    
	config_mem[0] <= LINES2_MATRIX5x8_MODE8bit;
	config_mem[1] <= SHIFT_CURSOR_RIGHT;
	config_mem[2] <= DISPON_CURSOROFF;
	config_mem[3] <= CLEAR_DISPLAY;
	
	// Inicializar dígitos
	temp_cent <= 8'd0;
	temp_dec <= 8'd0;
	temp_uni <= 8'd0;
    temp_cent2 <= 8'd0;
	temp_dec2 <= 8'd0;
	temp_uni2 <= 8'd0;
	hum_cent <= 8'd0;
	hum_dec <= 8'd0;
	hum_uni <= 8'd0;
end

// Divisor de frecuencia para generar clk_16ms
always @(posedge clk) begin
    if (clk_counter == COUNT_MAX-1) begin
        clk_16ms <= ~clk_16ms;
        clk_counter <= 'b0;
    end else begin
        clk_counter <= clk_counter + 1;
    end
end

// Actualización del estado de la FSM
always @(posedge clk_16ms) begin
    if(reset==0)begin
        fsm_state <= IDLE;
    end else begin
        fsm_state <= next_state;
    end
end

// Cálculo de dígitos (sincronizado con clk_16ms)
always @(posedge clk_16ms) begin
    if (reset) begin
        // Calcular dígitos de temperatura
        temp_cent <= (temperatura - temperatura%100)/100;
        temp_dec <= (temperatura % 100 - temperatura%10) / 10;
        temp_uni <= temperatura % 10;

        temp_cent2 <= (temperatura2 - temperatura2%100)/100;
        temp_dec2 <= (temperatura2 % 100 - temperatura2%10) / 10;
        temp_uni2 <= temperatura2 % 10;
        
        // Calcular dígitos de humedad
        hum_cent <= (humedad - humedad%100)/100;
        hum_dec <= (humedad % 100 - humedad% 10) / 10;
        hum_uni <= humedad % 10;
    end
end

// Lógica de transición de estados
always @(*) begin
    case(fsm_state)
        IDLE: begin
            next_state = (ready_i)? CONFIG_CMD1 : IDLE;
        end
        CONFIG_CMD1: begin 
            next_state = (command_counter == NUM_COMMANDS)? WR_STATIC_TEXT_1L : CONFIG_CMD1;
        end
        WR_STATIC_TEXT_1L:begin
			next_state = (data_counter == NUM_DATA_PERLINE)? CONFIG_CMD2 : WR_STATIC_TEXT_1L;
        end
        CONFIG_CMD2: begin 
            next_state = WR_STATIC_TEXT_2L;
        end
		WR_STATIC_TEXT_2L: begin
			next_state = (data_counter == NUM_DATA_PERLINE)? SET_CURSOR_TEMP : WR_STATIC_TEXT_2L;
		end
        SET_CURSOR_TEMP: begin
            next_state = WR_TEMP_CENT;
        end
        WR_TEMP_CENT: begin
            next_state = WR_TEMP_DEC;
        end
        WR_TEMP_DEC: begin
            next_state = WR_TEMP_UNI;
        end
        WR_TEMP_UNI: begin
            next_state = WR_TEMP_P;
        end
		  WR_TEMP_P: begin
            next_state = WR_TEMP_DEC_CENT;
        end
        WR_TEMP_DEC_CENT: begin
            next_state = WR_TEMP_DEC_DEC;
        end
        WR_TEMP_DEC_DEC: begin
            next_state = WR_TEMP_DEC_UNI;
        end
        WR_TEMP_DEC_UNI: begin
            next_state = SET_CURSOR_HUM;
        end
        SET_CURSOR_HUM: begin
            next_state = WR_HUM_CENT;
        end
        WR_HUM_CENT: begin
            next_state = WR_HUM_DEC;
        end
        WR_HUM_DEC: begin
            next_state = WR_HUM_UNI;
        end
        WR_HUM_UNI: begin
            next_state = WR_HUM_P; // Volver a empezar
        end
		  WR_HUM_P: begin
				next_state = SET_CURSOR_TEMP; 
			end
        default: next_state = IDLE;
    endcase
end

// Lógica de salida
always @(posedge clk_16ms) begin
    if (reset==0) begin
        flag <= 1'b0;
        command_counter <= 'b0;
        data_counter <= 'b0;
        data <= 'b0;
        rw <= 1'b0;
        $readmemh("/home/rustam/proyecto thermogrow/data.txt", static_data_mem);
    end else begin
        rw <= 1'b0; // Siempre en modo escritura
        case (next_state)
            IDLE: begin
                flag <= 1'b0;
                command_counter <= 'b0;
                data_counter <= 'b0;
                rs <= 1'b0;
                data  <= 'b0;
            end
            CONFIG_CMD1: begin
			    rs <= 1'b0; 	
                command_counter <= command_counter + 1;
				data <= config_mem[command_counter];
            end
            WR_STATIC_TEXT_1L: begin
                data_counter <= data_counter + 1;
                rs <= 1'b1; 
				data <= static_data_mem[data_counter];
            end
            CONFIG_CMD2: begin
                data_counter <= 'b0;
				rs <= 1'b0; 
				data <= START_2LINE; // Comando para mover el cursor a la segunda línea
            end
			WR_STATIC_TEXT_2L: begin
                data_counter <= data_counter + 1;
                rs <= 1'b1; 
				data <= static_data_mem[NUM_DATA_PERLINE + data_counter];
            end
            SET_CURSOR_TEMP: begin
                rs <= 1'b0; // Modo comando
                // Mover cursor a la posición de temperatura: línea 1, columna 6
                data <= 8'h80 + 6; // 0x80 para línea 1, +6 para columna 6
            end
            WR_TEMP_CENT: begin
                rs <= 1'b1; // Modo datos
                // Mostrar centena de temperatura (suprimir cero)
                data <= (temp_cent == 0) ? 8'h20 : temp_cent + 8'd48;
            end
            WR_TEMP_DEC: begin
                rs <= 1'b1;
                data <= temp_dec + 8'd48; // ASCII para dígito
            end
            WR_TEMP_UNI: begin
                rs <= 1'b1;
                data <= temp_uni + 8'd48;
            end
				WR_TEMP_P: begin
					rs <= 1'b1;
					data <= 8'h2E;
				end
                WR_TEMP_DEC_CENT: begin
                rs <= 1'b1; // Modo datos
                // Mostrar centena de temperatura (suprimir cero)
                data <= temp_cent2 + 8'd48;
            end
            WR_TEMP_DEC_DEC: begin
                rs <= 1'b1;
                data <= temp_dec2 + 8'd48; // ASCII para dígito
            end
            WR_TEMP_DEC_UNI: begin
                rs <= 1'b1;
                data <= temp_uni2 + 8'd48;
            end
            SET_CURSOR_HUM: begin
                rs <= 1'b0;
                // Mover cursor a la posición de humedad: línea 2, columna 9
                data <= 8'hC0 + 9; // 0xC0 para línea 2, +9 para columna 9
            end
            WR_HUM_CENT: begin
                rs <= 1'b1;
                data <= (hum_cent == 0) ? 8'h20 : hum_cent + 8'd48;
            end
            WR_HUM_DEC: begin
                rs <= 1'b1;
                data <= hum_dec + 8'd48;
            end
            WR_HUM_UNI: begin
                rs <= 1'b1;
                data <= hum_uni + 8'd48;
            end
				 WR_HUM_P: begin
                rs <= 1'b1;
                data <= 8'h2E;
            end
        endcase
        end 
    end

    assign enable = clk_16ms;
endmodule