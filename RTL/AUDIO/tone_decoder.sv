/// (c) Technion IIT, Department of Electrical Engineering 2021
//-- This module  generate the correet prescaler tones for a single ocatave

//-- Dudy Feb 12 2019
//-- Eyal Lev --change values to 31.5 MHz   Apr 2023
//-- Eyal Lev --change values to OCTAVA  6   Nov 2024
module	tone_decoder	(
					input	logic [3:0] tone,
					input	logic [2:0] octave,
					output	logic [11:0]	preScaleValue
		);

//---------------VALUES for 31.5MHz clock, Base Octava (1) ------------------------
	logic [0:11] [11:0] preScaleValueTable = '{
		12'heb3, // C	(2093.0 Hz) (2090 Hz = 31,500,000 / 256 / 3763 (i.e. 0xeb))
		12'hddf, // C#	(2217.5 Hz)
		12'hd18, // D	(2349.3 Hz)
		12'hc5c, // D#	(2489.0 Hz)
		12'hbaa, // E	(2637.0 Hz)
		12'hb03, // F	(2793.8 Hz)
		12'ha65, // F#	(2960.0 Hz)
		12'h9cf, // G	(3136.0 Hz)
		12'h942, // G#	(3322.4 Hz)
		12'h8bd, // A	(3520.0 Hz)
		12'h840, // A#	(3729.3 Hz)
		12'h7c9  // B	(3951.1 Hz)

	};

// tone select the specific song from the table to be played
assign 	preScaleValue = preScaleValueTable[tone] >> octave;

endmodule
