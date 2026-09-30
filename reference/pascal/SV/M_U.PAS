unit M_U;
{$B-,V-}
{$define external}
interface

procedure GlobMenu;

implementation
uses s_u,p_u,e_u,dialog,speech,mem,transfrm,line,dinamic,keyb,keyboard,hronos,
     {$ifdef internal}
     params,
     {$endif}
     help,various,  cursor,{$IFDEF SV_MOUSE}mouse,{$ENDIF}video,dos,harddisk;
const
  maxavail = $1000000; // FIXME

var
    MF:             byte;
    MV:             byte;
    MB:             byte;
    MM:             byte;
    ML:             byte;
    MW:             byte;
    MS:             byte;
    MH:             byte;
    C:              byte;

procedure SetpGeneral;
    var
        SubMenu:        toPopupMenu;
        Item:           array[1..2] of tPopupElem;

    procedure SetMemory;
        var
            Radio:          toRadio;
            Item:           array[1..3] of tRadioElem;
            Counter:        byte;

        begin
        if (V_Param^.Memory= mem.low) and (maxavail< sizeof(Item)+1) then
            begin
            V_Err(4);
            exit;
            end;
        Context:= 24;
        with Radio do
            begin
            Sorce:= '';
            Install(V_Param^.Memory);
            if not Installed then exit;
            Item[1]:= '  Верхняя';
            Item[2]:= '  Обычная';
            Item[3]:= '  Диск   ';
            for Counter:= 1 to sizeof(Item) div sizeof(Item[1]) do
                if not Add(Item[Counter]) then break;
            AllElem:= HowManyElem;
            Cycle:= V_Param^.CycleMenu;
            LMargin:= 2;
            TMargin:= 1;
            Res:= ord(V_Param^.Memory)+1;
            SetPosition(54,6,71,12);
            Clear(54,6,71,12);
            ECode[3]:= CF1;
            repeat
                Call;
                if ReturnCode= CF1 then
                    Hlp_Viewer^.CallPart(Context)
                else
                    break;
            until false;
            ECode[3]:= 0;
            Uninstall;
            if ReturnCode= CEnter then
                begin
                V_Param^.Memory:= tMemory(Res-1);
                Set_Viewer_Param;
                Say(OK);
                end
            else
                Say(Cancel);
            end;
        end;

    procedure SetVarious;
        label
            Area_1,Area_2,Area_3,Area_4;

        var
            Trig:           toTrigger;
            Item:           array[1..7] of tTrigElem;
            Radio:          toRadio;
            But:            array[1..2] of tRadioElem;
            Path:           string;
            Counter:        byte;
            S_Jump:         string;
            S_Buf:          string;
            N_Jump1:        longint;
            N_Jump2:        longint;
            Err:            word;

        begin
        if (V_Param^.Memory= mem.low) and (maxavail< sizeof(Item)+sizeof(But)+1) then
            begin
            V_Err(4);
            exit;
            end;
        Context:= 25;
        Path:= V_Param^.Temp_Dir;
        setcursor(7,8);
        with Trig do
            begin
            Sorce:= '';
            Install(V_Param^.Memory);
            if not Installed then exit;
            Item[1].Mess:= '  Цикличные меню           ';
            Item[1].Status:= V_Param^.CycleMenu;
            Item[2].Mess:= '  Авто сохранение          ';
            Item[2].Status:= V_Param^.AutoSave;
            Item[3].Mess:= '  Заменять символ табуляции';
            Item[3].Status:= V_Param^.Tab;
            Item[4].Mess:= '  Подтверждение выхода     ';
            Item[4].Status:= V_Param^.ExitConfirm;
            Item[5].Mess:= '  Латинские в русские      ';
            Item[5].Status:= V_Param^.Transform_Lat;
            Item[6].Mess:= '  Непрерывное перемещение  ';
            Item[6].Status:= V_Param^.NoStop;
            Item[7].Mess:= '  Сигнал точного времени   ';
            Item[7].Status:= V_Param^.Exact_Time;
            for Counter:= 1 to sizeof(Item) div sizeof(Item[1]) do
                if not Add(Item[Counter]) then break;
            Title:= '';
            AllElem:= HowManyElem;
            LMargin:= 2;
            TMargin:= 1;
            Cycle:= V_Param^.CycleMenu;
            SetPosition(22,7,77,21);
            end;
        with Radio do
            begin
            Sorce:= '';
            Install(V_Param^.Memory);
            if not Installed then exit;
            But[1]:= '  Слов         ';
            But[2]:= '  Промежудков  ';
            for Counter:= 1 to sizeof(But) div sizeof(But[1]) do
                if not Add(But[Counter]) then break;
            Res:= V_Param^.Local+1;
            Title:= '';
            AllElem:= HowManyElem;
            LMargin:= 35;
            TMargin:= 1;
            Cycle:= V_Param^.CycleMenu;
            SetPosition(22,7,77,21);
            end;
        Clear(22,7,77,21);
        PutLine(62,8,' Локализация ',Color.Title);
        PutLine(27,17,'Временный каталог:',Color.Message);
        PutLine(26,18,Left(Path,24),Color.Message);
        SeparateClass:= #0;
        PutLine(26,20,'Прыжки - '+LToS(V_Param^.Jump_1)+','+LToS(V_Param^.Jump_2),Color.Message);
        SeparateClass:= Sep_C;
        str(V_Param^.Jump_1,S_Buf);
        S_Jump:= S_Buf;
        str(V_Param^.Jump_2,S_Buf);
        S_Jump:= S_Jump+','+S_Buf;
        Radio.Show;
        ECode[3]:= CTab;
        ECode[4]:= CF1;
        ECode[5]:= CShift_Tab;
        repeat
            Area_1:
                Trig.Call;
                if ReturnCode= CF1 then
                    begin
                    Hlp_Viewer^.CallPart(Context);
                    goto Area_1;
                    end;
                if ReturnCode= CShift_Tab then goto Area_4;
                if (ReturnCode= CEsc) or (ReturnCode= CEnter) then break;
            Area_2:
                Say('локализа+ция.');
                Radio.Call;
                if ReturnCode= CF1 then
                    begin
                    Hlp_Viewer^.CallPart(Context);
                    goto Area_2;
                    end;
                if ReturnCode= CShift_Tab then goto Area_1;
                if (ReturnCode= CEsc) or (ReturnCode= CEnter) then break;
            Area_3:
                Say('вре+менный катало+г.');
                Say(Path);
                Posit:= 0;
                repeat
                    EditLn(26,18,Path,68,50);
                    if ReturnCode= CF1 then
                        Hlp_Viewer^.CallPart(Context)
                    else
                        break;
                until false;
                if ReturnCode= CShift_Tab then goto Area_2;
                if (ReturnCode= CEsc) or (ReturnCode= CEnter) then break;
            Area_4:
                Say('прыжки+.');
                Symb_On;
                Say(S_Jump);
                if not V_Param^.ReadBySym then
                    Symb_Off;
                Posit:= 0;
                repeat
                    EditLn(35,20,S_Jump,18,18);
                    if ReturnCode= CEnter then
                        begin
                        val(Left(S_Jump,pos(',',S_Jump)-1),N_Jump1,Err);
                        if Err<> 0 then
                            begin
                            Signal(S_Err);
                            continue;
                            end;
                        val(Right(S_Jump,length(S_Jump)-pos(',',S_Jump)),N_Jump2,Err);
                        if Err<> 0 then
                            begin
                            Signal(S_Err);
                            continue;
                            end;
                        end;
                    if ReturnCode= CF1 then
                        Hlp_Viewer^.CallPart(Context)
                    else
                        break;
                until false;
                if ReturnCode= CShift_Tab then goto Area_3;
                if (ReturnCode= CEsc) or (ReturnCode= CEnter) then break;
        until false;
        ECode[3]:= 0;
        ECode[4]:= 0;
        ECode[5]:= 0;
        if not V_Param^.Cursor then hidecursor;
        if ReturnCode= CEnter then
            begin
            with Trig do
                begin
                for Counter:= 1 to sizeof(Item) div sizeof(Item[1]) do
                    Pick(Counter,Item[Counter]);
                with V_Param^ do
                    begin
                    CycleMenu:= Item[1].Status;
                    AutoSave:= Item[2].Status;
                    Tab:= Item[3].Status;
                    ExitConfirm:= Item[4].Status;
                    Transform_Lat:= Item[5].Status;
                    Temp_Dir:= Path;
                    NoStop:= Item[6].Status;
                    val(Left(S_Jump,pos(',',S_Jump)-1),N_Jump1,Err);
                    if Err= 0 then
                        begin
                        val(Right(S_Jump,length(S_Jump)-pos(',',S_Jump)),N_Jump2,Err);
                        if Err= 0 then
                            begin
                            Jump_1:= N_Jump1;
                            Jump_2:= N_Jump2;
                            end;
                        end;
                    Exact_Time:= Item[7].Status;
                    Local:= Radio.Res-1;
                    end;
                Set_Viewer_Param;
                Say(OK);
                end;
            end
        else
            Say(Cancel);
        Trig.Uninstall;
        Radio.Uninstall;
        end;

    begin
    if (V_Param^.Memory= mem.low) and (maxavail< sizeof(Item)+1) then
        begin
        V_Err(4);
        exit;
        end;
    Context:= 11;
    with SubMenu do
        begin
        Sorce:= '';
        Install(V_Param^.Memory);
        if not Installed then exit;
        Item[1].Elem:= '  Память  ';
        Item[2].Elem:= '  Разное  ';
        for C:= 1 to sizeof(Item) div sizeof(Item[1]) do
            if not Add(Item[C]) then break;
        Cycle:= V_Param^.CycleMenu;
        Cursor:= V_Param^.Cursor;
        AllElem:= HowManyElem;
        SetPosition(57,4,68,7);
        PutLine(57,3,'  Общие      ',Color.Menu.DeactItem);
        ECode[3]:= CF1;
        ECode[4]:= CBack;
        repeat
            Call;
            if ReturnCode= CF1 then
                Hlp_Viewer^.CallPart(Context)
            else
                break;
        until false;
        ECode[3]:= 0;
        ECode[4]:= 0;
        Uninstall;
        if ReturnCode<> CEnter then exit;
        CASE CurElem OF
           1:  SetMemory;
           2:  SetVarious;
            end;
        end;
    end;

procedure SetpInterface;
    var
        Trig:           toTrigger;
        Item:           array[1..7] of tTrigElem;
        Counter:        byte;

    begin
    if (V_Param^.Memory= mem.low) and (maxavail< sizeof(Item)+1) then
        begin
        V_Err(4);
        exit;
        end;
    Context:= 26;
    with Trig do
        begin
        Sorce:= '';
        Install(V_Param^.Memory);
        if not Installed then exit;
        Item[1].Mess:= '  Показывать часы';
        Item[1].Status:= V_Param^.Clock;
        Item[2].Mess:= '  Показывать проценты';
        Item[2].Status:= V_Param^.PerCent;
        Item[3].Mess:= '  Показывать координаты';
        Item[3].Status:= V_Param^.Coord;
        Item[4].Mess:= '  Показывать память';
        Item[4].Status:= V_Param^.MemSize;
        Item[5].Mess:= '  Показывать кодировку';
        Item[5].Status:= V_Param^.ShCode;
        Item[6].Mess:= '  Использовать "мышь"';
        Item[6].Status:= V_Param^.Mouse;
        Item[7].Mess:= '  Показывать курсор';
        Item[7].Status:= V_Param^.Cursor;
        for Counter:= 1 to sizeof(Item) div sizeof(Item[1]) do
            if not Add(Item[Counter]) then break;
        AllElem:= HowManyElem;
        LMargin:= 3;
        TMargin:= 1;
        Cycle:= V_Param^.CycleMenu;
        SetPosition(43,5,76,15);
        Clear(43,5,76,15);
        ECode[3]:= CF1;
        repeat
            Call;
            if ReturnCode= CF1 then
                Hlp_Viewer^.CallPart(Context)
            else
                break;
        until false;
        ECode[3]:= 0;
        if ReturnCode= CEnter then
            begin
            for Counter:= 1 to sizeof(Item) div sizeof(Item[1]) do
                Pick(Counter,Item[Counter]);
            With V_Param^ do
                begin
                Clock:= Item[1].Status;
                PerCent:= Item[2].Status;
                Coord:= Item[3].Status;
                MemSize:= Item[4].Status;
                ShCode:= Item[5].Status;
                Mouse:= Item[6].Status;
                Cursor:= Item[7].Status;
                end;
            Set_Viewer_Param;
            Say(OK);
            end
        else
            Say(Cancel);
        Uninstall;
        end;
    end;

procedure SetpBookMark;
    var
        Trig:           toTrigger;
        Item:           array[1..3] of tTrigElem;
        C:              byte;

    begin
    if (V_Param^.Memory= mem.low) and (maxavail< sizeof(Item)+1) then
        begin
        V_Err(4);
        exit;
        end;
    Context:= 27;
    with Trig do
        begin
        Sorce:= '';
        Install(V_Param^.Memory);
        if not Installed then exit;
        Item[1].Mess:= '  Глобальные закладки';
        Item[1].Status:= V_Param^.SPBM;
        Item[2].Mess:= '  Показывать строку  ';
        Item[2].Status:= V_Param^.ShowLine;
        Item[3].Mess:= '  Автодобавление     ';
        Item[3].Status:= V_Param^.Auto_Ext_BMark;
        for C:= 1 to sizeof(Item) div sizeof(Item[1]) do
            if not Add(Item[C]) then break;
        AllElem:= HowManyElem;
        TMargin:= 1;
        LMargin:= 3;
        Cycle:= V_Param^.CycleMenu;
        SetPosition(43,6,74,12);
        Clear(43,6,74,12);
        ECode[3]:= CF1;
        repeat
            Call;
            if ReturnCode= CF1 then
                Hlp_Viewer^.CallPart(Context)
            else
                break;
        until false;
        ECode[3]:= 0;
        if ReturnCode= CEnter then
            begin
            for C:= 1 to sizeof(Item) div sizeof(Item[1]) do
                Pick(C,Item[C]);
            V_Param^.SPBM:= Item[1].Status;
            V_Param^.ShowLine:= Item[2].Status;
            V_Param^.Auto_Ext_BMark:= Item[3].Status;
            Set_Viewer_Param;
            Say(OK);
            end
        else
            Say(Cancel);
        Uninstall;
        end;
    end;

procedure SetpVoice;
    label
        Area_1,Area_2,Area_3,Area_4;

    var
        Trig:           toTrigger;
        TrItem:         array[1..1] of TTrigElem;
        Radio:          toRadio;
        RdItem:         array[1..4] of tRadioElem;
        VD:             string;
        VTemp:          0..150;
        LE:             byte;
        TE:             byte;
        OldTemp:        0..150;
        OldDictor:      byte;
        OldTalk:        boolean;
        C:              byte;

    begin
    if (V_Param^.Memory= mem.low) and (maxavail< sizeof(TrItem)+sizeof(RdItem)+1) then
        begin
        V_Err(4);
        exit;
        end;
    Context:= 28;
    TE:= 7;
    LE:= 45;
    VD:= V_Param^.Dic_Dir;
    VTemp:= V_Param^.Temp;
    OldTemp:= V_Param^.Temp;
    OldDictor:= V_Param^.Dictor;
    OldTalk:= V_Param^.Talk;
    Clear(LE,TE,LE+31,TE+14);
    with Trig do
        begin
        Sorce:= '';
        Install(V_Param^.Memory);
        if not Installed then exit;
        TrItem[1].Mess:= '  Речь';
        TrItem[1].Status:= V_Param^.Talk;
        Add(TrItem[1]);
        AllElem:= 1;
        LMargin:= 5;
        TMargin:= 1;
        Cycle:= V_Param^.CycleMenu;
        SetPosition(LE,TE,LE+31,TE+14);
        Show;
        end;
    with Radio do
        begin
        Sorce:= '';
        Install(V_Param^.Memory);
        if not Installed then exit;
        RdItem[3]:= '  Мужской баритон';
        RdItem[1]:= '  Мужской тенор';
        RdItem[2]:= '  Женский альт';
        RdItem[4]:= '  Женский сопрано';
        for C:= 1 to sizeof(RdItem) div sizeof(RdItem[1]) do
            if not Add(RdItem[C]) then break;
        AllElem:= HowManyElem;
        TMargin:= 3;
        LMargin:= 5;
        SetPosition(LE,TE,LE+31,TE+14);
        Res:= V_Param^.Dictor+1;
        Show;
        end;
    PutLine(LE+5,TE+9,' Темп - ',Color.Message);
    PutLine(LE+13,TE+9,'   ',Color.Menu.DeactItem);
    PutLine(LE+13,TE+9,LToS(VTemp),Color.Menu.DeactItem);
    PutLine(LE+2,TE+11,'  Путь к дикторским файлам  ',Color.Message);
    PutLine(LE+2,TE+12,Space(28),Color.Text);
    PutLine(LE+2,TE+12,Left(VD,30),Color.Text);
    ECode[3]:= CTab;
    ECode[4]:= CF1;
    ECode[5]:= CShift_Tab;
    repeat
        Area_1:
            repeat
                Trig.call;
                if ReturnCode= CF1 then
                    Hlp_Viewer^.CallPart(Context)
                else
                    break;
            until false;
            if ReturnCode= CShift_Tab then
                goto Area_4;
            if ReturnCode<> CTab then break;
        Area_2:
            repeat
                Radio.call;
                if ReturnCode= CF1 then
                    Hlp_Viewer^.CallPart(Context)
                else
                    break;
            until false;
            if ReturnCode= CShift_Tab then
                goto Area_1;
            if ReturnCode<> CTab then break;
        Area_3:
            Say('те+мп.');
            SetCursorXY(LE+12,TE+9);
            hidecursor;
            repeat
                PutLine(LE+13,TE+9,'   ',Color.Menu.ActItem);
                PutLine(LE+13,TE+9,LToS(VTemp),Color.Menu.ActItem);
                ShowScr;
                V_Param^.Temp:= VTemp;
                Set_Viewer_Param;
                Say(LToS(VTemp));
                while not keypressed do 
                  DoBackgroundTasks;
                while keypressed do
                    begin
                    ReturnCode:= DefineKey;
                    case ReturnCode of
                   CLeft:  if VTemp> 0 then inc(VTemp,-1) else VTemp:= 150;
                  CRight:  if VTemp< 150 then inc(VTemp) else VTemp:= 0;
                   CHome:  VTemp:= 0;
                    CEnd:  VTemp:= 150;
                     CF1:  Hlp_Viewer^.CallPart(Context);
                    CTab:  break;
              CShift_Tab:  break;
                  CEnter:  break;
                    CEsc:  break;
                        end;
                    Beep(30*(VTemp+1),100);
                    // Pause(50000); // ???
                    end;
                if (ReturnCode= CEsc) or (ReturnCode= CEnter) or
                   (ReturnCode= CTab) or (ReturnCode= CShift_Tab) then
                    break;
            until false;
            PutLine(LE+13,TE+9,'   ',Color.Menu.DeactItem);
            PutLine(LE+13,TE+9,LToS(VTemp),Color.Menu.DeactItem);
            setcursor(7,8);
            if ReturnCode= CShift_Tab then
                goto Area_2;
            if ReturnCode<> CTab then break;
        Area_4:
            Say('пу+ть к ди+кторским фа+йлам.');
            Say(VD);
            Color.Text:= Color.Menu.ActItem;
            repeat
                EditLn(LE+2,TE+12,VD,68,28);
                if ReturnCode= CF1 then
                    Hlp_Viewer^.CallPart(Context)
                else
                    break;
            until false;
            PutLine(LE+2,TE+12,Space(28),Color.Text);
            PutLine(LE+2,TE+12,Left(VD,30),Color.Text);
            if ReturnCode= CShift_Tab then
                goto Area_3;
            if ReturnCode<> CTab then break;
    until false;
    ECode[3]:= 0;
    ECode[4]:= 0;
    ECode[5]:= 0;
    if ReturnCode= CEnter then
        begin
        Trig.Pick(1,TrItem[1]);
        V_Param^.Talk:= TrItem[1].Status;
        V_Param^.Dictor:= Radio.Res-1;
        V_Param^.Temp:= VTemp;
        V_Param^.Dic_Dir:= VD;
        Set_Viewer_Param;
        Say(OK);
        end
    else
        begin
        V_Param^.Temp:= OldTemp;
        V_Param^.Dictor:= OldDictor;
        V_Param^.Talk:= OldTalk;
        Set_Viewer_Param;
        Say(Cancel);
        end;
    Trig.Uninstall;
    Radio.Uninstall;
    end;

procedure SetpRead;
    label
        Area_1,Area_2,Area_3;

    var
        Trig:           toTrigger;
        Item:           array[1..8] of tTrigElem;
        Empty_Pause:    string;
        Num:            byte;
        Err:            integer;
        BS:             byte;
        ES:             byte;
        B:              string;
        E:              string;
        C:              byte;

    begin
    if (V_Param^.Memory= mem.low) and (maxavail< sizeof(Item)+1) then
        begin
        V_Err(4);
        exit;
        end;
    Context:= 29;
    str(V_Param^.AOS.BSymb,B);
    str(V_Param^.AOS.ESymb,E);
    str(V_Param^.Empty_Delay,Empty_Pause);
    with Trig do
        begin
        Sorce:= '';
        Install(V_Param^.Memory);
        if not Installed then exit;
        Item[1].Mess:= '  Объявлять пустые строки  ';
        Item[1].Status:= V_Param^.ReadEmpty;
        Item[2].Mess:= '  Объявлять абзацы         ';
        Item[2].Status:= V_Param^.ReadIndent;
        Item[3].Mess:= '  Читать первое слово      ';
        Item[3].Status:= V_Param^.ReadWord;
        Item[4].Mess:= '  Читать все окна          ';
        Item[4].Status:= V_Param^.ReadWinByWin;
        Item[5].Mess:= '  Читать все символы       ';
        Item[5].Status:= V_Param^.ReadBySym;
        Item[6].Mess:= '  Читать всю строку        ';
        Item[6].Status:= V_Param^.ReadAllLine;
        Item[7].Mess:= '  Читать пробел            ';
        Item[7].Status:= V_Param^.ReadSpace;
        Item[8].Mess:= '  Индикация заглавных букв ';
        Item[8].Status:= V_Param^.Capital;
        for C:= 1 to sizeof(Item) div sizeof(Item[1]) do
            if not Add(Item[C]) then break;
        AllElem:= HowManyElem;
        Title:= '';
        TMargin:= 1;
        LMargin:= 3;
        Cycle:= V_Param^.CycleMenu;
        SetPosition(41,8,76,25);
        Clear(41,8,76,25);
        PutLine(43,19,'пауза пустых: '+Empty_Pause,Color.Message);
        PutLine(43,21,'Зона молчания:',Color.Message);
        PutLine(45,22,'Левая граница  -    ',Color.Menu.DEactItem);
        PutLine(45,23,'Правая граница -    ',Color.Menu.DEactItem);
        PutLine(62,22,B,Color.Menu.DEactItem);
        PutLine(62,23,E,Color.Menu.DEactItem);
        ECode[3]:= CTab;
        ECode[6]:= CShift_Tab;
        ECode[7]:= CF1;
        repeat
            Area_1:
                Call;
                if ReturnCode= CF1 then
                    begin
                    Hlp_Viewer^.CallPart(Context);
                    goto Area_1;
                    end;
                if ReturnCode= CShift_Tab then
                    goto Area_3;
                if (ReturnCode= CEnter) or (ReturnCode= CEsc) then
                    break;
            Area_2:
                Say('Па+уза пусты+х.');
                Say(Empty_Pause);
                EditLn(57,19,Empty_Pause,3,3);
                if ReturnCode= CF1 then
                    begin
                    Hlp_Viewer^.CallPart(Context);
                    goto Area_2;
                    end;
                if ReturnCode= CEsc then break;
                if ReturnCode= CEnter then
                    begin
                    val(Empty_Pause,Num,Err);
                    if (Err= 0) and (Num in [0..255]) then
                        break;
                    Signal(S_Err);
                    goto Area_2;
                    end;
                if ReturnCode= CShift_Tab then
                    goto Area_1;
            area_3:
                ECode[4]:= CUp;
                ECode[5]:= CDown;
                Say('зо+на молча+ния.');
                repeat
                    Say('пе+рвый си+мвол.');
                    Say(B);
                    EditLn(62,22,B,3,3);
                    if ReturnCode= CF1 then
                        begin
                        Hlp_Viewer^.CallPart(Context);
                        continue;
                        end;
                    if (ReturnCode= CUp) or (ReturnCode= CDown) then
                        begin
                        Say('после+дний си+мвол.');
                        Say(E);
                        repeat
                            EditLn(62,23,E,3,3);
                            if ReturnCode= CF1 then
                                Hlp_Viewer^.CallPart(Context)
                            else
                                break;
                        until false;
                        end;
                until (ReturnCode= CTab) or (ReturnCode= CEnter) or
                    (ReturnCode= CEsc) or (ReturnCode= CShift_Tab);
                ECode[4]:= 0;
                ECode[5]:= 0;
                PutLine(62,22,B,Color.Menu.DEactItem);
                PutLine(62,23,E,Color.Menu.DEactItem);
                if (ReturnCode= CEnter) or (ReturnCode= CEsc) then
                    break;
                if ReturnCode= CShift_Tab then
                    goto Area_2;
        until (ReturnCode= CEnter) or (ReturnCode= CEsc);
        ECode[3]:= 0;
        ECode[6]:= 0;
        ECode[7]:= 0;
        if ReturnCode= CEnter then
            begin
            for C:= 1 to sizeof(Item) div sizeof(Item[1]) do
                Pick(C,Item[C]);
            with V_Param^ do
                begin
                ReadEmpty:= Item[1].Status;
                ReadIndent:= Item[2].Status;
                ReadWord:= Item[3].Status;
                ReadWinByWin:= Item[4].Status;
                ReadBySym:= Item[5].Status;
                ReadAllLine:= Item[6].Status;
                ReadSpace:= Item[7].Status;
                Capital:= Item[8].Status;
                end;
            val(Empty_Pause,Num,Err);
            if Err= 0 then
                V_Param^.Empty_Delay:= Num;
            val(B,BS,Err);
            if Err= 0 then
                V_Param^.AOS.BSymb:= BS;
            val(E,ES,Err);
            if Err= 0 then
                V_Param^.AOS.ESymb:= ES;
            Set_Viewer_Param;
            Say(OK);
            end
        else
            Say(Cancel);
        Uninstall;
        end;
    end;

procedure SetpSound;
    var
        Trig:           toTrigger;
        Item:           array[1..4] of tTrigElem;
        C:              byte;

    begin
    if (V_Param^.Memory= mem.low) and (maxavail< sizeof(Item)+1) then
        begin
        V_Err(4);
        exit;
        end;
    Context:= 30;
    with Trig do
        begin
        Sorce:= '';
        Install(V_Param^.Memory);
        if not Installed then exit;
        Item[1].Mess:= '  Звуковое сопровождение  ';
        Item[1].Status:= V_Param^.Sound;
        Item[2].Mess:= '  Звук заголовка          ';
        Item[2].Status:= V_Param^.EmptyBell;
        Item[3].Mess:= '  Звук конца текста       ';
        Item[3].Status:= V_Param^.BOE;
        Item[4].Mess:= '  Звук:  "следующее окно"';
        Item[4].Status:= V_Param^.Sep_Win;
        for C:= 1 to sizeof(Item) div sizeof(Item[1]) do
            if not Add(Item[C]) then break;
        AllElem:= HowManyElem;
        Title:= '';
        LMargin:= 3;
        TMargin:= 1;
        Cycle:= V_Param^.CycleMenu;
        SetPosition(41,9,78,16);
        Clear(41,9,78,16);
        ECode[3]:= CF1;
        repeat
            Call;
            if ReturnCode= CF1 then
                Hlp_Viewer^.CallPart(Context)
            else
                break;
        until false;
        ECode[3]:= 0;
        if ReturnCode= CEnter then
            begin
            for C:= 1 to sizeof(Item) div sizeof(Item[1]) do
                Pick(C,Item[C]);
            With V_Param^ do
                begin
                Sound:= Item[1].Status;
                EmptyBell:= Item[2].Status;
                BOE:= Item[3].Status;
                Sep_Win:= Item[4].Status;
                end;
            Set_Viewer_Param;
            Say(OK);
            end
        else
            Say(Cancel);
        Uninstall;
        end;
    end;

procedure SetpAlarm;
    label
        Area_1,Area_2,Area_3;

    var
        Menu_Alm:       toPopupMenu;
        Item:           array[1..3] of tPopupElem;
        Trig:           toTrigger;
        Button:         array[1..2] of tTrigElem;
        Time_Str:       string[10];
        Alm_Mess:       string[72];
        TmpScreen:      tScreen;
        C:              byte;

    begin
    if (V_Param^.Memory= mem.low) and (maxavail< sizeof(Item)+sizeof(Button)+1) then
        begin
        V_Err(4);
        exit;
        end;
    with Trig do
        begin
        Sorce:= '';
        Install(V_Param^.Memory);
        if not Installed then exit;
        Cycle:= V_Param^.CycleMenu;
        end;
    with Menu_Alm do
        begin
        Sorce:= '';
        Install(V_Param^.Memory);
        if not Installed then exit;
        Item[1].Elem:= '  Первый     ';
        Item[2].Elem:= '  Второй     ';
        Item[3].Elem:= '  Третий     ';
        for C:= 1 to sizeof(Item) div sizeof(Item[1]) do
            Add(Item[C]);
        AllElem:= HowManyElem;
        Cycle:= V_Param^.CycleMenu;
        Cursor:= V_Param^.Cursor;
        In_Centr;
        end;
    ECode[3]:= CF1;
    ECode[4]:= CShift_Tab;
    repeat
        Context:= 31;
        ECode[6]:= CBack;
        Menu_Alm.Call;
        if (ReturnCode= CEsc) or (ReturnCode= CBack) then break;
        ECode[6]:= 0;
        if ReturnCode= CF1 then
            begin
            Hlp_Viewer^.CallPart(Context);
            continue;
            end;
        with V_Param^.Config.Alarm[Menu_Alm.CurElem] do
            begin
            Time_Str:= Tme;
            Alm_Mess:= Message;
            Button[1].Mess:= '  Будильник активизирован ';
            Button[1].Status:= Status;
            Button[2].Mess:= '  Постоянная работа       ';
            Button[2].Status:= EveryOnce;
            end;
        Context:= 35;
        with Trig do
            begin
            CleanMemory;
            for C:= 1 to sizeof(Button) div sizeof(Button[1]) do
                Add(Button[C]);
            AllElem:= HowManyElem;
            Title:= Item[Menu_Alm.CurElem].Elem;
            LMargin:= 5;
            TMargin:= 1;
            SetPosition(21,8,60,18);
            Clear(21,8,60,18);
            PutLine(22,13,' Время - '+Time_Str,Color.Message);
            PutLine(22,15,'         Сообщение будильника         '+Time_Str,Color.Message);
            TmpScreen:= BufScreen;
            ECode[4]:= CTab;
            ECode[5]:= CF1;
            repeat
                Area_1:
                    Call;
                    CurElem:= 0;
                    Show;
                    if ReturnCode= CF1 then
                        begin
                        Hlp_Viewer^.CallPart(Context);
                        goto Area_1;
                        end;
                    if (ReturnCode= CEnter) or (ReturnCode= CEsc) then
                        break;
                    if ReturnCode= CShift_Tab then
                        goto Area_3;
                area_2:
                        Say('вре+мя.');
                        Say(Time_Str);
                        PutLine(22,13,' Время - '+Time_Str,Color.Title);
                        EditLn(31,13,Time_Str,5,6);
                        PutLine(22,13,' Время - '+Time_Str,Color.Message);
                        if ReturnCode= CF1 then
                            begin
                            Hlp_Viewer^.CallPart(Context);
                            goto Area_2;
                            end;
                    if (ReturnCode= CEnter) or (ReturnCode= CEsc) then
                        break;
                    if ReturnCode= CShift_Tab then
                        goto Area_1;
                Area_3:
                    Say('Сообще+ние буди+льника.');
                    Say(Alm_Mess);
                    PutLine(22,15,'         Сообщение будильника         '+Time_Str,Color.Title);
                    Posit:= 0;
                    EditLn(22,16,Alm_Mess,255,37);
                    PutLine(22,15,'         Сообщение будильника         '+Time_Str,Color.Message);
                    if ReturnCode= CF1 then
                        begin
                        Hlp_Viewer^.CallPart(Context);
                        goto Area_3;
                        end;
                    if (ReturnCode= CEnter) or (ReturnCode= CEsc) then
                        break;
                    if ReturnCode= CShift_Tab then
                        goto Area_2;
            until (ReturnCode= CEnter) or (ReturnCode= CEsc);
            ECode[4]:= 0;
            BufScreen:= TmpScreen;
            ShowScr;
            if ReturnCode= CEnter then
                begin
                Say(OK);
                with V_Param^.Config.Alarm[Menu_Alm.CurElem] do
                    begin
                    for C:= 1 to sizeof(Button) div sizeof(Button[1]) do
                        Trig.Pick(C,Button[C]);
                    Tme:= Time_Str;
                    Message:= Alm_Mess;
                    Status:= Button[1].Status;
                    EveryOnce:= Button[2].Status;
                    end;
                end
            else
                Say(Cancel);
            end;
    until false;
    ECode[3]:= 0;
    ECode[4]:= 0;
    ECode[5]:= 0;
    Trig.Uninstall;
    Menu_Alm.Uninstall;
    end;

procedure SetpStartup;
    var
        Trig:           toTrigger;
        Item:           array[1..9] of tTrigElem;
        WSL:            byte;
        S_WSL:          string[3];
        T_WSL:          integer;
        Code:           integer;

    begin
    if (V_Param^.Memory= mem.low) and (maxavail< sizeof(Item)+1) then
        begin
        V_Err(4);
        exit;
        end;
    with Trig do
        begin
        Sorce:= '';
        Install(V_Param^.Memory);
        if not Installed then exit;
        Item[1].Mess:= '  Контроль отступа         ';
        Item[1].Status:= V_Param^.Indent_Control;
        Item[2].Mess:= '  Контроль баз данных      ';
        Item[2].Status:= V_Param^.DBF_Control;
        Item[3].Mess:= '  Контроль архивов         ';
        Item[3].Status:= V_Param^.Arc_Control;
        Item[4].Mess:= '  Контроль html-файлов     ';
        Item[4].Status:= V_Param^.Htm_Control;
        Item[5].Mess:= '  Сохранять ссылки в html  ';
        Item[5].Status:= V_Param^.Html_Link;
        Item[6].Mess:= '  Контроль файлов  Word 97 ';
        Item[6].Status:= V_Param^.Doc_Control;
        Item[7].Mess:= '  Восстанавливать позицию  ';
        Item[7].Status:= V_Param^.Last_Posit;
        Item[8].Mess:= '  Автоопределение кодировки';
        Item[8].Status:= V_Param^.AutoDetect_Code;
        Item[9].Mess:= '  Автозапуск чтения';
        Item[9].Status:= V_Param^.Startup_Read_OnStart;
        for C:= 1 to sizeof(Item) div sizeof(Item[1]) do
            Add(Item[C]);
        AllElem:= HowManyElem;
        Cycle:= V_Param^.CycleMenu;
        Title:= '';
        LMargin:= 3;
        TMargin:= 1;
        SetPosition(41,10,78,23);
        Clear(41,10,78,23);
        WSL:= V_Param^.Word97_StLen;
        str(WSL,S_WSL);
        PutLine(42,21,' Длина строки  Word 97  - '+S_WSL,Color.Message);
        ECode[3]:= CF1;
        ECode[4]:= CTab;
        ECode[5]:= CShift_Tab;
        repeat
            Call;
            if ReturnCode= CF1 then
                begin
                Hlp_Viewer^.CallPart(Context);
                continue;
                end;
            if (ReturnCode= CTab) or (ReturnCode= CShift_Tab) then
                begin
                repeat
                    Say('длина+ строки+  word 97  - '+S_WSL);
                    EditLn(68,21,S_WSL,3,3);
                    if ReturnCode= CEnter then
                        begin
                        val(S_WSL,T_WSL,Code);
                        if (Code= 0) and (T_WSL in [24..250]) then
                            WSL:= T_WSL
                        else
                            begin
                            Signal(S_Err);
                            continue;
                            end;
                        end;
                    if ReturnCode= CF1 then
                        Hlp_Viewer^.CallPart(Context)
                    else
                        break;
                until false;
                end;
        until (ReturnCode= CEnter) or (ReturnCode= CEsc);
        ECode[3]:= 0;
        ECode[4]:= 0;
        ECode[5]:= 0;
        if ReturnCode= CEnter then
            begin
            for C:= 1 to sizeof(Item) div sizeof(Item[1]) do
                Pick(C,Item[C]);
            with V_Param^ do
                begin
                Indent_Control:= Item[1].Status;
                DBF_Control:= Item[2].Status;
                Arc_Control:= Item[3].Status;
                Htm_Control:= Item[4].Status;
                Html_Link:= Item[5].Status;
                Doc_Control:= Item[6].Status;
                Last_Posit:= Item[7].Status;
                AutoDetect_Code:= Item[8].Status;
                Startup_Read_OnStart:= Item[9].Status;
                Word97_StLen:= WSL;
                end;
            Set_Viewer_Param;
            Say(OK);
            end
        else
            Say(Cancel);
        Uninstall;
        end;
    end;

procedure SetpOutLook;
    var
        Radio:          toRadio;
        R_But:          array[1..5] of tRadioElem;
        Trig:           toTrigger;
        Item:           tTrigElem;
        XLT_File:       string;
        BEdge:          byte;
        HMI:            byte;
        D:              dirstr;
        N:              namestr;
        E:              extstr;

    begin
    if (V_Param^.Memory= mem.low) and (maxavail< sizeof(Item)+sizeof(R_But)+1) then
        begin
        V_Err(4);
        exit;
        end;
    XLT_File:= V_Param^.User_Decode;
    BEdge:= 23;
    with Radio do
        begin
        Sorce:= '';
        Install(V_Param^.Memory);
        if not Installed then exit;
        HMI:= 4;
        R_But[1]:= '  Обычный    ';
        R_But[2]:= '  WINDOWS 866';
        R_But[3]:= '  KOI 8 r    ';
        R_But[4]:= '  utf 8      ';
        if not Empty(V_Param^.User_Decode) then
            begin
            for C:= 1 to HMI do
                R_But[C]:= R_But[C]+Space(9);
            fsplit(V_Param^.User_Decode,D,N,E);
            R_But[5]:= '  Польз.  '+N+IIF(E= '.','',E)+' ';
            HMI:= 5;
            inc(BEdge);
            end;
        for C:= 1 to HMI do
            if not Add(R_But[C]) then break;
        AllElem:= HowManyElem;
        Cycle:= V_Param^.CycleMenu;
        LMargin:= 3;
        TMargin:= 1;
        Res:= V_Param^.Mode +1;
        setposition(45,11,77,BEdge)
        end;
    with Trig do
        begin
        Sorce:= '';
        Install(V_Param^.Memory);
        if not Installed then exit;
        Item.Mess:= '  Quonted printable  ';
        Item.Status:= V_Param^.Printab;
        Add(Item);
        AllElem:= 1;
        Cycle:= V_Param^.CycleMenu;
        Title:= '';
        LMargin:= 3;
        TMargin:= BEdge-14;
        SetPosition(45,11,77,BEdge);
        end;
    Clear(45,11,77,BEdge);
    Trig.Show;
    PutLine(50,BEdge-5,'  Файл перекодировки  ',Color.Message);
    PutLine(46,BEdge-4,Left(XLT_File,31),Color.Message);
    Context:= 23;
    ECode[3]:= CF1;
    ECode[4]:= CTab;
    repeat
        Radio.Call;
        if ReturnCode= CF1 then
            begin
            Hlp_Viewer^.CallPart(Context);
            ReturnCode:= 0;
            continue;
            end;
        if ReturnCode= CTab then
            begin
            Say('фа+йл перекодиро+вки.');
            Say(Xlt_File);
            Posit:= 0;
            repeat
                EditLn(46,BEdge-4,XLT_File,68,30);
                if ReturnCode= CEnter then
                    begin
                    if Empty(XLT_File) then
                        begin
                        if V_Param^.Mode= 4 then
                            V_Param^.Mode:= 0;
                        break;
                        end;
                    if not File_Exists(XLT_File) then
                        begin
                        Signal(S_Err);
                        Say('фа+йл не+ существу+ет.');
                        continue;
                        end;
                    end;
                if ReturnCode= CF1 then
                    Hlp_Viewer^.CallPart(Context)
                else
                    break;
            until false;
            end;
        if ReturnCode= CTab then
            repeat
                Trig.Call;
                if ReturnCode= CF1 then
                    Hlp_Viewer^.CallPart(Context)
                else
                    break;
            until false;
    until (ReturnCode= CEnter) or (ReturnCode= CEsc);
    ECode[3]:= 0;
    ECode[4]:= 0;
    if ReturnCode= CEnter then
        begin
        Trig.Pick(1,Item);
        with V_Param^ do
            begin
            Mode:= Radio.Res-1;
            Printab:= Item.Status;
            User_Decode:= XLT_File;
            Say(OK);
            if (Empty(User_Decode)) and (Mode= 4) then
                begin
                Mode:= 0;
                Say('Сме+на кодиро+вки.');
                ReadCode;
                end;
            end;
        end
    else
        Say(Cancel);
    Trig.Uninstall;
    Radio.Uninstall;
    end;
{
procedure SetpLang;
    var
        Menu_Obj:       toPopupMenu;
        Menu_Clr:       toPopupMenu;
        Menu_Bck:       toPopupMenu;
        Objects:        array[0..$C] of tPopupElem;
        Colors:         array[0..$F] of tPopupElem;
        C:              byte;

    begin
    with Menu_Obj do
        begin
        Sorce:= '';
        Install(V_Param^.Memory);
        if not Installed then exit;
        Cursor:= V_Param^.Cursor;
        Title:= ' Объекты ';
        SetPosition(3,3,34,17);
        end;
    with Menu_Clr do
        begin
        Sorce:= '';
        Install(V_Param^.Memory);
        if not Installed then exit;
        Cursor:= V_Param^.Cursor;
        Title:= ' Цвет ';
        SetPosition(36,5,58,22);
        end;
    with Menu_Bck do
        begin
        Sorce:= '';
        Install(V_Param^.Memory);
        if not Installed then exit;
        Cursor:= V_Param^.Cursor;
        Title:= ' Фон ';
        SetPosition(59,5,80,22);
        end;
    Objects[$0].Elem:= '  Текст                       ';
    Objects[$1].Elem:= '  Заголовок                   ';
    Objects[$2].Elem:= '  Сообщение                   ';
    Objects[$3].Elem:= '  Рамка                       ';
    Objects[$4].Elem:= '  Часы                        ';
    Objects[$5].Elem:= '  Меню - Активный элемент     ';
    Objects[$6].Elem:= '  Меню - Не активный элемент  ';
    Objects[$7].Elem:= '  Меню - Рамка                ';
    Objects[$8].Elem:= '  Меню - Заголовок            ';
    Objects[$9].Elem:= '  Кнопка - Строка             ';
    Objects[$A].Elem:= '  Кнопка - Активная           ';
    Objects[$B].Elem:= '  Кнопка - Не активная        ';
    Objects[$C].Elem:= '  Кнопка - Рамка              ';
    Colors[$0].Elem:= '  Черный             ';
    Colors[$1].Elem:= '  Синий              ';
    Colors[$2].Elem:= '  Зеленый            ';
    Colors[$3].Elem:= '  Голубой            ';
    Colors[$4].Elem:= '  Красный            ';
    Colors[$5].Elem:= '  Фиолетовый         ';
    Colors[$6].Elem:= '  Коричневый         ';
    Colors[$7].Elem:= '  Светло-серый       ';
    Colors[$8].Elem:= '  Темно-серый        ';
    Colors[$9].Elem:= '  Светло-синий       ';
    Colors[$A].Elem:= '  Светло-зеленый     ';
    Colors[$B].Elem:= '  Светло-голубой     ';
    Colors[$C].Elem:= '  Светло-красный     ';
    Colors[$D].Elem:= '  Светло-фиолетовый  ';
    Colors[$E].Elem:= '  Желтый             ';
    Colors[$F].Elem:= '  Белый              ';
    with Menu_Obj do
        begin
        for C:= 0 to $C do
            Add(Objects[C]);
        AllElem:= HowManyElem;
        Show;
        end;
    with Menu_Clr do
        begin
        for C:= 0 to $F do
            Add(Colors[C]);
        AllElem:= HowManyElem;
        CurElem:= LTetr(Color.Text);
        Show;
        end;
    with Menu_Bck do
        begin
        for C:= 0 to $F do
            Add(Colors[C]);
        AllElem:= HowManyElem;
        CurElem:= HTetr(Color.Text);
        Show;
        end;
    showscr;
    ECode[3]:= CTab;
    ECode[4]:= CF1;
    repeat
        Menu_Obj.Call;
        if ReturnCode= CTab then
            Menu_Clr.Call;
        if ReturnCode= CTab then
            Menu_Bck.Call;
    until (ReturnCode= CEnter) or (ReturnCode= CEsc);
    ECode[3]:= 0;
    ECode[4]:= 0;
    if ReturnCode= CEnter then
        begin
        Color:= V_Param^.SV_Color;
        Say(OK);
        end
    else
        begin
        V_Param^.SV_Color:= Color;
        Say(Cancel);
        end;
    Menu_Obj.Uninstall;
    Menu_Clr.Uninstall;
    Menu_Bck.Uninstall;
    end;
}
function  Menu_File:  byte;
    var
        SubMenu:        toPopupMenu;
        Item:           array[1..4] of tPopupElem;

    begin
    if (V_Param^.Memory= mem.low) and (maxavail< sizeof(Item)+1) then
        begin
        V_Err(4);
        exit;
        end;
    Context:= 3;
    Menu_File:= 10;
    with SubMenu do
        begin
        Sorce:= '';
        Install(V_Param^.Memory);
        if not Installed then exit;
        Item[1].Elem:= '  Открыть     ';
        Item[2].Elem:= '  Закрыть     ';
        Item[3].Elem:= '  Статистика  ';
        Item[4].Elem:= '  Выход       ';
        for C:= 1 to sizeof(Item) div sizeof(Item[1]) do
            if not Add(Item[C]) then break;
        Cycle:= V_Param^.CycleMenu;
        Cursor:= V_Param^.Cursor;
        AllElem:= HowManyElem;
        SetPosition(2,2,17,7);
        CurElem:= MF;
        ECode[3]:= CLeft;
        ECode[4]:= CRight;
        ECode[5]:= CF1;
        ECode[6]:= CBack;
        repeat
            Call;
            if ReturnCode= CF1 then
                Hlp_Viewer^.CallPart(Context)
            else
                break;
        until false;
        ECode[3]:= 0;
        ECode[4]:= 0;
        ECode[5]:= 0;
        ECode[6]:= 0;
        MF:= CurElem;
        Uninstall;
        case ReturnCode of
       CLeft:  Menu_File:= 8;
      CRight:  Menu_File:= 2;
        CEsc:  Menu_File:= 0;
       CBack:  Menu_File:= 0;
            end;
        if ReturnCode<> CEnter then
            exit;
        CASE CurElem OF
           1:  Load_New_File;
           2:  Close_Win;
           3:  Statistics;
           4:
                begin
                if V_Param^.ExitConfirm then
                    if not Yes('     Выйти из программы?     ') then exit;
                SubMenu.Uninstall;
                FOR c:= 1 TO 9 DO
                    if Viewer[C]<> nil then
                        Viewer[C]^.Uninstall;
                Stop(0);
                end;
            end;
        end;
    end;

function  Menu_Voic:  byte;
    var
        SubMenu:        toPopupMenu;
        Item:           array[1..3] of tPopupElem;

    begin
    if (V_Param^.Memory= mem.low) and (maxavail< sizeof(Item)+1) then
        begin
        V_Err(4);
        exit;
        end;
    Context:= 4;
    Menu_Voic:= 10;
    with SubMenu do
        begin
        Sorce:= '';
        Install(V_Param^.Memory);
        if not Installed then exit;
        Item[1].Elem:= '  Весь текст  ';
        Item[2].Elem:= '  Строку      ';
        Item[3].Elem:= '  Блок        ';
        for C:= 1 to sizeof(Item) div sizeof(Item[1]) do
            if not Add(Item[C]) then break;
        Cycle:= V_Param^.CycleMenu;
        Cursor:= V_Param^.Cursor;
        AllElem:= HowManyElem;
        SetPosition(7,2,22,6);
        CurElem:= MV;
        ECode[3]:= CLeft;
        ECode[4]:= CRight;
        ECode[5]:= CF1;
        ECode[6]:= CBack;
        repeat
            Call;
            if ReturnCode= CF1 then
                Hlp_Viewer^.CallPart(Context)
            else
                break;
        until false;
        ECode[3]:= 0;
        ECode[4]:= 0;
        ECode[5]:= 0;
        ECode[6]:= 0;
        MV:= CurElem;
        Uninstall;
        case ReturnCode of
       CLeft:  Menu_Voic:= 1;
      CRight:  Menu_Voic:= 3;
        CEsc:  Menu_Voic:= 0;
       CBack:  Menu_Voic:= 0;
            end;
        if ReturnCode<> CEnter then
            exit;
        if Viewer[CWin]=nil then begin {//ss/31.03.2003 17:33:50//}
          Signal(S_err);
          Exit;
        end;
        case CurElem of
           1:  ReadTxt;
           2:  Viewer[CWin]^.ReadLine;
           3:  Block_Read;
            end;
        end;
    end;

function  Menu_Bloc:  byte;
    var
        SubMenu:        toPopupMenu;
        Item:           array[1..6] of tPopupElem;
        L:              byte;
        T:              byte;

    begin
    if (V_Param^.Memory= mem.low) and (maxavail< sizeof(Item)+1) then
        begin
        V_Err(4);
        exit;
        end;
    Context:= 5;
    Menu_Bloc:= 10;
    with SubMenu do
        begin
        Sorce:= '';
        Install(V_Param^.Memory);
        if not Installed then exit;
        Item[1].Elem:= '  Начало           ';
        Item[2].Elem:= '  Конец            ';
        Item[3].Elem:= '  Записать в файл  ';
        Item[4].Elem:= '  Время            ';
        Item[5].Elem:= '  Печать           ';
        Item[6].Elem:= '  Разметить        ';
        for C:= 1 to sizeof(Item) div sizeof(Item[1]) do
            if not Add(Item[C]) then break;
        Cycle:= V_Param^.CycleMenu;
        Cursor:= V_Param^.Cursor;
        AllElem:= HowManyElem;
        SetPosition(14,2,34,9);
        CurElem:= MB;
        ECode[3]:= CLeft;
        ECode[4]:= CRight;
        ECode[5]:= CF1;
        ECode[6]:= CBack;
        repeat
            Call;
            if ReturnCode= CF1 then
                Hlp_Viewer^.CallPart(Context)
            else
                break;
        until false;
        ECode[3]:= 0;
        ECode[4]:= 0;
        ECode[5]:= 0;
        ECode[6]:= 0;
        MB:= CurElem;
        Uninstall;
        case ReturnCode of
       CLeft:  Menu_Bloc:= 2;
      CRight:  Menu_Bloc:= 4;
        CEsc:  Menu_Bloc:= 0;
       CBack:  Menu_Bloc:= 0;
            end;
        if ReturnCode<> CEnter then
            exit;
        if Viewer[CWin]=nil then begin {//ss/31.03.2003 17:33:31//}
          Signal(S_err);
          Exit;
        end;
        case CurElem of
           1:
                begin
                Block_B;
                Say('нача+ло бло+ка.');
                end;
           2:
                begin
                Block_E;
                Say('коне+ц бло+ка.');
                end;
           3:
                begin
                Say('за+пись бло+ка.');
                Block_Write;
                end;
           4:
                begin
                L:= Viewer[CWin]^.L;
                T:= Viewer[CWin]^.T;
                Viewer[CWin]^.L:= 5;
                Viewer[CWin]^.t:= 6;
                Block_Time;
                Viewer[CWin]^.L:= L;
                Viewer[CWin]^.t:= T;
                ClearBuffer;
                end;
           5:
                 begin
                 Say('печа+ть бло+ка.');
                 Print_Block;
                 end;
           6:
                begin
                Block_Hide;
                Say('бло+к разме+чен.');
                end;
            end;
        end;
    end;

function  Menu_BMrk:  byte;
    var
        SubMenu:        toPopupMenu;
        Item:           array[1..2] of tPopupElem;

    begin
    if (V_Param^.Memory= mem.low) and (maxavail< sizeof(Item)+1) then
        begin
        V_Err(4);
        exit;
        end;
    Context:= 6;
    Menu_BMrk:= 10;
    with SubMenu do
        begin
        Sorce:= '';
        Install(V_Param^.Memory);
        if not Installed then exit;
        Item[1].Elem:= '  Список     ';
        Item[2].Elem:= '  Отчистить  ';
        for C:= 1 to sizeof(Item) div sizeof(Item[1]) do
            if Add(Item[C]) then continue;
        AllElem:= HowManyElem;
        Cursor:= V_Param^.Cursor;
        Cycle:= V_Param^.CycleMenu;
        SetPosition(26,2,40,5);
        CurElem:= MM;
        ECode[3]:= CLeft;
        ECode[4]:= CRight;
        ECode[5]:= CF1;
        ECode[6]:= CBack;
        repeat
            Call;
            if ReturnCode= CF1 then
                Hlp_Viewer^.CallPart(Context)
            else
                break;
        until false;
        ECode[3]:= 0;
        ECode[4]:= 0;
        ECode[5]:= 0;
        ECode[6]:= 0;
        Uninstall;
        case ReturnCode of
       CLeft:  Menu_BMrk:= 3;
      CRight:  Menu_BMrk:= 5;
        CEsc:  Menu_BMrk:= 0;
       CBack:  Menu_BMrk:= 0;
            end;
        if ReturnCode<> CEnter then
            exit;
        MM:= CurElem;
        case CurElem of
           1: if Viewer[CWin]<>nil then {//ss/31.03.2003 17:33:06//}
                Viewer[CWin]^.BookMark
              else
                Signal(S_err);
           2:  CleanBMark;
            end;
        end;
    end;

function  Menu_Find:  byte;
    var
        SubMenu:        toPopupMenu;
        Item:           array[1..3] of tPopupElem;

    begin
    if (V_Param^.Memory= mem.low) and (maxavail< sizeof(Item)+1) then
        begin
        V_Err(4);
        exit;
        end;
    Context:= 7;
    Menu_Find:= 10;
    with SubMenu do
        begin
        Sorce:= '';
        Install(V_Param^.Memory);
        if not Installed then exit;
        Item[1].Elem:= '  Начать поиск         ';
        Item[2].Elem:= '  Продолжить поиск     ';
        Item[3].Elem:= '  Перейти к строке...  ';
        for C:= 1 to sizeof(Item) div sizeof(Item[1]) do
            if not Add(Item[C]) then break;
        AllElem:= HowManyElem;
        Cycle:= V_Param^.CycleMenu;
        Cursor:= V_Param^.Cursor;
        setposition(32,2,56,6);
        CurElem:= ML;
        ECode[3]:= CLeft;
        ECode[4]:= CRight;
        ECode[5]:= CF1;
        ECode[6]:= CBack;
        repeat
            Call;
            if ReturnCode= CF1 then
                Hlp_Viewer^.CallPart(Context)
            else
                break;
        until false;
        ECode[3]:= 0;
        ECode[4]:= 0;
        ECode[5]:= 0;
        ECode[6]:= 0;
        ML:= CurElem;
        Uninstall;
        case ReturnCode of
       CLeft:  Menu_Find:= 4;
      CRight:  Menu_Find:= 6;
        CEsc:  Menu_Find:= 0;
       CBack:  Menu_Find:= 0;
            end;
        if ReturnCode<> CEnter then
            exit;
        if Viewer[CWin]=nil then begin {//ss/31.03.2003 17:31:27//}
          Signal(S_err);
          Exit;
        end;
        case CurElem of
        1..2:  Viewer[CWin]^.Find(CurElem= 2);
           3:  Viewer[CWin]^.GotoL;
            end;
        end;
    end;

function  Menu_Wind:  byte;
    var
        SubMenu:        toPopupMenu;
        Item:           array[1..2] of tPopupElem;

    begin
    if (V_Param^.Memory= mem.low) and (maxavail< sizeof(Item)+1) then
        begin
        V_Err(4);
        exit;
        end;
    Context:= 8;
    Menu_Wind:= 10;
    with SubMenu do
        begin
        Sorce:= '';
        Install(V_Param^.Memory);
        if not Installed then exit;
        Item[1].Elem:= '  Список окон   ';
        Item[2].Elem:= '  Размер/сдвиг  ';
        for C:= 1 to sizeof(Item) div sizeof(Item[1]) do
            if not Add(Item[C]) then break;
        AllElem:= HowManyElem;
        Cycle:= V_Param^.CycleMenu;
        Cursor:= V_Param^.Cursor;
        setposition(44,2,61,5);
        CurElem:= MW;
        ECode[3]:= CLeft;
        ECode[4]:= CRight;
        ECode[5]:= CF1;
        ECode[6]:= CBack;
        repeat
            Call;
            if ReturnCode= CF1 then
                Hlp_Viewer^.CallPart(Context)
            else
                break;
        until false;
        ECode[3]:= 0;
        ECode[4]:= 0;
        ECode[5]:= 0;
        ECode[6]:= 0;
        MW:= CurElem;
        Uninstall;
        case ReturnCode of
       CLeft:  Menu_Wind:= 5;
      CRight:  Menu_Wind:= 7;
        CEsc:  Menu_Wind:= 0;
       CBack:  Menu_Wind:= 0;
            end;
        if ReturnCode<> CEnter then
            exit;
        case CurElem of
           1:  WinList;
           2:  if Viewer[CWin]<>nil then Viewer[CWin]^.SetWin else
                 Signal(S_Err); {//ss/31.03.2003 17:30:11//}
            end;
        end;
    end;

function  Menu_Setp:  byte;
    label
        Begin_Menu;

    var
        SubMenu:        toPopupMenu;
        Item:           array[1..10] of tPopupElem;
        TmpScreen:      tScreen;

    begin
    if (V_Param^.Memory= mem.low) and (maxavail< sizeof(Item)+1) then
        begin
        V_Err(4);
        exit;
        end;
    TmpScreen:= BufScreen;
    Context:= 9;
    Menu_Setp:= 10;
    with SubMenu do
        begin
        Sorce:= '';
        Install(V_Param^.Memory);
        if not Installed then exit;
        Item[1].Elem:= '  Общие      ';
        Item[2].Elem:= '  Интерфейс  ';
        Item[3].Elem:= '  Закладки   ';
        Item[4].Elem:= '  Речь       ';
        Item[5].Elem:= '  Чтение     ';
        Item[6].Elem:= '  Звук       ';
        Item[7].Elem:= '  Загрузка   ';
        Item[8].Elem:= '  Вид        ';
        Item[9].Elem:= '  Будильник  ';
        Item[10].Elem:= '  Сохранить  ';
        for C:= 1 to sizeof(Item) div sizeof(Item[1]) do
            if not Add(Item[C]) then break;
        AllElem:= HowManyElem;
        Cycle:= V_Param^.CycleMenu;
        Cursor:= V_Param^.Cursor;
        SetPosition(56,2,70,12);
        CurElem:= MS;
        Begin_Menu:
        BufScreen:= TmpScreen;
        ShowScr;
        ECode[3]:= CLeft;
        ECode[4]:= CRight;
        ECode[5]:= CF1;
        ECode[6]:= CBack;
        repeat
            Call;
            if ReturnCode= CF1 then
                Hlp_Viewer^.CallPart(Context)
            else
                break;
        until false;
        ECode[3]:= 0;
        ECode[4]:= 0;
        ECode[5]:= 0;
        ECode[6]:= 0;
        TmpScreen:= BufScreen;
        MS:= CurElem;
        case ReturnCode of
       CLeft:  Menu_Setp:= 6;
      CRight:  Menu_Setp:= 8;
        CEsc:  Menu_Setp:= 0;
       CBack:  Menu_Setp:= 0;
            end;
        if ReturnCode<> CEnter then
            begin
            Uninstall;
            exit;
            end;
        case CurElem of
           1:
                begin
                SetpGeneral;
                if ReturnCode= CBack then
                    goto Begin_Menu;
                end;
           2:  SetpInterface;
           3:  SetpBookMark;
           4:  SetpVoice;
           5:  SetpRead;
           6:  SetpSound;
           7:  SetpStartup;
           8:  SetpOutLook;
            {
            :
                begin
                SetpLang;
                if ReturnCode= CBack then
                    goto Begin_Menu;
                end;
            }
           9:
                begin
                SetpAlarm;
                if ReturnCode= CBack then
                    goto Begin_Menu;
                end;
          10:  SParam;
            end;
        Uninstall;
        end;
    end;

function  Menu_Help:  byte;
    label
        Begin_Menu;

    var
        HlpMenu:        toPopupMenu;
        Item:           array[1..2] of tPopupElem;

    begin
    if (V_Param^.Memory= mem.low) and (maxavail< sizeof(Item)+1) then
        begin
        V_Err(4);
        exit;
        end;
    Context:= 10;
    Menu_Help:= 10;
    with HlpMenu do
        begin
        Sorce:= '';
        Install(V_Param^.Memory);
        if not Installed then exit;
        Item[1].Elem:= '  Клавиши  ';
        Item[2].Elem:= '  Разделы  ';
        for C:= 1 to sizeof(Item) div sizeof(Item[1]) do
            if not Add(Item[C]) then exit;
        AllElem:= HowManyElem;
        Cycle:= V_Param^.CycleMenu;
        Cursor:= V_Param^.Cursor;
        SetPosition(65,2,77,5);
        CurElem:= MH;
        Begin_Menu:
        ECode[3]:= CLeft;
        ECode[4]:= CRight;
        ECode[5]:= CF1;
        ECode[6]:= CBack;
        repeat
            Call;
            if ReturnCode= CF1 then
                Hlp_Viewer^.CallPart(Context)
            else
                break;
        until false;
        ECode[3]:= 0;
        ECode[4]:= 0;
        ECode[5]:= 0;
        ECode[6]:= 0;
        MH:= CurElem;
        Uninstall;
        case ReturnCode of
       CLeft:  Menu_Help:= 7;
      CRight:  Menu_Help:= 1;
        CEsc:  Menu_Help:= 0;
       CBack:  Menu_Help:= 0;
            end;
        if ReturnCode<> CEnter then
            exit;
        case CurElem of
           1:  Hlp_Viewer^.CallPart(12);
           2:
                begin
                HelpTopics;
                if ReturnCode= CBack then
                    goto Begin_Menu;
                end;
            end;
        end;
    end;

procedure GlobMenu;
    var
        Menu:           toPadMenu;
        Item:           array[1..8] of tPadElem;
        NextMenu:       byte;
        SayMenu:        boolean;
        PopMenu:        array[1..8] of string[11];
        TmpScreen:      tScreen;

    begin
    if (V_Param^.Memory= mem.low) and (maxavail< sizeof(Item)+1) then
        begin
        V_Err(4);
        exit;
        end;
    TmpScreen:= BufScreen;
    Context:= 2;
    NextMenu:= 0;
    PopMenu[1]:= 'фа+йл.';
    PopMenu[2]:= 'чита+ть.';
    PopMenu[3]:= 'бло+к.';
    PopMenu[4]:= 'закла+дки.';
    PopMenu[5]:= 'по+иск.';
    PopMenu[6]:= 'о+кна.';
    PopMenu[7]:= 'настро+йки.';
    PopMenu[8]:= 'по+мощь.';
    with Menu do
        begin
        Sorce:= '';
        Install(V_Param^.Memory);
        if not Installed then exit;
        Item[1]:= '  Файл  ';
        Item[2]:= '  Читать  ';
        Item[3]:= '  Блок  ';
        Item[4]:= '  Закладки  ';
        Item[5]:= '  Поиск  ';
        Item[6]:= '  Окна  ';
        Item[7]:= '  Настройки  ';
        Item[8]:= '  Помощь  ';
        for C:= 1 to sizeof(Item) div sizeof(Item[1]) do
            if not Add(Item[C]) then break;
        AllElem:= HowManyElem;
        Cycle:= true;
        Cursor:= V_Param^.Cursor;
        In_Centr;
        CurElem:= EOGM;
        putLine(1,1,Space(80),Color.Menu.DeactItem);
        repeat
            if NextMenu in [1..8] then
                begin
                if SayMenu then
                    Say(PopMenu[NextMenu]);
                SayMenu:= true;
                EOGM:= NextMenu;
                if Viewer[CWin]<>nil then  Viewer[CWin]^.Show; {//ss/31.03.2003 17:31:55//}
                ShowScr;
                end;
            case NextMenu of
               0:
                    begin
                    BufScreen:= TmpScreen;
                    ShowScr;
                    Context:= 2;
                    ECode[3]:= CDown;
                    ECode[4]:= CF1;
                    Call;
                    if ReturnCode= CF1 then
                        begin
                        Hlp_Viewer^.CallPart(Context);
                        continue;
                        end;
                    ECode[3]:= 0;
                    ECode[4]:= 0;
                    PutLine(2,1,MenuString,Color.Menu.DeactItem);
                    if ReturnCode= CEsc then
                        break;
                    NextMenu:= CurElem;
                    SayMenu:= false;
                    TmpScreen:= BufScreen;
                    end;
               1:  NextMenu:= Menu_File;
               2:  NextMenu:= Menu_Voic;
               3:  NextMenu:= Menu_Bloc;
               4:  NextMenu:= Menu_BMrk;
               5:  NextMenu:= Menu_Find;
               6:  NextMenu:= Menu_Wind;
               7:  NextMenu:= Menu_Setp;
               8:  NextMenu:= Menu_Help;
            else
                Signal(S_StartP);
                break;
                end;
            if ReturnCode= CEsc then
                break;
        until false;
        Uninstall;
        if ReturnCode= CEsc then Signal(S_StartP);
        end;
    end;

begin
end.
{

Владимир Довыденков
09/02/2000
  добавление кнопки  "Автодобавление"  в диалоговую область  "Закладки".

16/02/2000
  определена клавиша  backspace -  возврат в предыдущее меню
  escape -  возврат в текст
}
