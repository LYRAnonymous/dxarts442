/*
Project Title: projectSimplePlayBuf
Date: Wed Jan 29 13:48:27 2025

DXARTS 46x: Sound Series Tutorial
Authors: Joseph Anderson, Wei Yang, et al.
Affiliation: DXARTS, University of Washington (https://dxarts.washington.edu/)
License: GPLv3 (https://www.gnu.org/licenses/gpl-3.0.en.html)
*/

///////////////// Set RT environment variables ///////////////

(
// Clear environment and load dependencies
currentEnvironment.clear;
(Document.current.dir +/+ "functions.scd").load;
(Document.current.dir +/+ "synthDefs.scd").load;
)

(

// currentEnvironment.clear;

// Setup MIDI
MIDIIn.connectAll;
// MIDIFunc.trace;

// Setup server

Server.killAll;

~server = Server.default;

~serverOptions = ServerOptions.new;
~serverOptions.numOutputBusChannels_(2).memSize_(2**21);

~server.options(~serverOptions);
~server.boot;
~server.newAllocators;
~server.waitForBoot({

	// Collect soundFiles and instance CtkBuffers
	~sounds = SoundFile.collect(Document.current.dir +/+ "sounds/*");

	~buffers = Dictionary.newFrom(
		~sounds.collect({ |item|
			var itemPath = item.path;
			[
				PathName.new(itemPath).fileNameWithoutExtension.replace(".", "_").asSymbol,
				CtkBuffer.playbuf(itemPath)
			]
		}).flatten
	);

	// Load buffers onto server
	~buffers.do({|buffer, i| buffer.load(sync: false)});
	~server.sync;

	// Add SynthDefs to server
	~synths.do({|synthDef, i| synthDef.add});


	// Iterative note events
	// Buses
	// ~ctrlBuses[\randomWew].play;
	// ~controls[\randomWew].note.rate_(1.0).min_(-5.0).max_(5.0).outBus_(~ctrlBuses[\randomWew]).play;

	~sourceNotes = 10.collect({~synths[\stereoPlayBuf].note(addAction: \head)
		.gain_(-18.0).bufnum_(~buffers.choose.bufnum).loop_(1).outBus_(~fxBuses[\reverb]).play});

	~midiRate = MIDIFunc.cc({ |val, num, chan, src|
		~sourceNotes.do({|note, i| note.rate_(ControlSpec(0.25, 4, 'exp').map(val.linlin(0, 127, 0, 1)))})
    }, ccNum: 16);

	~midiPan = MIDIFunc.cc({ |val, num, chan, src|
		~sourceNotes.do({|note, i| note.pan_(ControlSpec(-1, 1, 'lin').map(val.linlin(0, 127, 0, 1)))})
    }, ccNum: 17);

	// Run through reverb bus
	~delay = ~effects[\reverb].note(addAction: \tail)
	.inBus_(~fxBuses[\reverb]).outBus_(0).play;

});
)

// Killswitch
(
(~sourceNotes ++ ~delay).do({|note, i| note.release});
~buffers.free;
Server.killAll;
)

~server.plotTree;