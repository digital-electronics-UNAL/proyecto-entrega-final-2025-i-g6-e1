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
    output wire [7:0] lcd_data,   // Bus de datos a LCD
	output [2:0] state
    
);

    // Señales internas
    wire [7:0] temperature1;
    wire [7:0] humidity1;
	 wire [7:0] temperature2;
    wire [7:0] humidity2;
    wire valid;
    wire [2:0] state_debug;

    // Instancia del sensor DHT11
    dht11_sensor dht11_inst (
        .clk(clk),
        .rst(rst_n),         // reset activo en bajo
        .dht11_io(dht11_io),
        .temp1(temperature1),
        .hum1(humidity1),
		  .temp2(temperature2),
        .hum2(humidity2),
        .valid(valid),
        .state_debug(state_debug),
		.state(state)
    );

    // Instancia del controlador LCD
    LCD1602_controller lcd_ctrl (
        .clk(clk),
        .reset(rst_n),     // reset activo en bajo
        .temperatura(temperature1), 
        .temperatura2(temperature2),
        .humedad(humidity1), // se muestra solo la temperatura
        .ready_i(ready_i),
        .rs(lcd_rs),
        .rw(lcd_rw),
        .enable(lcd_e),
        .data(lcd_data)
    );

endmodule
