unit Keyb;

interface

type
    tFlag=          (Up,Down,Verify);
    tBack_Key=      (Any_Alt,Any_Ctrl,Left_Shift,Right_Shift,Any_Shift,Nothing);
    tKeyCode=       integer;

CONST  { КОНСТАНТЫ КОДОВ КЛАВИШ                                             }
  { Главный код                                                        }
  CSlCod      = 00;
  CBack       = 08;
  CTab        = 09;
  CCtrl_Enter = 10;
  CEnter      = 13;
  CEsc        = 27;
  CSpace      = 32;
  cCtrl_Back = 127;

  CCtrl_A = 01;  CCtrl_H = 08;  CCtrl_O = 15;  CCtrl_V = 22;
  CCtrl_B = 02;  CCtrl_I = 09;  CCtrl_P = 16;  CCtrl_W = 23;
  CCtrl_C = 03;  CCtrl_J = 10;  CCtrl_Q = 17;  CCtrl_X = 24;
  CCtrl_D = 04;  CCtrl_K = 11;  CCtrl_R = 18;  CCtrl_Y = 25;
  CCtrl_E = 05;  CCtrl_L = 12;  CCtrl_S = 19;  CCtrl_Z = 26;
  CCtrl_F = 06;  CCtrl_M = 13;  CCtrl_T = 20;
  CCtrl_G = 07;  CCtrl_N = 14;  CCtrl_U = 21;

  { Вспомогательный код                                                }
  { Буквенно-цифровые клавиши                                          }
  CAlt_A  = -30;  CAlt_H  = -35;  CAlt_O  = -24;  CAlt_V  = -47;
  CAlt_B  = -48;  CAlt_I  = -23;  CAlt_P  = -25;  CAlt_W  = -17;
  CAlt_C  = -46;  CAlt_J  = -36;  CAlt_Q  = -16;  CAlt_X  = -45;
  CAlt_D  = -32;  CAlt_K  = -37;  CAlt_R  = -19;  CAlt_Y  = -21;
  CAlt_E  = -18;  CAlt_L  = -38;  CAlt_S  = -31;  CAlt_Z  = -44;
  CAlt_F  = -33;  CAlt_M  = -50;  CAlt_T  = -20;
  CAlt_G  = -34;  CAlt_N  = -49;  CAlt_U  = -22;

  CAlt_1  = -120; CAlt_4  = -123; CAlt_7  = -126; CAlt_0     = -129;
  CAlt_2  = -121; CAlt_5  = -124; CAlt_8  = -127; CAlt_Minus = -130;
  CAlt_3  = -122; CAlt_6  = -125; CAlt_9  = -128; CAlt_Equal = -131;

  { Функциональные клавиши                                             }
  CF1  = -59;  CShift_F1  = -84 ;  CCtrl_F1  = -94 ;  CAlt_F1  = -104;
  CF2  = -60;  CShift_F2  = -85 ;  CCtrl_F2  = -95 ;  CAlt_F2  = -105;
  CF3  = -61;  CShift_F3  = -86 ;  CCtrl_F3  = -96 ;  CAlt_F3  = -106;
  CF4  = -62;  CShift_F4  = -87 ;  CCtrl_F4  = -97 ;  CAlt_F4  = -107;
  CF5  = -63;  CShift_F5  = -88 ;  CCtrl_F5  = -98 ;  CAlt_F5  = -108;
  CF6  = -64;  CShift_F6  = -89 ;  CCtrl_F6  = -99 ;  CAlt_F6  = -109;
  CF7  = -65;  CShift_F7  = -90 ;  CCtrl_F7  = -100;  CAlt_F7  = -110;
  CF8  = -66;  CShift_F8  = -91 ;  CCtrl_F8  = -101;  CAlt_F8  = -111;
  CF9  = -67;  CShift_F9  = -92 ;  CCtrl_F9  = -102;  CAlt_F9  = -112;
  CF10 = -68;  CShift_F10 = -93 ;  CCtrl_F10 = -103;  CAlt_F10 = -113;

  { Клавиши управления курсором       (Alt-кодов  нет)                 }
  CHome = -71;   CShift_Home = -71;   CCtrl_Home = -119;
  CUp   = -72;   CShift_Up   = -72;   CCtrl_Up   = -11; {нет кода}
  CPgUp = -73;   CShift_PgUp = -73;   CCtrl_PgUp = -132;
  CLeft = -75;   CShift_Left = -75;   CCtrl_Left = -115;
  C_5   = -76;   CShift_5    = -76;   CCtrl_5    = -10; {нет кода}
  CRight= -77;   CShift_Right= -77;   CCtrl_Right= -116;
  CEnd  = -79;   CShift_End  = -79;   CCtrl_End  = -117;
  CDown = -80;   CShift_Down = -80;   CCtrl_Down = -12; { нет кода}
  CPgDn = -81;   CShift_PgDn = -81;   CCtrl_PgDn = -118;
  CIns  = -82;   CShift_Ins  = -05;   CCtrl_Ins  = -04; {-04}
  CDel  = -83;   CShift_Del  = -04;   CCtrl_Del  = -06;

  CShift_Ins2  = -07;
  CCtrl_Shift_Left  = -115;
  CCtrl_Shift_Right = -116;

  { Прочие                                                             }
  CShift_Tab = -15;  CCtrl_PrtScr = -114;  CCtrl_Break= 0;

var
    ReturnRShift:   boolean;
    ReturnLShift:   boolean;
    ReturnCtrl:     boolean;
    ReturnAlt:      boolean;
    ReturnShift:    boolean;
    MouseReady:     boolean;
    MouseButton:    byte;
    MCoordX:        word;
    MCoordY:        word;

procedure ClearBuffer;
procedure WaitCtrlUp;
function  RShift:  boolean;
function  LShift:  boolean;
function  Ctrl:  boolean;
function  Alt:  boolean;
function  Shift:  boolean;
function  DefineKey:  integer;
function  ScrollLock(Flag:  tFlag):  boolean;
function  NumLock(Flag:  tFlag):  boolean;
function  CapsLock(Flag:  tFlag):  boolean;
{$IFDEF SV_MOUSE}
function  LButton:  boolean;
function  RButton:  boolean;
function  MButton:  boolean;
{$ENDIF}
function  OnlyCtrl:  boolean;
function  OnlyAlt:  boolean;
function  OnlyShift:  boolean;
{$IFDEF SV_MOUSE}
procedure MousePositionStatus ( Status: PWord;
                                Xcoord: PWord;
                                Ycoord: PWord);
{$ENDIF}

implementation
uses Windows, hronos, {$IFDEF SV_MOUSE}mouse,{$ENDIF} keyboard;

var
    SpKey:          byte;

function SpecialKey: byte;
begin
   SpecialKey:=GetKeyEventShiftState(PollShiftStateEvent);
end;

procedure WaitCtrlUp;
var
  i: Integer;
begin
  for i:=0 to 3000 do begin
    if (SpecialKey and kbCtrl) = 0 then
       break;
    DoBackgroundTasks;
  end;
end;

function RShift:  boolean;
    var
        Buffer:         boolean;

    begin
    if (SpKey and $01)<>0 then
        Buffer:= true
    else
        Buffer:= false;
    SpKey:= SpKey and not $01;
    RShift:= Buffer;
    end;

function LShift:  boolean;
    var
        Buffer:         boolean;

    begin
    if (SpKey and $02)<>0 then
        Buffer:= true
    else
        Buffer:= false;
    SpKey:= SpKey and not $02;
    LShift:= Buffer;
    end;

function Ctrl:  boolean;
    begin
    if (SpKey and $04)<> 0 then
        Ctrl:= true
    else
        Ctrl:= false;
    SpKey:= SpKey and not $04;
    end;

function Alt:  boolean;
    var
        Buffer:         boolean;

    begin
    if (SpKey and $08)<>0 then
        Buffer:= true
    else
        Buffer:= false;
    SpKey:= SpKey and not $08;
    Alt:= Buffer;
    end;

function Shift:  boolean;
    begin
    if (RShift) or (LShift) then
        Shift:= true
    else
        Shift:= false;
    end;

function  DefineKey:  integer;
    const Ukr_I_Case: array[boolean] of Integer = (247, 246);
    var
        Event:          TKeyEvent;
        vShift:         boolean;
        vRShift:        boolean;
        vLShift:        boolean;
        vCtrl:          boolean;
        vAlt:           boolean;
        X:              word;
        Y:              word;
        Status:         word;

    begin
    vShift:= false;
    vRShift:= false;
    vLShift:= false;
    vCtrl:= false;
    vAlt:= false;
    Status:= 0;
    MouseButton:= 0;
    while True do begin
        ShowCurTime;
        {$IFDEF SV_MOUSE} 
        mousepositionstatus(@Status,@X,@Y);
        if (Status> 0) and (mouseready) then
            begin
            Definekey:= 0;
            MouseButton:= Status;
            MCoordX:= X;
            MCoordY:= Y;
            repeat
               DoBackgroundTasks;
            until (GetMouseButtons and Status) <> 0;
            exit;
            end;
        {$ENDIF}
        while (((SpecialKey and $01)<>0) or ((SpecialKey and $02)<>0)) and (ReturnShift) and (not keypressed) do begin
            vShift:= true;
            DoBackgroundTasks;
        end;
        if (vShift) and (not keypressed) then
            begin
            SpKey:= SpecialKey or $03;
            defineKey:= 0;
            exit;
            end;
        while ((SpecialKey and $02)<>0) and (ReturnLShift) and (not keypressed) do begin
            vLShift:= true;
            DoBackgroundTasks;
        end;
        if (vLShift) and (not keypressed)  then
            begin
            SpKey:= SpecialKey or $02;
            defineKey:= 0;
            exit;
            end;
        while ((SpecialKey and $01)<>0) and (ReturnRShift) and (not keypressed) do begin
            vRShift:= true;
            DoBackgroundTasks;
        end;
        if (vRShift) and (not keypressed)  then
            begin
            SpKey:= SpecialKey or $01;
            defineKey:= 0;
            exit;
            end;
        while ((SpecialKey and $04)<>0) and (ReturnCtrl) and (not keypressed) do begin
            vCtrl:= true;
            DoBackgroundTasks;
        end;
        if (vCtrl) and (not keypressed)  then
            begin
            SpKey:= SpecialKey or $04;
            defineKey:= 0;
            exit;
            end;
        while ((SpecialKey and $08)<>0) and (ReturnAlt) and (not keypressed) do begin
            vAlt:= true;
            DoBackgroundTasks;
        end;
        if (vAlt) and (not keypressed)  then
            begin
            SpKey:= SpecialKey or $08;
            defineKey:= 0;
            exit;
            end;
        if keypressed then
          break;
        DoBackgroundTasks;
    end;
    SpKey:= SpecialKey;
    Event:=GetKeyEvent;
    if (Event and $ff) = 0 then
        DefineKey:= -((Event shr 8) and $ff)
    else case (Event and $ffffff) of
        $001f3f, $00303f: DefineKey:=Ukr_I_Case[CapsLock(verify)]; {Украинская i}
        $031f3f, $03303f: DefineKey:=Ukr_I_Case[not CapsLock(verify)]; {Украинская I}
        else
          DefineKey:= Event and $ff;
        end; // case
    end;

function ScrollLock(Flag:  tFlag):  boolean; 
    begin
      ScrollLock:= false;
    case Flag of
      {Up:  // FIXME
            begin
            SpecialKey^:= SpecialKey^ or $10;
            SpKey:= SpecialKey^;
            ScrollLock:= true;
            end;
    Down:
            begin
            SpecialKey^:= SpecialKey^ and not $10;
            SpKey:= SpecialKey^;
            ScrollLock:= false;
            end;}
  verify:   ScrollLock:=GetKeyState(VK_SCROLL) <> 0;
        end;
    end;

function NumLock(Flag:  tFlag):  boolean;
    begin
    NumLock:= false;
    case Flag of
      {Up:  // FIXME
            begin
            SpecialKey^:= SpecialKey^ or $20;
            SpKey:= SpecialKey^;
            NumLock:= true;
            end;
    Down:
            begin
            SpecialKey^:= SpecialKey^ and not $20;
            SpKey:= SpecialKey^;
            NumLock:= false;
            end;}
  verify:   NumLock:=GetKeyState(VK_NUMLOCK) <> 0;
        end;
    end;

function CapsLock(Flag:  tFlag):  boolean;
    begin
    CapsLock:= false;
    case Flag of
      {Up:  // FIXME
            begin
            SpecialKey^:= SpecialKey^ or $40;
            SpKey:= SpecialKey^;
            CapsLock:= true;
            end;
    Down:
            begin
            SpecialKey^:= SpecialKey^ and not $40;
            SpKey:= SpecialKey^;
            CapsLock:= false;
            end;}
  verify:   CapsLock:=GetKeyState(VK_CAPITAL) <> 0;
        end;
    end;

procedure ClearBuffer;
    begin
    while PollKeyEvent<>0 do GetKeyEvent;
    end;

{$IFDEF SV_MOUSE}
function  LButton:  boolean;
    begin
    LButton:= false;
    if (MouseButton and MouseLeftButton)<>0 then
        begin
        LButton:= true;
        MouseButton:= 0;
        end;
    end;

function  RButton:  boolean;
    begin
    RButton:= false;
    if (MouseButton and MouseRightButton)<>0 then
        begin
        RButton:= true;
        MouseButton:= 0;
        end;
    end;

function  MButton:  boolean;
    begin
    MButton:= false;
    if (MouseButton and MouseMiddleButton)<>0 then
        begin
        MButton:= true;
        MouseButton:= 0;
        end;
    end;
{$ENDIF}

function  OnlyCtrl:  boolean;
    begin
    if (Ctrl) and (not Alt) and (not Shift) then
        OnlyCtrl:= true
    else
        OnlyCtrl:= false;
    end;

function  OnlyAlt:  boolean;
    begin
    if (not Ctrl) and (Alt) and (not Shift) then
        OnlyAlt:= true
    else
        OnlyAlt:= false;
    end;

function  OnlyShift:  boolean;
    begin
    if (not Ctrl) and (not Alt) and (Shift) then
        OnlyShift:= true
    else
        OnlyShift:= false;
    end;

{$IFDEF SV_MOUSE}
procedure MousePositionStatus ( Status: PWord;
                                Xcoord: PWord;
                                Ycoord: PWord);
begin
  Xcoord^:=GetMouseX;
  Ycoord^:=GetMouseY;
  Status^:=GetMouseButtons;
end;
{$ENDIF}

begin
ReturnRShift:= false;
ReturnLShift:= false;
ReturnCtrl:= false;
ReturnAlt:= false;
ReturnShift:= false;
MouseButton:= 0;
{$IFDEF SV_MOUSE}
MouseReady:=DetectMouse > 0;
{$ELSE}
MouseReady:=False;
{$ENDIF}
end.