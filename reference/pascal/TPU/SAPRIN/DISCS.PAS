unit discs;

interface

function GetCurDisk: Byte;
function SetCurDisk( D: Byte): Boolean;
function AvailableDisks: string;

implementation
uses SysUtils;

function GetCurDisk: Byte;
var
  dir: AnsiString;
begin
  dir:=GetCurrentDir;
  if (Length(dir) > 1) and (dir[2] = ':') then
    GetCurDisk:=ord(UpCase(dir[1]))-ord('A')
  else
    GetCurDisk:=2;
end;

function SetCurDisk( D: Byte): Boolean;
var
  dir: AnsiString;
begin
  GetDir(D + 1, dir);
  SetCurrentDir(dir);
  SetCurDisk:=GetCurDisk = D;
end;

function AvailableDisks: string;
var
   CurDisk: Byte;
   C: Char;
   Result: string;

begin
CurDisk:=GetCurDisk;
Result:= '';
for C:= 'A' to 'Z' do
    begin
    if SetCurDisk( Ord( C)- Ord( 'A')) then
       Result:= Result+ C;
    end;
SetCurDisk( CurDisk);
AvailableDisks:= Result;
end;

BEGIN
END.