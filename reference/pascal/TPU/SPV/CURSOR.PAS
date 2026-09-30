unit cursor;
{$D-}
interface
procedure HideCursor;
procedure SetCursor(BegLine,EndLine: byte);
procedure ShowCursor;
procedure NormalCursor;
procedure MaxCursor;
function getcursor:word;

implementation
uses video;
var OldCursor: word;

procedure SetCursor(BegLine,EndLine: byte); 
begin
  // FIXME
  SetCursorType(crUnderLine);
end;

function getcursor:word;
begin
  getcursor:=GetCursorType;
end;

procedure HideCursor;
begin
oldcursor:=getcursor;
SetCursorType(crHidden);
end;

procedure ShowCursor;
begin
SetCursorType(OldCursor);
end;

procedure NormalCursor;
begin
SetCursorType(crUnderLine);
end;

procedure MaxCursor;
begin
SetCursorType(crBlock);
end;

begin
end.