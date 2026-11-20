// Copyright (C) 2017  Intel Corporation. All rights reserved.
// Your use of Intel Corporation's design tools, logic functions 
// and other software and tools, and its AMPP partner logic 
// functions, and any output files from any of the foregoing 
// (including device programming or simulation files), and any 
// associated documentation or information are expressly subject 
// to the terms and conditions of the Intel Program License 
// Subscription Agreement, the Intel Quartus Prime License Agreement,
// the Intel MegaCore Function License Agreement, or other 
// applicable license agreement, including, without limitation, 
// that your use is for the sole purpose of programming logic 
// devices manufactured by Intel and sold by Intel or its 
// authorized distributors.  Please refer to the applicable 
// agreement for further details.

// PROGRAM		"Quartus Prime"
// VERSION		"Version 17.0.0 Build 595 04/25/2017 SJ Lite Edition"
// CREATED		"Fri Nov 20 18:45:46 2026"

module fish_block_t(
	clk,
	resetN,
	startOfFrame,
	Y_direction_key,
	gameOn,
	objectsResetN,
	darkModeOn,
	pixelX,
	pixelY,
	fishDR,
	fishRGB,
	fishTopLeftX,
	fishTopLeftY
);

parameter	initial_x = 280;
parameter	initial_x_speed = 60;
parameter	initial_y = 185;
parameter	initial_y_speed = 20;

input wire	clk;
input wire	resetN;
input wire	startOfFrame;
input wire	Y_direction_key;
input wire	gameOn;
input wire	objectsResetN;
input wire	darkModeOn;
input wire	[10:0] pixelX;
input wire	[10:0] pixelY;
output wire	fishDR;
output wire	[7:0] fishRGB;
output wire	[10:0] fishTopLeftX;
output wire	[10:0] fishTopLeftY;

wire	[10:0] fishOffsetX;
wire	[10:0] fishOffsety;
wire	fishRecDR;
wire	[10:0] FishTLX;
wire	[10:0] FishTLY;





fish_move	b2v_inst(
	.clk(clk),
	.resetN(resetN),
	.startOfFrame(startOfFrame),
	.Y_direction_key(Y_direction_key),
	.gameOn(gameOn),
	.objectsResetN(objectsResetN),
	.topLeftX(FishTLX),
	.topLeftY(FishTLY));
	defparam	b2v_inst.INITIAL_X = 130;
	defparam	b2v_inst.INITIAL_X_SPEED = 0;
	defparam	b2v_inst.INITIAL_Y = 240;
	defparam	b2v_inst.INITIAL_Y_SPEED = 20;
	defparam	b2v_inst.Y_ACCEL = -14;


fish_bit_map	b2v_inst1(
	.clk(clk),
	.resetN(resetN),
	.InsideRectangle(fishRecDR),
	.darkModeOn(darkModeOn),
	.Y_direction_key(Y_direction_key),
	.startOfFrame(startOfFrame),
	.offsetX(fishOffsetX),
	.offsetY(fishOffsety),
	.drawingRequest(fishDR),
	.RGBout(fishRGB));


square_object	b2v_inst6(
	.clk(clk),
	.resetN(resetN),
	.pixelX(pixelX),
	.pixelY(pixelY),
	.topLeftX(FishTLX),
	.topLeftY(FishTLY),
	.drawingRequest(fishRecDR),
	.offsetX(fishOffsetX),
	.offsetY(fishOffsety));
	defparam	b2v_inst6.OBJECT_HEIGHT_Y = 32;
	defparam	b2v_inst6.OBJECT_WIDTH_X = 32;

assign	fishTopLeftX = FishTLX;
assign	fishTopLeftY = FishTLY;

endmodule
