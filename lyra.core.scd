s.boot;

(
SynthDef(\lyra_core, {
	arg out=0, amp=0.5, atk=0.1;

	var freqs = \freqs.kr([100, 105, 150, 155, 200, 205, 250, 255]);
	var gates = \gates.kr([0, 0, 0, 0, 0, 0, 0, 0]);
	var holds = \holds.kr([0, 0, 0, 0, 0, 0, 0, 0]);
	var relSwitches = \relSwitches.kr([0, 0, 0, 0, 0, 0, 0, 0]);
	var fmDepths = \fmDepths.kr([0, 0, 0, 0, 0, 0, 0, 0]);

	var fastRel = 0.3;
	var slowRel = 6.0;
	var relTimes = Select.kr(relSwitches, [fastRel, slowRel]);

	var activeGates = (gates + holds).clip(0, 1);
	var envs = EnvGen.ar(Env.asr(atk, 1.0, relTimes), activeGates);

	var feedbackIn = LocalIn.ar(8);
	var modulators = feedbackIn[[1, 0, 3, 2, 5, 4, 7, 6]];
	var modFreqs = freqs + (modulators * fmDepths * 1000).clip(10, 15000);
	var oscs = VarSaw.ar(modFreqs, 0, width: LFNoise2.kr(0.5 ! 8).range(0.2, 0.8));

	var cleanOscs = LeakDC.ar(oscs);
	var voices = cleanOscs * envs;
	var mixed = Splay.ar(voices);

	LocalOut.ar(cleanOscs);

	Out.ar(out, mixed * amp);
}).add;
)

x = Synth(\lyra_core);

// Testit

x.set(\gates, [1, 1, 0, 0, 0, 0, 0, 0]);
x.set(\gates, [0, 0, 0, 0, 0, 0, 1, 1]);
x.set(\gates, [1, 1, 0, 0, 0, 1, 1, 0]);
x.set(\gates, [0, 0, 0, 0, 0, 0, 0, 0]);

x.set(\holds, [0, 0, 0, 0, 1, 1, 0, 0]);
x.set(\holds, [0, 0, 0, 0, 0, 0, 0, 0]);

x.set(\relSwitches, [1, 1, 0, 0, 1, 1, 0, 0]);
x.set(\relSwitches, [0, 0, 0, 0, 0, 0, 0, 0]);

x.set(\fmDepths, [0.1, 0.2, 0, 0, 0.2, 0.3, 0.05, 0]);
x.set(\fmDepths, [0.2, 0.1, 0, 0, 0.3, 0.2, 0.1, 0]);
x.set(\fmDepths, [0, 0, 0, 0, 1, 1, 0, 0]);
x.set(\fmDepths, [0.5, 0.5, 0, 0, 0, 0, 0, 0]);
x.set(\fmDepths, [0.8, 0.8, 0, 0, 0, 0.8, 0.8, 0]);
x.set(\fmDepths, [0, 0, 0, 0, 0, 0, 0, 0]);

x.set(\freqs, [105, 102, 154, 156, 189, 201, 250, 257]);
x.set(\freqs, [100, 105, 150, 155, 200, 205, 250, 255]);
x.set(\freqs, [80, 100, 120, 140, 180, 200, 205, 255]);