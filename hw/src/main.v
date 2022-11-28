// main module
// Author: Sarah Beth Blazic
// Date: 11/25/2022
// Purpose: To create a tic-tac-toe game on the Zybo Z7-10.
//This is the main driving file.

`timescale 1ns / 1ps


module main(
    input CLK_I, //input clk
    input [3:0] btn, //buttons on the zybo
    input [3:0] sw, //switches on the zybo
    output VGA_HS_O, //horizontal position
    output VGA_VS_O, //vertical position
    output [3:0] VGA_R, //red
    output [3:0] VGA_B, //blue
    output [3:0] VGA_G //green
//    input pxl_clk, //for testing
//    output reg [3:0] cur_state //purely for testing
    );
    
    wire pxl_clk; //pixel clk that is slowed down from clk wizard ip
    
    //clk wizard
    clk_wiz_0 clk_divisor(
        .clk_out1(pxl_clk), // Clock out ports
        .clk_in1(CLK_I)  // Clock in ports
    );
    
    
     
    // CONSTANTS
    //***1920x1080@60Hz***// Requires 148.5 MHz pxl_clk
    parameter FRAME_WIDTH = 1920; //visual height
    parameter FRAME_HEIGHT = 1080; //visual width of the screen
    parameter H_POL = 1'b1;
    parameter V_POL = 1'b1;
    
    parameter H_FP = 88; //H front porch width (pixels)
    parameter H_PW = 44; //H sync pulse width (pixels)
    parameter H_MAX = 2200; //H total period (pixels)
    
    parameter V_FP = 4; //V front porch width (lines)
    parameter V_PW = 5; //V sync pulse width (lines)
    parameter V_MAX = 1125; //V total period (lines)
    
    parameter ONE_SIXTY_FOUR_H = FRAME_WIDTH/64; //size of the Horizontal wall
    parameter ONE_SIXTY_V = FRAME_HEIGHT/60; //size of the Vertical wall
    
    //Moving Box constants
    parameter BOX_WIDTH = (20*8); //size
    parameter BOX_CLK_DIV = 1000000; //MAX=(2^25 - 1)
    
    parameter BOX_X_MAX = (FRAME_WIDTH - BOX_WIDTH);
    parameter BOX_Y_MAX = (FRAME_HEIGHT - BOX_WIDTH);
    
    parameter BOX_X_MIN = 0;
    parameter BOX_Y_MIN = 0;
    
    parameter [11:0] BOX_X_INIT = 12'b0;
    parameter [11:0] BOX_Y_INIT = 12'b0; 
    
    
    
    //WIRES/REGS
    reg [11:0] h_cntr_reg = 12'b0; // changing values horizontally
    reg [11:0] v_cntr_reg = 12'b0; // changing values vertically
    reg h_sync_reg = ~(H_POL);
    reg v_sync_reg = ~(V_POL);
    reg h_sync_dly_reg = ~(H_POL);
    reg v_sync_dly_reg = ~(V_POL); 
    reg [3:0] vga_red_reg = 4'b0, vga_green_reg = 4'b0, vga_blue_reg = 4'b0;
    reg [3:0] vga_red, vga_green, vga_blue; //to run combinational vga with clk
     
    reg [11:0] box_x_reg = BOX_X_INIT;
    
    //save position after turn ends
    reg [11:0] x1_x_reg;
    reg [11:0] x2_x_reg;
    reg [11:0] x3_x_reg;
    reg [11:0] x4_x_reg;
    reg [11:0] x5_x_reg;
    
    reg [11:0] o1_x_reg;
    reg [11:0] o2_x_reg;
    reg [11:0] o3_x_reg;
    reg [11:0] o4_x_reg;
    
    reg [11:0] x1_y_reg;
    reg [11:0] x2_y_reg;
    reg [11:0] x3_y_reg;
    reg [11:0] x4_y_reg;
    reg [11:0] x5_y_reg;
    
    reg [11:0] o1_y_reg;
    reg [11:0] o2_y_reg;
    reg [11:0] o3_y_reg;
    reg [11:0] o4_y_reg;
    
    reg box_x_dir = 1'b1;
    
    reg [11:0] box_y_reg = BOX_Y_INIT;
    reg box_y_dir = 1'b1;
    
    reg [24: 0] box_cntr_reg = 24'b0;
    
    wire update_box; //slow clk that updates the pixels
    
    //checks if pixel written is in the reg for O
    wire pixel_in_O1; 
    wire pixel_in_O2;
    wire pixel_in_O3;
    wire pixel_in_O4;
    
    
    //checks if pixel written is in the reg for X
    wire pixel_in_X1;
    wire pixel_in_X2;
    wire pixel_in_X3;
    wire pixel_in_X4;
    wire pixel_in_X5;
     
     //returns the bitmap constant for O
    wire o1_rom; 
    wire o2_rom; 
    wire o3_rom; 
    wire o4_rom;
    
    //returns the bitmap constant for X 
    wire x1_rom;
    wire x2_rom;
    wire x3_rom;
    wire x4_rom;
    wire x5_rom;
    
    //FSM turn logic
    localparam //10 states (rst, x 5 turns, o 4 turns)
        rst = 4'b0000,
        x1  = 4'b0001, //first turn
        o1  = 4'b0010,
        x2  = 4'b0011, //second turn
        o2  = 4'b0100,
        x3  = 4'b0101, //third turn
        o3  = 4'b0110,
        x4  = 4'b0111, //fourth turn
        o4  = 4'b1000,
        x5  = 4'b1001; //last possible turn
        
    reg [3:0] next_state; //holds next state
    reg [3:0] cur_state; //holds current state
    
    //FSM state changing logic
    always @(posedge pxl_clk)
    begin
        if(btn[0] == 1'b1) // go to state zero if reset button is pressed
            cur_state <= rst;
        else // otherwise update the states
            cur_state <= next_state;
    end
    
    //FSM transition logic
    always @(posedge pxl_clk) begin
        if (cur_state == rst) //rst state
            next_state <= x1; //next clk pulse starts the game over
        else if (cur_state == x1) begin //x first turn
            if (btn[1] == 1'b1) //when the 2nd button is pressed
                next_state <= o1; //switch to next player
            else
                next_state <= x1; //still x's first turn
        end
        else if (cur_state == o1) begin//o first turn
            if (btn[2] == 1'b1) //when the 3rd button is pressed
                next_state <= x2; //switch to next player
            else
                next_state <= o1; //still o's first turn
        end
        else if (cur_state == x2) begin//x second turn
            if (btn[1] == 1'b1) //when the 2nd button is pressed
                next_state <= o2; //switch to next player
            else
                next_state <= x2; //still x's second turn
        end
        else if (cur_state == o2) begin//o second turn
            if (btn[2] == 1'b1) //when the 3rd button is pressed
                next_state <= x3; //switch to next player
            else
                next_state <= o2; //still o's second turn
        end
        else if (cur_state == x3) begin//x third turn
            if (btn[1] == 1'b1) //when the 2nd button is pressed
                next_state <= o3; //switch to next player
            else
                next_state <= x3; //still x's third turn
        end
        else if (cur_state == o3) begin//o third turn
            if (btn[2] == 1'b1) //when the 3rd button is pressed
                next_state <= x4; //switch to next player
            else
                next_state <= o3; //still o's third turn
        end
        else if (cur_state == x4) begin //x fourth turn
            if (btn[1] == 1'b1) //when the 2nd button is pressed
                next_state <= o4; //switch to next player
            else
                next_state <= x4; //still x's fourth turn
        end
        else if (cur_state == o4) begin//o fourth turn
            if (btn[2] == 1'b1) //when the 3rd button is pressed
                next_state <= x5; //switch to next player
            else
                next_state <= o4; //still o's fourth turn
        end
        else if (cur_state == x5) begin//x last turn
            if (btn[1] == 1'b1) //when the 2nd button is pressed
                next_state <= rst; //switch to next player
            else
                next_state <= x5; //still x's last turn
        end
        else //catch all
            next_state <= rst;
    end
    
    //Instantiate the OX_ROMs
    OX_rom O1 (
        .isX(1'b0),//O rom => 0
        .x(o1_x_reg),
        .y(o1_y_reg),
        .h(h_cntr_reg),
        .v(v_cntr_reg),
        .box(pixel_in_O1), 
        .rom(o1_rom)
    ); 
    OX_rom O2 (
        .isX(1'b0),//O rom => 0
        .x(o2_x_reg),
        .y(o2_y_reg),
        .h(h_cntr_reg),
        .v(v_cntr_reg),
        .box(pixel_in_O2), 
        .rom(o2_rom)
    );
    OX_rom O3 (
        .isX(1'b0),//O rom => 0
        .x(o3_x_reg),
        .y(o3_y_reg),
        .h(h_cntr_reg),
        .v(v_cntr_reg),
        .box(pixel_in_O3), 
        .rom(o3_rom)
    );
    OX_rom O4 (
        .isX(1'b0),//O rom => 0
        .x(o4_x_reg),
        .y(o4_y_reg),
        .h(h_cntr_reg),
        .v(v_cntr_reg),
        .box(pixel_in_O4), 
        .rom(o4_rom)
    );

    OX_rom X1 (
        .isX(1'b1),//X rom => 1
        .x(x1_x_reg),
        .y(x1_y_reg),
        .h(h_cntr_reg),
        .v(v_cntr_reg),
        .box(pixel_in_X1), 
        .rom(x1_rom)
    );
    OX_rom X2 (
        .isX(1'b1),//X rom => 1
        .x(x2_x_reg),
        .y(x2_y_reg),
        .h(h_cntr_reg),
        .v(v_cntr_reg),
        .box(pixel_in_X2), 
        .rom(x2_rom)
    );
    OX_rom X3 (
        .isX(1'b1),//X rom => 1
        .x(x3_x_reg),
        .y(x3_y_reg),
        .h(h_cntr_reg),
        .v(v_cntr_reg),
        .box(pixel_in_X3), 
        .rom(x3_rom)
    );
    OX_rom X4 (
        .isX(1'b1),//X rom => 1
        .x(x4_x_reg),
        .y(x4_y_reg),
        .h(h_cntr_reg),
        .v(v_cntr_reg),
        .box(pixel_in_X4), 
        .rom(x4_rom)
    );
    OX_rom X5 (
        .isX(1'b1),//X rom => 1
        .x(x5_x_reg),
        .y(x5_y_reg),
        .h(h_cntr_reg),
        .v(v_cntr_reg),
        .box(pixel_in_X5), 
        .rom(x5_rom)
    );
    
    
    always @(active, h_cntr_reg, v_cntr_reg)
      begin 
        if (active == 1'b1)
        begin
            //create the tic-tac-toe walls in white
            //vertical walls
            if(v_cntr_reg >= ONE_SIXTY_V * 19 && v_cntr_reg < ONE_SIXTY_V * 20 ) //first wall at 1/3
            begin
                vga_red     <= 4'b1111;
                vga_green   <= 4'b1111;
                vga_blue    <= 4'b1111;
            end
            else if(v_cntr_reg >= ONE_SIXTY_V * 39 && v_cntr_reg < ONE_SIXTY_V * 40 ) //second wall at 2/3
            begin
                vga_red     <= 4'b1111;
                vga_green   <= 4'b1111;
                vga_blue    <= 4'b1111;
            end
            //horizontal walls
            else if(h_cntr_reg >= ONE_SIXTY_FOUR_H * 21 && h_cntr_reg < ONE_SIXTY_FOUR_H * 22 ) //first wall at 1/3
            begin
                vga_red     <= 4'b1111;
                vga_green   <= 4'b1111;
                vga_blue    <= 4'b1111;
            end
            else if(h_cntr_reg >= ONE_SIXTY_FOUR_H * 43 && h_cntr_reg < ONE_SIXTY_FOUR_H * 44 ) //first wall at 1/3
            begin
                vga_red     <= 4'b1111;
                vga_green   <= 4'b1111;
                vga_blue    <= 4'b1111;
            end
            //Moving X's and O's
            //displays first X if the state is not reset
            else if(pixel_in_X1 == 1'b1 && (cur_state != rst))
            begin
                //displays X's in Magenta
                vga_red     <= {4{x1_rom}}; //uses the XO_rom module to see if the bit is in the bitmap
                vga_blue    <= {4{x1_rom}};
            end
            //displays first O if the state is not reset or X's first turn 
            else if((pixel_in_O1 == 1'b1) && ((cur_state != rst) && (cur_state != x1)))
            begin
                //displays O's in Cyan
                vga_green   <= {4{o1_rom}};
                vga_blue    <= {4{o1_rom}};
            end
            //displays second X if the state is not reset or X's/O's first turn
            else if((pixel_in_X2 == 1'b1) && ((cur_state != rst) && (cur_state != x1) && (cur_state != o1)))
            begin
                vga_red     <= {4{x2_rom}};
                vga_blue    <= {4{x2_rom}};
            end
            //displays second O if the state is not reset, X's/O's first turn, or X's second turn
            else if(pixel_in_O2 == 1'b1 && ((cur_state != rst) && (cur_state != x1) && (cur_state != o1) && (cur_state != x2)) )
            begin
                vga_green   <= {4{o2_rom}};
                vga_blue    <= {4{o2_rom}};
            end
            //displays third X if the state is not reset, X's/O's first turn, or X's/O's second turn
            else if(pixel_in_X3 == 1'b1 && ((cur_state != rst) && (cur_state != x1) && (cur_state != o1) && (cur_state != x2) && (cur_state != o2)) )
            begin
                vga_red     <= {4{x3_rom}};
                vga_blue    <= {4{x3_rom}};
            end
            //displays third O if the state is either O's third turn, O's/X's fourth turn, or X's fifth turn
            else if(pixel_in_O3 == 1'b1 && ((cur_state == o3) || (cur_state == x4) || (cur_state == o4) || (cur_state == x5)))
            begin
                vga_green   <= {4{o3_rom}};
                vga_blue    <= {4{o3_rom}};
            end
            //displays fourth X if the state is either O's/X's fourth turn or X's fifth turn
            else if(pixel_in_X4 == 1'b1 && ((cur_state == x4) || (cur_state == o4) || (cur_state == x5)))
            begin
                vga_red     <= {4{x4_rom}};
                vga_blue    <= {4{x4_rom}};
            end
            //displays fourth O if the state is either O's fourth turn or X's fifth turn
            else if(pixel_in_O4 == 1'b1 && ((cur_state == o4) || (cur_state == x5)))
            begin
                vga_green   <= {4{o4_rom}};
                vga_blue    <= {4{o4_rom}};
            end
            //displays fifth X if the state is X's fifth turn
            else if(pixel_in_X5 == 1'b1 && (cur_state == x5))
            begin
                vga_red     <= {4{x5_rom}};
                vga_blue    <= {4{x5_rom}};
            end
            
            //other areas of the screen
            else
            begin
                vga_red     <= 4'b0;
                vga_green   <= 4'b0;
                vga_blue    <= 4'b0;
            end
        end   
        else // if active = 0 => turn off the vgas
        begin
            vga_red <= 4'b0;
            vga_green <= 4'b0;
            vga_blue <= 4'b0;
        end
        
      end
      
      //Moving X's and O's
      always @(posedge pxl_clk) //speed of the X's and O's
      begin
          if (box_cntr_reg == (BOX_CLK_DIV - 1)) // every time the box_cntr resets it updates the box
            box_cntr_reg <= 25'b0;
          else
            box_cntr_reg <= box_cntr_reg + 1;     
      end
      
      assign update_box = (box_cntr_reg == (BOX_CLK_DIV - 1)) ? 1'b1 : 1'b0;// (slow clk)

      always @(posedge pxl_clk) begin//direction
          if (btn[0] == 1 || cur_state == rst) begin  //check for rst
                box_y_reg <= BOX_Y_INIT;
                box_x_reg <= BOX_X_INIT;
          end
          else if (update_box == 1'b1)
          begin
            case (sw)
                4'b0001:begin //goes up
                    if (box_y_dir == 1'b0 && (box_y_reg == BOX_Y_MIN + 1)) //if it hits the top
                        box_y_reg <= box_y_reg; //doesn't move  
                    else begin
                        box_y_reg <= box_y_reg - 1;
                        box_y_dir <= 1'b0;
                    end
                end
                4'b0010:begin //goes down
                    if (box_y_dir == 1'b1 && (box_y_reg == BOX_Y_MAX - 1)) //if it hits the bottom
                        box_y_reg <= box_y_reg; //doesn't move  
                    else begin
                        box_y_reg <= box_y_reg + 1;
                        box_y_dir <= 1'b1;
                    end
                end
                4'b0100:begin //goes left
                    if (box_x_dir == 1'b0 && (box_x_reg == BOX_X_MIN + 1)) //if it hits the left edge
                        box_x_reg <= box_x_reg; //doesn't move  
                    else begin
                        box_x_reg <= box_x_reg - 1;
                        box_x_dir <= 1'b0;
                    end
                end
                4'b1000:begin //goes right
                    if (box_x_dir == 1'b1 && (box_x_reg == BOX_X_MAX - 1)) //if it hits the right edge
                        box_x_reg <= box_x_reg; //doesn't move  
                    else begin
                        box_x_reg <= box_x_reg + 1;
                        box_x_dir <= 1'b1;
                    end
                end
                default: begin
                    box_x_reg = box_x_reg; //no movement if no user input
                    box_y_reg = box_y_reg; //no movement if no user input
                end
            endcase
        end    
      end

      // Control which piece is being moved
      always @(posedge pxl_clk) begin
        case (cur_state)
        x1  : begin//first turn
            x1_x_reg <= box_x_reg;
            x1_y_reg <= box_y_reg;
        end    
        o1  :begin//first turn
            //o is now following the box
            o1_x_reg <= box_x_reg;
            o1_y_reg <= box_y_reg;
            
            //x stays the same
            x1_x_reg <= x1_x_reg;
            x1_y_reg <= x1_y_reg;
        end
        x2  : begin//second turn
            //x is now following the box
            x2_x_reg <= box_x_reg;
            x2_y_reg <= box_y_reg;
            
            //o stays the same
            o1_x_reg <= o1_x_reg;
            o1_y_reg <= o1_y_reg;
        end
        o2  : begin//second turn
            //o is now following the box
            o2_x_reg <= box_x_reg;
            o2_y_reg <= box_y_reg;
            
            //x stays the same
            x2_x_reg <= x2_x_reg;
            x2_y_reg <= x2_y_reg;
        end
        x3  : begin//third turn
            //x is now following the box
            x3_x_reg <= box_x_reg;
            x3_y_reg <= box_y_reg;
            
            //o stays the same
            o2_x_reg <= o2_x_reg;
            o2_y_reg <= o2_y_reg;
        end
        o3  : begin//third turn
            //o is now following the box
            o3_x_reg <= box_x_reg;
            o3_y_reg <= box_y_reg;
            
            //x stays the same
            x3_x_reg <= x3_x_reg;
            x3_y_reg <= x3_y_reg;
        end
        x4  : begin//fourth turn
            //x is now following the box
            x4_x_reg <= box_x_reg;
            x4_y_reg <= box_y_reg;
            
            //o stays the same
            o3_x_reg <= o3_x_reg;
            o3_y_reg <= o3_y_reg;
        end
        o4  :begin//fourth turn
            //o is now following the box
            o4_x_reg <= box_x_reg;
            o4_y_reg <= box_y_reg;
            
            //x stays the same
            x4_x_reg <= x4_x_reg;
            x4_y_reg <= x4_y_reg;
        end
        x5  :begin//fifth turn
            //x is now following the box
            x5_x_reg <= box_x_reg;
            x5_y_reg <= box_y_reg;
            
            //o stays the same
            o4_x_reg <= o4_x_reg;
            o4_y_reg <= o4_y_reg;
        end
        rst: begin //reset everything
            //x registers
            x1_x_reg <= box_x_reg;
            x2_x_reg <= box_x_reg;
            x3_x_reg <= box_x_reg;
            x4_x_reg <= box_x_reg;
            x5_x_reg <= box_x_reg;
            
            o1_x_reg <= box_x_reg;
            o2_x_reg <= box_x_reg;
            o3_x_reg <= box_x_reg;
            o4_x_reg <= box_x_reg;
            
            //y registers
            x1_y_reg <= box_y_reg;
            x2_y_reg <= box_y_reg;
            x3_y_reg <= box_y_reg;
            x4_y_reg <= box_y_reg;
            x5_y_reg <= box_y_reg;
            
            o1_y_reg <= box_y_reg;
            o2_y_reg <= box_y_reg;
            o3_y_reg <= box_y_reg;
            o4_y_reg <= box_y_reg;
        end
        default: begin //everything stays the same
            //x registers
            x1_x_reg <= x1_x_reg;
            x2_x_reg <= x2_x_reg;
            x3_x_reg <= x3_x_reg;
            x4_x_reg <= x4_x_reg;
            x5_x_reg <= x5_x_reg;
            
            o1_x_reg <= o1_x_reg;
            o2_x_reg <= o2_x_reg;
            o3_x_reg <= o3_x_reg;
            o4_x_reg <= o4_x_reg;
            
            //y registers
            x1_y_reg <= x1_y_reg;
            x2_y_reg <= x2_y_reg;
            x3_y_reg <= x3_y_reg;
            x4_y_reg <= x4_y_reg;
            x5_y_reg <= x5_y_reg;
            
            o1_y_reg <= o1_y_reg;
            o2_y_reg <= o2_y_reg;
            o3_y_reg <= o3_y_reg;
            o4_y_reg <= o4_y_reg;
        end
        endcase
        
      end
                    
      //logic controlling the X and O displays              
      assign pixel_in_X1 = (((h_cntr_reg >= x1_x_reg) && (h_cntr_reg < (x1_x_reg + BOX_WIDTH))) 
                            && ((v_cntr_reg >= x1_y_reg) && (v_cntr_reg < (x1_y_reg + BOX_WIDTH)))) 
                            ? 1'b1 : 1'b0;//generates shape of box
      
      assign pixel_in_O1 = (((h_cntr_reg >= o1_x_reg) && (h_cntr_reg < (o1_x_reg + BOX_WIDTH))) 
                            && ((v_cntr_reg >= o1_y_reg) && (v_cntr_reg < (o1_y_reg + BOX_WIDTH))))
                            ? 1'b1 : 1'b0;//generates shape of box
                            
      assign pixel_in_X2 = (((h_cntr_reg >= x2_x_reg) && (h_cntr_reg < (x2_x_reg + BOX_WIDTH))) 
                            && ((v_cntr_reg >= x2_y_reg) && (v_cntr_reg < (x2_y_reg + BOX_WIDTH))))
                            ? 1'b1 : 1'b0;//generates shape of box
      
      assign pixel_in_O2 = (((h_cntr_reg >= o2_x_reg) && (h_cntr_reg < (o2_x_reg + BOX_WIDTH))) 
                            && ((v_cntr_reg >= o2_y_reg) && (v_cntr_reg < (o2_y_reg + BOX_WIDTH))))
                            ? 1'b1 : 1'b0;//generates shape of box
                            
      assign pixel_in_X3 = (((h_cntr_reg >= x3_x_reg) && (h_cntr_reg < (x3_x_reg + BOX_WIDTH))) 
                            && ((v_cntr_reg >= x3_y_reg) && (v_cntr_reg < (x3_y_reg + BOX_WIDTH)))) 
                            ? 1'b1 : 1'b0;//generates shape of box
      
      assign pixel_in_O3 = (((h_cntr_reg >= o3_x_reg) && (h_cntr_reg < (o3_x_reg + BOX_WIDTH))) 
                            && ((v_cntr_reg >= o3_y_reg) && (v_cntr_reg < (o3_y_reg + BOX_WIDTH))))
                            ? 1'b1 : 1'b0;//generates shape of box     
      
      assign pixel_in_X4 = (((h_cntr_reg >= x4_x_reg) && (h_cntr_reg < (x4_x_reg + BOX_WIDTH))) 
                            && ((v_cntr_reg >= x4_y_reg) && (v_cntr_reg < (x4_y_reg + BOX_WIDTH))))
                            ? 1'b1 : 1'b0;//generates shape of box
      
      assign pixel_in_O4 = (((h_cntr_reg >= o4_x_reg) && (h_cntr_reg < (o4_x_reg + BOX_WIDTH))) 
                            && ((v_cntr_reg >= o4_y_reg) && (v_cntr_reg < (o4_y_reg + BOX_WIDTH))))
                            ? 1'b1 : 1'b0;//generates shape of box
      
      assign pixel_in_X5 = (((h_cntr_reg >= x5_x_reg) && (h_cntr_reg < (x5_x_reg + BOX_WIDTH))) 
                            && ((v_cntr_reg >= x5_y_reg) && (v_cntr_reg < (x5_y_reg + BOX_WIDTH))))
                            ? 1'b1 : 1'b0;//generates shape of box
      
     //SYNC GENERATION
     always @(posedge(pxl_clk))
     begin
        if (h_cntr_reg == (H_MAX - 1))// if not @ end of horizontal position
        begin 
            h_cntr_reg <= 12'b0; //restart horizontal counter
        end    
        else
        begin
            h_cntr_reg <= h_cntr_reg + 1; //travel to the next horizontal position
        end
     end

     always @(posedge(pxl_clk))
     begin
        if ((h_cntr_reg == (H_MAX - 1)) && (v_cntr_reg == (V_MAX - 1))) // checks if @ end of horizontal line and @ the end of the vertical
            v_cntr_reg <= 12'b0;  //if so => restart
        else if (h_cntr_reg == (H_MAX - 1)) //if at the end of the horizontal position 
            v_cntr_reg <= v_cntr_reg + 1; //move to the next line
     end
    
     always @(posedge pxl_clk)
     begin
        if ((h_cntr_reg >= (H_FP + FRAME_WIDTH - 1)) && (h_cntr_reg < (H_FP + FRAME_WIDTH + H_PW - 1))) 
            h_sync_reg <= H_POL; //if in display region => shine
        else
            h_sync_reg <= ~(H_POL); //not in display region => don't shine
     end
      
     always @(posedge pxl_clk)
     begin
        if ((v_cntr_reg >= (V_FP + FRAME_HEIGHT - 1)) && (v_cntr_reg < (V_FP + FRAME_HEIGHT + V_PW - 1))) 
            v_sync_reg <= V_POL; //if in diplay region => shine
        else
            v_sync_reg <= ~(V_POL); //not in display region => don't shine
     end 
      
     //if within the active region of the display => return a 1 
     assign active = ((h_cntr_reg < FRAME_WIDTH) && (v_cntr_reg < FRAME_HEIGHT)) ? 1'b1: 1'b0;
    
    
    //set the values of the delay registers
     always @(posedge pxl_clk)
     begin
        v_sync_dly_reg <= v_sync_reg;
        h_sync_dly_reg <= h_sync_reg;
        vga_red_reg <= vga_red;
        vga_green_reg <= vga_green;
        vga_blue_reg <= vga_blue;
     end
    
    //set the output wires to the delay registers
    assign VGA_HS_O = h_sync_dly_reg;
    assign VGA_VS_O = v_sync_dly_reg;
    assign VGA_R = vga_red_reg;
    assign VGA_G = vga_green_reg;
    assign VGA_B = vga_blue_reg;
     
             
endmodule
