unit Mem;

interface
uses
  memdrv,
  mem_hea,
  mem_dsk,
  dos;

type
    tMemory=        (High,Low,Disk,AutoDetect);

    toMemory=       object
                        public
                            InitMemory:     boolean;
                            Sorce:          dirstr;
                            Reserved:       boolean;
                            Allocated:      longint;

                        constructor Define(Mem:  tMemory;S:  longint);
                        function    Add(var Elem):  boolean;
                        function    Pick(Index:  longint;var Capacity):  boolean;
                        function    FreeMemory(Mem:  tMemory):  boolean;
                        function    Change(Index:  longint;var NewElem):  boolean;
                        function    HowManyElem:  longint;
                        procedure   CleanMemory;
                        function    HowManyMem(Mem:  tMemory):  longint;
                        function    Reserve(Valume:  longint):  boolean;
                        destructor  Undefine;
                        function    MaxElem:  longint; {//ss/31.03.2003 15:13:32//}
                        private
                            Memory:         tMemory;
                            MemoryDriver:   pomemdriver;
                            Size:           longint;
                            Drive:          char;
                        end;

{var
    W_Dirc:         dirstr;}

function  HeapSize(TOH:  tMemory):  longint;

implementation
uses line,harddisk, P_U;

constructor toMemory.Define(Mem:  tMemory;S:  longint);
    var
        Temp:           word;
        FP:             dirstr;
        FN:             namestr;
        FE:             extstr;

    begin
    InitMemory:= false;
    if Mem= AutoDetect then exit;
    Memory:= Mem;
    Size:= S;
    MemoryDriver:=nil;
    case Memory of
    High:
            begin
              if (MemoryDriver=nil)  then begin
                MemoryDriver:=New(poHeapDriver, Init(Size));
                if MemoryDriver^.FreeSpace< Size then begin
                  Dispose(MemoryDriver, Done);
                  Exit;
                end;
              end;
            end;
     Low:
            begin
                MemoryDriver:=New(poHeapDriver, Init(Size));
                if MemoryDriver^.FreeSpace< Size then begin
                  Dispose(MemoryDriver, Done);
                  Exit;
                end;
            end;
    Disk:
            begin
            if empty(Sorce) then
                repeat
                    str(random(10000),Sorce);
                    Sorce:= V_Param^.Temp_Dir+Sorce+'.TMP'; {//ss/12.04.2003 14:30:44//}
                until not File_Exists(Sorce);
            if Sorce[2]= ':' then
                Drive:= Sorce[1]
            else
                Drive:= chr(64);
            if diskfree(ord(Drive)-64)< Size then exit;
                MemoryDriver:=New(poDiskDriver, Init(Size, Sorce));
                if MemoryDriver^.FreeSpace< Size then begin
                  Dispose(MemoryDriver, Done);
                  Exit;
                end;
            end;
        end;
    Allocated:=0;
    Reserved:= false;
    InitMemory:= true;
    end;

function    toMemory.Add(var Elem):  boolean;
    var
        Temp:           word;
        RealSize:       word;
        Counter:        longint;

    begin
      Add:= false;
      if not InitMemory then exit;
      if not FreeMemory(Memory) then exit;
      {//ss/07.08.2003 18:39:07//}
      if MemoryDriver^.putel((Allocated+1),Elem) then begin
        Inc(Allocated);
        Add:= true;
      end;
    end;

function    toMemory.Pick(Index:  longint;var Capacity):  boolean;
    var
        RealSize:       word;
        Temp:           word;

    begin
    Pick:= false;
    if (Index< 1) or (Index> HowManyElem) or (not InitMemory) then
        exit;
    MemoryDriver^.getel(Index,Capacity);
    Pick:= true;
    end;

function    toMemory.FreeMemory(Mem:  tMemory):  boolean;
    begin
    FreeMemory:= false;
    if (not InitMemory) or (HowManyMem(Mem)< Size*5) then exit;
    FreeMemory:= true;
    end;

function    toMemory.Change(Index:  longint;var NewElem):  boolean;
    var
        Temp:           word;
        RealSize:       word;

    begin
    Change:= false;
    if (not InitMemory) or (HowManyElem< 1) or (Index< 1) or (Index> HowManyElem) then
        exit;
    MemoryDriver^.putel(Index,NewElem);
    Change:= true;
    end;

function    toMemory.HowManyElem:  longint;
    begin
    HowManyElem:= Allocated;
    end;

procedure   toMemory.CleanMemory;
    var
        C:              longint;
        Nul:            char;
        IORes:          word;

    begin
    if (not InitMemory) or (HowManyElem< 1) then exit;
    Nul:= #0;
            MemoryDriver^.clean;
            for C:= 1 to Allocated do
                MemoryDriver^.putel(C,nul);
    Allocated:=0;
    end;

function    toMemory.HowManyMem(Mem:  tMemory):  longint;
    begin
    HowManyMem:= 0;
    if not InitMemory then exit;
    HowManyMem:= MemoryDriver^.FreeSpace;
    end;

function    toMemory.Reserve(Valume:  longint):  boolean;
    var
        NeedMemory:     longint;
        C:              longint;

    begin
    Reserved:= MemoryDriver^.Reserve(Valume);
    Reserve:=Reserved;
    end;

destructor  toMemory.Undefine;
    var
        Temp:           word;

    begin
    if not InitMemory then exit;
    Dispose(MemoryDriver, Done);
    MemoryDriver:=nil;
    Allocated:=0;
    InitMemory:= false;
    end;

function  HeapSize(TOH:  tMemory):  longint;
    var
        Temp_Memory:    toMemory;

    begin
    HeapSize:= 0;
    with Temp_Memory do
        begin
        Sorce:= '';
        Define(TOH,0);
        if not InitMemory then exit;
        HeapSize:= HowManyMem(TOH);
        Undefine;
        end;
    end;

function    toMemory.MaxElem:  longint;
var
  r: longint;
begin
  r:= (HowManyMem(Memory)-1024*32) div Size; {резерв 32кб}
  if r>0 then
     MaxElem:=r
  else
     MaxElem:=0;
end;

begin
end.