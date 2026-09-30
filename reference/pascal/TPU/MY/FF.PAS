unit FF;
{$F+,I-}
interface
uses mem,harddisk,help,  dos;

type
    tProcedure=     procedure;
    tpsearchrec=    ^searchrec;

const
    Bug:            longint = 1;
    CF_Mask:        string = '*.*';
    CF_Hidn:        boolean = false;
    CF_Path:        dirstr = '';
    CF_ChDr:        boolean = true;
    CF_Memr:        tMemory = mem.low;
    CF_NoFl:        string = ';.;';
    CF_Sort:        byte = 0;
    StackSize:      word = 512;
    Sort_By_Ext=    0;
    Sort_By_Nme=    1;

var
    PLocated:       tpsearchrec;
    Dirc:           toMemory;
    SizeDirectory:  longint;
    CF_Help:        toHelp;

procedure WF(proc:  tProcedure);
procedure Calc_Size_Directory(Dir_Name:  dirstr);
function  ChFile:  string;

function FileStrToConsole(const WinStr: String): String;
function FileSymbToConsole(WinSymb: Char): Char;

function SameFileName(const FileName1, FileName2: String): Boolean;

implementation
uses keyb,line,dialog,dinamic,transfrm,speech,various,  discs,video,tables, ff_win;

const
    W_L=            15;
    W_T=            8;
    W_R=            66;
    W_B=            18;

var
    IOR:            word;
    FList:          toMemory;
    F:             SearchRec;
    Src_dir:        dirstr;
    Cur_F:          longint;
    Dir:            dirstr;
    NDir:           dirstr;
    FL:             longint;
    ToConsole:      toWin2Dos;

procedure WF(Proc:  tProcedure);
    begin
    if not Dirc.InitMemory then exit;
    if not Dirc.Pick(Bug,Dir) then exit;
    IOR:= ioresult;
    chdir(Dir);
    findfirst('*.*',anyfile,PLocated^);
    while (doserror= 0) and (ioresult= 0) do
        begin
        if (PLocated^.attr and $10)= 0 then
            proc
        else
            if (PLocated^.name<> '..') and (PLocated^.name<> '.') then
                begin
                NDir:= Dir+'\'+PLocated^.name;
                Dirc.Add(NDir);
                end;
        findnext(PLocated^);
        end;
    findclose(PLocated^);
    inc(Bug);
    {$ifndef FPC}{!!!}
    if (Bug<= Dirc.HowManyElem) and ((SPtr-StackLimit)> (StackSize+1024)) then
    {$endIf}
        WF(Proc);

    Bug:= 1;
    end;

procedure Plus;
    begin
    inc(SizeDirectory,PLocated^.size);
    end;

procedure Calc_Size_Directory(Dir_Name:  dirstr);
    var
        Old_Directory:  dirstr;
        NDD:            dirstr;

    begin
    SizeDirectory:= 0;
    Dirc.Define(Mem.low,sizeof(dirstr));
    if not Dirc.InitMemory then exit;
    IOR:= ioresult;
    getdir(0,Old_Directory);
    if ioresult<> 0 then
        Old_Directory:= '';
    if copy(Dir_Name,2,2)= ':\' then
        begin
        getdir(ord(upcase(Dir_Name[1]))-64,NDD);
        if ioresult<> 0 then
            NDD:= '';
        end;
    Dirc.Add(Dir_Name);
    WF(Plus);
    IOR:= ioresult;
    chdir(NDD);
    IOR:= ioresult;
    chdir(Old_Directory);
    Dirc.Undefine;
    end;

function FileStrToConsole(const WinStr: String): String;
var
  s: String;
begin
  s:=WinStr;
  ReputStrng(s,ToConsole.Win2Dos);
  FileStrToConsole:=s;
end;

function FileSymbToConsole(WinSymb: Char): Char;
begin
  FileSymbToConsole:=ToConsole.Win2Dos[WinSymb];
end;


function SameFileName(const FileName1, FileName2: String): Boolean;
begin
  SameFileName:=ff_win.SameFileName(FileName1, FileName2);
end;


procedure Show_FList;
    var
        C:              byte;
        FColor:         byte;
        Size_Str:       string[9];
        OfS_T:          byte;
        CurD:           dirstr;

    begin
    Clear(W_L,W_T,W_R,W_B);
    Frame(W_L,W_T,W_R,W_B);
    for C:= 1 to (W_B-W_T)-3 do
        begin
        FColor:= $1F;
        if not FList.Pick(FL+C,F) then
            begin
            PutLine(W_L+4,(W_T+1)+C,Space(22),FColor);
            continue;
            end;
        if FL+C= Cur_F then
            FColor:= $1E;
        if (F.attr and directory)<> 0 then
            begin
            if F.name= '..' then
                Size_Str:= '<КАТАЛОГ>'
            else
                Size_Str:= '>КАТАЛОГ<';
            end
        else
            begin
            if F.size< 1E+7 then
                Size_Str:= LToS(F.size)
            else
                Size_Str:= LToS(F.size div 1024)+'k';
            Size_Str:= Space(9-length(Size_Str))+Size_Str;
            end;
        PutLine(W_L+4,(W_T+1)+C,
          FileStrToConsole(Copy(F.Name, 1,w_r-w_l-length(Size_Str)-3)),
          FColor); {//ss/14.04.2003 18:35:08//}
        PutLine(W_L+17+22,(W_T+1)+C,Size_Str,FColor);
        if F.time= $FF then
            PutLine(W_L+3,(W_T+1)+C,'*',FColor);
        end;
    CurD:= FileStrToConsole(CF_Path);
    while length(CurD)> (W_R-W_L)-5 do
        CurD:= Left(CurD,3)+'...'
            +Right(CurD,(length(CurD)-3)
            -pos('\',Right(CurD,length(CurD)-3)));
    CurD:= ' '+CurD+' ';
    OfS_T:= ((((W_R-W_L)-1)-length(CurD)) div 2) +1;
    PutLine(W_L+OfS_T,W_T,CurD,Color.Frame);
    PutLine(W_L+2,W_B,IIF(CF_Hidn,'HIDN',''),Color.Frame);
    PutLine(W_L+9,W_B,IIF(CF_Sort= Sort_By_Ext,'ext','name'),Color.Frame);
    end;

procedure FastFind;
    var
        Key:            integer;
        FFile:          string;
        FirstRound:     boolean;
        CanSpeak:       boolean;
        OldNum:         word;
        CF:             SearchRec;
        CX:             byte;
        C:              word;

    begin
    FFile:= '';
    CanSpeak:= true;
    OldNum:= Cur_F;
    Say('По+иск.');
    repeat
        Show_FList;
        CX:= 31+8 +length(FFile);
        Frame(29,W_B+1,52,W_B+3);
        PutLine(30,W_B+2,' Поиск - ',Color.Frame);
        PutLine(31+8,W_B+2,FFile+Space(13-length(FFile)),Color.Message);
        SetCursorXY(CX,W_B+2);
        ShowSCr;
        Key:= DefineKey;
        case Key of
     32..244:{letter}
                begin
                FFile:= FFile +chr(Key);
                if Cur_F> 1 then
                    FirstRound:= true;
                for C:= Cur_F to FList.HowManyElem+1 do
                    begin
                    if C= FList.HowManyElem+1 then
                        if FirstRound then
                            begin
                            C:= 1;
                            FirstRound:= false;
                            end
                        else
                            break;
                    if not FList.Pick(C,CF) then continue;
                    if Upper(FileStrToConsole(Left(CF.Name,length(FFile))))= Upper(FFile) then
                        begin
                        Cur_F:= C;
                        if Cur_F> (W_B-W_T)-3 then
                            FL:= Cur_F-((W_B-W_T)-3)
                        else
                            FL:= 0;
                        break;
                        end;
                    end;
                if C= FList.HowManyElem+1 then
                    begin
                    FFile:= Left(FFile,length(FFile)-1);
                    CanSpeak:= true;
                    Signal(S_Edge);
                    end
                else
                    if (CanSpeak) or (OldNum<> Cur_F) then
                        begin
                        Say(FileStrToConsole(CF.Name));
                        CanSpeak:= false;
                        OldNum:= Cur_F;
                        end;
                end;
       CBack:  if length(FFile)> 0 then
                begin
                SaySymb(FFile[length(FFile)]);
                FFile:= Left(FFile,length(FFile)-1);
                CanSpeak:= true;
                end;
        else
            break;
            end;
    until false;
    ReturnCode:= Key;
    end;

procedure Fill_FList;
    label
        Next,Next_Dirc;

    begin
    FList.CleanMemory;
    IOR:= ioresult;
    findfirst('*.*',anyfile,F);
    while doserror= 0 do
        begin
        if ((F.attr and volumeid)<> 0) or
           ((not CF_Hidn) and ((F.attr and hidden)<> 0)) or
           ((F.attr and directory)= 0) then
            goto Next_Dirc;
        if pos(';'+LowerFileName(F.name)+';',LowerFileName(CF_NoFl))> 0 then
            goto Next_Dirc;
        if SameFileName(Src_Dir, CF_Path) and (not CF_ChDr) and (F.Name= '..') then
            goto Next_Dirc;
        F.time:= 0;
        FList.Add(F);
        Next_Dirc:
        findnext(F);
        end;
    findclose(F);

    findfirst(CF_Mask,anyfile,F);
    while doserror= 0 do
        begin
        if ((F.attr and volumeid)<> 0) or
           ((not CF_Hidn) and ((F.attr and hidden)<> 0)) or
           ((F.attr and directory)<> 0) then
            goto Next;
        if pos(';'+LowerFileName(F.name)+';',LowerFileName(CF_NoFl))> 0 then
            goto Next;
        if SameFileName(Src_Dir, CF_Path) and (not CF_ChDr) and (F.Name= '..') then
            goto Next;
        F.time:= 0;
        FList.Add(F);
        Next:
        findnext(F);
        end;
    findclose(F);
    end;

procedure Sort_FList;
    var
        C1:             longint;
        C2:             longint;
        F1:             SearchRec;
        F2:             SearchRec;
        Buf:            searchrec;
        S1:             string;
        S2:             string;
        {//ss/15.04.2003 14:44:59//}
        Dir:            dirstr;
        Nme:            namestr;
        Ext:            extstr;

    begin
    if FList.HowManyElem= 1 then exit;
    for C1:= 1 to FList.HowManyElem-1 do
        for C2:= C1+1 to FList.HowManyElem do
            begin
            FList.Pick(C1,F1);
            FList.Pick(C2,F2);
            if CF_Sort= Sort_By_Ext then
                begin
                FSplit(F1.Name,Dir,Nme,Ext);
                S1:= LowerFileName(Ext+Nme);
                FSplit(F2.Name,Dir,Nme,Ext);
                S2:= LowerFileName(Ext+Nme);
                end;
            if CF_Sort= Sort_By_Nme then
                begin
                FSplit(F1.Name,Dir,Nme,Ext);
                S1:= LowerFileName(Nme+Ext);
                FSplit(F2.Name,Dir,Nme,Ext);
                S2:= LowerFileName(Nme+Ext);
                end;
            if (F1.attr and directory)<> 0 then
                S1:= #1+S1;
            if (F2.attr and directory)<> 0 then
                S2:= #1+S2;
            if S1> S2 then
                begin
                FList.Change(C1,F2);
                FList.Change(C2,F1);
                end;
            end;
    end;

function  ChFile:  string;
    label
        Choice;

    var
        K:              tKeyCode;
        C:              longint;
        Marked:         longint;
        DC:             byte;
        Find_Name:      string;
        F_Dir:          dirstr;
        F_Dsk:          byte;
        FMList:         string;
        VisibleCount:   byte;
        CharPos:        Integer;
        DontSay:        Boolean;
    begin
    ChFile:= '';
    Marked:= 0;
    ReturnCode:= 0;
    VisibleCount:=W_B - W_T - 4;
    CharPos:=0;
    DontSay:=False;
    with FList do
        begin
        Sorce:= '';
        Define(CF_Memr,sizeof(F));
        if not InitMemory then exit;
        end;
    IOR:= ioresult;
    getdir(0,F_Dir);
    F_Dsk:= getcurdisk;
    IOR:= ioresult;
    if (Length(CF_Path) = 2) and (CF_Path[2] = ':') then
        getdir(Ord(Upcase(CF_Path[1]))-Ord('A')+1,CF_Path);
    if Empty(CF_Path) then
        getdir(0,CF_Path);
    Src_Dir:= CF_Path;
    Cur_F:= 1;
    FL:= 0;
    Find_Name:= '';
    Choice:
    if Empty(CF_Path) then
        getdir(0,CF_Path);
    IOR:= ioresult;
    chdir(CF_Path);
    Fill_FList;
    if (FList.HowManyElem= 1) and (not CF_ChDr) and
       SameFileName(Src_Dir, CF_Path) then
        begin
        FList.Pick(1,F);
        if (F.attr and directory)= 0 then
            begin
            ChFile:= F.name;
            FList.Undefine;
            exit;
            end;
        end;
    if FList.HowManyElem< 1 then
        begin
        FList.Undefine;
        exit;
        end;
    Sort_FList;
    if not Empty(Find_Name) then
        begin
        for Cur_F:= 1 to FList.HowManyElem+1 do
            begin
            if Cur_F= FList.HowManyElem+1 then break;
            FList.Pick(Cur_F,F);
            if SameFileName(F.name, Find_Name) then
                break;
            end;
        if Cur_F= FList.HowManyElem+1 then
            Cur_F:= 1
        else
            if Cur_F> (W_B-W_T)-3 then
                FL:= Cur_F-((W_B-W_T)-3);
        end;
    ReturnAlt:= true;
    while true do
        begin
        Show_FList;
        SetCursorXY(W_L+2,(W_T+1)+(Cur_F-FL));
        ShowScr;
        if FList.Pick(Cur_F,F) then
            if not DontSay then begin
              if F.name= '..' then
                  Say('две+ то+чки.')
              else
                  Say(FileStrToConsole(F.Name));
            end;
        DontSay:=False;
        if F.time= $FF then
            Signal(S_Selected);
        K:= DefineKey;
        if (K= 0) and (OnlyAlt) then
            begin
            FastFind;
            K:= ReturnCode;
            end;
        case K of
        CEsc:  break;
       CDown:  if Cur_F< FList.HowManyElem then
                begin
                inc(Cur_F);
                if Cur_F> ((W_B-W_T)-3)+FL then
                    inc(FL);
                CharPos:=0;
                end
            else
                Signal(S_Edge);
         CUp:  if Cur_F> 1 then
                begin
                inc(Cur_F,-1);
                if Cur_F< FL+1 then
                    inc(FL,-1);
                CharPos:=0;
                end
            else
                Signal(S_Edge);
       CPgUp: begin
                Inc(Cur_F, -VisibleCount);
                Inc(FL, -VisibleCount);
                if Cur_F <= 0 then begin
                  Cur_F:=1;
                  FL:=0;
                  Signal(S_Edge);
                end;
                if FL < 0 then
                  FL:=0;
                CharPos:=0;
              end;
       CPgDn: begin
                Inc(Cur_F, VisibleCount);
                Inc(FL, VisibleCount);
                if FL > (FList.HowManyElem-((W_B-W_T)-3)) then
                  FL:= FList.HowManyElem-((W_B-W_T)-3);
                if Cur_F >= FList.HowManyElem then begin
                  Cur_F:= FList.HowManyElem;
                  FL:= Cur_F-((W_B-W_T)-3);
                  Signal(S_Edge);
                end;
                CharPos:=0;
              end;
       CHome:
                begin
                Cur_F:= 1;
                FL:= 0;
                CharPos:=0;
                end;
        CEnd:
                begin
                Cur_F:= FList.HowManyElem;
                FL:= Cur_F-((W_B-W_T)-3);
                CharPos:=0;
                end;
      CRight:   begin
                  Inc(CharPos);
                  if CharPos <= Length(F.Name) then
                    SaySymb(FileSymbToConsole(F.Name[CharPos]))
                  else begin
                    CharPos:=Length(F.Name)+1;
                    Signal(S_Edge);
                  end;
                  DontSay:=True;
                end;
      CLeft:    begin
                  Dec(CharPos);
                  if CharPos >= 1 then
                    SaySymb(FileSymbToConsole(F.Name[CharPos]))
                  else begin
                    CharPos:=0;
                    Signal(S_Edge);
                  end;
                  DontSay:=True;
                end;
      CEnter:
                begin
                FList.Pick(Cur_F,F);
                if (F.attr and directory)= 0 then
                    begin
                    if Marked= 0 then
                        begin
                        ChFile:= F.name;
                        break;
                        end
                    else
                        begin
                        FMList:= '';
                        for C:= 1 to FList.HowManyElem do
                            begin
                            if not FList.Pick(C,F) then continue;
                            if F.time= $FF then
                                FMList:= FMList +F.name +';';
                            end;
                        ChFile:= FMList;
                        break;
                        end;
                    end
                else
                    begin
                    if F.name= '..' then
                        begin
                        if (CF_Path[length(CF_Path)]= '\') and (length(CF_Path)> 3) then
                            CF_Path:= Left(CF_Path,length(CF_Path)-1);
                        for DC:= length(CF_Path) downto 1 do
                            if CF_Path[DC]= '\' then
                                break;
                        Find_Name:= Right(CF_Path,length(CF_Path)-DC);
                        CF_Path:= Left(CF_Path,DC-1);
                        if length(CF_Path)= 2 then
                            chdir('..');
                        FL:= 0;
                        Cur_F:= 1;
                        goto Choice;
                        end
                    else
                        begin
                        CF_Path:= CF_Path
                            +IIF(CF_Path[length(CF_Path)]= '\','','\')
                            +F.name;
                        FL:= 0;
                        Cur_F:= 1;
                        goto Choice;
                        end;
                    end;
                end;
     CCtrl_S:  if OnlyCtrl then
                begin
                case CF_Sort of
         Sort_By_Nme:
                        begin
                        CF_Sort:= Sort_By_Ext;
                        Say('Сортирова+ть по+ расшире+нию.');
                        end;
         Sort_By_Ext:
                        begin
                        CF_Sort:= Sort_By_Nme;
                        Say('Сортирова+ть по+ и+мени фа+йла..');
                        end;
                    end;
                Find_Name:= F.name;
                FL:= 0;
                Cur_F:= 1;
                goto choice;
                end;
     CCtrl_H:  if OnlyCtrl then
                begin
                CF_Hidn:= not CF_Hidn;
                Say(IIF(CF_Hidn,'','не')+'пока+зывать скры+тые фа+йлы.');
                Find_Name:= F.name;
                FL:= 0;
                Cur_F:= 1;
                goto choice;
                end;
         CF1:  CF_Help.CallPart(Context);
CAlt_9..CAlt_1:  if (OnlyAlt) and (CF_ChDr) then
                begin
                if pos(upcase(chr(abs(K)-55)),Upper(availabledisks))> 0 then
                    begin
                    if setcurdisk(abs(K)-120) then
                        begin
                        FL:= 0;
                        Cur_F:= 1;
                        CF_Path:= '';
                        CharPos:=0;
                        goto Choice;
                        end;
                    end;
                end;
  CCtrl_PgUp:  if (OnlyCtrl) and (CF_ChDr) then
                begin
                if (CF_Path[length(CF_Path)]= '\') and (length(CF_Path)> 3) then
                    CF_Path:= Left(CF_Path,length(CF_Path)-1);
                for DC:= length(CF_Path) downto 1 do
                    if CF_Path[DC]= '\' then
                        break;
                Find_Name:= Right(CF_Path,length(CF_Path)-DC);
                CF_Path:= Left(CF_Path,DC-1);
                chdir('..');
                FL:= 0;
                Cur_F:= 1;
                CharPos:=0;
                goto Choice;
                end;
          28:  if (OnlyCtrl) and (CF_ChDr) then
                begin
                IOR:= ioresult;
                while ioresult= 0 do
                    chdir('..');
                CF_Path:= '';
                FL:= 0;
                Cur_F:= 1;
                CharPos:=0;
                goto Choice;
                end;
        CIns:  if (F.attr and directory)= 0 then
                begin
                if F.time= $FF then
                    begin
                    F.time:= 0;
                    inc(Marked,-1);
                    end
                else
                    begin
                    F.time:= $FF;
                    inc(Marked);
                    end;
                FList.Change(Cur_F,F);
                str(Marked,FMList);
                Say(FMList);
                end;
   CCtrl_End:  if OnlyCtrl then
                begin
                for Cur_F:= 1 to FList.HowManyElem do
                    begin
                    if not FList.Pick(Cur_F,F) then continue;
                    if (F.attr and directory)= 0 then
                        begin
                        if Cur_F= 1 then
                            begin
                            Signal(S_Edge);
                            break;
                            end;
                        inc(Cur_F,-1);
                        if Cur_F> (W_B-W_T)-3 then
                            FL:= Cur_F-((W_B-W_T)-3);
                        CharPos:=0;
                        break;
                        end;
                    end;
                end;
  CCtrl_Home:  if OnlyCtrl then
                begin
                for C:= 1 to FList.HowManyElem+1 do
                    begin
                    if C= FList.HowManyElem+1 then
                        begin
                        Signal(S_Edge);
                        break;
                        end;
                    if not FList.Pick(C,F) then continue;
                    if (F.attr and directory)= 0 then
                        begin
                        Cur_F:= C;
                        if Cur_F> (W_B-W_T)-3 then
                            FL:= Cur_F-((W_B-W_T)-3);
                        CharPos:=0;
                        break;
                        end;
                    end;
                end;
            end;
        end;
    ReturnCode:= K;
    FList.Undefine;
    IOR:= ioresult;
    setcurdisk(F_Dsk);
    chdir(F_Dir);
    IOR:= ioresult;
    end;

begin
CF_Help.Usage_Mem:= CF_Memr;
ToConsole.Install;
end.
