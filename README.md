# Snake Lua (Playdate)

This repository contains a complete Playdate Lua project for a Snake game, including source code, metadata, and built output artifacts. The project is structured for local development and quick testing in the Playdate simulator.

## Project Overview

- `source/main.lua`: Main game logic, state handling, rendering, input, and audio feedback.
- `source/pdxinfo`: Playdate app metadata used during build.
- `builds/main.pdx/`: Built game package output.
- `builds/buildsFolder.txt`: Build folder marker/config helper file.

The game implementation includes:

- Title, options, gameplay, game-over, and win states.
- Configurable speed presets, including a progressive challenge mode.
- Score tracking, collision detection, and food spawning.
- Simple synthesized sound effects for movement, eating, and collisions.

## Options

You can select game speed from the Options screen:

- Slow
- Normal
- Fast
- Challenge (speed increases every 4 food pickups)

## Button Functions

### Title Screen

- D-pad: Move direction during gameplay (shown as control hint)
- A: Start game
- B: Open options

### Options Screen

- Up/Down: Change selected speed
- A: Confirm and return to title
- B: Back to title

### During Gameplay

- D-pad: Change snake direction

### Game Over

- A: Restart
- B: Return to title menu

### Win Screen

- A: Restart
