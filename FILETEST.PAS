{ FILETEST.PAS - Simple test module for MASTERDB.PAS }

program FileTest;

uses MASTERDB;

begin
  CreateMasterDBFfromTXT('impmstr.txt', 'master.dbf');
  WriteLn('Conversion complete.');

    var
      Records: array[1..1000] of MasterRecord;
      RecCount, I: Integer;
  
    ReadMasterDBF('master.dbf', Records, RecCount);
    WriteLn('Title', #9, 'Publisher', #9, 'Year');
    for I := 1 to RecCount do
      WriteLn(Records[I].TITLE, #9, Records[I].PUBLISHER, #9, Records[I].YEARMIN);

    WriteMasterTXTfromDBF('expmstr.txt', Records, RecCount);
    WriteLn('Exported to expmstr.txt.');
  
end.
