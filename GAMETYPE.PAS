{ GAMETYPES.PAS - Shared data structures for DOS Game Launcher }

unit GameType;

interface

{ Helper function to convert genre name to code }
function GenreNameToCode(Name: string): Byte;

{ Helper function to get genre name from code }
function GenreCodeToName(Code: Byte): string;

{ Helper function to convert string to uppercase }
function UpperStr(S: string): string;

const
  DATAFILE = 'GAMES.DAT';
  RECORD_SIZE = 256;
  
  MAPFILE = 'LBMAP.DAT';
  MAP_RECORD_SIZE = 48;
  
  { Sound flag bits - Byte 1: Legacy (80s era, for MENU.PAS) }
  SND_PCSPK  = $01;  { Bit 0: PC Speaker }
  SND_TANDY  = $02;  { Bit 1: Tandy/PCjr }
  SND_CMS    = $04;  { Bit 2: Creative Music System / Game Blaster }
  SND_ADLIB  = $08;  { Bit 3: AdLib }
  SND_MT32   = $10;  { Bit 4: Roland MT-32 }
  SND_SB     = $20;  { Bit 5: Sound Blaster }
  SND_COVOX  = $40;  { Bit 6: Covox/Disney Sound Source }
  
  { Sound flag bits - Byte 2: FM/Digital (90s era, for MENU486.PAS) }
  SND_FM_SB      = $01;  { Bit 0: Sound Blaster }
  SND_FM_SBPRO   = $02;  { Bit 1: Sound Blaster Pro }
  SND_FM_SB16    = $04;  { Bit 2: Sound Blaster 16 }
  SND_FM_AWE     = $08;  { Bit 3: AWE32/64 }
  SND_FM_PAS     = $10;  { Bit 4: Pro Audio Spectrum }
  SND_FM_PAS16   = $20;  { Bit 5: Pro Audio Spectrum 16 }
  
  { Sound flag bits - Byte 3: MIDI/Wavetable (90s era, for MENU486.PAS) }
  SND_MIDI_MT32  = $01;  { Bit 0: Roland MT-32 }
  SND_MIDI_CM64  = $02;  { Bit 1: Roland CM-64 }
  SND_MIDI_SC55  = $04;  { Bit 2: Roland SC-55 / General MIDI }
  SND_MIDI_GUS   = $08;  { Bit 3: Gravis Ultrasound }
  SND_MIDI_ESS   = $10;  { Bit 4: ESS AudioDrive }
  SND_MIDI_SSCAPE = $20; { Bit 5: Ensoniq Soundscape }
  
  { Graphics flag bits - organized primitive to advanced }
  GFX_HERC   = $01;  { Bit 0: Hercules (mono graphics) }
  GFX_CGA    = $02;  { Bit 1: CGA (4-color) }
  GFX_TANDY  = $04;  { Bit 2: Tandy/PCjr Graphics (16-color) }
  GFX_EGA    = $08;  { Bit 3: EGA (16-color) }
  GFX_VGA    = $10;  { Bit 4: VGA (256-color) }
  GFX_SVGA   = $20;  { Bit 5: SVGA (high-res 640x480+) }
  
  { Genre codes (LaunchBox compatible) }
  GENRE_NONE = 0;
  GENRE_ACTION = 1;
  GENRE_ADVENTURE = 2;
  GENRE_BEAT_EM_UP = 3;
  GENRE_BOARD_GAME = 4;
  GENRE_CASINO = 5;
  GENRE_COMPILATION = 6;
  GENRE_CONSTRUCTION_SIM = 7;
  GENRE_EDUCATION = 8;
  GENRE_FIGHTING = 9;
  GENRE_FLIGHT_SIM = 10;
  GENRE_HORROR = 11;
  GENRE_LIFE_SIM = 12;
  GENRE_MMO = 13;
  GENRE_MUSIC = 14;
  GENRE_PARTY = 15;
  GENRE_PINBALL = 16;
  GENRE_PLATFORM = 17;
  GENRE_PUZZLE = 18;
  GENRE_QUIZ = 19;
  GENRE_RACING = 20;
  GENRE_ROLE_PLAYING = 21;
  GENRE_SANDBOX = 22;
  GENRE_SHOOTER = 23;
  GENRE_SPORTS = 24;
  GENRE_STEALTH = 25;
  GENRE_STRATEGY = 26;
  GENRE_VEHICLE_SIM = 27;
  GENRE_VISUAL_NOVEL = 28;
  
  GenreNames: array[0..28] of string = (
    '(None)',
    'Action',
    'Adventure',
    'Beat ''em Up',
    'Board Game',
    'Casino',
    'Compilation',
    'Construction and Management Simulation',
    'Education',
    'Fighting',
    'Flight Simulator',
    'Horror',
    'Life Simulation',
    'MMO',
    'Music',
    'Party',
    'Pinball',
    'Platform',
    'Puzzle',
    'Quiz',
    'Racing',
    'Role-Playing',
    'Sandbox',
    'Shooter',
    'Sports',
    'Stealth',
    'Strategy',
    'Vehicle Simulation',
    'Visual Novel'
  );

type
  String13 = string[13];
  String20 = string[20];
  String30 = string[30];
  String50 = string[50];
  String60 = string[60];
  String80 = string[80];
  
  GameRecord = record
    Title: String50;      { Game title }
    Path: String80;       { Directory path }
    Command: String13;    { Executable/batch file (8.3 format) }
    Args: String60;       { Command line arguments }
    SoundFlags: Byte;     { Bit flags for legacy sound (80s) }
    SoundFM: Byte;        { Bit flags for FM/digital sound (90s) }
    SoundMIDI: Byte;      { Bit flags for MIDI/wavetable (90s) }
    GraphicsFlags: Byte;  { Bit flags for graphics modes }
    Publisher: String30;  { Publisher name }
    Year: string[4];      { Year (e.g., "1987") }
    GenreCode: Byte;      { Genre code (0-28, see GENRE_* constants) }
    SlowdownSU: Word;     { SLOWDOWN /S:XXX value (0=none) }
    RequiresCD: Boolean;  { True if game needs CD in drive }
    Deleted: Boolean;     { Soft delete flag }
  end;
  
  { LaunchBox mapping record - stores relationship between GAMES.DAT and LaunchBox }
  LaunchBoxMapping = record
    GameIndex: Word;      { Position in GAMES.DAT (1-based, 0=unused) }
    DatabaseID: LongInt;  { LaunchBox DatabaseID }
    GUID: string[36];     { LaunchBox GUID }
  end;

implementation

{ Convert string to uppercase - TP 5.5 UpCase only works on chars }
function UpperStr(S: string): string;
var
  I: Integer;
begin
  for I := 1 to Length(S) do
    S[I] := UpCase(S[I]);
  UpperStr := S;
end;

function GenreNameToCode(Name: string): Byte;
var
  I: Integer;
  Upper: string;
begin
  Upper := UpperStr(Name);
  
  { Check for exact matches (case-insensitive) }
  for I := 0 to 28 do
    if UpperStr(GenreNames[I]) = Upper then
    begin
      GenreNameToCode := I;
      Exit;
    end;
  
  { Check for partial matches / common aliases }
  if Pos('ACTION', Upper) > 0 then
    GenreNameToCode := GENRE_ACTION
  else if Pos('ADVENTURE', Upper) > 0 then
    GenreNameToCode := GENRE_ADVENTURE
  else if (Pos('BEAT', Upper) > 0) or (Pos('BRAWL', Upper) > 0) then
    GenreNameToCode := GENRE_BEAT_EM_UP
  else if Pos('BOARD', Upper) > 0 then
    GenreNameToCode := GENRE_BOARD_GAME
  else if Pos('CASINO', Upper) > 0 then
    GenreNameToCode := GENRE_CASINO
  else if Pos('COMPILATION', Upper) > 0 then
    GenreNameToCode := GENRE_COMPILATION
  else if (Pos('CONSTRUCTION', Upper) > 0) or (Pos('MANAGEMENT', Upper) > 0) or 
          (Pos('SIM', Upper) > 0) then
    GenreNameToCode := GENRE_CONSTRUCTION_SIM
  else if Pos('EDUCATION', Upper) > 0 then
    GenreNameToCode := GENRE_EDUCATION
  else if Pos('FIGHTING', Upper) > 0 then
    GenreNameToCode := GENRE_FIGHTING
  else if Pos('FLIGHT', Upper) > 0 then
    GenreNameToCode := GENRE_FLIGHT_SIM
  else if Pos('HORROR', Upper) > 0 then
    GenreNameToCode := GENRE_HORROR
  else if Pos('LIFE', Upper) > 0 then
    GenreNameToCode := GENRE_LIFE_SIM
  else if (Pos('MMO', Upper) > 0) or (Pos('ONLINE', Upper) > 0) then
    GenreNameToCode := GENRE_MMO
  else if Pos('MUSIC', Upper) > 0 then
    GenreNameToCode := GENRE_MUSIC
  else if Pos('PARTY', Upper) > 0 then
    GenreNameToCode := GENRE_PARTY
  else if Pos('PINBALL', Upper) > 0 then
    GenreNameToCode := GENRE_PINBALL
  else if Pos('PLATFORM', Upper) > 0 then
    GenreNameToCode := GENRE_PLATFORM
  else if Pos('PUZZLE', Upper) > 0 then
    GenreNameToCode := GENRE_PUZZLE
  else if Pos('QUIZ', Upper) > 0 then
    GenreNameToCode := GENRE_QUIZ
  else if Pos('RACING', Upper) > 0 then
    GenreNameToCode := GENRE_RACING
  else if (Pos('ROLE', Upper) > 0) or (Pos('RPG', Upper) > 0) then
    GenreNameToCode := GENRE_ROLE_PLAYING
  else if Pos('SANDBOX', Upper) > 0 then
    GenreNameToCode := GENRE_SANDBOX
  else if (Pos('SHOOT', Upper) > 0) or (Pos('FPS', Upper) > 0) then
    GenreNameToCode := GENRE_SHOOTER
  else if Pos('SPORT', Upper) > 0 then
    GenreNameToCode := GENRE_SPORTS
  else if Pos('STEALTH', Upper) > 0 then
    GenreNameToCode := GENRE_STEALTH
  else if Pos('STRATEG', Upper) > 0 then
    GenreNameToCode := GENRE_STRATEGY
  else if Pos('VEHICLE', Upper) > 0 then
    GenreNameToCode := GENRE_VEHICLE_SIM
  else if Pos('VISUAL', Upper) > 0 then
    GenreNameToCode := GENRE_VISUAL_NOVEL
  else
    GenreNameToCode := GENRE_NONE;
end;

function GenreCodeToName(Code: Byte): string;
begin
  if Code <= 28 then
    GenreCodeToName := GenreNames[Code]
  else
    GenreCodeToName := GenreNames[0];
end;

end.
