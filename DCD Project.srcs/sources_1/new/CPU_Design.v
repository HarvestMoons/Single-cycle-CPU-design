`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: ³ÂÐÇÓî 22302010019
// 
// Create Date: 2023/12/21 15:34:02
// Design Name: CPU_Design
// Module Name: CPU_Design
// Project Name: CPU_Design
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


module CPU_Design(clock);
input clock;

    wire clk;
    wire [31:0] newPC, command;
    wire [31:0] PC;
    wire [25:0] Jtarget;
    wire [15:0] immediate, offset,  Qs, Qt, memoryValue, result;
    wire [5:0] commandType,func;
    wire [4:0] rs, rd, rt;
    wire [1:0] outputFlag;   
    CLK myclock(clock, clk); 
    CommandDevider myCommandDevider(command, commandType, Jtarget, immediate, offset, rs, rt, rd,func);
    Commands myCommands(PC, command);   
    CommandOperator myCommandOperator(clk, PC, commandType, Jtarget, immediate, Qs, Qt, memoryValue, newPC, outputFlag, result,func);
    Memory myMemory(clk, outputFlag, result, rs, rt, rd, offset, Qs, Qt, memoryValue);
    setPC mySetPC(clk, newPC, PC);
endmodule


module setPC(clk, newPC, PC);
    input clk;
    input [31:0] newPC;
    output reg [31:0] PC = -1;
    
    always @(posedge clk) begin
        if(newPC < 127) PC = newPC;
    end
endmodule



module CLK(clock, clk);
    input clock;
    integer count = 0;
    output reg clk = 0;
    always @(posedge clock) begin
        count = count + 1;
        if (count >= 50) begin
            clk = ~clk;
            count = 0;
        end
    end
endmodule



module CommandDevider(command, commandType, Jtarget, immediate, offset, rs, rt, rd,func);
    input [31:0] command;
    output [5:0] commandType,func;
    output [25:0] Jtarget;
    output [15:0] immediate, offset;
    output [4:0] rs, rd, rt;
    assign func=command[5:0];
    assign commandType = command[31:26];
    assign rs = command[25:21];
    assign rt = command[20:16];
    assign rd = command[15:11];
    assign Jtarget = command[25:0];
    assign immediate = command[15:0];
    assign offset = command[15:0];
endmodule


module Commands(PC, command);
    input [31:0] PC;
    output [31:0] command;
    reg [31:0] PCfile [0:127];
    initial begin: mult3
    integer i;
    PCfile[0] =32'b00100000001000010000000000000101;//reg1+5 6
    PCfile[1] =32'b00100000001000010000000000000001;//reg1+1 7
    PCfile[2] =32'b00000000001000110000100000100010;//reg1-reg3->reg1 4
    PCfile[3] =32'b00000000001000100000100000100101;//reg1|reg2->reg1 6    
    PCfile[4] =32'b00000000001000000000100000100100;//reg1&reg0->reg1 0
    PCfile[5] =32'b00110100001000010000000000010000;//reg1|000...10000->reg1 16
    PCfile[6] =32'b00100000001000010000000000000001;//reg1+1 17
    PCfile[7] =32'b00110000001000010000000000011111;//reg1&000...11111->reg1 17
    PCfile[8] =32'b00000000001000110000100000101010;//reg1<reg3(3) (no) ->reg1=0 0
    PCfile[9] =32'b00000000000000000000000000000000;//nop 0
    PCfile[10] =32'b00001000000000000000000000001100;//J->PCfile[12] 
    PCfile[11] =32'b00100000001000010000000000000011;//reg1+3(jump) 0
    PCfile[12] =32'b00101000001000010000000001111111;//reg1<0...1111111 (yes) ->reg1=1 1
    PCfile[13] =32'b10101100011000010000000000000001;//mem[reg3+1]=mem[4]=reg1 1
    PCfile[14] =32'b10001100011000010000000000000111;//reg1=mem[reg3+7]=mem[10]=15 15
        for (i = 15; i < 128; i = i + 1) begin
           PCfile[i] = 32'b00100000001000010000000000000101;
        end
    end
    
    assign command = PCfile[PC];
    
endmodule



module Memory(clk, outputFlag, result, rs, rt, rd, offset, Qs, Qt, memoryValue);
    input clk;
    input [1:0] outputFlag;
    input [15:0] result;
    input [4:0] rs, rd, rt;
    input [15:0] offset;
    reg [15:0] regfile [0:31];
    reg [15:0] memory [0:127];
    output [15:0] Qs, Qt, memoryValue;
        
    initial begin: mult1 
        integer i;
        regfile[0] = 0;
        for (i = 1; i < 32; i = i + 1) begin
            regfile[i] = i;
        end
    end
    
    initial begin: mult2
        integer i;
        for (i = 0; i < 128; i = i + 1) begin
            memory[i] = 4'h000F;
        end
    end  
    assign Qs = regfile[rs];
    assign Qt = regfile[rt];
    assign memoryValue = memory[regfile[rs] + offset];   
    always @(posedge clk) begin
        case(outputFlag)
            2'b00:begin
            end
            2'b01:begin
                if(rd != 0) regfile[rd] = result;
            end
            2'b10:begin
                if(rt != 0) regfile[rt] = result;
            end
            2'b11:begin
                memory[regfile[rs] + offset] = result;
            end
        endcase
    end
endmodule



module CommandOperator(clk, PC, commandType, Jtarget, immediate, Qs, Qt, memoryValue, newPC, outputFlag, result,func);
    input clk;
    input [31:0] PC;
    input [15:0] Qs, Qt, memoryValue;
    input [5:0] commandType,func;
    input [25:0] Jtarget;
    input [15:0] immediate;
    wire signed[14:0] QsValue, QtValue, imValue;
    output reg [31:0] newPC;
    output reg [1:0] outputFlag;
    output reg [15:0] result = 0;
    
    assign QsValue = Qs;
    assign QtValue = Qt;
    assign imValue = immediate;
    
    always @(negedge clk) begin
        newPC = PC + 1;
        case(commandType)
            6'b000000:begin 
             case(func)
                6'b100000:begin
                   result = Qs + Qt;
                   if(Qs[15] == Qt[15] && Qs[15] != result[15]) begin
                     outputFlag = 2'b00;
                   end 
                   else 
                   outputFlag = 2'b01;
                   end
                6'b100100:begin
                    result = Qs & Qt;
                    outputFlag = 2'b01;
                    end
                6'b100101:begin
                    result = Qs | Qt;
                    outputFlag = 2'b01;
                    end
                6'b101010:begin
                    if(QsValue < QtValue) result = 1;
                    else 
                    result = 0;
                    outputFlag = 2'b01;
                    end
                6'b100010:begin
                    result = Qs - Qt;
                    if(Qs[15] != Qt[15] && Qs[15] != result[15]) begin
                    outputFlag = 2'b00;
                    end
                    else 
                    outputFlag = 2'b01;
                    end 
            endcase
            end
            6'b001000:begin
               result = Qs + immediate;
               if(Qs[15] == immediate[15] && Qs[15] != result[15]) begin
               outputFlag = 2'b00;
               end 
               else 
               outputFlag = 2'b10;
            end
            6'b000010:begin
                newPC = {newPC[31:28],2'b00, Jtarget };
                outputFlag = 2'b00;
            end
            6'b100011:begin
                result = memoryValue;
                outputFlag = 2'b10;
            end
            6'b001100:begin
                result = Qs & immediate;
                outputFlag = 2'b10;
            end
          
            6'b001101:begin
                result = Qs | immediate;
                outputFlag = 2'b10;
            end
            6'b001010:begin
                if(QsValue < imValue) 
                result = 1;
                else 
                result = 0;
                outputFlag = 2'b10;
            end
            6'b101011:begin
                result = Qt;
                outputFlag = 2'b11;
            end
            default:begin
                outputFlag = 2'b00;
            end
        endcase
    end
endmodule
