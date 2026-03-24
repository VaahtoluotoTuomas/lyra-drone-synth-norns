s.boot;

(
SynthDef(\lyra_core, {
	arg out=0, amp=0.5, atk=0.1;

	// --- PARAMETERS ---
	var freqs = \freqs.kr([100, 105, 150, 155, 200, 205, 250, 255]);
	var gates = \gates.kr([0, 0, 0, 0, 0, 0, 0, 0]);
	var holds = \holds.kr([0, 0, 0, 0, 0, 0, 0, 0]);
	var relSwitches = \relSwitches.kr([0, 0, 0, 0, 0, 0, 0, 0]);
	var fmDepths = \fmDepths.kr([0, 0, 0, 0, 0, 0, 0, 0]); // audio rate fm pairs modulation amount

	// --- DUAL LFO PARAMETERS
	var lfoFreqA = \lfoFreqA.kr(0.5);
	var lfoFreqB = \lfoFreqB.kr(0.2);
	var lfoCrossMod = \lfoCrossMod.kr(0.0); // (0.0 - 1.0)
	var lfoPitchDepths = \lfoPitchDepths.kr([0, 0, 0, 0, 0, 0, 0, 0]); // lfo pitch effect

	// --- TAPE DELAY PARAMETERS
	var dlyTime = \dlyTime.kr(0.4); // in seconds
	var dlyFb = \dlyFb.kr(0.4); // (0.0 - 1.0)
	var dlyMix = \dlyMix.kr(0.3); // (0.0 - 1.0)
	var dlyLfoMod = \dlyLfoMod.kr(0.02); // tape echo wobble

	// --- VCA & ENVELOPES ---
	var fastRel = 0.3;
	var slowRel = 6.0;
	var relTimes = Select.kr(relSwitches, [fastRel, slowRel]);

	var activeGates = (gates + holds).clip(0, 1);
	var envs = EnvGen.ar(Env.asr(atk, 1.0, relTimes), activeGates);

	// --- HYPER LFO BLOCK
	var lfoFeedback = LocalIn.kr(2);
	var lfoModA = lfoFeedback[1];
	var lfoModB = lfoFeedback[0];

	var lfoA = LFTri.kr(lfoFreqA + (lfoModA * lfoCrossMod * 5));
	var lfoB = LFTri.kr(lfoFreqB + (lfoModB * lfoCrossMod * 5));
	var hyperLfo = (lfoA + lfoB) * 0.5;

	// --- LOCALIN.AR BUSSES ---
	var localIn = LocalIn.ar(10);
	var fmFeedbackIn = localIn[0..7]; // oscillators
	var delayFbIn = localIn[8..9]; // delay channels

	// --- SOUND SOURCES & CROSS MODULATION ---

	var modulators = fmFeedbackIn[[1, 0, 3, 2, 5, 4, 7, 6]];

	var lfoEffect = hyperLfo * lfoPitchDepths * 50;
	var modFreqs = (freqs + lfoEffect + (modulators * fmDepths * 1000)).clip(10, 15000);

	var oscs = VarSaw.ar(modFreqs, 0, width: LFNoise2.kr(0.5 ! 8).range(0.2, 0.8));
	var cleanOscs = LeakDC.ar(oscs);

	var voices = cleanOscs * envs;
	var mixed = Splay.ar(voices);

	// --- TAPE DELAY ---
	var timeL = (dlyTime + (hyperLfo * dlyLfoMod)).clip(0.01, 2.0);
	var timeR = (dlyTime + (hyperLfo * dlyLfoMod * -1.2)).clip(0.01, 2.0);

	var safeFb = dlyFb.clip(0.0, 0.99);

	var inL = mixed[0] + (delayFbIn[0] * safeFb);
	var inR = mixed[1] + (delayFbIn[1] * safeFb);

	var delayL = DelayL.ar(inL, maxdelaytime: 2.0, delaytime: timeL);
	var delayR = DelayL.ar(inR, maxdelaytime: 2.0, delaytime: timeR);

	var wetL = LPF.ar(delayL, 2000);
	var wetR = LPF.ar(delayR, 2000);

	var finalOut = (mixed * (1.0 - dlyMix)) + ([wetL, wetR] * dlyMix);

	// --- SAFETY LIMITER ---
	finalOut = Limiter.ar(finalOut, 0.95);

	// --- FM FEEDBACK SENDS ---
	LocalOut.kr([lfoA, lfoB]);
	LocalOut.ar(cleanOscs ++ [wetL, wetR]);

	Out.ar(out, finalOut * amp);
}).add;
)

x = Synth(\lyra_core);

// Testit

x.set(\gates, [1, 1, 0, 0, 0, 0, 0, 0]);
x.set(\gates, [1, 1, 1, 1, 0, 0, 0, 0]);
x.set(\gates, [0, 0, 0, 0, 0, 0, 1, 1]);
x.set(\gates, [1, 1, 0, 0, 0, 1, 1, 0]);
x.set(\gates, [0, 0, 0, 0, 0, 0, 0, 0]);

x.set(\holds, [0, 0, 0, 0, 1, 1, 0, 0]);
x.set(\holds, [0, 0, 0, 0, 0, 0, 0, 0]);

x.set(\relSwitches, [1, 1, 0, 0, 1, 1, 0, 0]);
x.set(\relSwitches, [0, 0, 0, 0, 0, 0, 0, 0]);

x.set(\dlyFb, 0.2);
x.set(\dlyFb, 0.4);
x.set(\dlyFb, 0.5);
x.set(\dlyFb, 0.6);
x.set(\dlyFb, 0.85);
x.set(\dlyFb, 0.0);

x.set(\dlyLfoMod, 0.02);
x.set(\dlyLfoMod, 0.1);
x.set(\dlyLfoMod, 0.2);
x.set(\dlyLfoMod, 0.4);

x.set(\fmDepths, [0.1, 0.2, 0.2, 0.1, 0.2, 0.3, 0.05, 0]);
x.set(\fmDepths, [0.2, 0.1, 0,1, 0,1, 0.3, 0.2, 0.1, 0]);
x.set(\fmDepths, [0, 0, 0, 0, 1, 1, 0, 0]);
x.set(\fmDepths, [0.5, 0.5, 0, 0, 0, 0, 0, 0]);
x.set(\fmDepths, [0.8, 0.8, 0, 0, 0, 0.8, 0.8, 0]);
x.set(\fmDepths, [0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.01, 0]);
x.set(\fmDepths, [0.01, 0.01, 0.01, 0.01, 0.1, 0.1, 0.01, 0]);
x.set(\fmDepths, [0, 0, 0, 0, 0, 0, 0, 0]);

x.set(\lfoPitchDepths, [1.0, 1.0, 0, 0, 0, 0, 0, 0]);
x.set(\lfoPitchDepths, [0.3, 0.3, 0.3, 0.3, 0, 0, 0, 0]);
x.set(\lfoPitchDepths, [0.5, 0.4, 0.3, 0.7, 0, 0, 0, 0]);
x.set(\lfoPitchDepths, [0.7, 0.2, 0.5, 0.4, 0, 0, 0, 0]);
x.set(\lfoPitchDepths, [0.1, 0.1, 0.1, 0.1, 0, 0, 0, 0]);

x.set(\lfoCrossMod, 1.0);
x.set(\lfoCrossMod, 0.85);
x.set(\lfoCrossMod, 0.45);
x.set(\lfoCrossMod, 0.20);
x.set(\lfoCrossMod, 0.10);

x.set(\lfoFreqA, 56.0);
x.set(\lfoFreqB, 42.4);

x.set(\lfoFreqA, 4.0);
x.set(\lfoFreqB, 6.4);


x.set(\freqs, [105, 102, 154, 156, 189, 201, 250, 257]);
x.set(\freqs, [100, 105, 150, 155, 200, 205, 250, 255]);
x.set(\freqs, [80, 100, 120, 140, 180, 200, 205, 255]);