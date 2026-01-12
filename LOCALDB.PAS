
{ LOCALDB.PAS - Local database record structure for DOS Game Launcher }

type
  LocalRecord = record
    MASTERID:   LongInt;      { foreign key }
    PATH:       string[80];   { launch path }
    COMMAND:    string[13];   { 8.3 exe/bat }
    ARGS:       string[60];   { command-line args }

    TITLE:      string[50];   { display title }
    PUBLISHER:  string[30];   { display publisher }
    YEARDISP:   string[4];    { 1993, 199X, 19XX, ???? }
    PLATFORM:   string[16];   { cached from MASTER }
    REQCD:      Boolean;      { cached from MASTER }

    TITLEKEY:   string[50];   { search key }
    TITLEKEY2:  string[50];   { rotated-article key }
    PUBKEY:     string[30];   { publisher key }

    YEARMIN:    Word;         { filter cache }
    YEARMAX:    Word;
    GENRE:      Byte;
    SNDLEG:     Byte;
    SNDFM:      Byte;
    SNDMIDI:    Byte;
    GFX:        Byte;
    GROUPID:    Word;
    VRANK:      Byte;
    VNAME:      string[20];
    SERIESID:   Word;
    SERIESNO:   Byte;

    ISDEF:      Boolean;      { preferred default variant }
    VIDSEL:     Byte;         { selected video enum }
    MUSSEL:     Byte;         { selected MIDI/wavetable enum }
    AUDSEL:     Byte;         { selected legacy audio enum }
    SFXSEL:     Byte;         { selected digital card/profile enum }

    CACHE:      Byte;         { 0=none, 1=force OFF, 2=force ON }
    SETMUL:     Byte;         { bitmask (0–255) }
    SDSU:       Word;         { 0=none, else SLOWDOWN /S: }
  end;

procedure WriteLocalRecord(F: File; Record: LocalRecord);
var
  Buf: array[1..512] of Byte;
  P: ^Byte;
  S: string;
  function Pad(S: string; Len: Integer): string;
  begin
    while Length(S) < Len do S := S + ' ';
    if Length(S) > Len then S := Copy(S, 1, Len);
    Pad := S;
  end;
begin
  FillChar(Buf, SizeOf(Buf), 0);
  P := @Buf;
  P^ := $20; Inc(P); { not deleted }
  S := Pad(IntToStr(Record.MASTERID), 10); Move(S[1], P^, 10); Inc(P, 10);
  S := Pad(Record.PATH, 80); Move(S[1], P^, 80); Inc(P, 80);
  S := Pad(Record.COMMAND, 13); Move(S[1], P^, 13); Inc(P, 13);
  S := Pad(Record.ARGS, 60); Move(S[1], P^, 60); Inc(P, 60);
  S := Pad(Record.TITLE, 50); Move(S[1], P^, 50); Inc(P, 50);
  S := Pad(Record.PUBLISHER, 30); Move(S[1], P^, 30); Inc(P, 30);
  S := Pad(Record.YEARDISP, 4); Move(S[1], P^, 4); Inc(P, 4);
  S := Pad(Record.PLATFORM, 16); Move(S[1], P^, 16); Inc(P, 16);
  if Record.REQCD then S := 'T' else S := 'F'; Move(S[1], P^, 1); Inc(P, 1);
  S := Pad(Record.TITLEKEY, 50); Move(S[1], P^, 50); Inc(P, 50);
  S := Pad(Record.TITLEKEY2, 50); Move(S[1], P^, 50); Inc(P, 50);
  S := Pad(Record.PUBKEY, 30); Move(S[1], P^, 30); Inc(P, 30);
  S := Pad(IntToStr(Record.YEARMIN), 4); Move(S[1], P^, 4); Inc(P, 4);
  S := Pad(IntToStr(Record.YEARMAX), 4); Move(S[1], P^, 4); Inc(P, 4);
  S := Pad(IntToStr(Record.GENRE), 2); Move(S[1], P^, 2); Inc(P, 2);
  S := Pad(IntToStr(Record.SNDLEG), 3); Move(S[1], P^, 3); Inc(P, 3);
  S := Pad(IntToStr(Record.SNDFM), 3); Move(S[1], P^, 3); Inc(P, 3);
  S := Pad(IntToStr(Record.SNDMIDI), 3); Move(S[1], P^, 3); Inc(P, 3);
  S := Pad(IntToStr(Record.GFX), 3); Move(S[1], P^, 3); Inc(P, 3);
  S := Pad(IntToStr(Record.GROUPID), 6); Move(S[1], P^, 6); Inc(P, 6);
  S := Pad(IntToStr(Record.VRANK), 2); Move(S[1], P^, 2); Inc(P, 2);
  S := Pad(Record.VNAME, 20); Move(S[1], P^, 20); Inc(P, 20);
  S := Pad(IntToStr(Record.SERIESID), 6); Move(S[1], P^, 6); Inc(P, 6);
  S := Pad(IntToStr(Record.SERIESNO), 3); Move(S[1], P^, 3); Inc(P, 3);
  if Record.ISDEF then S := 'T' else S := 'F'; Move(S[1], P^, 1); Inc(P, 1);
  S := Pad(IntToStr(Record.VIDSEL), 3); Move(S[1], P^, 3); Inc(P, 3);
  S := Pad(IntToStr(Record.MUSSEL), 3); Move(S[1], P^, 3); Inc(P, 3);
  S := Pad(IntToStr(Record.AUDSEL), 3); Move(S[1], P^, 3); Inc(P, 3);
  S := Pad(IntToStr(Record.SFXSEL), 3); Move(S[1], P^, 3); Inc(P, 3);
  S := Pad(IntToStr(Record.CACHE), 1); Move(S[1], P^, 1); Inc(P, 1);
  S := Pad(IntToStr(Record.SETMUL), 3); Move(S[1], P^, 3); Inc(P, 3);
  S := Pad(IntToStr(Record.SDSU), 5); Move(S[1], P^, 5); Inc(P, 5);
  BlockWrite(F, Buf, (P - @Buf));
end;