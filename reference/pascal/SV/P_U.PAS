unit P_U;
{$B-,I-,V-}
{$define external}
interface
uses mem,dialog,various, s_u{//ss};

type
    tAlarm=         record
                        Status:         boolean;
                        Tme:            string[5];
                        EveryOnce:      boolean;
                        Message:        string;
                        end;
    tConfig_Viewer= record
                        Forward:        boolean; {menu of found line}
                        Regs:           boolean; {register of letter}
                        FromBegin:      boolean; {find from begin}
                        SubString:      boolean;
                        Say_Posit:      boolean;
                        Alarm:          array[1..10] of tAlarm;
                        end;
    tAOS=           record
                        BSymb:          byte;
                        ESymb:          byte;
                        end;
    tParam_Viewer=  record
                        Config:         tConfig_Viewer;
                        Mode:           byte; {type of file}
                        Memory:         tMemory; {type of memory for work}
                        Temp_Dir:       string; {work directory}
                        CycleMenu:      boolean;
                        AutoSave:       boolean;
                        Tab:            boolean;
                        ExitConfirm:    boolean;
                        Transform_Lat:  boolean;
                        NoStop:         boolean;
                        User_Decode:    string;
                        Jump_1:         longint;
                        Jump_2:         longint;
                        Exact_Time:     boolean;
                        Local:          byte;
                        ChFrag:         boolean;
                        ChFrag_F:       string;
                        Printab:        boolean;
                        Clock:          boolean;
                        Mouse:          boolean;
                        Cursor:         Boolean;
                        PerCent:        boolean; {show percent}
                        Coord:          boolean; {show firstline and offset}
                        MemSize:        boolean; {show free memory}
                        ShCode:         boolean;
                        SPBM:           boolean; {global book-mark}
                        ShowLine:       boolean; {line of book-mark}
                        Auto_Ext_BMark: boolean;
                        Talk:           boolean;
                        Dictor:         byte;
                        Dic_Dir:        string;
                        Temp:           0..150;
                        ReadEmpty:      boolean; {read empty line as "empty"}
                        ReadBySym:      boolean; {read symbol by symbol}
                        ReadWord:       boolean; {Read one word}
                        ReadIndent:     boolean;
                        ReadWinByWin:   boolean;
                        ReadAllLine:    boolean;
                        ReadSpace:      boolean;
                        Capital:        boolean;
                        AOS:            tAOS;
                        Empty_Delay:    byte;
                        Sound:          boolean;
                        EmptyBell:      boolean; {bell after more 1 empty line}
                        BOE:            boolean; {bell of end}
                        Sep_Win:        boolean;
                        LoadSound:      boolean;
                        Indent_Control: boolean;
                        DBF_Control:    boolean;
                        Arc_Control:    boolean;
                        Doc_Control:    boolean;
                        Word97_StLen:   byte;
                        Htm_Control:    boolean;
                        Html_Link:      boolean;
                        ShowProcess:    boolean;
                        Last_Posit:     boolean;
                        AutoDetect_Code:boolean;
                        Lat_Language:   byte;
                        Cyr_Language:   byte;
                        Ukr_Coding:     byte;
                        SV_Color:       tColor;
                        Load_Last_Files: Boolean; {//ss/27.03.2003 15:34:18//}
                        Last_Files: array[tHMW] of String; {//ss/27.03.2003 15:34:20//}
                        Open_Mask: String; {//ss/31.03.2003 18:04:33//}
                        Startup_OpenDialog: Boolean; {//ss/14.04.2003 18:07:32//}
                        Startup_Read_OnStart: Boolean;
                        end;
    tCfgFile=       file of tConfig_Viewer;
    tLast_Posit=    record
                        L:              longint;
                        OfS:            word;
                        FN:             string[255];
                        end;
    tFLP=           file of tLast_Posit;
{$ifdef external}
const
    CfgFile=        'SV.CFG';
    IniFile=        'SV.INI';
    IniComm=        ';';
{$endif}
var
    V_Param:        ^tParam_Viewer;
{$ifdef external}
    C_Name:         array[Tetrada] of string[14];

procedure RParam;
procedure SParam;
{$endif}
procedure Set_Viewer_Param;
procedure Set_Default_Param;

implementation
uses e_u,transfrm,harddisk,line,hronos,speech,dinamic,htmtrans,
  ff,  spick,  keyb,wordconv,  dos, Musefect;
{$ifdef external}
var
    IORes:          word;

procedure SParam;
    var
        Cfg:            tCfgFile;
        Ini:            text;
        i: tHMW;
        s: String;
    begin
    assign(Cfg,MyDirc+CfgFile);
    assign(Ini,MyDirc+IniFile);
    IORes:= ioresult;
    rewrite(Cfg);
    if ioresult<> 0 then
        V_Err(9);
    write(Cfg,V_Param^.Config);
    if ioresult<> 0 then
        V_Err(10);
    close(Cfg);
    IORes:= ioresult;
    rewrite(Ini);
    if ioresult<> 0 then
        begin
        V_Err(11);
        exit;
        end;
    SeparateClass:= #0;
    writeln(Ini,'[GENERAL]');
    write(Ini,'InvokedMemory= ');
    case V_Param^.Memory of
     Low:  writeln(Ini,'Low');
    High:  writeln(Ini,'High');
    Disk:  writeln(Ini,'Disk');
    else
        writeln(Ini);
        end;
    {$IfDef DPMI} {//ss/08.06.2003 18:24:33//}
    writeln(Ini,'Protected_Mode= on');
    {$Else}
    writeln(Ini,'Protected_Mode= off');
    {$EndIf}
    writeln(Ini,'CycleObj= ',iif(V_Param^.CycleMenu,'on','off'));
    writeln(Ini,'AutoSave= ',iif(V_Param^.AutoSave,'on','off'));
    writeln(Ini,'Tab= ',iif(V_Param^.Tab,'on','off'));
    writeln(Ini,'ExitConfirm= ',iif(V_Param^.ExitConfirm,'on','off'));
    writeln(Ini,'Latin2Russ= ',IIF(V_Param^.Transform_Lat,'on','off'));
    writeln(Ini,'NoStop= ',IIF(V_Param^.NoStop,'on','off'));
    writeln(Ini,'Jump= '+LToS(V_Param^.Jump_1)+','+LToS(V_Param^.Jump_2));
    writeln(Ini,'Exact_Time= ',IIF(V_Param^.Exact_Time,'on','off'));
    writeln(Ini,'Change_Frag= ',IIF(V_Param^.ChFrag,'on','off'));
    writeln(Ini,'ChFrag_File= ',V_Param^.ChFrag_F);
    write(Ini,'Local= ');
    case V_Param^.Local of
       0:  writeln(Ini,'Word');
       1:  writeln(Ini,'Interval');
        end;
    writeln(Ini,'Open_Mask= ',V_Param^.Open_Mask); {//ss/31.03.2003 18:09:44//}
    writeln(Ini, 'Last_Path= ', CF_Path);
    writeln(Ini);

    writeln(Ini,'[INTERFACE]');
    writeln(Ini,'Clock= ',iif(V_Param^.Clock,'on','off'));
    {$IFDEF SV_MOUSE}
    writeln(Ini,'Mouse= ',iif(V_Param^.Mouse,'on','off'));
    {$ELSE}
    writeln(Ini,'Mouse= off');
    {$ENDIF}
    writeln(Ini,'Cursor= ',iif(V_Param^.Cursor,'on','off'));
    writeln(Ini,'PerCent= ',iif(V_Param^.PerCent,'on','off'));
    writeln(Ini,'Coords= ',iif(V_Param^.Coord,'on','off'));
    writeln(Ini,'FreeMemory= ',iif(V_Param^.MemSize,'on','off'));
    writeln(Ini,'Code= ',iif(V_Param^.ShCode,'on','off'));
    writeln(Ini);
    writeln(Ini,'[BOOK-MARK]');
    writeln(Ini,'Global= ',iif(V_Param^.SPBM,'on','off'));
    writeln(Ini,'ShowLine= ',iif(V_Param^.ShowLine,'on','off'));
    writeln(Ini,'Auto_Add= ',iif(V_Param^.Auto_Ext_BMark,'on','off'));
    writeln(Ini);
    writeln(Ini,'[SINTEZIZER]');
    writeln(Ini,'Talk= ',iif(V_Param^.Talk,'on','off'));
    writeln(Ini,'Dictor= ',V_Param^.Dictor);
    writeln(Ini,'VoiceDirectory= ',V_Param^.Dic_Dir);
    writeln(Ini,'Temp= ',V_Param^.Temp);
    writeln(Ini);
    writeln(Ini,'[READING]');
    writeln(Ini,'EmptyLine= ',iif(V_Param^.ReadEmpty,'on','off'));
    writeln(Ini,'Indent= ',iif(V_Param^.ReadIndent,'on','off'));
    writeln(Ini,'FirstWord= '+IIF(V_Param^.ReadWord,'on','off'));
    writeln(Ini,'Line= '+IIF(V_Param^.ReadAllLine,'on','off'));
    writeln(Ini,'ReadSpaceBar= '+IIF(V_Param^.ReadSpace,'on','off'));
    writeln(Ini,'Symbols= ',iif(V_Param^.ReadBySym,'on','off'));
    writeln(Ini,'WinByWin= ',iif(V_Param^.ReadWinByWin,'on','off'));
    writeln(Ini,'Capital= ',iif(V_Param^.Capital,'on','off'));
    writeln(Ini,'AOS= '+LToS(V_Param^.AOS.BSymb)+'-'+LToS(V_Param^.AOS.ESYMB));
    writeln(Ini,'Empty_Delay= '+LToS(V_Param^.Empty_Delay));
    writeln(Ini);
    writeln(Ini,'[SOUND]');
    writeln(Ini,'Status= ',iif(V_Param^.Sound,'on','off'));
    writeln(Ini,'EmptyBell= ',iif(V_Param^.EmptyBell,'on','off'));
    writeln(Ini,'BellOfEnd= ',iif(V_Param^.BOE,'on','off'));
    writeln(Ini,'Separate_Win= ',iif(V_Param^.Sep_Win,'on','off'));
    writeln(Ini,'LoadSound= ',iif(V_Param^.LoadSound,'on','off'));
    writeln(Ini);
    writeln(Ini,'[STARTUP]');
    writeln(Ini,'Indent_Control= ',IIF(V_Param^.Indent_Control,'on','off'));
    writeln(Ini,'DBF_Control= ',IIF(V_Param^.DBF_Control,'on','off'));
    writeln(Ini,'Arc_Control= ',IIF(V_Param^.Arc_Control,'on','off'));
    writeln(Ini,'Html_Control= ',IIF(V_Param^.Htm_Control,'on','off'));
    writeln(Ini,'ShowLink= ',IIF(V_Param^.Html_Link,'on','off'));
    writeln(Ini,'Doc_Control= ',IIF(V_Param^.Doc_Control,'on','off'));
    writeln(Ini,'Word97_StLen= ',V_Param^.Word97_StLen);
    writeln(Ini,'ShowProcess= ',IIF(V_Param^.ShowProcess,'on','off'));
    writeln(Ini,'Old_Posit= ',IIF(V_Param^.Last_Posit,'on','off'));
    writeln(Ini,'AutoDetect_Code= ',iif(V_Param^.AutoDetect_Code,'on','off'));
    writeln(Ini,'Load_Last_Files= ',iif(V_Param^.Load_Last_Files,'on','off')); {//ss/27.03.2003 15:35:16//}
    writeln(Ini,'Open_Dialog= ',iif(V_Param^.Startup_OpenDialog,'on','off')); {//ss/14.04.2003 18:15:11//}
    writeln(Ini,'Read_OnStart= ',iif(V_Param^.Startup_Read_OnStart,'on','off'));

    writeln(Ini);
    writeln(Ini,'[LANGUAGE]');
    write(Ini,'Lat_Language= ');
    case V_Param^.Lat_Language of
 English:  writeln(Ini,'English');
  German:  writeln(Ini,'German');
    else
        writeln(Ini);
        end;
    write(Ini,'Cyr_Language= ');
    case V_Param^.Cyr_Language of
 Russian:   writeln(Ini,'Russian');
Ukrainian:  writeln(Ini,'Ukrainian');
    else
        writeln(Ini);
        end;
    writeln(Ini);
    writeln(Ini,'[OUTLOOK]');
    write(Ini,'Code= ');
    case V_Param^.Mode of
       0:  writeln(Ini,'Normal');
       1:  writeln(Ini,'Windows');
       2:  writeln(Ini,'KOI8');
       3:  writeln(Ini,'utf-8');
       4:  writeln(Ini,'User_Recoding');
    else
        writeln(Ini);
        end;
    writeln(Ini,'User_Decode= ',V_Param^.User_Decode);
    writeln(Ini,'Q_Printable= '+IIF(V_Param^.Printab,'on','off'));
    writeln(Ini);
    writeln(Ini,'[COLORS]');
    with V_Param^.SV_Color do
        begin
        writeln(Ini,'Text= '+C_Name[LTetr(Text)]+'-'+C_Name[HTetr(Text)]);
        writeln(Ini,'Title= '+C_Name[LTetr(Title)]+'-'+C_Name[HTetr(Title)]);
        writeln(Ini,'Message= '+C_Name[LTetr(Message)]+'-'+C_Name[HTetr(Message)]);
        writeln(Ini,'Frame= '+C_Name[LTetr(Frame)]+'-'+C_Name[HTetr(Frame)]);
        writeln(Ini,'Time= '+C_Name[LTetr(Time)]+'-'+C_Name[HTetr(Time)]);
        writeln(Ini,'Mark= '+C_Name[LTetr(Marked)]+'-'+C_Name[HTetr(Marked)]);
        with Menu do
            begin
            writeln(Ini,'Menu.ActItem= '+C_Name[LTetr(ActItem)]+'-'+C_Name[HTetr(ActItem)]);
            writeln(Ini,'Menu.NoactItem= '+C_Name[LTetr(DeactItem)]+'-'+C_Name[HTetr(DeactItem)]);
            writeln(Ini,'Menu.Frame= '+C_Name[LTetr(Frame)]+'-'+C_Name[HTetr(Frame)]);
            writeln(Ini,'Menu.Title= '+C_Name[LTetr(Title)]+'-'+C_Name[HTetr(Title)]);
            end;
        {
        with Button do
            begin
            writeln(Ini,'Button.Line= '+C_Name[LTetr(Line)]+'-'+C_Name[HTetr(Line)]);
            writeln(Ini,'Button.Act= '+C_Name[LTetr(ActBut)]+'-'+C_Name[HTetr(ActBut)]);
            writeln(Ini,'Button.Noact= '+C_Name[LTetr(DeactBut)]+'-'+C_Name[HTetr(DeactBut)]);
            writeln(Ini,'Button.Frame= '+C_Name[LTetr(Frame)]+'-'+C_Name[HTetr(Frame)]);
            end;
        }
        end;
    {//ss/27.03.2003 15:35:53//}
    writeln(Ini);
    writeln(Ini, '[LAST-FILES]');
    for i:=System.Low(V_Param^.Last_Files) to System.High(V_Param^.Last_Files) do begin
      str(i, s);
      writeln(Ini, 'File', s, '=', V_Param^.Last_Files[i]);
    end;
    close(Ini);
    SeparateClass:= Sep_C;
    end;


function BoolParam(var Buf: String; const Name: String; var BoolVar: Boolean; Default: Boolean): Boolean;
{//ss/27.03.2003 15:38:41//}
begin
  if Upper(Left(Buf,Length(Name))) = Name then
  begin
    BoolParam:=True;
    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
    if Buf= 'ON' then
      BoolVar:= true
    else  if Buf= 'OFF' then
      BoolVar:= false
    else
      BoolVar:=Default;
  end else
    BoolParam:=False;
end;

function FileStrParam(var Buf: String; const Name: String; var StrVar: String; const Default: String): Boolean;
{//ss/27.03.2003 15:38:47//}
begin
  if Upper(Left(Buf,Length(Name))) = Name then
  begin
    FileStrParam:=True;
    Buf:= Trim(Right(Buf,length(Buf)-pos('=',Buf)));
    if Buf[length(Buf)]= '\' then
        Buf:= Left(Buf,Length(Buf)-1);
    if File_Exists(Buf) then
      begin
        StrVar:= Buf;
      end else StrVar:=Default;
  end else
    FileStrParam:=False;
end;

function StrParam(var Buf: String; const Name: String; var StrVar: String): Boolean;
{//ss/31.03.2003 18:06:27//}
begin
  if Upper(Left(Buf,Length(Name))) = Name then
  begin
    StrParam:=True;
    Buf:= Trim(Right(Buf,length(Buf)-pos('=',Buf)));
    if Buf[length(Buf)]= '\' then
        Buf:= Left(Buf,Length(Buf)-1);
    StrVar:= Buf;
  end else
    StrParam:=False;
end;

procedure RParam;
    label
        EndProc;

    var
        Cfg:            tCfgFile;
        Ini:            text;
        NormBuf:        string;
        Buf:            string;
        BufNum:         longint;
        Code:           integer;
        BN1:            byte;
        BN2:            byte;
        S1:             string[14];
        S2:             string[14];
        pm: Boolean; {//ss/08.06.2003 18:25:08//}
    begin
    Clr;
    ShowScr;
    Set_Default_Param;
    Set_Viewer_Param;
    DrawTime:= 0;
    assign(Cfg,MyDirc+CfgFile);
    assign(Ini,MyDirc+IniFile);
    IORes:= ioresult;
    reset(Cfg);
    if ioresult<> 0 then begin
        {//ss/21.04.2003 15:50:46//}
        FillChar(V_Param^.Config, SizeOf(V_Param^.Config), 0);
        V_Err(12)
    end
    else
        begin
        read(Cfg,V_Param^.Config);
        if ioresult<> 0 then
            V_Err(13);
        end;
    close(Cfg);
    IORes:= ioresult;
    reset(Ini);
    if ioresult<> 0 then
        begin
        V_Err(14);
        goto EndProc;
        end {if ioresult<> 0};
    while not eof(Ini) do
        begin
        readln(Ini,Buf);
        NormBuf:=Trim(Buf);
        Buf:= Upper(NormBuf);
        if Empty(Buf) then continue;
        if Buf[1]= IniComm then continue;
        if Buf= '[GENERAL]' then
            while not eof(Ini) do
                begin
                readln(Ini,Buf);
                NormBuf:=Trim(Buf);
                Buf:=Upper(NormBuf);
                if Empty(Buf) then continue;
                if Buf[1]= IniComm then continue;
                if Buf[1]= '[' then break;
                if StrParam(NormBuf, 'OPEN_MASK', V_Param^.Open_Mask) {//ss/31.03.2003 18:09:55//}
                or StrParam(NormBuf, 'LAST_PATH', CF_Path)
                or BoolParam(Buf, 'PROTECTED_MODE', pm, False) {//ss/08.06.2003 18:24:45//}
                then Continue
                else
                if Left(Buf,13)= 'INVOKEDMEMORY' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    if Buf= 'LOW' then
                        begin
                        V_Param^.Memory:= mem.Low;
                        continue;
                        end;
                    if Buf= 'HIGH' then
                        begin
                        V_Param^.Memory:= mem.High;
                        continue;
                        end;
                    if Buf= 'DISK' then
                        begin
                        V_Param^.Memory:= mem.Disk;
                        continue;
                        end;
                    end;
                if Left(Buf,8)= 'CYCLEOBJ' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    if Buf= 'ON' then
                        begin
                        V_Param^.CycleMenu:= true;
                        continue;
                        end;
                    if Buf= 'OFF' then
                        begin
                        V_Param^.CycleMenu:= false;
                        continue;
                        end;
                    end;
                if Left(Buf,8)= 'AUTOSAVE' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    if Buf= 'ON' then
                        begin
                        V_Param^.AutoSave:= true;
                        continue;
                        end;
                    if Buf= 'OFF' then
                        begin
                        V_Param^.AutoSave:= false;
                        continue;
                        end;
                    end;
                if Left(Buf,3)= 'TAB' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    if Buf= 'ON' then
                        begin
                        V_Param^.Tab:= true;
                        continue;
                        end;
                    if Buf= 'OFF' then
                        begin
                        V_Param^.Tab:= false;
                        continue;
                        end;
                    end;
                if Left(Buf,11)= 'EXITCONFIRM' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    if Buf= 'ON' then
                        begin
                        V_Param^.ExitConfirm:= true;
                        continue;
                        end;
                    if Buf= 'OFF' then
                        begin
                        V_Param^.ExitConfirm:= false;
                        continue;
                        end;
                    end;
                if Left(Buf,10)= 'LATIN2RUSS' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    if Buf= 'ON' then
                        begin
                        V_Param^.Transform_Lat:= true;
                        continue;
                        end;
                    if Buf= 'OFF' then
                        begin
                        V_Param^.Transform_Lat:= false;
                        continue;
                        end;
                    end;
                if Left(Buf,6)= 'NOSTOP' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    if Buf= 'ON' then
                        begin
                        V_Param^.NoStop:= true;
                        continue;
                        end;
                    if Buf= 'OFF' then
                        begin
                        V_Param^.NoStop:= false;
                        continue;
                        end;
                    end;
                if Left(Buf,4)= 'JUMP' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    S1:= Left(Buf,pos(',',Buf)-1);
                    val(S1,BufNum,Code);
                    if Code= 0 then
                        begin
                        if BufNum< 0 then BufNum:= 0;
                        V_Param^.Jump_1:= BufNum;
                        S2:= Right(Buf,length(Buf)-pos(',',Buf));
                        val(S2,BufNum,Code);
                        if Code= 0 then
                            begin
                            if BufNum< 0 then BufNum:= 0;
                            V_Param^.Jump_2:= BufNum;
                            continue;
                            end;
                        end;
                    end;
                if Left(Buf,10)= 'EXACT_TIME' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    if Buf= 'ON' then
                        begin
                        V_Param^.Exact_Time:= true;
                        continue;
                        end;
                    if Buf= 'OFF' then
                        begin
                        V_Param^.Exact_Time:= false;
                        continue;
                        end;
                    end;
                if Left(Buf,11)= 'CHANGE_FRAG' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    if Buf= 'ON' then
                        begin
                        V_Param^.ChFrag:= true;
                        continue;
                        end;
                    if Buf= 'OFF' then
                        begin
                        V_Param^.ChFrag:= false;
                        continue;
                        end;
                    end;
                if Left(Buf,11)= 'CHFRAG_FILE' then
                    begin
                    Buf:= Trim(Right(Buf,length(Buf)-pos('=',Buf)));
                    if Empty(Buf) then
                        begin
                        V_Param^.ChFrag_F:= '';
                        continue;
                        end;
                    if File_Exists(Buf) then
                        begin
                        V_Param^.ChFrag_F:= Buf;
                        continue;
                        end;
                    end;
                if Left(Buf,5)= 'LOCAL' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    if Buf= 'WORD' then
                        begin
                        V_Param^.Local:= 0;
                        continue;
                        end;
                    if Buf= 'INTERVAL' then
                        begin
                        V_Param^.Local:= 1;
                        continue;
                        end;
                    end;
                V_Err(15);
                end;
        if Buf= '[INTERFACE]' then
            while not eof(Ini) do
                begin
                readln(Ini,Buf);
                NormBuf:=Trim(Buf);
                Buf:=Upper(NormBuf);
                if Empty(Buf) then continue;
                if Buf[1]= IniComm then continue;
                if Buf[1]= '[' then break;
                if Left(Buf,5)= 'CLOCK' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    if Buf= 'ON' then
                        begin
                        V_Param^.Clock:= true;
                        continue;
                        end;
                    if Buf= 'OFF' then
                        begin
                        V_Param^.Clock:= false;
                        continue;
                        end;
                    end;
                if Left(Buf,5)= 'MOUSE' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    if Buf= 'ON' then
                        begin
                        V_Param^.Mouse:= true;
                        continue;
                        end;
                    if Buf= 'OFF' then
                        begin
                        V_Param^.Mouse:= false;
                        continue;
                        end;
                    end;
                if Left(Buf,6)= 'CURSOR' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    if Buf= 'ON' then
                        begin
                        V_Param^.Cursor:= true;
                        continue;
                        end;
                    if Buf= 'OFF' then
                        begin
                        V_Param^.Cursor:= false;
                        continue;
                        end;
                    end;
                if Left(Buf,7)= 'PERCENT' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    if Buf= 'ON' then
                        begin
                        V_Param^.PerCent:= true;
                        continue;
                        end;
                    if Buf= 'OFF' then
                        begin
                        V_Param^.PerCent:= false;
                        continue;
                        end;
                    end;
                if Left(Buf,6)= 'COORDS' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    if Buf= 'ON' then
                        begin
                        V_Param^.Coord:= true;
                        continue;
                        end;
                    if Buf= 'OFF' then
                        begin
                        V_Param^.Coord:= false;
                        continue;
                        end;
                    end;
                if Left(Buf,10)= 'FREEMEMORY' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    if Buf= 'ON' then
                        begin
                        V_Param^.MemSize:= true;
                        continue;
                        end;
                    if Buf= 'OFF' then
                        begin
                        V_Param^.MemSize:= false;
                        continue;
                        end;
                    end;
                if Left(Buf,4)= 'CODE' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    if Buf= 'ON' then
                        begin
                        V_Param^.ShCode:= true;
                        continue;
                        end;
                    if Buf= 'OFF' then
                        begin
                        V_Param^.ShCode:= false;
                        continue;
                        end;
                    end;
                V_Err(16);
                end;
        if Buf= '[BOOK-MARK]' then
            while not eof(Ini) do
                begin
                readln(Ini,Buf);
                NormBuf:=Trim(Buf);
                Buf:=Upper(NormBuf);
                if Empty(Buf) then continue;
                if Buf[1]= IniComm then continue;
                if Buf[1]= '[' then break;
                if Left(Buf,6)= 'GLOBAL' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    if Buf= 'ON' then
                        begin
                        V_Param^.SPBM:= true;
                        continue;
                        end;
                    if Buf= 'OFF' then
                        begin
                        V_Param^.SPBM:= false;
                        continue;
                        end;
                    end;
                if Left(Buf,8)= 'SHOWLINE' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    if Buf= 'ON' then
                        begin
                        V_Param^.ShowLine:= true;
                        continue;
                        end;
                    if Buf= 'OFF' then
                        begin
                        V_Param^.ShowLine:= false;
                        continue;
                        end;
                    end;
                if Left(Buf,8)= 'AUTO_ADD' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    if Buf= 'ON' then
                        begin
                        V_Param^.Auto_Ext_BMark:= true;
                        continue;
                        end;
                    if Buf= 'OFF' then
                        begin
                        V_Param^.Auto_Ext_BMark:= false;
                        continue;
                        end;
                    end;
                V_Err(17);
                end;
        if Buf= '[SINTEZIZER]' then
            while not eof(Ini) do
                begin
                readln(Ini,Buf);
                NormBuf:=Trim(Buf);
                Buf:=Upper(NormBuf);
                if Empty(Buf) then continue;
                if Buf[1]= IniComm then continue;
                if Buf[1]= '[' then break;
                if Left(Buf,4)= 'TALK' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    if Buf= 'ON' then
                        begin
                        V_Param^.Talk:= true;
                        continue;
                        end;
                    if Buf= 'OFF' then
                        begin
                        V_Param^.Talk:= false;
                        continue;
                        end;
                    end;
                if Left(Buf,6)= 'DICTOR' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    val(Buf,BufNum,Code);
                    if (Code= 0) and (BufNum in [0..3]) then
                        begin
                        V_Param^.Dictor:= BufNum;
                        continue;
                        end;
                    end;
                if Left(Buf,14)= 'VOICEDIRECTORY' then
                    begin
                    Buf:= Trim(Right(NormBuf,length(NormBuf)-pos('=',NormBuf)));
                    if Buf[length(Buf)]= '\' then
                        Buf:= Left(Buf,length(Buf)-1);
                    if Directory_Exists(Buf) then
                        begin
                        V_Param^.Dic_Dir:= Buf;
                        continue;
                        end;
                    end;
                if Left(Buf,4)= 'TEMP' then
                    begin
                    Buf:= Trim(Right(Buf,length(Buf)-pos('=',Buf)));
                    val(Buf,BufNum,Code);
                    if (Code= 0) and (BufNum in [0..150]) then
                        begin
                        V_Param^.Temp:= BufNum;
                        continue;
                        end;
                    end;
                V_Err(18);
                end;
        if Buf= '[READING]' then
            while not eof(Ini) do
                begin
                readln(Ini,Buf);
                NormBuf:=Trim(Buf);
                Buf:=Upper(NormBuf);
                if Empty(Buf) then continue;
                if Buf[1]= IniComm then continue;
                if Buf[1]= '[' then break;
                if Left(Buf,9)= 'EMPTYLINE' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    if Buf= 'ON' then
                        begin
                        V_Param^.ReadEmpty:= true;
                        continue;
                        end;
                    if Buf= 'OFF' then
                        begin
                        V_Param^.ReadEmpty:= false;
                        continue;
                        end;
                    end;
                if Left(Buf,6)= 'INDENT' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    if Buf= 'ON' then
                        begin
                        V_Param^.ReadIndent:= true;
                        continue;
                        end;
                    if Buf= 'OFF' then
                        begin
                        V_Param^.ReadIndent:= false;
                        continue;
                        end;
                    end;
                if Left(Buf,9)= 'FIRSTWORD' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    if Buf= 'ON' then
                        begin
                        V_Param^.ReadWord:= true;
                        continue;
                        end;
                    if Buf= 'OFF' then
                        begin
                        V_Param^.ReadWord:= false;
                        continue;
                        end;
                    end;
                if Left(Buf,4)= 'LINE' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    if Buf= 'ON' then
                        begin
                        V_Param^.ReadAllLine:= true;
                        continue;
                        end;
                    if Buf= 'OFF' then
                        begin
                        V_Param^.ReadAllLine:= false;
                        continue;
                        end;
                    end;
                if Left(Buf,12)= 'READSPACEBAR' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    if Buf= 'ON' then
                        begin
                        V_Param^.ReadSpace:= true;
                        continue;
                        end;
                    if Buf= 'OFF' then
                        begin
                        V_Param^.ReadSpace:= false;
                        continue;
                        end;
                    end;
                if Left(Buf,7)= 'SYMBOLS' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    if Buf= 'ON' then
                        begin
                        V_Param^.ReadBySym:= true;
                        continue;
                        end;
                    if Buf= 'OFF' then
                        begin
                        V_Param^.ReadBySym:= false;
                        continue;
                        end;
                    end;
                if Left(Buf,8)= 'WINBYWIN' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    if Buf= 'ON' then
                        begin
                        V_Param^.ReadWinByWin:= true;
                        continue;
                        end;
                    if Buf= 'OFF' then
                        begin
                        V_Param^.ReadWinByWin:= false;
                        continue;
                        end;
                    end;
                if Left(Buf,7)= 'CAPITAL' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    if Buf= 'ON' then
                        begin
                        V_Param^.Capital:= true;
                        continue;
                        end;
                    if Buf= 'OFF' then
                        begin
                        V_Param^.Capital:= false;
                        continue;
                        end;
                    end;
                if Left(Buf,3)= 'AOS' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    val(Left(Buf,pos('-',Buf)-1),BN1,Code);
                    if Code= 0 then
                        begin
                        val(Right(Buf,length(Buf)-pos('-',Buf)),BN2,Code);
                        if Code= 0 then
                            if BN2>= BN1 then
                                begin
                                V_Param^.AOS.BSymb:= BN1;
                                V_Param^.AOS.ESymb:= BN2;
                                continue;
                                end;
                        end;
                    end;
                if Left(Buf,11)= 'EMPTY_DELAY' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    val(Buf,BufNum,Code);
                    if Code= 0 then
                        begin
                        V_Param^.Empty_Delay:= BufNum;
                        continue;
                        end;
                    end;
                V_Err(19);
                end;
        if Buf= '[SOUND]' then
            while not eof(Ini) do
                begin
                readln(Ini,Buf);
                NormBuf:=Trim(Buf);
                Buf:=Upper(NormBuf);
                if Empty(Buf) then continue;
                if Buf[1]= IniComm then continue;
                if Buf[1]= '[' then break;
                if Left(Buf,6)= 'STATUS' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    if Buf= 'ON' then
                        begin
                        V_Param^.Sound:= true;
                        continue;
                        end;
                    if Buf= 'OFF' then
                        begin
                        V_Param^.Sound:= false;
                        continue;
                        end;
                    end;
                if Left(Buf,9)= 'EMPTYBELL' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    if Buf= 'ON' then
                        begin
                        V_Param^.EmptyBell:= true;
                        continue;
                        end;
                    if Buf= 'OFF' then
                        begin
                        V_Param^.EmptyBell:= false;
                        continue;
                        end;
                    end;
                if Left(Buf,9)= 'BELLOFEND' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    if Buf= 'ON' then
                        begin
                        V_Param^.BOE:= true;
                        continue;
                        end;
                    if Buf= 'OFF' then
                        begin
                        V_Param^.BOE:= false;
                        continue;
                        end;
                    end;
                if Left(Buf,12)= 'SEPARATE_WIN' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    if Buf= 'ON' then
                        begin
                        V_Param^.Sep_Win:= true;
                        continue;
                        end;
                    if Buf= 'OFF' then
                        begin
                        V_Param^.Sep_Win:= false;
                        continue;
                        end;
                    end;
                if Left(Buf,9)= 'LOADSOUND' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    if Buf= 'ON' then
                        begin
                        V_Param^.LoadSound:= true;
                        continue;
                        end;
                    if Buf= 'OFF' then
                        begin
                        V_Param^.LoadSound:= false;
                        continue;
                        end;
                    end;
                V_Err(20);
                end;
        if Buf= '[STARTUP]' then
            while not eof(Ini) do
                begin
                readln(Ini,Buf);
                NormBuf:=Trim(Buf);
                Buf:=Upper(NormBuf);
                if Empty(Buf) then continue;
                if Buf[1]= IniComm then continue;
                if Buf[1]= '[' then break;
                {//ss/27.03.2003 15:39:44//}
                if BoolParam(Buf, 'LOAD_LAST_FILES', V_Param^.Load_Last_Files, False)
                {//ss/14.04.2003 18:08:40//}
                or BoolParam(Buf, 'OPEN_DIALOG', V_Param^.Startup_OpenDialog, False)
                or BoolParam(Buf, 'READ_ONSTART', V_Param^.Startup_Read_OnStart, False)
                {or BoolParam(Buf, 'INDENT_CONTROL', V_Param^.Indent_Control, False)}
                then Continue;
                if Left(Buf,14)= 'INDENT_CONTROL' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    if Buf= 'ON' then
                        begin
                        V_Param^.Indent_Control:= true;
                        continue;
                        end;
                    if Buf= 'OFF' then
                        begin
                        V_Param^.Indent_Control:= false;
                        continue;
                        end;
                    end;
                if Left(Buf,11)= 'DBF_CONTROL' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    if Buf= 'ON' then
                        begin
                        V_Param^.DBF_Control:= true;
                        continue;
                        end;
                    if Buf= 'OFF' then
                        begin
                        V_Param^.DBF_Control:= false;
                        continue;
                        end;
                    end;
                if Left(Buf,11)= 'ARC_CONTROL' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    if Buf= 'ON' then
                        begin
                        V_Param^.Arc_Control:= true;
                        continue;
                        end;
                    if Buf= 'OFF' then
                        begin
                        V_Param^.Arc_Control:= false;
                        continue;
                        end;
                    end;
                if Left(Buf,12)= 'HTML_CONTROL' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    if Buf= 'ON' then
                        begin
                        V_Param^.Htm_Control:= true;
                        continue;
                        end;
                    if Buf= 'OFF' then
                        begin
                        V_Param^.Htm_Control:= false;
                        continue;
                        end;
                    end;
                if Left(Buf,8)= 'SHOWLINK' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    if Buf= 'ON' then
                        begin
                        V_Param^.Html_Link:= true;
                        continue;
                        end;
                    if Buf= 'OFF' then
                        begin
                        V_Param^.Html_Link:= false;
                        continue;
                        end;
                    end;
                if Left(Buf,11)= 'DOC_CONTROL' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    if Buf= 'ON' then
                        begin
                        V_Param^.Doc_Control:= true;
                        continue;
                        end;
                    if Buf= 'OFF' then
                        begin
                        V_Param^.Doc_Control:= false;
                        continue;
                        end;
                    end;
                if Left(Buf,12)= 'WORD97_STLEN' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    val(Buf,BufNum,Code);
                    if (Code= 0) and (BufNum in [24..250]) then
                        begin
                        V_Param^.Word97_StLen:= BufNum;
                        continue;
                        end;
                    end;
                if Left(Buf,11)= 'SHOWPROCESS' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    if Buf= 'ON' then
                        begin
                        V_Param^.ShowProcess:= true;
                        continue;
                        end;
                    if Buf= 'OFF' then
                        begin
                        V_Param^.ShowProcess:= false;
                        continue;
                        end;
                    end;
                if Left(Buf,9)= 'OLD_POSIT' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    if Buf= 'ON' then
                        begin
                        V_Param^.Last_Posit:= true;
                        continue;
                        end;
                    if Buf= 'OFF' then
                        begin
                        V_Param^.Last_Posit:= false;
                        continue;
                        end;
                    end;
                if Left(Buf,15)= 'AUTODETECT_CODE' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    if Buf= 'ON' then
                        begin
                        V_Param^.AutoDetect_Code:= true;
                        continue;
                        end;
                    if Buf= 'OFF' then
                        begin
                        V_Param^.AutoDetect_Code:= false;
                        continue;
                        end;
                    end;
                V_Err(23);
                end;
        if Buf= '[LANGUAGE]' then
            while not eof(Ini) do
                begin
                readln(Ini,Buf);
                NormBuf:=Trim(Buf);
                Buf:=Upper(NormBuf);
                if Empty(Buf) then continue;
                if Buf[1]= IniComm then continue;
                if Buf[1]= '[' then break;
                if Left(Buf,12)= 'LAT_LANGUAGE' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    if Buf= 'ENGLISH' then
                        begin
                        V_Param^.Lat_Language:= English;
                        continue;
                        end;
                    if Buf= 'GERMAN' then
                        begin
                        V_Param^.Lat_Language:= German;
                        continue;
                        end;
                    end;
                if Left(Buf,12)= 'CYR_LANGUAGE' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    if Buf= 'RUSSIAN' then
                        begin
                        V_Param^.Cyr_Language:= Russian;
                        continue;
                        end;
                    if Buf= 'UKRAINIAN' then
                        begin
                        V_Param^.Cyr_Language:= Ukrainian;
                        continue;
                        end;
                    end;
                V_Err(32);
                end;
        if Buf= '[OUTLOOK]' then
            while not eof(Ini) do
                begin
                readln(Ini,Buf);
                NormBuf:=Trim(Buf);
                Buf:=Upper(NormBuf);
                if Empty(Buf) then continue;
                if Buf[1]= IniComm then continue;
                if Buf[1]= '[' then break;
                if Left(Buf,4)= 'CODE' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    if Buf= 'NORMAL' then
                        begin
                        V_Param^.Mode:= 0;
                        continue;
                        end;
                    if Buf= 'WINDOWS' then
                        begin
                        V_Param^.Mode:= 1;
                        continue;
                        end;
                    if Buf= 'KOI8' then
                        begin
                        V_Param^.Mode:= 2;
                        continue;
                        end;
                    if Buf= 'UTF-8' then
                        begin
                        V_Param^.Mode:= 3;
                        continue;
                        end;
                    if Buf= 'USER_RECODING' then
                        begin
                        V_Param^.Mode:= 4;
                        continue;
                        end;
                    end;
                if Left(Buf,11)= 'USER_DECODE' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    if Empty(Buf) then
                        begin
                        V_Param^.User_Decode:= '';
                        continue;
                        end;
                    if File_Exists(Buf) then
                        begin
                        V_Param^.User_Decode:= Buf;
                        continue;
                        end;
                    end;
                if Left(Buf,11)= 'Q_PRINTABLE' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    if Buf= 'ON' then
                        begin
                        V_Param^.Printab:= true;
                        continue;
                        end;
                    if Buf= 'OFF' then
                        begin
                        V_Param^.Printab:= false;
                        continue;
                        end;
                    end;
                V_Err(24);
                end;
        if Buf= '[COLORS]' then
            while not eof(Ini) do
                begin
                readln(Ini,Buf);
                NormBuf:=Trim(Buf);
                Buf:=Upper(NormBuf);
                if Empty(Buf) then continue;
                if Buf[1]= IniComm then continue;
                if Buf[1]= '[' then break;
                if Left(Buf,4)= 'TEXT' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    for BufNum:= 0 to $F+1 do
                        begin
                        if BufNum= $F+1 then break;
                        if Upper(C_Name[BufNum])= Trim(Right(Buf,length(Buf)-pos('-',Buf))) then
                            begin
                            BN1:= BufNum;
                            break;
                            end;
                        end;
                    for BufNum:= 0 to $F+1 do
                        begin
                        if BufNum= $F+1 then break;
                        if Upper(C_Name[BufNum])= Trim(Left(Buf,pos('-',Buf)-1)) then
                            begin
                            BN2:= BufNum;
                            break;
                            end;
                        end;
                    if BufNum< $F+1 then
                        begin
                        V_Param^.SV_Color.Text:= Paste_Tetrads(BN2,BN1);
                        continue;
                        end;
                    end;
                if Left(Buf,5)= 'TITLE' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    for BufNum:= 0 to $F+1 do
                        begin
                        if BufNum= $F+1 then break;
                        if Upper(C_Name[BufNum])= Trim(Right(Buf,length(Buf)-pos('-',Buf))) then
                            begin
                            BN1:= BufNum;
                            break;
                            end;
                        end;
                    for BufNum:= 0 to $F+1 do
                        begin
                        if BufNum= $F+1 then break;
                        if Upper(C_Name[BufNum])= Trim(Left(Buf,pos('-',Buf)-1)) then
                            begin
                            BN2:= BufNum;
                            break;
                            end;
                        end;
                    if BufNum< $F+1 then
                        begin
                        V_Param^.SV_Color.Title:= Paste_Tetrads(BN2,BN1);
                        continue;
                        end;
                    end;
                if Left(Buf,7)= 'MESSAGE' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    for BufNum:= 0 to $F+1 do
                        begin
                        if BufNum= $F+1 then break;
                        if Upper(C_Name[BufNum])= Trim(Right(Buf,length(Buf)-pos('-',Buf))) then
                            begin
                            BN1:= BufNum;
                            break;
                            end;
                        end;
                    for BufNum:= 0 to $F+1 do
                        begin
                        if BufNum= $F+1 then break;
                        if Upper(C_Name[BufNum])= Trim(Left(Buf,pos('-',Buf)-1)) then
                            begin
                            BN2:= BufNum;
                            break;
                            end;
                        end;
                    if BufNum< $F+1 then
                        begin
                        V_Param^.SV_Color.Message:= Paste_Tetrads(BN2,BN1);
                        continue;
                        end;
                    end;
                if Left(Buf,5)= 'FRAME' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    for BufNum:= 0 to $F+1 do
                        begin
                        if BufNum= $F+1 then break;
                        if Upper(C_Name[BufNum])= Trim(Right(Buf,length(Buf)-pos('-',Buf))) then
                            begin
                            BN1:= BufNum;
                            break;
                            end;
                        end;
                    for BufNum:= 0 to $F+1 do
                        begin
                        if BufNum= $F+1 then break;
                        if Upper(C_Name[BufNum])= Trim(Left(Buf,pos('-',Buf)-1)) then
                            begin
                            BN2:= BufNum;
                            break;
                            end;
                        end;
                    if BufNum< $F+1 then
                        begin
                        V_Param^.SV_Color.Frame:= Paste_Tetrads(BN2,BN1);
                        continue;
                        end;
                    end;
                if Left(Buf,4)= 'TIME' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    for BufNum:= 0 to $F+1 do
                        begin
                        if BufNum= $F+1 then break;
                        if Upper(C_Name[BufNum])= Trim(Right(Buf,length(Buf)-pos('-',Buf))) then
                            begin
                            BN1:= BufNum;
                            break;
                            end;
                        end;
                    for BufNum:= 0 to $F+1 do
                        begin
                        if BufNum= $F+1 then break;
                        if Upper(C_Name[BufNum])= Trim(Left(Buf,pos('-',Buf)-1)) then
                            begin
                            BN2:= BufNum;
                            break;
                            end;
                        end;
                    if BufNum< $F+1 then
                        begin
                        V_Param^.SV_Color.Time:= Paste_Tetrads(BN2,BN1);
                        continue;
                        end;
                    end;
                if Left(Buf,4)= 'MARK' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    for BufNum:= 0 to $F+1 do
                        begin
                        if BufNum= $F+1 then break;
                        if Upper(C_Name[BufNum])= Trim(Right(Buf,length(Buf)-pos('-',Buf))) then
                            begin
                            BN1:= BufNum;
                            break;
                            end;
                        end;
                    for BufNum:= 0 to $F+1 do
                        begin
                        if BufNum= $F+1 then break;
                        if Upper(C_Name[BufNum])= Trim(Left(Buf,pos('-',Buf)-1)) then
                            begin
                            BN2:= BufNum;
                            break;
                            end;
                        end;
                    if BufNum< $F+1 then
                        begin
                        V_Param^.SV_Color.Marked:= Paste_Tetrads(BN2,BN1);
                        continue;
                        end;
                    end;
                if Left(Buf,12)= 'MENU.ACTITEM' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    for BufNum:= 0 to $F+1 do
                        begin
                        if BufNum= $F+1 then break;
                        if Upper(C_Name[BufNum])= Trim(Right(Buf,length(Buf)-pos('-',Buf))) then
                            begin
                            BN1:= BufNum;
                            break;
                            end;
                        end;
                    for BufNum:= 0 to $F+1 do
                        begin
                        if BufNum= $F+1 then break;
                        if Upper(C_Name[BufNum])= Trim(Left(Buf,pos('-',Buf)-1)) then
                            begin
                            BN2:= BufNum;
                            break;
                            end;
                        end;
                    if BufNum< $F+1 then
                        begin
                        V_Param^.SV_Color.Menu.ActItem:= Paste_Tetrads(BN2,BN1);
                        continue;
                        end;
                    end;
                if Left(Buf,14)= 'MENU.NOACTITEM' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    for BufNum:= 0 to $F+1 do
                        begin
                        if BufNum= $F+1 then break;
                        if Upper(C_Name[BufNum])= Trim(Right(Buf,length(Buf)-pos('-',Buf))) then
                            begin
                            BN1:= BufNum;
                            break;
                            end;
                        end;
                    for BufNum:= 0 to $F+1 do
                        begin
                        if BufNum= $F+1 then break;
                        if Upper(C_Name[BufNum])= Trim(Left(Buf,pos('-',Buf)-1)) then
                            begin
                            BN2:= BufNum;
                            break;
                            end;
                        end;
                    if BufNum< $F+1 then
                        begin
                        V_Param^.SV_Color.Menu.DeactItem:= Paste_Tetrads(BN2,BN1);
                        continue;
                        end;
                    end;
                if Left(Buf,10)= 'MENU.FRAME' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    for BufNum:= 0 to $F+1 do
                        begin
                        if BufNum= $F+1 then break;
                        if Upper(C_Name[BufNum])= Trim(Right(Buf,length(Buf)-pos('-',Buf))) then
                            begin
                            BN1:= BufNum;
                            break;
                            end;
                        end;
                    for BufNum:= 0 to $F+1 do
                        begin
                        if BufNum= $F+1 then break;
                        if Upper(C_Name[BufNum])= Trim(Left(Buf,pos('-',Buf)-1)) then
                            begin
                            BN2:= BufNum;
                            break;
                            end;
                        end;
                    if BufNum< $F+1 then
                        begin
                        V_Param^.SV_Color.Menu.Frame:= Paste_Tetrads(BN2,BN1);
                        continue;
                        end;
                    end;
                if Left(Buf,10)= 'MENU.TITLE' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    for BufNum:= 0 to $F+1 do
                        begin
                        if BufNum= $F+1 then break;
                        if Upper(C_Name[BufNum])= Trim(Right(Buf,length(Buf)-pos('-',Buf))) then
                            begin
                            BN1:= BufNum;
                            break;
                            end;
                        end;
                    for BufNum:= 0 to $F+1 do
                        begin
                        if BufNum= $F+1 then break;
                        if Upper(C_Name[BufNum])= Trim(Left(Buf,pos('-',Buf)-1)) then
                            begin
                            BN2:= BufNum;
                            break;
                            end;
                        end;
                    if BufNum< $F+1 then
                        begin
                        V_Param^.SV_Color.Menu.Title:= Paste_Tetrads(BN2,BN1);
                        continue;
                        end;
                    end;
                {
                if Left(Buf,11)= 'BUTTON.LINE' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    for BufNum:= 0 to $F+1 do
                        begin
                        if BufNum= $F+1 then break;
                        if Upper(C_Name[BufNum])= Trim(Right(Buf,length(Buf)-pos('-',Buf))) then
                            begin
                            BN1:= BufNum;
                            break;
                            end;
                        end;
                    for BufNum:= 0 to $F+1 do
                        begin
                        if BufNum= $F+1 then break;
                        if Upper(C_Name[BufNum])= Trim(Left(Buf,pos('-',Buf)-1)) then
                            begin
                            BN2:= BufNum;
                            break;
                            end;
                        end;
                    if BufNum< $F+1 then
                        begin
                        V_Param^.SV_Color.Button.Line:= Paste_Tetrads(BN2,BN1);
                        continue;
                        end;
                    end;
                if Left(Buf,10)= 'BUTTON.ACT' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    for BufNum:= 0 to $F+1 do
                        begin
                        if BufNum= $F+1 then break;
                        if Upper(C_Name[BufNum])= Trim(Right(Buf,length(Buf)-pos('-',Buf))) then
                            begin
                            BN1:= BufNum;
                            break;
                            end;
                        end;
                    for BufNum:= 0 to $F+1 do
                        begin
                        if BufNum= $F+1 then break;
                        if Upper(C_Name[BufNum])= Trim(Left(Buf,pos('-',Buf)-1)) then
                            begin
                            BN2:= BufNum;
                            break;
                            end;
                        end;
                    if BufNum< $F+1 then
                        begin
                        V_Param^.SV_Color.Button.ActBut:= Paste_Tetrads(BN2,BN1);
                        continue;
                        end;
                    end;
                if Left(Buf,12)= 'BUTTON.NOACT' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    for BufNum:= 0 to $F+1 do
                        begin
                        if BufNum= $F+1 then break;
                        if Upper(C_Name[BufNum])= Trim(Right(Buf,length(Buf)-pos('-',Buf))) then
                            begin
                            BN1:= BufNum;
                            break;
                            end;
                        end;
                    for BufNum:= 0 to $F+1 do
                        begin
                        if BufNum= $F+1 then break;
                        if Upper(C_Name[BufNum])= Trim(Left(Buf,pos('-',Buf)-1)) then
                            begin
                            BN2:= BufNum;
                            break;
                            end;
                        end;
                    if BufNum< $F+1 then
                        begin
                        V_Param^.SV_Color.Button.DeactBut:= Paste_Tetrads(BN2,BN1);
                        continue;
                        end;
                    end;
                if Left(Buf,12)= 'BUTTON.FRAME' then
                    begin
                    Buf:= Trim(Upper(Right(Buf,length(Buf)-pos('=',Buf))));
                    for BufNum:= 0 to $F+1 do
                        begin
                        if BufNum= $F+1 then break;
                        if Upper(C_Name[BufNum])= Trim(Right(Buf,length(Buf)-pos('-',Buf))) then
                            begin
                            BN1:= BufNum;
                            break;
                            end;
                        end;
                    for BufNum:= 0 to $F+1 do
                        begin
                        if BufNum= $F+1 then break;
                        if Upper(C_Name[BufNum])= Trim(Left(Buf,pos('-',Buf)-1)) then
                            begin
                            BN2:= BufNum;
                            break;
                            end;
                        end;
                    if BufNum< $F+1 then
                        begin
                        V_Param^.SV_Color.Button.Frame:= Paste_Tetrads(BN2,BN1);
                        continue;
                        end;
                    end;
                }
                V_Err(21);
                end;

        {//ss/27.03.2003 15:40:31//}
        if Buf= '[LAST-FILES]' then
            while not eof(Ini) do
                begin
                readln(Ini,Buf);
                NormBuf:=Trim(Buf);
                Buf:=Upper(NormBuf);
                if Empty(Buf) then continue;
                if Buf[1]= IniComm then continue;
                if Buf[1]= '[' then break;
                if FileStrParam(NormBuf, 'FILE1', V_Param^.Last_Files[1], '')
                or FileStrParam(NormBuf, 'FILE2', V_Param^.Last_Files[2], '')
                or FileStrParam(NormBuf, 'FILE3', V_Param^.Last_Files[3], '')
                or FileStrParam(NormBuf, 'FILE4', V_Param^.Last_Files[4], '')
                or FileStrParam(NormBuf, 'FILE5', V_Param^.Last_Files[5], '')
                or FileStrParam(NormBuf, 'FILE6', V_Param^.Last_Files[6], '')
                or FileStrParam(NormBuf, 'FILE7', V_Param^.Last_Files[7], '')
                or FileStrParam(NormBuf, 'FILE8', V_Param^.Last_Files[8], '')
                or FileStrParam(NormBuf, 'FILE9', V_Param^.Last_Files[9], '')
                then continue;
                V_Err(21);
                end;
                {//ss//}
        if (Buf[1]<> '[') and (not eof(Ini)) then
            V_Err(22);
        end;
    close(Ini);
    EndProc:
    Set_Viewer_Param;
    end;
{$endif}
procedure Set_Viewer_Param;
    begin
    {$ifdef external}
    Color:= V_Param^.SV_Color;
    {$endif}
    NullSymb:= nostextsym;
    with V_Param^ do
        begin
        if Clock then
            DrawTime:= 2
        else
            DrawTime:= 0;
        VDirc:= Dic_Dir;
        TalkStatus(Talk);
        SetDictor(Dictor);
        Wave.Status:= (Sound) {and (OS= dos6_22)};
        set_temp(Temp);
        if Mode= 3 then
            if Empty(User_Decode) then
                Mode:= 0;
        UseMouse:= (Mouse) and (mouseready);
        CF_Memr:= Memory;
        Usage_Mem:= Memory;
        RSpace:= ReadSpace;
        Discret:= Word97_StLen;
        LatLang:= Lat_Language;
        CyrLang:= Cyr_Language;
        UkrCoding:= Ukr_Coding;
        if (ChFrag) and (not Empty(ChFrag_F)) then
            begin
            ChList.Define(mem.low,sizeof(tChFrag));
            Load_ChF;
            end;
        Save_Link:= Html_Link;
        end;
    end;

procedure Set_Default_Param;
    var
        Temp_Str:       string;

    begin
    Temp_Str:= '';
    Temp_Str:= getenv('temp');
    if Empty(Temp_Str) then
        begin
        Temp_Str:= getenv('tmp');
        if Empty(Temp_Str) then
            Temp_Str:= MyDirc;
        end;
    with V_Param^ do
        begin
        {//ss/27.03.2003 15:41:29//}
        Load_Last_Files:=True;
        FillChar(Last_Files, SizeOf(Last_Files), #0);
        {//ss//}
        Open_Mask:=''; {//ss/31.03.2003 18:04:43//}
        Startup_OpenDialog:=False; {//ss/14.04.2003 18:07:57//}
        Startup_Read_OnStart:=False;
        Memory:= Low;
        Temp_Dir:= Temp_Str;
        CycleMenu:= true;
        AutoSave:= true;
        Tab:= true;
        ExitConfirm:= true;
        Transform_Lat:= false;
        NoStop:= false;
        Jump_1:= 100;
        Jump_2:= 500;
        Exact_Time:= true;
        ChFrag:= false;
        ChFrag_F:= '';
        Local:= 0;
        Clock:= true;
        Mouse:= true;
        Cursor:= false;
        PerCent:= true;
        Coord:= true;
        MemSize:= true;
        ShCode:= true;
        SPBM:= false;
        ShowLine:= false;
        Auto_Ext_BMark:= true;
        V_Param^.Talk:= true;
        Dictor:= 0;
        Dic_Dir:= left(MYDirc,length(MyDirc)-1);
        Temp:= 0;
        ReadEmpty:= false;
        ReadBySym:= false;
        ReadWord:= false;
        ReadIndent:= false;
        ReadWinByWin:= false;
        ReadAllLine:= false;
        ReadSpace:= true;
        Capital:= false;
        AOS.BSymb:= 0;
        AOS.ESymb:= 0;
        Empty_Delay:= 5;
        Sound:= true;
        EmptyBell:= false;
        BOE:= true;
        Sep_Win:= true;
        LoadSound:= true;
        Indent_Control:= true;
        DBF_Control:= true;
        Arc_Control:= true;
        Doc_Control:= true;
        Word97_StLen:= 72;
        ShowProcess:= false;
        Last_Posit:= true;
        AutoDetect_Code:= true;
        Mode:= 0;
        User_Decode:= '';
        Printab:= false;
        Lat_Language:= English;
        Cyr_Language:= Russian;
        Ukr_Coding:= UkrLexCoding;
        SV_Color:= Color;
        with Config do
            begin
            Forward:= true;
            Regs:= false;
            FromBegin:= true;
            SubString:= true;
            Say_Posit:= false;
            for C:= 1 to 10 do
                with Alarm[C] do
                    begin
                    Status:= false;
                    Tme:= '';
                    EveryOnce:= true;
                    Message:= '';
                    end;
            end;
        end;
    end;

begin
{$ifdef external}
C_Name[0]:= 'black';
C_Name[1]:= 'blue';
C_Name[2]:= 'green';
C_Name[3]:= 'cyan';
C_Name[4]:= 'red';
C_Name[5]:= 'magenta';
C_Name[6]:= 'brown';
C_Name[7]:= 'light_gray';
C_Name[8]:= 'dark_gray';
C_Name[9]:= 'light_blue';
C_Name[10]:= 'light_green';
C_Name[11]:= 'light_cyan';
C_Name[12]:= 'light_red';
C_Name[13]:= 'light_magenta';
C_Name[14]:= 'yellow';
C_Name[15]:= 'white';
{$endif}
end.
{

Шишминцев Сергей
27.03.2003 15:43:02
Добавлены
   Load_Last_Files: Boolean;
   Last_Files: array[tHMW] of String[80];
17.09.2008
Добавлены
   [GENERAL]->Last_Path (FF.CF_Path)
   Startup_Read_OnStart: Boolean;


Довыденков Владимир

09/02/2000
  добавление параметра  V_Param^.Auto_Ext_BMark.  Добавление этого
  параметра в файл инициализации.
10/02/2000
  введены параметры  Lat_Language  и  Cyr_Language
  введен раздел  [LANGUAGE]  в файле инициализации
  введен параметр  Ukr_Coding
}
