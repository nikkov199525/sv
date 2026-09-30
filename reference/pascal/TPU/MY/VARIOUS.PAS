unit Various;

interface

type
    tOS=            (dos6_22,windows);
    Tetrada=        0..$F;

var
    OS:             tOS;

function  iif(Choice:  boolean;S1,S2:  string):  string;
function  LTetr(B:  byte):  Tetrada;
function  HTetr(B:  byte):  Tetrada;
function  Paste_Tetrads(B1,B2:  byte):  byte;

implementation

procedure Detect_OS;
    begin
        OS:= windows
    end;

function  iif(Choice:  boolean;S1,S2:  string):  string;
    begin
    if Choice then
        iif:= S1
    else
        iif:= S2;
    end;

function  LTetr(B:  byte):  Tetrada;
    var
        T:              byte;

    begin
    LTetr:= B and $f;
    end;

function  HTetr(B:  byte):  Tetrada;
    begin
    HTetr:= B shr 4;
    end;

function  Paste_Tetrads(B1,B2:  byte):  byte;
    begin
    if (B2 and $01)<> 0 then
        inc(B1,$10);
    if (B2 and $02)<> 0 then
        inc(B1,$20);
    if (B2 and $04)<> 0 then
        inc(B1,$40);
    if (B2 and $08)<> 0 then
        inc(B1,$80);
    Paste_Tetrads:= B1;
    end;


begin
Detect_OS;
end.