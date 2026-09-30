{$mode objfpc}
unit ff_win;

interface

function SameFileName(const FileName1, FileName2: String): Boolean;
function LowerFileName(const S: string): string;

implementation
uses Windows;

function LowerFileName(const S: string): string;
var
  Len: Integer;
begin
  Len := Length(S);
  SetString(Result, PChar(@S[1]), Len);
  if Len > 0 then CharLowerBuff(Pointer(@Result[1]), Len);
end;

function AnsiCompareStr(const S1, S2: string): Integer;
begin
  Result := CompareString(LOCALE_USER_DEFAULT, 0, PChar(@S1[1]), Length(S1),
    PChar(@S2[1]), Length(S2)) - 2;
end;

function SameFileName(const FileName1, FileName2: String): Boolean;
begin
  SameFilename:=AnsiCompareStr(LowerFileName(FileName1), LowerFileName(FileName2)) = 0;
end;


end.
