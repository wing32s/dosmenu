{ EDIT486.PAS - Game Database Editor for 386/486/Pentium Systems }
{ Extends EDIT.PAS with FM/MIDI sound options and CPU slowdown support }

program GameEditor486;

uses Crt, Dos, GameType;

const
  MAX_GAMES = 250;  { Maximum games (256 bytes × 250 = 64000 bytes) }

type
  GameArray = array[1..MAX_GAMES] of GameRecord;
  PositionArray = array[1..MAX_GAMES] of LongInt;

var
  Games: ^GameArray;
  FilePositions: ^PositionArray;  { File position for each loaded game }
  GameCount: Integer;
  CurrentIndex: Integer;
  TopIndex: Integer;
  SearchStr: string;  { Title filter }
  Quit: Boolean;

{ Check if a game matches current filters }
function MatchesFilter(Game: GameRecord): Boolean;
begin
  MatchesFilter := True;
end;

{$I MENUCORE.PAS}  { Include the shared editor procedures }
{$I EDITCORE.PAS}  { Include the shared editor procedures }

{ Graphics editor - included from EDIT.PAS }
function EditGraphicsFlags(Current: Byte): Byte;
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
    WriteLn('Graphics Modes (press letter to toggle, ENTER when done)');
    WriteLn;
    
    TextColor(LightGray);
    Write('[H] Hercules (mono)  ');
    if (Flags and GFX_HERC) <> 0 then begin TextColor(LightGreen); Write('[X]'); end else Write('[ ]');
    WriteLn;
    
    TextColor(LightGray);
    Write('[C] CGA (4-color)    ');
    if (Flags and GFX_CGA) <> 0 then begin TextColor(LightGreen); Write('[X]'); end else Write('[ ]');
    WriteLn;
    
    TextColor(LightGray);
    Write('[T] Tandy/PCjr (16)  ');
    if (Flags and GFX_TANDY) <> 0 then begin TextColor(LightGreen); Write('[X]'); end else Write('[ ]');
    WriteLn;
    
    TextColor(LightGray);
    Write('[E] EGA (16-color)   ');
    if (Flags and GFX_EGA) <> 0 then begin TextColor(LightGreen); Write('[X]'); end else Write('[ ]');
    WriteLn;
    
    TextColor(LightGray);
    Write('[V] VGA (256-color)  ');
    if (Flags and GFX_VGA) <> 0 then begin TextColor(LightGreen); Write('[X]'); end else Write('[ ]');
    WriteLn;
    
    TextColor(LightGray);
    Write('[S] SVGA (hi-res)    ');
    if (Flags and GFX_SVGA) <> 0 then begin TextColor(LightGreen); Write('[X]'); end else Write('[ ]');
    WriteLn;
    
    Ch := UpCase(ReadKey);
    case Ch of
      'H': Flags := Flags xor GFX_HERC;
      'C': Flags := Flags xor GFX_CGA;
      'T': Flags := Flags xor GFX_TANDY;
      'E': Flags := Flags xor GFX_EGA;
      'V': Flags := Flags xor GFX_VGA;
      'S': Flags := Flags xor GFX_SVGA;
      #13: Done := True;
      #27: begin Flags := Current; Done := True; end;
    end;
  until Done;
  
  EditGraphicsFlags := Flags;
end;

{ Input a Word value }
function InputWord(Prompt: string; Default: Word): Word;
var
  S, DefaultStr: string;
  Ch: Char;
  Value: Word;
  Code: Integer;
  Done: Boolean;
begin
  Write(Prompt);
  Str(Default, DefaultStr);
  S := DefaultStr;
  Write(S);
  
  Done := False;
  repeat
    Ch := ReadKey;
    if Ch = #13 then Done := True;
    if Ch = #27 then begin S := DefaultStr; Done := True; end;
    if (Ch = #8) and not Done then
    begin
      if Length(S) > 0 then
      begin
        Delete(S, Length(S), 1);
        Write(#8, ' ', #8);
      end;
    end
    else if (Ch >= '0') and (Ch <= '9') and (Length(S) < 5) and not Done then
    begin
      S := S + Ch;
      Write(Ch);
    end;
  until Done;
  
  Val(S, Value, Code);
  if Code <> 0 then Value := Default;
  InputWord := Value;
end;

{ Add or edit a game entry - EXTENDED VERSION }
procedure EditEntry486(Index: Integer; IsNew: Boolean);
var
  Game: GameRecord;
  F: file of GameRecord;
  I: Integer;
  Ch: Char;
begin
  if IsNew then
  begin
    FillChar(Game, SizeOf(Game), 0);
    Game.Deleted := False;
    Game.SlowdownSU := 0;
  end
  else
    Game := Games^[Index];
  
  ClrScr;
  TextColor(White);
  if IsNew then
    WriteLn('=== Add New Game (486+ Edition) ===')
  else
    WriteLn('=== Edit Game (486+ Edition) ===');
  WriteLn;
  
  TextColor(LightGray);
  Game.Title := InputString('Title: ', 50, Game.Title);
  WriteLn;
  
  Game.Path := InputString('Path (e.g., C:\GAMES\DOOM): ', 80, Game.Path);
  WriteLn;
  
  Game.Command := InputString('Command (.EXE or .BAT): ', 13, Game.Command);
  WriteLn;
  
  Game.Args := InputString('Arguments (optional): ', 60, Game.Args);
  WriteLn;
  
  WriteLn('Press any key to configure legacy sound...');
  Ch := ReadKey;
  Game.SoundFlags := SelectSoundFlags(Game.SoundFlags);
  
  WriteLn('Press any key to configure FM/Digital sound (90s)...');
  Ch := ReadKey;
  Game.SoundFM := SelectFMMusicFlags(Game.SoundFM);
  
  WriteLn('Press any key to configure MIDI/Wavetable sound (90s)...');
  Ch := ReadKey;
  Game.SoundMIDI := SelectMidiMusicFlags(Game.SoundMIDI);  
  WriteLn('Press any key to configure graphics modes...');
  Ch := ReadKey;
  Game.GraphicsFlags := EditGraphicsFlags(Game.GraphicsFlags);  
  ClrScr;
  TextColor(White);
  WriteLn('Optional Information:');
  WriteLn;
  
  TextColor(LightGray);
  Game.Publisher := InputString('Publisher: ', 30, Game.Publisher);
  WriteLn;
  
  Game.Year := InputString('Year (YYYY): ', 4, Game.Year);
  WriteLn;
  
  WriteLn('Press any key to select genre...');
  Ch := ReadKey;
  Game.GenreCode := SelectGenre(Game.GenreCode);
  
  ClrScr;
  TextColor(White);
  WriteLn('Selected Genre: ', GenreCodeToName(Game.GenreCode));
  WriteLn;
  
  TextColor(LightGray);
  Write('Requires CD in drive? (Y/N): ');
  if Game.RequiresCD then Write('[Y] ') else Write('[N] ');
  if UpCase(ReadKey) = 'Y' then
    Game.RequiresCD := True
  else
    Game.RequiresCD := False;
  WriteLn;
  WriteLn;
  
  TextColor(Yellow);
  WriteLn('CPU Slowdown (for speed-sensitive games):');
  TextColor(LightGray);
  Game.SlowdownSU := InputWord('SLOWDOWN /S:XXX value (0=none): ', Game.SlowdownSU);
  WriteLn;
  WriteLn;
    
  DisplayGameDetail486(Game);
  GotoXY(1, 18); 

  TextColor(Yellow);
  Write('Save this entry? (Y/N): ');
  if UpCase(ReadKey) <> 'Y' then
    Exit;
  
  { Save to file }
  if IsNew then
  begin
    { Append new record }
    Assign(F, DATAFILE);
    {$I-}
    Reset(F);
    {$I+}
    if IOResult <> 0 then
      Rewrite(F);
    Seek(F, FileSize(F));
    Write(F, Game);
    Close(F);
    
    { Add to memory }
    if GameCount < 1000 then
    begin
      Inc(GameCount);
      Games^[GameCount] := Game;
    end;
  end
  else
  begin
    { Update existing record }
    Assign(F, DATAFILE);
    Reset(F);
    Seek(F, Index - 1);
    Write(F, Game);
    Close(F);
    
    { Update memory }
    Games^[Index] := Game;
  end;
  
  TextColor(LightGreen);
  WriteLn;
  WriteLn('Entry saved!');
  Delay(1000);
end;

{ Note: DeleteEntry, LoadGames, and DisplayList are inherited from EDIT.PAS }

{ Main program - override with 486-specific behavior }
var
  Ch: Char;
  
begin
  New(Games);
  
  CurrentIndex := 1;
  TopIndex := 1;
  Quit := False;
  
  LoadGames;
  
  ClrScr;
  TextColor(Yellow);
  WriteLn('DOS Game Database Editor - 486+ Edition');
  WriteLn('Supports extended sound options and CPU slowdown');
  WriteLn;
  TextColor(LightGray);
  WriteLn('Press any key to continue...');
  Ch := ReadKey;
  
  repeat
    DisplayGameList;
    Write('Enter=SELECT  A=Add  D=Delete  Q=Quit  Games: ', GameCount);
    ClrEol;
    
    Ch := UpCase(ReadKey);
    case Ch of
      #0: begin
        Ch := ReadKey;
        case Ch of
          #72: if CurrentIndex > 1 then  { Up }
          begin
            Dec(CurrentIndex);
            if CurrentIndex < TopIndex then
              TopIndex := CurrentIndex;
          end;
          #80: if CurrentIndex < GameCount then  { Down }
          begin
            Inc(CurrentIndex);
            if CurrentIndex >= TopIndex + 18 then
              TopIndex := CurrentIndex - 17;
          end;
        end;
      end;
      'A': begin
        EditEntry486(0, True);
        LoadGames;
      end;
      #13: if GameCount > 0 then
      begin
        EditEntry486(CurrentIndex, False);
        LoadGames;
      end;
      'D': if GameCount > 0 then
      begin
        DeleteEntry(CurrentIndex);
      end;
      'Q': Quit := True;
    end;
  until Quit;
  
  Dispose(FilePositions);
  Dispose(Games);
  ClrScr;
end.
