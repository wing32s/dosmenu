{ MENU486.PAS - DOS Game Launcher for 386/486/Pentium Systems }

program GameLauncher486;

uses Crt, Dos, GameType;

const
  FIRST_GAME_ROW = 4;
  LAST_GAME_ROW = 23; { was 20, now 3 more rows }
  MAX_DISPLAY = LAST_GAME_ROW - FIRST_GAME_ROW + 1;
  MAX_RESULTS = 200;  { Maximum matching games to keep in memory }

type
  GameArray = array[1..MAX_RESULTS] of GameRecord;
  
var
  Games: ^GameArray;
  GameCount: Integer;
  CurrentIndex: Integer;
  TopIndex: Integer;
  SearchStr: string;
  FilterPublisher: String30;
  FilterGenreCode: Byte;
  FilterYear: string[4];
  FilterFM: Byte;      { FM/Digital sound filter }
  FilterMIDI: Byte;    { MIDI/Wavetable filter }
  Quit: Boolean;
  Ch: Char;


{ Check if a game matches current filters }
function MatchesFilter(Game: GameRecord): Boolean;
var
  Match: Boolean;
begin
  Match := True;
  
  { Search string filter }
  if SearchStr <> '' then
    Match := Match and (Pos(SearchStr, Game.Title) > 0);
  
  { Publisher filter }
  if FilterPublisher <> '' then
    Match := Match and (Game.Publisher = FilterPublisher);
  
  { Genre filter }
  if FilterGenreCode <> 0 then
    Match := Match and (Game.GenreCode = FilterGenreCode);
  
  { Year filter }
  if FilterYear <> '' then
    Match := Match and (Game.Year = FilterYear);
  
  { FM sound filter (must have ANY selected flags) }
  if FilterFM <> 0 then
    Match := Match and ((Game.SoundFM and FilterFM) <> 0);
  
  { MIDI sound filter (must have ANY selected flags) }
  if FilterMIDI <> 0 then
    Match := Match and ((Game.SoundMIDI and FilterMIDI) <> 0);
  
  { Not deleted }
  Match := Match and (not Game.Deleted);
  
  MatchesFilter := Match;
end;

{$I MENUCORE.PAS}  { Include the shared editor procedures }

{ Convert FM sound flags to string }
function SoundFMToStr(SoundFlags: Byte) : String; 
var
  S: String;
begin
    S := '';
    if (SoundFlags and SND_FM_SB) <> 0 then S := S + 'Sound Blaster, ';
    if (SoundFlags and SND_FM_SBPRO) <> 0 then S := S + 'Sound Blaster Pro, ';
    if (SoundFlags and SND_FM_SB16) <> 0 then S := S + 'Sound Blaster 16, ';
    if (SoundFlags and SND_FM_AWE) <> 0 then S := S + 'Sound Blaster AWE, ';
    if (SoundFlags and SND_FM_PAS) <> 0 then S := S + 'Pro Audio Spectrum, ';
    if (SoundFlags and SND_FM_PAS16) <> 0 then S := S + 'Pro Audio Spectrum 16, ';
    if Length(S) > 2 then Delete(S, Length(S)-1, 2);

    SoundFMToStr := S;
end;

{ Convert MIDI sound flags to string }
function SoundMIDIToStr(Flags: Byte): string;
var
  S: string;
begin
  S := '';
  if (Flags and SND_MIDI_MT32) <> 0 then S := S + 'Roland MT-32, ';
  if (Flags and SND_MIDI_CM64) <> 0 then S := S + 'Roland CM-64, ';
  if (Flags and SND_MIDI_SC55) <> 0 then S := S + 'General MIDI, ';
  if (Flags and SND_MIDI_GUS) <> 0 then S := S + 'Gravis Ultrasound, ';
  if (Flags and SND_MIDI_ESS) <> 0 then S := S + 'ESS Audiodrive, ';
  if (Flags and SND_MIDI_SSCAPE) <> 0 then S := S + 'Ensoniq Soundscape, ';
  if Length(S) > 2 then Delete(S, Length(S)-1, 2);

  SoundMIDIToStr := S;
end;


{ Filter dialog }
procedure DoFilter;
var
  S: string;
  Ch: Char;
  Done: Boolean;
begin
  Done := False;
  repeat
    ClrScr;
    TextColor(Yellow);
    WriteLn('=== Set Filters ===');
    WriteLn;
    TextColor(LightGray);
    WriteLn('1. Publisher: ', FilterPublisher);
    WriteLn('2. Genre: ', GenreCodeToName(FilterGenreCode));
    WriteLn('3. Year: ', FilterYear);
    WriteLn('4. FM Music: ', SoundFMToStr(FilterFM));
    WriteLn('5. MIDI Music: ', SoundMIDIToStr(FilterMIDI));
    WriteLn('6. Clear all filters');
    WriteLn('Q. Done');
    WriteLn;
    TextColor(White);
    Write('Select option (1-5,Q): ');
    Ch := UpCase(ReadKey);
    WriteLn(Ch);
    case Ch of
      '1': begin
        Write('Enter publisher (blank=none): ');
        ReadLn(S);
        FilterPublisher := S;
      end;
      '2': begin
        FilterGenreCode := SelectGenre(0);
      end;
      '3': begin
        Write('Enter year (blank=none): ');
        ReadLn(S);
        FilterYear := S;
      end;
      '4': begin
        FilterFM := SelectFMMusicFlags(0);
      end;
      '5': begin
        FilterMIDI := SelectMidiMusicFlags(0);
      end;      
      '6': begin
        FilterPublisher := '';
        FilterGenreCode := 0;
        FilterYear := '';
        FilterFM := 0;
        FilterMIDI := 0;
      end;
      'Q': Done := True;
    end;
    LoadGames;
    CurrentIndex := 1;
    TopIndex := 1;
  until Done;
end;


{ Show game details }
procedure ShowGameDetails(Index: Integer);
var
  Game: GameRecord;
  S: string;
  Ch: Char;
begin
  if (Index < 1) or (Index > GameCount) then Exit;
  Game := Games^[Index];
  repeat
    ClrScr;
    TextColor(White);
    GotoXY(1, 1); Write('========================================');
    GotoXY(1, 2); Write('           ', Game.Title);
    GotoXY(1, 3); Write('----------------------------------------');
    TextColor(LightGray);
    GotoXY(1, 5); Write('Publisher:      ', Game.Publisher);
    GotoXY(1, 6); Write('Year:           ', Game.Year);
    GotoXY(1, 7); Write('Genre:          ', GenreCodeToName(Game.GenreCode));
    GotoXY(1, 8); Write('FM Music:       ', SoundFMToStr(Game.SoundFM));
    GotoXY(1, 9); Write('MIDI Music:     ', SoundMIDIToStr(Game.SoundMIDI));
    GotoXY(1, 10); Write('Video:          ', VideoModeFlagsToStr(Game.GraphicsFlags));
    GotoXY(1, 11); Write('Path:           ', Game.Path);
    GotoXY(1, 12); Write('Command:        ', Game.Command);
    GotoXY(1, 13); Write('Arguments:      ', Game.Args);
    GotoXY(1, 14); Write('Requires CD:    ');
    if Game.RequiresCD then Write('Yes') else Write('No');
    GotoXY(1, 15); Write('Slowdown Speed (SU): ', Game.SlowdownSU);

    TextColor(White);
    GotoXY(1, 17); Write('[L] Launch Game      [Esc] Return to Menu');
    GotoXY(1, 18); Write('========================================');
    Ch := UpCase(ReadKey);
    if Ch = 'L' then
    begin
      LaunchGame;
      Exit;
    end;
    if Ch = #27 then Exit;
  until False;
end;

{ Main program }
begin
  { Allocate memory for games }
  New(Games);
  
  { Initialize }
  SearchStr := '';
  FilterPublisher := '';
  FilterGenreCode := 0;
  FilterYear := '';
  FilterFM := 0;
  FilterMIDI := 0;
  CurrentIndex := 1;
  TopIndex := 1;
  Quit := False;
  
  { Load initial game list }
  LoadGames;
  
  if GameCount = 0 then
  begin
    ClrScr;
    WriteLn('No games found in ', DATAFILE);
    WriteLn('Run EDIT486.EXE to add games.');
    WriteLn;
    Write('Press any key...');
    Ch := ReadKey;    
    Halt(0);
  end;
  
  { Main loop }
  repeat
    DisplayGameList;
    Write('ENTER=Launch  D=Details  F=Filter  S=Search  Q=Quit  Games: ', GameCount);
    ClrEol;

    case UpCase(ReadKey) of
      #0: begin  { Extended key }
        case ReadKey of
          #72: begin  { Up arrow }
            if CurrentIndex > 1 then
            begin
              Dec(CurrentIndex);
              if CurrentIndex < TopIndex then
                TopIndex := CurrentIndex;
            end;
          end;
          #80: begin  { Down arrow }
            if CurrentIndex < GameCount then
            begin
              Inc(CurrentIndex);
              if CurrentIndex >= TopIndex + MAX_DISPLAY then
                TopIndex := CurrentIndex - MAX_DISPLAY + 1;
            end;
          end;
        end;
      end;
      #13: LaunchGame;  { Enter }
      'F': DoFilter;
      'S': DoSearch;
      'D': ShowGameDetails(CurrentIndex);
      'Q': Quit := True;
    end;
  until Quit;
  
  { Cleanup }
  Dispose(Games);
  ClrScr;
end.
