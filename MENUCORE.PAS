{ MENUCORE.PAS - Shared editor procedures and variables }

{ Load all games from data file }
procedure LoadGames;
var
  F: file of GameRecord;
  Game: GameRecord;
  MAX_RESULTS: Integer;
begin
  GameCount := 0;
  MAX_RESULTS := 200;  { Maximum matching games to keep in memory }
  
  Assign(F, DATAFILE);
  {$I-}
  Reset(F);
  {$I+}
  if IOResult <> 0 then
    Exit;
  
  { Scan file and load matching games }
  while (not EOF(F)) and (GameCount < MAX_RESULTS) do
  begin
    Read(F, Game);
    if not Game.Deleted and MatchesFilter(Game) then
    begin
      Inc(GameCount);
      Games^[GameCount] := Game;
    end;
  end;
  
  Close(F);
end;

{ Search dialog }
procedure DoSearch;
var
  Ch: Char;
  Done: Boolean;
begin
  ClrScr;
  TextColor(Yellow);
  GotoXY(1, 10);
  Write('Enter search text (partial title match): ');
  TextColor(White);
  
  { Simple input }
  SearchStr := '';
  Done := False;
  repeat
    Ch := ReadKey;
    if Ch = #13 then Done := True;
    if Ch = #27 then begin SearchStr := ''; Done := True; end;
    if (Ch = #8) and not Done then
    begin
      if Length(SearchStr) > 0 then
      begin
        Delete(SearchStr, Length(SearchStr), 1);
        Write(#8, ' ', #8);
      end;
    end
    else if (Ch >= ' ') and not Done then
    begin
      SearchStr := SearchStr + UpCase(Ch);
      Write(UpCase(Ch));
    end;
  until Done;
  
  { Reload with new filter }
  LoadGames;
  CurrentIndex := 1;
  TopIndex := 1;
end;

procedure DrawBox(X1, Y1, X2, Y2: Integer; Title: string);
var
  I: Integer;
begin
  GotoXY(X1, Y1);
  Write(#218);
  for I := X1 + 1 to X2 - 1 do Write(#196);
  Write(#191);
  
  if Title <> '' then
  begin
    GotoXY(X1 + 2, Y1);
    Write(' ', Title, ' ');
  end;
  
  for I := Y1 + 1 to Y2 - 1 do
  begin
    GotoXY(X1, I); Write(#179);
    GotoXY(X2, I); Write(#179);
  end;
  
  GotoXY(X1, Y2);
  Write(#192);
  for I := X1 + 1 to X2 - 1 do Write(#196);
  Write(#217);
end;

function VideoModeFlagsToStr(VideoFlags: Byte) : String; 
var
  S: String;
begin
    S := '';
    if (VideoFlags and GFX_HERC) <> 0 then S := S + 'Hercules, ';
    if (VideoFlags and GFX_CGA) <> 0 then S := S + 'CGA, ';
    if (VideoFlags and GFX_TANDY) <> 0 then S := S + 'Tandy, ';
    if (VideoFlags and GFX_EGA) <> 0 then S := S + 'EGA, ';
    if (VideoFlags and GFX_VGA) <> 0 then S := S + 'VGA, ';
    if (VideoFlags and GFX_SVGA) <> 0 then S := S + 'SVGA, ';
    if Length(S) > 2 then Delete(S, Length(S)-1, 2);

    VideoModeFlagsToStr := S;
end;

{ Display the game list }
procedure DisplayGameList;
const
  FIRST_GAME_ROW = 4;
  LAST_GAME_ROW = 23; { was 20, now 3 more rows }
  MAX_DISPLAY = LAST_GAME_ROW - FIRST_GAME_ROW + 1;
var
  I, Row: Integer;
  DisplayCount: Integer;
begin
  ClrScr;
  
  { Title }
  TextColor(White);
  TextBackground(Blue);
  GotoXY(1, 1);
  Write(' DOS Game Launcher');
  ClrEol;
  TextBackground(Black);

  { Draw game list box at the very top }
  DrawBox(1, 2, 80, 24, ''); { was 21, now 24 for 3 more rows }

  { Column headers just inside the box }
  GotoXY(3, 3);
  TextColor(White);
  Write('CD');
  GotoXY(6, 3);
  Write('Title');
  GotoXY(46, 3);
  Write('Publisher');
  GotoXY(73, 3);
  Write('Year');
  TextColor(LightGray);

  { Adjust TopIndex so CurrentIndex is always visible }
  if CurrentIndex < TopIndex then
    TopIndex := CurrentIndex;
  if CurrentIndex > TopIndex + MAX_DISPLAY - 1 then
    TopIndex := CurrentIndex - MAX_DISPLAY + 1;
  if TopIndex < 1 then TopIndex := 1;
  if TopIndex > GameCount - MAX_DISPLAY + 1 then
    TopIndex := GameCount - MAX_DISPLAY + 1;
  if TopIndex < 1 then TopIndex := 1;

  { Calculate how many games to display on this page }
  DisplayCount := GameCount - TopIndex + 1;
  if DisplayCount > MAX_DISPLAY then
    DisplayCount := MAX_DISPLAY;

  for I := 1 to DisplayCount do
  begin
    Row := FIRST_GAME_ROW - 1 + I;
    if TopIndex + I - 1 = CurrentIndex then
    begin
      TextBackground(Cyan);
      TextColor(Black);
      GotoXY(3, Row);
      Write('                                                                   ');
      GotoXY(3, Row);
    end
    else
    begin
      TextBackground(Black);
      TextColor(LightGray);
      GotoXY(3, Row);
      Write('                                                                   ');
      GotoXY(3, Row);
    end;
    if Games^[TopIndex + I - 1].RequiresCD then
      Write('CD ')
    else
      Write('   ');
    Write(Copy(Games^[TopIndex + I - 1].Title, 1, 39));
    GotoXY(46, Row);
    Write(Copy(Games^[TopIndex + I - 1].Publisher, 1, 26));
    GotoXY(73, Row);
    Write(Games^[TopIndex + I - 1].Year);
    TextBackground(Black);
    TextColor(LightGray);
  end;

  { Clear remaining rows }
  TextBackground(Black);
  for I := DisplayCount + 1 to MAX_DISPLAY do
  begin
    Row := FIRST_GAME_ROW - 1 + I;
    GotoXY(3, Row);
    Write('                                                                      ');
  end;
  
  { Scroll indicators }
  if TopIndex > 1 then
  begin
    GotoXY(78, FIRST_GAME_ROW);
    TextColor(White);
    Write('^');
    TextColor(LightGray);
  end;
  if TopIndex + DisplayCount - 1 < GameCount then
  begin
    GotoXY(78, FIRST_GAME_ROW - 1 + DisplayCount);
    TextColor(White);
    Write('V');
    TextColor(LightGray);
  end;

  { Status bar }
  TextColor(White);
  TextBackground(Black);
  GotoXY(1, 25);
  ClrEol;
end;

{ Launch selected game }
procedure LaunchGame;
var
  Game: GameRecord;
  CmdLine: string;
  F: Text;
  PathStr: string;

begin
  if (GameCount = 0) or (CurrentIndex < 1) or (CurrentIndex > GameCount) then
    Exit;
  
  Game := Games^[CurrentIndex];
  
  ClrScr;
  TextColor(White);
  WriteLn('Launching: ', Game.Title);
  WriteLn('Path: ', Game.Path);
  if Game.RequiresCD then
  begin
    TextColor(Yellow);
    WriteLn('NOTE: This game requires a CD in the drive');
  end;
  WriteLn;
  
  Assign(F, 'RUN.BAT');
  Rewrite(F);
  { Remove trailing spaces from Game.Path for TP5.5 compatibility }
  PathStr := Game.Path;
  while (Length(PathStr) > 0) and (PathStr[Length(PathStr)] = ' ') do
    Delete(PathStr, Length(PathStr), 1);
  WriteLn(F, '@ECHO OFF');
  if PathStr <> '' then
    WriteLn(F, 'CD ', PathStr);
  if Game.SlowdownSU > 0 then
  begin
    if Game.Args <> '' then
      WriteLn(F, 'SLOWDOWN /S:', Game.SlowdownSU, ' ', Game.Command, ' ', Game.Args)
    else
      WriteLn(F, 'SLOWDOWN /S:', Game.SlowdownSU, ' ', Game.Command);
  end
  else
  begin
    if Game.Args <> '' then
      WriteLn(F, Game.Command, ' ', Game.Args)
    else
      WriteLn(F, Game.Command);
  end;
  Close(F);
  ClrScr;
  TextColor(White);
  WriteLn('RUN.BAT has been created.');
  WriteLn('Call RUN to launch the game.');

  WriteLn;
  Halt(0); { Fully exit launcher after writing batch file }
     
end;

{ Genre selection menu }
function SelectGenre(Current: Byte): Byte;
var
  Selected: Byte;
  Ch: Char;
  Done: Boolean;
  I, Row: Integer;
begin
  Selected := Current;
  Done := False;
  
  repeat
    ClrScr;
    TextColor(Yellow);
    WriteLn('Select Genre (use arrow keys, ENTER to confirm, ESC to cancel)');
    WriteLn;
    
    { Display genre list in two columns }
    for I := 0 to 14 do
    begin
      Row := I + 3;
      
      { Left column }
      if I = Selected then
      begin
        TextBackground(Cyan);
        TextColor(Black);
      end
      else
      begin
        TextBackground(Black);
        TextColor(LightGray);
      end;
      
      GotoXY(2, Row);
      Write(I:2, '. ', GenreNames[I]);
      
      { Right column }
      if I + 15 <= 28 then
      begin
        if I + 15 = Selected then
        begin
          TextBackground(Cyan);
          TextColor(Black);
        end
        else
        begin
          TextBackground(Black);
          TextColor(LightGray);
        end;
        
        GotoXY(42, Row);
        Write(I + 15:2, '. ', GenreNames[I + 15]);
      end;
    end;
    
    TextBackground(Black);
    TextColor(White);
    
    Ch := ReadKey;
    if Ch = #0 then
    begin
      Ch := ReadKey;
      case Ch of
        #72: if Selected > 0 then Dec(Selected);  { Up }
        #80: if Selected < 28 then Inc(Selected);  { Down }
        #75: if Selected >= 15 then Dec(Selected, 15);  { Left }
        #77: if Selected < 14 then Inc(Selected, 15);  { Right }
      end;
    end
    else
      case Ch of
        #13: Done := True;  { Enter }
        #27: begin Selected := Current; Done := True; end;  { Esc }
        '0'..'9': begin
          { Direct number entry for quick selection }
          if Ch <= '2' then
          begin
            Selected := Ord(Ch) - Ord('0');
            if Selected <= 28 then Done := True;
          end;
        end;
      end;
  until Done;
  
  SelectGenre := Selected;
end;


{ Toggle sound flags }
function SelectSoundFlags(Current: Byte): Byte;
var
  Ch: Char;
  Flags: Byte;
  Done: Boolean;
begin
  Flags := Current;
  Done := False;
  
  repeat
    ClrScr;
    TextColor(Yellow);
    WriteLn('Sound Hardware Tags (press letter to toggle, ENTER when done)');
    WriteLn;
    
    TextColor(LightGray);
    Write('[P] PC Speaker    ');
    if (Flags and SND_PCSPK) <> 0 then begin TextColor(LightGreen); Write('[X]'); end else Write('[ ]');
    WriteLn;
    
    TextColor(LightGray);
    Write('[T] Tandy/PCjr    ');
    if (Flags and SND_TANDY) <> 0 then begin TextColor(LightGreen); Write('[X]'); end else Write('[ ]');
    WriteLn;
    
    TextColor(LightGray);
    Write('[S] CMS/Game Blaster ');
    if (Flags and SND_CMS) <> 0 then begin TextColor(LightGreen); Write('[X]'); end else Write('[ ]');
    WriteLn;
    
    TextColor(LightGray);
    Write('[A] AdLib         ');
    if (Flags and SND_ADLIB) <> 0 then begin TextColor(LightGreen); Write('[X]'); end else Write('[ ]');
    WriteLn;
    
    TextColor(LightGray);
    Write('[M] MT-32         '); 
    if (Flags and SND_MT32) <> 0 then begin TextColor(LightGreen); Write('[X]'); end else Write('[ ]');
    WriteLn;
    
    TextColor(LightGray);
    Write('[B] Sound Blaster ');
    if (Flags and SND_SB) <> 0 then begin TextColor(LightGreen); Write('[X]'); end else Write('[ ]');
    WriteLn;
    
    TextColor(LightGray);
    Write('[D] Covox/DSS     ');
    if (Flags and SND_COVOX) <> 0 then begin TextColor(LightGreen); Write('[X]'); end else Write('[ ]');
    WriteLn;
    
    Ch := UpCase(ReadKey);
    case Ch of
      'P': Flags := Flags xor SND_PCSPK;
      'T': Flags := Flags xor SND_TANDY;
      'S': Flags := Flags xor SND_CMS;
      'A': Flags := Flags xor SND_ADLIB;
      'M': Flags := Flags xor SND_MT32;
      'B': Flags := Flags xor SND_SB;
      'D': Flags := Flags xor SND_COVOX;
      #13: Done := True;
      #27: begin Flags := Current; Done := True; end;
    end;
  until Done;
  
  SelectSoundFlags := Flags;
end;


{ Edit FM sound flags (90s era) }
function SelectFMMusicFlags(Current: Byte): Byte;
var
  Ch: Char;
  Flags: Byte;
  Done: Boolean;
begin
  Flags := Current;
  Done := False;
  
  repeat
    ClrScr;
    TextColor(Yellow);
    WriteLn('FM/Digital Sound Hardware (90s era)');
    WriteLn('Press letter to toggle, ENTER when done');
    WriteLn;
    
    TextColor(LightGray);
    Write('[B] Sound Blaster     ');
    if (Flags and SND_FM_SB) <> 0 then begin TextColor(LightGreen); Write('[X]'); end else Write('[ ]');
    WriteLn;
    
    TextColor(LightGray);
    Write('[P] SB Pro (stereo)   ');
    if (Flags and SND_FM_SBPRO) <> 0 then begin TextColor(LightGreen); Write('[X]'); end else Write('[ ]');
    WriteLn;
    
    TextColor(LightGray);
    Write('[1] SB16 (16-bit)     ');
    if (Flags and SND_FM_SB16) <> 0 then begin TextColor(LightGreen); Write('[X]'); end else Write('[ ]');
    WriteLn;
    
    TextColor(LightGray);
    Write('[W] AWE32/64          ');
    if (Flags and SND_FM_AWE) <> 0 then begin TextColor(LightGreen); Write('[X]'); end else Write('[ ]');
    WriteLn;
    
    TextColor(LightGray);
    Write('[A] Pro Audio Spectrum ');
    if (Flags and SND_FM_PAS) <> 0 then begin TextColor(LightGreen); Write('[X]'); end else Write('[ ]');
    WriteLn;
    
    TextColor(LightGray);
    Write('[6] PAS16             ');
    if (Flags and SND_FM_PAS16) <> 0 then begin TextColor(LightGreen); Write('[X]'); end else Write('[ ]');
    WriteLn;
    
    Ch := UpCase(ReadKey);
    case Ch of
      'B': Flags := Flags xor SND_FM_SB;
      'P': Flags := Flags xor SND_FM_SBPRO;
      '1': Flags := Flags xor SND_FM_SB16;
      'W': Flags := Flags xor SND_FM_AWE;
      'A': Flags := Flags xor SND_FM_PAS;
      '6': Flags := Flags xor SND_FM_PAS16;
      #13: Done := True;
      #27: begin Flags := Current; Done := True; end;
    end;
  until Done;
  
  SelectFMMusicFlags := Flags;
end;

{ Edit MIDI/Wavetable sound flags }
function SelectMidiMusicFlags(Current: Byte): Byte;
var
  Ch: Char;
  Flags: Byte;
  Done: Boolean;
begin
  Flags := Current;
  Done := False;
  
  repeat
    ClrScr;
    TextColor(Yellow);
    WriteLn('MIDI/Wavetable Sound Hardware (90s era)');
    WriteLn('Press letter to toggle, ENTER when done');
    WriteLn;
    
    TextColor(LightGray);
    Write('[3] Roland MT-32         ');
    if (Flags and SND_MIDI_MT32) <> 0 then begin TextColor(LightGreen); Write('[X]'); end else Write('[ ]');
    WriteLn;

    TextColor(LightGray);
    Write('[6] Roland CM-64         ');
    if (Flags and SND_MIDI_CM64) <> 0 then begin TextColor(LightGreen); Write('[X]'); end else Write('[ ]');
    WriteLn;
    
    TextColor(LightGray);
    Write('[M] SC-55 / General MIDI ');
    if (Flags and SND_MIDI_SC55) <> 0 then begin TextColor(LightGreen); Write('[X]'); end else Write('[ ]');
    WriteLn;
    
    TextColor(LightGray);
    Write('[G] Gravis Ultrasound   ');
    if (Flags and SND_MIDI_GUS) <> 0 then begin TextColor(LightGreen); Write('[X]'); end else Write('[ ]');
    WriteLn;
    
    TextColor(LightGray);
    Write('[E] ESS AudioDrive      ');
    if (Flags and SND_MIDI_ESS) <> 0 then begin TextColor(LightGreen); Write('[X]'); end else Write('[ ]');
    WriteLn;
    
    TextColor(LightGray);
    Write('[S] Ensoniq Soundscape  ');
    if (Flags and SND_MIDI_SSCAPE) <> 0 then begin TextColor(LightGreen); Write('[X]'); end else Write('[ ]');
    WriteLn;
    
    Ch := UpCase(ReadKey);
    case Ch of
      '3': Flags := Flags xor SND_MIDI_MT32;
      '6': Flags := Flags xor SND_MIDI_CM64;
      'M': Flags := Flags xor SND_MIDI_SC55;
      'G': Flags := Flags xor SND_MIDI_GUS;
      'E': Flags := Flags xor SND_MIDI_ESS;
      'S': Flags := Flags xor SND_MIDI_SSCAPE;
      #13: Done := True;
      #27: begin Flags := Current; Done := True; end;
    end;
  until Done;
  
  SelectMidiMusicFlags := Flags;
end;

function SoundFlagsToStr(SoundFlags: Byte) : String; 
var
  S: String;
begin
    S := '';
    if (SoundFlags and SND_PCSPK) <> 0 then S := S + 'PC Speaker, ';
    if (SoundFlags and SND_TANDY) <> 0 then S := S + 'Tandy, ';
    if (SoundFlags and SND_CMS) <> 0 then S := S + 'CMS/Game Blaster, ';
    if (SoundFlags and SND_ADLIB) <> 0 then S := S + 'AdLib, ';
    if (SoundFlags and SND_MT32) <> 0 then S := S + 'MT-32, ';
    if (SoundFlags and SND_SB) <> 0 then S := S + 'Sound Blaster, ';
    if (SoundFlags and SND_COVOX) <> 0 then S := S + 'Covox/DSS, ';
    if Length(S) > 2 then Delete(S, Length(S)-1, 2);

    SoundFlagsToStr := S;
end;


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

procedure DisplayGameDetail(Game: GameRecord);
begin
    ClrScr;
    TextColor(White);
    GotoXY(1, 1); Write('========================================');
    GotoXY(1, 2); Write('           ', Game.Title);
    GotoXY(1, 3); Write('----------------------------------------');
    TextColor(LightGray);
    GotoXY(1, 5); Write('Publisher:      ', Game.Publisher);
    GotoXY(1, 6); Write('Year:           ', Game.Year);
    GotoXY(1, 7); Write('Genre:          ', GenreCodeToName(Game.GenreCode));
    GotoXY(1, 8); Write('Sound:          ', SoundFlagsToStr(Game.SoundFlags));
    GotoXY(1, 9); Write('Video:          ', VideoModeFlagsToStr(Game.GraphicsFlags));
    GotoXY(1, 10); Write('Path:           ', Game.Path);
    GotoXY(1, 11); Write('Command:        ', Game.Command);
    GotoXY(1, 12); Write('Arguments:      ', Game.Args);
    GotoXY(1, 13); Write('Requires CD:    ');
    if Game.RequiresCD then Write('Yes') else Write('No');
end;

procedure DisplayGameDetail486(Game: GameRecord);
begin
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
end;