unit Mem_Hea;
interface
uses MemDrv, Objects;
type
    poHeapDriver= ^toHeapDriver;
    toHeapDriver= object( toStreamMemDriver)
                 constructor Init( ES: Word);
                 function    FreeSpace: LongInt; virtual; {Выдает число свободных байтов в  EMS}
                 function    FullSpace: LongInt; virtual;{Выдает размер EMS в байтах}
                 end;

implementation
constructor toHeapDriver. Init( ES: Word);
begin
  inherited Init(ES, New(PMemoryStream, Init(1024, 1024*8)));
end;

function    toHeapDriver.FreeSpace: LongInt;
begin
  FreeSpace:=$1000000; // FIXME
end;

function toHeapDriver.FullSpace: LongInt;
begin
  FullSpace:=$1000000; // FIXME
end;

END.