`timescale 1ns / 1ps
`include "fsm_fan_control.v"
//`include "lcd_display.v"
//`include "dht11_sensor.v"
//`include "thermogrow_top.v" 
module testbench_thermogrow;

    reg clk;
    reg rst;
    reg [7:0] temperature;
    wire fan_on;

    // Instancia del DUT (Device Under Test)
    fsm_fan_control uut (
        .clk(clk),
        .rst(rst),
        .temperature(temperature),
        .fan_on(fan_on)
    );

    // Clock de 10 ns
    always #5 clk = ~clk;

    // Simulación de diferentes temperaturas
    initial begin
        $dumpfile("thermogrow_tb.vcd");
        $dumpvars(0, testbench_thermogrow);

        clk = 0;
        rst = 1;
        temperature = 8'd0;
        #20;
        rst = 0;

        simulate_temperature(8'd10); // Esperar apagado
        simulate_temperature(8'd19); // Esperar apagado
        simulate_temperature(8'd20); // Activar ventilador
        simulate_temperature(8'd18); // Mantener ventilador encendido
        simulate_temperature(8'd15); // Apagar ventilador
        simulate_temperature(8'd22); // Encender nuevamente
        simulate_temperature(8'd14); // Apagar por debajo de umbral

        #100;
        $finish;
    end

    // Tarea para simular temperatura
    task simulate_temperature;
        input [7:0] temp_celsius;
        begin
            temperature = temp_celsius;
            #200_000;  // 200 us con esa temperatura
        end
    endtask

endmodule
