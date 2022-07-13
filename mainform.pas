unit mainform;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, Grids,
  ExtCtrls, StdCtrls, Menus, mainunit, LCLType;

type

  { TForm1 }

  TForm1 = class(TForm)
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    PageControl1: TPageControl;
    Panel1: TPanel;
    PopupGrid: TPopupMenu;
    StringGrid1: TStringGrid;
    GridData: TStringGrid;
    TabSheet1: TTabSheet;
    ClockTimer : TTimer;
    procedure MenuItem4Click(Sender: TObject);
    procedure RunUpdate(firstTime:boolean = false);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure GridDataResize(Sender: TObject);
    procedure MenuItem1Click(Sender: TObject);
    procedure MenuItem2Click(Sender: TObject);
    procedure MenuItem3Click(Sender: TObject);
    procedure StringGrid1KeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure StringGrid1Resize(Sender: TObject);
    Procedure ClockTimerEjecutar(Sender: TObject);
  private

  public

  end;

function ThisPercent(percent, thiswidth : integer;RestarBarra : boolean = false):integer;
Procedure UpdateGrid(newblock:boolean = false);

var
  Form1      : TForm1;
  FirstShow  : Boolean = true;
  FirsTTimer : boolean = true;


implementation

{$R *.lfm}

{ TForm1 }

function ThisPercent(percent, thiswidth : integer;RestarBarra : boolean = false):integer;
Begin
result := (percent*thiswidth) div 100;
if RestarBarra then result := result-20;
End;

// Form create
procedure TForm1.FormCreate(Sender: TObject);
Begin
if not DirectoryExists('data') then
   begin
   createdir('data');
   createdir('data'+directoryseparator+'blocks');
   end;
if not DirectoryExists('data'+directoryseparator+'blocks') then createdir('data'+directoryseparator+'blocks');
if not fileExists(LastMNFilename) then
   begin
   CreateTextFile(LastMNFilename);
   SaveToFile(LastMNFilename,DefaultNodesString);
   end;
LoadLastRequest();
FillMNsArray();
if not FileExists(MyAddressesFilename) then CreateTextFile(MyAddressesFilename);
LoadMyAddresses();
Form1.ClockTimer:= TTimer.Create(Form1);
Form1.ClockTimer.Enabled:=false;
Form1.ClockTimer.Interval:=10;
Form1.ClockTimer.OnTimer:= @form1.ClockTimerEjecutar;
End;

// Form show
procedure TForm1.FormShow(Sender: TObject);
Begin
if FirstShow then
   begin
   FirstShow := false;
   StringGrid1.Cells[0,0]:='Address';
   StringGrid1.Cells[1,0]:='Label';
   StringGrid1.Cells[2,0]:='Uptime';
   StringGrid1.Cells[3,0]:='Age';
   StringGrid1.FocusRectVisible := false;
   StringGrid1Resize(nil);
   GridData.FocusRectVisible:=false;
   GridData.GridLineWidth := 0;
   GridDataResize(nil);
   UpdateGrid();
   ClockTimer.Enabled:=true;
   end;
End;

// GRid addresses on keyup
procedure TForm1.StringGrid1KeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);

   Procedure TryMoveUpAddress();
   var
     tempdata:TMyAddresses;
     CurrRow : integer;
   Begin
   CurrRow := stringgrid1.Row-1;
   if CurrRow>0 then
      begin
      tempdata := ArrAddresses[currRow-1];
      ArrAddresses[currRow-1] := ArrAddresses[currRow];
      ArrAddresses[currRow] := Tempdata;
      UpdateGrid;
      stringgrid1.Row :=stringgrid1.Row-1
      end;
   end;

   Procedure TryMoveDownAddress();
   var
     tempdata:TMyAddresses;
     CurrRow : integer;
   Begin
   CurrRow := stringgrid1.Row-1;
   if CurrRow<length(ArrAddresses)-1 then
      begin
      tempdata := ArrAddresses[currRow+1];
      ArrAddresses[currRow+1] := ArrAddresses[currRow];
      ArrAddresses[currRow] := Tempdata;
      UpdateGrid;
      SaveMyAddresses();
      stringgrid1.Row :=stringgrid1.Row+1
      end;
   end;

begin
if stringgrid1.Row>0 then
   begin
   if (Key = VK_Q) then
      TryMoveUpAddress;
   if (Key = VK_A) then
      TryMoveDownAddress;
   if (Key = VK_DELETE) then
      begin
      delete(ArrAddresses,stringgrid1.Row-1,1);
      SaveMyAddresses();
      UpdateGrid();
      end;
   if (Key = VK_ADD) then
      begin
      MenuItem3Click(nil);
      end
   end
end;

// PopUp New
procedure TForm1.MenuItem3Click(Sender: TObject);
var
  newaddr : string = '';
  Counter : integer;
  IsValid : boolean = true;
  Tnew    : TMyAddresses;
Begin
if InputQuery('New Address', 'Enter Address', newaddr) then
   begin
   newaddr := Trim(newaddr);
   for counter := 0 to length(ArrAddresses)-1 do
      begin
      if newaddr = ArrAddresses[counter].address then
         begin
         IsValid := false;
         break;
         end;
      end;
   if IsValid then
      begin
      Tnew.address := newaddr;
      TNew.ALabel  :='';
      TNew.Good    :=0;
      TNew.Bad     :=0;
      Insert(Tnew,ArrAddresses,length(ArrAddresses));
      SaveMyAddresses();
      UpdateGrid();
      stringgrid1.Row :=stringgrid1.Rowcount-1;
      end;
   end;
End;

// PopUp delete
procedure TForm1.MenuItem1Click(Sender: TObject);
Begin
if stringgrid1.Row>0 then
   begin
   delete(ArrAddresses,stringgrid1.Row-1,1);
   SaveMyAddresses();
   UpdateGrid();
   end;

End;

// PopUpLabel
procedure TForm1.MenuItem2Click(Sender: TObject);
var
  newlabel : string= 'Test example';
Begin
newlabel := ArrAddresses[stringgrid1.Row-1].ALabel;
if InputQuery('Edit label', 'Enter label', newlabel) then
   begin
   ArrAddresses[stringgrid1.Row-1].ALabel := newlabel;
   SaveMyAddresses();
   UpdateGrid();
   end;
End;

// Button to update
procedure TForm1.RunUpdate(firstTime:boolean = false);
Begin
if GetMainnetMasternodes then
   begin
   UpdateGrid(true);
   NextUpdateTime := NextBlockTimeStamp+30;
   end
else
   begin
   if not firstTime then
      NextUpdateTime := NextUpdateTime+15;
   end;
End;

// Popup reset
procedure TForm1.MenuItem4Click(Sender: TObject);
Begin
if stringgrid1.Row>0 then
   begin
   ArrAddresses[stringgrid1.Row-1].Bad := 0;
   ArrAddresses[stringgrid1.Row-1].good := 0;
   SaveMyAddresses();
   UpdateGrid();
   end;
End;

// Updates the screen
Procedure UpdateGrid(newblock:boolean = false);
var
  counter    : integer;
  TValue     : integer;
  empty      : integer = 0;
  CurrRow    : integer;
  ThisUptime : integer;
  TotalUptime: integer = 0;
Begin
CurrRow := Form1.StringGrid1.Row;
Form1.StringGrid1.RowCount:=1;
form1.StringGrid1.Cells[0,0] := Format('Addresses (%d)',[length(ArrAddresses)]);
for counter := 0 to length(ArrAddresses)-1 do
   begin
   TValue := GetAddressAge(ArrAddresses[counter].address);
   if TValue = 0 then Inc(Empty);
   if newblock then
      begin
      if TValue = 0 then Inc(ArrAddresses[counter].Bad)
      else Inc(ArrAddresses[counter].good);
      end;
   form1.StringGrid1.RowCount := form1.StringGrid1.RowCount+1;
   Form1.StringGrid1.Cells[0,counter+1] := ArrAddresses[counter].address;
   Form1.StringGrid1.Cells[1,counter+1] := ArrAddresses[counter].ALabel;
   ThisUptime := GetAddressUptimeValue(counter);
   TotalUptime := TotalUptime + ThisUptime;
   Form1.StringGrid1.Cells[2,counter+1] := Format('%d %% (%d)',[ThisUptime,ArrAddresses[counter].Bad+ArrAddresses[counter].good]);
   Form1.StringGrid1.Cells[3,counter+1] := TValue.ToString;
   end;
if newblock then SaveMyAddresses;
if empty = 0 then Form1.StringGrid1.Cells[0,0] := format('Addresses (%d)',[length(ArrAddresses)])
else Form1.StringGrid1.Cells[0,0] := format('Addresses (%d) - %d offline',[length(ArrAddresses), empty]);
form1.GridData.Cells[0,0]:='Block: '+LastValidBlock.ToString;
form1.GridData.Cells[0,1]:=Format('Nodes: %d (%d)',[length(ArrMNs),TotalVerifics]);
form1.GridData.Cells[1,0]:=Format('Avg. uptime : %d %%',[TotalUptime div length(ArrAddresses)]);
Form1.StringGrid1.Row := CurrRow;
End;

procedure TForm1.StringGrid1Resize(Sender: TObject);
var
  GridWidth : integer;
begin
GridWidth := StringGrid1.Width;
StringGrid1.ColWidths[0]:= thispercent(40,GridWidth);
StringGrid1.ColWidths[1]:= thispercent(30,GridWidth);
StringGrid1.ColWidths[2]:= thispercent(15,GridWidth);
StringGrid1.ColWidths[3]:= thispercent(15,GridWidth,true);
End;

procedure TForm1.GridDataResize(Sender: TObject);
var
  GridWidth : integer;
begin
GridWidth := GridData.Width;
GridData.ColWidths[0]:= thispercent(50,GridWidth);
GridData.ColWidths[1]:= thispercent(49,GridWidth);
End;

// Timer runs
Procedure TForm1.ClockTimerEjecutar(Sender: TObject);
var
  MainNetTime : int64;
Begin
ClockTimer.Enabled:=false;
if FirstTimer then
   begin
   FirstTimer := false;
   MainNetTime := GetMainnetTimestamp();
   If MainNetTime <> 0 then OffSet := UTCTime-MainNetTime;
   ClockTimer.Interval:=200;
   NextUpdateTime := NextBlockTimeStamp+30;
   RunUpdate(true);
   Form1.StringGrid1.SetFocus;
   end;
if UTCTime >= NextUpdateTime then RunUpdate;
form1.GridData.Cells[0,2]:= TimestampToDate(UTCTime);
form1.GridData.Cells[1,2]:= Format('Next : %d second',[NextUpdateTime-UTCTime]);
ClockTimer.Enabled:=true;
End;

END.

