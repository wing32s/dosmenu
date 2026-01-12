unit DBF;

interface

type
  TDBFColumn = record
    Name: string[11];   { Field name (max 11 chars) }
    FieldType: Char;    { 'C', 'N', 'L', etc. }
    Length: Byte;       { Field length in bytes }
    Decimals: Byte;     { Number of decimal places (for numeric) }
    Offset: Word;       { offset within record; first field starts at 1 }
  end;

const
  DBFMaxFields = 64;
  DBFMaxRecordSize = 4096;

type
  TDBFHeader = record
    Version: Byte;                { dBase version, e.g., $03 for dBase III }
    Year: Byte;                   { Last update year (since 1900) }
    Month: Byte;                  { Last update month }
    Day: Byte;                    { Last update day }
    RecordCount: LongInt;         { Number of records }
    HeaderSize: Word;             { Header size in bytes }
    RecordSize: Word;             { Record size in bytes }
    Fields: array[1..DBFMaxFields] of TDBFColumn; { Field descriptors }
    FieldCount: Integer;          { Actual number of fields used }
  end;

  TDBFValues = array[1..DBFMaxFields] of string[255];
  TDBFRow = array[0..DBFMaxRecordSize - 1] of Byte;

function ReadFieldStr(P: Pointer; Len: Integer): string;
function ReadFieldNum(P: Pointer; Len: Integer): LongInt;
function ReadFieldWord(P: Pointer; Len: Integer): Word;
function ReadFieldByte(P: Pointer; Len: Integer): Byte;
function Pad(S: string; Len: Integer): string;
function ParseInt(S: string): LongInt;
function ParseWord(S: string): Word;
function ParseByte(S: string): Byte;
function ParseBool(S: string): Boolean;

procedure WriteDBFHeader(var F: File; Header: TDBFHeader);
procedure UpdateDBFRecordCount(var F: File; NewCount: LongInt);
procedure WriteDBFRow(var F: File; Header: TDBFHeader; Values: TDBFValues);
procedure SetDBFRowDeleted(var F: File; Deleted: Boolean);
procedure ReadDBFHeader(var F: File; var Header: TDBFHeader);
procedure ReadDBFRow(var F: File; var Buf: TDBFRow; RecordSize: Integer);
function GetFieldStr(var Buf: TDBFRow; Header: TDBFHeader; FieldIdx: Integer): string;
procedure SetFieldStr(var Buf: TDBFRow; Header: TDBFHeader; FieldIdx: Integer; Value: string);
function GetActualDBFRowCount(var F: File; Header: TDBFHeader): LongInt;
procedure SeekToFirstRow(var F: File; Header: TDBFHeader);
procedure SeekToEnd(var F: File; Header: TDBFHeader);
procedure SeekToRow(var F: File; const Header: TDBFHeader; RowIndex: LongInt);
procedure AppendDBFRow(var F: File; var Header: TDBFHeader; Values: TDBFValues);

implementation

type
  TByteArray = array[0..65520] of Byte;
  PByteArray = ^TByteArray;

function ReadFieldStr(P: Pointer; Len: Integer): string;
var
  T: string[255];
  I: Integer;
begin
  T := '';
  for I := 0 to Len - 1 do
    T := T + Chr(PByteArray(P)^[I]);
  while (Length(T) > 0) and (T[Length(T)] = ' ') do
    Delete(T, Length(T), 1);
  ReadFieldStr := T;
end;

function ReadFieldNum(P: Pointer; Len: Integer): LongInt;
var
  T: string;
  V: LongInt;
  Code: Integer;
begin
  T := ReadFieldStr(P, Len);
  V := 0;
  Val(T, V, Code);
  ReadFieldNum := V;
end;

function ReadFieldWord(P: Pointer; Len: Integer): Word;
var
  T: string;
  V: LongInt;
  Code: Integer;
begin
  T := ReadFieldStr(P, Len);
  V := 0;
  Val(T, V, Code);
  ReadFieldWord := V;
end;

function ReadFieldByte(P: Pointer; Len: Integer): Byte;
var
  T: string;
  V: LongInt;
  Code: Integer;
begin
  T := ReadFieldStr(P, Len);
  V := 0;
  Val(T, V, Code);
  ReadFieldByte := V;
end;

function Pad(S: string; Len: Integer): string;
begin
  while Length(S) < Len do
    S := S + ' ';
  if Length(S) > Len then
    S := Copy(S, 1, Len);
  Pad := S;
end;

function ParseInt(S: string): LongInt;
var
  V: LongInt;
  Code: Integer;
begin
  V := 0;
  Val(S, V, Code);
  ParseInt := V;
end;

function ParseWord(S: string): Word;
var
  V: LongInt;
  Code: Integer;
begin
  V := 0;
  Val(S, V, Code);
  ParseWord := V;
end;

function ParseByte(S: string): Byte;
var
  V: LongInt;
  Code: Integer;
begin
  V := 0;
  Val(S, V, Code);
  ParseByte := V;
end;

function ParseBool(S: string): Boolean;
var
  C: Char;
  I: Integer;
begin
  I := 1;
  while (I <= Length(S)) and (S[I] = ' ') do
    Inc(I);
  if I > Length(S) then
    ParseBool := False
  else
  begin
    C := UpCase(S[I]);
    ParseBool := (C = 'T') or (C = 'Y') or (C = '1');
  end;
end;

procedure WriteDBFHeader(var F: File; Header: TDBFHeader);
var
  I, J: Integer;
  Buf: array[1..32] of Byte;
begin
  { Write main file header (32 bytes) }
  FillChar(Buf, SizeOf(Buf), 0);
  Buf[1] := Header.Version;
  Buf[2] := Header.Year;
  Buf[3] := Header.Month;
  Buf[4] := Header.Day;
  Buf[5] := Header.RecordCount and $FF;
  Buf[6] := (Header.RecordCount shr 8) and $FF;
  Buf[7] := (Header.RecordCount shr 16) and $FF;
  Buf[8] := (Header.RecordCount shr 24) and $FF;
  Buf[9] := Header.HeaderSize and $FF;
  Buf[10] := (Header.HeaderSize shr 8) and $FF;
  Buf[11] := Header.RecordSize and $FF;
  Buf[12] := (Header.RecordSize shr 8) and $FF;
  BlockWrite(F, Buf, 32);

  { Write field descriptors (32 bytes each) }
  for I := 1 to Header.FieldCount do
  begin
    FillChar(Buf, SizeOf(Buf), 0);
    for J := 1 to Length(Header.Fields[I].Name) do
      Buf[J] := Ord(Header.Fields[I].Name[J]);
    Buf[12] := Ord(Header.Fields[I].FieldType);
    Buf[17] := Header.Fields[I].Length;
    Buf[18] := Header.Fields[I].Decimals;
    BlockWrite(F, Buf, 32);
  end;

  { Field descriptor terminator (0x0D) }
  Buf[1] := $0D;
  BlockWrite(F, Buf, 1);

  { Write file terminator (0x1A) to indicate no rows }
  Buf[1] := $1A;
  BlockWrite(F, Buf, 1);
end;

procedure UpdateDBFRecordCount(var F: File; NewCount: LongInt);
var
  Buf: array[1..4] of Byte;
begin
  { Seek to record count offset (byte 4, zero-based) }
  Seek(F, 4);
  Buf[1] := NewCount and $FF;
  Buf[2] := (NewCount shr 8) and $FF;
  Buf[3] := (NewCount shr 16) and $FF;
  Buf[4] := (NewCount shr 24) and $FF;
  BlockWrite(F, Buf, 4);
end;

procedure WriteDBFRow(var F: File; Header: TDBFHeader; Values: TDBFValues);
var
  I, J, FieldLen: Integer;
  Buf: Pointer;
  S: string[255];
begin
  GetMem(Buf, Header.RecordSize);
  FillChar(Buf^, Header.RecordSize, Ord(' '));
  PByteArray(Buf)^[0] := Ord(' '); { delete flag }
  for I := 1 to Header.FieldCount do
  begin
    FieldLen := Header.Fields[I].Length;
    S := Values[I];
    if Length(S) > FieldLen then
      S := Copy(S, 1, FieldLen);
    while Length(S) < FieldLen do
      S := S + ' ';
    for J := 1 to FieldLen do
      PByteArray(Buf)^[Header.Fields[I].Offset + J - 1] := Ord(S[J]);
  end;
  BlockWrite(F, Buf^, Header.RecordSize);
  FreeMem(Buf, Header.RecordSize);
end;

procedure SetDBFRowDeleted(var F: File; Deleted: Boolean);
var
  Flag: Byte;
begin
  if Deleted then
    Flag := Ord('*')
  else
    Flag := Ord(' ');
  BlockWrite(F, Flag, 1);
end;

procedure ReadDBFHeader(var F: File; var Header: TDBFHeader);
var
  I, J: Integer;
  Buf: array[1..32] of Byte;
  FieldName: string[11];
  Offs: Integer;
  Done: Boolean;
begin
  { Read main file header (32 bytes) }
  BlockRead(F, Buf, 32);
  Header.Version := Buf[1];
  Header.Year := Buf[2];
  Header.Month := Buf[3];
  Header.Day := Buf[4];
  Header.RecordCount := Buf[5] + (Buf[6] shl 8) + (Buf[7] shl 16) + (Buf[8] shl 24);
  Header.HeaderSize := Buf[9] + (Buf[10] shl 8);
  Header.RecordSize := Buf[11] + (Buf[12] shl 8);

  { Read field descriptors until 0x0D (field descriptor terminator) }
  I := 1;
  Done := False;
  while (I <= DBFMaxFields) and not Done do
  begin
    BlockRead(F, Buf, 1); { peek 1 byte }
    if Buf[1] = $0D then
      Done := True
    else
    begin
      Seek(F, FilePos(F) - 1); { rewind 1 byte }
      BlockRead(F, Buf, 32);   { read descriptor }
      FieldName := '';
      for J := 1 to 11 do
        if Buf[J] <> 0 then
          FieldName := FieldName + Chr(Buf[J]);
      Header.Fields[I].Name := FieldName;
      Header.Fields[I].FieldType := Chr(Buf[12]);
      Header.Fields[I].Length := Buf[17];
      Header.Fields[I].Decimals := Buf[18];
      Inc(I);
    end;
  end;
  Header.FieldCount := I - 1;

  Offs := 1;
  for I := 1 to Header.FieldCount do
  begin
    Header.Fields[I].Offset := Offs;
    Inc(Offs, Header.Fields[I].Length);
  end;
end;

procedure ReadDBFRow(var F: File; var Buf: TDBFRow; RecordSize: Integer);
begin
  BlockRead(F, Buf, RecordSize);
end;

function GetFieldStr(var Buf: TDBFRow; Header: TDBFHeader; FieldIdx: Integer): string;
var
  Offs, Len, I: Integer;
  S: string[255];
begin
  Offs := Header.Fields[FieldIdx].Offset;
  Len := Header.Fields[FieldIdx].Length;
  S := '';
  for I := 0 to Len - 1 do
    S := S + Chr(Buf[Offs + I - 1]);
  GetFieldStr := S;
end;

procedure SetFieldStr(var Buf: TDBFRow; Header: TDBFHeader; FieldIdx: Integer; Value: string);
var
  Offs, Len, I: Integer;
  S: string[255];
begin
  Offs := Header.Fields[FieldIdx].Offset;
  Len := Header.Fields[FieldIdx].Length;
  S := Value;
  if Length(S) > Len then
    S := Copy(S, 1, Len);
  while Length(S) < Len do
    S := S + ' ';
  for I := 0 to Len - 1 do
    Buf[Offs + I - 1] := Ord(S[I + 1]);
end;

function GetActualDBFRowCount(var F: File; Header: TDBFHeader): LongInt;
var
  DiskSize: LongInt;
begin
  DiskSize := FileSize(F);
  if Header.RecordSize = 0 then
    GetActualDBFRowCount := 0
  else if DiskSize < Header.HeaderSize then
    GetActualDBFRowCount := 0
  else
    GetActualDBFRowCount := (DiskSize - Header.HeaderSize) div Header.RecordSize;
end;

procedure SeekToFirstRow(var F: File; Header: TDBFHeader);
begin
  Seek(F, Header.HeaderSize);
end;

procedure SeekToEnd(var F: File; Header: TDBFHeader);
var
  Posn: LongInt;
  DiskRecordCount: LongInt;
  RecordCount: LongInt;
begin
  DiskRecordCount := GetActualDBFRowCount(F, Header);
  RecordCount := Header.RecordCount;

  if DiskRecordCount <> RecordCount then
  begin
    RecordCount := DiskRecordCount;
    UpdateDBFRecordCount(F, RecordCount);
  end;
  if RecordCount = 0 then
    Posn := Header.HeaderSize
  else
    Posn := Header.HeaderSize + (RecordCount) * Header.RecordSize;
  Seek(F, Posn);
end;

procedure SeekToRow(var F: File; const Header: TDBFHeader; RowIndex: LongInt);
var
  Posn: LongInt;
  DiskRecordCount: LongInt;
  RecordCount: LongInt;
begin
  DiskRecordCount := GetActualDBFRowCount(F, Header);
  RecordCount := Header.RecordCount;

  if DiskRecordCount <> RecordCount then
  begin
    RecordCount := DiskRecordCount;
    UpdateDBFRecordCount(F, RecordCount);
  end;

  if RecordCount <= 0 then
  begin
    Seek(F, Header.HeaderSize);
    Exit;
  end;

  if RowIndex < 0 then
    RowIndex := 0;
  if RowIndex > RecordCount - 1 then
    RowIndex := RecordCount - 1;

  Posn := Header.HeaderSize + RowIndex * Header.RecordSize;
  Seek(F, Posn);
end;

procedure AppendDBFRow(var F: File; var Header: TDBFHeader; Values: TDBFValues);
var
  Terminator: Byte;
begin
  SeekToEnd(F, Header);
  WriteDBFRow(F, Header, Values);
  Inc(Header.RecordCount);
  UpdateDBFRecordCount(F, Header.RecordCount);
  Terminator := $1A;
  BlockWrite(F, Terminator, 1);
end;

end.
