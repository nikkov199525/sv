unit Mem_Dsk;
interface
uses MemDrv, Objects;
type
    poDiskDriver= ^toDiskDriver;
    toDiskDriver= object( toStreamMemDriver)
                 Path: String;
                 constructor Init(ES: LongInt; const APath: String);
                 destructor Done; virtual;
                 function    FreeSpace: LongInt; virtual; {Выдает число свободных байтов в  EMS}
                 function    FullSpace: LongInt; virtual;{Выдает размер EMS в байтах}

                 end;

implementation
uses Dos;
constructor toDiskDriver.Init(ES: LongInt; const APath: String);
begin
  inherited Init(ES, New(PBufStream, Init(APath, stCreate, 4096)));
  Path:=FExpand(APath);
end;

destructor toDiskDriver.Done;
var
  APath: String;
  f: Text;
begin
  Assign(f, Path);
  Inherited Done;
  Erase(f);
end;
function    toDiskDriver.FreeSpace: LongInt; {Выдает число свободных байтов в  EMS}
begin
  {//ss/12.04.2003 14:26:26//}
  FreeSpace:= DiskFree(Ord(Path[1])-Ord('A')+1);
end;

function    toDiskDriver.FullSpace: LongInt;
begin
  FullSpace:= DiskFree(Ord(Path[1])-Ord('A'));
end;

END.