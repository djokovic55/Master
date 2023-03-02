/***************************************************************************************************************************************
* Project name : ascm                                                                                                                  *
* File name    : tb.v                                                                                                                  *                                                                            
* Author(s)    : Aleksa Djokovic, Sreten Vasiljevic, Stefan Stanisic, Miodrag Vukovic                                                  *   
* Version      : 1.0                                                                                                                   *
* Created      : Feb 19, 2021                                                                                                          *
* E-mail(s)    : aleksa.djokovic@elsys-eastern.com, sreten.vasiljevic@elsys-eastern.com,                                               *
                 stefan.stanisic@elsys-eastern.com, miodrag.vukovic@elsys-eastern.com                                                  *
*Support       : ELSYS EE                                                                                                              *
****************************************************************************************************************************************
* Release notes:

   v1.0 (Feb 19, 2021): - Initial version

* Description:

   This file is a testbench and is part of a functional development project of ASCM IP by using HDL languages. 

* Folder structure:

    ascm
      |
      |---> doc              - Contains all project related documentation, such as user manual and design microarchitecture.
      |---> rtl
      |      |---> vhdl      - Contains DUT files written in VHDL language.
      |
      |---> verif
      |      |---> directed  - Contains verification testbenches.
      |
      |---> scripts          - Contains all scripts and tool related files needed for simulations.
      |---> work             - Contains results of every simulation that has been run.

* Usage:
 - Go to 'scripts' folder.
 - Run 'make help' command to get more info on how to run simulation.

****************************************************************************************************************************************/
/*`timescale 1ns/1ps
`define CLK_HALF_PERIOD 20

`define IN_DATA_WIDTH 8
`define OUT_DATA_WIDTH 3
*/
module ascm_tb_top();
//---ascm clock and reset
    reg clk;
    reg reset_n;

//--ascm control inputs
    reg active_mode;
    reg error_det;

//--ascm input data
    reg [8-1:0] colomn_length_east;
    reg [8-1:0] colomn_length_west;
    reg [8-1:0] colomn_length_north;
    reg [8-1:0] colomn_length_south;

//--ascm output data
    wire [8-1:0] semaphore_ctrl_east;
    wire [8-1:0] semaphore_ctrl_west;
    wire [8-1:0] semaphore_ctrl_north;
    wire [8-1:0] semaphore_ctrl_south;
//---------------------------------------------------

//Dut instance-----------------
 semaphore dut(
        //clock and reset ports
        .pi_clk(clk),
        .pi_rst_n(reset_n),
        
        //dut's control input ports
        .pi_active_mode(active_mode),
        .pi_error_det(error_det),
        
        //dut's data input ports
        .pi_colomn_length_east(colomn_length_east),
        .pi_colomn_length_west(colomn_length_west),
        .pi_colomn_length_north(colomn_length_north),
        .pi_colomn_length_south(colomn_length_south),

        //dut's data output ports
        .po_semaphore_ctrl_east(semaphore_ctrl_east),
        .po_semaphore_ctrl_west(semaphore_ctrl_west),
        .po_semaphore_ctrl_north(semaphore_ctrl_north),
        .po_semaphore_ctrl_south(semaphore_ctrl_south));

//CLK GEN
    initial begin
        clk = 1'b0;
        forever begin
            #20 clk = ~clk;
        end
    end


   

//Direct testing----------------
    initial begin
        colomn_length_east = 20;
        colomn_length_west = 25;
        colomn_length_north = 30;
        colomn_length_south = 50;

        reset_n = 0;
        active_mode = 0;
        error_det = 0;
        
        #100;
        active_mode = 1;
        
        #50;
        reset_n = 1;

        #500;
        error_det = 1;
        
        #100
        error_det = 0;

        #1000 $stop;
        
    end
endmodule
