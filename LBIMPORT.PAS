{ LBIMPORT.PAS - LaunchBox XML Metadata Importer (Free Pascal version) }
{ Compile with: fpc lbimport.pas }

program LaunchBoxImporter;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes, DOM, XMLRead, GameTypes;

type
  TGameMetadata = record
    Title: String;
    Publisher: String;
    Year: String;
    Genre: String;
  end;

var
  MetadataList: array of TGameMetadata;
  MetadataCount: Integer;

{ Normalize title for matching }
function NormalizeTitle(const Title: string): string;
var
  S: string;
begin
  S := UpperCase(Title);
  S := StringReplace(S, ':', '', [rfReplaceAll]);
  S := StringReplace(S, '-', ' ', [rfReplaceAll]);
  while Pos('  ', S) > 0 do
    S := StringReplace(S, '  ', ' ', [rfReplaceAll]);
  Result := Trim(S);
end;

{ Calculate similarity between two strings (simple algorithm) }
function SimilarityRatio(const S1, S2: string): Real;
var
  Norm1, Norm2: string;
  Matches, MaxLen: Integer;
  I: Integer;
begin
  Norm1 := NormalizeTitle(S1);
  Norm2 := NormalizeTitle(S2);
  
  if (Length(Norm1) = 0) or (Length(Norm2) = 0) then
  begin
    Result := 0.0;
    Exit;
  end;
  
  { Simple matching: count matching characters in order }
  Matches := 0;
  for I := 1 to Length(Norm1) do
    if Pos(Norm1[I], Norm2) > 0 then
      Inc(Matches);
  
  MaxLen := Length(Norm1);
  if Length(Norm2) > MaxLen then
    MaxLen := Length(Norm2);
  
  Result := Matches / MaxLen;
end;

{ Parse LaunchBox XML }
procedure ParseLaunchBoxXML(const FileName: string);
var
  Doc: TXMLDocument;
  Games, Game, Node: TDOMNode;
  I: Integer;
  Title, Publisher, ReleaseDate, Genre: string;
begin
  WriteLn('Parsing LaunchBox XML...');
  
  try
    ReadXMLFile(Doc, FileName);
    
    Games := Doc.DocumentElement;
    MetadataCount := 0;
    SetLength(MetadataList, 10000);
    
    if Assigned(Games) then
    begin
      Game := Games.FirstChild;
      while Assigned(Game) do
      begin
        if Game.NodeName = 'Game' then
        begin
          Title := '';
          Publisher := '';
          ReleaseDate := '';
          Genre := '';
          
          { Extract child nodes }
          Node := Game.FirstChild;
          while Assigned(Node) do
          begin
            if Node.NodeName = 'Title' then
              Title := Node.TextContent
            else if Node.NodeName = 'Publisher' then
              Publisher := Node.TextContent
            else if Node.NodeName = 'ReleaseDate' then
              ReleaseDate := Node.TextContent
            else if Node.NodeName = 'Genre' then
              Genre := Node.TextContent;
            
            Node := Node.NextSibling;
          end;
          
          if Title <> '' then
          begin
            { Extract year from date }
            if Length(ReleaseDate) >= 4 then
              ReleaseDate := Copy(ReleaseDate, 1, 4)
            else
              ReleaseDate := '';
            
            { Handle multiple genres (semicolon separated) }
            if Pos(';', Genre) > 0 then
              Genre := Copy(Genre, 1, Pos(';', Genre) - 1);
            
            { Add to list }
            MetadataList[MetadataCount].Title := Title;
            MetadataList[MetadataCount].Publisher := Copy(Publisher, 1, 30);
            MetadataList[MetadataCount].Year := Copy(ReleaseDate, 1, 4);
            MetadataList[MetadataCount].Genre := Copy(Genre, 1, 20);
            Inc(MetadataCount);
            
            if MetadataCount >= Length(MetadataList) then
              SetLength(MetadataList, Length(MetadataList) + 1000);
          end;
        end;
        
        Game := Game.NextSibling;
      end;
    end;
    
    Doc.Free;
    WriteLn('Found ', MetadataCount, ' games in LaunchBox XML');
  except
    on E: Exception do
    begin
      WriteLn('Error parsing XML: ', E.Message);
      Halt(1);
    end;
  end;
end;

{ Import metadata into GAMES.DAT }
procedure ImportMetadata(const DatFileName: string);
var
  F: file of GameRecord;
  Game: GameRecord;
  BestIdx: Integer;
  BestRatio, Ratio: Real;
  I, UpdateCount: Integer;
  OldPub, OldYear, OldGenre: string;
  BackupName: string;
begin
  if not FileExists(DatFileName) then
  begin
    WriteLn('Error: ', DatFileName, ' not found');
    Halt(1);
  end;
  
  { Create backup }
  BackupName := DatFileName + '.bak';
  WriteLn('Creating backup: ', BackupName);
  try
    if FileExists(BackupName) then
      DeleteFile(BackupName);
    if not CopyFile(PChar(DatFileName), PChar(BackupName), False) then
      WriteLn('Warning: Could not create backup');
  except
    WriteLn('Warning: Backup creation failed');
  end;
  
  WriteLn('Processing GAMES.DAT...');
  WriteLn;
  
  Assign(F, DatFileName);
  Reset(F);
  
  UpdateCount := 0;
  
  while not EOF(F) do
  begin
    Read(F, Game);
    
    if Game.Deleted then
      Continue;
    
    { Find best match in LaunchBox data }
    BestIdx := -1;
    BestRatio := 0.0;
    
    for I := 0 to MetadataCount - 1 do
    begin
      Ratio := SimilarityRatio(Game.Title, MetadataList[I].Title);
      if Ratio > BestRatio then
      begin
        BestRatio := Ratio;
        BestIdx := I;
      end;
    end;
    
    { Update if good match (threshold 0.8) }
    if (BestIdx >= 0) and (BestRatio >= 0.8) then
    begin
      OldPub := Game.Publisher;
      OldYear := Game.Year;
      OldGenre := Game.Genre;
      
      { Update empty fields }
      if Trim(Game.Publisher) = '' then
        Game.Publisher := MetadataList[BestIdx].Publisher;
      if Trim(Game.Year) = '' then
        Game.Year := MetadataList[BestIdx].Year;
      if Trim(Game.Genre) = '' then
        Game.Genre := MetadataList[BestIdx].Genre;
      
      { Write back if changed }
      if (Game.Publisher <> OldPub) or (Game.Year <> OldYear) or 
         (Game.Genre <> OldGenre) then
      begin
        Seek(F, FilePos(F) - 1);
        Write(F, Game);
        Seek(F, FilePos(F));
        
        Inc(UpdateCount);
        WriteLn(Game.Title);
        if Game.Title <> MetadataList[BestIdx].Title then
          WriteLn('  LaunchBox: ', MetadataList[BestIdx].Title, 
                  ' (', BestRatio:0:0, '%)');
        WriteLn('  Publisher: ', OldPub, ' -> ', Game.Publisher);
        WriteLn('  Year:      ', OldYear, ' -> ', Game.Year);
        WriteLn('  Genre:     ', OldGenre, ' -> ', Game.Genre);
        WriteLn;
      end;
    end;
  end;
  
  Close(F);
  
  WriteLn('Updated ', UpdateCount, ' records');
end;

{ Main program }
var
  XMLFile, DatFile: string;
  
begin
  WriteLn('LaunchBox Metadata Importer');
  WriteLn('============================');
  WriteLn;
  
  if ParamCount < 1 then
  begin
    WriteLn('Usage: lbimport <launchbox.xml> [games.dat]');
    WriteLn;
    WriteLn('Imports Publisher, Year, and Genre from LaunchBox XML into GAMES.DAT');
    Halt(1);
  end;
  
  XMLFile := ParamStr(1);
  if ParamCount >= 2 then
    DatFile := ParamStr(2)
  else
    DatFile := 'GAMES.DAT';
  
  if not FileExists(XMLFile) then
  begin
    WriteLn('Error: ', XMLFile, ' not found');
    Halt(1);
  end;
  
  ParseLaunchBoxXML(XMLFile);
  ImportMetadata(DatFile);
  
  WriteLn('Done!');
end.
