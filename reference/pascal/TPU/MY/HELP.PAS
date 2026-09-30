unit Help;
{$I-,V-}
interface
uses mem,  dos;

type
    tString=        string[70];
    tHelpFile=      file of tString;
    tReference=     record
                        FLine:          longint;
                        ELine:          longint;
                        end;
    tpoHelp=        ^toHelp;
    toHelp=         object
                        public
                            Loaded:         boolean;
                            HelpFile:       tHelpFile;
                            FPath:          dirstr;
                            FName:          namestr;
                            FExtn:          extstr;
                            References:     toMemory;
                            Usage_Mem:      tMemory;

                        constructor Load(FN:  string;M:  tMemory);
                        procedure   CallPart(NumPart:  word);
                        destructor  Release;
                        end;

var
    Context:        word;

implementation
uses line,dialog,keyb,keyboard,{$IFDEF SV_MOUSE}mouse,{$ENDIF}speech,dinamic,hronos;

var
    IOR:            word;

constructor toHelp.Load(FN:  string;M:  tMemory);
    var
        Buf_Str:        tString;
        Buf_Num:        word;
        Buf_Rnc:        tReference;
        Err:            integer;
        C:              longint;

    begin
    Loaded:= false;
    assign(HelpFile,FN);
    IOR:= ioresult;
    reset(HelpFile);
    if ioresult<> 0 then exit;
    Usage_Mem:= M;
    References.Sorce:= '';
    References.Define(Usage_Mem,sizeof(tReference));
    if not References.InitMemory then exit;
    fsplit(FN,FPath,FName,FExtn);
    if Empty(FPath) then
        fsplit(fexpand(FN),FPath,FName,FExtn);
    Buf_Str:= '';
    Buf_Num:= 0;
    Buf_Rnc.FLine:= 0;
    Buf_Rnc.ELine:= 0;
    read(HelpFile,Buf_Str);
    if Buf_Str= 'end discription' then Release;
    C:= 1;
    repeat
        val(Buf_Str,Buf_Num,Err);
        if Err= 0 then
            begin
            Buf_Rnc.FLine:= Buf_Num;
            seek(HelpFile,C);
            read(HelpFile,Buf_Str);
            if Buf_Str= 'end discription' then Release;
            val(Buf_Str,Buf_Num,Err);
            if Err= 0 then
                if Buf_Rnc.FLine< Buf_Num then
                    if Buf_Num<= filesize(HelpFile) then
                        begin
                        Buf_Rnc.ELine:= Buf_Num;
                        References.Add(Buf_Rnc);
                        end;
            end;
        seek(HelpFile,C+1);
        read(HelpFile,Buf_Str);
        inc(C,2);
    until Buf_Str= 'end discription';
    if References.HowManyElem< 1 then Release;
    Loaded:= true;
    end;

procedure   toHelp.CallPart(NumPart:  word);
    var
        Buf_Str:        tString;
        First_Str:      string;
        Buf_Rnc:        tReference;
        Point:          longint;
        OldScreen:      tScreen;
        Fix:            longint;
        C:              longint;

    begin
    if not Loaded then exit;
    if not References.Pick(NumPart,Buf_Rnc) then exit;
    OldScreen:=BufScreen;
    Clear(5,3,76,22);
    Frame(5,3,76,22);
    seek(HelpFile,Buf_Rnc.FLine);
    read(HelpFile,Buf_Str);
    if not Empty(Buf_Str) then
        begin
        Say(Buf_Str);
        PutLine(((80-(length(Buf_Str)+2)) div 2)+1,3,' '+Buf_Str+' ',Color.Title);
        end;
    Point:= Buf_Rnc.FLine+1;
    while true do
        begin
        for C:= 1 to 18 do
            begin
            if (Point+C)-1<= Buf_Rnc.ELine then
                begin
                seek(HelpFile,(Point+C)-1);
                read(HelpFile,Buf_Str);
                Buf_Str:= Buf_Str+Space(70-length(Buf_Str));
                if C= 1 then
                    First_Str:= Buf_Str;
                end
            else
                Buf_Str:= Space(70);
            PutLine(6,3+C,Buf_Str,Color.Text);
            end;
        ECode[3]:= CUp;
        ECode[4]:= CDown;
        ECode[5]:= CCtrl_Enter;
        ECode[6]:= CF6;
        ECode[7]:= CF1;
        ECode[8]:= CCtrl_Home;
        ECode[9]:= CCtrl_End;
        ViewLN(6,4,First_Str,70);
        ECode[3]:= 0;
        ECode[4]:= 0;
        ECode[5]:= 0;
        ECode[6]:= 0;
        ECode[7]:= 0;
        ECode[8]:= 0;
        ECode[9]:= 0;
        if ReturnCode= 0 then
            begin
            {$IFDEF SV_MOUSE}
            if LButton then
                begin
                Fix:= Timer;
                repeat
                    mousepositionstatus(@MouseButton,@MCoordX,@MCoordY);
                until (Timer-Fix> 3) or (MouseButton> 0);
                if LButton then
                    begin
                    for C:= Point to Buf_Rnc.ELine do
                        begin
                        seek(HelpFile,C);
                        read(HelpFile,Buf_Str);
                        if not Empty(Buf_Str) then
                            Say(Trim(Buf_Str))
                        else
                            Pause(50);
                        if keypressed then
                            begin
                            DefineKey;
                            Signal(S_Break);
                            break;
                            end;
                        end;
                    Point:= C;
                    end
                else
                    begin
                    seek(HelpFile,Point);
                    read(HelpFile,Buf_Str);
                    Say(Trim(Buf_Str));
                    end;
                end;
            if RButton then ReturnCode:= 27;
            {$ENDIF}
            end;
        case ReturnCode of
        CEsc:
                begin
                BufScreen:= OldScreen;
                ShowScr;
                Say('Вы+ход.');
                exit;
                end;
       CDown:  if Point< Buf_Rnc.ELine then
                inc(Point)
            else
                Signal(S_Edge);
         CUp:  if Point> Buf_Rnc.FLine+1 then
                inc(Point,-1)
            else
                Signal(S_Edge);
 CCtrl_Enter:  if OnlyCtrl then
                begin
                for C:= Point to Buf_Rnc.ELine do
                    begin
                    seek(HelpFile,C);
                    read(HelpFile,Buf_Str);
                    if not Empty(Buf_Str) then
                        Say(Trim(Buf_Str))
                    else
                        Pause(50);
                    if keypressed then
                        begin
                        DefineKey;
                        Signal(S_Break);
                        break;
                        end;
                    end;
                Point:= C;
                end;
  CCtrl_Home:
                begin
                Point:= Buf_Rnc.FLine+1;
                Posit:= 0;
                Signal(S_Edge);
                end;
   CCtrl_End:
                begin
                Point:= Buf_Rnc.ELine;
                Posit:= 0;
                Signal(S_Edge);
                end;
         CF6:
                begin
                for C:= Point to Buf_Rnc.ELine do
                    begin
                    seek(HelpFile,C);
                    read(HelpFile,Buf_Str);
                    if not Empty(Buf_Str) then
                        Say(Trim(Buf_Str))
                    else
                        Pause(50);
                    if keypressed then
                        begin
                        DefineKey;
                        Signal(S_Break);
                        break;
                        end;
                    end;
                Point:= C;
                end;
        CF1:
               begin
               Say('f6 и ко+нтрл-э+нтер - чте+ние по+мощи, f5 и а+льт-пробе+л - чте+ние строки+.');
               say('эске+йп - выход.');
               end;
           end;
        end;
    end;

destructor  toHelp.Release;
    begin
    if not Loaded then exit;
    References.Undefine;
    IOR:= ioresult;
    close(HelpFile);
    Loaded:= false;
    end;

begin
end.