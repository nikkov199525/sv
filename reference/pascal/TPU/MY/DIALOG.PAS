unit Dialog;
{$define nomaster}
interface
uses mem,keyb;

type
    tSquare=        record
                        Symb:           char;
                        Attr:           byte;
                        end;
    tScreen=        array[1..25,1..80] of tSquare;
    tFrame=         string[16];
    tColorMenu=     record
                        ActItem:        byte;
                        DeactItem:      byte;
                        Frame:          byte;
                        Title:          byte;
                        end;
    tColor_Radio=   record
                        Act_Title:      byte;
                        Deact_Title:    byte;
                        Act_B:          byte;
                        Deact_B:        byte;
                        end;
    tColor_Trig=    record
                        Act_Title:      byte;
                        Deact_Title:    byte;
                        Act_B:          byte;
                        Deact_b:        byte;
                        end;
    tColor_Button=  record
                        Title:          byte;
                        Act_B:          byte;
                        Deact_B:        byte;
                        end;
    tColor=         record
                        Message:        byte;
                        Text:           byte;
                        Frame:          byte;
                        Menu:           tColorMenu;
                        Title:          byte;
                        Error:          byte;
                        Marked:         byte;
                        Time:           byte;
                        R_Button:       tColor_Radio;
                        T_Button:       tColor_Trig;
                        Button:         tColor_Button;
                        Scale:          byte;
                        end;
    tOutputScreen=  (Current,Buffer);
    tHigh=          3..25;
    tWidth=         3..80;
    tExitCodes=     array[1..32] of integer;
    tPopupElem=     record
                        Elem:           string[80];
                        Mess:           string[80];
                        end;
    toPopupMenu=    object(toMemory)
                        public
                            Installed:      boolean;
                            High:           tHigh;
                            Width:          tWidth;
                            CurElem:        longint;
                            AllElem:        longint;
                            Cycle:          boolean;
                            SFrame:         tFrame;
                            Title:          string[76];
                            Cursor:         boolean;
                            Talk_Elem:      boolean;
                            MX:             byte;
                            MY:             byte;
                            L:              byte;
                            T:              byte;
                            R:              byte;
                            B:              byte;

                        constructor Install(Mem:  tMemory);
                        procedure   SetPosition(LE,TE,RE,BE:  byte);
                        procedure   In_Centr;
                        procedure   Call;
                        procedure   Show;
                        destructor  Uninstall;

                        private
                            FirstLine:      longint;
                            HotKeys:        array[0..0] of tKeyCode;

                        procedure   WorkHot;
                        end;
    tTrigElem=      record
                        Mess:           string;
                        Status:         boolean;
                        end;
    toTrigger=      object(toMemory)
                        public
                            Installed:      boolean;
                            High:           tHigh;
                            Width:          tWidth;
                            LMargin:        byte;
                            TMargin:        byte;
                            CurElem:        longint;
                            SFrame:         tFrame;
                            Cycle:          boolean;
                            AllElem:        longint;
                            Title:          string[78];

                        constructor Install(Mem:  tMemory);
                        procedure   SetPosition(LE,TE,RE,BE:  byte);
                        procedure   Call;
                        procedure   Show;
                        destructor  Uninstall;

                        private
                            L:              byte;
                            T:              byte;
                            R:              byte;
                            B:              byte;
                        end;
    tRadioElem=     string[78];
    toRadio=        object(toMemory)
                        public
                            Installed:      boolean;
                            High:           tHigh;
                            Width:          tWidth;
                            LMargin:        byte;
                            TMargin:        byte;
                            SFrame:         tFrame;
                            Title:          string[76];
                            AllElem:        longint;
                            CurElem:        longint;
                            Res:            longint;
                            Cycle:          boolean;

                        constructor Install(Mem:  tMemory);
                        procedure   SetPosition(LE,TE,RE,BE:  byte);
                        procedure   Call;
                        procedure   Show;
                        destructor  Uninstall;

                        private
                            L:              byte;
                            T:              byte;
                            R:              byte;
                            B:              byte;
                        end;
    tPadElem=       string[20];
    toPadMenu=      object(toMemory)
                        public
                            Installed:      boolean;
                            Cursor:         boolean;
                            AllElem:        longint;
                            CurElem:        longint;
                            Cycle:          boolean;

                        constructor Install(Mem:  tMemory);
                        procedure   Call;
                        procedure   SetPosition(LE,TE,RE:  byte);
                        procedure   In_Centr;
                        destructor  Uninstall;

                        private
                            L:              byte;
                            T:              byte;
                            R:              byte;

                        procedure   Show;
                        end;
    tChElem=        string[76];
    toChoice=       object(toMemory)
                        public
                            Installed:      boolean;
                            Mess:           string[78];
                            CurElem:        byte;
                            Cursor:         boolean;
                            AllElem:        byte;
                            LMargin:        byte;
                            TMargin:        byte;
                            SFrame:         tFrame;
                            Talk_Button:    boolean;

                        constructor Install(Mem:  tMemory);
                        procedure   Call;
                        procedure   Show;
                        procedure   SetPosition(LE,TE,RE,BE:  byte);
                        procedure   In_Centr;
                        destructor  Uninstall;

                        private
                            T:              byte;
                            L:              byte;
                            R:              byte;
                            B:              byte;
                            First:          boolean;
                        end;

const
    double=         '╔═╗║╝═╚║ ╩╠╦╣╬';
    single=         '┌─┐│┘─└│ ┴├┬┤┼';
    None=           '                ';
    OK=             'оке+й.';
    Cancel=         'отме+на.';
    Color:          tColor =
        (
        Message:  $17;
        Text:     $1F;
        Frame:    $1F;
        Menu:
             (
            ActItem:   $B8;
            DeactItem: $70;
            Frame:     $70;
            Title:     $70
             );
        Title:    $1F;
        Error:    $4E;
        Marked:   $1E;
        Time:     $1D;
        R_Button:
             (
            Act_Title:      $1F;
            Deact_Title:    $17;
            Act_B:          $1F;
            Deact_b:        $17
             );
        T_Button:
             (
            Act_Title:      $1F;
            Deact_Title:    $17;
            Act_B:          $1F;
            Deact_b:        $17
             );
        Button:
             (
            Title:          $1F;
            Act_B:          $B8;
            Deact_B:        $07
             );
        Scale:    $70
        );
    SymFrm:         tFrame = Double;
    ShFrm:          boolean = true;

var
    BufScreen:      tScreen;
    ReturnCode:     integer;
    ECode:          tExitCodes;
    Posit:          byte;
    UseMouse:       boolean;

procedure SetCursorXY(X, Y: Word);
procedure Frame(L,T,R,B:  byte);
procedure Frame_(L,T,R,B:  byte;Symbs:  tFrame);
procedure Frame__(L,T,R,B:  byte;Symbs:  tFrame;FrmCol:  byte);
procedure PutLine(X,Y:  byte;const Strng:  string;Col:  byte);
procedure ShowScr;
procedure Clear(L,T,R,B:  byte);
procedure EditLn(X,Y:  byte;var EL:  string;Max,Width:  byte);
function  Yes(Message:  string):  boolean;
procedure ShowMessage(M:  string;Hlp_Str:  string);
procedure ViewLN(X,Y:  byte;Mess:  string;Width:  byte);
procedure Clr;

implementation
uses video, line,various,dinamic,  cursor,speech,{$IFDEF SV_MOUSE}mouse,{$ENDIF}keyboard, hronos;

var
    C:              byte;

procedure SetCursorXY(X, Y: Word);
begin
  SetCursorPos(X-1, Y-1);
end;

procedure Frame(L,T,R,B:  byte);
    var
        Counter:        byte;

    begin
    if Empty(SymFrm) then exit;
    putline(L,T,SymFrm[1]+replicate(SymFrm[2],R-L-1)+SymFrm[3],Color.Frame);
    for Counter:= 1 to B-T-1 do
        if SymFrm[9]= ' ' then
            begin
            putline(L,T+Counter,SymFrm[8],Color.Frame);
            putline(R,T+Counter,SymFrm[4],Color.Frame);
            end
        else
            putline(L,T+Counter,SymFrm[8]+replicate(SymFrm[9],R-L-1)+SymFrm[4],Color.Frame);
    putline(L,B,SymFrm[7]+replicate(SymFrm[6],R-L-1)+SymFrm[5],Color.Frame);
    if (ShFrm) and (R< 80) and (B< 25) then
        begin
        for Counter:= 1 to (R-L)+1 do
            BufScreen[B+1,L+1+Counter].Attr:= 0;
        for Counter:= 1 to B-T do
            BufScreen[T+1+(Counter-1),R+1].Attr:= 0;
        for Counter:= 1 to B-T do
            BufScreen[T+1+(Counter-1),R+2].Attr:= 0;
        end;
    end;

procedure Frame_(L,T,R,B:  byte;Symbs:  tFrame);
    var
        TempFrm:        tFrame;

    begin
    TempFrm:= SymFrm;
    SymFrm:= Symbs;
    frame(L,T,R,B);
    SymFrm:= TempFrm;
    end;

procedure Frame__(L,T,R,B:  byte;Symbs:  tFrame;FrmCol:  byte);
    var
        TempFrm:        tFrame;
        TempCol:        byte;

    begin
    TempFrm:= SymFrm;
    TempCol:= Color.Frame;
    SymFrm:= Symbs;
    Color.Frame:= FrmCol;
    frame(L,T,R,B);
    SymFrm:= TempFrm;
    Color.Frame:= TempCol;
    end;

procedure PutLine(X,Y:  byte;const Strng:  string;Col:  byte);
    var
        Counter:        byte;
    begin
    if (X= 0) or (X+Length(Strng)> 81) or (Y= 0) or (Y> 25) then exit;
    for Counter:= 1 to Length(Strng) do
            with BufScreen[Y,X+(Counter-1)] do begin
               Symb:= Strng[Counter];
               Attr:= Col;
            end;
    end;

procedure ShowScr;
    begin
    Move(BufScreen, VideoBuf^, sizeof(BufScreen));
    UpdateScreen(False);
    end;

procedure Clear(L,T,R,B:  byte);
    var
        Counter:        byte;

    begin
    for counter:= T to B do
        putline(L,Counter,space((R-L)+1),Color.Text);
    end;

function  Quit(Code:  integer):  boolean;
    var
        Counter:        byte;

    begin
    Quit:= false;
    for Counter:= 1 to 32 do
        if ECode[Counter]= Code then
            begin
            Quit:= true;
            exit;
            end;
    end;

procedure EditLn(X,Y:  byte;var EL:  string;Max,Width:  byte);
    var
        OffSet:         byte;
        Point:          byte;
        CoordX:         byte;
        Key:            tKeyCode;
    begin
    ReturnCode:= 0;
    if (Width+X)>81 then Width:= 81 -X;
    if Posit> Length(El)+1 then Posit:= Length(El) + 1;
    if Length(El)<Width then
        begin
        OffSet:= 1;
        if Posit= 0 then
            CoordX:= X + Length(El)
        else
            CoordX:= (X +Posit)-1;
        end
    else
        begin
        OffSet:= (Length(El) - Width) +1;
        CoordX:= X +Width;
        end;
    if Posit= 0 then
        Point:= Length(El) + 1
    else
        Point:= Posit;
    while true do
        begin
        putline(X,Y,space(Width),Color.Text);
        putline(X,Y,copy(EL,OffSet,Width),Color.Text);
        showscr;
        SetCursorXY(CoordX,Y);
        Key:= definekey;
        {$IFDEF SV_MOUSE} 
        if Key= 0 then
            begin
            if LButton then Key:= CEnter;
            if MButton then Key:= CF1;
            if RButton then Key:= CEsc;
            end;
        {$ENDIF}
        if Quit(Key) then break;
        if (Key > 31) and (Length(El) < Max) then
            begin
            if (Key= CSpace) and (OnlyAlt) then
                begin
                Say(EL);
                continue;
                end;
            EL:= left(EL,Point-1) +chr(Key) +right(EL,(Length(El)-Point)+1);
            SaySymb(chr(Key));
            inc(Point);
            if CoordX<Width+X then
                inc(CoordX)
            else
                inc(OffSet);
            end;
        case Key of
       CBack:  if Point> 1 then
                   begin
                   SaySymb(EL[Point-1]);
                   EL:= left(EL,Point-2) +right(EL,(Length(El)-Point)+1);
                   inc(Point,-1);
                   if CoordX>X then
                       inc(CoordX,-1)
                   else
                       inc(OffSet,-1);
                   end
               else
                   Signal(S_Edge);
       CLeft:  if Point> 1 then
                begin
                SaySymb(EL[Point-1]);
                inc(Point,-1);
                if CoordX> X then
                    inc(CoordX,-1)
                else
                    inc(OffSet,-1);
                end
            else
                begin
                Signal(S_Edge);
                if Length(El) > 0 then SaySymb(EL[1]);
                end;
      CRight:  if Point< Length(El)+1 then
                begin
                if Length(El) > Point then
                    SaySymb(El[Point+1])
                else
                    SaySymb(' ');
                inc(Point);
                if CoordX<(X+Width)-1 then
                    inc(CoordX)
                else
                    inc(OffSet);
                end
            else
                Signal(S_Edge);
       CHome:
                begin
                if Length(El) > 0 then
                    SaySymb(EL[1])
                else
                    Signal(S_Edge);
                Point:= 1;
                OffSet:= 1;
                CoordX:= X;
                end;
        CEnd:
                begin
                if Length(El) > 0 then
                    SaySymb(' ')
                else
                    Signal(S_Edge);
                if Length(El) < Width then
                    begin
                    OffSet:= 1;
                    CoordX:= X + Length(El);
                    end
                else
                    begin
                    OffSet:= (Length(El) - Width) +1;
                    CoordX:= X +Width;
                    end;
                Point:= Length(El) + 1;
                end;
        CDel:  if Point< Length(El) + 1 then
                begin
                EL:= left(EL,Point-1) +right(EL,Length(El) - Point);
                if Length(El) > 0 then
                    SaySymb(El[Point])
                else
                    Signal(S_Edge);
                end
            else
                   Signal(S_Edge);
     CCtrl_Y:  if OnlyCtrl then
                begin
                EL:= '';
                Point:= 1;
                OffSet:= 1;
                CoordX:= X;
                Say('удалено+.');
                end;
     CCtrl_L:  if Point> 1 then Say(Left(El,Point-1));
     CCtrl_R:  if length(El)> Point then Say(Right(El,(length(El)-Point)+1));
     CCtrl_S:  Say(El);
            end;
        end;
    ReturnCode:= Key;
    Posit:= Point;
    end;

constructor toPopupMenu.Install(Mem:  tMemory);
    begin
    Installed:= false;
    Define(Mem,sizeof(tPopupElem));
    if not InitMemory then exit;
    CurElem:= 0;
    AllElem:= 0;
    SFrame:= Double;
    Title:= '';
    Cursor:= false;
    Talk_Elem:= true;
    Cycle:= true;
    MY:= 0;
    SetPosition(1,1,80,25);
    Installed:= true;
    end;

procedure   toPopupMenu.SetPosition(LE,TE,RE,BE:  byte);
    begin
    if (LE> 78) or (LE= 0) then exit;
    if (TE> 23) or (TE= 0) then exit;
    if RE-LE< 2 then RE:= LE +2;
    if BE-TE< 2 then BE:=  TE +2;
    L:= LE;
    T:= TE;
    R:= RE;
    B:= BE;
    High:= (BE-TE) +1;
    Width:= (RE-LE) +1;
    end;

procedure   toPopupMenu.In_Centr;
    var
        Counter:        longint;
        Buf:            tPopupElem;
        MaxLen:         byte;

    begin
    if (not Installed) or (HowManyElem< 1) or (AllElem< 1) then
        exit;
    MaxLen:= 0;
    for Counter:= 1 to AllElem do
        begin
        if not Pick(Counter,Buf) then break;
        if Length(Buf.Elem) > MaxLen then 
            MaxLen:=Length(Buf.Elem);
        end;
    T:= ((25-(AllElem+2)) div 2) +1;
    B:= T +AllElem +1;
    L:= ((80-(MaxLen+2)) div 2) +1;
    R:= L +MaxLen +1;
    if AllElem> 22 then
        begin
        T:= 1;
        B:= 25;
        end;
    if MaxLen> 77 then
        begin
        L:= 1;
        R:= 80;
        end;
    High:= B-T+1;
    Width:= R-L+1;
    end;

procedure   toPopupMenu.Call;
    var
        Key:            tKeyCode;
        CoordY:         byte;
        St,X,Y,OldY:    word;
        Buf:            tPopupElem;
        OldTalk:        boolean;

    begin
    OldTalk:= speech.Talk;
    ReturnCode:= 0;
    if (not Installed) or (HowManyElem< 1) then exit;
    if (AllElem> HowManyElem) or (AllElem< 2) then
        AllElem:= HowManyElem;
    if (CurElem= 0) or (CurElem> AllElem) then
        CurElem:= 1;
    CoordY:= T+CurElem;
    if CoordY> B-1 then CoordY:= B -1;
    FirstLine:= CurElem;
    if FirstLine> AllElem-High+3 then
        FirstLine:= CurElem-High+3;
    if FirstLine< 1 then FirstLine:= 1;
    if Cursor then
        setcursor(7,8)
    else
        hidecursor;
    {$IFDEF SV_MOUSE}
    if UseMouse then
        begin
        SetMouseXY((L-1)*8,(CoordY-1)*8);
        //mousescreensize((L-1)*8,(T-1)*8,(R-1)*8,(B-1)*8);
        end;
    {$ENDIF}
    while true do
        begin
        Show;
        SetCursorXY(L,CoordY);
        OldY:= CoordY;
        while not keypressed do
            begin
            DoBackgroundTasks;
            {$IFDEF SV_MOUSE} 
            if not UseMouse then continue;
            mousepositionstatus(@St,@X,@Y);
            if St> 0 then break;
            if (CurElem< AllElem) and ((Y/8)+1> CoordY) then
                begin
                inc(CurElem);
                if CoordY< T+High-2 then
                    inc(CoordY)
                else
                    inc(FirstLine);
                break;
                end;
            if (CurElem> 1) and ((Y/8)+1< CoordY) then
                begin
                inc(CurElem,-1);
                if CoordY> T+1 then
                    inc(CoordY,-1)
                else
                    inc(FirstLine,-1);
                break;
                end;
            {$ENDIF}
            end;
        if keypressed then
            Key:= definekey;
        TalkStatus(OldTalk);
        {$IFDEF SV_MOUSE}
        if (St> 0) and (UseMouse) then
            begin
            MouseButton:= St;
            repeat
                mousepositionstatus(@St,@X,@Y);
            until St= 0;
            if LButton then Key:= CEnter;
            if RButton then Key:= CEsc;
            if MButton then Key:= CF1;
            end;
        {$ENDIF}
        if (Key= CEnter) and (quit(Key)) and (Pick(CurElem,Buf)) and (Buf.Elem[1]= #1) then
            Key:= 1;
        if Key= CDown then
            begin
            if CurElem< AllElem then
                begin
                inc(CurElem);
                if CoordY< T+High-2 then
                    inc(CoordY)
                else
                inc(FirstLine);
                end
            else
                begin
                if Cycle then
                    begin
                    FirstLine:= 1;
                    CurElem:= 1;
                    CoordY:= T+1;
                    end
                else
                    TalkStatus(false);
                Signal(S_Edge);
                end;
            {$IFDEF SV_MOUSE}
            if UseMouse then
                SetMouseXY((L-1)*8,(CoordY-1)*8);
            {$ENDIF}
            end;
        if Key= CUp then
            begin
            if CurElem> 1 then
                begin
                inc(CurElem,-1);
                if CoordY> T+1 then
                    inc(CoordY,-1)
                else
                    inc(FirstLine,-1);
                end
            else
                begin
                if Cycle then
                    begin
                    CoordY:= B-1;
                    FirstLine:= AllElem-(B-T-2);
                    CurElem:= AllElem;
                    end
                else
                    TalkStatus(false);
                Signal(S_Edge);
                end;
            {$IFDEF SV_MOUSE}
            if UseMouse then
                SetMouseXY((L-1)*8,(CoordY-1)*8);
            {$ENDIF}
            end;
        if Quit(Key) then break;
        case Key of
      CSpace:  if (Pick(CurElem,Buf)) and (MY> 0) then
                begin
                Say(Buf.Mess);
                Talk_Elem:= false;
                end;
      49..57:  if Key-48<= AllElem then
                begin
                CurElem:= Key-48;
                CoordY:= T+CurElem;
                if CoordY> B-1 then CoordY:= B -1;
                FirstLine:= CurElem;
                if FirstLine> AllElem-High+3 then
                    FirstLine:= CurElem-High+3;
                if FirstLine< 1 then FirstLine:= 1;
                end;
       CHome:
                begin
                FirstLine:= 1;
                CurElem:= 1;
                CoordY:= T+1;
                end;
        CEnd:
                begin
                CoordY:= B-1;
                FirstLine:= AllElem-(B-T-2);
                CurElem:= AllElem;
                end;
            end;
    end;
    ReturnCode:= Key;
    end;

procedure   toPopupMenu.Show;
    var
        Counter:        byte;
        Buffer:         tPopupElem;

    begin
    if not Installed then exit;
    frame__(L,T,R,B,SFrame,Color.Menu.Frame);
    if (length(Title)< Width-4) and (Width> 4) then
        Title:= left(Title,Width-4);
    if Width> 4 then
        putline(L+((Width-length(Title)) div 2),T,Title,Color.Menu.Title);
    for Counter:= 0 to High-3 do
        begin
        if not Pick(FirstLine+Counter,Buffer) then
            begin
            putline(L+1,T+(Counter+1),space(Width-2),Color.Menu.DeActItem);
            continue;
            end;
        with Buffer do
            begin
            Elem:= left(Elem,Width-2);
            if Elem[1]= #1 then
                Elem:= right(Elem,length(Elem)-1)+' ';
            if FirstLine+Counter<> CurElem then
                putline(L+1,T+(Counter+1),Elem,Color.Menu.DeActItem)
            else
                begin
                putline(L+1,T+(Counter+1),Elem,Color.Menu.ActItem);
                if Talk_Elem then
                    Say(Elem)
                else
                    Talk_Elem:= true;
                if MX= 0 then
                    MX:= round((80-length(Mess))/2);
                putline(MX,MY,Mess,Color.Message);
                end;
            end;
        end;
    ShowScr;
    end;

procedure   toPopupMenu.WorkHot;
    var
        Counter:        longint;
        Buf:            tPopupElem;

    begin
    if AllElem< 2 then exit;
    for Counter:= 0 to AllElem-1 do
        begin
        if not pick(Counter,Buf) then break;
        end;
    end;

destructor  toPopupMenu.Uninstall;
    begin
    if not Installed then exit;
    Undefine;
    Installed:= false;
    end;

constructor toTrigger.Install(Mem:  tMemory);
    begin
    Define(Mem,sizeof(tTrigElem));
    if not InitMemory then exit;
    setposition(1,1,80,25);
    CurElem:= 0;
    LMargin:= 0;
    TMargin:= 0;
    SFrame:= Double;
    Installed:= true;
    end;

procedure   toTrigger.SetPosition(LE,TE,RE,BE:  byte);
    begin
    L:= LE;
    T:= TE;
    R:= RE;
    B:= BE;
    High:= (BE-TE) +1;
    Width:= (RE-LE) +1;
    end;

procedure   toTrigger.Call;
    var
        Key:            integer;
        CoordY:         byte;
        Buffer:         tTrigElem;
        OldTalk:        boolean;

    begin
    OldTalk:= speech.Talk;
    if (not Installed) or (HowManyElem< 1) then
        exit;
    if (AllElem= 0) or (AllElem> HowManyElem) then
        AllElem:= HowManyElem;
    if CurElem> AllElem then
        CurElem:= AllElem;
    if CurElem= 0 then
        CurElem:= 1;
    CoordY:= T+TMargin+CurElem;
    while true do
        begin
        show;
        if Pick(CurElem,Buffer) then
            with Buffer do
                Say(iif(Status,'вклю+чено.','вы+ключено.')+Mess);
        SetCursorXY(L+LMargin+2,CoordY);
        Key:= definekey;
        TalkStatus(OldTalk);
        {$IFDEF SV_MOUSE}
        if (Key= 0) and (UseMouse) then
            begin
            if LButton then Key:= 13;
            if MButton then Key:= -59;
            if RButton then Key:= 27;
            end;
        {$ENDIF}
        if (Quit(CSpace)) and (Key= 32) then
            if Pick(CurElem,Buffer) then
                begin
                with Buffer do
                    Status:= not Status;
                change(CurElem,Buffer);
                end;
        if Quit(Key) then break;
        case Key of
         CUp:
                begin
                if CurElem= 1 then
                    if Cycle then
                        begin
                        CurElem:= AllElem;
                        CoordY:= T+TMargin+AllElem;
                        end
                    else
                        break
                else
                    begin
                    inc(CoordY,-1);
                    inc(CurElem,-1);
                    end;
                end;
       CDown:
                begin
                if CurElem< HowManyElem then
                    begin
                    inc(CurElem);
                    inc(CoordY);
                    end
                else
                    if Cycle then
                        begin
                        CoordY:= T+TMargin+1;
                        CurElem:= 1;
                        end
                    else
                        break;
                end;
      CSpace:
                begin
                if Pick(CurElem,Buffer) then
                    begin
                    with Buffer do
                        Status:= not Status;
                    change(CurElem,Buffer);
                    end;
                end;
            end;
        end;
    ReturnCode:= Key;
    end;

procedure   toTrigger.Show;
    var
        Counter:        longint;
        Buffer:         tTrigElem;
        Mes:            string;

    begin
    frame__(L,T,R,B,SFrame,Color.Frame);
    if not Empty(Title) then
        PutLine(L+(((R-L)-length(Title)) div 2),T,Title,Color.Title);
    for Counter:= 1 to HowManyElem do
        begin
        if not Pick(Counter,Buffer) then break;
        Mes:= iif(Buffer.Status,'[X]','[ ]')+Buffer.Mess;
        if Counter= CurElem then
            putline(L+LMargin+1,(T+TMargin)+Counter,left(Mes,R-L-1),Color.T_Button.Act_B)
        else
            putline(L+LMargin+1,(T+TMargin)+Counter,left(Mes,R-L-1),Color.T_Button.Deact_B);
        end;
    ShowScr;
    end;

destructor  toTrigger.Uninstall;
    begin
    if Not Installed then exit;
    Undefine;
    Installed:= false;
    end;

constructor toRadio.Install(Mem:  tMemory);
    begin
    Installed:= false;
    Define(Mem,sizeof(tRadioElem));
    if not InitMemory then exit;
    SetPosition(1,1,80,25);
    LMargin:= 0;
    TMargin:= 0;
    SFrame:= Double;
    Title:= '';
    AllElem:= 0;
    CurElem:= 0;
    Res:= 1;
    Installed:= true;
    end;

procedure   toRadio.SetPosition(LE,TE,RE,BE:  byte);
    begin
    if (TE< 1) or (BE> 25) or (LE< 1) or (RE> 80) then exit;
    if (BE-TE< 3) or (RE-LE< 5) then exit;
    L:= LE;
    T:= TE;
    R:= RE;
    B:= BE;
    High:= (BE-TE)+1;
    Width:= (RE-LE)+1;
    end;

procedure   toRadio.Call;
    var
        Key:            integer;
        CoordY:         byte;

    begin
    if (not Installed) or (HowManyElem< 2) then exit;
    if (AllElem= 0) or (AllElem> HowManyElem) then
        AllElem:= HowManyElem;
    if CurElem= 0 then CurElem:= 1;
    if Res= 0 then Res:= 1;
    if Res> HowManyElem then Res:= HowManyElem;
    CoordY:= T+TMargin+CurElem;
    while true do
        begin
        Show;
        SetCursorXY(L+LMargin+2,CoordY);
        Key:= DefineKey;
        if Quit(Key) then break;
        case Key of
       CDown:
                begin
                inc(CurElem);
                inc(CoordY);
                if CurElem> AllElem then
                    if Cycle then
                        begin
                        CurElem:= 1;
                        CoordY:= T+TMargin+CurElem;
                        end
                    else
                        begin
                        inc(CurElem,-1);
                        inc(CoordY,-1);
                        end;
                end;
         -72:
                begin
                inc(CurElem,-1);
                inc(CoordY,-1);
                if CurElem< 1 then
                    if Cycle then
                        begin
                        CurElem:= AllElem;
                        CoordY:= T+TMargin+CurElem;
                        end
                    else
                        begin
                        inc(CurElem);
                        inc(CoordY);
                        end;
                end;
          32:  Res:= CurElem;
            end;
        end;
    ReturnCode:= Key;
    end;

procedure   toRadio.Show;
    var
        Counter:        longint;
        Buf:            tRadioElem;

    begin
    frame_(L,T,R,B,SFrame);
    if length(Title)> R-L-3 then
        Title:= left(Title,R-L-3);
    putline(L+(((R-L-1)-length(Title)) div 2)+1,T,Title,Color.Title);
    for Counter:= 1 to AllElem do
        begin
        if not Pick(Counter,Buf) then Continue;
        if (Counter= Res) and (CurElem= Res) then 
          Signal(S_Selected);
        if Counter= CurElem then
            begin
            putline(L+LMargin+1,T+TMargin+Counter,'('+IIF(Counter= Res,#7,' ')+')'+Buf,
                Color.R_Button.Act_B);
            Say(Buf);
            end
        else
            putline(L+LMargin+1,T+TMargin+Counter,'('+IIF(Counter= Res,#7,' ')+')'+Buf,
                Color.R_Button.Deact_B);
        end;
    showscr;
    end;

destructor  toRadio.Uninstall;
    begin
    Undefine;
    Installed:= false;
    end;

constructor toPadMenu.Install(Mem:  tMemory);
    begin
    Define(Mem,sizeof(tPadElem));
    if not InitMemory then exit;
    Cycle:= false;
    Cursor:= false;
    L:= 1;
    T:= 1;
    R:= 80;
    AllElem:= 0;
    CurElem:= 0;
    Installed:= true;
    end;

procedure   toPadMenu.Call;
    var
        Key:            tKeyCode;
        CoordX:         byte;
        Buffer:         tPadElem;
        St,X,Y,OldX:    word;
        Counter:        longint;

    begin
    if (not Installed) or (HowManyElem< 2) or (AllElem< 2) then exit;
    if AllElem> HowManyElem then
        AllElem:= HowManyElem;
    if CurElem< 1 then
        CurElem:= 1;
    if CurElem> AllElem then
        CurElem:= AllElem;
    CoordX:= L;
    if CurElem> 1 then
        for Counter:= 1 to CurElem-1 do
            if Pick(Counter,Buffer) then
                inc(CoordX,Length(Buffer));
    if Cursor then
        setcursor(7,8)
    else
        hidecursor;
    {$IFDEF SV_MOUSE}
    if UseMouse then
        begin
        SetMouseXY((CoordX-1)*8,(T-1)*8);
        //mousescreensize((L-1)*8,(T-1)*8,(R-1)*8,(T-1)*8);
        end;
    {$ENDIF}
    while true do
        begin
        Show;
        SetCursorXY(CoordX,T);
        while not keypressed do
            begin
            DoBackgroundTasks;
            {$IFDEF SV_MOUSE} 
            if not UseMouse then continue;
            OldX:= X;
            mousepositionstatus(@St,@X,@Y);
            if St> 0 then break;
            Pick(CurElem,Buffer);
            if (X/8> OldX/8) and (CurElem< AllElem) and (CoordX+Length(Buffer)< X/8) then
                begin
                inc(CurElem);
                Pick(CurElem-1,Buffer);
                inc(CoordX,Length(Buffer));
                break;
                end;
            if (X/8< OldX/8) and (CurElem> 1) and (CoordX> X/8) then
                begin
                inc(CurElem,-1);
                Pick(CurElem,Buffer);
                inc(CoordX,-Length(Buffer));
                break;
                end;
            {$ENDIF}
            end;
        if keypressed then Key:= definekey;
        {$IFDEF SV_MOUSE}  
        if ((Key= 0) or (St> 0)) and (UseMouse) then
            begin
            MouseButton:= St;
            repeat
                mousepositionstatus(@St,@X,@Y);
            until St= 0;
            if LButton then Key:= CEnter;
            if MButton then Key:= CF1;
            if RButton then Key:= CEsc;
            end;
        {$ENDIF}
        if quit(Key) then break;
        case Key of
      CRight:
                begin
                if CurElem< AllElem then
                    begin
                    inc(CurElem);
                    Pick(CurElem-1,Buffer);
                    inc(CoordX,Length(Buffer));
                    end
                else
                    if Cycle then
                        begin
                        CurElem:= 1;
                        CoordX:= L;
                        end;
                {$IFDEF SV_MOUSE}
                if UseMouse then
                    SetMouseXY((CoordX+1)*8,(T-1)*8);
                {$ENDIF}
                end;
       CLeft:
                begin
                if CurElem> 1 then
                    begin
                    inc(CurElem,-1);
                    Pick(CurElem,Buffer);
                    inc(CoordX,-Length(Buffer));
                    end
                else
                    if Cycle then
                        begin
                        CurElem:= AllElem;
                        CoordX:= L;
                        for Counter:= 1 to AllElem-1 do
                            if Pick(Counter,Buffer) then
                                inc(CoordX,Length(Buffer));
                        end;
                {$IFDEF SV_MOUSE}
                if UseMouse then
                    SetMouseXY((CoordX+1)*8,(T-1)*8);
                {$ENDIF}
                end;
      49..57:  if Key-48<= AllElem then
                begin
                CurElem:= Key-48;
                CoordX:= L;
                if CurElem> 1 then
                    for Counter:= 1 to CurElem-1 do
                        if Pick(Counter,Buffer) then
                            inc(CoordX,Length(Buffer));
                end;
            end;
        end;
    setcursor(7,8);
    ReturnCode:= Key;
    end;

procedure   toPadMenu.Show;
    var
        Counter:        longint;
        Buf:            tPadElem;
        CX:             byte;

    begin
    if (not Installed) or (HowManyElem< 1) then exit;
    CX:= L;
    for Counter:= 1 to AllElem do
        if Pick(Counter,Buf) then
            begin
            if CurElem= Counter then
                begin
                Say(Buf);
                putline(CX,T,Buf,Color.Menu.ActItem);
                end
            else
                putline(CX,T,Buf,Color.Menu.DeactItem);
            inc(CX,length(Buf));
            end;
    showscr;
    end;

procedure   toPadMenu.SetPosition(LE,TE,RE:  byte);
    begin
    L:= LE;
    T:= TE;
    R:= RE;
    end;

procedure   toPadMenu.In_Centr;
    var
        Counter:        longint;
        Buf:            tPadElem;
        Len:            longint;

    begin
    if (not Installed) or (AllElem> HowManyElem) or (HowManyElem< 2) then exit;
    T:= 1;
    Len:= 0;
    for Counter:= 1 to AllElem do
        if Pick(Counter,Buf) then
            inc(Len,length(Buf));
    L:= 1;
    if Len< 80 then
        L:= ((80-Len) div 2) +1;
    R:= 80;
    end;

destructor  toPadMenu.Uninstall;
    begin
    Undefine;
    Installed:= false;
    end;

constructor toChoice.Install(Mem:  tMemory);
    begin
    Define(Mem,sizeof(tChElem));
    if not InitMemory then exit;
    Cursor:= false;
    L:= 1;
    T:= 1;
    R:= 80;
    B:= 25;
    AllElem:= 0;
    CurElem:= 0;
    Talk_Button:= false;
    SFrame:= Double;
    Installed:= true;
    end;

procedure   toChoice.Call;
    var
        CoordX:         byte;
        Buffer:         tChElem;
        Counter:        longint;
        Key:            integer;

    begin
    if (not Installed) or (HowManyElem< 2) or (AllElem< 2) then exit;
    if AllElem> HowManyElem then
        AllElem:= HowManyElem;
    if CurElem< 1 then
        CurElem:= 1;
    if CurElem> AllElem then
        CurElem:= AllElem;
    CoordX:= L+1+LMargin;
    if CurElem> 1 then
        for Counter:= 1 to CurElem-1 do
            if Pick(Counter,Buffer) then
                inc(CoordX,Length(Buffer)+6);
    if Cursor then
        setcursor(7,8)
    else
        hidecursor;
    First:= true;
    while true do
        begin
        Show;
        SetCursorXY(CoordX,B-2);
        Key:= definekey;
        {$IFDEF SV_MOUSE}  
        if (Key= 0) and (UseMouse) then
            begin
            if LButton then Key:= 13;
            if MButton then Key:= -59;
            if RButton then Key:= 27;
            end;
        {$ENDIF}
        if quit(Key) then break;
        case Key of
         -77:  if CurElem< AllElem then
                   begin
                   inc(CurElem);
                   Pick(CurElem-1,Buffer);
                   inc(CoordX,Length(Buffer)+6);
                   end
               else
                   begin
                   CurElem:= 1;
                   CoordX:= L+LMargin+1;
                   end;
         -75:  if CurElem> 1 then
                   begin
                   inc(CurElem,-1);
                   Pick(CurElem,Buffer);
                   inc(CoordX,-(Length(Buffer)+6));
                   end
               else
                   begin
                   CurElem:= AllElem;
                   CoordX:= L+1+LMargin;
                   for Counter:= 1 to AllElem-1 do
                       if Pick(Counter,Buffer) then
                           inc(CoordX,Length(Buffer)+6);
                   end;
          19:  Say(Mess);
            end;
        end;
    setcursor(7,8);
    ReturnCode:= Key;
    end;

procedure   toChoice.Show;
    var
        Counter:        longint;
        C:              byte;
        Buf:            tChElem;
        CX:             byte;
        TC:             byte;
        CShad:          byte;

    begin
    if (not Installed) or (HowManyElem< 1) then exit;
    CShad:= 0;
    CShad:= (Color.Frame shr 4) shl 4;
    inc(CShad,9);
    TC:= Color.Text;
    frame__(L,T,R,B,SFrame,Color.Frame);
    if not Empty(Mess) then
        putline(L+1,T+1+TMargin,Mess,Color.Button.Title);
    CX:= L+1+LMargin;
    for Counter:= 1 to AllElem do
        if Pick(Counter,Buf) then
            begin
            if CurElem= Counter then
                begin
                if Talk_Button then
                    begin
                    Say(Buf);
                    Talk_Button:= false;
                    end;
                if First then
                    begin
                    Say(Mess);
                    First:= false;
                    end
                else
                    Say(Buf);
                putline(CX+1,B-2,Buf,Color.Button.Act_B);
                putline(CX,B-2,'',Color.Button.Act_B);
                putline(CX+length(Buf)+1,B-2,'',Color.Button.Act_B);
                end
            else
                begin
                putline(CX,B-2,' ',Color.Button.Deact_B);
                putline(CX+length(Buf)+1,B-2,' ',Color.Button.Deact_B);
                putline(CX+1,B-2,Buf,Color.Button.Deact_B);
                end;
            putline(CX+1,B-1,replicate(chr(223),Length(Buf)+2),CShad);
            putline(CX+Length(Buf)+2,B-2,chr(220),CShad);
            inc(CX,length(Buf)+6);
            end;
    if CurElem= 0 then
        begin
        putline(L+1+LMargin,B-2,'',Color.Button.Deact_B);
        putline(L+LMargin+length(Buf),B-2,'',Color.Button.Deact_B);
        end;
    showscr;
    Color.Text:= TC;
    end;

procedure   toChoice.SetPosition(LE,TE,RE,BE:  byte);
    begin
    L:= LE;
    T:= TE;
    R:= RE;
    B:= BE;
    end;

procedure   toChoice.In_Centr;
    var
        Counter:        longint;
        Buf:            tChElem;
        Len:            longint;

    begin
    if (not Installed) or (AllElem> HowManyElem) or (HowManyElem< 2) then exit;
    T:= 9;
    Len:= 0;
    for Counter:= 1 to AllElem do
        if Pick(Counter,Buf) then
            inc(Len,length(Buf));
    L:= 1;
    if Len< 80 then
        L:= ((80-Len) div 2) +1;
    R:= 80;
    end;

destructor  toChoice.Uninstall;
    begin
    Undefine;
    Installed:= false;
    end;

function  Yes(Message:  string):  boolean;
    var
        Choice:         toChoice;
        Item:           array[1..2] of tChElem;
        Lft:            byte;

    begin
    Yes:= false;
    Lft:= (80-length(Message)) div 2;
    with Choice do
        begin
        Sorce:= '';
        Install(mem.low);
        if not Installed then exit;
        Item[1]:= '  Да  ';
        Item[2]:= '  Нет  ';
        Add(Item[1]);
        Add(Item[2]);
        AllElem:= HowManyElem;
        Mess:= Message;
        TMargin:= 1;
        LMargin:= ((length(Message)-24) div 2) +1;
        SetPosition(Lft,9,Lft+length(Message)+1,16);
        Clear(Lft,9,Lft+length(Message)+1,16);
        Call;
        if (CurElem= 1) and (ReturnCode= 13) then
            begin
            Say('да+.');
            Yes:= true;
            Uninstall;
            exit;
            end;
        Uninstall;
        end;
    Say('не+т.');
    end;

procedure ShowMessage(M:  string;Hlp_Str:  string);
    var
        TmpScreen:      tScreen;  { для сохранения экрана }
        Key:            integer;  { переменная для клавиши }
        LEdge:          byte;  { левый отступ }
        REdge:          byte;  { правый отступ }
        Old_Color:      byte;  { цвет, который был ранее }
        CShadow:        byte;  { цвет тени }
        C:              byte;  { счетчик }

    begin {ShowMessage} { выводит сообщение, ожидает  ОK }
    TmpScreen:= BufScreen;  { текущий экран в память }
    Old_Color:= Color.Text;  { запоминаем старый цвет }
    CShadow:= 0;  { цвет тени }
    { далее выделение тетрады и повышение ее }
    CShadow:= (Color.Frame shr 4) shl 4;
    inc(CShadow,9);
    Color.Text:= Color.Message;  { переустановка цвета }
    LEdge:= (80-length(M)) div 2;  { подсчет левого края }
    REdge:= (LEdge+length(M))+1;  { подсчет правого края }
    clear(LEdge,9,REdge,16);  { отчистка части экрана }
    Frame__(LEdge,9,REdge,16,Double,Color.Frame);  { рамка }
    putline(LEdge+1,11,M,Color.Button.Title);  { вывод сообщения }
    putline(LEdge+1,14,space(length(M)),Color.Button.Title);  { очищение строки }
    { вывод кнопки }
    putline(37,14,'  Ok   ',Color.Button.Act_B);
    putline(37,15,replicate(chr(223),8),CShadow);
    putline(44,14,chr(220),CShadow);
    for C:= 37 to 43 do
        BufScreen[14,C].Attr:= Color.Button.Act_B;
    putline(36,14,'',Color.Button.Act_B);
    putline(43,14,'',Color.Button.Act_B);
    showscr;
    Say(Trim(M));  { сказать сообщение }
    repeat  { повтор }
        Key:= definekey;
        if Key= CSpace then
            begin
            Say(Trim(M));
            continue;
            end;
        if Key= CF1 then
            begin
            Say(Trim(Hlp_Str)+'.');
            Say('нажми+те э+нтер и+ли эске+йп для+ продолже+ния.');
            continue;
            end;
        if (Key<> cEnter) and (Key<> cEsc) then
            Say('Нажми+те э+нтер.');
    until (Key= CEnter) or (Key= CEsc);
    Color.Text:= Old_Color;  { восстановить цвет }
    BufScreen:= TmpScreen;  { восстановить экран }
    ShowScr;
    Say(OK);  { произнести кнопку }
  end;

procedure ViewLN(X,Y:  byte;Mess:  string;Width:  byte);
    const
        Ofs_Right=      #77;
        Ofs_Left=       #75;

    var
        Key:            tKeyCode;
        OfS:            byte;
        Point:          byte;
        NW:             integer;
        LEd:            byte;
        REd:            byte;

    begin
    ReturnCode:= 0;
    if (not (X in [1..80])) or (not (Y in [1..25])) then
        exit;
    if Width> (80-X)+1 then
        Width:= (80-X)+1;
    if length(Mess)< Width then
        Mess:= Mess +Space(Width-length(Mess));
    OfS:= 1;
    Point:= X;
    if Posit> length(Mess) then
        Posit:= length(Mess);
    if Posit> 0 then
        if Posit< Width+1 then
            Point:= X+Posit;
    while true do
        begin
        PutLine(X,Y,copy(Mess,OfS,Width),Color.Message);
        SetCursorXY(Point,Y);
        ShowScr;
        Key:= DefineKey;
        if Quit(Key) then break;
        case Key of
      CRight:
                begin
                if Point< (X+Width)-1 then
                    inc(Point)
                else
                    begin
                    if length(Mess)> (OfS+Width)-1 then
                        inc(OfS)
                    else
                        Signal(S_Edge);
                    end;
                SaySymb(Mess[OfS+(Point-X)]);
                end;
       CLeft:
                begin
                if Point> X then
                    inc(Point,-1)
                else
                    begin
                    if OfS> 1 then
                        inc(OfS,-1)
                    else
                        Signal(S_Edge);
                    end;
                SaySymb(Mess[OfS+(Point-X)]);
                end;
       CHome:
                begin
                Point:= X;
                OfS:= 1;
                Signal(S_Edge);
                if length(Mess)> 0 then
                    SaySymb(Mess[1]);
                end;
        CEnd:
                begin
                Point:= (X+Width)-1;
                OfS:= (length(Mess)-Width)+1;
                Signal(S_Edge);
                if length(Mess)> 0 then
                    SaySymb(Mess[OfS+(Point-X)]);
                end;
 CCtrl_Right:  if OnlyCtrl then
                begin
                NW:= 0;
                WordLoc(Mess,OfS+(Point-X),NW,Ofs_Right,LEd,REd);
                if (LEd= 0) or (REd= 0) then
                    begin
                    Signal(S_Edge);
                    continue;
                    end;
                Say(copy(Mess,LEd,(REd-LEd)+1));
                if length(Mess)<= Width then
                    Point:= (X+LEd)-1;
                {
                if LEd< OfS+Width then
                    begin
                    Point:= LEd;
                    continue;
                    end;
                if LEd+Width< length(Mess) then
                    begin
                    Point:= X;
                    OfS:= LEd;
                    end
                else
                    begin
                    OfS:= (length(Mess)-Width)+1;
                    Point:= (LEd-OfS)+1;
                    end;
                }
                end;
  CCtrl_Left:  if OnlyCtrl then
                begin
                NW:= 0;
                WordLoc(Mess,OfS+(Point-X),NW,Ofs_Left,LEd,REd);
                if (LEd= 0) or (REd= 0) then
                    begin
                    Signal(S_Edge);
                    continue;
                    end;
                Say(copy(Mess,LEd,(REd-LEd)+1));
                if length(Mess)<= Width then
                    Point:= (X+LEd)-1;
                {
                if LEd> OfS+1 then
                    begin
                    Point:= LEd-OfS;
                    continue;
                    end;
                if LEd+Width< length(Mess) then
                    begin
                    Point:= X;
                    OfS:= LEd;
                    end
                else
                    begin
                    OfS:= (length(Mess)-Width)+1;
                    Point:= (LEd-OfS)+1;
                    end;
                }
                end;
      CSpace:  Say(Mess);
         CF5:  Say(Mess);
            end;
        end;
    Posit:= (OfS+(Point-X))-1;
    ReturnCode:= Key;
    end;

procedure Clr;
    begin
    Clear(1,1,80,25);
    end;

begin
for C:= 1 to 32 do ECode[C]:= 0;
ECode[1]:= CEsc;
ECode[2]:= CEnter;
Posit:= 0;
UseMouse:= MouseReady;
end.
