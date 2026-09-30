unit E_U;
{$B-,I-,V-}
interface

var
    UnArc:          boolean;

procedure ReadLNum;
procedure ReadOfS;
procedure ReadPerCent;
procedure ReadFMem;
procedure ReadCode;
procedure ReadTxt;
procedure SaveAs;
procedure Get_XLT;
procedure Get_ChFrag;
function  Local_Eng_Word(S:  string;Cursor_Pos:  byte;var  L,R:  byte):  boolean;
procedure Translate(EngWord:  string);
function  ReadData(var Buffer;var Buf_Size:  Word): Word; far;
function  WriteData(var Buffer;var B_Read:  Word): Word; far;
procedure Print_Part(FLine,NLine:  longint);
procedure Print;
procedure Print_Block;
procedure Interval_Loc(S:  string;C:  byte;var LE,RE:  byte;Direct:  char);
function  Detect_Code(S:  string):  byte;
procedure Time_Control;
procedure V_Err(Variant:  byte);
procedure VerifyAlarms;
procedure Set_SpSpeed_Slower;
procedure Set_SpSpeed_Faster;
procedure Block_B;
procedure Block_E;
procedure Block_Read;
procedure Block_Hide;
procedure Block_Write;

implementation
uses SayForm,s_u,p_u,speech,mymath,mem,dialog,line,keyb,keyboard,help,harddisk,
     hronos,dinamic,transfrm,tables,ff,dos,printer;

var
    IOR:            word;
    Sorce:          file;
    Result:         file;

procedure ReadLNum;

    begin
    SayOrdNum(Viewer[CWin]^.FirstLine,'\ая\ строка+.  ');
    end;

procedure ReadOfS;

    begin
    SayOrdNum(Viewer[CWin]^.OffSet,'\ая\ Пози+ция.  ');
    end;

procedure ReadPerCent;

    begin
    SayRight(percent(Viewer[CWin]^.FirstLine,Viewer[CWin]^.Real_L),'м \проце+нт\\а\ов\.');
    end;

procedure ReadFMem;

    begin
    Say('свабо+дно ');
    SayRightByteSize(HeapSize(V_Param^.Memory));
    case V_Param^.Memory of
    High:  Say('ве+рхней');
     Low:  say('ни+жней');
    Disk:  Say('ди+сковой');
        end;
    Say('па+мяти.');
    end;

procedure ReadCode;
    begin
    case V_Param^.Mode of
       1:  Say('ви+ндовс.');
       2:  Say('ко+и8 э+р.');
       3:  Say('ютэ эф 8.');
       4:  Say('по+льзовательская.');
    else
        Say('обы+чная.');
        end;
    end;

procedure ReadTxt;
    var
        C:              byte;

    begin
    for C:= CWin to 9 do
      if Viewer[C]<>nil then {//ss/31.03.2003 17:20:04//}
        with Viewer[C]^ do
            begin
            if Real_L> 0 then
                ReadText;
            if (FirstLine< Real_L) or (not V_Param^.ReadWinByWin) then
                break;
            if Viewer[C+1]^.Real_L> 0 then
                if C< 9 then
                    CWin:= C+1;
            end;
    end;

procedure SaveAs;
    const
        Mask:           string = '';

    var
        Input_File:     string;
        InF:            text;
        Choice:         toChoice;
        Button:         array[1..3] of tChElem;
        Buf:            string;
        FD:             dirstr;
        FN:             namestr;
        FE:             extstr;
        C:              longint;
        Old_Str:        ^tOld_Str;
        OSF:            tOSF;
        Exist_File:     boolean;
        Point:          byte;
        Save_Str:       boolean;
        HMS:            byte;
        Nul:            ^tOld_Str;

    begin
    Exist_File:= false;
    Save_Str:= true;
    HMS:= 0;
    new(Old_Str);
    for Point:= 1 to 10 do
        Old_Str^[Point]:= '';
    assign(OSF,MyDirc+FLoaded);
    IOR:= ioresult;
    reset(OSF);
    if ioresult= 0 then
        begin
        seek(OSF,Sve_Old_Str);
        read(OSF,Old_Str^);
        if ioresult= 0 then
            Exist_File:= true;
        end;
    Point:= 1;
    if Exist_File then
        for HMS:= 10 downto 1 do
            if not Empty(Old_Str^[HMS]) then break;
    Say('и+мя фа+йла.');
    frame(21,11,60,13);
    putline(31,11,' Введите имя файла ',Color.Title);
    ECode[3]:= -59;
    ECode[4]:= -80;
    ECode[5]:= -72;
    repeat
        if Exist_File then
            begin
            Mask:= Old_Str^[Point];
            Say(Mask);
            end;
        editln(22,12,Mask,80,38);
        if ReturnCode= CDown then
            if (Exist_File) and (Point< HMS) then
                inc(Point)
            else
                Signal(S_Edge);
        if ReturnCode= CUp then
            if (Exist_File) and (Point> 1) then
                inc(Point,-1)
            else
                Signal(S_Edge);
        if ReturnCode= CF1 then
            begin
            Hlp_Viewer^.CallPart(Context);
            continue;
            end;
        if ReturnCode= CEnter then
            begin
            if Upper(Trim(Mask))= Upper(Trim(Old_Str^[Point])) then
                Save_Str:= false;
            if (pos('*',Mask)> 0) or (pos('?',Mask)>0) then
                begin
                Context:= 14;
                if pos('\',Mask)> 0 then
                    begin
                    CF_Path:= Left(Mask,length(Mask)-(RPos('\',Mask)));
                    CF_Mask:= Right(Mask,RPos('\',Mask)-1);
                    end
                else
                    CF_Mask:= Mask;
                CF_Help.Load(MyDirc+HFile,V_Param^.Memory);
                Input_File:= ChFile;
                if ReturnCode= CEnter then
                    begin
                    if length(CF_Path)> 3 then
                        CF_Path:= CF_Path +'\';
                    Input_File:= CF_Path+Input_File;
                    end;
                CF_Help.Release;
                end
            else
                Input_File:= Mask;
            end;
    until (ReturnCode= CEnter) or (ReturnCode= CEsc);
    ECode[3]:= 0;
    ECode[4]:= 0;
    ECode[5]:= 0;
    if ReturnCode= CEsc then
        begin
        close(OSF);
        Say(Cancel);
        if Exist_File then
            dispose(Old_Str);
        exit;
        end;
    if (not Exist_File) and (Save_Str) then
        begin
        IOR:= ioresult;
        rewrite(OSF);
        new(Nul);
        for C:= 1 to 10 do
            Nul^[C]:= '';
        for C:= 0 to Sve_Old_Str do
            begin
            seek(OSF,C);
            write(OSF,Nul^);
            end;
        dispose(Nul);
        if ioresult= 0 then
            Exist_File:= true;
        end;
    if (Exist_File) and (Save_Str) then
        begin
        Old_Str^[1]:= Mask;
        for Point:= 10 downto 2 do
            Old_Str^[Point]:= Old_Str^[Point-1];
        Old_Str^[1]:= '';
        seek(OSF,Sve_Old_Str);
        IOR:= ioresult;
        write(OSF,Old_Str^);
        end;
    dispose(Old_Str);
    IOR:= ioresult;
    close(OSF);
    fsplit(Input_File,FD,FN,FE);
    assign(InF,Input_File);
    append(InF);
    if ioresult= 0 then
        with Choice do
            begin
            Sorce:= '';
            Install(V_Param^.Memory);
            if not Installed then exit;
            Button[1]:= ' Перезаписать ';
            Button[2]:= ' Добавить ';
            Button[3]:= ' Отмена ';
            for C:= 1 to sizeof(Button) div sizeof(Button[1]) do
                if not Add(Button[C]) then break;
            AllElem:= HowManyElem;
            Buf:= Space((33-length(FN+FE)) div 2);
            Buf:= Buf+'Файл  '+FN+FE+'  уже существует';
            Mess:= Buf+Space(54-length(Buf));
            Cursor:= V_Param^.Cursor;
            LMargin:= 4;
            TMargin:= 1;
            SetPosition(13,9,68,16);
            Call;
            Uninstall;
            if (CurElem= 3) or (ReturnCode= CEsc) then
                begin
                Say(Cancel);
                exit;
                end;
            if CurElem= 1 then
                rewrite(InF);
            end
    else
        begin
        rewrite(InF);
        if ioresult<> 0 then
            begin
            V_Err(7);
            exit;
            end;
        Say('Со+здан фа+йл '+FN+FE);
        end;
    for C:= 1 to Viewer[CWin]^.Real_L do
        begin
        Buf:= Viewer[CWin]^.LOF(C);
        writeln(InF,Buf);
        end;
    close(InF);
    SeparateClass:= #0;
    Say('Запи+сано: '+LToS(Viewer[CWin]^.Real_L)+' стро+к.');
    SeparateClass:= Sep_C;
    end;

procedure Get_XLT;
    const
        Mask:           string = '';

    var
        Input_File:     string;
        Buf:            string;
        Old_Str:        ^tOld_Str;
        OSF:            tOSF;
        Exist_File:     boolean;
        Point:          byte;
        Save_Str:       boolean;
        HMS:            byte;
        Nul:            ^tOld_Str;

    begin
    Exist_File:= false;
    Save_Str:= true;
    HMS:= 0;
    new(Old_Str);
    for Point:= 1 to 10 do
        Old_Str^[Point]:= '';
    assign(OSF,MyDirc+FLoaded);
    IOR:= ioresult;
    reset(OSF);
    if ioresult= 0 then
        begin
        seek(OSF,Xlt_Old_Str);
        read(OSF,Old_Str^);
        if ioresult= 0 then
            Exist_File:= true;
        end;
    Point:= 1;
    if Exist_File then
        for HMS:= 10 downto 1 do
            if not Empty(Old_Str^[HMS]) then break;
    Old_Str^[1]:= V_Param^.User_Decode;
    Say('и+мя фа+йла.');
    Clear(21,11,60,13);
    frame(21,11,60,13);
    putline(31,11,' Введите имя файла ',Color.Title);
    ECode[3]:= CF1;
    ECode[4]:= CDown;
    ECode[5]:= CUp;
    repeat
        if Exist_File then
            begin
            Mask:= Old_Str^[Point];
            Say(Mask);
            end;
        editln(22,12,Mask,80,37);
        if ReturnCode= CDown then
            if (Exist_File) and (Point< HMS) then
                inc(Point)
            else
                Signal(S_Edge);
        if ReturnCode= CUp then
            if (Exist_File) and (Point> 1) then
                inc(Point,-1)
            else
                Signal(S_Edge);
        if ReturnCode= CF1 then
            begin
            Hlp_Viewer^.CallPart(Context);
            continue;
            end;
        if ReturnCode= CEnter then
            begin
            if Upper(Trim(Mask))= Upper(Trim(Old_Str^[Point])) then
                Save_Str:= false;
            if (pos('*',Mask)> 0) or (pos('?',Mask)>0) then
                begin
                Context:= 14;
                if pos('\',Mask)> 0 then
                    begin
                    CF_Path:= Left(Mask,length(Mask)-(RPos('\',Mask)));
                    CF_Mask:= Right(Mask,RPos('\',Mask)-1);
                    end
                else
                    CF_Mask:= Mask;
                CF_Help.Load(MyDirc+HFile,V_Param^.Memory);
                Input_File:= ChFile;
                if ReturnCode= CEnter then
                    begin
                    if length(CF_Path)> 3 then
                        CF_Path:= CF_Path +'\';
                    Input_File:= CF_Path+Input_File;
                    end;
                CF_Help.Release;
                end
            else
                Input_File:= Mask;
            if (Empty(Input_File)) or (ReturnCode= CEsc) then
                break;
            if not File_Exists(Input_File) then
                begin
                Signal(S_Err);
                Say('Фа+йл не+ на+йден.');
                ReturnCode:= 0;
                end;
            end;
    until (ReturnCode= CEnter) or (ReturnCode= CEsc);
    ECode[3]:= 0;
    ECode[4]:= 0;
    ECode[5]:= 0;
    if ReturnCode= CEsc then
        begin
        close(OSF);
        Say(Cancel);
        if Exist_File then
            dispose(Old_Str);
        Signal(S_StartP);
        exit;
        end;
    if (not Exist_File) and (Save_Str) then
        begin
        IOR:= ioresult;
        rewrite(OSF);
        new(Nul);
        for C:= 1 to 10 do
            Nul^[C]:= '';
        for C:= 0 to Xlt_Old_Str do
            begin
            seek(OSF,C);
            write(OSF,Nul^);
            end;
        dispose(Nul);
        if ioresult= 0 then
            Exist_File:= true;
        end;
    if (Exist_File) and (Save_Str) then
        begin
        Old_Str^[1]:= Mask;
        for Point:= 10 downto 2 do
            Old_Str^[Point]:= Old_Str^[Point-1];
        Old_Str^[1]:= '';
        seek(OSF,Xlt_Old_Str);
        IOR:= ioresult;
        write(OSF,Old_Str^);
        end;
    dispose(Old_Str);
    IOR:= ioresult;
    close(OSF);
    V_Param^.User_Decode:= Input_File;
    Say(OK);
    if (Empty(V_Param^.User_Decode)) and (V_Param^.Mode= 4) then
        begin
        V_Param^.Mode:= 0;
        Say('Сме+на кодиро+вки.');
        ReadCode;
        end;
    Signal(S_StartP);
    end;

procedure Get_ChFrag;
    const
        Mask:           string = '';

    var
        Input_File:     string;
        Buf:            string;
        Old_Str:        ^tOld_Str;
        OSF:            tOSF;
        Exist_File:     boolean;
        Point:          byte;
        Save_Str:       boolean;
        HMS:            byte;
        Nul:            ^tOld_Str;

    begin
    Exist_File:= false;
    Save_Str:= true;
    HMS:= 0;
    new(Old_Str);
    for Point:= 1 to 10 do
        Old_Str^[Point]:= '';
    assign(OSF,MyDirc+FLoaded);
    IOR:= ioresult;
    reset(OSF);
    if ioresult= 0 then
        begin
        seek(OSF,ChF_Old_Str);
        read(OSF,Old_Str^);
        if ioresult= 0 then
            Exist_File:= true;
        end;
    Point:= 1;
    if Exist_File then
        for HMS:= 10 downto 1 do
            if not Empty(Old_Str^[HMS]) then break;
    Old_Str^[1]:= V_Param^.ChFrag_F;
    Say('и+мя фа+йла.');
    Clear(21,11,60,13);
    frame(21,11,60,13);
    putline(31,11,' Введите имя файла ',Color.Title);
    ECode[3]:= CF1;
    ECode[4]:= CDown;
    ECode[5]:= CUp;
    repeat
        if Exist_File then
            begin
            Mask:= Old_Str^[Point];
            Say(Mask);
            end;
        editln(22,12,Mask,80,37);
        if ReturnCode= CDown then
            if (Exist_File) and (Point< HMS) then
                inc(Point)
            else
                Signal(S_Edge);
        if ReturnCode= CUp then
            if (Exist_File) and (Point> 1) then
                inc(Point,-1)
            else
                Signal(S_Edge);
        if ReturnCode= CF1 then
            begin
            Hlp_Viewer^.CallPart(Context);
            continue;
            end;
        if ReturnCode= CEnter then
            begin
            if Upper(Trim(Mask))= Upper(Trim(Old_Str^[Point])) then
                Save_Str:= false;
            if (pos('*',Mask)> 0) or (pos('?',Mask)>0) then
                begin
                Context:= 14;
                if pos('\',Mask)> 0 then
                    begin
                    CF_Path:= Left(Mask,length(Mask)-(RPos('\',Mask)));
                    CF_Mask:= Right(Mask,RPos('\',Mask)-1);
                    end
                else
                    CF_Mask:= Mask;
                CF_Help.Load(MyDirc+HFile,V_Param^.Memory);
                Input_File:= ChFile;
                if ReturnCode= CEnter then
                    begin
                    if length(CF_Path)> 3 then
                        CF_Path:= CF_Path +'\';
                    Input_File:= CF_Path+Input_File;
                    end;
                CF_Help.Release;
                end
            else
                Input_File:= Mask;
            if (Empty(Input_File)) or (ReturnCode= CEsc) then
                break;
            if not File_Exists(Input_File) then
                begin
                Signal(S_Err);
                Say('Фа+йл не+ на+йден.');
                ReturnCode:= 0;
                end;
            end;
    until (ReturnCode= CEnter) or (ReturnCode= CEsc);
    ECode[3]:= 0;
    ECode[4]:= 0;
    ECode[5]:= 0;
    if ReturnCode= CEsc then
        begin
        close(OSF);
        Say(Cancel);
        if Exist_File then
            dispose(Old_Str);
        Signal(S_StartP);
        exit;
        end;
    if (not Exist_File) and (Save_Str) then
        begin
        IOR:= ioresult;
        rewrite(OSF);
        new(Nul);
        for C:= 1 to 10 do
            Nul^[C]:= '';
        for C:= 0 to ChF_Old_Str do
            begin
            seek(OSF,C);
            write(OSF,Nul^);
            end;
        dispose(Nul);
        if ioresult= 0 then
            Exist_File:= true;
        end;
    if (Exist_File) and (Save_Str) then
        begin
        Old_Str^[1]:= Mask;
        for Point:= 10 downto 2 do
            Old_Str^[Point]:= Old_Str^[Point-1];
        Old_Str^[1]:= '';
        seek(OSF,ChF_Old_Str);
        IOR:= ioresult;
        write(OSF,Old_Str^);
        end;
    dispose(Old_Str);
    IOR:= ioresult;
    close(OSF);
    V_Param^.ChFrag_F:= Input_File;
    Say(OK);
    if Empty(V_Param^.ChFrag_F) and V_Param^.ChFrag then
        begin
        V_Param^.ChFrag:= false;
        Say('бе+з заме+ны.');
        end;
    Signal(S_StartP);
    end;

function  Local_Eng_Word(S:  string;Cursor_Pos:  byte;var  L,R:  byte):  boolean;
    var
        C:              byte;

    begin
    Local_Eng_Word:= false;
    L:= 0;
    R:= 0;
    if (Cursor_Pos< 1) or (Cursor_Pos> length(S)) then
        exit;
    if not (ord(upcase(S[Cursor_Pos])) in [65..90]) then exit;
    C:= Cursor_Pos;
    if Cursor_Pos> 1 then
        while (ord(upcase(S[C-1])) in [65..90]) and (C> 1) do
            inc(C,-1);
    L:= C;
    C:= Cursor_Pos;
    if Cursor_Pos< length(S) then
        while (ord(upcase(S[C+1])) in [65..90]) and (C< length(S)) do
            inc(C);
    R:= C;
    Local_Eng_Word:= true;
    end;

procedure Translate(EngWord:  string);
    type
        tDic_Rec=       record
                            Eng_Word:       string[20];
                            Rus_Text:       string[72];
                            end;
        tIndex_Rec=     array[1..26] of longint;

    const
        Heap_Order=     32768;

    var
        Dic:            file of tDic_Rec;
        Index:          tIndex_Rec;
        Ndx_File:       file of tIndex_Rec;
        Dic_Rec:        tDic_Rec;
        Cur_Addr:       longint;
        CSym:           byte;
        LE:             byte;
        LEDG:           byte;
        RE:             byte;
        K:              tKeyCode;
        Res_Compr:      Integer;
        Buf:            pointer;
        TmpScreen:      tScreen;
        Old_Str:        ^tOld_Str;
        Null:           ^tOld_Str;
        OSF:            tOSF;
        Exist_File:     boolean;
        Save_Str:       boolean;
        HMS:            byte;
        C:              word;
        Fix:            longint;

    begin
    EngWord:= Upper(Trim(EngWord));
    CSym:= ord(EngWord[1])-64;
    if not (CSym in [1..26]) then
        begin
        V_Err(28);
        exit;
        end;
    {if maxavail< Heap_Order+1 then
        begin
        V_Err(4);
        exit;
        end;
    Assign(Sorce,MyDirc+Arc_Dictionary);
    filemode:= 0;
    Reset(Sorce,1);
    filemode:= 2;
    if ioresult<> 0 then
        begin
        V_Err(29);
        exit;
        end;
    Assign(Result,MyDirc+Dictionary);
    Rewrite(Result,1);
    if ioresult<> 0 then
        begin
        V_Err(30);
        exit;
        end;
    getmem(buf,Heap_Order);
    Res_Compr:= explode(ReadData,WriteData,Buf^);
    freemem(buf,Heap_Order);
    Close(Sorce);
    Close(Result);
    if Res_Compr<> 0 then
        begin
        V_Err(31);
        exit;
        end;}
    assign(Ndx_File,MyDirc+Dic_Index);
    filemode:= 0;
    reset(Ndx_File);
    filemode:= 2;
    if ioresult<> 0 then
        begin
        V_Err(25);
        exit;
        end;
    read(Ndx_File,Index);
    if ioresult<> 0 then
        begin
        V_Err(26);
        exit;
        end;
    close(Ndx_File);
    IOR:= ioresult;
    assign(Dic,MyDirc+Dictionary);
    filemode:= 0;
    reset(Dic);
    filemode:= 2;
    if ioresult<> 0 then
        begin
        V_Err(27);
        exit;
        end;
    Cur_Addr:= Index[CSym];
    TmpScreen:= BufScreen;
    while (not eof(Dic)) or (Empty(EngWord)) do
        begin
        seek(Dic,(Cur_Addr) div sizeof(tDic_Rec));
        read(Dic,Dic_Rec);
        if (Left(Dic_Rec.Eng_Word,length(EngWord))= EngWord) or (Empty(EngWord)) then
            begin
            if length(Dic_Rec.Rus_Text)> length(Dic_Rec.Eng_Word) then
                begin
                LE:= (80-length(Trim(Dic_Rec.Rus_Text))) div 2;
                RE:= LE+length(Trim(Dic_Rec.Rus_Text))+1;
                end
            else
                begin
                LE:= (80-length(Trim(Dic_Rec.Eng_Word))) div 2;
                RE:= LE+length(Trim(Dic_Rec.Eng_Word))+1;
                end;
            Clear(LE-3,11,RE+3,15);
            Frame(LE-3,11,RE+3,15);
            Ledg:= (80-length(Trim(Dic_Rec.Eng_Word))) div 2;
            PutLine(LEdg+1,12,Trim(Dic_Rec.Eng_Word),Color.Message);
            PutLine(LE+1,14,Trim(Dic_Rec.Rus_Text),Color.Message);
            ShowScr;
            if Empty(EngWord) then
                V_Signal(19)
            else
                V_Signal(18);
            Say(Trim(Dic_Rec.Eng_Word));
            if not Empty(EngWord) then
                begin
                Fix:= Timer;
                repeat
                until Timer-Fix> 5;
                Say(Trim(Dic_Rec.Rus_Text));
                end;
            ECode[3]:= CF1;
            ECode[4]:= CCtrl_Enter;
            ECode[5]:= CSpace;
            ECode[6]:= CUp;
            ECode[7]:= CDown;
            ECode[8]:= CCtrl_End;
            ECode[9]:= CCtrl_Home;
            repeat
                ViewLN(LE+1,14,Trim(Dic_Rec.Rus_Text),(RE-LE)-1);
                case ReturnCode of
                CEsc:
                        begin
                        close(Dic);
                        erase(Dic);
                        Signal(S_StartP);
                        BufScreen:= TmpScreen;
                        ShowScr;
                        exit;
                        end;
                 CF1:  Hlp_Viewer^.CallPart(Context);
              CEnter:
                        begin
                        Exist_File:= false;
                        Save_Str:= true;
                        HMS:= 0;
                        new(Old_Str);
                        for C:= 1 to 10 do
                            Old_Str^[C]:= '';
                        assign(OSF,MyDirc+FLoaded);
                        IOR:= ioresult;
                        reset(OSF);
                        if ioresult= 0 then
                            begin
                            seek(OSF,Dic_Old_Str);
                            read(OSF,Old_Str^);
                            if ioresult= 0 then
                                Exist_File:= true;
                            end;
                        if Exist_File then
                            for HMS:= 10 downto 1 do
                                if not Empty(Old_Str^[HMS]) then break;
                        Clear(21,8,60,10);
                        Frame(21,8,60,10);
                        Say('по+иск.');
                        C:= 1;
                        ECode[3]:= CF1;
                        repeat
                            if Exist_File then
                                EngWord:= Old_Str^[C];
                            Say(EngWord);
                            ECode[4]:= CUp;
                            ECode[5]:= CDown;
                            editln(22,9,EngWord,255,38);
                            ECode[4]:= 0;
                            ECode[5]:= 0;
                            if ReturnCode= CDown then
                                if (Exist_File) and (C< HMS) then
                                    inc(C)
                                else
                                    Signal(S_Edge);
                            if ReturnCode= CUp then
                                if (Exist_File) and (C> 1) then
                                    inc(C,-1)
                                else
                                    Signal(S_Edge);
                            if ReturnCode= CF1 then
                                Hlp_Viewer^.CallPart(Context);
                            if ReturnCode= CEnter then
                                if not (ord(Upcase(EngWord[1])) in [65..90]) then
                                    begin
                                    Signal(S_Err);
                                    Say('неве+рный пе+рвый си+мвол.');
                                    ReturnCode:= 0;
                                    end;
                        until (ReturnCode= CEsc) or (ReturnCode= CEnter);
                        ECode[3]:= 0;
                        if (Upper(Trim(EngWord))= Upper(Trim(Old_Str^[C]))) and (ReturnCode= CEnter) then
                            Save_Str:= false;
                        if ReturnCode= CEsc then
                            begin
                            close(OSF);
                            if Exist_File then
                                dispose(Old_Str);
                            EngWord:= '';
                            inc(Cur_Addr,-sizeof(tDic_Rec));
                            Say(Cancel);
                            end;
                        if (not Exist_File) and (Save_Str) then
                            begin
                            IOR:= ioresult;
                            rewrite(OSF);
                            new(Null);
                            for C:= 1 to 10 do
                                Null^[C]:= '';
                            for C:= 0 to Dic_Old_Str do
                                begin
                                seek(OSF,C);
                                write(OSF,Null^);
                                end;
                            dispose(Null);
                            if ioresult= 0 then
                                Exist_File:= true;
                            end;
                        if (Exist_File) and (Save_Str) then
                            begin
                            Old_Str^[1]:= EngWord;
                            for C:= 10 downto 2 do
                                Old_Str^[C]:= Old_Str^[C-1];
                            Old_Str^[1]:= '';
                            seek(OSF,Dic_Old_Str);
                            IOR:= ioresult;
                            write(OSF,Old_Str^);
                            end;
                        dispose(Old_Str);
                        IOR:= ioresult;
                        close(OSF);
                        EngWord:= Upper(EngWord);
                        CSym:= ord(EngWord[1])-64;
                        Cur_Addr:= Index[CSym]-sizeof(tDic_Rec);
                        Say(OK);
                        break;
                        end;
              CSpace:  if OnlyAlt then Say(Dic_Rec.Eng_Word);
         CCtrl_Enter:  if Onlyctrl then Say(Dic_Rec.Rus_Text);
               CDown:  if (Cur_Addr div sizeof(tDic_Rec))< filesize(Dic)-1 then
                        begin
                        EngWord:= '';
                        break;
                        end
                    else
                        Signal(S_Edge);
                 CUp:  if Cur_Addr> 0 then
                        begin
                        inc(Cur_Addr,-2*sizeof(tDic_Rec));
                        EngWord:= '';
                        break;
                        end
                    else
                        Signal(S_Edge);
          CCtrl_Home:
                        begin
                        EngWord:= '';
                        Cur_Addr:= -sizeof(tDic_Rec);
                        break;
                        end;
           CCtrl_End:
                        begin
                        Cur_Addr:= sizeof(tDic_Rec)*(filesize(Dic)-2);
                        EngWord:= '';
                        break;
                        end;
                    end;
            until false;
            BufScreen:= TmpScreen;
            ShowScr;
            ECode[3]:= 0;
            ECode[4]:= 0;
            ECode[5]:= 0;
            ECode[6]:= 0;
            ECode[7]:= 0;
            ECode[8]:= 0;
            ECode[9]:= 0;
            end;
        inc(Cur_Addr,sizeof(tDic_Rec));
        if (CSym< 26) and (Cur_Addr> Index[CSym+1]) and (Index[CSym+1]> 0) then
            if not Empty(EngWord) then break;
        end;
    V_Err(28);
    close(Dic);
    erase(Dic);
    end;

function  ReadData(var Buffer;var Buf_Size:  Word): Word;
    var
        RealSize:       Word;

    begin
    BlockRead(Sorce,Buffer,Buf_Size,RealSize);
    ReadData:= RealSize;
    end;

function  WriteData(var Buffer;var B_Read:  Word): Word;
    var
        RealSize:       Word;

    begin
    BlockWrite(Result,Buffer,B_Read,RealSize);
    WriteData:= RealSize;
    end;

procedure Print_Part(FLine,NLine:  longint);
    var
        C:              longint;
        Buf:            string;

    begin
    if (FLine< 1) or (FLine> Viewer[CWin]^.Real_L) then
        exit;
    if (NLine> Viewer[CWin]^.Real_L) or (NLine< 1) or (NLine< FLine) then
        exit;
    for C:= FLine to NLine do
        begin
        Buf:= Viewer[CWin]^.LOF(C);
        writeln(lst,Buf);
        end;
    end;

procedure Print;
    begin
    if Viewer[CWin]= nil then
        begin
        Signal(0);
        exit;
        end;
    if Yes('       Печатать весь текст?       ') then
        Print_Part(1,Viewer[CWin]^.Real_L);
    end;

procedure Print_Block;
    begin
    if Viewer[CWin]= nil then
        begin
        Signal(0);
        exit;
        end;
    if (Viewer[CWin]^.Block_Begin= 0) or (Viewer[CWin]^.Block_End= 0) then
        begin
        Say('оши+бка.  бло+к не+ отме+чен.');
        exit;
        end;
    if Yes('       Печатать блок?       ') then
        Print_Part(Viewer[CWin]^.Block_Begin,Viewer[CWin]^.Block_End);
    end;

procedure Interval_Loc(S:  string;C:  byte;var LE,RE:  byte;Direct:  char);
    var
        Counter:        byte;
        Sym:            char;

    begin
    LE:= 0;
    RE:= 0;
    if Empty(S) then exit;
    if (C= 0) or (C> length(S)) then C:= 1;
    if S[C]<> ' ' then
        begin
        if Direct= OfS_Right then
            begin
            for Counter:= C to length(S) do
                if S[Counter]= ' ' then break;
            if S[Counter]<> ' ' then exit;
            C:= Counter;
            end
        else
            begin
            for Counter:= C downto 1 do
                if S[Counter]= ' ' then break;
            if S[Counter]<> ' ' then exit;
            C:= Counter;
            end;
        end;
    if S[C]= ' ' then
        begin
        if Direct= OfS_Right then
            begin
            for Counter:= C to length(S) do
                if S[Counter]<> ' ' then break;
            if S[Counter]= ' ' then exit;
            C:= Counter;
            end
        else
            begin
            for Counter:= C to 1 do
                if S[Counter]<> ' ' then break;
            if S[Counter]= ' ' then exit;
            C:= Counter;
            end;
        end;
    for Counter:= C downto 1 do
        if S[Counter]= ' ' then break;
    if S[Counter]= ' ' then
        inc(Counter);
    LE:= Counter;
    for Counter:= C to length(S) do
        if S[Counter]= ' ' then break;
    if S[Counter]= ' ' then
        inc(Counter,-1);
    RE:= Counter;
    end;

function Detect_Code(S:  string):  byte;
    var
        C:              byte;
        Dos866:         byte;
        Win866:         byte;
        Koi8_r:         byte;
        Sym_Cod:        byte;
        No_Dos:         byte;
        Latin:          byte;
        Utf8:           byte;
        Win_String:     string[32];
        Koi_String:     string[32];
        Tab_1:          toDos2Win;
        Tab_2:          toDos2Koi;
        utf8str:        string;
    begin
    Detect_Code:= 0;
    if Empty(S) then exit;
    S:= LTrim(RTrim(S));
    Sym_Cod:= 0;
    Dos866:= 0;
    Win866:= 0;
    Koi8_r:= 0;
    Utf8:=0;
    Latin:= 0;
    No_Dos:= 0;
    Win_String:= 'аеёиоуыэюяАЕЁИОУЫЭЮЯ';
    Koi_String:= 'аеёиоуыэюяАЕЁИОУЫЭЮЯ';
    for C:= 1 to length(S) do
        begin
        if ord(S[C]) in [192..255] then
            inc(No_Dos);
        if (ord(S[C]) in [128..175]) or (ord(S[C]) in [224..241]) then
            inc(Dos866);
        if (Ord(S[C]) in [65..90]) or (ord(S[C]) in [97..122]) then
            inc(Latin);
        end;
    if (Latin> Dos866) and (Latin> No_Dos) then
        begin
        Dos866:= 0;
        No_Dos:= 0;
        Sym_Cod:= $FF;
        end;
    if Dos866> No_Dos then
        Sym_Cod:= 1;
    if No_Dos> Dos866 then
        begin
        Tab_1.Install;
        Tab_2.Install;
        ReputStrng(Win_String,Tab_1.Dos2Win);
        ReputStrng(Koi_String,Tab_2.Dos2Koi);
        utf8str:=s;
        winStringFromUtf8(utf8str);
        for C:= 1 to length(S) do
            begin
            if pos(S[C],Win_String)> 0 then
                inc(Win866);
            if pos(S[C],Koi_String)> 0 then
                inc(Koi8_R);
            if pos(utf8str[C],Win_String)> 0 then
                inc(Utf8);
            end;
        if Win866> Koi8_R then
            Sym_Cod:= 2;
        if Koi8_R> Win866 then
            Sym_Cod:= 3;
        if Utf8 > Koi8_R then
            Sym_Cod:= 4;
        end;
    Detect_Code:= Sym_Cod;
    end;

procedure Time_Control;
    var
        Hour:           word;
        Min:            word;
        Sec:            word;
        PSec:           word;
        Time_Signal:    boolean;
        OldTime:        word;

    begin
    if not V_Param^.Exact_Time then exit;
    if not V_Param^.Sound then exit;
    gettime(Hour,Min,Sec,PSec);
    if (Min in [1..58]) or (Sec in [1..50]) then exit;
    if (Min= 59) and (Sec= 0) then exit;
    OldTime:= 0;
    if Min= 59 then
        repeat
            ShowCurTime;
            gettime(Hour,Min,Sec,PSec);
            if OldTime<> Sec then
                begin
                Time_Signal:= true;
                OldTime:= Sec;
                end;
            if (Sec in [55..59]) and (Time_Signal) then
                begin
                V_Signal(14);
                Time_Signal:= false;
                end;
        until Sec= 0;
    gettime(Hour,Min,Sec,PSec);
    if (Min= 0) and (Sec= 0) then V_Signal(15);
    repeat
        gettime(Hour,Min,Sec,PSec);
        VerifyAlarms;
        ShowCurTime;
    until Sec<> 0;
    ClearBuffer;
    end;

procedure V_Err(Variant:  byte);
    begin
    case Variant of
       1:  ShowMessage('   Не удается перейти к закладке   ',
               'строки+ ука+заной в закла+дке не+существу+ет');
       2:  ShowMessage('   Не удается добавить закладку   ',
               'оши+бка при+ попы+тки дописа+ть да+нные в фа+йл закла+док');
       3:  ShowMessage('   Ошибка при открытии файла закладок   ',
               'возни+кла оши+бка при+ откры+тии фа+йла '+FBookMark);
       4:  ShowMessage('         Не достаточно памяти         ','');
       5:  ShowMessage('    Не удается использовать память    ','');
       6:  ShowMessage('     Ошибка при добавлении строки     ','');
       7:  ShowMessage('       Не удается создать файл       ','');
       8:  ShowMessage('            Файл не найден            ','');
       9:  ShowMessage('   Не могу создать файл конфигурации',
               'Оши+бка при+ созда+нии фа+йла конфигура+ции');
      10:  ShowMessage('   Не могу записать в файл конфигурации   ',
            'оши+бка при+ за+писи в фа+йл конфигура+ции');
      11:  ShowMessage('   Не могу создать файл инициализации   ',
               'оши+бка при+ созда+нии фа+йла инициализа+ции');
      12:  ShowMessage('   Не могу открыть файл конфигурации   ',
               'нена+йден файл конфигурации '+CfgFile);
      13:  ShowMessage('   Не могу прочитать файл конфигурации   ',
               'оши+бка при+ чте+нии фа+йла конфигура+ции');
      14:  ShowMessage('   Не могу открыть файл инициализации   ',
               'нена+йден фа+йл инициализа+ции '+IniFile);
      15:  ShowMessage('   Ошибка в файле инициализации: общие   ',
               'неве+рно ука+зано значе+ние для+ строки+ в разде+ле general, и+ли неве+рно ука+зан са+м пара+метр');
      16:  ShowMessage('   Ошибка в файле инициализации: интерфейс   ',
               'неве+рно ука+зано значе+ние для+ строки+ в разде+ле interface, и+ли неве+рно ука+зан са+м пара+метр');
      17:  ShowMessage('   Ошибка в файле инициализации: закладки   ',
               'неве+рно ука+зано значе+ние для+ строки+ в разде+ле book-mark, и+ли неве+рно ука+зан са+м пара+метр');
      18:  ShowMessage('   Ошибка в файле инициализации: речь   ',
               'неве+рно ука+зано значе+ние для+ строки+ в разде+ле sintezator, и+ли неве+рно ука+зан са+м пара+метр');
      19:  ShowMessage('   Ошибка в файле инициализации: чтение   ',
               'неве+рно ука+зано значе+ние для+ строки+ в разде+ле reading, и+ли неве+рно ука+зан са+м пара+метр');
      20:  ShowMessage('   Ошибка в файле инициализации: звук   ',
               'неве+рно ука+зано значе+ние для+ строки+ в разде+ле sound, и+ли неве+рно ука+зан са+м пара+метр');
      21:  ShowMessage('   Ошибка в файле инициализации: цвет   ',
               'неве+рно ука+зано значе+ние для+ строки+ в разде+ле color, и+ли неве+рно ука+зан са+м пара+метр');
      22:  ShowMessage('     Ошибка в файле инициализации     ','');
      23:  ShowMessage('   Ошибка в файле инициализации: загрузка   ',
               'неве+рно ука+зано значе+ние для+ строки+ в разде+ле startup, и+ли неве+рно ука+зан са+м пара+метр');
      24:  ShowMessage('   Ошибка в файле инициализации: вид   ',
               'неве+рно ука+зано значе+ние для+ строки+ в разде+ле outlook, и+ли неве+рно ука+зан са+м пара+метр');
      25:  ShowMessage('     Не удается открыть индексный файл для словоря     ',
               'неудае+тся откры+ть и+ндексный фа+йл '+Dic_Index);
      26:  ShowMessage('     Не удается считать индексный файл для словоря     ',
               'неудае+тся счита+ть информа+цию из и+ндексного фа+йл '+Dic_Index);
      27:  ShowMessage('     Не удается открыть словорь     ',
               'неудае+тся откры+ть фа+йл словаря+ '+Dictionary);
      28:  ShowMessage('       Слово не найдено       ',
               'тако+го сло+ва в словаре+ не+т.');
      29:  ShowMessage('       Не удается открыть архив словаря       ',
               'неудае+тся откры+ть архи+вный фа+йл словаря+ - '+Arc_Dictionary);
      30:  ShowMessage('       Не удается создать файл       ',
               'неудае+тся созда+ть фа+йл словаря+ - '+Dictionary);
      31:  ShowMessage('       Не удается разархивировать словарь       ',
               'оши+бка при+ распако+вки словаря+.');
      32:  ShowMessage('   Ошибка в файле инициализации: язык   ',
               'неве+рно ука+зано значе+ние для+ строки+ в разде+ле language, и+ли неве+рно ука+зан са+м пара+метр');
        end;
    end;

procedure VerifyAlarms;
    var
        C:              byte;

    begin
    for C:= 1 to 10 do
        with V_Param^.Config.Alarm[C] do
            if Status then
                begin
                if Tme= Left(CurrentTime,5) then
                    begin
                    if Alarm_Off then exit;
                    V_Signal(16);
                    Say(Message);
                    while true do
                        begin
                        Pause(800);
                        if keypressed then break;
                        V_Signal(16);
                        if keypressed then break;
                        end;
                    ClearBuffer;
                    Alarm_Off:= true;
                    if not EveryOnce then
                        Status:= false;
                    end
                else
                    Alarm_Off:= false;
            end;
    end;

procedure Set_SpSpeed_Slower;
    begin
    repeat
        if (V_Param^.Temp in [1..50]) or ((V_Param^.Temp mod 2)<> 0) then
            begin
            if V_Param^.Temp= 0 then
                begin
                Signal(S_Edge);
                break;
                end;
            inc(V_Param^.Temp,-1);
            end
        else
            begin
            if V_Param^.Temp< 2 then
                begin
                Signal(S_Edge);
                break;
                end;
            inc(V_Param^.Temp,-2);
            end;
    until not keypressed;
    Set_Temp(V_Param^.Temp);
    Say(LToS(V_Param^.Temp));
    end;

procedure Set_SpSpeed_Faster;
    begin
    repeat
        if (V_Param^.Temp in [0..49]) or ((V_Param^.Temp mod 2)<> 0) then
            begin
            if V_Param^.Temp= 150 then
                begin
                Signal(S_Edge);
                break;
                end;
            inc(V_Param^.Temp);
            end
        else
            begin
            if V_Param^.Temp> 148 then
                begin
                Signal(S_Edge);
                break;
                end;
            inc(V_Param^.Temp,2);
            end;
    until not keypressed;
    Set_Temp(V_Param^.Temp);
    Say(LToS(V_Param^.Temp));
    end;

procedure Block_B;
    begin
    Viewer[CWin]^.Block_Begin:= Viewer[CWin]^.FirstLine;
    Viewer[CWin]^.Block_End:= 0;
    end;

procedure   Block_E;
    begin
    if Viewer[CWin]^.Block_Begin= 0 then
        begin
        Viewer[CWin]^.Block_Begin:= 1;
        Viewer[CWin]^.Block_End:= Viewer[CWin]^.FirstLine;
        Say('бло+к отме+чен с пе+рвой строки+.');
        exit;
        end;
    if Viewer[CWin]^.Block_Begin> Viewer[CWin]^.FirstLine then
        begin
        Say('оши+бка.  коне+ц вы+ше нача+ла.');
        exit;
        end;
    Viewer[CWin]^.Block_End:= Viewer[CWin]^.FirstLine;
    end;

procedure Block_Read;
    var
        Old_FirstLine:  longint;

    begin
    if (Viewer[CWin]^.Block_Begin= 0) or (Viewer[CWin]^.Block_End= 0) then
        begin
        Say('оши+бка.  бло+к не+ отме+чен.');
        exit;
        end;
    Old_FirstLine:= Viewer[CWin]^.FirstLine;
    Viewer[CWin]^.FirstLine:= Viewer[CWin]^.Block_Begin;
    Viewer[CWin]^.Break_Read_Line:= Viewer[CWin]^.Block_End;
    Viewer[CWin]^.ReadText;
    Viewer[CWin]^.FirstLine:= Old_FirstLine;
    end;

procedure Block_Hide;
    begin
    Viewer[CWin]^.Block_Begin:= 0;
    Viewer[CWin]^.Block_End:= 0;
    end;

procedure Block_Write;
    const
        Mask:           string = '';

    var
        Input_File:     string;
        InF:            text;
        Choice:         toChoice;
        Button:         array[1..3] of tChElem;
        Buf:            string;
        FD:             dirstr;
        FN:             namestr;
        FE:             extstr;
        C:              longint;
        Old_Str:        ^tOld_Str;
        OSF:            tOSF;
        Exist_File:     boolean;
        Point:          byte;
        Save_Str:       boolean;
        HMS:            byte;
        Nul:            ^tOld_Str;

    begin
    if (Viewer[CWin]^.Block_Begin= 0) or (Viewer[CWin]^.Block_End= 0) then
        begin
        Say('оши+бка.  бло+к не+ отме+чен.');
        exit;
        end;
    Context:= 32;
    Exist_File:= false;
    Save_Str:= true;
    HMS:= 0;
    new(Old_Str);
    for Point:= 1 to 10 do
        Old_Str^[Point]:= '';
    assign(OSF,MyDirc+FLoaded);
    IOR:= ioresult;
    reset(OSF);
    if ioresult= 0 then
        begin
        seek(OSF,WrBlock_Old_Str);
        read(OSF,Old_Str^);
        if ioresult= 0 then
            Exist_File:= true;
        end;
    Point:= 1;
    if Exist_File then
        for HMS:= 10 downto 1 do
            if not Empty(Old_Str^[HMS]) then break;
    Say('и+мя фа+йла.');
    frame(21,11,60,13);
    putline(31,11,' Введите имя файла ',Color.Title);
    ECode[3]:= -59;
    ECode[4]:= -80;
    ECode[5]:= -72;
    repeat
        Context:= 32;
        if Exist_File then
            begin
            Mask:= Old_Str^[Point];
            Say(Mask);
            end;
        editln(22,12,Mask,80,37);
        if ReturnCode= CDown then
            if (Exist_File) and (Point< HMS) then
                inc(Point)
            else
                Signal(S_Edge);
        if ReturnCode= CUp then
            if (Exist_File) and (Point> 1) then
                inc(Point,-1)
            else
                Signal(S_Edge);
        if ReturnCode= CF1 then
            begin
            Hlp_Viewer^.CallPart(Context);
            continue;
            end;
        if ReturnCode= CEnter then
            begin
            if Upper(Trim(Mask))= Upper(Trim(Old_Str^[Point])) then
                Save_Str:= false;
            if (pos('*',Mask)> 0) or (pos('?',Mask)> 0) then
                begin
                Context:= 14;
                if pos('\',Mask)> 0 then
                    begin
                    CF_Path:= Left(Mask,length(Mask)-(RPos('\',Mask)));
                    CF_Mask:= Right(Mask,RPos('\',Mask)-1);
                    end
                else
                    CF_Mask:= Mask;
                CF_Help.Load(MyDirc+HFile,V_Param^.Memory);
                Input_File:= ChFile;
                if ReturnCode= CEsc then
                    ReturnCode:= CEsc
                else
                    begin
                    if length(CF_Path)> 3 then
                        CF_Path:= CF_Path +'\';
                    Input_File:= CF_Path+Input_File;
                    end;
                CF_Help.Release;
                end
            else
                Input_File:= Mask;
            end;
    until (ReturnCode= CEnter) or (ReturnCode= CEsc);
    ECode[3]:= 0;
    ECode[4]:= 0;
    ECode[5]:= 0;
    if ReturnCode= CEsc then
        begin
        close(OSF);
        Say(Cancel);
        if Exist_File then
            dispose(Old_Str);
        exit;
        end;
    if (not Exist_File) and (Save_Str) then
        begin
        IOR:= ioresult;
        rewrite(OSF);
        new(Nul);
        for C:= 1 to 10 do
            Nul^[C]:= '';
        for C:= 0 to WrBlock_Old_Str do
            begin
            seek(OSF,C);
            write(OSF,Nul^);
            end;
        dispose(Nul);
        if ioresult= 0 then
            Exist_File:= true;
        end;
    if (Exist_File) and (Save_Str) then
        begin
        Old_Str^[1]:= Mask;
        for Point:= 10 downto 2 do
            Old_Str^[Point]:= Old_Str^[Point-1];
        Old_Str^[1]:= '';
        seek(OSF,WrBlock_Old_Str);
        IOR:= ioresult;
        write(OSF,Old_Str^);
        end;
    dispose(Old_Str);
    IOR:= ioresult;
    close(OSF);
    fsplit(Input_File,FD,FN,FE);
    assign(InF,Input_File);
    append(InF);
    if ioresult= 0 then
        with Choice do
            begin
            Sorce:= '';
            Install(V_Param^.Memory);
            if not Installed then exit;
            Button[1]:= ' Перезаписать ';
            Button[2]:= ' Добавить ';
            Button[3]:= ' Отмена ';
            for C:= 1 to sizeof(Button) div sizeof(Button[1]) do
                if not Add(Button[C]) then break;
            AllElem:= HowManyElem;
            Buf:= Space((33-length(FN+FE)) div 2);
            Buf:= Buf+'Файл  '+FN+FE+'  уже существует';
            Mess:= Buf+Space(54-length(Buf));
            Cursor:= V_Param^.Cursor;
            LMargin:= 4;
            TMargin:= 1;
            Clear(13,9,68,16);
            SetPosition(13,9,68,16);
            Call;
            Uninstall;
            if (CurElem= 3) or (ReturnCode= CEsc) then
                begin
                Say(Cancel);
                exit;
                end;
            if CurElem= 1 then
                rewrite(InF);
            end
    else
        begin
        rewrite(InF);
        if ioresult<> 0 then
            begin
            V_Err(7);
            exit;
            end;
        Say('Со+здан фа+йл '+FN+FE);
        end;
    for C:= Viewer[CWin]^.Block_Begin to Viewer[CWin]^.Block_End do
        begin
        Buf:= Viewer[CWin]^.LOF(C);
        writeln(InF,Buf);
        {//ss/25.09.2003//}
        {BeepOn(random(10000));
        BeepOff;}
        Signal(S_Tick);
        end;
    close(InF);
    SeparateClass:= #0;
    SayRight((Viewer[CWin]^.Block_End-Viewer[CWin]^.Block_Begin)+1,'ж слово \запи+сан\а\о\о');
    SayRight((Viewer[CWin]^.Block_End-Viewer[CWin]^.Block_Begin)+1,'ж \строк\а+\и+\\.');
    SeparateClass:= Sep_C;
    end;

begin
end.
{


Сергей Картавцев:
1. 08.02.2000 Подключил модуль SayForm и применил процедуры произнесения
   числительных SayOrdNum и SayRight;

Довыденков Владимир
10/02/2000
  введен пункт  32  в процедуру  V_Err
}