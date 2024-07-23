`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: ³ÂÐÇÓî 22302010019
// 
// Create Date: 2024/01/04 17:20:06
// Design Name: 
// Module Name: CPU_sim
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Simulation;
    reg  CLOCK;
    wire clk = sim.clk;

    CPU_Design sim(CLOCK);
    
    always begin
        #0.1 CLOCK = ~CLOCK;
    end

    initial begin
        CLOCK = 0;
        #500;
        $finish;
    end
endmodule

