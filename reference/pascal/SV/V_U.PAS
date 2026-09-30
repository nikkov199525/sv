
unit V_U;
{$B-,I-,V-}
{$define external}
{.$define release}
interface
uses mem,dialog,harddisk,tables,  dos;

type
    tRecord=        record
                        Adr:            longint;
                        Len:            byte;
                        end;
    tBookMark=      record
                        FileName:       string[255];
                        BMName:         string[23];
                        Line:           longint;
                        nUM:            LONGINT;
                        end;
    tFOBM=          file of tBookMark;
    tField=         record
                        Name:           string[11];
                        Typ:            char;
                        OfS:            longint;
                        Len:            byte;
                        Len_:           byte;
                        end;
    tpField=        ^tField;
    tDBF=           record
                        Field:          array[1..255] of tpField;
                        HMRecords:      longint;
                        HMFields:       byte;
                        F_Rec_Addr:     word;
                        Record_Len:     word;
                        Last_Date:      string[8];
                        Record_Size:    word;
                        end;
    tpDBF=          ^tDBF;
    tpoViewer=      ^toViewer;
    toViewer=       object(toMemory)
                        public
                            Installed:      boolean;
                            FPath:          pathstr;
                            FName:          namestr;
                            FExtn:          extstr;
                            Title:          boolean;
                            PText:          tTextInfo;
                            ViewFile:       file;
                            FirstLine:      longint;
                            OffSet:         byte;
                            FLine:          string;
                            TrimSpace:      boolean;
                            Block_Begin:    longint;
                            Block_End:      longint;
                            Break_Read_Line:longint;
                            DBF_File:       boolean;
                            DBF:            tpDBF;
                            Doc_File:       boolean;
                            Doc2txt_F:      pathstr;
                            Htm_File:       boolean;
                            CurField:       byte;
                            Real_L:         longint;
                            L:              byte;
                            T:              byte;
                            R:              byte;
                            B:              byte;
                            Tab_1:          toWin2Dos;
                            Tab_2:          toKoi2Dos;
                            Tab_3:          tReput;
                            Tab_3_Loaded:   boolean;
                            Tab_3_Filename: string;

                        constructor Install(FN:  string);
                        procedure   SetPosition(LE,TE,RE,BE:  byte);
                        procedure   BookMark;
                        procedure   ReadLine;
                        procedure   ReadText;
                        procedure   Show;
                        function    AddBookMark:  boolean;
                        procedure   ChBookMark(NOR:  longint);
                        function    DelBookMark(NOR:  longint):  boolean;
                        procedure   Load(FN:  string);
                        procedure   GotoL;
                        procedure   Find(FindContinue:  boolean);
                        procedure   SetWin;
                        procedure   Next(Step:  longint);
                        procedure   Last(Step:  longint);
                        function    LOF(Num:  longint):  string;
                        procedure   Load_Tab_3;
                        destructor  Uninstall;
                        end;

implementation
uses s_u,p_u,e_u,line,keyboard,keyb,mymath,transfrm,dinamic,speech,various,hronos,help,ff,htmtrans,
    sayform,  cursor, {$IFDEF SV_MOUSE}mouse,{$ENDIF}wordconv,video;

var
    IORes:          word;

constructor toViewer.Install(FN:  string);
    begin
    Installed:= false;
    randomize;
    CurField:= 1;
    FPath:= '';
    FName:= '';
    FExtn:= '';
    Sorce:= '';
    {Обработка позиции курсора перенесена в Load //ss/27.03.2003/15:31:59/}
    Load(FN);
    L:= 1;
    T:= 2;
    R:= 80;
    B:= 25;
    FLine:= '';
    Block_Begin:= 0;
    Block_End:= 0;
    Break_Read_Line:= 0;
    Tab_1.Install;
    Tab_2.Install;
    Tab_3_Filename:='';
    Load_Tab_3;
    Installed:= true;
    end;

procedure toViewer.Load_Tab_3;
begin
    if (Tab_3_Filename = '') or (Tab_3_Filename <> V_Param^.User_Decode) then begin
      if not File_Exists(V_Param^.User_Decode) then begin
        Tab_3_Loaded:=False;
        Tab_3_Filename:='';
        Exit;
      end;
      Tab_3_Loaded:=Load_Xlt(V_Param^.User_Decode,Tab_3);
      if Tab_3_Loaded then
        Tab_3_Filename:=V_Param^.User_Decode
      else
        Tab_3_Filename:='';
    end;
end;

procedure   toViewer.SetPosition(LE,TE,RE,BE:  byte);
    begin
    L:= 1;
    T:= 2;
    R:= 80;
    B:= 25;
    if (BE-TE< 3) or (RE-LE< 21) or (LE= 0) or (TE= 1) or (RE> 80) or (BE> 25) then
        exit;
    L:= LE;
    T:= TE;
    R:= RE;
    B:= BE;
    end {proc. Set Position};

procedure   toViewer.Show;
    label
        Show_Inform;

    var
        Buf1:           string;
        Buf2:           string;
        D:              dirstr;
        N:              namestr;
        E:              extstr;
        C:              byte;
        ShowLine:       longint;
    begin
    putline(1,1,Space(80),Color.Menu.DeactItem);
    putline(2,1,MenuString,Color.Menu.DeactItem);
    Clear(L,T,R,B);
    Frame(L,T,R,B);
    if not Installed then
        begin
        Clear(1,1,80,25);
        Frame(1,1,80,25);
        exit;
        end;
    if DBF_File then
        begin
        PutLine(L+5,T+1,'Имя: '+DBF^.Field[CurField]^.Name,Color.Title);
        PutLine(L+22,T+1,'Тип: '+RType[DBF^.Field[CurField]^.Typ],Color.Title);
        PutLine(L+42,T+1,'Длина: '+LToS(DBF^.Field[CurField]^.Len),Color.Title);
        for C:= T+2 to B-1 do
            begin
            putline(L+1,C,Space(R-L-1),Color.Text);
            putline(L+1,C,copy(LOF(FirstLine+(C-T)-2),OffSet,R-L-1),Color.Text);
            end;
        if CurField< DBF^.HMFields then
            PutLine(R,T+1,chr(30),Color.Frame);
        if CurField> 1 then
            PutLine(L,T+1,chr(31),Color.Frame);
        with DBF^.Field[CurField]^ do
            if (Len> R-L-1) and ((R-L-1)< Len-OffSet+1) then
                PutLine(R,T+2,chr(24),Color.Frame);
        goto Show_Inform;
        end;
    IORes:= ioresult;
    for C:= T+1 to B-1 do
        begin
        putline(L+1,C,Space(R-L-1),Color.Text);
        ShowLine:=FirstLine+(C-T)-1;
        if (ShowLine >= Block_Begin) and (ShowLine <= Block_End) then
            putline(L+1,C,copy(LOF(ShowLine),OffSet,R-L-1),Color.Marked)
        else
            putline(L+1,C,copy(LOF(ShowLine),OffSet,R-L-1),Color.Text);
        end;
    Show_Inform:
    if V_Param^.Coord then
        begin
        str(FirstLine,Buf1);
        str(OffSet,Buf2);
        putline(L+4,B,' '+Buf1+':'+Buf2+' ',Color.Message);
        end;
    if (V_Param^.PerCent) and (R-L> 23) then
        begin
        str(percent(FirstLine,Real_L),Buf1);
        Buf2:= space(4-length(Buf1))+Buf1+'%';
        putline(L+17,B,Buf2,Color.Message);
        end;
    if (V_Param^.MemSize) and (R-L> 47) then
        putline(L+25,B,' '+LToS(HeapSize(V_Param^.Memory))+' свободно ',Color.Message);
    if (V_Param^.ShCode) and (R-L> 59) then
        case V_Param^.Mode of
           0:  putline(L+50,B,' Обычная ',Color.Message);
           1:  putline(L+50,B,' WINDOWS ',Color.Message);
           2:  putline(L+50,B,' KOI 8-R ',Color.Message);
           3:  putline(L+50,B,' UTF-8   ',Color.Message);
           4:
                begin
                fsplit(V_Param^.User_Decode,D,N,E);
                putline(L+50,B,' Польз. '+N+IIF(E= '.','',E)+' ',Color.Message);
                end;
            end;
    end;

procedure   toViewer.BookMark;
    label
        StartMenu,endproc;

    const
        Mask:           string = '';

    var
        BMark:          toPopupMenu;
        BookMarks:      tFOBM;
        LBookMarks:     tFOBM;
        Buf:            tBookMark;
        Point:          longint;
        TPath:          dirstr;
        TName:          namestr;
        TExtn:          extstr;
        BufElem:        tPopupElem;
        NLine:          longint;
        Code:           integer;
        SubMenu:        toPopupMenu;
        Item:           array[1..4] of tPopupElem;
        TempScr:        tScreen;
        LON:            toMemory;
        BufNum:         longint;
        CBMark:         byte;
        CanSay:         boolean;
        Input_File:     string;
        Choice:         toChoice;
        Button:         array[1..3] of tChElem;
        FD:             dirstr;
        FN:             namestr;
        FE:             extstr;
        C:              longint;
        Old_Str:        ^tOld_Str;
        OSF:            tOSF;
        Exist_File:     boolean;
        Save_Str:       boolean;
        HMS:            byte;
        Nul:            ^tOld_Str;
        BM_Sve:         tFOBM;
        F_Buf:          string;
        Load_Ext_BM:    boolean;

    begin
    if (Viewer[CWin]= nil) or (not Installed) then exit;
    if not File_Exists(FPath+FName+FExtn) then 
        exit;
    TempScr:= BufScreen;
    CanSay:= true;
    IORes:= ioresult;
    assign(BookMarks,MyDirc+FBookMark);
    BMark.Installed:= false;
    LON.InitMemory:= false;
    CBMark:= 1;
    Load_Ext_BM:= false;
    if V_Param^.Auto_Ext_BMark then
        begin
        IORes:= ioresult;
        if File_Exists(FName+Right(FBookMark,4)) and (File_Size(FName+Right(FBookMark,4)) > 0) then
            begin
            IORes:= ioresult;
            assign(LBookMarks,FName+Right(FBookMark,4));
            Load_Ext_BM:= true;
            end;
        end;
    StartMenu:
    if not File_Exists(MyDirc+FBookMark) or (File_Size(MyDirc+FBookMark) = 0)
       and (not Load_Ext_BM) then
        begin
        if Yes('   Закладок нет.  Вложить закладку?   ') then
            begin
            if not AddBookMark then goto endproc;
            end
        else
            goto endproc;
        end;
    BMark.Uninstall;
    LON.Undefine;
    BMark.Sorce:= '';
    LON.Sorce:= '';
    BMark.Install(V_Param^.Memory);
    LON.Define(V_Param^.Memory,sizeof(longint));
    if (not BMark.Installed) or (not LON.InitMemory) then
        goto endproc;
    BMark.MY:= 0;
    IORes:= ioresult;
    reset(BookMarks);
    Point:= 0;
    while (not eof(BookMarks)) and (ioresult= 0) do
        begin
        seek(BookMarks,Point);
        read(BookMarks,Buf);
        if not V_Param^.SPBM then
            begin
            BufElem.Elem:= Buf.BMName+space(sizeof(Buf.BMName)-length(Buf.BMName))
                +iif(V_Param^.ShowLine,': '+space(12-length(ltos(Buf.Line))) +ltos(Buf.Line),'');
            str(Buf.Line,BufElem.Mess);
            if Buf.FileName= FPath+FName+FExtn then
                begin
                BMark.add(BufElem);
                LON.Add(Buf.Num);
                end;
            end
        else
            begin
            fsplit(Buf.FileName,TPath,TName,TExtn);
            BufElem.Elem:= Buf.BMName+space(sizeof(Buf.BMName)-length(Buf.BMName))+': '+
                iif(V_Param^.ShowLine,': '+space(12-length(ltos(Buf.Line))) +ltos(Buf.Line),'');
            str(Buf.Line,BufElem.Mess);
            if SameFileName(TName+TExtn, FName+FExtn) then
                begin
                BMark.add(BufElem);
                LON.Add(Buf.Num);
                end;
            end;
        inc(Point);
        end;
    close(BookMarks);
    if Load_Ext_BM then
        begin
        IORes:= ioresult;
        reset(LBookMarks);
        Point:= 0;
        while not eof(LBookMarks) do
            begin
            seek(LBookMarks,Point);
            read(LBookMarks,Buf);
            if not V_Param^.SPBM then
                begin
                BufElem.Elem:= Buf.BMName+space(sizeof(Buf.BMName)-length(Buf.BMName))
                    +iif(V_Param^.ShowLine,': '+space(12-length(ltos(Buf.Line))) +ltos(Buf.Line),'');
                str(Buf.Line,BufElem.Mess);
                if Buf.FileName= FPath+FName+FExtn then
                    begin
                    BMark.add(BufElem);
                    LON.Add(Buf.Num);
                    end;
                end
            else
                begin
                fsplit(Buf.FileName,TPath,TName,TExtn);
                BufElem.Elem:= Buf.BMName+space(sizeof(Buf.BMName)-length(Buf.BMName))+': '+
                    iif(V_Param^.ShowLine,': '+space(12-length(ltos(Buf.Line))) +ltos(Buf.Line),'');
                str(Buf.Line,BufElem.Mess);
                if SameFileName(TName+TExtn, FName+FExtn) then
                    begin
                    BMark.add(BufElem);
                    LON.Add(Buf.Num);
                    end;
                end;
            inc(Point);
            end;
        close(lBookMarks);
        end;
    if BMark.HowManyElem< 1 then
        if Yes('   Закладок нет.  Вложить закладку?   ') then
            if not AddBookMark then
                goto endproc
            else
                goto StartMenu
        else
            goto EndProc;
    if CanSay then
        begin
        CanSay:= false;
        Say('Спи+сак закла+дак.');
        end;
    BufScreen:= TempScr;
    ShowScr;
    BMark.AllElem:= BMark.HowManyElem;
    if BMark.AllElem< 6 then
        BMark.IN_Centr
    else
        BMark.SetPosition(21,10,60,16);
    Clear(BMark.L,BMark.T,BMark.R,BMark.b);
    BMark.Cycle:= V_Param^.CycleMenu;
    BMark.Cursor:= V_Param^.Cursor;
    BMark.Title:= ' Список закладок ';
    ECode[3]:= CIns;
    ECode[4]:= CSpace;
    ECode[5]:= CDel;
    ECode[6]:= CF10;
    ECode[7]:= CF1;
    ECode[8]:= CF2;
    ECode[9]:= CF3;
    if CBMark= 0 then
        CBMark:= BMark.AllElem;
    BMark.CurElem:= CBMark;
    Context:= 16;
    if not keypressed then
        BMark.Call
    else
        ReturnCode:= DefineKey;
    CBMark:= BMark.CurElem;
    ECode[3]:= 0;
    ECode[4]:= 0;
    ECode[5]:= 0;
    ECode[6]:= 0;
    ECode[7]:= 0;
    ECode[8]:= 0;
    ECode[9]:= 0;
    LON.Pick(BMark.CurElem,BufNum);
    case ReturnCode of
  CEnter:  if not OnlyCtrl then
            begin
            if BMark.pick(BMark.CurElem,BufElem) then
                begin
                val(BufElem.Mess,NLine,Code);
                if (Code= 0) and (NLine< Viewer[CWin]^.Real_L) then
                    begin
                    FirstLine:= NLine;
                    ReadLNum;
                    end
                else
                    V_Err(1);
                end
            else
                V_Err(1);
            end
          else goto StartMenu;
    CIns:
            begin
            if (not AddBookMark) and (ReturnCode<> CEsc) then
                V_Err(2)
            else
                CBMark:= BMark.AllElem+1;
            goto StartMenu;
            end;
  CSpace:
            begin
            ChBookMark(BufNum);
            goto StartMenu;
            end;
    CDel:
            begin
            if DelBookMark(BufNum) then
                if BMark.CurElem= BMark.AllElem then
                    CBMark:= BMark.CurElem-1;
            goto StartMenu;
            end;
    CF10:
            begin
            TempScr:= BufScreen;
            with SubMenu do
                begin
                Sorce:= '';
                Install(V_Param^.Memory);
                if Installed then
                    begin
                    Item[1].Elem:= '  Добавить закладку      ';
                    Item[2].Elem:= '  Перезаложить закладку  ';
                    Item[3].Elem:= '  Удалить закладку       ';
                    Item[4].Elem:= '  Выход                   ';
                    for Point:= 1 to sizeof(Item) div sizeof(Item[1]) do
                        if not Add(Item[Point]) then break;
                    AllElem:= HowManyElem;
                    Cycle:= V_Param^.CycleMenu;
                    Cursor:= V_Param^.Cursor;
                    In_Centr;
                    MY:= 0;
                    ECode[3]:= CF1;
                    Context:= 17;
                    Say('меню+.');
                    repeat
                        Call;
                        if ReturnCode= CF1 then
                            Hlp_Viewer^.CallPart(Context)
                        else
                            break;
                    until false;
                    ECode[3]:= 0;
                    if ReturnCode= CEnter then
                        case CurElem of
                           1:  if not AddBookMark then
                                V_Err(2);
                           2:  ChBookMark(BufNum);
                           3:  DelBookMark(BufNum);
                           4:  goto EndProc;
                            end;
                    Uninstall;
                    end;
                BufScreen:= TempScr;
                goto StartMenu;
                end;
            end;
     CF1:
            begin
            Hlp_Viewer^.CallPart(Context);
            goto StartMenu;
            end;
     CF2:
            begin
            if not File_Exists(MyDirc+FBookMark) or (File_Size(MyDirc+FBookMark) = 0) then
                begin
                ShowMessage('     Не найден файл закладок     ','');
                goto startmenu;
                end;
            Exist_File:= false;
            Save_Str:= true;
            HMS:= 0;
            new(Old_Str);
            for Point:= 1 to 10 do
                Old_Str^[Point]:= '';
            assign(OSF,MyDirc+FLoaded);
            IORes:= ioresult;
            reset(OSF);
            if ioresult= 0 then
                begin
                seek(OSF,BMSve_Old_Str);
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
            Old_Str^[1]:= FName+Right(FBookMark,4);
            if not Exist_file then
                begin
                Mask:= FName+Right(FBookMark,4);
                Say(Mask);
                end;
            Posit:= 0;
            ECode[3]:= -59;
            ECode[4]:= -80;
            ECode[5]:= -72;
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
                goto StartMenu;
                end;
            if (not Exist_File) and (Save_Str) then
                begin
                IORes:= ioresult;
                rewrite(OSF);
                new(Nul);
                for C:= 1 to 10 do
                    Nul^[C]:= '';
                for C:= 0 to BMSve_Old_Str do
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
                seek(OSF,BMSve_Old_Str);
                IORes:= ioresult;
                write(OSF,Old_Str^);
                end;
            dispose(Old_Str);
            IORes:= ioresult;
            close(OSF);
            fsplit(Input_File,FD,FN,FE);
            assign(BM_Sve,Input_File);
            reset(BM_Sve);
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
                    F_Buf:= Space((33-length(FN+FE)) div 2);
                    F_Buf:= F_Buf+'Файл  '+FN+FE+'  уже существует';
                    Mess:= F_Buf+Space(54-length(F_Buf));
                    Cursor:= V_Param^.Cursor;
                    LMargin:= 4;
                    TMargin:= 1;
                    SetPosition(13,9,68,16);
                    Call;
                    Uninstall;
                    if (CurElem= 3) or (ReturnCode= CEsc) then
                        begin
                        Say(Cancel);
                        goto startmenu;
                        end;
                    if CurElem= 1 then
                        rewrite(BM_Sve);
                    end
            else
                begin
                rewrite(BM_Sve);
                if ioresult<> 0 then
                    begin
                    V_Err(7);
                    goto startmenu;
                    end;
                end;
            IORes:= ioresult;
            reset(BookMarks);
            Point:= 0;
            while not eof(BookMarks) do
                begin
                seek(BookMarks,Point);
                read(BookMarks,Buf);
                if not V_Param^.SPBM then
                    begin
                    if Buf.FileName= FPath+FName+FExtn then
                        begin
                        seek(BM_Sve,filesize(BM_Sve));
                        write(BM_Sve,Buf);
                        end;
                    end
                else
                    begin
                    fsplit(Buf.FileName,TPath,TName,TExtn);
                    if SameFileName(TName+TExtn, FName+FExtn) then
                        begin
                        seek(BM_Sve,filesize(BM_Sve));
                        write(BM_Sve,Buf);
                        end;
                    end;
                inc(Point);
                end;
            close(BookMarks);
            Say('сохранено+ в фа+йл '+FN+FE);
            end;
     CF3:
            begin
            Exist_File:= false;
            Save_Str:= true;
            HMS:= 0;
            new(Old_Str);
            for Point:= 1 to 10 do
                Old_Str^[Point]:= '';
            assign(OSF,MyDirc+FLoaded);
            IORes:= ioresult;
            reset(OSF);
            if ioresult= 0 then
                begin
                seek(OSF,BMload_Old_Str);
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
            Old_Str^[1]:= FName+Right(FBookMark,4);
            if not Exist_File then
                begin
                Mask:= FName+Right(FBookMark,4);
                Say(Mask);
                end;
            ECode[3]:= -59;
            ECode[4]:= -80;
            ECode[5]:= -72;
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
                goto StartMenu;
                end;
            if (not Exist_File) and (Save_Str) then
                begin
                IORes:= ioresult;
                rewrite(OSF);
                new(Nul);
                for C:= 1 to 10 do
                    Nul^[C]:= '';
                for C:= 0 to BMSve_Old_Str do
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
                seek(OSF,BMLoad_Old_Str);
                IORes:= ioresult;
                write(OSF,Old_Str^);
                end;
            dispose(Old_Str);
            IORes:= ioresult;
            close(OSF);
            IORes:= ioresult;
            if not File_Exists(Input_File) or (File_Size(Input_File) = 0) then
                begin
                V_Err(32);
                goto startmenu;;
                end;
            assign(LBookMarks,Input_File);
            Load_Ext_BM:= true;
            goto StartMenu;
            end;
        end;
    endproc:
    BMark.Uninstall;
    LON.Undefine;
    Say('текст.');
    end;

function    toViewer.AddBookMark:  boolean;
    label
        EndProc;

    var
        FBM:            tFOBM;
        BMName:         string[23];
        Rec:            tBookMark;
        Old_Str:        ^tOld_Str;
        Nul:            ^tOld_Str;
        OSF:            tOSF;
        Exist_File:     boolean;
        Save_Str:       boolean;
        HMS:            byte;
        C:              byte;

    begin
    Context:= 18;
    Exist_File:= false;
    Save_Str:= true;
    HMS:= 0;
    new(Old_Str);
    for C:= 1 to 10 do
        Old_Str^[C]:= '';
    assign(OSF,MyDirc+FLoaded);
    IORes:= ioresult;
    reset(OSF);
    if ioresult= 0 then
        begin
        seek(OSF,BM_Old_Str);
        read(OSF,Old_Str^);
        if ioresult= 0 then
            Exist_File:= true;
        end;
    if Exist_File then
        for HMS:= 10 downto 1 do
            if not Empty(Old_Str^[HMS]) then break;
    C:= 1;
    AddBookMark:= false;
    IORes:= ioresult;
    assign(FBM,MyDirc+FBookMark);
    reset(FBM);
    if ioresult<> 0 then
        rewrite(FBM);
    if ioresult<> 0 then
        begin
        V_Err(3);
        goto EndProc;
        end;
    BMName:= '';
    Show;
    frame(28,12,53,14);
    putline(34,12,' Имя закладки ',Color.Title);
    PutLine(29,13,Space(24),Color.Text);
    Say('И+мя закла+дки.');
    setcursor(7,8);
    ECode[3]:= CF1;
    ECode[4]:= CUp;
    ECode[5]:= CDown;
    repeat
        if Exist_File then
            BMName:= Old_Str^[C];
        Say(BMName);
        EditLn(29,13,BMName,23,23);
        if ReturnCode= CF1 then
            Hlp_Viewer^.CallPart(Context);
        if (ReturnCode= CEnter) and Empty(BMName) then
            continue;
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
    until (ReturnCode= CEsc) or (ReturnCode= CEnter);
    ECode[3]:= 0;
    ECode[4]:= 0;
    ECode[5]:= 0;
    if (Upper(Trim(BMName))= Upper(Trim(Old_Str^[C]))) and (ReturnCode= CEnter) then
        Save_Str:= false;
    if ReturnCode= CEsc then
        begin
        close(OSF);
        if Exist_File then
            dispose(Old_Str);
        Say(Cancel);
        goto EndProc;
        end;
    if (not Exist_File) and (Save_Str) then
        begin
        IORes:= ioresult;
        rewrite(OSF);
        new(Nul);
        for C:= 1 to 10 do
            Nul^[C]:= '';
        for C:= 0 to BM_Old_Str do
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
        Old_Str^[1]:= BMName;
        for C:= 10 downto 2 do
            Old_Str^[C]:= Old_Str^[C-1];
        Old_Str^[1]:= '';
        seek(OSF,BM_Old_Str);
        IORes:= ioresult;
        write(OSF,Old_Str^);
        end;
    dispose(Old_Str);
    IORes:= ioresult;
    close(OSF);
    if not V_Param^.Cursor then
        hidecursor;
    Rec.FileName:= FPath+FName+FExtn;
    Rec.BMName:= BMName;
    Rec.Line:= FirstLine;
    Rec.Num:= filesize(FBM)+1;
    seek(FBM,filesize(FBM));
    write(FBM,Rec);
    AddBookMark:= true;
    Say(OK);
    goto EndProc;
    EndProc:
    close(FBM);
    end;

procedure   toViewer.ChBookMark(NOR:  longint);
    var
        FBM:            tFOBM;
        Rec:            tBookMark;

    begin
    if not Yes('        Перезаложить закладку?        ') then exit;
    IORes:= ioresult;
    assign(FBM,MyDirc+FBookMark);
    reset(FBM);
    if ioresult<> 0 then
        begin
        V_Err(3);
        close(FBM);
        end;
    seek(FBM,NOR-1);
    read(FBM,Rec);
    Rec.Line:= FirstLine;
    seek(FBM,NOR-1);
    write(FBM,Rec);
    close(FBM);
    end;

function    toViewer.DelBookMark(NOR:  longint):  boolean;
    label
        EndProc;

    var
        FBM:            tFOBM;
        Rec:            tBookMark;
        C:              longint;

    begin
    DelBookMark:= false;
    if NOR< 1 then exit;
    if not Yes('          Удалить закладку ?          ') then exit;
    IORes:= ioresult;
    assign(FBM,MyDirc+FBookMark);
    IORes:= ioresult;
    reset(FBM);
    if ioresult<> 0 then
        begin
        V_Err(3);
        goto EndProc;
        end;
    if filesize(FBM)= 1 then
        begin
        close(FBM);
        erase(FBM);
        DelBookMark:= true;
        exit;
        end;
    IORes:= ioresult;
    C:= NOR;
    while not eof(FBM) do
        begin
        seek(FBM,C);
        read(FBM,Rec);
        inc(Rec.Num,-1);
        seek(FBM,C-1);
        write(FBM,Rec);
        inc(C);
        end;
    seek(FBM,filesize(FBM)-1);
    truncate(FBM);
    close(FBM);
    DelBookMark:= true;
    EndProc:
    close(FBM);
    end;

procedure   toViewer.Load(FN:  string);
    const
        Buf_Size=       $2000;

    var
        Starting:       file;
        Address:        longint;
        Buf:            string;
        Len:            byte;
        Rec:            tRecord;
        Choice:         toChoice;
        Button:         array[1..3] of tChElem;
        Buf_Arr:        array[1..11] of char;
        RS:             integer;
        C:              longint;
        C2:             byte;
        C3:             byte;
        Cod:            array[0..250] of byte;
        TC:             array[0..4] of byte;
        Transp:         byte;
        S_Buf:          array[0..Buf_Size] of byte;
        Emp_String:     boolean;
        Lng_String:     boolean;
        Spc_String:     boolean;
        Bug_Posit:      integer;
        Sym_Enter:      byte;
        {//ss}
        lp_Buf:            string[5];
        FLP:            tFLP;
        LP:             tLast_Posit;
        Cnt:            longint;
        cur_percent:    integer;
        last_percent:   integer;
        {ss//}
    begin
    if FN= '' then exit;
    if not File_Exists(FN) then
        Stop(5);
    fsplit(FN,FPath,FName,FExtn);
    if FPath= '' then
        fsplit(fexpand(FN),FPath,FName,FExtn);
    last_percent:=-1;
    DBF_File:= false;
    Doc_File:= false;
    Htm_File:= false;
    if Upper(FExtn)= '.DBF' then
        begin
        if V_Param^.DBF_Control then
            begin
            if Yes('     Файл имеет расширение базы данных.  Загружать как Базу Данных?     ') then
                DBF_File:= true;
            end
        else
            DBF_File:= true;
        if DBF_File then
            begin
            if maxavail< sizeof(tDBF) then
                begin
                Transport:= sizeof(tDBF);
                Stop(1);
                end;
            new(DBF);
            IORes:= ioresult;
            assign(ViewFile,FN);
            filemode:= 0;
            reset(ViewFile,1);
            filemode:= 2;
            seek(ViewFile,$01);
            with DBF^ do
                begin
                blockread(ViewFile,C2,sizeof(byte),RS);
                Last_Date:= LToS(C2);
                blockread(ViewFile,C2,sizeof(byte),RS);
                Last_Date:= IIF(C2< 10,'0','')+LToS(C2) +'/' +Last_Date;
                blockread(ViewFile,C2,sizeof(byte),RS);
                Last_Date:= IIF(C2< 10,'0','')+LToS(C2) +'/' +Last_Date;
                blockread(ViewFile,HMRecords,sizeof(longint),RS);
                blockread(ViewFile,F_Rec_Addr,sizeof(word),RS);
                blockread(ViewFile,Record_Len,sizeof(word),RS);
                HMFields:= (F_Rec_Addr-33) div 32;
                for C:= 1 to HMFields do
                    begin
                    seek(ViewFile,32*C);
                    blockread(ViewFile,Buf_Arr,11,RS);
                    new(Field[C]);
                    with Field[C]^ do
                        begin
                        blockread(ViewFile,Typ,sizeof(byte),RS);
                        Name:= '';
                        for C2:= 1 to 11 do
                            begin
                            if Buf_Arr[C2]= #0 then break;
                            Name:= Name +Buf_Arr[C2];
                            end;
                        blockread(ViewFile,OfS,sizeof(longint),RS);
                        blockread(ViewFile,Len,sizeof(byte),RS);
                        blockread(ViewFile,Len_,sizeof(byte),RS);
                        end;
                    end;
                end;
            Real_L:= DBF^.HMRecords;
            exit;
            end;
        end;
    if (Upper(FExtn)= '.DOC') and ((not V_Param^.Doc_Control) or
           (Yes('     Загружать файл как текст  MS WORD 97?     '))) then
            begin
            Doc_File:= true;
            Doc2txt_F:= V_Param^.Temp_Dir+FName+'.TXT';
            Trans_w97_txt(FN,Doc2txt_F);
            FN:= Doc2txt_F;
            fsplit(FN,FPath,FName,FExtn);
            if FPath= '' then
                fsplit(fexpand(FN),FPath,FName,FExtn);
            end;
    if (Upper(FExtn)= '.HTM') and ((not V_Param^.htm_Control) or
           (Yes('     Загружать файл как html?     '))) then
            begin
            Htm_File:= true;
            Doc2txt_F:= V_Param^.Temp_Dir+FName+'.TXT';
            htm2txt(FN,Doc2txt_F);
            FN:= Doc2txt_F;
            fsplit(FN,FPath,FName,FExtn);
            if FPath= '' then
                fsplit(fexpand(FN),FPath,FName,FExtn);
            end;
    if Viewer[CWin]<> nil then
        CleanMemory;
    Define(V_Param^.Memory,sizeof(tRecord));
    if not InitMemory then
        Stop(2);
    with PText do
        begin
        MaxWidth:= 0;
        MaxWNL:= 0;
        MinWidth:= 0;
        MinWNL:= 0;
        Lines:= 0;
        LMargin:= 0;
        end;
    with Choice do
        begin
        Sorce:= '';
        Install(V_Param^.Memory);
        if not Installed then exit;
        Button[1]:= ' Продолжить ';
        Button[2]:= ' Прервать ';
        Button[3]:= ' Выход ';
        for C:= 1 to sizeof(Button) div sizeof(Button[1]) do
            if not Add(Button[C]) then break;
        AllElem:= HowManyElem;
        Cursor:= V_Param^.Cursor;
        Mess:= '                  Прервано...';
        TMargin:= 1;
        LMargin:= 2;
        SetPosition(16,9,65,16);
        end;
    Address:= 0;
    //OScreen:= Current;
    SetCursorXY(21,13);
    hidecursor;
    clear(1,1,80,25);
    frame(21,11,60,14);
    putline(36,12,'АНАЛИЗ...',$14);
    ShowScr;
    if File_Size(FN) > 5000000 then 
      Say('ана+лиз...');
    getNtextinfo(FN,PText);
    IORes:= ioresult;
    assign(Starting,FPath+FName+FExtn);
    filemode:= 0;
    reset(Starting,1);
    filemode:= 2;
    if IOResult<> 0 then
        exit;
    TrimSpace:= false;
    if (PText.LMargin> 0) and (V_Param^.Indent_Control) then
        if Yes('   Левый отступ '+LToS(PText.LMargin)+' символов.  Удалять?   ') then
            TrimSpace:= true;
    if V_Param^.ShowProcess then
        putline(34,12,'Загружено ',Color.Message)
    else
        putline(34,12,' Загрузка... ',Color.Message);
    ShowScr;
    if MaxElem< PText.Lines then
        begin
        Buf:= 'Можно загрузить только '+LToS(Percent(MaxElem,PText.Lines))+'% текста.  Продолжать?';
        if not Yes('     '+Buf+'     ') then Stop(4);
        PText.Lines:= MaxElem;
        if V_Param^.ShowProcess then
            begin
            SetCursorXY(21,13);
            clear(1,1,80,25);
            frame(21,11,60,14);
            putline(34,12,'Загружено ',Color.Message);
            ShowScr;
            end;
        end;
    for C:= 0 to 250 do Cod[C]:= $FF;
    C:= 0;
    C3:= 0;
    Lng_String:= false;
    while (not eof(Starting)) and ((C< PText.Lines) or (Lng_String)) do
        begin
        if filepos(Starting)> 0 then
            seek(Starting,filepos(Starting)-(RS-Bug_Posit));
        blockread(Starting,S_Buf,Buf_Size,RS);
        Bug_Posit:= 0;
        while (Bug_Posit< RS-$FF) or ((eof(Starting)) and (Bug_Posit< RS)) do
            begin
            if C>= PText.Lines then
                break;
            if V_Param^.LoadSound then
                begin
                (*BeepOn(random(1000)); {//ss/25.09.2003//}
                BeepOff;*)
                Signal(S_Tick);
                end;
            Emp_String:= false;
            Lng_String:= false;
            Spc_String:= false;
            for Len:= 0 to $FF do
                begin
                if Len= $FF then
                    begin
                    Lng_String:= true;
                    break;
                    end;
                if Spc_String then begin
                  C2:=S_Buf[Bug_Posit+Len];
                  if (C2 <> 32) and (C2 <> 9) and (C2 <> $D) and (C2 <> $A) then
                      begin
                        Lng_String:= true;
                        break;
                      end;
                end;
                if Len > 80 then begin
                    C2:=S_Buf[Bug_Posit+Len];
                    if (C2 = 32) or (C2 = 9) then
                        Spc_String:= true;
                end;
                if ((S_Buf[Bug_Posit+Len]= $D) and (S_Buf[Bug_Posit+Len+1]= $A)) or
                   (S_Buf[Bug_Posit+Len]= $A) or (Bug_Posit+Len>= RS) then
                    begin
                    if (S_Buf[Bug_Posit+Len]= $A) then
                        Sym_Enter:= 1
                    else
                        Sym_Enter:= 2;
                    if Len= 0 then
                        begin
                        Emp_String:= true;
                        break;
                        end;
                    break;
                    end;
                end;
            if not Emp_String then
                inc(Bug_Posit,Len)
            else
                inc(Bug_Posit,Sym_Enter);
            if (not Lng_String) and (not Emp_String) then
                inc(Bug_Posit,Sym_Enter);
            if (V_Param^.AutoDetect_Code) and (Len> 0) and (C3< 250) then
                begin
                for C2:= 0 to Len-1 do
                    Buf[C2+1]:= chr(S_Buf[Bug_Posit+C2]);
                SetLength(Buf, Len);
                Cod[C3]:= Detect_Code(Buf);
                inc(C3);
                end;
            Rec.Adr:= Address;
            Rec.Len:= Len;
            if not add(Rec) then
                Stop(3);
            if V_Param^.ShowProcess then
                begin
                cur_percent:=PerCent(C,PText.Lines);
                if cur_percent <> last_percent then begin
                  putline(22,13,scale(C,PText.Lines,38),Color.Message);
                  putline(44,12,LToS(cur_percent)+'%',Color.Message);
                  ShowScr;
                  last_percent:=cur_percent;
                end;
                end;
            if not Emp_String then
                begin
                if not Lng_String then
                    inc(Address,Len+Sym_Enter)
                else
                    inc(Address,Len);
                end
            else
                inc(Address,Sym_enter);
            inc(C);
            end;

            if C>= PText.Lines then
                break;

        if keypressed then
            case DefineKey of
            CEsc:
                    begin
                    Choice.Call;
                    case Choice.CurElem of
                       1:
                            begin
                            clear(1,1,80,25);
                            frame(21,11,60,14);
                            putline(34,12,'Загружено ',Color.Message);
                            ShowScr;
                            SetCursorXY(21,13);
                            Say('продо+лжить.');
                            continue;
                            end;
                       2:  break;
                       3:  Stop(4);
                        end;
                    end;
          CSpace:  Say(LToS(PerCent(C,PText.Lines))+'%');
                end;
        end;
    if V_Param^.AutoDetect_Code then
        begin
        for C:= 0 to 4 do TC[C]:= 0;
        for C:= 0 to 250 do
            if Cod[C]<> $FF then
                inc(TC[Cod[C]]);
        C3:= 0;
        Transp:= TC[0];
        for C:= 1 to 4 do
            if TC[C]> Transp then
                begin
                Transp:= TC[C];
                C3:= C;
                end;
        if C3= 0 then
            Say('Кодиро+вка не+ определена+.')
        else
            if (C3-1)<> V_Param^.Mode then
                begin
                Say('Сме+на кодиро+вки.');
                V_Param^.Mode:= C3-1;
                ReadCode;
                end;
        end;
    Real_L:= HowManyElem;
    //OScreen:= Buffer;
    Choice.Uninstall;
    close(Starting);
    IORes:= ioresult;

    FirstLine:= 1; {//ss/31.03.2003 18:17:55//}
    OffSet:= 1;

    Block_Begin:= 0; {//ss/07.08.2003 18:36:39//}
    Block_End:= 0;

    assign(ViewFile,FPath+FName+FExtn);
    filemode:= 0;
    reset(ViewFile,1);
    filemode:= 2;
    if V_Param^.Last_Posit then
        begin
        assign(FLP,MyDirc+FLast_Posit);
        IORes:= ioresult;
        reset(FLP);
        if ioresult= 0 then
            begin
            for Cnt:= 0 to filesize(FLP)-1 do
                begin
                IORes:= ioresult;
                seek(FLP,Cnt);
                read(FLP,LP);
                if (ioresult= 0) and SameFileName(LP.FN, FPath+FName+FExtn) then
                    begin
                    FirstLine:= LP.L;
                    OffSet:= LP.OfS;
                    end;
                end;
            end;
        close(FLP);
        end;
    end;

procedure   toViewer.GotoL;
    var
        Num:            longint;
        Numb:           string[10];
        Code:           integer;

    begin
    Context:= 20;
    frame(27,11,54,13);
    Say('но+мер строки+.');
    putline(28,12,'Номер строки - ',Color.Message);
    Numb:= '';
    ECode[3]:= CF1;
    repeat
        editln(43,12,Numb,10,10);
        if ReturnCode= CF1 then
            Hlp_Viewer^.CallPart(Context);
        if ReturnCode= CEnter then
            begin
            val(Numb,Num,Code);
            if Code<> 0 then
                begin
                Say('оши+бка.');
                Signal(S_Err);
                ReturnCode:= 0;
                end;
            if (Num> Real_L) or (Num< 1) then
                begin
                Say('тако+й строки+ несуществу+ет.');
                Signal(S_Err);
                ReturnCode:= 0;
                end;
            end;
    until (ReturnCode= CEnter) or (ReturnCode= CEsc);
    ECode[3]:= 0;
    if ReturnCode= CEsc then
        begin
        Say(Cancel);
        exit;
        end;
    FirstLine:= Num;
    ReadLNum;
    end;

procedure   toViewer.Find(FindContinue:  boolean);
    const
        FStr:           string= '';

    var
        Buf:            string;
        C_1:            longint;
        C_2:            longint;
        FTrig:          toTrigger;
        Item:           array[1..5] of tTrigElem;
        OldCol:         byte;
        Old_Str:        ^tOld_Str;
        Null:           ^tOld_Str;
        OSF:            tOSF;
        Exist_File:     boolean;
        Save_Str:       boolean;
        HMS:            byte;

    begin
    if not Installed then exit;
    if (FindContinue) and (Empty(FStr)) then
        begin
        Say('Строка+ по+иска не+ за+дана.');
        FindContinue:= false;
        end;
    if FindContinue then
        if V_Param^.Config.Forward then
            C_1:= FirstLine +1
        else
            C_1:= FirstLine -1
    else
        begin
        Exist_File:= false;
        Save_Str:= true;
        HMS:= 0;
        new(Old_Str);
        for C_1:= 1 to 10 do
            Old_Str^[C_1]:= '';
        assign(OSF,MyDirc+FLoaded);
        IORes:= ioresult;
        reset(OSF);
        if ioresult= 0 then
            begin
            seek(OSF,Find_Old_Str);
            read(OSF,Old_Str^);
            if ioresult= 0 then
                Exist_File:= true;
            end;
        if Exist_File then
            for HMS:= 10 downto 1 do
                if not Empty(Old_Str^[HMS]) then break;
        Context:= 19;
        Say('По+иск.');
        FStr:= FLine;
        with FTrig do
            begin
            Sorce:= '';
            Install(V_Param^.Memory);
            if not Installed then exit;
            OldCol:= Color.Text;
            Color.Text:= Color.Frame;
            Item[1].Mess:= '  Различать регистр  ';
            Item[1].Status:= V_Param^.Config.Regs;
            Item[2].Mess:= '  Искать в прямом направлении  ';
            Item[2].Status:= V_Param^.Config.Forward;
            Item[3].Mess:= '  Начать поиск с текущей строки  ';
            Item[3].Status:= not V_Param^.Config.FromBegin;
            Item[4].Mess:= '  Искать начало строки  ';
            Item[4].Status:= not V_Param^.Config.SubString;
            Item[5].Mess:= '  Сообщать позицию  ';
            Item[5].Status:= V_Param^.Config.Say_Posit;
            for C_1:= 1 to sizeof(Item) div sizeof(Item[1]) do
                if not Add(Item[C_1]) then break;
            AllElem:= HowManyElem;
            TMargin:= 2;
            LMargin:= 2;
            Title:= ' Поиск ';
            Cycle:= V_Param^.CycleMenu;
            setposition(21,8,60,16);
            Clear(21,8,60,16);
            Color.Text:= Color.Frame;
            FTrig.Show;
            putline(22,9,'Строка - ',Color.Frame);
            end;
        C_1:= 1;
        ECode[3]:= CTab;
        ECode[4]:= CF1;
        Color.Text:= OldCol;
        repeat
            if Exist_File then
                FStr:= Old_Str^[C_1];
            Say('строка+:');
            Say(FStr);
            ECode[5]:= CUp;
            ECode[6]:= CDown;
            editln(31,9,FStr,255,28);
            ECode[5]:= 0;
            ECode[6]:= 0;
            if ReturnCode= CDown then
                if (Exist_File) and (C_1< HMS) then
                    inc(C_1)
                else
                    Signal(S_Edge);
            if ReturnCode= CUp then
                if (Exist_File) and (C_1> 1) then
                    inc(C_1,-1)
                else
                    Signal(S_Edge);
            if ReturnCode= CTab then
                begin
                Say('устано+вки.');
                repeat
                    FTrig.Call;
                    if ReturnCode= CF1 then
                        Hlp_Viewer^.CallPart(Context)
                    else
                        break;
                until false;
                end;
            if ReturnCode= CF1 then
                Hlp_Viewer^.CallPart(Context);
        until (ReturnCode= CEsc) or (ReturnCode= CEnter);
        ECode[3]:= 0;
        ECode[4]:= 0;
        if (Upper(Trim(FStr))= Upper(Trim(Old_Str^[C_1]))) and (ReturnCode= CEnter) then
            Save_Str:= false;
        for C_1:= 1 to sizeof(Item) div sizeof(Item[1]) do
            FTrig.Pick(C_1,Item[C_1]);
        FTrig.Uninstall;
        Color.Text:= OldCol;
        if ReturnCode= CEsc then
            begin
            close(OSF);
            if Old_Str<> nil then
                dispose(Old_Str);
            Say(Cancel);
            exit;
            end;
        if (not Exist_File) and (Save_Str) then
            begin
            IORes:= ioresult;
            rewrite(OSF);
            new(Null);
            for C_1:= 1 to 10 do
                Null^[C_1]:= '';
            for C_1:= 0 to Find_Old_Str do
                begin
                seek(OSF,C_1);
                write(OSF,Null^);
                end;
            dispose(Null);
            if ioresult= 0 then
                Exist_File:= true;
            end;
        if (Exist_File) and (Save_Str) then
            begin
            Old_Str^[1]:= FStr;
            for C_1:= 10 downto 2 do
                Old_Str^[C_1]:= Old_Str^[C_1-1];
            Old_Str^[1]:= '';
            seek(OSF,Find_Old_Str);
            IORes:= ioresult;
            write(OSF,Old_Str^);
            end;
        dispose(Old_Str);
        IORes:= ioresult;
        close(OSF);
        Say(OK);
        FLine:= FStr;
        with V_Param^.Config do
            begin
            Regs:= Item[1].Status;
            Forward:= Item[2].Status;
            FromBegin:= not Item[3].Status;
            SubString:= not Item[4].Status;
            Say_Posit:= Item[5].Status;
            end;
        end;
    if not FindContinue then
        if V_Param^.Config.FromBegin then
            begin
            if V_Param^.Config.Forward then
                C_1:= 1
            else
                C_1:= Real_L;
            end
        else
            C_1:= FirstLine;
    IORes:= ioresult;
    if not V_Param^.Config.Regs then
        FStr:= Lower(FLine)
    else
        FStr:= FLine;
    while true do
        begin
        if (V_Param^.Config.Forward) and (C_1> Real_L) then break;
        if (not V_Param^.Config.Forward) and (C_1< 2) then break;
        if keypressed then
            if DefineKey= CEsc then
                if Yes('       Прервать поиск?       ') then
                    exit;
        (*BeepOn(random(10000)); {//ss/25.09.2003//}
        BeepOff;*)
        Signal(S_Tick);
        Buf:= LOF(C_1);
        if not V_Param^.Config.Regs then
            Buf:= Lower(Buf);
        if V_Param^.Config.SubString then
            begin
            if pos(FStr,Buf)> 0 then
                begin
                V_Signal(6);
                FirstLine:= C_1;
                if V_Param^.Config.Say_Posit then
                    begin
                    SayordNum(FirstLine,'\ая\ строка+');
                    Sayordnum(pos(FStr,Buf),'\ая\ пози+ция.');
                    end;
                exit;
                end;
            end
        else
            if (length(FStr)<= length(Buf)) and (Left(Buf,length(FStr))= FStr) then
                begin
                V_Signal(6);
                FirstLine:= C_1;
                if V_Param^.Config.Say_Posit then
                    SayordNum(FirstLine,'\ая\ строка+');
                exit;
                end;
        if V_Param^.Config.Forward then
            inc(C_1)
        else
            inc(C_1,-1);
        end;
    ShowMessage('           Строка не найдена          ','')
    end;

procedure   toViewer.SetWin;
    var
        TL:             byte;
        TT:             byte;
        TR:             byte;
        TB:             byte;
        Key:            tKeyCode;
        TFR:            tFrame;
        TCl:            byte;

    begin
    Context:= 22;
    TL:= L;
    TT:= T;
    TR:= R;
    TB:= B;
    TCl:= Color.Frame;
    Color.Frame:= $17;
    SymFrm:= Single;
    hidecursor;
    while true do
        begin
        clear(1,1,80,25);
        Show;
        SetCursorXY(L,T+1);
        Key:= definekey;
        case Key of
        CEsc:
                begin
                setposition(TL,TT,TR,TB);
                break;
                end;
      CEnter:  break;
   CShift_Up:  if OnlyShift then
                   setposition(L,T,R,B-1)
               else
                   setposition(L,T-1,R,B-1);
 CShift_Down:  if OnlyShift then
                   setposition(L,T,R,B+1)
               else
                   setposition(L,T+1,R,B+1);
CShift_Right:  if OnlyShift then
                   setposition(L,T,R+1,B)
               else
                   setposition(L+1,T,R+1,B);
 CShift_Left:  if OnlyShift then
                   setposition(L,T,R-1,B)
               else
                   setposition(L-1,T,R-1,B);
         CF1:  Hlp_Viewer^.CallPart(Context);
            end;
        end;
    setcursor(7,8);
    Color.Frame:= TCl;
    SymFrm:= Double;
    clear(1,1,80,25);
    end;

procedure   toViewer.ReadLine;
    var
        Buf:            string;
        Point:          word;
        Counter:        byte;
        Status:         word;
        X,Y:            word;
        Die:            boolean;
        Part:           string;
        BreakSymb:      string[128];
        Cap_Sym:        boolean;

    begin
    Buf:= LOF(FirstLine);
    with V_Param^.AOS do
        if (BSymb> 0) and (ESymb> 0) then
            delete(Buf,BSymb,(ESymb-BSymb)+1);
    if Empty(Buf) then exit;
    if Buf= Replicate(Buf[1],length(Buf)) then
        begin
        speech.SayText(Buf);
        exit;
        end;
    if V_Param^.ReadBySym then Symb_On;
    BreakSymb:= Break_Sym;
    if V_Param^.Capital then
        BreakSymb:= Break_Sym +Alf;
    Point:= 1;
    Die:= false;
    Status:= 0;
    Buf:= Right(Buf,Length(Buf)-(OffSet-1));
    Cap_Sym:= false;
    while Point<= length(Buf) do
        begin
        Buf:= copy(Buf,Point,(length(Buf)-Point)+1);
        for Counter:= 1 to length(Buf)+1 do
            begin
            if Counter= length(Buf)+1 then break;
            if pos(Buf[Counter],BreakSymb)> 0 then
                begin
                if pos(Buf[Counter],Alf)> 0 then
                    if not Cap_Sym then
                        begin
                        Cap_Sym:= true;
                        continue;
                        end
                    else
                        inc(Counter,-1);
                break;
                end;
            {$IFDEF SV_MOUSE}
            if (V_Param^.Mouse) and (mouseready) then
                mousepositionstatus(@Status,@X,@Y);
            {$ENDIF}
            if (keypressed) or (Status> 0) then
                begin
                Die:= true;
                break;
                end;
            end;
        if Die then break;
        if Counter= 0 then
            begin
            Cap_Sym:= false;
            Point:= Counter+1;
            continue;
            end;
        if Counter<= length(Buf) then
            begin
            if Cap_Sym then
                begin
                Signal(S_Cap);
                Cap_Sym:= false;
                end;
            speech.sayText(Left(Buf,Counter));
            Part:= '';
            Point:= Counter+1;
            end
        else
            begin
            Part:= RTrim(Buf);
            break;
            end;
        end;
    if keypressed then
        V_Signal(20)
    else
        begin
        if (V_Param^.Capital) and (ord(Part[1]) in [128..160]) then
            Signal(S_Cap);
        speech.SayText(Part);
        end;
    Symb_Off;
    end;

procedure   toViewer.ReadText;
    var
        C:              longint;
        Buf:            string;
        HMSpace:        longint;
        Counter:        byte;
        Point:          byte;
        Die:            boolean;
        BreakSymb:      string[128];
        Part:           string;
        Status:         word;
        X,Y:            word;
        TempStr:        string;
        Fix:            longint;
        Old_Time:       string[2];
        Time_Signal:    boolean;
        Time_Num:       byte;
        Err:            integer;
        CanSpeak:       boolean;
        Cap_Sym:        boolean;
        BreakKey:       boolean;

    function  Wrk_Key(K:  tKeyCode):  boolean;
        begin
        Wrk_Key:= true;
        case K of
       CDown:
                begin
                FindEmpty(true);
                C:= FirstLine-1;
                Part:= '';
                Buf:= '';
                end;
         CUp:
                begin
                FindEmpty(false);
                C:= FirstLine-1;
                Part:= '';
                Buf:= '';
                end;
       CLeft:
                begin
                FindIndent(false);
                C:= FirstLine-1;
                Part:= '';
                Buf:= '';
                end;
      CRight:
                begin
                FindIndent(true);
                C:= FirstLine-1;
                Part:= '';
                Buf:= '';
                end;
        else
            Wrk_Key:= false;
            BreakKey:= true;
            end;
        end;
    var
      i, j: Integer;
    begin
    IORes:= ioresult;
    HMSpace:= 0;
    Die:= false;
    BreakSymb:= Break_Sym;
    if V_Param^.Capital then
        BreakSymb:= Break_Sym +Alf;
    Part:= '';
    BreakKey:= false;
    if V_Param^.ReadBySym then Symb_On;
    {$IFDEF SV_MOUSE}
    repeat
        mousepositionstatus(@Status,@X,@Y);
    until (Status= 0) or (not V_Param^.Mouse) or (not mouseready);
    {$ENDIF}
    Status:= 0;
    Old_Time:= '';
    Time_Signal:= false;
    CanSpeak:= true;
    Cap_Sym:= false;
    for C:= FirstLine to Real_L do
        begin
        Buf:= Trim(LOF(C));
        {$IFDEF SV_MOUSE}  
        if (V_Param^.Mouse) and (mouseready) then
            mousepositionstatus(@Status,@X,@Y);
        {$ENDIF}
        VerifyAlarms;
        if (keypressed) or (Status> 0) then
            begin
            if not Wrk_Key(DefineKey) then
                break
            else
                continue;
            end;
        if empty(Buf) then
            begin
            if Cap_Sym then
                begin
                Signal(S_Cap);
                Cap_Sym:= false;
                end;
            speech.SayText(Part);
            Part:= '';
            inc(HMSpace);
            if HMSpace< 5 then
                for i:=0 to V_Param^.Empty_Delay-1 do begin
                  if keypressed then
                    break;
                  VerifyAlarms;
                  Pause(54);
                end;
            if (keypressed) or (Status> 0) then
                begin
                if not Wrk_Key(DefineKey) then
                    break
                else
                    continue;
                end;
            end
        else
            begin
            if (HMSpace> 2) and (V_Param^.EmptyBell) then
                for Counter:= 1 to 10 do
                    V_Signal(8);
            HMSpace:= 0;
            Point:= 1;
            {$IFDEF SV_MOUSE} 
            if (V_Param^.Mouse) and (mouseready) then
                mousepositionstatus(@Status,@X,@Y);
            {$ENDIF}
            if (keypressed) or (Status> 0) then
                begin
                if not Wrk_Key(DefineKey) then
                    break
                else
                    continue;
                end;
            if length(Part)+length(Buf)> 160 then
                begin
                if Part[length(Part)]= '-' then
                    begin
                    speech.SayText(Left(Part,length(Part)-RPos(' ',Part)));
                    Part:= Right(Part,RPos(' ',Part)-1);
                    end
                else
                    begin
                    speech.SayText(Part);
                    Part:= '';
                    end;
                end;
            if Part[length(Part)]= '-' then
                Buf:= Trim(Left(Part,length(Part)-1)+Buf)
            else
                Buf:= Trim(Part +' ' +Buf);
            if Buf= Replicate(Buf[1],length(Buf)) then
                begin
                speech.SayText(Buf);
                Point:= length(Buf)+1;
                end;
            while Point<= length(Buf) do
                begin
                Buf:= copy(Buf,Point,(length(Buf)-Point)+1);
                {$IFDEF SV_MOUSE} 
                if (V_Param^.Mouse) and (mouseready) then
                    mousepositionstatus(@Status,@X,@Y);
                {$ENDIF}
                if (keypressed) or (Status> 0) then
                    begin
                    if not Wrk_Key(DefineKey) then
                        break
                    else
                        continue;
                    end;
                for Counter:= 1 to length(Buf)+1 do
                    begin
                    if Counter= length(Buf)+1 then break;
                    if pos(Buf[Counter],BreakSymb)> 0 then
                        begin
                        if pos(Buf[Counter],Alf)> 0 then
                            if not Cap_Sym then
                                begin
                                Cap_Sym:= true;
                                continue;
                                end
                            else
                                inc(Counter,-1);
                        break;
                        end;
                    {$IFDEF SV_MOUSE}
                    if (V_Param^.Mouse) and (mouseready) then
                        mousepositionstatus(@Status,@X,@Y);
                    {$ENDIF}
                    if (keypressed) or (Status> 0) then
                        begin
                        if not Wrk_Key(DefineKey) then
                            begin
                            Die:= true;
                            break;
                            end
                        else
                            break;
                        end;
                    end;
                Time_Control;
                VerifyAlarms;
                if Die then break;
                if Counter= 0 then
                    begin
                    Point:= Counter+1;
                    Cap_Sym:= false;
                    continue;
                    end;
                if Counter<= length(Buf) then
                    begin
                    if Cap_Sym then
                        begin
                        Signal(S_Cap);
                        Cap_Sym:= false;
                        end;
                    speech.SayText(Left(Buf,Counter));
                    Part:= '';
                    {$IFDEF SV_MOUSE}
                    if (V_Param^.Mouse) and (mouseready) then
                        mousepositionstatus(@Status,@X,@Y);
                    {$ENDIF}
                    if (keypressed) or (Status> 0) then
                        begin
                        if not Wrk_Key(DefineKey) then
                            begin
                            Die:= true;
                            break;
                            end
                        else
                            break;
                        end;
                    if Counter= 255 then
                        break;
                    Point:= Counter+1;
                    end
                else
                    begin
                    Part:= RTrim(Buf);
                    break;
                    end;
                end;
            end;
        FirstLine:= C;
        show;
        ShowScr;
        if FirstLine= Break_Read_Line then break;
        if Die then break;
        end;
    if not BreakKey then
        begin
        if (V_Param^.Capital) and (ord(Part[1]) in [128..160]) then
            Signal(S_Cap);
        speech.SayText(Part);
        end;
    Symb_Off;
    if FirstLine= Break_Read_Line then
        begin
        V_Signal(9);
        exit;
        end;
    if (V_Param^.ReadWinByWin) and (V_Param^.Sep_Win) and (not BreakKey) then
        begin
        V_Signal(10);
        exit;
        end;
    if (not V_Param^.BOE) and (not BreakKey) then exit;
    while True do begin
        V_Signal(9);
        if BreakKey then break;
        if keypressed or (Status> 0) then
          break;
        DoBackgroundTasks;
    end;
    ClearBuffer;
    end;

procedure   toViewer.Next(Step:  longint);
    var
        Buff:           string;
        LEd:            byte;
        REd:            byte;
        NW:             integer;

    begin
    if (Viewer[CWin]= nil) or ((FirstLine= Real_L) or (Real_L< 1)) then
        begin
        Signal(S_Edge);
        exit;
        end;
    inc(FirstLine,Step);
    if FirstLine> Real_L then
        FirstLine:= Real_L;
    if FirstLine= Block_Begin then
        Say('Нача+ло бло+ка.');
    if FirstLine= Block_End then
        Say('коне+ц бло+ка.');
    if (FirstLine> Block_Begin) and (FirstLine< Block_End) then
        V_Signal(12);
    Buff:= LOF(FirstLine);
    if empty(Buff) then
        begin
        if V_Param^.ReadEmpty then
            Say('пуста+я.')
        else
            V_Signal(1);
        end
    else
        begin
        if Buff[1]<> ' ' then
            begin
            if V_Param^.ReadWord then
                begin
                if not V_Param^.ReadAllLine then
                    if V_Param^.Local= 0 then
                        begin
                        for C:= 1 to length(Buff) do
                            if (pos(Buff[C],Break_Sym)> 0) or (Buff[C]= ' ') then break;
                        REd:= C;
                        Say(copy(Buff,1,REd));
                        end
                    else
                        begin
                        if pos(' ',Buff)> 0 then
                            Red:= pos(' ',Buff)
                        else
                            REd:= length(Buff);
                        Say(copy(Buff,1,REd));
                        end;
                end
            else
                V_Signal(2);
            end
        else
            begin
            if (Left(LTrim(Buff),1)= '-') or (Empty(Left(Buff,10))) then
                V_Signal(2)
            else
                if V_Param^.ReadIndent then
                    Say('абза+ц.')
                else
                    V_Signal(3);
            end;
        end;
    if V_Param^.ReadAllLine then
        ReadLine;
    if (length(Buff)< OffSet) then
        OffSet:= length(Buff);
    end;

procedure   toViewer.Last(Step:  longint);
    var
        Buff:           string;

    begin
    if (Viewer[CWin]= nil) or (FirstLine= 1) then
        begin
        Signal(S_Edge);
        exit;
        end;
    inc(FirstLine,-Step);
    if FirstLine< 1 then
        FirstLine:= 1;
    if FirstLine= Block_Begin then
        Say('Нача+ло бло+ка.');
    if FirstLine= Block_End then
        Say('коне+ц бло+ка.');
    if (FirstLine> Block_Begin) and (FirstLine< Block_End) then
        V_Signal(12);
    Buff:= LOF(FirstLine);
    if empty(Buff) then
        begin
        if V_Param^.ReadEmpty then
            Say('пуста+я.')
        else
            V_Signal(1);
        end
    else
        begin
        if Buff[1]<> ' ' then
            begin
            if V_Param^.ReadWord then
                begin
                if not V_Param^.ReadAllLine then Say(Left(Buff,pos(' ',Buff)));
                end
            else
                V_Signal(2);
            end
        else
            begin
            if (Left(LTrim(Buff),1)= '-') or (Empty(Left(Buff,10))) then
                V_Signal(2)
            else
                if V_Param^.ReadIndent then
                    Say('абза+ц.')
                else
                    V_Signal(3);
            end;
        end;
    if V_Param^.ReadAllLine then
        ReadLine;
    if (length(Buff)< OffSet) and (not Empty(Buff)) then
        OffSet:= length(Buff);
    end;

function    toViewer.LOF(Num:  longint):  string;
    var
        Rec:            tRecord;
        Buf:            array[0..$1FF] of byte;
        BufStr:         string;
        S:              string;
        Ins_Pos:        byte;
        RealSize:       word;
        Symb_Pos:       byte;
        Fragments:      text;
        FndFrag:        string;
        NewFrag:        string;
        EndFrag:        byte;
        NoCase:         boolean;
        BufS:           string;
        FPos:           byte;
        Addr:           longint;
        XLT:            file;
        C:              word;
        i:              integer;
    begin
    LOF:= '';
    if DBF_File then
        with DBF^ do
            begin
            if Num> DBF^.HMRecords then exit;
            Addr:= (F_Rec_Addr+((Num-1)*Record_Len)+Field[CurField]^.OfS);
            seek(ViewFile,Addr);
            blockread(ViewFile,Buf,Field[CurField]^.Len,RealSize);
            BufStr:= '';
            for C:= 0 to Field[CurField]^.Len-1 do
            BufStr:= BufStr +chr(Buf[C]);
            if DBF^.Field[CurField]^.Typ= 'D' then
                BufStr:= Right(BufStr,2)+'/'+copy(BufStr,5,2)+'/'+Left(BufStr,4);
            LOF:= BufStr;
            exit;
            end;
    if not pick(Num,Rec) then exit;
    IORes:= ioresult;
    seek(ViewFile,Rec.Adr);
    blockread(ViewFile,Buf,Rec.Len,RealSize);
    ArrToString(Buf,BufStr,RealSize);
    if RealSize= 0 then BufStr:= '';
    if V_Param^.Printab then
        begin
        S:= '';
        Symb_Pos:= 0;
        if pos('=?',BufStr)> 0 then
            begin
            Symb_Pos:= pos('=?',BufStr);
            delete(BufStr,Symb_Pos,2);
            end;
        if (Symb_Pos> 0) and (pos('?',BufStr)> Symb_Pos) then
            delete(BufStr,Symb_Pos,pos('?',BufStr)-Symb_Pos);
        for C:= 1 to $FF do
            begin
            if C> length(BufStr) then break;
            if (BufStr[C]= '=') and ((ord(BufStr[C+1]) in [65..90]) or
               (ord(BufStr[C]) in [97..122]) or (ord(BufStr[C+1]) in [48..57])) then
                begin
                S:= S+chr(HToB(copy(BufStr,C+1,2)));
                delete(BufStr,C,3);
                inc(C,-1);
                end
            else
                S:= S +BufStr[C];
            end;
        BufStr:= S;
        end;
    case V_Param^.Mode of
       1:  reputStrng(BufStr,Tab_1.Win2Dos);
       2:  reputStrng(BufStr,Tab_2.Koi2Dos);
       3:  begin
             winStringFromUtf8(BufStr);
             reputStrng(BufStr,Tab_1.Win2Dos);
           end;
       4:  begin
             Load_Tab_3;
             if Tab_3_Loaded then
               reputStrng(BufStr,Tab_3);
           end;
    end;

    for i:=Length(BufStr) downto 1 do begin
        if (BufStr[i] >= #1) and (BufStr[i] <= #31) and (BufStr[i] <> #9) then
            Delete(BufStr,i,1);
        if (V_Param^.Tab) and (BufStr[i] = #9) then begin
            delete(BufStr,i,1);
            insert(Space(5),BufStr,i);
        end;
    end;

    if V_Param^.Transform_Lat then
        Lat2Rus(BufStr);
    if (TrimSpace) and (not Empty(BufStr)) then
        BufStr:= Right(BufStr,length(BufStr)-PText.LMargin);
    if V_Param^.ChFrag then
        begin
        if ChList.InitMemory then
            C:= 0
        else
            begin
            if Empty(V_Param^.ChFrag_F) then
                assign(Fragments,MyDirc+ChFrag)
            else
                assign(Fragments,V_Param^.ChFrag_F);
            IORes:= ioresult;
            reset(Fragments);
            if ioresult<> 0 then
                begin
                LOF:= BufStr;
                exit;
                end;
            end;
        FndFrag:= #1;
        NewFrag:= #1;
        NoCase:= false;
        while ((not ChList.InitMemory) and (not eof(Fragments))) or
            ((ChList.InitMemory) and (C< ChList.HowManyElem)) do
            begin
            if ChList.InitMemory then
                begin
                inc(C);
                ChList.Pick(C,BufS);
                end
            else
                readln(Fragments,BufS);
            if (BufS[1]= FndFrag_Mark) or
               ((BufS[1]= NoCase_Mark) and (BufS[2]= FndFrag_Mark)) then
                begin
                if BufS[1]= NoCase_Mark then
                    begin
                    BufS:= Upper(Right(BufS,length(BufS)-1));
                    NoCase:= true;
                    end
                else
                    NoCase:= false;
                FndFrag:= BufS;
                for EndFrag:= length(BufS) downto 1 do
                    if BufS[EndFrag]= FndFrag_Mark then break;
                if EndFrag> 2 then
                    FndFrag:= copy(BufS,2,EndFrag-2);
                end;
            if BufS[1]= NewFrag_Mark then
                begin
                NewFrag:= BufS;
                for EndFrag:= length(BufS) downto 1 do
                    if BufS[EndFrag]= NewFrag_Mark then break;
                if EndFrag> 2 then
                    NewFrag:= copy(BufS,2,EndFrag-2)
                else
                    NewFrag:= '';
                end;
            if (FndFrag= #1) or (NewFrag= #1) then continue;
            BufS:= BufStr;
            BufStr:= '';
            FPos:= pos(FndFrag,iif(NoCase,Upper(BufS),BufS));
            while FPos> 0 do
                begin
                BufStr:= BufStr+Left(BufS,FPos-1)+NewFrag;
                BufS:= Right(BufS,length(BufS)-FPos-length(FndFrag)+1);
                FPos:= pos(FndFrag,iif(NoCase,Upper(BufS),BufS));
                end;
            BufStr:= BufStr+BufS;
            FndFrag:= #1;
            NewFrag:= #1;
            end;
        if not ChList.InitMemory then
            begin
            IORes:= ioresult;
            close(Fragments);
            IORes:= ioresult;
            end;
        end;
    LOF:= BufStr;
    end;

destructor  toViewer.Uninstall;
    var
        FLP:            tFLP;
        LP:             tLast_Posit;
        Cnt:            longint;

    begin
    if not Installed then exit;
    clear(L,T,R,B);
    showscr;
    close(ViewFile);
    if DBF_File then
        begin
        for C:= 1 to DBF^.HMFields do
            dispose(DBF^.Field[C]);
        dispose(DBF);
        end
    else
        undefine;
    if (Doc_File) or (Htm_File) then
        DeleteFile(Doc2txt_F);
    Real_L:= 0;
    if not V_Param^.Last_Posit then
        begin
        OffSet:= 1;
        FirstLine:= 1;
        Installed:= false;
        exit;
        end;
    assign(FLP,MyDirc+FLast_Posit);
    IORes:= ioresult;
    reset(FLP);
    if ioresult= 0 then
        begin
        for Cnt:= 0 to filesize(FLP) do
            begin
            if Cnt= filesize(FLP) then break;
            IORes:= ioresult;
            seek(FLP,Cnt);
            read(FLP,LP);
            if SameFileName(LP.FN, FPath+FName+FExtn) then
                begin
                if (FirstLine= 1) and (OffSet= 1) then
                    begin
                    seek(FLP,filesize(FLP)-1);
                    read(FLP,LP);
                    seek(FLP,Cnt);
                    write(FLP,LP);
                    seek(FLP,filesize(FLP)-1);
                    truncate(FLP);
                    break;
                    end;
                LP.L:= FirstLine;
                LP.OfS:= OffSet;
                seek(FLP,Cnt);
                write(FLP,LP);
                break;
                end;
            end;
        if (Cnt= filesize(FLP)) and ((FirstLine> 1) or (OffSet> 1)) then
            begin
            FillChar(LP, SizeOf(LP), 0); {//ss/21.04.2003 14:44:26//}
            LP.FN:= FPath+FName+FExtn;
            LP.L:= FirstLine;
            LP.OfS:= OffSet;
            IORes:= ioresult;
            seek(FLP,filesize(FLP));
            write(FLP,LP);
            end;
        end
    else
        if (FirstLine> 1) or (OffSet> 1) then
            begin
            FillChar(LP, SizeOf(LP), 0); {//ss/21.04.2003 14:44:29//}
            LP.FN:= FPath+FName+FExtn;
            LP.L:= FirstLine;
            LP.OfS:= OffSet;
            rewrite(FLP);
            write(FLP,LP);
            end;
    IORes:= ioresult;
    close(FLP);
    OffSet:= 1;
    FirstLine:= 1;
    Installed:= false;
    end;

begin
end.
{

Довыденков Владимир
08/02/2000
  определение клавиши  f2  в списке закладок
    toViewer.BookMark

09/02/2000
  определение клавиши  f3  в списке закладок

16/02/2000
  введение функции  SayText  для чтения текста (в зависимости от языка)
  в процедуры  toViewer.ReadText  и  toViewer.ReadLine
}
