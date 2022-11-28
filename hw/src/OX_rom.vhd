-- OX_rom module
-- Author: Sarah Beth Blazic
-- Date: 11/25/2022
-- Purpose: To create a bitmap of the moving images, X's and O's, in the application, 
-- a constant 2D array was needed so that each bit could be read when the display passed
-- over a specific area. This was easier to implement in VHDL and proved to be a good 
-- application of how the two languages, Verilog and VHDL, can be used in designs of a 
-- different language. 

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;
use ieee.math_real.all;

entity OX_rom is
    Port ( 
           isX : in STD_LOGIC;
           x : in STD_LOGIC_VECTOR (11 downto 0);
           y : in STD_LOGIC_VECTOR (11 downto 0);
           h : in STD_LOGIC_VECTOR (11 downto 0);
           v : in STD_LOGIC_VECTOR (11 downto 0);
           box : in STD_LOGIC;
           rom : out STD_LOGIC);
end OX_rom;

architecture Behavioral of OX_rom is

type rom_type is array (0 to 19) of std_logic_vector(19 downto 0); -- ROM definition
                                                                                    
constant O_ROM: rom_type := ( --Bit map of the O piece                                          
                "00000111111111100000",                                                     
                "00001111111111110000",                                                     
                "00111111111111111100",                                                     
                "00111000000000011100",                                                 
                "01110000000000001110",                                             
                "11100000000000000111",                                                     
                "11100000000000000111",                                                             
                "11100000000000000111",                                                 
                "11100000000000000111",                                                 
                "11100000000000000111",                                             
                "11100000000000000111",                                                         
                "11100000000000000111",                                             
                "11100000000000000111",                                                         
                "11100000000000000111",                                             
                "11100000000000000111",                                                         
                "01110000000000001110",                                                     
                "00111000000000011100",                                                     
                "00111111111111111100",                                                     
                "00001111111111110000",                                                 
                "00000111111111100000"                                                           
            );                                                                       
                                                                                    
constant X_ROM: rom_type := ( -- Bit map of the X piece
                "11100000000000000111",
                "11100000000000000111",
                "01110000000000001110",
                "00111000000000011100",
                "00011100000000111000",
                "00001110000001110000",
                "00000111000011100000",
                "00000011100111000000",
                "00000001111110000000",
                "00000000111100000000",
                "00000000111100000000",
                "00000001111110000000",
                "00000011100111000000",
                "00000111000011100000",
                "00001110000001110000",
                "00011100000000111000",
                "00111000000000011100",
                "01110000000000001110",
                "11100000000000000111",
                "11100000000000000111"
            );


begin

--        -- returns X rom
    rom <= X_ROM(conv_integer(v(7 downto 3) - y(11 downto 3) )) --grab vertical val in rom and subtract box_y_reg for current location
                (conv_integer(h(7 downto 3) - x(11 downto 3) )) when (box = '1' and isX = '1') else 
           -- returns O rom
           O_ROM(conv_integer(v(7 downto 3) - y(11 downto 3))) --grab vertical val in rom and subtract box_y_reg for current location
                (conv_integer(h(7 downto 3) - x(11 downto 3))) when (box = '1' and isX = '0') else
           '0'; 
           
end Behavioral;
