uses SysUtils;

{ MASTERDB.PAS - Master database record structure for DOS Game Launcher }

type
  MasterRecord = record
    MASTERID:    LongInt;      { stable internal ID }
    LBID:        LongInt;      { LaunchBox DatabaseID (0 if none) }
    LBGUID:      string[36];   { LaunchBox GUID string (blank if none) }

    TITLE:       string[50];   { display title }
    TITLEKEY:    string[50];   { normalized uppercase key }
    TITLEKEY2:   string[50];   { rotated-article key }
    PUBLISHER:   string[30];   { display publisher }
    PUBKEY:      string[30];   { normalized publisher key }

    PLATFORM:    string[16];   { one platform tag per variant }

    YEARMIN:     Word;         { 0 if unknown }
    YEARMAX:     Word;         { 0 if unknown }
    GENRE:       Byte;         { 0–28 }

    SNDLEG:      Byte;         { legacy sound flags (0–255) }
    SNDFM:       Byte;         { FM/digital flags (0–255) }
    SNDMIDI:     Byte;         { MIDI/wavetable flags (0–255) }
    GFX:         Byte;         { graphics flags (0–255) }
    REQCD:       Boolean;      { requires CD }

    GROUPID:     Word;         { variants share this ID }
    VRANK:       Byte;         { 1=preferred default, 2,3… }
    VNAME:       string[20];   { short variant label }

    SERIESID:    Word;         { 0 if none }
    SERIESNO:    Byte;         { 0 if none }
  end;

  MasterHeaderArray = array[1..32+32*22] of Byte; { enough for up to 22 fields }

{$I DBFHELP.PAS}  { Include the shared editor procedures }

function GetMasterFieldCount() : Integer;
begin
   GetMasterFieldCount := 22;
end;

procedure WriteMasterRecord(F: File, Record: MasterRecord);
var
  Buf: array[1..512] of Byte;
  P: ^Byte;
  S: string;

begin
      FillChar(Buf, SizeOf(Buf), 0);
      P := @Buf;
      P^ := $20; Inc(P); { not deleted }
      S := Pad(IntToStr(Record.MASTERID), 10); Move(S[1], P^, 10); Inc(P, 10);
      S := Pad(IntToStr(Record.LBID), 10); Move(S[1], P^, 10); Inc(P, 10);
      S := Pad(Record.LBGUID, 36); Move(S[1], P^, 36); Inc(P, 36);
      S := Pad(Record.TITLE, 50); Move(S[1], P^, 50); Inc(P, 50);
      S := Pad(Record.TITLEKEY, 50); Move(S[1], P^, 50); Inc(P, 50);
      S := Pad(Record.TITLEKEY2, 50); Move(S[1], P^, 50); Inc(P, 50);
      S := Pad(Record.PUBLISHER, 30); Move(S[1], P^, 30); Inc(P, 30);
      S := Pad(Record.PUBKEY, 30); Move(S[1], P^, 30); Inc(P, 30);
      S := Pad(Record.PLATFORM, 16); Move(S[1], P^, 16); Inc(P, 16);
      S := Pad(IntToStr(Record.YEARMIN), 4); Move(S[1], P^, 4); Inc(P, 4);
      S := Pad(IntToStr(Record.YEARMAX), 4); Move(S[1], P^, 4); Inc(P, 4);
      S := Pad(IntToStr(Record.GENRE), 2); Move(S[1], P^, 2); Inc(P, 2);
      S := Pad(IntToStr(Record.SNDLEG), 3); Move(S[1], P^, 3); Inc(P, 3);
      S := Pad(IntToStr(Record.SNDFM), 3); Move(S[1], P^, 3); Inc(P, 3);
      S := Pad(IntToStr(Record.SNDMIDI), 3); Move(S[1], P^, 3); Inc(P, 3);
      S := Pad(IntToStr(Record.GFX), 3); Move(S[1], P^, 3); Inc(P, 3);
      if Record.REQCD then S := 'T' else S := 'F'; Move(S[1], P^, 1); Inc(P, 1);
      S := Pad(IntToStr(Record.GROUPID), 6); Move(S[1], P^, 6); Inc(P, 6);
      S := Pad(IntToStr(Record.VRANK), 2); Move(S[1], P^, 2); Inc(P, 2);
      S := Pad(Record.VNAME, 20); Move(S[1], P^, 20); Inc(P, 20);
      S := Pad(IntToStr(Record.SERIESID), 6); Move(S[1], P^, 6); Inc(P, 6);
      S := Pad(IntToStr(Record.SERIESNO), 3); Move(S[1], P^, 3); Inc(P, 3);
      Seek(F, PosInFile);
      BlockWrite(F, Buf, (P - @Buf));
end;

procedure CreateMasterDBF(FileName: string)
var
  F: File;
  Header: MasterHeaderArray;
  I, J, RecCount: Integer;
begin
  Assign(F, FileName);
  Rewrite(F, 1);

  RecCount := Length(Records);

  { Write DBF header (128 bytes for 10 fields, 32 bytes per field) }
  FillChar(Header, SizeOf(Header), 0);
  Header[1] := $03; { dBase III, no memo }
  Header[5] := RecCount and $FF;
  Header[6] := (RecCount shr 8) and $FF;
  Header[7] := (RecCount shr 16) and $FF;
  Header[8] := (RecCount shr 24) and $FF;
  Header[9] := SizeOf(Header) + 1;
  Header[11] := SizeOf(MasterRecord); { record size }
  { Write DBF field descriptors (32 bytes each, terminated by 0x0D) }
  J := 32; { start after 32-byte header }

  { Field definitions: name, type, length, decimals }
  WriteFieldDesc('MASTERID',  'N', 10, 0);
  WriteFieldDesc('LBID',      'N', 10, 0);
  WriteFieldDesc('LBGUID',    'C', 36, 0);
  WriteFieldDesc('TITLE',     'C', 50, 0);
  WriteFieldDesc('TITLEKEY',  'C', 50, 0);
  WriteFieldDesc('TITLEKEY2', 'C', 50, 0);
  WriteFieldDesc('PUBLISHER', 'C', 30, 0);
  WriteFieldDesc('PUBKEY',    'C', 30, 0);
  WriteFieldDesc('PLATFORM',  'C', 16, 0);
  WriteFieldDesc('YEARMIN',   'N', 4, 0);
  WriteFieldDesc('YEARMAX',   'N', 4, 0);
  WriteFieldDesc('GENRE',     'N', 2, 0);
  WriteFieldDesc('SNDLEG',    'N', 3, 0);
  WriteFieldDesc('SNDFM',     'N', 3, 0);
  WriteFieldDesc('SNDMIDI',   'N', 3, 0);
  WriteFieldDesc('GFX',       'N', 3, 0);
  WriteFieldDesc('REQCD',     'L', 1, 0);
  WriteFieldDesc('GROUPID',   'N', 6, 0);
  WriteFieldDesc('VRANK',     'N', 2, 0);
  WriteFieldDesc('VNAME',     'C', 20, 0);
  WriteFieldDesc('SERIESID',  'N', 6, 0);
  WriteFieldDesc('SERIESNO',  'N', 3, 0);

  Header[J+1] := $0D; { field descriptor terminator }
  BlockWrite(F, Header, SizeOf(Header));

  Close(F);
end;

procedure WriteMasterDBF(FileName: string; Records: array of MasterRecord);
var
  F: File;
  Header: MasterHeaderArray;
  I, J, RecCount: Integer;
begin
  Assign(F, FileName);
  Rewrite(F, 1);

  RecCount := Length(Records);

  { Write DBF header (128 bytes for 10 fields, 32 bytes per field) }
  FillChar(Header, SizeOf(Header), 0);
  Header[1] := $03; { dBase III, no memo }
  Header[5] := RecCount and $FF;
  Header[6] := (RecCount shr 8) and $FF;
  Header[7] := (RecCount shr 16) and $FF;
  Header[8] := (RecCount shr 24) and $FF;
  Header[9] := SizeOf(Header) + 1;
  Header[11] := SizeOf(MasterRecord); { record size }
  { Write DBF field descriptors (32 bytes each, terminated by 0x0D) }
  J := 32; { start after 32-byte header }

  { Field definitions: name, type, length, decimals }
  WriteFieldDesc('MASTERID',  'N', 10, 0);
  WriteFieldDesc('LBID',      'N', 10, 0);
  WriteFieldDesc('LBGUID',    'C', 36, 0);
  WriteFieldDesc('TITLE',     'C', 50, 0);
  WriteFieldDesc('TITLEKEY',  'C', 50, 0);
  WriteFieldDesc('TITLEKEY2', 'C', 50, 0);
  WriteFieldDesc('PUBLISHER', 'C', 30, 0);
  WriteFieldDesc('PUBKEY',    'C', 30, 0);
  WriteFieldDesc('PLATFORM',  'C', 16, 0);
  WriteFieldDesc('YEARMIN',   'N', 4, 0);
  WriteFieldDesc('YEARMAX',   'N', 4, 0);
  WriteFieldDesc('GENRE',     'N', 2, 0);
  WriteFieldDesc('SNDLEG',    'N', 3, 0);
  WriteFieldDesc('SNDFM',     'N', 3, 0);
  WriteFieldDesc('SNDMIDI',   'N', 3, 0);
  WriteFieldDesc('GFX',       'N', 3, 0);
  WriteFieldDesc('REQCD',     'L', 1, 0);
  WriteFieldDesc('GROUPID',   'N', 6, 0);
  WriteFieldDesc('VRANK',     'N', 2, 0);
  WriteFieldDesc('VNAME',     'C', 20, 0);
  WriteFieldDesc('SERIESID',  'N', 6, 0);
  WriteFieldDesc('SERIESNO',  'N', 3, 0);

  Header[J+1] := $0D; { field descriptor terminator }
  BlockWrite(F, Header, SizeOf(Header));

  { Write records }
  for I := 0 to RecCount-1 do
  begin
    WriteMasterRecord(F, Records[I]);
  end;

  Close(F);
end;

procedure ReadMasterDBF(FileName: string; var Records: array of MasterRecord; var RecCount: Integer);
var
  F: File;
  Header: MasterHeaderArray;
  I, J, K, N, FieldLen, FieldStart: Integer;
  Buf: array[1..512] of Byte;
  P: ^Byte;
  S: string;

begin
  Assign(F, FileName);
  Reset(F, 1);
  BlockRead(F, Header, SizeOf(MasterHeaderArray));
  { Get record count from header }
  N := Header[5] + (Header[6] shl 8) + (Header[7] shl 16) + (Header[8] shl 24);
  RecCount := N;
  for I := 0 to N-1 do
  begin
    BlockRead(F, Buf, SizeOf(Buf));
    P := @Buf;
    if P^ = $2A then Continue; { deleted }
    Inc(P);
    { Read each field in order }
    Records[I].MASTERID  := ReadFieldNum(P, 10); Inc(P, 10);
    Records[I].LBID      := ReadFieldNum(P, 10); Inc(P, 10);
    Records[I].LBGUID    := ReadFieldStr(P, 36); Inc(P, 36);
    Records[I].TITLE     := ReadFieldStr(P, 50); Inc(P, 50);
    Records[I].TITLEKEY  := ReadFieldStr(P, 50); Inc(P, 50);
    Records[I].TITLEKEY2 := ReadFieldStr(P, 50); Inc(P, 50);
    Records[I].PUBLISHER := ReadFieldStr(P, 30); Inc(P, 30);
    Records[I].PUBKEY    := ReadFieldStr(P, 30); Inc(P, 30);
    Records[I].PLATFORM  := ReadFieldStr(P, 16); Inc(P, 16);
    Records[I].YEARMIN   := ReadFieldWord(P, 4); Inc(P, 4);
    Records[I].YEARMAX   := ReadFieldWord(P, 4); Inc(P, 4);
    Records[I].GENRE     := ReadFieldByte(P, 2); Inc(P, 2);
    Records[I].SNDLEG    := ReadFieldByte(P, 3); Inc(P, 3);
    Records[I].SNDFM     := ReadFieldByte(P, 3); Inc(P, 3);
    Records[I].SNDMIDI   := ReadFieldByte(P, 3); Inc(P, 3);
    Records[I].GFX       := ReadFieldByte(P, 3); Inc(P, 3);
    Records[I].REQCD     := (UpCase(Char(P^)) = 'T'); Inc(P, 1);
    Records[I].GROUPID   := ReadFieldWord(P, 6); Inc(P, 6);
    Records[I].VRANK     := ReadFieldByte(P, 2); Inc(P, 2);
    Records[I].VNAME     := ReadFieldStr(P, 20); Inc(P, 20);
    Records[I].SERIESID  := ReadFieldWord(P, 6); Inc(P, 6);
    Records[I].SERIESNO  := ReadFieldByte(P, 3); Inc(P, 3);
  end;
  Close(F);
end;

procedure CreateMasterDBFfromTXT(TxtFile, DbfFile: string);
var
  F: Text;
  Line, Field: string;
  Fields: array[1..22] of string;
  Records: array[1..1000] of MasterRecord;
  RecCount, I, J: Integer;

begin
  Assign(F, TxtFile);
  Reset(F);
  ReadLn(F, Line); { skip header }
  RecCount := 0;
  while not EOF(F) do
  begin
    ReadLn(F, Line);
    if Trim(Line) = '' then Continue;
    I := 1; J := 1; Field := '';
    FillChar(Fields, SizeOf(Fields), 0);
    while (I <= Length(Line)) and (J <= GetMasterFieldCount()) do
    begin
      if Line[I] = '|' then begin Fields[J] := Field; Field := ''; Inc(J); end
      else Field := Field + Line[I];
      Inc(I);
    end;
    if (J <= GetMasterFieldCount()) then Fields[J] := Field;
    Inc(RecCount);
    with Records[RecCount] do
    begin
      MASTERID  := ParseInt(Fields[1]);
      LBID      := ParseInt(Fields[2]);
      LBGUID    := Fields[3];
      TITLE     := Fields[4];
      TITLEKEY  := Fields[5];
      TITLEKEY2 := Fields[6];
      PUBLISHER := Fields[7];
      PUBKEY    := Fields[8];
      PLATFORM  := Fields[9];
      YEARMIN   := ParseWord(Fields[10]);
      YEARMAX   := ParseWord(Fields[11]);
      GENRE     := ParseByte(Fields[12]);
      SNDLEG    := ParseByte(Fields[13]);
      SNDFM     := ParseByte(Fields[14]);
      SNDMIDI   := ParseByte(Fields[15]);
      GFX       := ParseByte(Fields[16]);
      REQCD     := ParseBool(Fields[17]);
      GROUPID   := ParseWord(Fields[18]);
      VRANK     := ParseByte(Fields[19]);
      VNAME     := Fields[20];
      SERIESID  := ParseWord(Fields[21]);
      SERIESNO  := ParseByte(Fields[22]);
    end;
  end;
  Close(F);
  WriteMasterDBF(DbfFile, Slice(Records, RecCount));
end;

procedure WriteMasterTXTfromDBF(TxtFile: string; Records: array of MasterRecord; RecCount: Integer);
var
  F: Text;
  I: Integer;
  function B2S(B: Boolean): string;
  begin if B then B2S := 'T' else B2S := 'F'; end;
begin
  Assign(F, TxtFile);
  Rewrite(F);
  WriteLn(F, 'MASTERID|LBID|LBGUID|TITLE|TITLEKEY|TITLEKEY2|PUBLISHER|PUBKEY|PLATFORM|YEARMIN|YEARMAX|GENRE|SNDLEG|SNDFM|SNDMIDI|GFX|REQCD|GROUPID|VRANK|VNAME|SERIESID|SERIESNO');
  for I := 1 to RecCount do
    with Records[I] do
      WriteLn(F,
        MASTERID, '|', LBID, '|', LBGUID, '|', TITLE, '|', TITLEKEY, '|', TITLEKEY2, '|',
        PUBLISHER, '|', PUBKEY, '|', PLATFORM, '|', YEARMIN, '|', YEARMAX, '|', GENRE, '|',
        SNDLEG, '|', SNDFM, '|', SNDMIDI, '|', GFX, '|', B2S(REQCD), '|', GROUPID, '|',
        VRANK, '|', VNAME, '|', SERIESID, '|', SERIESNO);
  Close(F);
end;

procedure UpdateMasterRecordInDBFInPlace(FileName: string; const NewRec: MasterRecord);
var
  F: File;
  Header: array[1..32+32*22] of Byte; { enough for up to 22 fields }

  RecSize, RecCount, I, PosInFile: Integer;
  Buf: array[1..512] of Byte;
  P: ^Byte;
  S: string;
  function Pad(S: string; Len: Integer): string;
  begin
    while Length(S) < Len do S := S + ' ';
    if Length(S) > Len then S := Copy(S, 1, Len);
    Pad := S;
  end;
  function ReadFieldNum(P: PByte; Len: Integer): LongInt;
  var T: string; K: Integer;
  begin
    SetLength(T, Len);
    Move(P^, T[1], Len);
    while (Length(T) > 0) and (T[Length(T)] = ' ') do Delete(T, Length(T), 1);
    Val(T, ReadFieldNum, K);
  end;
begin
  Assign(F, FileName);
  Reset(F, 1);
  BlockRead(F, Header, GetMasterFileOffset());
  RecSize := 0;
  RecSize := Header[11];
  RecCount := Header[5] + (Header[6] shl 8) + (Header[7] shl 16) + (Header[8] shl 24);
  PosInFile := GetMasterFileOffset();
  Seek(F, PosInFile);
  for I := 1 to RecCount do
  begin
    BlockRead(F, Buf, RecSize);
    P := @Buf;
    if P^ = $2A then begin Inc(PosInFile, RecSize); Seek(F, PosInFile); Continue; end; { deleted }
    Inc(P); { skip deleted flag }
    { MASTERID is first field, N(10,0) }
    if ReadFieldNum(P, 10) = NewRec.MASTERID then
    begin
      WriteMasterRecord(F, NewRec);
      Close(F);
      Exit;
    end;
    Inc(PosInFile, RecSize);
    Seek(F, PosInFile);
  end;
  Close(F);
end;

procedure AppendMasterRecordToDBF(FileName: string; Rec: MasterRecord);
var
  F: File;
  Header: MasterHeaderArray
  RecSize, RecCount, NewCount, PosInFile: Integer;
begin
  Assign(F, FileName);
  Reset(F, 1);
  BlockRead(F, Header, GetMasterFileOffset());
  RecSize := Header[11];
  RecCount := Header[5] + (Header[6] shl 8) + (Header[7] shl 16) + (Header[8] shl 24);
  PosInFile := GetMasterFileOffset() + RecCount * RecSize;
  Seek(F, PosInFile);
  { Write the new record }
  WriteMasterRecord(F, Rec);
  { Update header record count }
  NewCount := RecCount + 1;
  Header[5] := NewCount and $FF;
  Header[6] := (NewCount shr 8) and $FF;
  Header[7] := (NewCount shr 16) and $FF;
  Header[8] := (NewCount shr 24) and $FF;
  Seek(F, 0);
  BlockWrite(F, Header, GetMasterFileOffset());
  Close(F);
end;

procedure ToggleMasterRecordInDBF(FileName: string; MasterID: LongInt; DeleteFlag: Boolean);
var
  F: File;
  Header: array[1..32+32*22] of Byte; { enough for up to 22 fields }

  RecSize, RecCount, I, PosInFile: Integer;
  Buf: array[1..512] of Byte;
  P: ^Byte;
  function ReadFieldNum(P: PByte; Len: Integer): LongInt;
  var T: string; K: Integer;
  begin
    SetLength(T, Len);
    Move(P^, T[1], Len);
    while (Length(T) > 0) and (T[Length(T)] = ' ') do Delete(T, Length(T), 1);
    Val(T, ReadFieldNum, K);
  end;
begin
  Assign(F, FileName);
  Reset(F, 1);
  BlockRead(F, Header, GetMasterFileOffset());
  RecSize := Header[11];
  RecCount := Header[5] + (Header[6] shl 8) + (Header[7] shl 16) + (Header[8] shl 24);
  PosInFile := GetMasterFileOffset();
  Seek(F, PosInFile);
  for I := 1 to RecCount do
  begin
    BlockRead(F, Buf, RecSize);
    P := @Buf;
    { If already deleted and DeleteFlag is true, skip. If not deleted and DeleteFlag is false, skip. }
    if (P^ = $2A) and DeleteFlag then begin Inc(PosInFile, RecSize); Seek(F, PosInFile); Continue; end;
    if (P^ <> $2A) and not DeleteFlag then begin Inc(PosInFile, RecSize); Seek(F, PosInFile); Continue; end;
    Inc(P); { skip deleted flag }
    if ReadFieldNum(P, 10) = MasterID then
    begin
      Seek(F, PosInFile);
      if DeleteFlag then
        Buf[1] := $2A { set deleted flag }
      else
        Buf[1] := $20; { unset deleted flag }
      BlockWrite(F, Buf, 1); { only need to write the flag }
      Close(F);
      Exit;
    end;
    Inc(PosInFile, RecSize);
    Seek(F, PosInFile);
  end;
  Close(F);
end;