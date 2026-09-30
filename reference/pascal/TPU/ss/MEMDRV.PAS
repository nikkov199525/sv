Unit MemDrv;

interface
uses Objects;

type
    poMemDriver= ^toMemDriver;
    toMemDriver= object( TObject )
                 ElSize: Word;
                 constructor Init( ES: Word);
                 function   PutEl( N: LongInt; var Value): Boolean; virtual;
                 procedure   GetEl( N: LongInt; var Value); virtual;
                 procedure   Clean; virtual;
{-----------------------------------------------}
                 function    Reserve(Count: LongInt): Boolean; virtual;
                 function    FreeSpace: LongInt; virtual; {Выдает число свободных байтов }
                 function    FullSpace: LongInt; virtual; {Выдает общий размер в байтах}
{-----------------------------------------------}
                 end;

    poStreamMemDriver= ^toStreamMemDriver;
    toStreamMemDriver= object( toMemDriver )
                 Stream: PStream;
                 constructor Init(ES: Word; AStream: PStream);
                 function   PutEl( N: LongInt; var Value): Boolean; virtual;
                 procedure   GetEl( N: LongInt; var Value); virtual;
                 function    Reserve(Count: LongInt): Boolean; virtual;
                 procedure   Clean; virtual;
                 destructor Done; virtual;
                 end;

implementation

constructor toMemDriver.Init( ES: Word);
begin
  inherited Init;
  ElSize:=ES;
end;

function   toMemDriver.PutEl( N: LongInt; var Value): Boolean;
begin
  PutEl:=False;
end;

procedure   toMemDriver.GetEl( N: LongInt; var Value);
begin
  RunError(111);
end;

procedure   toMemDriver.Clean;
begin
end;


{-----------------------------------------------}
function    toMemDriver.FreeSpace: LongInt; {Выдает число свободных байтов в  EMS}
begin
  RunError(111);
end;

function    toMemDriver.FullSpace: LongInt; {Выдает размер EMS в байтах}
begin
  RunError(111);
end;

function    toMemDriver.Reserve(Count: LongInt): Boolean;
begin
  RunError(111);
end;
{-----------------------------------------------}

constructor toStreamMemDriver.Init(ES: Word; AStream: PStream);
var
  buf: byte;
begin
  inherited Init(ES);
  Stream:=AStream;
  Stream^.Write(buf, ElSize); // FPC compatibilty
end;

destructor toStreamMemDriver.Done;
begin
  Dispose(Stream, Done);
  inherited Done;
end;

function   toStreamMemDriver.PutEl( N: LongInt; var Value): Boolean;
begin
  if Stream^.Status<>stWriteError then
     Stream^.Reset
  else begin
    PutEl:=False;
    Exit;
  end;
  if Stream^.GetPos<>N* ElSize then
    Stream^.Seek( N* ElSize);
  Stream^.Write( Value, ElSize);
  PutEl:=Stream^.Status=stOk;
end;

procedure   toStreamMemDriver.GetEl( N: LongInt; var Value);
begin
  Stream^.Reset;
  if Stream^.GetPos<>N* ElSize then
    Stream^.Seek( N* ElSize);
  Stream^.Read( Value, ElSize);
end;

procedure   toStreamMemDriver.Clean;
var
  buf: byte;
begin
  Stream^.Seek( 0);
  Stream^.Write(buf, ElSize); // FPC compatibilty
  Stream^.Truncate;
end;

function    toStreamMemDriver.Reserve(Count: LongInt): Boolean;
begin
  Stream^.Seek(Count*ElSize);
  Reserve:=Stream^.Status=stOk;
end;

end.
