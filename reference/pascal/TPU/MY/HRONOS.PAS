unit hronos;

interface

type
    tL2W=           record
                        L:              word;
                        H:              word;
                        end;
    toDate=         object
                        public
                            Installed:      boolean;

                        constructor Install;
                        function    Day:  byte;
                        function    Month:  byte;
                        function    Year:  word;
                        function    DOW:  byte;
                        procedure   Now;
                        procedure   Equal(GD,GM:  byte;GY:  word);
                        destructor  Uninstall;

                        private
                            D:              byte;
                            M:              byte;
                            Y:              word;
                            W:              byte;
                        end;
    tProcedure=     procedure(NumOfAlm:  byte);
    tAlarm=         record
                        Status:         boolean;
                        Time:           record
                                            Hour:           byte;
                                            Minute:         byte;
                                            Second:         byte;
                                            end;

                        Attr:           word;
                        Reflex:         tProcedure;
                        Message:        string[80];
                        end;
    tStrOfTime=     string[11];

const
    DivideByTime:   string[3] = '::.';

var
    Alarm:          array[0..9] of tAlarm;
    TimeIntVec:     procedure;
    DrawTime:       byte;

function  More(First,Second:  toDate):  boolean;
function  Less(First,Second:  toDate):  boolean;
Procedure WorkOutAlarm;
function  CurrentTime:  tStrOfTime;
function  ToDay:  string;
procedure Pause(HowLong:  longint);
procedure ShowCurTime;
function Timer: LongInt;
procedure DoBackgroundTasks;

implementation
uses Windows, line,dialog,dinamic,various,  zeller,inter,  dos;

var
    LastShownTime:  tStrOfTime;
    Fixed:          longint;

constructor toDate.Install;
    begin
    Installed:= true;
    end;

function    toDate.Day:  byte;
    begin
    Day:= D;
    end;

function    toDate.Month:  byte;
    begin
    Month:= M;
    end;

function    toDate.Year:  word;
    begin
    Year:= y;
    end;

function    toDate.DOW:  byte;
    begin
    if W= 0 then
        DOW:= 6
    else
        DOW:= W -1;
    end;

procedure   toDate.Now;
    var
        BY,BM,BD,BW:    word;

    begin
    getdate(BY,BM,BD,BW);
    D:= BD;
    M:= BM;
    Y:= BY;
    W:= BW;
    end;

procedure   toDate.Equal(GD,GM:  byte;GY:  word);
    begin
    Y:= GY;
    if (GM<13) and (GM>0) then M:= GM;
    case GM of
       1:  if (GD<32) and (GD>0) then D:= GD;
       2:  if (GY div 4)= GY/4 then
               begin
               if (GD<30) and (GD>0) then D:= GD;
               end
           else
               if (GD<29) and (GD>0) then D:= GD;
       3:  if (GD<32) and (GD>0) then D:= GD;
       4:  if (GD<31) and (GD>0) then D:= GD;
       5:  if (GD<32) and (GD>0) then D:= GD;
       6:  if (GD<31) and (GD>0) then D:= GD;
       7:  if (GD<32) and (GD>0) then D:= GD;
       8:  if (GD<32) and (GD>0) then D:= GD;
       9:  if (GD<31) and (GD>0) then D:= GD;
      10:  if (GD<32) and (GD>0) then D:= GD;
      11:  if (GD<31) and (GD>0) then D:= GD;
      12:  if (GD<32) and (GD>0) then D:= GD;
        end;
    if (D<>0) and (M<>0) and (Y<>0) then W:= dayofweek(D,M,Y);
    end;

destructor  toDate.Uninstall;
    begin
    Installed:= false;
    end;

function  More(First,Second:  toDate):  boolean;
    begin
    if First.Year>Second.Year then
        begin
        More:= true;
        exit;
        end;
    if First.Year<Second.Year then
        begin
        More:= false;
        exit;
        end;
    if First.Year=second.Year then
        begin
        if First.Month>Second.Month then
            begin
            More:= true;
            exit;
            end;
        if First.Month<Second.Month then
            begin
            More:= false;
            exit;
            end;
        if First.Month=Second.Month then
            begin
            if First.Day>Second.Day then
                begin
                More:= true;
                exit;
                end;
            if First.Day<Second.Day then
                begin
                More:= false;
                exit;
                end;
            if First.Day=Second.Day then
                begin
                More:= false;
                exit;
                end;
            end;
        end;
    end;

function  Less(First,Second:  toDate):  boolean;
    begin
    Less:= not More(First,Second);
    end;

procedure WorkOutAlarm;
    var
        Counter:        byte;
        CHour:          word;
        CMinute:        word;
        CSecond:        word;
        CPartOfSecond:  word;

    procedure RunAlarm(Num:  byte);
        begin
        gettime(CHour,CMinute,CSecond,CPartOfSecond);
        with Alarm[Num].Time do
            begin
            if CHour=Hour then
                if CMinute=Minute then
                    if (CSecond<Second+10) and (CSecond>=Second) then
                        begin
                        {tut}
                        end;
            end;
        end;

    begin
    for Counter:= 0 to 9 do
        if Alarm[Counter].Status then RunAlarm(Counter);
    end;

function  CurrentTime:  tStrOfTime;
    var
        CHour:          word;
        CMinute:        word;
        CSecond:        word;
        CPartOfSecond:  word;
        Buffer:         string[2];
    begin
    Buffer:= '';
    gettime(CHour,CMinute,CSecond,CPartOfSecond);

    str(CHour,Buffer);
    CurrentTime[0]:=#11; // SetLength не компилируется
    if Length(Buffer) = 2 then begin
      CurrentTime[1]:=Buffer[1];
      CurrentTime[2]:=Buffer[2];
    end else begin
      CurrentTime[1]:='0';
      CurrentTime[2]:=Buffer[1];
    end;
    CurrentTime[3]:=DivideByTime[1];

    str(CMinute,Buffer);
    if Length(Buffer) = 2 then begin
      CurrentTime[4]:=Buffer[1];
      CurrentTime[5]:=Buffer[2];
    end else begin
      CurrentTime[4]:='0';
      CurrentTime[5]:=Buffer[1];
    end;
    CurrentTime[6]:=DivideByTime[2];

    str(CSecond,Buffer);
    if Length(Buffer) = 2 then begin
      CurrentTime[7]:=Buffer[1];
      CurrentTime[8]:=Buffer[2];
    end else begin
      CurrentTime[7]:='0';
      CurrentTime[8]:=Buffer[1];
    end;
    CurrentTime[9]:=DivideByTime[3];

    str(CPartOfSecond,Buffer);
    if Length(Buffer) = 2 then begin
      CurrentTime[10]:=Buffer[1];
      CurrentTime[11]:=Buffer[2];
    end else begin
      CurrentTime[10]:='0';
      CurrentTime[11]:=Buffer[1];
    end;
    end;

function  ToDay:  string;
    var
        D:              word;
        M:              word;
        Y:              word;
        W:              word;
        Res:            string[10];
        BuFF:           string[4];

    begin
    getdate(Y,M,D,W);
    str(D,Buff);
    Res:= iif(length(Buff)=1,'0','')+Buff+'/';
    str(M,Buff);
    Res:= Res +iif(length(Buff)=1,'0','')+Buff+'/';
    str(Y,Buff);
    Res:= Res +iif(length(Buff)=1,'0','')+Buff;
    ToDay:= Res;
    end;

procedure Pause(HowLong:  longint);
    begin
    inter.Pause(HowLong);
    end;      (*Pause*)

procedure ShowCurTime;
    var
      cur_time: tStrOfTime;
    begin
    if DrawTime= 0 then exit;
    cur_time:=Left(CurrentTime,8);
    if LastShownTime <> cur_time then begin
      PutLine(70,DrawTime,' '+cur_time+' ',Color.Time);
      ShowScr;
      LastShownTime:=cur_time;
    end;
    end;

function Timer: LongInt;
begin
  {$IFDEF WINDOWS}
  Timer:=GetTickCount;
  {$ELSE}
  Timer:=mem[Seg0040:$6C];
  {$ENDIF}
end;

procedure DoBackgroundTasks;
begin
  Sleep(1);
end;

end.