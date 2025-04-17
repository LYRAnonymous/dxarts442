/*
Project Title: projectSimplePlayBuf
Date: Wed Jan 29 13:48:27 2025

DXARTS 46x: Sound Series Tutorial
Authors: Joseph Anderson, Wei Yang, et al.
Affiliation: DXARTS, University of Washington (https://dxarts.washington.edu/)
License: GPLv3 (https://www.gnu.org/licenses/gpl-3.0.en.html)
*/

// -------------------------
// Instantiate CtkProtoNotes

~synths = CtkProtoNotes.new;
~effects = CtkProtoNotes.new;
~controls = CtkProtoNotes.new;
~ctrlBuses = Dictionary();
~fxBuses = Dictionary();

// -------------------------
// Add SynthDefs

~synths.add(
	/*
	Enveloped stereo PlayBuf
	*/
	SynthDef(
		\stereoPlayBuf,

		{ |gain = 0.0, loop = 0, bufnum = 0, gate = 1, outBus = 0|

            // Nodes
            var ampEnvSig;
            var playBufSig;
            var panSig;
            var outSig;

            // Control
			var numChannels = 2;
            var amp = gain.dbamp;

			// ----
			// Synthesis

			// Amplitude envelope
			ampEnvSig = EnvGen.kr(
				Env([0, 1, 1, 0], [0.1, 1.0, 2.0], \sin, 2),
				gate,
				levelScale: amp,
				doneAction: 2
			);

			// Sample playback
			playBufSig = PlayBuf.ar(numChannels, bufnum, BufRateScale.kr(bufnum) * 'rate'.kr(1.0, 0.1), loop: loop);

			// Apply envelope
			playBufSig = playBufSig * ampEnvSig;

			// Stereo imager
			panSig = Balance2.ar(playBufSig[0], playBufSig[1], 'pan'.kr(0.0, 0.1));

			// Assign to out
			outSig = panSig;

			Out.ar(outBus, outSig)
		}
	)
);

~ctrlBuses[\randomWew] = CtkControl.new(2, server: ~server);
~controls.add(
	SynthDef(
		\randomWew,

		{ |rate = 1, min = -1.0, max = 1.0, outBus|
			Out.kr(outBus, LFNoise2.ar(rate).range(min, max))
		}
	)
);

~fxBuses[\reverb] = CtkAudio.new(2, server: ~server);
~effects.add(
	SynthDef(
		\reverb,

		{  |inBus = 0, gain = 0.0,
			reverbMix = 0.33, reverbRoom = 0.5, reverbDamp = 0.5,
			outBus = 0|

			var inSig = In.ar(inBus, 2);
			Out.ar(outBus, FreeVerb2.ar(inSig[0], inSig[1], reverbMix, reverbRoom, reverbDamp, gain.dbamp))
		}
	)
);
