// main testbench module
// Author: Sarah Beth Blazic
// Date: 11/26/2022
// Purpose: To test the FSM states with the btn inputs.

`timescale 1ns / 1ps

module main_tb();

    reg CLK_I; //input clk
    reg [3:0] btn; //buttons on the zybo
    reg [3:0] sw; //switches on the zybo
    wire VGA_HS_O; //horizontal position
    wire VGA_VS_O; //vertical position
    wire [3:0] VGA_R; //red
    wire [3:0] VGA_B; //blue
    wire [3:0] VGA_G; //green
    wire [3:0] cur_state;

    
    //module instantiation
    main test (
    .pxl_clk(CLK_I), //input clk
    .btn(btn), //buttons on the zybo
    .sw(sw), //switches on the zybo
    .VGA_HS_O(VGA_HS_O), //horizontal position
    .VGA_VS_O(VGA_VS_O), //vertical position
    .VGA_R(VGA_R), //red
    .VGA_B(VGA_B), //blue
    .VGA_G(VGA_G) //green
    .cur_state(cur_state)
    );
    
    
    //initialize the clk (will run forever)
    always #50 CLK_I = !CLK_I; //clk period of 100ns
    
    initial //test the inputs
    begin
        //initialize everything to zero
        CLK_I = 0;
        btn = 0; 
        sw = 0; //not checking sw movement b/c it is seen w/monitor from VGA
              
        #50; //so all changes are made on the trailing edge of the clk
        
        #100; //so FSM moves from rst to x1 (takes one clk pulse)
        
        btn = 4'b0010; //moves from x1 to o1
        #100;
        btn = 4'b0100; //moves from o1 to x2
        #100;
        btn = 4'b0010; //moves from x2 to o2
        #100;
        btn = 4'b0100; //moves from o2 to x3
        #100;
        btn = 4'b0010; //moves from x3 to o3
        #100;
        btn = 4'b0100; //moves from o3 to x4
        #100;
        btn = 4'b0010; //moves from x4 to o4
        #100;
        btn = 4'b0100; //moves from o4 to x5
        #100;
        btn = 4'b0010; //moves from x5 to rst
        #100;
        
        #100; //move from rst to x1
        
        btn = 4'b0001; //moves from x1 to rst
        #100;
        btn = 4'b0000;//moves from rst to x1
        #100;   
    end
    
endmodule
