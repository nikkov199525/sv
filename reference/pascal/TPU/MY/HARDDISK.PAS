unit harddisk;
{$F+,I-,R-}
interface
uses speech,various,mem,  dos;

type
    tTextInfo=      record
                        MaxWidth:       byte;
                        MaxWNL:         longint;
                        MinWidth:       byte;
                        MinWNL:         longint;
                        Lines:          longint;
                        LMargin:        byte;
                        end;
    tFileInfo=      record
                        Name:           namestr;
                        Extn:           extstr;
                        Attr:           byte;
                        Size:           longint;
                        Time:           longint;
                        Mark:           boolean;
                        end;


var
    MyDirc:         string;
    F:              dos.searchrec;

procedure DeleteFile(FileName:  string);
procedure CopyFile(From,where:  string);
function  GetLabel:  string;
procedure GoToSlash;
procedure GetTextInfo(FN:  string;var Capacity:  tTextInfo);
procedure GetMyDirc;
procedure Del_Directory(DN:  string;New_DN:  string;Memr:  tMemory);
procedure GetnTextInfo(FN:  string;var Capacity:  tTextInfo);
function File_Exists(const FileName: String): Boolean;
function Directory_Exists(const Directory: String): Boolean;
function File_Size(const FileName: String): LongInt;

implementation
uses Windows, line, ff, discs;


const
  maxavail = $1000000; // FIXME
var
    IOR:            word;
    FList:          toMemory;

procedure DeleteFile(FileName:  string);
    var
        Prototype:      file;

    begin
    assign(Prototype,FileName);
    IOR:= ioresult;
    erase(Prototype);
    end;

procedure CopyFile(From,where:  string);
    type
        tpBuf=          ^tBuf;
        tBuf=           array[0..65534] of byte;

    var
        GetFile:        file;
        PutFile:        file;
        Buf:            tpBuf;
        Result:         integer;
        Attr:           word;
        Date:           longint;

    begin
    IOR:= ioresult;
    assign(GetFile,From);
    assign(PutFile,where);
    reset(GetFile,1);
    if ioresult<> 0 then exit;
    rewrite(PutFile,1);
    if ioresult<> 0 then exit;
    new(Buf);
    while not eof(GetFile) do
        begin
        blockread(GetFile,Buf^,sizeof(tBuf),Result);
        blockwrite(PutFile,Buf^,Result);
        end;
    dispose(Buf);
    close(GetFile);
    close(PutFile);
    getfattr(GetFile,Attr);
    getftime(GetFile,Date);
    setfattr(PutFile,Attr);
    setftime(PutFile,Date);
    end;

function  GetLabel:  string;
    var
        FoundLabel:     searchrec;

    begin
    GetLabel:= '';
    dos.findfirst('*.*',volumeid,FoundLabel);
    dos.findclose(FoundLabel);
    if doserror<> 0 then exit;
    if pos('.',FoundLabel.Name)> 0 then;
        delete(FoundLabel.Name,pos('.',FoundLabel.Name),1);
    GetLabel:= FoundLabel.name;
    end;

procedure GoToSlash;
    begin
    chdir(Chr(GetCurDisk+Ord('A'))+':\');
    end;

procedure GetTextInfo(FN:  string;var Capacity:  tTextInfo);
    var
        F:              text;
        Buffer:         string;
        Result:         tTextInfo;

    begin
    with Result do
        begin
        MaxWidth:= 0;
        MaxWNL:= 0;
        MinWidth:= 255;
        MinWNL:= 0;
        Lines:= 0;
        LMargin:= $FF;
        IOR:= ioresult;
        assign(F,FN);
        reset(F);
        if ioresult<> 0 then exit;
        while not eof(F) do
            begin
            readln(F,Buffer);
            inc(Lines);
            if Length(Buffer) > MaxWidth then
                begin
                MaxWidth:=Length(Buffer);
                MaxWNL:= Lines;
                end;
            if Length(Buffer) < MinWidth then
                begin
                MinWidth:=Length(Buffer);
                MinWNL:= Lines;
                end;
            if (Length(Buffer)-length(LTrim(Buffer))< LMargin) and (not Empty(Buffer)) then
                LMargin:= Length(Buffer)-length(LTrim(Buffer));
            end;
        end;
    close(F);
    Capacity:= Result;
    end;

procedure GetNTextInfo(FN:  string;var Capacity:  tTextInfo);
    const
        BufSize=        $2000;

    type
        tBuf=           array[0..BufSize] of byte;
        tpBuf=          ^tBuf;

    var
        F:              file;
        Result:         tTextInfo;
        SpCounter:      byte;
        Buf:            tpBuf;
        Len:            byte;
        RS:             word;
        C:              word;
        LastChar:       Byte;
        IsSpaces:       boolean;

    begin
    with Result do
        begin
        MaxWidth:= 0;
        MaxWNL:= 0;
        MinWidth:= 255;
        MinWNL:= 0;
        Lines:= 0;
        LMargin:= 0;
        if maxavail< sizeof(tBuf)+1 then exit;
        IOR:= ioresult;
        assign(F,FN);
        IOR:= ioresult;
        filemode:= 0;
        reset(F,1);
        filemode:= 2;
        if ioresult<> 0 then exit;
        new(Buf);
        Len:= 0;
        SpCounter:= 0;
        LastChar:=0;
        IsSpaces:=False;
        while not eof(F) do
            begin
            blockread(F,Buf^,BufSize,RS);
            C:= 0;
            while C<= RS do
                begin
                if IsSpaces then begin
                  if (Buf^[C] <> 32) and (Buf^[C] <> 9)
                     and (Buf^[C] <> $D) and (Buf^[C] <> $A) then begin
                    inc(Lines);
                    if Len> MaxWidth then
                        begin
                        MaxWidth:= Len;
                        MaxWNL:= Lines;
                        end;
                    if Len< MinWidth then
                        begin
                        MinWidth:= Len;
                        MinWNL:= Lines;
                        end;
                    Len:= 0;
                    LastChar:=Buf^[C];
                    inc(C);
                    IsSpaces:=False;
                    continue;
                  end;
                end;
                if Buf^[C]= $A then
                    begin
                    inc(Lines);
                    if (Len> 0) and (LastChar = $D) then {//ss/31.03.2003 16:18:16//}
                        dec(Len);
                    if Len> MaxWidth then
                        begin
                        MaxWidth:= Len;
                        MaxWNL:= Lines;
                        end;
                    if Len< MinWidth then
                        begin
                        MinWidth:= Len;
                        MinWNL:= Lines;
                        end;
                    Len:= 0;
                    LastChar:=Buf^[C];
                    inc(C);
                    IsSpaces:=False;
                    continue;
                    end;
                if Buf^[C]<> $D then
                    begin
                    inc(Len);
                    if (Len = 255) then
                        begin
                        inc(Lines);
                        if Len> MaxWidth then
                            begin
                            MaxWidth:= Len;
                            MaxWNL:= Lines;
                            end;
                        Len:= 0;
                        IsSpaces:=False;
                        end
                    else if (Len > 81) and ((Buf^[C] = 32) or (Buf^[C] = 9)) then
                      IsSpaces:=True
                    end;
                LastChar:=Buf^[C];
                inc(C);
                end;
            end;
        if Len> 0 then
            inc(Lines);
        dispose(Buf);
        close(F);
        end;
    Capacity:= Result;
    end;

procedure  GetMyDirc;
    var
        Dirc:           dirstr;
        Name:           namestr;
        Extn:           extstr;

    begin
    fsplit(paramstr(0),Dirc,Name,Extn);
    if empty(Dirc) then
        fsplit(fexpand(paramstr(0)),Dirc,Name,Extn);
    MyDirc:= Dirc;
    end;

procedure Del_F;
    var
        TmpFile:        file;

    begin
    if PLocated= nil then exit;
    assign(TmpFile,PLocated^.name);
    setfattr(TmpFile,0);
    erase(TmpFile);
    end;

procedure Del_Directory(DN:  string;New_DN:  string;Memr:  tMemory);
    var
        Cap_Dirc:       dirstr;
        C:              longint;

    begin
    setcurdisk(ord(upcase(DN[1]))-65);
    GoToSlash;
    IOR:= ioresult;
    rmdir(DN);
    if ioresult= 0 then
        begin
        chdir(New_DN);
        exit;
        end;
    if maxavail< sizeof(searchrec)+1 then exit;
    new(PLocated);
    Dirc.Define(Memr,sizeof(dirstr));
    StackSize:= 266;
    Dirc.Add(DN);
    WF(Del_F);
    dispose(PLocated);
    IOR:= ioresult;
    {setcurdisk(ord(upcase(New_DN[1]))-65);}
    GoToSlash;
    chdir(New_DN);
    for C:= Dirc.HowManyElem downto 1 do  { цикл по подкаталогам }
        begin
        if not Dirc.Pick(C,Cap_Dirc) then continue;
        IOR:= ioresult;
        rmdir(Cap_Dirc);
        if ioresult= 0 then
        end;
    Dirc.Undefine;
    end;

function File_Exists(const FileName: String): Boolean;
var
  s: AnsiString;
  Attr: Dword;
begin
  s:=FileName;
  Attr:=GetFileAttributesA(PAnsiChar(s));
  if Attr <> $ffffffff then
    File_Exists:=(Attr and FILE_ATTRIBUTE_DIRECTORY) = 0
  else
    File_Exists:=False;
end;

function Directory_Exists(const Directory: String): Boolean;
var
  s: AnsiString;
  Attr: Dword;
begin
  s:=Directory;
  Attr:=GetFileAttributesA(PAnsiChar(s));
  if Attr <> $ffffffff then
    Directory_Exists:=(Attr and FILE_ATTRIBUTE_DIRECTORY) <> 0
  else
    Directory_Exists:=False;
end;

function File_Size(const FileName: String): LongInt;
var
  s: AnsiString;
  fad: WIN32_FILE_ATTRIBUTE_DATA;
begin
  s:=FileName;
  File_Size:=0;
  if not GetFileAttributesEx(PAnsiChar(s), GetFileExInfoStandard, @fad) then
    Exit;
  if (fad.nFileSizeHigh <> 0) or (fad.nFileSizeLow >= $7FFFFFFF) then
    File_Size:=$7FFFFFFF
  else 
    File_Size:=fad.nFileSizeLow;
end;

begin
getmydirc;
end.
