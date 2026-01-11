{ EDITCORE.PAS - Shared editor procedures and variables }

{ Input a string }
function InputString(Prompt: string; MaxLen: Integer; Default: string): string;
var
  S: string;
  Ch: Char;
  Done: Boolean;
begin
  Write(Prompt);
  S := Default;
  Write(S);
  
  Done := False;
  repeat
    Ch := ReadKey;
    if Ch = #13 then Done := True;
    if Ch = #27 then begin S := Default; Done := True; end;
    if (Ch = #8) and not Done then
    begin
      if Length(S) > 0 then
      begin
        Delete(S, Length(S), 1);
        Write(#8, ' ', #8);
      end;
    end
    else if (Ch >= ' ') and (Length(S) < MaxLen) and not Done then
    begin
      S := S + Ch;
      Write(Ch);
    end;
  until Done;
  
  InputString := S;
end;

{ Delete entry (soft delete) }
procedure DeleteEntry(Index: Integer);
var
  F: file of GameRecord;
  Game: GameRecord;
  I: Integer;
begin
  if (Index < 1) or (Index > GameCount) then
    Exit;
  
  ClrScr;
  TextColor(Yellow);
  WriteLn('Delete: ', Games^[Index].Title);
  WriteLn;
  Write('Are you sure? (Y/N): ');
  
  if UpCase(ReadKey) <> 'Y' then
    Exit;
  
  { Mark as deleted }
  Game := Games^[Index];
  Game.Deleted := True;
  
  Assign(F, DATAFILE);
  Reset(F);
  Seek(F, Index - 1);
  Write(F, Game);
  Close(F);
  
  { Remove from memory array }
  for I := Index to GameCount - 1 do
    Games^[I] := Games^[I + 1];
  Dec(GameCount);
  
  if CurrentIndex > GameCount then
    CurrentIndex := GameCount;
  
  TextColor(LightGreen);
  WriteLn;
  WriteLn('Entry deleted!');
  Delay(1000);
end;
