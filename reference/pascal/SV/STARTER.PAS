program Starter;
{$M $FFF0,$3000,$3000}
{$B-,I-}
uses line,various,speech,dialog,harddisk,ff,transfrm,  dos;

const
    Work_Program: string[13] =   'svr.man';
    Arc_List:       string[12] = 'SV.DCL';
    Arc_Dirc=       'ARC';
    Init_File=      'SV.INI';
    Edge_Dir=       200;

var
    Work_Dirc:      dirstr;
    Param_List:     string;
    Dirc:           dirstr;
    Name:           namestr;
    Extn:           extstr;
    Temp_Dir:       string[68];
    Old_Dirc:       string[68];
    TalkStat:       boolean;
    Arc_Control:    boolean;
    Names:          string;
    Killed:         file;
    F:              searchrec;
    IOR:            word;
    CDir:           byte;
    C:              byte;

function  Unpacked(Arc_Name:  string):  boolean;
    const
        Macros_File=    '<ARCHIVE>';
        Macros_Dirc=    '<DIRECTORY>';

    var
        Archivers:      text;
        Point:          byte;
        Com_File:       string;
        S:              string;

    begin
    UnPacked:= false;
    assign(Archivers,Work_Dirc+Arc_List);
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
        if (Arc_Control)
           and (not Yes('     Файл имеет расширение архива.  Загружать как архив?     ')) then
            exit;
        fsplit(Arc_Name,Dirc,Name,Extn);
        if Dirc= '' then
            Arc_Name:= fexpand(Arc_Name);
        IOR:= ioresult;
        mkdir(Temp_Dir+Arc_Dirc);
        if ioresult<> 0 then
            begin
            CDir:= 0;
            repeat
                if Directory_Exists(Temp_Dir+Arc_Dirc) then
                    Del_Directory(Temp_Dir+Arc_Dirc,Old_Dirc,mem.low)
                else
                    break;
                inc(CDir);
                if CDir= Edge_Dir then break;
            until false;
            mkdir(Temp_Dir+Arc_Dirc);
            if ioresult<> 0 then exit;
            end;
        S:= Trim(Right(S,length(S)-pos(':',S)));
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
            insert(Temp_Dir+Arc_Dirc,S,Point);
            end;
        IOR:= ioresult;
        chdir(Temp_Dir+Arc_Dirc);
        IOR:= ioresult;
        Com_File:= getenv('comspec');
        swapvectors;
        exec(Com_File,'/c '+S);
        swapvectors;
        {//ss/07.08.2003 19:07:19//}
        asm
           mov ax, $4A10
           mov bx, $0002
           int $2F
        end;
        Unpacked:= true;
        break;
        end;
    close(Archivers);
    end;

procedure Get_Param;
    var
        Init:           text;
        Buf:            string;

    begin
    assign(Init,Work_Dirc+Init_File);
    filemode:= 0;
    reset(Init);
    filemode:= 2;
    while not eof(Init) do
        begin
        readln(Init,Buf);
        if Left(Upper(Trim(Buf)),15)= 'TEMP_DIRECTORY=' then
            begin
            Buf:= Trim(Right(Buf,length(Buf)-pos('=',Buf)));
            Temp_Dir:= Buf;
            end;
        if Left(Upper(Trim(Buf)),5)= 'TALK=' then
            begin
            Buf:= Upper(Trim(Right(Buf,length(Buf)-pos('=',Buf))));
            if Buf= 'ON' then
                TalkStat:= true;
            if Buf= 'OFF' then
                TalkStat:= false;
            end;
        if Left(Upper(Trim(Buf)),Length('PROTECTED_MODE='))= 'PROTECTED_MODE=' then
            begin
            Buf:= Upper(Trim(Right(Buf,length(Buf)-pos('=',Buf))));
            if Buf= 'ON' then
                Work_Program:='SVP.MAN';
            if Buf= 'OFF' then
                Work_Program:='SVR.MAN';
            end;
        if Left(Upper(Trim(Buf)),12)= 'ARC_CONTROL=' then
            begin
            Buf:= Upper(Trim(Right(Buf,length(Buf)-pos('=',Buf))));
            if Buf= 'ON' then
                Arc_Control:= true;
            if Buf= 'OFF' then
                Arc_Control:= false;
            end;
        end;
    close(Init);
    end;

begin
fsplit(paramstr(0),Work_Dirc,Name,Extn);
if Work_Dirc= '' then
    fsplit(fexpand(paramstr(0)),Work_Dirc,Name,Extn);
Temp_Dir:= Work_Dirc;
TalkStat:= true;
Arc_Control:= true;
Get_Param;
talkstatus(TalkStat);
getdir(0,Old_Dirc);
CF_ChDr:= false;
Param_List:= '';
if paramcount> 0 then
    for C:= 1 to paramcount do
        begin
        if Unpacked(paramstr(C)) then
            begin
            chdir(Temp_Dir+Arc_Dirc);
            Names:= ChFile;
            chdir(Old_Dirc);
            if ReturnCode<> 27 then
                begin
                Param_List:= Param_List +CF_Path+iif(CF_Path[length(CF_Path)]= '\','','\')+Names+' ';
                continue;
                end
            else
                Exit;
            end;
        Param_List:= Param_List +paramstr(C)+' ';
        end;
{//ss/06.04.2003 10:27:22//}
{if Empty(Param_List) then
    begin
    CDir:= 0;
    repeat
        findfirst(Temp_Dir+Arc_Dirc,$3F,F);
        if (doserror= 0) and ((F.attr and directory)<> 0) then
            Del_Directory(Temp_Dir+Arc_Dirc,Old_Dirc,mem.low)
        else
            break;
        inc(CDir);
        if CDir= Edge_Dir then break;
    until false;
    IOR:= ioresult;
    chdir(Old_Dirc);
    halt;
    end;}
swapvectors;
exec(Work_Dirc+Work_Program,Param_List);
swapvectors;
findfirst(Temp_Dir+Arc_Dirc,anyfile,F);
CDir:= 0;
while (doserror= 0) and ((F.attr and directory)<> 0) do
    begin
    Del_Directory(Temp_Dir+Arc_Dirc,Old_Dirc,mem.Low);
    findfirst(Temp_Dir+Arc_Dirc,anyfile,F);
    inc(CDir);
    if CDir= Edge_Dir then break;
    end;
IOR:= ioresult;
chdir(Old_Dirc);
end {w006}.
