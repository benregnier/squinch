# squinch
monome norns/crow midi to cv looper

squinch was developed as a way to quickly bring little sequences into modular from a midi controller. It brings the feature set of a dual audio looper to midi and CV messages, allowing users to play with loop start and end points, reversing, etc, as well as a "decay" feature that slowly lowers velocity over time. I've also implemented variable quantization per loop; quantization is input only so you can start with sequences on rigid quantization and then add in looser notes on top, or have one loop quantized and the other unquantized, etc. Using crow, it can output a wide variety of cv outs.

INPUTS
squinch currently accepts all midi inputs without filtering - filters are planned for a future release. It records note on and velocity from note events - similar to awake note off is not used (note off being problematic with the looper function). There is also limited cc recording that is currently used only to play with the cutoff of the engine. 
The crow CV inputs are planned for future control of the envelope outs.

OUTPUTS
Audio: squinch uses the "PolyPerc" engine to output audio directly. Currently the cutoff parameter is exposed to global cc input per loop.
CV: using crow, squinch can output many different cv outputs:
  - v/oct outputs pitch cv
  - velocity outputs velocity values (0 to 8v)
  - trigger outputs 100ms triggers with a variable voltage scaled by velocity (1v to 8v)
  - gate outputs variable 5v gates scaled by velocity (100 to 500 ms)
  - envelope outputs an exponential envelope with a fixed vertical attack and decay scaled by velocity (100 ms to 500 ms)
MIDI: this is not yet implemented, but I plan to bring in a method similar to how MIDI is done on Awake, with note off delayed by metro.

CONTROLS:
When you start squinch you will see two sets of two lines, each set representing a single loop with one midi time step per pixel. Each bar represents 4 beats. Loops use the norns clock and are 8 beats with 32 time steps per beat, for a total of 256 steps. At the bottom of the screen are decay and quantization for the current loop. Controls work as follows:

-- enc 1: select active loop - active loop will highlight
-- enc 2: decay - decay determines the amount of velocity drop between "reads" of each step
-- enc 2 (alt): loop start
-- enc 2: quantization, shown in fractions of each bar (eg as if each beat is a quarter note). This affects both note input as well as the loop start and stop modification.
-- enc 2 (alt): loop end
-- key 1 (hold): activate alt functions when held
-- key 2: sync active loop with non-active loop
-- key 3: reverse active loop

FUTURE DEVELOPMENTS
midi out
better control over envelopes
better parameter control in norns
better cc implementation
