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
// CREATED		"Fri Nov 20 18:45:45 2026"

module background_object_block_t(
	clk,
	resetN,
	startOfFrame,
	Y_direction_key,
	toggle_x_key,
	gameOn,
	objectsResetN,
	pixelX,
	pixelY,
	speedBooost,
	backObjDR,
	backObjRGB
);

parameter	INITIAL_X = 281;
parameter	INITIAL_X_SPEED = -64;
parameter	INITIAL_Y = 110;
parameter	INITIAL_Y_SPEED = 0;
parameter	MIF_FILE_ = "RTL/sea_turtle.mif";
parameter	OBJECT_HEIGHT_Y_ = 32;
parameter	OBJECT_WIDTH_X_ = 64;

input wire	clk;
input wire	resetN;
input wire	startOfFrame;
input wire	Y_direction_key;
input wire	toggle_x_key;
input wire	gameOn;
input wire	objectsResetN;
input wire	[10:0] pixelX;
input wire	[10:0] pixelY;
input wire	[7:0] speedBooost;
output wire	backObjDR;
output wire	[7:0] backObjRGB;

wire	[10:0] backObjOffsetX;
wire	[10:0] backObjOffsety;
wire	backObjRecDR;
wire	[10:0] backObjTLX;
wire	[10:0] backObjTLY;
wire	SYNTHESIZED_WIRE_0;





background_object_move	b2v_inst(
	.clk(clk),
	.resetN(resetN),
	.startOfFrame(startOfFrame),
	.Y_direction_key(Y_direction_key),
	.toggle_x_key(toggle_x_key),
	.gameOn(gameOn),
	.objectsResetN(objectsResetN),
	.speedBoost(speedBooost),
	.regenerate(SYNTHESIZED_WIRE_0),
	.topLeftX(backObjTLX),
	.topLeftY(backObjTLY));
	defparam	b2v_inst.INITIAL_X = INITIAL_X;
	defparam	b2v_inst.INITIAL_X_SPEED = INITIAL_X_SPEED;
	defparam	b2v_inst.INITIAL_Y = INITIAL_Y;
	defparam	b2v_inst.INITIAL_Y_SPEED = INITIAL_Y_SPEED;


background_object_bit_map	b2v_inst2(
	.clk(clk),
	.resetN(resetN),
	.InsideRectangle(backObjRecDR),
	.objectTypeSelect(SYNTHESIZED_WIRE_0),
	.offsetX(backObjOffsetX),
	.offsetY(backObjOffsety),
	.drawingRequest(backObjDR),
	.RGBout(backObjRGB));
	defparam	b2v_inst2.MIF_FILE = MIF_FILE_;


square_object	b2v_inst6(
	.clk(clk),
	.resetN(resetN),
	.pixelX(pixelX),
	.pixelY(pixelY),
	.topLeftX(backObjTLX),
	.topLeftY(backObjTLY),
	.drawingRequest(backObjRecDR),
	.offsetX(backObjOffsetX),
	.offsetY(backObjOffsety));
	defparam	b2v_inst6.OBJECT_HEIGHT_Y = OBJECT_HEIGHT_Y_;
	defparam	b2v_inst6.OBJECT_WIDTH_X = OBJECT_WIDTH_X_;


endmodule
