## Field Dynamics

Field Dynamics studies motion as memory. A flow field is not treated as a background force but as a living topology that is continuously rewritten by the particles moving through it. The image is built from trajectories, and each trajectory is both a response and a trace.

The system is generated from a seeded vector field shaped by smooth noise and local curl. Particles sample that field, rotate through it, and advance in measured steps. No stroke attempts to dominate the frame; the composition emerges from many small directional decisions that gradually align into larger currents.

Randomness is present but constrained. `randomSeed(seed)` and `noiseSeed(seed)` lock the initial particle distribution and field structure, so identical seeds and parameters always reproduce the same work. Variation is introduced through seed changes and parameter shifts, not through uncontrolled per-frame chaos.

Accumulation is the central gesture. Instead of clearing the canvas each frame, the system applies a translucent veil, allowing older marks to persist and soften over time. This creates temporal depth: recent motion is sharp, older motion diffuses into atmosphere, and the whole piece reads as a history of flow rather than a single instant.

Its controls are deliberately structural. Particle count sets density, noise scale sets field granularity, step size sets temporal stride, trail alpha sets memory half-life, curl sets rotational tension, and palette shift remaps tonal temperature. Parameters do not decorate the image; they redefine the behavior that produces it.
