# DOS Game Launcher

A lightweight game launcher for DOS systems, designed to run on IBM PC XT and compatibles.

## Features

- Fast binary database supporting large game libraries
- Search and filter by title, publisher, year, genre, and sound hardware
- Built-in editor for managing game entries
- Additive sound tag filtering (MT-32, SC-55, Sound Blaster, AdLib, PC Speaker)
- Minimal memory footprint - exits completely before launching games

## Building

### Requirements
- **Turbo Pascal 5.5 or later** (Turbo Pascal 7.0 recommended)
- The code uses standard TP features and should compile on any TP 5.5+ compiler

### Turbo Pascal
```
REM For 80s/XT systems:
tpc MENU.PAS
tpc EDIT.PAS

REM For 486+ systems:
tpc MENU486.PAS
tpc EDIT486.PAS
```

Or simply run `BUILD.BAT` to compile all executables.

## Usage

### 80s/XT Systems (MENU.EXE)
1. Run `EDIT.EXE` to add your first game
2. Configure legacy sound options (PC Speaker, Tandy, AdLib, MT-32, etc.)
3. Run `MENU.EXE` to browse and launch games

### 486+ Systems (MENU486.EXE)
1. Run `EDIT486.EXE` to add games
2. Configure extended sound options (SB16, GUS, AWE32, etc.)
3. Set CPU slowdown if needed for speed-sensitive games
4. Run `MENU486.EXE` with dual FM/MIDI filtering

Add `MENU` (or `MENU486`) to your PATH in AUTOEXEC.BAT for easy return after game exit.

### Importing from LaunchBox

Use the Python importer on a modern PC to bulk-import metadata:
```bash
python lbimport.py LaunchBox.xml GAMES.DAT
```

This creates `LBMAP.DAT` which maps your games to LaunchBox IDs for reliable re-imports. After first import, re-running uses exact ID matching instead of fuzzy title matching.

## File Formats

### GAMES.DAT
Games are stored as fixed-size binary records (256 bytes each):
- Title: 50 chars
- Path: 80 chars
- Command: 13 chars (8.3 filename)
- Arguments: 60 chars
- Sound flags (legacy): 1 byte (80s era sound)
- Sound flags (FM): 1 byte (90s FM/digital)
- Sound flags (MIDI): 1 byte (90s MIDI/wavetable)
- Graphics flags: 1 byte (video modes)
- Publisher: 30 chars
- Year: 4 chars
- Genre code: 1 byte (0-28, see genre list below)
- Slowdown SU: 2 bytes (Word, for SLOWDOWN utility)
- Requires CD: 1 byte (boolean flag)
- Deleted flag: 1 byte

### LBMAP.DAT (Optional)
LaunchBox mapping records (48 bytes each):
- Game Index: 2 bytes (position in GAMES.DAT, 1-based)
- Database ID: 4 bytes (LaunchBox DatabaseID)
- GUID: 37 bytes (LaunchBox GUID string)

This file is created automatically by the LaunchBox importer and enables exact matching on subsequent imports. Not required for menu operation.

## Sound Flags

### Legacy Sound (Byte 1 - 80s era, MENU.PAS)
- Bit 0: PC Speaker (P)
- Bit 1: Tandy/PCjr (T)
- Bit 2: CMS / Game Blaster (S)
- Bit 3: AdLib (A)
- Bit 4: MT-32 (M)
- Bit 5: Sound Blaster (B)
- Bit 6: Covox/Disney Sound Source (D)

### FM/Digital Sound (Byte 2 - 90s era, MENU486.PAS)
- Bit 0: Sound Blaster (B)
- Bit 1: SB Pro (P)
- Bit 2: SB16 (16)
- Bit 3: AWE32/64 (W)
- Bit 4: Pro Audio Spectrum (A)
- Bit 5: PAS16 (A16)

### MIDI/Wavetable (Byte 3 - 90s era, MENU486.PAS)
- Bit 0: MT-32 (M)
- Bit 1: SC-55 / General MIDI (C)
- Bit 2: Gravis Ultrasound (G)
- Bit 3: ESS AudioDrive (E)
- Bit 4: Ensoniq Soundscape (S)

Flags are additive - games often support multiple sound cards. MT-32 and Sound Blaster appear in both legacy and 90s bytes for dual-menu compatibility.

## Graphics Flags

Organized from most primitive to most advanced:

- Bit 0: Hercules (H) - Monochrome graphics
- Bit 1: CGA (C) - 4-color
- Bit 2: Tandy/PCjr (T) - 16-color enhanced
- Bit 3: EGA (E) - 16-color, better resolution
- Bit 4: VGA (V) - 256-color
- Bit 5: SVGA (S) - High-res (640x480+)

Many games support multiple modes (e.g., King's Quest 4: CGA + Tandy + EGA + VGA). Tandy graphics often look significantly better than CGA.

## Genre Codes

Genre is stored as a single byte (0-28) for efficiency:

0. (None) | 1. Action | 2. Adventure | 3. Beat 'em Up | 4. Board Game
5. Casino | 6. Compilation | 7. Construction and Management Simulation
8. Education | 9. Fighting | 10. Flight Simulator | 11. Horror
12. Life Simulation | 13. MMO | 14. Music | 15. Party | 16. Pinball
17. Platform | 18. Puzzle | 19. Quiz | 20. Racing | 21. Role-Playing
22. Sandbox | 23. Shooter | 24. Sports | 25. Stealth | 26. Strategy
27. Vehicle Simulation | 28. Visual Novel

The editor provides a full menu to select genres by name. This saves 19 bytes per record compared to storing the string.
