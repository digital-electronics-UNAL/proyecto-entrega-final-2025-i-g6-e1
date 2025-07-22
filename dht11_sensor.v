//`timescale 1ns / 1ps

module dht11_sensor (
    input wire clk,               // Reloj de 50 MHz
    input wire rst,               // Reset síncrono
    inout wire dht11_io,          // Línea de datos bidireccional
    output reg [7:0] temp1,        // Temperatura (entera)
    output reg [7:0] hum1,         // Humedad (entera)
	 output reg [7:0] temp2,        // Temperatura (entera)
    output reg [7:0] hum2,         // Humedad (entera)
    output reg valid,             // Señal de datos válidos
    output reg [2:0] state_debug,  // Estado FSM para debug
	output reg [2:0] state
);

    // Estados FSM
    localparam IDLE      = 3'd0;
    localparam START     = 3'd1;
    localparam WAIT_RESP = 3'd2;
    localparam READ_BIT  = 3'd3;
    localparam DONE      = 3'd4;
	
	 initial begin
		state = IDLE;
	 end
    reg [31:0] timer = 0;

    reg [5:0] bit_count = 0;
    reg [39:0] shift_reg = 0;
    
    // Control de línea bidireccional
    reg io_dir = 0;      // 1 = salida, 0 = entrada
    reg io_out = 1;
    assign dht11_io = io_dir ? io_out : 1'bz;
    wire io_in = dht11_io;

    reg [1:0] in_sync;  // Sincronizador doble flanco

    always @(posedge clk) begin
        in_sync <= {in_sync[0], io_in};
    end

    wire io_fall = (in_sync[1] == 1 && in_sync[0] == 0);
    wire io_rise = (in_sync[1] == 0 && in_sync[0] == 1);

    always @(posedge clk) begin
        if (!rst) begin
            state <= IDLE;
            timer <= 0;
            bit_count <= 0;
            shift_reg <= 0;
            temp1 <= 0;
            hum1 <= 0;
            valid <= 0;
            io_dir <= 1;
            io_out <= 1;
        end else begin
            case (state)
                IDLE: begin
                    valid <= 0;
                    io_dir <= 1;
                    io_out <= 1;
                    timer <= timer + 1;
                    if (timer > 30_000_000) begin 
                        timer <= 0;
                        state <= START;
                    end
                end

                START: begin
                    io_out <= 0;
                    timer <= timer + 1;
                    if (timer == 900_000) begin  // ~18ms LOW
                        io_out <= 1;
                    end else if (timer == 905_000) begin // ~20us HIGH
                        io_dir <= 0;  // liberar línea
                        timer <= 0;
                        state <= WAIT_RESP;
                    end
                end

                WAIT_RESP: begin
                    timer <= timer + 1;
                    if (io_fall) begin
                        timer <= 0;
                        state <= READ_BIT;
                    end else if (timer > 200_000) begin
                        state <= IDLE; // timeout
                        timer <= 0;
                    end
                end

                READ_BIT: begin
                    timer <= timer + 1;
                    if (io_rise) begin
                        timer <= 0;
                    end else if (io_fall) begin
                        if (timer > 3000 && timer <5000) 
                            shift_reg <= {shift_reg[38:0], 1'b1};
                        else
                            shift_reg <= {shift_reg[38:0], 1'b0};

                        bit_count <= bit_count + 1;
                        if (bit_count == 39) begin
                            state <= DONE;
                        end
                    end
                end

                DONE: begin
                    hum1 <= shift_reg[38:31];
                    temp1 <= shift_reg[24:15];
					hum2 <= shift_reg[30:23];
                    temp2 <= shift_reg[14:7];
                    valid <= 1;
                    timer <= 0;
                    bit_count <= 0;
                    shift_reg <= 0;
                    io_dir <= 1;
                    io_out <= 1;
                    state <= IDLE;
                end
            endcase
        end
        state_debug <= state;
    end
endmodule
