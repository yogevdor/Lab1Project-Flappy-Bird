`begin_keywords "1364-2005"
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
// CREATED		"Fri Nov 20 18:45:44 2026"

module TOP_KBD(
	resetN,
	PS2_CLK,
	PS2_DAT,
	CLOCK_50,
	keyPadValid,
	Plus,
	back,
	slash,
	del,
	enter,
	minus,
	star,
	num,
	keyIsPressed,
	keyPad
);


input wire	resetN;
input wire	PS2_CLK;
input wire	PS2_DAT;
input wire	CLOCK_50;
output wire	keyPadValid;
output wire	Plus;
output wire	back;
output wire	slash;
output wire	del;
output wire	enter;
output wire	minus;
output wire	star;
output wire	num;
output wire	[9:0] keyIsPressed;
output wire	[3:0] keyPad;

wire	brake;
wire	clk;
wire	[8:0] keyCode;
wire	make;





KBDINTF	b2v_inst(
	.CLOCK_50(clk),
	.resetN(resetN),
	.PS2_CLK(PS2_CLK),
	.PS2_DAT(PS2_DAT),
	.make(make),
	.break(brake),
	.keyCode(keyCode));


keyPad_decoder	b2v_inst2(
	.clk(clk),
	.resetN(resetN),
	.make(make),
	.brakee(brake),
	.keyCode(keyCode),
	.plus(Plus),
	.Back(back),
	.slash(slash),
	.del(del),
	.enter(enter),
	.minus(minus),
	.star(star),
	.num(num),
	.keyIsValid(keyPadValid),
	.key(keyPad),
	.NumberKey(keyIsPressed));

assign	clk = CLOCK_50;

endmodule
`end_keywords
