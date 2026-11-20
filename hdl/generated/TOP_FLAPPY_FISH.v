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

module TOP_FLAPPY_FISH(
	CLOCK_50,
	PS2_CLK,
	PS2_DAT,
	resetN_pin,
	AUDIN,
	KEY,
	SW,
	AUDOUT,
	HEX0,
	HEX1,
	HEX2,
	HEX3,
	HEX4,
	HEX5,
	OVGA
);


input wire	CLOCK_50;
input wire	PS2_CLK;
input wire	PS2_DAT;
input wire	resetN_pin;
input wire	[1:2] AUDIN;
input wire	[3:3] KEY;
input wire	[1:0] SW;
output wire	[4:7] AUDOUT;
output wire	[6:0] HEX0;
output wire	[6:0] HEX1;
output wire	[6:0] HEX2;
output wire	[6:0] HEX3;
output wire	[6:0] HEX4;
output wire	[6:0] HEX5;
output wire	[28:0] OVGA;

wire	[18:0] address;
wire	backObj1DR;
wire	[7:0] backObj1RGB;
wire	backObj2DR;
wire	[7:0] backObj2RGB;
wire	[7:0] BG_RGB;
wire	bossActive;
wire	[10:0] Box_offsetX;
wire	[10:0] Box_offsetY;
wire	boxDrawingRequest;
wire	clk;
wire	collision;
wire	darkModeOn;
wire	[3:0] digit;
wire	enableGameOverScreen;
wire	enablePauseScreen;
wire	enableStartScreen;
wire	enter;
wire	fishDR;
wire	[7:0] fishRGB;
wire	[10:0] fishTopLeftX;
wire	[10:0] fishTopLeftY;
wire	gameOn;
wire	gameOverScreenDR;
wire	[7:0] gameOverScreenRGB;
wire	[10:0] gapOut1;
wire	[10:0] gapOut2;
wire	[10:0] gapOut3;
wire	[10:0] gapTop1;
wire	[10:0] gapTop2;
wire	[10:0] gapTop3;
wire	[3:0] hundreds;
wire	[9:0] keyIsPressed;
wire	[3:0] keyPad;
wire	keypadValid;
wire	numberDrawingRequest;
wire	numLCK;
wire	objectsResetN;
wire	[10:0] offsetXdigit;
wire	[3:0] ones;
wire	passed1;
wire	passed2;
wire	passed3;
wire	pauseScreenDR;
wire	[7:0] pauseScreenRGB;
wire	[10:0] pixelX;
wire	[10:0] pixelY;
wire	point;
wire	regenerate1;
wire	regenerate2;
wire	regenerate3;
wire	resetN;
wire	[7:0] RGB;
wire	[7:0] RGBNum;
wire	[10:0] SCORE_topLeftX;
wire	[10:0] SCORE_topLeftY;
wire	singlePipe1DR;
wire	[7:0] singlePipe1RGB;
wire	singlePipe2DR;
wire	[7:0] singlePipe2RGB;
wire	singlePipe3DR;
wire	[7:0] singlePipe3RGB;
wire	[9:0] speedBoost;
wire	startMelody;
wire	startOfFrame;
wire	startScreenDR;
wire	[7:0] startScreenRGB;
wire	[3:0] tens;
wire	[3:0] SYNTHESIZED_WIRE_0;
wire	SYNTHESIZED_WIRE_1;
wire	SYNTHESIZED_WIRE_2;





vga_controller	b2v_inst(
	.clk(clk),
	.resetN(resetN),
	.RGBIn(RGB),
	.startOfFrame(startOfFrame),
	.address(address),
	.oVGA(OVGA),
	.PixelX(pixelX),
	.PixelY(pixelY));


fish_block_t	b2v_inst1(
	.clk(clk),
	.resetN(resetN),
	.startOfFrame(startOfFrame),
	.Y_direction_key(keyIsPressed[8]),
	.gameOn(gameOn),
	.objectsResetN(objectsResetN),
	.darkModeOn(darkModeOn),
	.pixelX(pixelX),
	.pixelY(pixelY),
	.fishDR(fishDR),
	.fishRGB(fishRGB),
	.fishTopLeftX(fishTopLeftX),
	.fishTopLeftY(fishTopLeftY));
	defparam	b2v_inst1.initial_x = 280;
	defparam	b2v_inst1.initial_x_speed = 60;
	defparam	b2v_inst1.initial_y = 185;
	defparam	b2v_inst1.initial_y_speed = 20;


objects_mux	b2v_inst10(
	.clk(clk),
	.resetN(resetN),
	.fishDrawingRequest(fishDR),
	.singlePipe1DrawingRequest(singlePipe1DR),
	.singlePipe2DrawingRequest(singlePipe2DR),
	.singlePipe3DrawingRequest(singlePipe3DR),
	.scoreDrawingRequest(numberDrawingRequest),
	.startScreenDrawingRequest(startScreenDR),
	.gameOverScreenDrawingRequest(gameOverScreenDR),
	.pauseScreenDrawingRequest(pauseScreenDR),
	.backgroundObject1DrawingRequest(backObj1DR),
	.backgroundObject2DrawingRequest(backObj2DR),
	.darkModeOn(darkModeOn),
	.BG_RGB(BG_RGB),
	.BGObj1RGB(backObj1RGB),
	.BGObj2RGB(backObj2RGB),
	.fishRGB(fishRGB),
	.fishTopLeftX(fishTopLeftX),
	.fishTopLeftY(fishTopLeftY),
	.gameOverScreenRGB(gameOverScreenRGB),
	.pauseScreenRGB(pauseScreenRGB),
	.pixelX(pixelX),
	.pixelY(pixelY),
	.Score_RGB(RGBNum),
	.singlePipe1RGB(singlePipe1RGB),
	.singlePipe2RGB(singlePipe2RGB),
	.singlePipe3RGB(singlePipe3RGB),
	.startScreenRGB(startScreenRGB),
	.RGBOut(RGB));


score_position	b2v_inst11(
	.gameOver(enableGameOverScreen),
	.topLeftX(SCORE_topLeftX),
	.topLeftY(SCORE_topLeftY));


speed_controller	b2v_inst13(
	.clk(clk),
	.resetN(objectsResetN),
	.point(point),
	.turbo2(SW[0]),
	.turbo3(SW[1]),
	.speedBoost(speedBoost));
	defparam	b2v_inst13.MAX_BOOST = 128;
	defparam	b2v_inst13.PIPES_PER_STEP = 8;
	defparam	b2v_inst13.SPEED_STEP = 4;


numbers_bit_map	b2v_inst15(
	.clk(clk),
	.resetN(resetN),
	.InsideRectangle(boxDrawingRequest),
	.digit(digit),
	.offsetX(offsetXdigit),
	.offsetY(Box_offsetY),
	.drawingRequest(numberDrawingRequest),
	.RGBout(RGBNum));
	defparam	b2v_inst15.digit_color = 8'b11111111;


TOP_KBD	b2v_inst16(
	.CLOCK_50(clk),
	.resetN(resetN),
	.PS2_CLK(PS2_CLK),
	.PS2_DAT(PS2_DAT),
	
	
	
	
	.enter(enter),
	
	
	.num(numLCK),
	
	.keyIsPressed(keyIsPressed)
	);


audio	b2v_inst18(
	.volume(KEY),
	.clk(clk),
	.resetN(resetN),
	.startMelody(startMelody),
	.AUDIN(AUDIN),
	.melodySelect(SYNTHESIZED_WIRE_0),
	.AUDOUT(AUDOUT));


random	b2v_inst19(
	.clk(clk),
	.resetN(resetN),
	.rise(regenerate1),
	.flap(keyIsPressed[8]),
	.dout(gapTop1));
	defparam	b2v_inst19.MAX_VAL = 276;
	defparam	b2v_inst19.MIN_VAL = 32;
	defparam	b2v_inst19.SIZE_BITS = 11;
	defparam	b2v_inst19.START_COUNTER = 55;


score_digit_select	b2v_inst2(
	.hundreds(hundreds),
	.offsetX(Box_offsetX),
	.ones(ones),
	.tens(tens),
	.digit(digit),
	.offsetX_digit(offsetXdigit));


pause_screen_bit_map	b2v_inst20(
	.clk(clk),
	.resetN(resetN),
	.enable(enablePauseScreen),
	.pixelX(pixelX),
	.pixelY(pixelY),
	.drawingRequest(pauseScreenDR),
	.RGBout(pauseScreenRGB));


background_object_block_t	b2v_inst21(
	.clk(clk),
	.resetN(resetN),
	.startOfFrame(startOfFrame),
	.Y_direction_key(keyIsPressed[8]),
	.toggle_x_key(enter),
	.gameOn(gameOn),
	.objectsResetN(objectsResetN),
	.pixelX(pixelX),
	.pixelY(pixelY),
	.speedBooost(speedBoost[7:0]),
	.backObjDR(backObj1DR),
	.backObjRGB(backObj1RGB));
	defparam	b2v_inst21.INITIAL_X = 537;
	defparam	b2v_inst21.INITIAL_X_SPEED = -160;
	defparam	b2v_inst21.INITIAL_Y = 110;
	defparam	b2v_inst21.INITIAL_Y_SPEED = 0;
	defparam	b2v_inst21.MIF_FILE = "RTL/sea_turtle.mif";
	defparam	b2v_inst21.MIF_FILE_ = "RTL/sea_turtle.mif";
	defparam	b2v_inst21.OBJECT_HEIGHT_Y_ = 32;
	defparam	b2v_inst21.OBJECT_WIDTH_X_ = 64;


pipes_block_t	b2v_inst22(
	.clk(clk),
	.resetN(resetN),
	.startOfFrame(startOfFrame),
	.gameOn(gameOn),
	.objectsResetN(objectsResetN),
	.gapTop(gapOut2),
	.pixelX(pixelX),
	.pixelY(pixelY),
	.speedBooost(speedBoost),
	.singlePipeDR(singlePipe2DR),
	.passed(passed2),
	.regenerate(regenerate2),
	.singlePipeRGB(singlePipe2RGB));
	defparam	b2v_inst22.INITIAL_PIPE_TYPE = 0;
	defparam	b2v_inst22.INITIAL_X = 720;
	defparam	b2v_inst22.INITIAL_X_SPEED = -128;
	defparam	b2v_inst22.INITIAL_Y = 0;
	defparam	b2v_inst22.INITIAL_Y_SPEED = 0;


pipes_block_t	b2v_inst23(
	.clk(clk),
	.resetN(resetN),
	.startOfFrame(startOfFrame),
	.gameOn(gameOn),
	.objectsResetN(objectsResetN),
	.gapTop(gapOut3),
	.pixelX(pixelX),
	.pixelY(pixelY),
	.speedBooost(speedBoost),
	.singlePipeDR(singlePipe3DR),
	.passed(passed3),
	.regenerate(regenerate3),
	.singlePipeRGB(singlePipe3RGB));
	defparam	b2v_inst23.INITIAL_PIPE_TYPE = 0;
	defparam	b2v_inst23.INITIAL_X = 940;
	defparam	b2v_inst23.INITIAL_X_SPEED = -128;
	defparam	b2v_inst23.INITIAL_Y = 0;
	defparam	b2v_inst23.INITIAL_Y_SPEED = 0;


random	b2v_inst24(
	.clk(clk),
	.resetN(resetN),
	.rise(regenerate2),
	.flap(keyIsPressed[8]),
	.dout(gapTop2));
	defparam	b2v_inst24.MAX_VAL = 276;
	defparam	b2v_inst24.MIN_VAL = 32;
	defparam	b2v_inst24.SIZE_BITS = 11;
	defparam	b2v_inst24.START_COUNTER = 137;


random	b2v_inst25(
	.clk(clk),
	.resetN(resetN),
	.rise(regenerate3),
	.flap(keyIsPressed[8]),
	.dout(gapTop3));
	defparam	b2v_inst25.MAX_VAL = 276;
	defparam	b2v_inst25.MIN_VAL = 32;
	defparam	b2v_inst25.SIZE_BITS = 11;
	defparam	b2v_inst25.START_COUNTER = 211;


collision_controller	b2v_inst26(
	.clk(clk),
	.resetN(resetN),
	.startOfFrame(startOfFrame),
	.drawing_request_fish(fishDR),
	.drawing_request_pipe1(singlePipe1DR),
	.drawing_request_pipe2(singlePipe2DR),
	.drawing_request_pipe3(singlePipe3DR),
	.fishTopY(fishTopLeftY),
	.collision(collision));


game_controller	b2v_inst27(
	.clk(clk),
	.resetN(resetN),
	.startOfFrame(startOfFrame),
	.collision(collision),
	.keyIsPressed8(keyIsPressed[8]),
	.keyIsPressed0(keyIsPressed[0]),
	.keyIsPressedNUMLK(numLCK),
	.startDrawingReq(enableStartScreen),
	.gameOverDrawingReq(enableGameOverScreen),
	.pauseDrawingReq(enablePauseScreen),
	.objectsResetN(objectsResetN),
	.startMelody(startMelody),
	.game_on(gameOn));

assign	SYNTHESIZED_WIRE_1 = passed2 | passed3 | passed1;

assign	point = SYNTHESIZED_WIRE_1 & gameOn;

assign	SYNTHESIZED_WIRE_2 =  ~resetN_pin;


print_screen_bit_map	b2v_inst30(
	.clk(clk),
	.resetN(resetN),
	.enable(enableStartScreen),
	.pixelX(pixelX),
	.pixelY(pixelY),
	.drawingRequest(startScreenDR),
	.RGBout(startScreenRGB));
	defparam	b2v_inst30.MIF_FILE = "RTL/start_screen320x240.mif";
	defparam	b2v_inst30.TOP_X = 192;
	defparam	b2v_inst30.TOP_Y = 112;


print_screen_bit_map	b2v_inst31(
	.clk(clk),
	.resetN(resetN),
	.enable(enableGameOverScreen),
	.pixelX(pixelX),
	.pixelY(pixelY),
	.drawingRequest(gameOverScreenDR),
	.RGBout(gameOverScreenRGB));
	defparam	b2v_inst31.MIF_FILE = "RTL/game_over320x240.mif";
	defparam	b2v_inst31.TOP_X = 192;
	defparam	b2v_inst31.TOP_Y = 112;


gap_mover	b2v_inst32(
	.clk(clk),
	.resetN(resetN),
	.objectsResetN(objectsResetN),
	.startOfFrame(startOfFrame),
	.game_on(gameOn),
	.bossActive(bossActive),
	.gapIn(gapTop1),
	.gapOut(gapOut1));
	defparam	b2v_inst32.GAP_MAX = 276;
	defparam	b2v_inst32.GAP_MIN = 32;
	defparam	b2v_inst32.GAP_SPEED = 1;


boss_detect	b2v_inst33(
	.hundreds(hundreds),
	.tens(tens),
	.bossActive(bossActive),
	.darkModeOn(darkModeOn));


gap_mover	b2v_inst34(
	.clk(clk),
	.resetN(resetN),
	.objectsResetN(objectsResetN),
	.startOfFrame(startOfFrame),
	.game_on(gameOn),
	.bossActive(bossActive),
	.gapIn(gapTop2),
	.gapOut(gapOut2));
	defparam	b2v_inst34.GAP_MAX = 276;
	defparam	b2v_inst34.GAP_MIN = 32;
	defparam	b2v_inst34.GAP_SPEED = 1;


gap_mover	b2v_inst35(
	.clk(clk),
	.resetN(resetN),
	.objectsResetN(objectsResetN),
	.startOfFrame(startOfFrame),
	.game_on(gameOn),
	.bossActive(bossActive),
	.gapIn(gapTop3),
	.gapOut(gapOut3));
	defparam	b2v_inst35.GAP_MAX = 276;
	defparam	b2v_inst35.GAP_MIN = 32;
	defparam	b2v_inst35.GAP_SPEED = 1;


background_object_block_t	b2v_inst36(
	.clk(clk),
	.resetN(resetN),
	.startOfFrame(startOfFrame),
	.Y_direction_key(keyIsPressed[8]),
	.toggle_x_key(enter),
	.gameOn(gameOn),
	.objectsResetN(objectsResetN),
	.pixelX(pixelX),
	.pixelY(pixelY),
	.speedBooost(speedBoost[7:0]),
	.backObjDR(backObj2DR),
	.backObjRGB(backObj2RGB));
	defparam	b2v_inst36.INITIAL_X = 204;
	defparam	b2v_inst36.INITIAL_X_SPEED = -140;
	defparam	b2v_inst36.INITIAL_Y = 35;
	defparam	b2v_inst36.INITIAL_Y_SPEED = 0;
	defparam	b2v_inst36.MIF_FILE = "RTL/sardines.mif";
	defparam	b2v_inst36.MIF_FILE_ = "RTL/sardines.mif";
	defparam	b2v_inst36.OBJECT_HEIGHT_Y_ = 64;
	defparam	b2v_inst36.OBJECT_WIDTH_X_ = 64;


back_ground_draw	b2v_inst4(
	.clk(clk),
	.resetN(resetN),
	.startOfFrame(startOfFrame),
	.game_on(gameOn),
	.address(address),
	.pixelX(pixelX),
	.pixelY(pixelY),
	.speedBoost(speedBoost),
	.BG_RGB(BG_RGB));
	defparam	b2v_inst4.BG_SPEED = 1;
	defparam	b2v_inst4.COLOR_MATRIX_LEFT_X = 30;
	defparam	b2v_inst4.COLOR_MATRIX_TOP_Y = 30;


audio_selector	b2v_inst5(
	.clk(clk),
	.resetN(resetN),
	.startScreen(enableStartScreen),
	.gameOver(enableGameOverScreen),
	
	.objectsResetN(objectsResetN),
	.game_on(gameOn),
	.melodySelect(SYNTHESIZED_WIRE_0));


score_counter	b2v_inst6(
	.clk(clk),
	.resetN(objectsResetN),
	.point(point),
	.hundreds(hundreds),
	.ones(ones),
	.tens(tens));


CLK_31P5	b2v_inst7(
	.refclk(CLOCK_50),
	.rst(SYNTHESIZED_WIRE_2),
	.outclk_0(clk),
	.locked(resetN));


best_score_display	b2v_inst8(
	.clk(clk),
	.resetN(resetN),
	.hundreds(hundreds),
	.ones(ones),
	.tens(tens),
	.HEX0(HEX0),
	.HEX1(HEX1),
	.HEX2(HEX2),
	.HEX3(HEX3),
	.HEX4(HEX4),
	.HEX5(HEX5));


pipes_block_t	b2v_inst9(
	.clk(clk),
	.resetN(resetN),
	.startOfFrame(startOfFrame),
	.gameOn(gameOn),
	.objectsResetN(objectsResetN),
	.gapTop(gapOut1),
	.pixelX(pixelX),
	.pixelY(pixelY),
	.speedBooost(speedBoost),
	.singlePipeDR(singlePipe1DR),
	.passed(passed1),
	.regenerate(regenerate1),
	.singlePipeRGB(singlePipe1RGB));
	defparam	b2v_inst9.INITIAL_PIPE_TYPE = 0;
	defparam	b2v_inst9.INITIAL_X = 500;
	defparam	b2v_inst9.INITIAL_X_SPEED = -128;
	defparam	b2v_inst9.INITIAL_Y = 0;
	defparam	b2v_inst9.INITIAL_Y_SPEED = 0;


square_object	b2v_ScoreSquareObject(
	.clk(clk),
	.resetN(resetN),
	.pixelX(pixelX),
	.pixelY(pixelY),
	.topLeftX(SCORE_topLeftX),
	.topLeftY(SCORE_topLeftY),
	.drawingRequest(boxDrawingRequest),
	.offsetX(Box_offsetX),
	.offsetY(Box_offsetY));
	defparam	b2v_ScoreSquareObject.OBJECT_COLOR = 8'b11111111;
	defparam	b2v_ScoreSquareObject.OBJECT_HEIGHT_Y = 32;
	defparam	b2v_ScoreSquareObject.OBJECT_WIDTH_X = 48;


endmodule
