//`timescale 1ns / 1ps
//`include "dht11_sensor.v"
//`include "lcd1602_controller.v"
module thermogrow_top (
    input wire clk,              // Reloj de 50 MHz
    input wire rst_n,            // Reset activo en bajo
    input wire ready_i,          // Señal de inicio de la operación
    inout wire dht11_io,         // Línea bidireccional para sensor DHT11
    output wire lcd_rs,          // RS de LCD
    output wire lcd_rw,          // RW de LCD (suele ir a GND)
    output wire lcd_e,           // Enable de LCD
    output wire [7:0] lcd_data,  // Bus de datos a LCD
	output wire [2:0] state,      // Estado de la FSM del sensor DHT11 para debug 
    output wire fan_enable        // Señal de activación del ventilador
);

    // Señales internas del sensor DHT11
    wire [7:0] temperature_int;      // Parte entera de la temperatura
    wire [7:0] humidity_int;         // Parte entera de la humedad
    wire [7:0] temperature_dec;      // Parte decimal de la temperatura
    wire [7:0] humidity_dec;         // Parte decimal de la humedad
    wire        valid_data;          // Señal de dato válido
    wire [2:0]  fsm_state_debug;     // Estado interno de la FSM del sensor

    // Instancia del sensor DHT11
    dht11_sensor dht11_inst (
        .clk(clk),
        .rst(rst_n),        
        .dht11_io(dht11_io),
        .temp1(temperature_int),
        .hum1(humidity_int),
		.temp2(temperature_dec),
        .hum2(humidity_dec),
        .valid(valid_data),
        .state_debug(fsm_state_debug)
    );

    // Instancia del controlador LCD
    LCD1602_controller lcd_ctrl (
        .clk(clk),
        .reset(rst_n),     
        .temperatura_int(temperature_int), 
        .temperatura_frac(temperature_dec),
        .humedad(humidity_int),
        .humedad_frac(humidity_dec), 
        .ready_i(ready_i),
        .rs(lcd_rs),
        .rw(lcd_rw),
        .enable(lcd_e),
        .data(lcd_data)
    );
    // Instancia del controlador de ventilador
    fsm_fan_control fan_ctrl(
        .clk(clk),
        .rst(~rst_n),
        .temp(temperature_int),
        .valid(valid_data),
        .fan_enable(fan_enable)
    );

    assign state = fsm_state_debug; // Asignación del estado de la FSM del sensor DHT11 para debug

endmodule
