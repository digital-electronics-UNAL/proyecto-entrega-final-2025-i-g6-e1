`timescale 1ns / 1ps
`include "dht11_sensor.v"
module tb_dht11_sensor();

    reg clk;
    reg rst;
    wire dht11_io;
    wire [7:0] temp1;
    wire [7:0] hum1;
    wire [7:0] temp2;
    wire [7:0] hum2;
    wire valid;
    wire [2:0] state_debug;
    wire [2:0] state;

    // Instancia del módulo bajo prueba
    dht11_sensor uut (
        .clk(clk),
        .rst(rst),
        .dht11_io(dht11_io),
        .temp1(temp1),
        .hum1(hum1),
        .temp2(temp2),
        .hum2(hum2),
        .valid(valid),
        .state_debug(state_debug),
        .state(state)
    );

    // Simulación de la línea bidireccional
    reg dht11_drive;  // 1 = testbench controla la línea
    reg dht11_value;  // valor que el testbench impulsa
    assign dht11_io = dht11_drive ? dht11_value : 1'bz;

    // Generador de reloj (50 MHz)
    always #10 clk = ~clk;  // 20 ns período = 50 MHz

    // Tarea para simular la respuesta del sensor (CORREGIDA)
    task dht11_send_response;
        input [39:0] data;  // {hum_ent, hum_dec, temp_ent, temp_dec, checksum}
        begin
            // Esperar a que el DUT solicite datos (nuevo método)
            wait(uut.state == 3'd2);  // WAIT_RESP es 3'd2
            
            // Respuesta del sensor (80us bajo + 80us alto)
            dht11_drive = 1;
            dht11_value = 0;
            #80000;  // 80us
            
            dht11_value = 1;
            #80000;  // 80us
            
            // Enviar 40 bits de datos (CORREGIDO: bit más significativo primero)
            for (integer i = 39; i >= 0; i = i - 1) begin
                // Inicio de bit (50us bajo)
                dht11_value = 0;
                #50000;
                
                // Parte alta con duración variable
                dht11_value = 1;
                if (data[i]) 
                    #70000;  // 70us para 1
                else 
                    #26000;  // 26us para 0
            end
            
            // Liberar la línea
            dht11_drive = 0;
            #1000000;  // 1ms extra
        end
    endtask

    // Secuencia de prueba CORREGIDA
    initial begin
        // Archivo VCD para GTKWave
        $dumpfile("dht11_sim.vcd");
        $dumpvars(0, tb_dht11_sensor);
        $dumpvars(0, uut);  // Agregar todas las señales internas del DUT
        
        // Inicialización
        clk = 0;
        rst = 0;  // Reset activado (activo en bajo)
        dht11_drive = 0;
        dht11_value = 1;
        
        // Reset prolongado
        #1000000;  // 1ms
        rst = 1;    // Desactivar reset
        
        // Esperar inicio de primera lectura (30ms en DUT)
        #30000000;  // 30ms
        
        // Datos de ejemplo válidos (hum=50.0%, temp=25.0°C)
        dht11_send_response(40'h32_00_19_00_4B);  // Checksum: 50+0+25+0=75 (0x4B)
        
        // Esperar para segunda lectura
        #30000000;  // 30ms
        
        // Segundo conjunto válido (hum=75.5%, temp=22.3°C)
        dht11_send_response(40'h4B_05_16_03_69);  // 75+5+22+3=105 (0x69)
        
        // Esperar para tercera lectura
        #30000000;  // 30ms
        
        // Datos inválidos
        dht11_send_response(40'hFF_FF_FF_FF_FF);
        
        // Finalizar simulación
        #100000000;
        $finish;
    end

endmodule