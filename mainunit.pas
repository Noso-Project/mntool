unit mainunit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,IdTCPClient, IdGlobal, fileutil, dateutils;

Type
  TMyAddresses = packed Record
    address : string[35];
    ALabel  : string[20];
    Good    : integer;
    Bad     : integer;
    end;

  TMNs = Packed record
    ipandPort : string[21];
    address   : string[35];
    count     : integer;
    end;

  TVerificators = packed Record
    ip    : string[15];
    port  : integer;
    count : integer;
    end;

CONST
  DefaultNodesString = '0 109.230.238.240;8080:N3iEmfEoYhW99Gn6U6EaLfJ3bqmWCD3:114 '+
                      '198.144.190.194;8080:N4DixvMj1ZEBhm1xbxmCNursoZxPeH1:114 '+
                      '107.175.59.177;8080:N4VJxLRtbvngmThBJohq7aHd5BwKbFf:76 '+
                      '107.172.193.176;8080:N3sb23UXr23Som3B11u5q7qR9FvsDC7:114 '+
                      '66.151.117.247;8080:NUhcAdqnVDHtd8NmMMo6sLK3bmYFE5:56 '+
                      '192.3.73.184;8080:N2RJi7FYf76UBH9RyhndTofskzHKuEe:114 '+
                      '107.175.24.151;8080:N4HrfiM6YVw2g4oAmWGKCvU5PXpZ2DM:126 '+
                      '107.174.137.27;8080:N46PiNk7chSURJJZoMSRdwsDh8FAbDa:114';
  LastMNFilename = 'data'+directoryseparator+'last.txt';
  MyAddressesFilename = 'data'+directoryseparator+'addresses.dat';
  AppVersion = '1.0';

Function Parameter(LineText:String;ParamNumber:int64):String;
Procedure CreateTextFile(name:string);
Procedure SaveToFIle(filename:string;ThisText:String);
Procedure LoadLastRequest();
Procedure LoadMyAddresses();
Procedure SaveMyAddresses();
Procedure FillMNsArray();
Procedure FillVerificators();
Function GetAddressUptimeValue(Number:integer):integer;
function GetMainnetMasternodes(Trys:integer=5):boolean;
function GetMainnetTimestamp(Trys:integer=5):int64;
function GetMyLastUpdatedBlock():integer;
// ***** TIME
function GetLocalTimestamp():int64;
Function UTCTime():int64;
function TimestampToDate(timestamp:int64):String;
Function NextBlockTimeStamp():Int64;

Function GetAddressAge(Address:String):integer;

var
  FileAddress    : file of TMyAddresses;
  ArrAddresses   : array of TMyAddresses;
  ArrMNs         : array of TMNs;
  LastValidBlock : integer = 0;
  LastMNsLine    : string = '';
  ArrVers        : array of TVerificators;
  TotalVerifics  : integer = 0;
  // Time
  LocalTIme      : int64;
  OffSet         : integer;
  NextUpdateTime : int64;

implementation

Function Parameter(LineText:String;ParamNumber:int64):String;
var
  Temp : String = '';
  ThisChar : Char;
  Contador : int64 = 1;
  WhiteSpaces : int64 = 0;
  parentesis : boolean = false;
Begin
while contador <= Length(LineText) do
   begin
   ThisChar := Linetext[contador];
   if ((thischar = '(') and (not parentesis)) then parentesis := true
   else if ((thischar = '(') and (parentesis)) then
      begin
      result := '';
      exit;
      end
   else if ((ThisChar = ')') and (parentesis)) then
      begin
      if WhiteSpaces = ParamNumber then
         begin
         result := temp;
         exit;
         end
      else
         begin
         parentesis := false;
         temp := '';
         end;
      end
   else if ((ThisChar = ' ') and (not parentesis)) then
      begin
      WhiteSpaces := WhiteSpaces +1;
      if WhiteSpaces > Paramnumber then
         begin
         result := temp;
         exit;
         end;
      end
   else if ((ThisChar = ' ') and (parentesis) and (WhiteSpaces = ParamNumber)) then
      begin
      temp := temp+ ThisChar;
      end
   else if WhiteSpaces = ParamNumber then temp := temp+ ThisChar;
   contador := contador+1;
   end;
if temp = ' ' then temp := '';
Result := Temp;
End;

Procedure CreateTextFile(name:string);
var
  TFile : TextFile;
Begin
AssignFile(Tfile,name);
Rewrite(TFile);
Closefile(TFile);
End;

Procedure SaveToFIle(filename:string;ThisText:String);
var
  TFile : TextFile;
Begin
AssignFile(Tfile,filename);
Rewrite(TFile);
WriteLn(Tfile,ThisText);
Closefile(TFile);
End;

Procedure LoadLastRequest();
var
  TFile : TextFile;
Begin
AssignFile(Tfile,LastMNFilename);
Reset(TFile);
ReadLn(Tfile,LastMNsLine);
Closefile(TFile);
End;

Procedure LoadMyAddresses();
var
  Counter  : integer;
  TAddress : TMyAddresses;
Begin
SetLength(ArrAddresses,0);
reset(FileAddress);
for counter := 0 to FileSize(FileAddress)-1 do
   begin
   seek(FileAddress,counter);
   read(FileAddress,TAddress);
   insert(TAddress,ArrAddresses, length(ArrAddresses));
   end;
closeFile(FileAddress);
End;

Procedure SaveMyAddresses();
var
  counter : integer;
Begin
Rewrite(FileAddress);
for counter := 0 to length(ArrAddresses)-1 do
   begin
   seek(FileAddress,counter);
   Write(FileAddress,ArrAddresses[counter]);
   end;
CloseFile(FileAddress);
End;

Function GetAddressAge(Address:String):integer;
var
  counter  : integer;
Begin
Result := 0;
For counter := 0 to length(ArrMNs)-1 do
   begin
   if ArrMNs[counter].address=Address then
      begin
      result := ArrMNs[counter].count;
      break;
      end;
   end;
End;

Procedure FillMNsArray();
var
  TValue  : string;
  counter : integer= 1;
  ThisMN    : TMNs;
Begin
SetLength(ArrMNs,0);
LastValidBlock := StrToIntDef(Parameter(LastMNsLine,0),0);
repeat
   TValue := parameter(LastMNsLine,counter);
   if TValue <> '' then
      begin
      TValue := StringReplace(TValue,':',' ',[rfReplaceAll, rfIgnoreCase]);
      ThisMN.ipandPort:=Parameter(Tvalue,0);
      ThisMN.address := Parameter(Tvalue,1);
      ThisMN.count := StrToIntDef(Parameter(TValue,2),0);
      Insert(thisMN,ArrMNs,length(ArrMNs));
      end;
   inc(counter);
until TValue = '';
FillVerificators();
End;

Procedure FillVerificators();
var
  counter, count2 : integer;
  ThisVer : TVerificators;
  TData   : String;
  Added   : boolean;
Begin
SetLength(ArrVers,0);
for counter := 0 to length(ArrMNs)-1 do
   begin
   Added := false;
   TData := StringReplace(ArrMNs[counter].ipandPort,';',' ',[rfReplaceAll, rfIgnoreCase]);
   ThisVer.ip:=Parameter(TData,0);
   ThisVer.port:=StrToIntDef(Parameter(Tdata,1),8080);
   ThisVer.count:=ArrMNs[counter].count;
   if length(ArrVers)= 0 then Insert(ThisVer,ArrVers,0)
   else
      begin
      for count2 := 0 to length(ArrVers)-1 do
         begin
         if ArrMNs[counter].count > ArrVers[count2].count then
            begin
            Insert(ThisVer,ArrVers,count2);
            added := true;
            break;
            end
         end;
      if not Added then Insert(ThisVer,ArrVers,length(ArrVers));
      end;
   end;
TotalVerifics := (length(ArrVers) div 10)+3;
Delete(ArrVers,TotalVerifics,Length(ArrVers));
TotalVerifics := length(ArrVers);
End;

Function GetAddressUptimeValue(Number:integer):integer;
var
  TTotal : integer;
Begin
result := 0;
TTotal := ArrAddresses[number].Good+ArrAddresses[number].Bad;
if TTotal > 0 then result := (ArrAddresses[number].Good*100) div TTotal;

End;

function GetMainnetMasternodes(Trys:integer=5):boolean;
var
  Client     : TidTCPClient;
  RanNode    : integer;
  WasDone    : boolean = false;
  ThisResult : String = '';
  BlckNmb    : integer;
Begin
Result := false;
REPEAT
   RanNode := Random(length(ArrVers));
   Client := TidTCPClient.Create(nil);
   Client.Host:=ArrVers[RanNode].ip;
   Client.Port:=ArrVers[RanNode].port;
   Client.ConnectTimeout:= 3000;
   Client.ReadTimeout:= 3000;
   TRY
   Client.Connect;
   Client.IOHandler.WriteLn('NSLMNS');
   ThisResult := Client.IOHandler.ReadLn(IndyTextEncoding_UTF8);
   WasDone := true;
   EXCEPT on E:Exception do
      begin
      WasDone := False;
      end;
   END{Try};
Inc(Trys);
UNTIL ( (WasDone) or (Trys = 5) );
if client.Connected then Client.Disconnect();
client.Free;
if ThisResult <> '' then
   begin
   BlckNmb := StrToIntDef(parameter(ThisResult,0),0);
   if BlckNmb = 0 then
      begin

      end
   else if BlckNmb <> LastValidBlock then
      begin
      SaveToFile(LastMNFilename,ThisResult);
      LastMNsLine := ThisResult;
      FillMNsArray();
      if not fileexists('data'+directoryseparator+'blocks'+directoryseparator+LastValidBlock.ToString+'.txt') then
         SaveToFile('data'+directoryseparator+'blocks'+directoryseparator+LastValidBlock.ToString+'.txt',ThisResult);
      Result := true;
      end;
   end;
End;

function GetMainnetTimestamp(Trys:integer=5):int64;
var
  Client : TidTCPClient;
  RanNode : integer;
  WasDone : boolean = false;
Begin
Result := 0;
REPEAT
   RanNode := Random(length(ArrVers));
   Client := TidTCPClient.Create(nil);
   Client.Host:=ArrVers[RanNode].ip;
   Client.Port:=ArrVers[RanNode].port;
   Client.ConnectTimeout:= 3000;
   Client.ReadTimeout:= 3000;
   TRY
   Client.Connect;
   Client.IOHandler.WriteLn('NSLTIME');
   Result := StrToInt64Def(Client.IOHandler.ReadLn(IndyTextEncoding_UTF8),0);
   WasDone := true;
   EXCEPT on E:Exception do
      begin
      WasDone := False;
      end;
   END{Try};
Inc(Trys);
UNTIL ( (WasDone) or (Trys = 5) );
if client.Connected then Client.Disconnect();
client.Free;
End;

// Returns the last downloaded block
function GetMyLastUpdatedBlock():integer;
Var
  BlockFiles : TStringList;
  contador : int64 = 0;
  LastBlock : int64 = 0;
  OnlyNumbers : String;
Begin
BlockFiles := TStringList.Create;
   TRY
   FindAllFiles(BlockFiles, 'data'+directoryseparator+'blocks'+directoryseparator, '*.txt', true);
   while contador < BlockFiles.Count do
      begin
      OnlyNumbers := copy(BlockFiles[contador], 13, length(BlockFiles[contador])-16);
      if StrToIntDef(OnlyNumbers,0) > Lastblock then
         LastBlock := StrToIntDef(OnlyNumbers,0);
      Inc(contador);
      end;
   Result := LastBlock;
   EXCEPT on E:Exception do

   END; {TRY}
BlockFiles.Free;
end;

// ****************
// ***** TIME *****
// ****************

// Returns local UNIX time
function GetLocalTimestamp():int64;
Begin
result := DateTimeToUnix(now);
end;

// Returns the UTCTime
Function UTCTime():int64;
var
  G_TIMELocalTimeOffset : int64;
  GetLocalTimestamp : int64;
  UnixTime : int64;
Begin
result := 0;
G_TIMELocalTimeOffset := GetLocalTimeOffset*60;
GetLocalTimestamp := DateTimeToUnix(now);
UnixTime := GetLocalTimestamp+G_TIMELocalTimeOffset;
result := UnixTime-Offset;
End;

// Unix timestamp to human time
function TimestampToDate(timestamp:int64):String;
var
  Fecha : TDateTime;
begin
fecha := UnixToDateTime(timestamp);
result := DateTimeToStr(fecha);
end;

// Next block expected timestamp
Function NextBlockTimeStamp():Int64;
var
  currTime : int64;
  Remains : int64;
Begin
CurrTime := UTCTime;
Remains := 600-(CurrTime mod 600);
Result := CurrTime+Remains;
End;

INITIALIZATION
AssignFile(FileAddress,MyAddressesFilename);
SetLength(ArrAddresses,0);
SetLength(ArrMNs,0);
SetLength(ArrVers,0);

END.

