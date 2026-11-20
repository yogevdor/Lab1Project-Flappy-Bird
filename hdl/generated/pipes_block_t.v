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
// CREATED		"Fri Nov 20 18:45:47 2026"

module pipes_block_t(
	clk,
	resetN,
	startOfFrame,
	gameOn,
	objectsResetN,
	gapTop,
	pixelX,
	pixelY,
	speedBooost,
	singlePipeDR,
	regenerate,
	passed,
	singlePipeRGB
);

parameter	INITIAL_PIPE_TYPE = 0;
parameter	INITIAL_X = 281;
parameter	INITIAL_X_SPEED = -64;
parameter	INITIAL_Y = 64;
parameter	INITIAL_Y_SPEED = 0;

input wire	clk;
input wire	resetN;
input wire	startOfFrame;
input wire	gameOn;
input wire	objectsResetN;
input wire	[10:0] gapTop;
input wire	[10:0] pixelX;
input wire	[10:0] pixelY;
input wire	[9:0] speedBooost;
output wire	singlePipeDR;
output wire	regenerate;
output wire	passed;
output wire	[7:0] singlePipeRGB;

wire	[10:0] pipeOffsetX;
wire	[10:0] pipeOffsety;
wire	pipeRecDR;
wire	regenerate_ALTERA_SYNTHESIZED;
wire	[10:0] singlePipeTLX;
wire	[10:0] singlePipeTLY;





single_pipe_move	b2v_inst(
	.clk(clk),
	.resetN(resetN),
	.startOfFrame(startOfFrame),
	.gameOn(gameOn),
	.objectsResetN(objectsResetN),
	.speedBoost(speedBooost),
	.passed(passed),
	.regenerate(regenerate_ALTERA_SYNTHESIZED),
	.topLeftX(singlePipeTLX),
	.topLeftY(singlePipeTLY));
	defparam	b2v_inst.FISH_X = 130;
	defparam	b2v_inst.INITIAL_X = INITIAL_X;
	defparam	b2v_inst.INITIAL_X_SPEED = INITIAL_X_SPEED;
	defparam	b2v_inst.INITIAL_Y = INITIAL_Y;
	defparam	b2v_inst.INITIAL_Y_SPEED = INITIAL_Y_SPEED;


pipe_brick_bit_map	b2v_inst3(
	.clk(clk),
	.resetN(resetN),
	.InsideRectangle(pipeRecDR),
	.regenerate(regenerate_ALTERA_SYNTHESIZED),
	.gapTop(gapTop),
	.offsetX(pipeOffsetX),
	.offsetY(pipeOffsety),
	.drawingRequest(singlePipeDR),
	.RGBout(singlePipeRGB));
	defparam	b2v_inst3.GAP_SIZE_Y = 140;
	defparam	b2v_inst3.INITIAL_PILLAR_TYPE = INITIAL_PIPE_TYPE;


square_object	b2v_inst6(
	.clk(clk),
	.resetN(resetN),
	.pixelX(pixelX),
	.pixelY(pixelY),
	.topLeftX(singlePipeTLX),
	.topLeftY(singlePipeTLY),
	.drawingRequest(pipeRecDR),
	.offsetX(pipeOffsetX),
	.offsetY(pipeOffsety));
	defparam	b2v_inst6.OBJECT_HEIGHT_Y = 480;
	defparam	b2v_inst6.OBJECT_WIDTH_X = 64;

assign	regenerate = regenerate_ALTERA_SYNTHESIZED;

endmodule
