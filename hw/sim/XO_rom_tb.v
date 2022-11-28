// OX_rom testbench module
// Author: Sarah Beth Blazic
// Date: 11/26/2022
// Purpose: To test the outputs from the OX_rom module. This will see if the module is giving out
// the desired bit map. 

`timescale 1ns / 1ps

module XO_rom_tb();
    
    reg isX; //different rom modes
    reg [11:0] x_reg; //position within
    reg [11:0] y_reg;
    reg [11:0] h_reg;
    reg [11:0] v_reg;
    reg pixel_in_box;
    wire ox_rom;
    
    integer i, j;

    OX_rom test (
        .isX(isX),//O rom => 0
        .x(x_reg),
        .y(y_reg),
        .h(h_reg),
        .v(v_reg),
        .box(pixel_in_box), 
        .rom(ox_rom)
    );
    

    initial
    begin
        x_reg = 0;
        y_reg = 0;
        h_reg = 0;
        v_reg = 0;
        pixel_in_box = 1; //assume the pixel is always in the box
        
        isX = 0; //test the O case
        #50 //so changes are made at the trailing edge of the clk
        for(j = 0; j < 1000; j = j + 1) //run through the  positions
        begin
            v_reg = v_reg + 1;
            for(i = 0; i < 1000; i = i + 1)
            begin
                h_reg = h_reg + 1;
                #100;
            end
        end
        
        isX = 1; //test the X case
        #50 //so changes are made at the trailing edge of the clk
        for(j = 0; j < 1000; j = j + 1) //run through the  positions
        begin
            v_reg = v_reg + 1;
            for(i = 0; i < 1000; i = i + 1)
            begin
                h_reg = h_reg + 1;
                #100;
            end
        end
    
    end


endmodule


