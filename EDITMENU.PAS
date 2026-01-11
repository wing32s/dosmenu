{ EDIT.PAS - Game Database Editor }

  program GameEditor;

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

  {$I MENUCORE.PAS}
  {$I EDITCORE.PAS}


{ Toggle graphics flags - 80s modes only }
function SelectGraphicsFlags(Current: Byte): Byte;
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
    WriteLn('Graphics Modes - 80s Era (press letter to toggle, ENTER when done)');
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
    
    TextColor(DarkGray);
    WriteLn;
    WriteLn('(VGA/SVGA available in EDIT486.EXE)');
    
    Ch := UpCase(ReadKey);
    case Ch of
      'H': Flags := Flags xor GFX_HERC;
      'C': Flags := Flags xor GFX_CGA;
      'T': Flags := Flags xor GFX_TANDY;
      'E': Flags := Flags xor GFX_EGA;
      #13: Done := True;
      #27: begin Flags := Current; Done := True; end;
    end;
  until Done;
  
  SelectGraphicsFlags := Flags;
end;

{ Add or edit a game entry }
procedure EditEntry(Index: Integer; IsNew: Boolean);
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
  end
  else
    Game := Games^[Index];
  
  ClrScr;
  TextColor(White);
  if IsNew then
    WriteLn('=== Add New Game ===')
  else
    WriteLn('=== Edit Game ===');
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
  
  WriteLn('Press any key to configure sound tags...');
  Ch := ReadKey;
  Game.SoundFlags := SelectSoundFlags(Game.SoundFlags);
  
  WriteLn('Press any key to configure graphics modes...');
  Ch := ReadKey;
  Game.GraphicsFlags := SelectGraphicsFlags(Game.GraphicsFlags);
  
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

{ Main program }
var
  Ch: Char;

begin
  New(Games);
  New(FilePositions);
  
  CurrentIndex := 1;
  TopIndex := 1;
  Quit := False;
  
  LoadGames;
  
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
        EditEntry(0, True);
        LoadGames;
      end;
      'D': if GameCount > 0 then
      begin
        DeleteEntry(CurrentIndex);
      end;
      'S': begin
        { Search filter }
        ClrScr;
        TextColor(Yellow);
        GotoXY(1, 10);
        Write('Enter title search (partial match, blank for all): ');
        TextColor(White);
        ReadLn(SearchStr);
        SearchStr := UpperStr(SearchStr);
        CurrentIndex := 1;
        TopIndex := 1;
        LoadGames;
      end;
      'Q': Quit := True;
      #13: if GameCount > 0 then
      begin
        EditEntry(CurrentIndex, False);
        LoadGames;
      end;

    end;
  until Quit;
  
  Dispose(FilePositions);
  Dispose(Games);
  ClrScr;
end.


