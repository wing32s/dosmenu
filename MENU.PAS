{ MENU.PAS - DOS Game Launcher Main Menu }

program GameLauncher;

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
  FilterSound: Byte;
  Ch: Char;
  Quit: Boolean;

{ Check if a game matches current filters }
function MatchesFilter(Game: GameRecord): Boolean;
var
  Match: Boolean;
  PubA, PubB: string;
begin
  Match := True;
  
  { Search string filter }
  if SearchStr <> '' then
    Match := Match and (Pos(UpperStr(SearchStr), UpperStr(Game.Title)) > 0);
  
  { Publisher filter (case-insensitive, trimmed) }
  if FilterPublisher <> '' then
  begin
    PubA := UpperStr(Game.Publisher);
    while (Length(PubA) > 0) and (PubA[Length(PubA)] = ' ') do Delete(PubA, Length(PubA), 1);
    PubB := UpperStr(FilterPublisher);
    while (Length(PubB) > 0) and (PubB[Length(PubB)] = ' ') do Delete(PubB, Length(PubB), 1);
    Match := Match and (PubA = PubB);
  end;
  
  { Genre filter }
  if FilterGenreCode <> 0 then
    Match := Match and (Game.GenreCode = FilterGenreCode);
  
  { Year filter }
  if FilterYear <> '' then
    Match := Match and (Game.Year = FilterYear);
  
  { Sound filter (must have ANY selected flag) }
  if FilterSound <> 0 then
    Match := Match and ((Game.SoundFlags and FilterSound) <> 0);
  
  { Not deleted }
  Match := Match and (not Game.Deleted);
  
  MatchesFilter := Match;
end;

  {$I MENUCORE.PAS}

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
    WriteLn('4. Sound Flags: ', SoundFlagsToStr(FilterSound));
    WriteLn('5. Clear all filters');
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
        FilterSound := SelectSoundFlags(0);
      end;
      '5': begin
        FilterPublisher := '';
        FilterGenreCode := 0;
        FilterYear := '';
        FilterSound := 0;
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
    DisplayGameDetail(Game);
    TextColor(White);
    GotoXY(1, 15); Write('[L] Launch Game      [Esc] Return to Menu');
    GotoXY(1, 17); Write('========================================');
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
  FilterSound := 0;
  CurrentIndex := 1;
  TopIndex := 1;
  Quit := False;
  
  { Load initial game list }
  LoadGames;
  
  if GameCount = 0 then
  begin
    ClrScr;
    WriteLn('No games found in ', DATAFILE);
    WriteLn('Run EDIT.EXE to add games.');
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
