program SpeakingViewer;
{$B-,I-,V-}
{$R SV.RES}
uses Windows, {$IFDEF SV_MOUSE}mouse,{$ENDIF} video, keyboard,
  s_u,p_u,various,line,mem,speech,dialog,harddisk,ff,transfrm,dos,strutils;

const
    Arc_List:       string[12] = 'SV.DCL';
    Arc_Dirc=       'SV_ARC';
    Edge_Dir=       200;

var
  Old_Dirc: string;
  CleanArcOnExit: boolean;

procedure CleanArc;
var
  CDir: byte;
begin
  CDir:=0;
  while Directory_Exists(V_Param^.Temp_Dir+Arc_Dirc) do begin
    Del_Directory(V_Param^.Temp_Dir+Arc_Dirc,Old_Dirc,mem.Low);
    inc(CDir);
    if CDir = Edge_Dir then 
      break;
  end;
end;

function  Unpacked(Arc_Name:  string):  boolean;
    const
        Macros_File=    '<ARCHIVE>';
        Macros_Dirc=    '<DIRECTORY>';

    var
        Archivers:      text;
        Point:          byte;
        S:              string;
        Cmd:            string;
        i:              Integer;
        Dirc:           dirstr;
        Name:           namestr;
        Extn:           extstr;
        CDir:           byte;

    begin
    UnPacked:= false;
    assign(Archivers,MyDirc+Arc_List);
    filemode:= 0;
    reset(Archivers);
    filemode:= 2;
    if ioresult<> 0 then exit;
    fsplit(Arc_Name,Dirc,Name,Extn);
    while not eof(Archivers) do
        begin
        readln(Archivers,S);
        S:= Upper(Trim(S));
        if '.'+Upper(Trim(Left(S,pos(':',S)-1)))<> Upper(Extn) then
            continue;
        if (V_Param^.Arc_Control)
           and (not Yes('     Файл имеет расширение архива.  Загружать как архив?     ')) then
            exit;
        fsplit(Arc_Name,Dirc,Name,Extn);
        if Dirc= '' then
            Arc_Name:= fexpand(Arc_Name);
        ioresult;
        mkdir(V_Param^.Temp_Dir+Arc_Dirc);
        if not CleanArcOnExit then begin
          AddExitProc(CleanArc);
          CleanArcOnExit:=True;
        end;
        if ioresult<> 0 then
            begin
            CDir:= 0;
            repeat
                if Directory_Exists(V_Param^.Temp_Dir+Arc_Dirc) then
                    Del_Directory(V_Param^.Temp_Dir+Arc_Dirc,Old_Dirc,mem.low)
                else
                    break;
                inc(CDir);
                if CDir= Edge_Dir then break;
            until false;
            mkdir(V_Param^.Temp_Dir+Arc_Dirc);
            if ioresult<> 0 then exit;
            end;
        S:= Trim(Right(S,length(S)-pos(':',S)));
        i:=Pos(' ', S);
        Cmd:=ReplaceText(Copy(S, 1, i-1), '$SV', MyDirc);
        Delete(S, 1, i);
        if pos(Macros_File,S)> 0 then
            begin
            Point:= pos(Macros_File,S);
            delete(S,Point,length(Macros_File));
            insert(Arc_Name,S,Point);
            end;
        if pos(Macros_Dirc,S)> 0 then
            begin
            Point:= pos(Macros_Dirc,S);
            delete(S,Point,length(Macros_Dirc));
            insert(V_Param^.Temp_Dir+Arc_Dirc,S,Point);
            end;
        ioresult;
        chdir(V_Param^.Temp_Dir+Arc_Dirc);
        ioresult;
        fsplit(cmd,Dirc,Name,Extn);
        Extn:=Upper(Extn);
        if (Extn = '.CMD') or (Extn = '.BAT') then begin
          s:='/c '+Cmd+' '+s; 
          cmd:=GetEnv('COMSPEC');
        end;
        exec(Cmd, s);
        Unpacked:=True;
        break;
        end;
    close(Archivers);
    end;

procedure DoneConsole;
begin
{$IFDEF SV_MOUSE}
  DoneMouse;
{$ENDIF}
  DoneKeyboard;
  DoneVideo;
end;

const
  VideoMode: TVideoMode = (Col: 80; Row: 25; Color: True);
var
  LastMode, Mode: DWORD;
  Names: namestr;
begin
CleanArcOnExit:=False;
InitVideo;
SetVideoMode(VideoMode);
InitKeyboard;
AddExitProc(DoneConsole);
GetConsoleMode(StdInputHandle, @LastMode);
SetConsoleMode(StdInputHandle, LastMode and not (ENABLE_LINE_INPUT{xp/w7} or ENABLE_ECHO_INPUT{xp})); // Разрешить обработку Ctrl+S
{$IFDEF SV_MOUSE}
InitMouse;
{$ENDIF}
SaveScreen;
new(V_Param);
RParam;
Set_Viewer_Param;
Dev:= 0;
ReadMode:= false;
for C:= 1 to paramcount do
    if left(paramstr(C),1)= '/' then
        begin
        if lower(paramstr(C))= '/high' then Dev:= 1;
        if lower(paramstr(C))= '/low' then Dev:= 2;
        if lower(paramstr(C))= '/disk' then Dev:= 3;
        if lower(paramstr(C))= '/r' then ReadMode:= true;
        end;
if Dev> 0 then
    V_Param^.Memory:= tMemory(Dev-1);
Old_Dirc:=CF_Path;
CF_ChDr:= false;
HMW:= 1;
for C:= 1 to paramcount do
    if (Left(paramstr(C),1)<> '/') and (HMW< 10) then
        begin
        if Unpacked(paramstr(C)) then begin
            CF_Path:= V_Param^.Temp_Dir+Arc_Dirc;
            Names:= ChFile;
            chdir(Old_Dirc);
            if ReturnCode<> 27 then
                begin
                new(Viewer[HMW],Install(CF_Path+iif(CF_Path[length(CF_Path)]= '\','','\')+Names));
                inc(HMW);
                end
            else
                Exit;
        end else begin
          new(Viewer[HMW],Install(paramstr(C)));
          if not Viewer[HMW]^.Installed then
              Stop(2);
          V_Param^.Last_Files[HMW]:=FExpand(paramstr(C)); {//ss/27.03.2003 20:43:48//}
          inc(HMW);
        end;
        end;
{//ss/27.03.2003 15:44:50//}
with V_Param^ do if Load_Last_Files then
  for c:=System.Low(Last_Files) to System.High(Last_Files) do
    if (Viewer[c]=nil) and (Last_Files[c]<>'') then begin
      new(Viewer[c],Install(Last_Files[c]));
      if not Viewer[c]^.Installed then begin
        Dispose(Viewer[c], UnInstall);
        Viewer[c]:=nil;
      end else
        inc(HMW);
      end;
CF_Path:=Old_Dirc;
CF_ChDr:=True;
{//ss//}
if HMW= 1 then
  {//ss/14.04.2003 18:12:52//}
  if V_Param^.Startup_OpenDialog then begin
  Load_New_File;
  if Viewer[CWin]=nil then Stop(0);
  if not Viewer[CWin]^.Installed then Stop(0)
end
  else
    Stop(0);
new(Hlp_Viewer,Load(MyDirc+HFile,V_Param^.Memory));
Say('загру+жено.');
if V_Param^.Startup_Read_OnStart then
  Viewer[1]^.ReadText;
Call;
for C:= 1 to 9 do
    if Viewer[C]<> nil then
        dispose(Viewer[C],Uninstall);
Stop(0);
end { Speaking Viewer  v2.34 w130 }.