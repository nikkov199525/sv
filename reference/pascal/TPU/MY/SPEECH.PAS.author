unit Speech;

interface

const
    VDirc:          string = '';
    SymFile:        string = 'speech.sym';
    RSpace:         boolean = true;

var
    Talk:           boolean;

procedure Say(Mess:  string);
procedure SetDictor(NumDic:  byte);
procedure Set_Temp(Speed:  byte);
procedure SaySymb(Sym:  char);
procedure TalkStatus(Flag:  boolean);
{procedure SayTime;}
procedure SayText(Mess:  string);
procedure Say_Date(D,M,Y:  integer);
procedure Say_Time(H,M:  integer);

implementation
uses line,various,harddisk,hronos,transfrm,dinamic,  zeller,  spick,sayform,  dos,keyboard,
SdrvPrim;

procedure Say(Mess:  string);
    const
        SrcName=        'C:\speaker\speaker.msg';
        TmpName=        'C:\speaker\speaker.tmp';
        FlgName=        'C:\speaker\speaker.000';

    var
        T:              Text;
        F:              file;
        C:              byte;
    begin
    if not Talk then exit;
    Mess:= Del_Mid_Space(Trim(Mess));
    for C:= 176 to 223 do
        while pos(chr(C),Mess)> 0 do
            delete(Mess,pos(chr(C),Mess),1);
    Mess:= Trim(Mess);
    if AdrFon> 0 then
        begin
        if length(Mess)< 200 then
            stext(Mess)
        else
            begin
            stext(Left(Mess,200));
            stext(Right(Mess,length(Mess)-200));
            end;
        end
    else
        begin
        exit;
        if OS<> windows then exit;
        {$I-}
        Assign(T,TmpName);
        Rewrite(T);
        WriteLn(T,Mess);
        Close(T);
        Rename(T,SrcName);
        while not File_Exists(FlgName) and not keypressed do
          DoBackgroundTasks;
        assign(F,FlgName);
        erase(F);
        {$I+}
        end;
    end;

procedure SetDictor(NumDic:  byte);
    var
        OldDirc:        string;
        NewDirc:        string;
        OldDrive:       char;
        NewDrive:       char;

    begin
    if (not Talk) or (adrfon= 0) then
      exit;
    SpkSetVoice(TSpVoice(NumDic));
    end;

procedure Set_Temp(Speed:  byte);
    begin
    if (not Talk) or (adrfon= 0) or (Speed> 150) then exit;
    {asm
        mov ah,4
        mov al,Speed
        int $80
        end;}
      SpkSetTemp(TSpTempo(Speed)); {//ss/28.03.2003 16:21:23//}
    end {proc. Set Temp};

procedure SaySymb(Sym:  char);
    var
        Symb:           text;
        Wrd:            string[32];
        C:              byte;
        IORes:          word;

    begin
    if (not Talk) or (adrfon= 0) then exit;
    assign(Symb,MyDirc+SymFile);
    {$I-}
    IORes:= ioresult;
    reset(Symb);
    if ioresult= 0 then
        begin
        C:= 0;
        while not eof(Symb) do
            begin
            inc(C);
            readln(Symb,Wrd);
            if ord(Sym)= C then
                begin
                Say(Wrd);
                close(Symb);
                exit;
                end;
            end;
        {$I+}
        end;
    if (ord(Sym) in [176..223]) or (ord(Sym) in [1..31]) or
       (ord(Sym) in [242..255]) then
        begin
        Say('си+мвол '+LToS(ord(Sym)));
        exit;
        end;
    if (ord(Sym) in [65..90]) or (ord(Sym) in [128..159]) then
        Signal(S_Cap);
    case Sym of
     ' ':  if RSpace then
            Say('пб')
        else
            Signal(S_Space);
     '\':  Say('слэ+ш');
     '.':  Say('тэ+чк');
     ',':  Say('за+п');
     ':':  Say('дво+');
     '"':  Say('Кавы+');
     '-':  Say('тирэ+.');
     '!':  Say('во+скл.');
     '@':  Say('эт.');
     '#':  Say('Но+мер.');
     '_':  Say('по+д.');
     '+':  Say('плю+с.');
     '=':  Say('равно+.');
     '*':  Say('звё+.');
     '$':  Say('до+ллар.');
     '~':  Say('ти+льда.');
     '?':  Say('во+пр.');
     '/':  Say('дро+бь.');
     '%':  Say('проце+нт.');
     '^':  Say('кры+шка.');
     '&':  Say('а+мпер.');
     '(':  Say('ле+ско.');
     ')':  Say('пра+ско.');
     '|':  Say('ве+рт.');
    '''':  Say('а+по.');
     ';':  Say('тэчзап.');
     '`':  Say('обрапо.');
     '>':  Say('бо+льше.');
     '<':  Say('ме+ньше.');
     'б':  Say('бэ');
     'Б':  Say('бэ');
     'в':  Say('вэ');
     'В':  Say('вэ');
     'к':  Say('кэ');
     'К':  Say('кэ');
     'с':  Say('эс');
     'С':  Say('эс');
     '[':  Say('ле+квас.');
     ']':  Say('пра+квас.');
     '{':  Say('ле+фис.');
     '}':  Say('пра+фис.');
    else
        Say(Sym);
        end;
    end;

procedure TalkStatus(Flag:  boolean);
    begin
    if (Flag) and (OS= Windows) then
        Talk:= false;
    Talk:= Flag;
    end;

{
procedure SayTime;
    var
        Buf:            string[12];
        CTime:          string[8];
        Sym:            char;

    begin
    CTime:= CurrentTime;
    Buf:= ' часов,';
    Sym:= CTime[2];
    if (Sym= '1') and (Left(CTime,2)<> '11') then Buf:= ' час,';
    if Sym in ['2'..'4'] then Buf:= ' часа,';
    Say(Left(CTime,2)+Buf);
    Buf:= ' минут,';
    Sym:= CTime[5];
    if (Sym= '1') and (copy(CTime,4,2)<> '11') then Buf:= ' минута,';
    if Sym in ['2'..'4'] then Buf:= ' минуты,';
    Say(copy(CTime,4,2)+Buf);
    end;
}

procedure SayText(Mess:  string);
    var
        i: Integer;
    begin
    if not Talk then exit;
    for i:=1 to Length(Mess) do
        if (Mess[i] >= #176) and (Mess[i] <= #223) then {псевдографика}
            Mess[i]:=' ';
    Mess:= Del_Mid_Space(Trim(Mess));
    if {AdrFon> 0}true then
        begin
        Mess:= RTrim(LTrim(Mess));
        if length(Mess)< 200 then
            u_r_stext(Mess)
        else
            begin
            u_r_stext(Left(Mess,200));
            u_r_stext(Right(Mess,length(Mess)-200));
            end;
        end;
    end;

procedure Say_Date(D,M,Y:  integer);
    begin
    Case dayofweek(D,M,Y) of
       0:  SText ('Воскресе+нье');
       1:  SText ('Понеде+льник');
       2:  SText ('Вто+рник');
       3:  SText ('среда+');
       4:  SText ('Четве+рг');
       5:  SText ('Пя+тница');
       6:  Stext ('Суббо+та');
        end;
    SayOrdNum (D,'\ое\'+MonthName(M));
    Say_Year (Y);
    end;

procedure Say_Time(H,M:  integer);
    begin
    SayRight (H,'м \час\\а+\о+в');
    if M= 0 then
        SText('Ро+вно')
    else
        Sayright(M,'ж \мину+т\а\ы\\.');
    end;

begin
Talk:= true;
end.