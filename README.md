# Lyra-Drone-Synth-Norns (WIP)

**Note:** This is a Work in Progress! Currently in the early stages of building a SuperCollider engine, with plans to build a Monome Norns + Grid application around it. 

## Concept
This project is an experimental drone synthesizer heavily inspired by the "organismic" architecture of the Soma Laboratory Lyra-8. Instead of standard polyphony, it focuses on 8 interconnected oscillators that can continuously bleed into and modulate one another, creating massive, chaotic, and evolving textures.

## Architecture (The SuperCollider Engine)
The engine is built as a single, monolithic `SynthDef` (`\lyra_core`) rather than spawning new synths for every voice. This mimics a hardware device being constantly "on".

### 1. The Voices
* **8 Oscillators:** Powered by `VarSaw`, with the width parameter slowly modulated by `LFNoise2` for an organic, analog-drifting feel.
* **Envelopes & VCA:** Uses `Env.asr`. Each voice has a `gate` (for grid touch plates) and a `hold` (for continuous drone). 
* **Fast/Slow Release:** Each voice has a toggle (`relSwitches`) to switch between a quick, percussive release (0.3s) and a long, ambient fade-out (6.0s).

### 2. The Cross-FM Matrix
The core of the sound design is the feedback frequency modulation (Cross-FM) between oscillator pairs: (1&2), (3&4), (5&6), and (7&8).

To achieve this in digital DSP the SuperCollider UGens LocalOut.ar and LocalIn.ar are used:
* **`LocalOut.ar` / `LocalIn.ar`:** The raw oscillator outputs are sent to `LocalOut`, and read back via `LocalIn` on the *next audio sample* (a ~1.5ms delay). This solves the circular dependency problem where Voice 1 and Voice 2 need to know each other's current state simultaneously.

The actual cross-wiring is done via array indexing, which swaps the routing so Voice 1 is modulated by Voice 2, Voice 3 by Voice 4, and so on.:

```supercollider
var modulators = feedbackIn[[1, 0, 3, 2, 5, 4, 7, 6]];
```
### 3. Safety Mechanisms
Heavy feedback FM can easily cause math errors or silent crashes. This engine includes two safety nets:
* **`LeakDC.ar` inside the loop:** Heavy FM with asymmetrical waveforms creates a DC offset (the wave gets stuck above or below 0). If fed back into the FM loop, this offset multiplies endlessly. `LeakDC` scrubs the signal clean before it goes back into `LocalOut`.
* **Frequency `.clip(10, 15000)`:** Prevents the FM matrix from driving the oscillator frequency into negative values or above human hearing.

## Next Steps (Roadmap)
-  **Hyper LFO:** Implement a dual-LFO system where the LFOs can modulate each other, used for slowly drifting pitches and delay times.
-  **Dual Modulated Delay:** Build a PT2399-style dual delay network that can be modulated by the raw audio of the oscillators themselves.
-  **Norns Lua Script:** Map the SuperCollider parameters to the Norns screen, encoders, and Monome Grid.