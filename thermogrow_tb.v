`timescale 1ns / 1ps
`include "dht11_sensor.v"
`include "lcd1602_controller.v"
`include "fsm_fan_control.v"
`include "thermogrow_top.v"

module thermogrow_top_tb;

    reg clk;
    reg rst_n;
    reg ready_i;

    wire dht11_io;
    wire lcd_rs;
    wire lcd_rw;
    wire lcd_e;
    wire [7:0] lcd_data;
    wire [2:0] state;
    wire fan_enable;

    // DUT
    thermogrow_top dut (
        .clk(clk),
        .rst_n(rst_n),
        .ready_i(ready_i),
        .dht11_io(dht11_io),
        .lcd_rs(lcd_rs),
        .lcd_rw(lcd_rw),
        .lcd_e(lcd_e),
        .lcd_data(lcd_data),
        .state(state),
        .fan_enable(fan_enable)
    );

    // Clock 50 MHz
    initial clk = 0;
    always #10 clk = ~clk;

    initial begin
        // Reset
        rst_n = 0;
        ready_i = 0;
        #100;
        rst_n = 1;
        #200;
        ready_i = 1;

        // Esperar estabilización y luego inyectar datos manualmente
        #10_000;

        // CASO 1: 14.5 °C, 60.7 %
        force dut.dht11_inst.temp1 = 8'd14;
        force dut.dht11_inst.temp2 = 8'd50;
        force dut.dht11_inst.hum1 = 8'd60;
        force dut.dht11_inst.hum2 = 8'd70;
        force dut.dht11_inst.valid = 1;
        #5_000_000;

        // CASO 2: 23.4 °C, 58.0 %
        force dut.dht11_inst.temp1 = 8'd23;
        force dut.dht11_inst.temp2 = 8'd40;
        force dut.dht11_inst.hum1 = 8'd58;
        force dut.dht11_inst.hum2 = 8'd00;
        force dut.dht11_inst.valid = 1;
        #5_000_000;

        // CASO 3: 17.2 °C, 65.2 %
        force dut.dht11_inst.temp1 = 8'd17;
        force dut.dht11_inst.temp2 = 8'd20;
        force dut.dht11_inst.hum1 = 8'd65;
        force dut.dht11_inst.hum2 = 8'd20;
        force dut.dht11_inst.valid = 1;
        #5_000_000;

        $finish;
    end

    // Dump para GTKWave
    initial begin
        $dumpfile("thermogrow_top_tb.vcd");
        $dumpvars(0, thermogrow_top_tb);
    end

endmodule