unit transfrm;

interface
uses tables,  dos;

type
    tPrefix=        record
                        BigLat:         char;
                        SmlLat:         char;
                        BigRus:         char;
                        SmlRus:         char;
                        Number:         char;
                        RSlash:         char;
                        BSlash:         char;
                        end;
    tCode=          string[2];

const
    Filler:  char = 'Û';
    BackGround:  char = '°';

var
    Prefix:         tPrefix;
    Attitude:       1..50;
    AfterSymb:      string;
    BiforeSymb:     string;
    OneSpaceBifore: string;
    OneSpaceAfter:  string;
    LeftOver:       string;
    MaxWidth:          byte;
    MinWidth:       byte;
    CutAfter:       string;
    CutBifore:      string;
    SeparateClass:  char;
    Table_1:        toRecode;
    Table_2:        toDefinition;
    CutString:      boolean;

procedure Transform(var Strng:  string);
procedure DelSpace(var Strng:  string);
procedure Cut(var Strng:  string);
procedure Lat2Rus(var Strng:  string);
procedure TransformFile(From,Where:  string);
function  LtoS(Number:  longint):  string;
function  BToH(Byt:  byte):  tCode;
function  SToH(Strng:  string):  string;
function  BToB(Byt:  byte):  string;
procedure ReputStrng(var Strng:  string; const Tab: tReput);
procedure Reput(GF,PF:  string; const Tab: tReput);
function  CutDirectory(Dir:  string;HowSymb:  byte):  string;
function  Scale(Part:  longint;Full:  longint;Width:  byte):  string;
function  HToB(Hix:  tCode):  byte;
procedure winStringFromUtf8(var s: String);

implementation
uses mymath,line,Dinamic,various, harddisk, windows;

procedure Transform(var Strng:  string);
    var 
        Result:         string; 
        Counter:        byte; 
        Meaning:        byte; 
        Mark:           boolean; 
 
    function  Automaton(Symb:  char):  string; 
        var 
            Res:            string[3]; 
            MS:             array[boolean] of 1..2; 
 
        begin 
        MS[true]:= 2; 
        MS[false]:= 1; 
        case Meaning of 
           0:  res:= Table_1.Recode[Symb]; 
           1:  res:= Prefix.BigLat +Table_1.Recode[Symb]; 
           2: 
                begin 
                res:= Table_1.Recode[Symb]; 
                Meaning:= 1; 
                end; 
           3:  res:= Prefix.SmlLat +Table_1.recode[Symb]; 
           4: 
                begin 
                res:= Table_1.Recode[Symb]; 
                Meaning:= 3; 
                end; 
           5:  res:= Prefix.BigRus +Table_1.Recode[Symb]; 
           6: 
                begin 
                res:= Table_1.Recode[Symb]; 
                Meaning:= 5; 
                end; 
           7:  res:= Prefix.Number +Table_1.Recode[Symb]; 
           8: 
                begin 
                res:= Table_1.Recode[Symb]; 
                Meaning:= 7; 
                end; 
           9: 
                begin 
                res:= Table_1.Recode[Symb][MS[Mark]]; 
                Mark:= not Mark; 
                end; 
            end; 
        Automaton:= res; 
        end; 
 
    begin 
    Mark:= false; 
    Result:= ''; 
    Meaning:= 0; 
    for Counter:= 1 to length(Strng) do 
        begin 
        case Table_2.definition[Strng[Counter]] of 
         $00: 
                begin 
                if Meaning= 8 then 
                    Result:= Result +' ' +Prefix.Number 
                else 
                    Result:= Result +' '; 
                continue; 
                end; 
         $06:  if meaning<> 1 then 
                   meaning:= 1 
               else 
                   Meaning:= 2; 
         $07:  if ((Meaning= 0) or (Meaning> 3)) and 
                  (Table_2.Definition[Strng[Counter-1]]<> $02) then 
                   meaning:= 3 
               else 
                   meaning:= 4; 
         $08:  if (meaning<> 5) and (Table_2.Definition[Strng[Counter+1]]=$08) then 
                   meaning:= 5 
               else 
                   Meaning:= 6; 
         $09:  Meaning:= 0; 
         $05:  if meaning<>7 then 
                   meaning:= 7 
               else 
                   Meaning:= 8; 
         $03:  Meaning:= 9; 
        else 
            Meaning:= 0; 
            end; 
        Result:= Result +automaton(Strng[Counter]); 
        end; 
    Strng:= Result; 
    end; 
 
procedure Cut(var Strng:  string); 
    var 
        Result:         string; 
        TWidth:         byte; 
        Counter:        byte; 
 
    begin 
    Result:= ''; 
    LeftOver:= ''; 
    if length(Strng)<=MaxWidth then 
        exit; 
    TWidth:= MaxWidth; 
    Result:= ''; 
    for Counter:= length(Strng) downto 1 do 
        begin 
        if (pos(Strng[Counter],CutAfter)>0) and ((Counter>MinWidth) and (Counter<MaxWidth)) then 
            begin 
            tWidth:= Counter; 
            break; 
            end; 
        if (pos(Strng[Counter],CutBifore)>0) and ((Counter>MinWidth+1) and (Counter<MaxWidth)) then 
            begin 
            tWidth:= Counter-1; 
            break; 
            end; 
        end; 
    Result:= rtrim(left(Strng,TWidth)); 
    LeftOver:= trim(right(Strng,length(Strng)-TWidth)); 
    if empty(LeftOver) then LeftOver:= ''; 
    Strng:= Result; 
    end; 
 
procedure Lat2Rus(var Strng:  string);
    var
        C:              byte;
        Res:            string;

    begin
    Res:= '';
    for C:= 1 to length(Strng) do
        begin
        case Strng[C] of
         'p':  Res:= Res +'à';
         'P':  res:= Res +'';
         'H':  Res:= Res +'';
         'c':  Res:= Res +'á';
         'C':  Res:= Res +'‘';
         'y':  Res:= Res +'ã';
         'Y':  Res:= Res +'“';
         'b':  Res:= Res +'¢';
         'B':  Res:= Res +'‚';
        else
            Res:= Res +Strng[C];
            end;
    if (ord(Strng[2]) in [128..175]) or (ord(Strng[2]) in [224..241]) then
        case Strng[1] of
         'p':  Res[1]:= 'à';
         'P':  res[1]:= '';
         'H':  Res[1]:= '';
         'c':  Res[1]:= 'á';
         'C':  Res[1]:= '‘';
         'y':  Res[1]:= 'ã';
         'Y':  Res[1]:= '“';
            end;
        end;
    Strng:= Res;
    end;

procedure TransformFile(From,Where:  string);
    var 
        GetFile:        text; 
        PutFile:        text; 
        Row:            string; 
        HowLines:       longint; 
        Temp:           word; 
 
    begin 
    Temp:= ioresult; 
    {$I-} 
    if not File_Exists(From) then
        exit; 
    assign(GetFile,From); 
    assign(PutFile,Where); 
    reset(GetFile); 
    rewrite(PutFile); 
    HowLines:= 0; 
    while not eof(GetFile) do 
        begin 
        readln(GetFile,Row); 
        transform(Row); 
        lat2rus(Row); 
        delspace(Row); 
        writeln(PutFile,Row); 
        Signal(S_Tick); 
        inc(HowLines); 
        end; 
    close(GetFile); 
    close(PutFile); 
    {$I+} 
    end; 
 
function  LToS(Number:  longint):  string; 
    var 
        Prototype:      string; 
        Significance:   string; 
 
    begin 
    str(Number,Prototype); 
    Significance:= ''; 
    while length(Prototype)>3 do 
        begin 
        if SeparateClass= #0 then 
            Significance:= right(Prototype,3) +Significance 
        else 
            Significance:= Separateclass +right(Prototype,3) +Significance; 
        Prototype:= left(Prototype,length(Prototype)-3); 
        end; 
    LToS:= Prototype +Significance; 
    end; 
 
function  BToH(Byt:  byte):  tCode; 
    var 
        Result:         tCode; 
        Buffer:         tCode; 
        Byt1:           byte; 
        Byt2:           byte; 
 
    begin 
    Result:= ''; 
    Buffer:= ''; 
    Byt1:= byt and $F; 
    byt2:= Byt shr 4; 
    if Byt2<10 then 
        str(Byt2,Buffer)
    else
        Buffer:= chr(Byt2+55);
    Result:= Buffer;
    if Byt1<10 then
        str(Byt1,Buffer)
    else
        Buffer:= chr(Byt1+55);
    Result:= Result +Buffer;
    BToH:= Result; 
    end; 
 
function  SToH(Strng:  string):  string; 
    var 
        Result:         string; 
        Counter:        byte; 
 
    begin 
    Result:= ''; 
    for Counter:= 1 to length(Strng) do 
        begin 
        Result:= Result +btoH(ord(Strng[Counter])) +' '; 
        if length(Result)=255 then break; 
        end; 
    SToH:= Result; 
    end; 
 
function  BToB(Byt:  byte):  string; 
    var 
        Res:            string; 
 
    begin 
    Res:= ''; 
    Res:= iif((Byt and $80)<>0,'1','0'); 
    Res:= Res +iif((Byt and $40)<>0,'1','0'); 
    Res:= Res +iif((Byt and $20)<>0,'1','0'); 
    Res:= Res +iif((Byt and $10)<>0,'1','0'); 
    Res:= Res +iif((Byt and $08)<>0,'1','0'); 
    Res:= Res +iif((Byt and $04)<>0,'1','0'); 
    Res:= Res +iif((Byt and $02)<>0,'1','0'); 
    Res:= Res +iif((Byt and $01)<>0,'1','0'); 
    BToB:= Res; 
    end; 
 
procedure ReputStrng(var Strng:  string;const Tab:  tReput);
    var 
        Counter:        byte; 
    begin 
    for Counter:= 1 to length(Strng) do 
        Strng[Counter]:=Tab[Strng[Counter]]; 
    end; 
 
procedure Reput(GF,PF:  string;const Tab:  tReput); 
    var 
        GetFile:        text; 
        PutFile:        text; 
        Buffer:         string; 
        Counter:        byte; 
        Temp:           word; 
 
    begin 
    if not File_Exists(GF) then
        exit;
    Temp:= ioresult; 
    {$I-} 
    assign(GetFile,GF); 
    assign(PutFile,PF); 
    reset(GetFile); 
    rewrite(PutFile); 
    Buffer:= ''; 
    randomize; 
    while not eof(GetFile) do 
        begin 
        readln(GetFile,Buffer); 
        ReputStrng(Buffer,Tab); 
        writeln(PutFile,Buffer); 
        Signal(S_Tick); 
        end; 
    close(GetFile); 
    close(PutFile); 
    {$I+} 
    end; 
 
function  CutDirectory(Dir:  string;HowSymb:  byte):  string; 
    var 
        Directory:      string; 
        repairing:      string; 
        Counter:        word;

    begin
    CutDirectory:= '';
    if (length(Dir)<HowSymb) then
        begin 
        CutDirectory:= Dir; 
        exit; 
        end; 
    if HowSymb<25 then exit; 
    Repairing:= Dir; 
    for counter:= 4 to length(Repairing) do 
        if copy(Repairing,counter,1)='\' then break; 
    Directory:= left(Dir,counter); 
    Repairing:= right(Repairing,Length(Repairing)-counter); 
    while length(Repairing)>HowSymb-length(Directory)-5 do 
        begin 
        for counter:= 1 to length(Repairing) do 
            if copy(Repairing,counter,1)='\' then break; 
        Repairing:= right(Repairing,length(Repairing)-counter); 
        end; 
    CutDirectory:= Directory+'...\' +Repairing; 
    end; 
 
procedure DelSpace(var Strng:  string); 
    var 
        Counter:        byte; 
        Result:         string; 
        HowSpace:       byte; 
        CountSpace:     byte; 
 
    begin 
    Result:= ''; 
    for Counter:= 1 to length(Strng) do 
        begin
        HowSpace:= 0;
        CountSpace:= 0;
        while (Strng[Counter]=' ') and (Counter<length(Strng)) do
            begin
            inc(CountSpace);
            inc(Counter);
            end;
        if CountSpace>0 then
            HowSpace:= CountSpace div Attitude;
        if CountSpace/Attitude<>round(CountSpace/Attitude) then
            inc(HowSpace);
        if pos(Result[length(Result)],AfterSymb)>0 then
            HowSpace:= 0;
        if ((pos(Result[length(Result)],OneSpaceAfter)>0) and
           (Strng[Counter]<>Result[length(Result)])) and 
           (Result[length(Result)]<>'.') then 
            HowSpace:= 1; 
        if (pos(Strng[Counter],OneSpaceBifore)>0) and 
           (Strng[Counter]<>Result[length(Result)]) then 
            HowSpace:= 1; 
        if (Strng[Counter]='-') and (Result[length(Result)]='.') then 
            HowSpace:= 0; 
        if pos(Strng[Counter],BiforeSymb)>0 then 
            HowSpace:= 0; 
        Result:= concat(Result,space(HowSpace),Strng[Counter]); 
        end; 
    Strng:= Result; 
    end; 
 
function  Scale(Part:  longint;Full:  longint;Width:  byte):  string; 
    var 
        Dots:           byte; 
 
    begin 
    if Width>80 then Width:= 80; 
    Dots:= percent(Part/(100/(Width-2)),Full); 
    Scale:= '['+replicate(Filler,Dots)+replicate(BackGround,(Width-2)-Dots)+']'; 
    end;

function  HToB(Hix:  tCode):  byte;
    var
        Res:            byte;
        Num:            byte;
        Err:            integer;

    begin
    Res:= 0;
    if ord(Hix[1]) in [48..57] then
        begin
        val(Hix[1],Num,Err);
        Res:= Num*16;
        end
    else
        if ord(upcase(Hix[1])) in [65..70] then
            Res:= (ord(upcase(Hix[1]))-55)*16;
    if ord(Hix[2]) in [48..57] then
        begin
        val(Hix[2],Num,Err);
        Res:= Res+Num;
        end
    else
        if ord(upcase(Hix[2])) in [65..70] then
            Res:= Res +ord(upcase(Hix[2]))-55;
    HToB:= Res;
    end;

procedure winStringFromUtf8(var s: String);
var
  u: UnicodeString;
  offset, len: Integer;
begin
  SetLength(u, Length(s));
  SetLength(u, Utf8ToUnicode(@u[1], Length(u), @s[1], Length(s)) - 1);
  if Length(u) = 0 then begin
    s:='';
    Exit;
  end;
  if Ord(u[1]) = $FEFF then begin
    // Byte Order Mark (BOM)
    offset:=2;
    len:=Length(u)-1;
  end else begin
    offset:=1;
    len:=Length(u);
  end;
  SetLength(s, 255);
  SetLength(s, WideCharToMultiByte(1251, 0, @u[offset], len, @s[1], Length(s), nil, nil));
end;

begin
with Prefix do
    begin
    BigLat:= ':';
    SmlLat:= ',';
    BigRus:= '>';
    SmlRus:= '!';
    Number:= '#';
    RSlash:= ',';
    BSlash:= '"';
    end;
Attitude:= 3;
AfterSymb:= ';,(';
BiforeSymb:= '?!.);:%,';
LeftOver:= '';
MaxWidth:= 36;
MinWidth:= 20;
CutAfter:= '1465) 0';
CutBifore:= '(8';
SeparateClass:= ',';
CutString:= false;
OneSpaceBifore:= '(';
OneSpaceAfter:= ').';
end.