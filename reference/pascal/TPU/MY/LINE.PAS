unit line;

interface

function  Space(HowSpace:  byte):  string;
function  Left(Str:  string;HowSymb:  byte):  string;
function  Right(Str:  string;HowSymb:  byte):  string;
function  LTrim(Str:  string):  string;
function  RTrim(Str:  string):  string;
function  Trim(Str:  string):  string;
function  Replicate(Symb:  char;HowMany:  byte):  string;
function  Upper(Str:  string):  string;
function  Lower(Str:  string):  string;
function  LwCase(Symb:  char):  char;
function  Equal(First,Second:  string):  boolean;
function  Empty(Str:  string):  boolean;
procedure ArrToString(var Arr:  array of byte;var Str:  string;HowManyBytes:  byte);
function  Letter(Sym:  char):  boolean;
function  Del_Mid_Space(S:  string):  string;
function  RPos(Sym:  char;Strng:  string):  byte;
function  Find_Sym(Sym:  char;S:  string):  byte;
function  StrEmpty(PC_Str:  pchar):  boolean;
function  StrTrim(PC_Str:  pchar):  pchar;
function  StrLeft(Src:  pchar;Size:  byte):  string;
function  StrRight(Src:  pchar;Size:  byte):  string;
function  StrCut(Src:  pchar;FS:  word;Size:  byte):  string;
procedure WordLoc(TSW: string;PK: integer;var NW: integer;B2: char;var LB,RB: byte);

implementation
uses SysUtils, Inter;

function  Space(HowSpace:  byte):  string;
    var
        Counter:        byte;
    begin
    space[0]:=Chr(HowSpace); // SetLength не компилируется
    for Counter:= 1 to HowSpace do
        space[Counter]:=' ';
    end;

function  Left(Str:  string;HowSymb:  byte):  string;
    begin
    if HowSymb> length(Str) then
        HowSymb:= length(Str);
    Left:= copy(Str,1,HowSymb);
    end;

function  Right(Str:  string;HowSymb:  byte):  string;
    begin
    Right:= copy(Str,length(Str)-HowSymb+1,HowSymb);
    end;

function  LTrim(Str:  string):  string;
    var
        C:              byte;

    begin
    LTrim:= '';
    if Str= '' then
        exit;
    for C:= 1 to length(Str) do
        if Str[C]<> ' ' then break;
    if Str[C]= ' ' then exit;
    LTrim:= Right(Str,length(Str)-(C-1));
    end;

function  RTrim(Str:  string):  string;
    var
        C:              byte;

    begin
    if Str= '' then
        begin
        RTrim:= '';
        exit;
        end;
    for C:= length(Str) downto 1 do
        if Str[C]<> ' ' then break;
    if (C= 1) and (Str[1]= ' ') then
        begin
        RTrim:= '';
        exit;
        end;
    RTrim:= Left(Str,C);
    end;

function  Trim(Str:  string):  string;
    var
        Res:            string;
        C:              byte;

    begin
    if Str= '' then
        begin
        Trim:= '';
        exit;
        end;
    for C:= 1 to length(Str) do
        if Str[C]<> ' ' then break;
    Res:= Right(Str,length(Str)-(C-1));
    for C:= length(Res) downto 1 do
        if Res[C]<> ' ' then break;
    Trim:= Left(Res,C);
    end;

function  Replicate(Symb:  char;HowMany:  byte):  string;
    var
        Counter:        byte;
    begin
    Replicate[0]:=Chr(HowMany); // SetLength не компилируется
    for Counter:= 1 to HowMany do
        Replicate[Counter]:= Symb;
    end;

function  Upper(Str:  string):  string;
    var
        Counter:       byte;
    begin
    Upper[0]:=Str[0]; // SetLength не компилируется
    for Counter:= 1 to length(Str) do
        Upper[Counter]:=upcase(Str[Counter]);
    end;

function  Lower(Str:  string):  string;
    var
        Counter:       byte;
    begin
    Lower[0]:=Str[0];
    for Counter:= 1 to length(Str) do
        Lower[Counter]:= LwCase(Str[Counter]);
    end;

function  Equal(First,Second:  string):  boolean;
    begin
    if trim(upper(First))=trim(upper(Second)) then
        Equal:= true
    else
        Equal:= false;
    end;

function  Empty(Str:  string):  boolean;
    var
        Counter:        byte;

    begin
    Empty:= true;
    for Counter:= 1 to length(Str) do
        if Str[Counter]<> ' ' then
            begin
            Empty:= false;
            exit;
            end;
    end;

function  LwCase(Symb:  char):  char;
    var
        Res:            char;

    begin
    Res:= Symb;
    if (ord(Symb)>64) and (ord(Symb)<91) then Res:= chr(ord(Symb)+32);
    if (ord(Symb)>127) and (ord(Symb)<144) then Res:= chr(ord(Symb)+32);
    if (ord(Symb)>143) and (ord(Symb)<160) then Res:= chr(ord(Symb)+80);
    if ord(Symb)=240 then Res:= chr(241);
    LwCase:= Res;
    end;

procedure ArrToString(var Arr:  array of byte;var Str:  string;HowManyBytes:  byte);
    var
        Counter:        byte;

    begin
    Str:= '';
    if HowManyBytes= 0 then exit;
    if HowManyBytes> sizeof(Arr)/sizeof(Arr[0]) then exit;
    SetLength(Str, HowManyBytes);
    for Counter:= 0 to HowManyBytes-1 do
        Str[Counter+1]:= chr(Arr[Counter]);
    end;

function  Letter(Sym:  char):  boolean;
    var
        Code:           byte absolute Sym;

    begin
    Letter:= false;
    if ((Code> 64) and (Code< 91)) or ((Code> 96) and (Code< 123)) or
       ((Code> 127) and (Code< 176)) or ((Code> 223) and (Code< 243)) then
        Letter:= true;
    end;

function  Del_Mid_Space(S:  string):  string;
    var
        R:              string;
        L1:             byte;
        L2:             byte;
        C:              byte;

    begin
    if Empty(S) then
        begin
        Del_Mid_Space:= '';
        exit;
        end;
    L1:= length(S)-length(LTrim(S));
    L2:= length(S)-length(RTrim(S));
    S:= Trim(S);
    for C:= 1 to length(S) do
        begin
        if S[C]= ' ' then
            if (S[C+1]= ' ') and (C< length(S)) then
                begin
                delete(S,C,1);
                inc(C,-1);
                end;
        end;
    Del_Mid_Space:= Space(L1)+S+Space(L2);
    end;

function  RPos(Sym:  char;Strng:  string):  byte;
    var
        C:              byte;

    begin
    RPos:= 0;
    if length(Strng)= 0 then exit;
    for C:= length(Strng) downto 0 do
        if Strng[C]= Sym then break;
    if C> 0 then
        C:= (length(Strng)-C)+1;
    RPos:= C;
    end;

function  StrEmpty(PC_Str:  pchar):  boolean;
    var
        C:              word;

    begin
    if PC_Str= nil then exit;
    StrEmpty:= true;
    C:= 0;
    while PC_Str[C]<> #0 do
        begin
        if PC_Str[C]<> #32 then
            begin
            StrEmpty:= false;
            exit;
            end;
        inc(C);
        end;
    end;

function  StrTrim(PC_Str:  pchar):  pchar;
    begin
    StrTrim:= PC_Str;
    end;

function  StrLeft(Src:  pchar;Size:  byte):  string;
    var
        Res:            string;
        C:              byte;

    begin
    StrLeft:= '';
    if (Src= nil) or (Size= 0) then exit;
    if strlen(Src)< Size then Size:= strlen(Src);
    Res:= '';
    for C:= 0 to Size-1 do
        Res:= Res +Src[C];
    StrLeft:= Res;
    end;

function  StrRight(Src:  pchar;Size:  byte):  string;
    var
        Res:            string;
        C:              byte;

    begin
    StrRight:= '';
    if (Src= nil) or (Size= 0) then exit;
    if strlen(Src)< Size then Size:= strlen(Src);
    Res:= '';
    for c:= strlen(Src)-1 downto strlen(Src)-Size do
        Res:= Src[C] +Res;
    StrRight:= Res;
    end;

function  StrCut(Src:  pchar;FS:  word;Size:  byte):  string;
    var
        Res:            string;
        C:              word;

    begin
    StrCut:= '';
    if (Src= nil) or (Size= 0) then exit;
    if FS> strlen(Src) then exit;
    if Size> strlen(Src)-FS then Size:= strlen(Src)-FS;
    inc(FS,-1);
    Res:= '';
    for c:= FS to FS+Size do
        Res:= Res +Src[C];
    StrCut:= Res;
    end;

procedure WordLoc(TSW: string;PK: integer;var NW: integer;B2: char;var LB,RB: byte);
{#75 - сдвиг на предыдущее слово,}
{#77 - сдвиг на следующее слово,}
{#115 - установка на первое слово,}
{#116 - установка на последнее слово}

    var
        I,J,KW,L:       integer;
        V,VB:           boolean;

    begin
    TSW:= TSW+' ';
    LB:= 0;
    RB:= 0;
    L:= length(TSW);
    if L< 1 then exit;
    if B2= #71 then
        NW:= 1
    else
        if B2= #79 then
            begin
            NW:= 0;
            PK:= L
            end;
    if NW> 0 then
        begin
        PK:= L;
        KW:= NW
        end
    else
        if (PK> L) and not (B2 in [#75,#115]) or (PK< 1) then
            exit
        else
            KW:= 255;
    i:= 1;
    J:= 0;
    V:= true;
    VB:= true;
    while (I<= PK) and (J< KW) do
        begin
        VB:= (TSW[i] in RazdLim);
        if V and not (VB) then
            begin
            inc(J);
            LB:= I
            end;
        V:= VB;
        inc(I);
        end;
    if B2 in [#71,#75,#77,#79,#115,#116] then
        begin
        VB:= false;
        NW:= J
        end;
    if VB or ((NW> 0) and (J<> NW)) then
        LB:= 0
    else
        begin
        NW:= J;
        if ((B2= #75) or (B2= #115)) and not V then
            begin
            I:= LB-1;
            while (I> 0) and (TSW[i] in RazdLim) do dec(I);
            while (I> 0) and not (TSW[i] in RazdLim) do dec(I);
            if not (TSW[i+1] in RazdLim) and (I< (LB-1)) then
                begin
                LB:= I+1;
                dec(NW)
                end;
            end
        else
            if (B2= #77) or (B2= #116) then
                begin
                I:= LB;
                while (I< L) and not (TSW[i] in RazdLim) do inc(I);
                while (I< L) and (TSW[i] in RazdLim) do inc(I);
                if not (TSW[i] in RazdLim) and (I> LB) then
                    begin
                    LB:= I;
                    inc(NW)
                    end;
                end;
        I:= LB;
        while (I<= L) and not (TSW[I] in RazdLim) do inc(I);
        if I< 255 then
            RB:= I
        else
            RB:= 255;
        end;
    end;

function  Find_Sym(Sym:  char;S:  string):  byte;
    var
        CS:             byte;

    begin
    Find_Sym:= 0;
    if Empty(S) then exit;
    for CS:= 1 to length(S) do
        if S[CS]= Sym then
            begin
            Find_Sym:= CS;
            exit;
            end;
    end;

begin
razdlim:= razdlim+[':','@','=','*'];
end.
