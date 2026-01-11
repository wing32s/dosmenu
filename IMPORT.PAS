{ IMPORT.PAS - Import games from import.txt into GAMES.DAT }

program ImportGames;

uses Crt, Dos, GameType;

const
  ImportFile = 'IMPORT.TXT';
  DataFile = 'GAMES.DAT';

var
  FIn: Text;
  FOut: file of GameRecord;
  Line: string;
  Fields: array[1..10] of string;
  I, P, FieldNum: Integer;
  Game: GameRecord;
  SkipLine: Boolean;

function NextField(var S: string): string;
var
  P: Integer;
begin
  P := Pos('|', S);
  if P = 0 then
  begin
    NextField := S;
    S := '';
  end
  else
  begin
    NextField := Copy(S, 1, P-1);
    Delete(S, 1, P);
  end;
end;

begin
  Assign(FIn, ImportFile);
  Reset(FIn);
  Assign(FOut, DataFile);
  {$I-} Reset(FOut); {$I+}
  if IOResult <> 0 then Rewrite(FOut);
  Seek(FOut, FileSize(FOut));

  while not EOF(FIn) do
  begin
    ReadLn(FIn, Line);
    { Manual trim: skip if all spaces }
    P := 1;
    while (P <= Length(Line)) and (Line[P] = ' ') do Inc(P);
    SkipLine := P > Length(Line);
    if not SkipLine then
    begin
      { Parse fields }
      for I := 1 to 10 do Fields[I] := '';
      FieldNum := 1;
      while (Line <> '') and (FieldNum <= 10) do
      begin
        Fields[FieldNum] := NextField(Line);
        Inc(FieldNum);
      end;
      FillChar(Game, SizeOf(Game), 0);
      { Title, Path, Command, Args }
      Game.Title := Copy(Fields[1], 1, 50);
      Game.Path := Copy(Fields[2], 1, 80);
      Game.Command := Copy(Fields[3], 1, 13);
      Game.Args := Copy(Fields[4], 1, 60);
      { SoundFlags, GraphicsFlags }
      Val(Fields[5], Game.SoundFlags, I);
      Val(Fields[6], Game.GraphicsFlags, I);
      { Publisher, Year }
      Game.Publisher := Copy(Fields[7], 1, 30);
      Game.Year := Copy(Fields[8], 1, 4);
      { GenreCode }
      Val(Fields[9], Game.GenreCode, I);
      { RequiresCD }
      if Length(Fields[10]) > 0 then
        Game.RequiresCD := (UpCase(Fields[10][1]) = 'Y')
      else
        Game.RequiresCD := False;
      { Write to file }
      Write(FOut, Game);
    end;
  end;

  Close(FIn);
  Close(FOut);
  WriteLn('Import complete.');
end.
