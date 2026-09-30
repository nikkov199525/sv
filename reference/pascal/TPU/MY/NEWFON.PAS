unit Newfon;

{ Драйвер речи на ядре  newfon_core
  (https://github.com/nikkov199525/newfon_core).

  Модуль подставлен под самый низ речевого тракта  -  туда, где
  SDRVPRIM.SDRVXPApi.INC  раньше разговаривал с  sdrvxpapi.dll,  а та
  через  NTVDM  гоняла  COM-программу драйвера в DOS-машине.  На
  64-разрядной  Windows  этого пути больше нет.

  Выше не меняется ничего:  и  SPEECH.PAS,  и нормализатор текста
  SPICK.U_R_SText  со схлопыванием повторов и названиями символов,  и
  разбор украинско-русского текста  -  всё авторское и работает как
  работало.

  Воспроизведение асинхронное:  Newfon_Play_Begin  запускает и сразу
  возвращает управление, Newfon_Playing  говорит, играет ли ещё.  Это
  нужно затем, чтобы  SText00  мог, как у автора, опрашивать клавиатуру
  и обрывать речь по нажатию.

  Ядро подключается динамически.  Нет  newfon_core.dll  -  Newfon_Ready
  вернёт  false,  и  SPEECH.PAS  поведёт себя ровно так же, как вёл при
  ненайденном драйвере речи  (у автора это была проверка  AdrFon> 0).

  Соответствие параметров:

    диктор  SV                        голос  newfon_core
    0  мужской тенор                  0  male 1
    1  женский альт                   1  female 1
    2  мужской баритон                2  male 2
    3  женский сопрано                3  female 2

    темп  SV           0..150,  0 - самая быстрая, 150 - самая медленная
    темп  newfon_core  0..150,  ровно та же шкала
    значит число идёт насквозь, без пересчёта

  Шкала темпа взята не из догадки:  авторская справка, раздел 28, говорит
  дословно  -  "Темп определяется цифрой от 0 до 150  (0: самая быстрая -
  150: самая медленная)",  и  home  ставит самый быстрый темп, а  end  -
  самый медленный.  У драйвера, что стоял здесь раньше, шкала была та же:
  SDRVPRIM.PAS:57  объявляет  TSpTempo = 0..150,  а  SDRVXPApi.INC:176
  ставит по умолчанию  30  -  ровно столько же, сколько  NEWFON_RATE_DEFAULT.

  Ударение:  SV  ставит  '+'  после ударной гласной  ('загру+жено'),
  ядро ждёт того же  (transcription.c:441),  знак идёт насквозь.

  Кодировка:  внутри  SV  текст в  DOS-866,  ядро принимает  koi8-r,
  перекодировка таблицей  Dos_Koi. }

{$B-,I-,V-}
{$MODE FPC}
{$H-}

interface

const
    Newfon_Lib=     'newfon_core.dll';

    { Настройки драйверного уровня.  Файл лежит рядом с программой.
      Это замена ключам  setup.bat  прежнего драйвера  SDRV:  сам  SV
      их никогда не трогал, они всегда задавались снаружи. }
    Newfon_Cfg=     'newfon.cfg';

    { голоса ядра }
    Newfon_Male_1=       0;
    Newfon_Female_1=     1;
    Newfon_Male_2=       2;
    Newfon_Female_2=     3;

    { темп ядра:  0 - самая быстрая речь, 150 - самая медленная }
    Newfon_Rate_Min=     0;
    Newfon_Rate_Max=     150;
    Newfon_Rate_Default= 30;

    Newfon_Accel_Off=    0;
    Newfon_Accel_Max=    7;
    Newfon_Pause_Max=    255;
    Newfon_Pitch_Default=      50;
    Newfon_Inflection_Default= 50;

    { флаги управления }
    Dec_Sep_Point=        1;
    Dec_Sep_Comma=        2;
    Use_Legacy_Rate_Algo= 8;

    { ядро выдаёт знаковые восьмибитные отсчёты }
    Newfon_Sample_Rate=   10000;

var
    { Где искать библиотеку.  SPEECH.PAS  кладёт сюда  VDirc,  то есть
      "путь к дикторским файлам" из настроек.  Голоса  newfon  вшиты
      в ядро, отдельных файлов не требуют, так что путь нужен только
      затем, чтобы найти  DLL. }
    Newfon_Dirc:    string;

{ Ядро загружено и готово.  Первый вызов пытается загрузить библиотеку.
  Это замена авторской проверки  AdrFon> 0. }
function  Newfon_Ready: boolean;

{ Синтезировать строку  (текст в  DOS-866)  и запустить воспроизведение.
  Управление возвращается сразу.  false  -  сказать нечего либо не вышло. }
function  Newfon_Play_Begin(S: string): boolean;

{ Ещё звучит? }
function  Newfon_Playing: boolean;

{ Оборвать немедленно }
procedure Newfon_Play_Stop;

{ Закончить проигрывание и освободить заголовок.
  Звать обязательно после  Newfon_Play_Begin. }
procedure Newfon_Play_End;

{ Произнести и дождаться конца.  Для простых случаев. }
procedure Newfon_Text(S: string);

{ Выбрать диктора,  0..3.  Замена  SpkSetVoice. }
procedure Newfon_Voice(N: byte);

{ Задать темп,  0..150,  0 - быстрее всего.  Замена  SpkSetTemp. }
procedure Newfon_Tempo(T: byte);

{ Оборвать то, что звучит сейчас }
procedure Newfon_Silence;

implementation

uses windows;

type
    tNewfon_Conf=   record
                        Voice:          longint;
                        Speech_Rate:    longint;
                        Acceleration:   longint;
                        Pitch:          longint;
                        Inflection:     longint;
                        Pause:          longint;
                        Flags:          longint;
                        end;
    pNewfon_Conf=   ^tNewfon_Conf;

    tNewfon_Callback= function(Buffer: pointer;Size: PtrUInt;
                               User_Data: pointer): longint;  cdecl;

const
    { Перекодировка  DOS-866  ->  koi8-r.
      Псевдографика и прочее, чего нет в  koi8-r,  заменяется пробелом;
      украинские буквы  -  ближайшими русскими, так как ядро русское.
      SPEECH.PAS  псевдографику вычищает и сам, эта замена  -  на всякий. }
    Dos_Koi:        array[char] of byte = (
      $00,$01,$02,$03,$04,$05,$06,$07,
      $08,$09,$0A,$0B,$0C,$0D,$0E,$0F,
      $10,$11,$12,$13,$14,$15,$16,$17,
      $18,$19,$1A,$1B,$1C,$1D,$1E,$1F,
      $20,$21,$22,$23,$24,$25,$26,$27,
      $28,$29,$2A,$2B,$2C,$2D,$2E,$2F,
      $30,$31,$32,$33,$34,$35,$36,$37,
      $38,$39,$3A,$3B,$3C,$3D,$3E,$3F,
      $40,$41,$42,$43,$44,$45,$46,$47,
      $48,$49,$4A,$4B,$4C,$4D,$4E,$4F,
      $50,$51,$52,$53,$54,$55,$56,$57,
      $58,$59,$5A,$5B,$5C,$5D,$5E,$5F,
      $60,$61,$62,$63,$64,$65,$66,$67,
      $68,$69,$6A,$6B,$6C,$6D,$6E,$6F,
      $70,$71,$72,$73,$74,$75,$76,$77,
      $78,$79,$7A,$7B,$7C,$7D,$7E,$7F,
      $E1,$E2,$F7,$E7,$E4,$E5,$F6,$FA,
      $E9,$EA,$EB,$EC,$ED,$EE,$EF,$F0,
      $F2,$F3,$F4,$F5,$E6,$E8,$E3,$FE,
      $FB,$FD,$FF,$F9,$F8,$FC,$E0,$F1,
      $C1,$C2,$D7,$C7,$C4,$C5,$D6,$DA,
      $C9,$CA,$CB,$CC,$CD,$CE,$CF,$D0,
      $90,$91,$92,$81,$87,$B2,$B4,$A7,
      $A6,$B5,$A1,$A8,$AE,$AD,$AC,$83,
      $84,$89,$88,$86,$80,$8A,$AF,$B0,
      $AB,$A5,$BB,$B8,$B1,$A0,$BE,$B9,
      $BA,$B6,$B7,$AA,$A9,$A2,$A4,$BD,
      $BC,$85,$82,$8D,$8C,$8E,$8F,$8B,
      $D2,$D3,$D4,$D5,$C6,$C8,$C3,$DE,
      $DB,$DD,$DF,$D9,$D8,$DC,$C0,$D1,
      $B3,$A3,$E5,$C5,$E9,$C9,$F5,$D5,
      $9C,$95,$9E,$96,$4E,$20,$94,$20
      );

    { Диктор  SV  ->  голос ядра.  Порядок из меню "Настройки"/"Речь". }
    Dictor_Voice:   array[0..3] of longint = (
      Newfon_Male_1,      { 0  мужской тенор   }
      Newfon_Female_1,    { 1  женский альт    }
      Newfon_Male_2,      { 2  мужской баритон }
      Newfon_Female_2);   { 3  женский сопрано }

    Chunk_Size=     4096;
    Snd_Grow=       65536;

    { winmm }
    Wave_Mapper=     dword(-1);
    WHDR_Done=       $00000001;
    Wave_Format_PCM= 1;

type
    tWave_Format=   packed record
                        wFormatTag:      word;
                        nChannels:       word;
                        nSamplesPerSec:  dword;
                        nAvgBytesPerSec: dword;
                        nBlockAlign:     word;
                        wBitsPerSample:  word;
                        cbSize:          word;
                        end;
    pWave_Hdr=      ^tWave_Hdr;
    tWave_Hdr=      record
                        lpData:          pchar;
                        dwBufferLength:  dword;
                        dwBytesRecorded: dword;
                        dwUser:          PtrUInt;
                        dwFlags:         dword;
                        dwLoops:         dword;
                        lpNext:          pWave_Hdr;
                        Reserved:        PtrUInt;
                        end;

function  waveOutOpen(Wave_Out: pointer;Device_ID: dword;Format: pointer;
                      Callback,Instance,Flags: PtrUInt): longint;
                      stdcall;  external 'winmm.dll'  name 'waveOutOpen';
function  waveOutPrepareHeader(Wave_Out: PtrUInt;Hdr: pWave_Hdr;
                      Size: longint): longint;
                      stdcall;  external 'winmm.dll'  name 'waveOutPrepareHeader';
function  waveOutUnprepareHeader(Wave_Out: PtrUInt;Hdr: pWave_Hdr;
                      Size: longint): longint;
                      stdcall;  external 'winmm.dll'  name 'waveOutUnprepareHeader';
function  waveOutWrite(Wave_Out: PtrUInt;Hdr: pWave_Hdr;
                      Size: longint): longint;
                      stdcall;  external 'winmm.dll'  name 'waveOutWrite';
function  waveOutReset(Wave_Out: PtrUInt): longint;
                      stdcall;  external 'winmm.dll'  name 'waveOutReset';

var
    { точки входа ядра }
    NF_Config_Init: procedure(Config: pNewfon_Conf);  cdecl;
    NF_Voice_Name:  function(Voice: longint): pchar;  cdecl;
    NF_Transfer:    procedure(Config: pNewfon_Conf;Text: pchar;
                              Wave_Buffer: pointer;Wave_Buffer_Size: PtrUInt;
                              Wave_Consumer: tNewfon_Callback;
                              User_Data: pointer);  cdecl;

    Lib:            hModule;
    Pause_Auto:     boolean;   { pause = -1:  паузы пропорциональны accel }
    Loaded:         boolean;
    Tried:          boolean;
    Tried_Dirc:     string;
    Cfg:            tNewfon_Conf;
    Snd:            pchar;
    Snd_Size:       longint;
    Snd_Len:        longint;
    Chunk:          array[0..Chunk_Size-1] of byte;
    Txt:            array[0..1023] of char;
    Wave_Out:       PtrUInt;
    Hdr:            tWave_Hdr;
    Hdr_Prepared:   boolean;

{ Приёмник звука.  Ядро отдаёт знаковые восьмибитные отсчёты,
  играем шестнадцатибитными  -  так же, как это делает  newfon_speak. }
function  Consumer(Buffer: pointer;Size: PtrUInt;
                   User_Data: pointer): longint;  cdecl;
    var
        Src:            pShortInt;
        Need:           longint;
        C:              longint;
        V:              smallint;

    begin
    Consumer:= 0;
    if Size= 0 then
        exit;
    Need:= Snd_Len +longint(Size)*2;
    if Need> Snd_Size then
        begin
        while Snd_Size< Need do
            inc(Snd_Size,Snd_Grow);
        ReAllocMem(Snd,Snd_Size);
        if Snd= nil then
            begin
            Snd_Size:= 0;
            Snd_Len:= 0;
            Consumer:= 1;
            exit;
            end;
        end;
    Src:= Buffer;
    for C:= 0 to longint(Size)-1 do
        begin
        V:= smallint(Src^)*256;
        Snd[Snd_Len]:= chr(V and $FF);
        Snd[Snd_Len+1]:= chr((V shr 8) and $FF);
        inc(Snd_Len,2);
        inc(Src);
        end;
    end;

function  Open_Wave: boolean;
    var
        Format:         tWave_Format;

    begin
    Open_Wave:= Wave_Out<> 0;
    if Wave_Out<> 0 then
        exit;
    with Format do
        begin
        wFormatTag:= Wave_Format_PCM;
        nChannels:= 1;
        nSamplesPerSec:= Newfon_Sample_Rate;
        wBitsPerSample:= 16;
        nBlockAlign:= 2;
        nAvgBytesPerSec:= Newfon_Sample_Rate*2;
        cbSize:= 0;
        end;
    if waveOutOpen(@Wave_Out,Wave_Mapper,@Format,0,0,0)<> 0 then
        begin
        Wave_Out:= 0;
        exit;
        end;
    Open_Wave:= true;
    end;

function  Newfon_Play_Begin(S: string): boolean;
    var
        C:              longint;
        L:              longint;

    begin
    Newfon_Play_Begin:= false;
    Hdr_Prepared:= false;
    if S= '' then
        exit;
    if not Newfon_Ready then
        exit;
    L:= length(S);
    if L> sizeof(Txt)-1 then
        L:= sizeof(Txt)-1;
    for C:= 1 to L do
        Txt[C-1]:= chr(Dos_Koi[S[C]]);
    Txt[L]:= #0;
    Snd_Len:= 0;
    NF_Transfer(@Cfg,Txt,@Chunk,sizeof(Chunk),@Consumer,nil);
    if Snd_Len= 0 then
        exit;
    if not Open_Wave then
        exit;
    FillChar(Hdr,sizeof(Hdr),0);
    Hdr.lpData:= Snd;
    Hdr.dwBufferLength:= Snd_Len;
    if waveOutPrepareHeader(Wave_Out,@Hdr,sizeof(Hdr))<> 0 then
        exit;
    Hdr_Prepared:= true;
    if waveOutWrite(Wave_Out,@Hdr,sizeof(Hdr))<> 0 then
        begin
        waveOutUnprepareHeader(Wave_Out,@Hdr,sizeof(Hdr));
        Hdr_Prepared:= false;
        exit;
        end;
    Newfon_Play_Begin:= true;
    end;

function  Newfon_Playing: boolean;
    begin
    Newfon_Playing:= (Hdr_Prepared) and ((Hdr.dwFlags and WHDR_Done)= 0);
    end;

procedure Newfon_Play_Stop;
    begin
    if Wave_Out<> 0 then
        waveOutReset(Wave_Out);
    end;

procedure Newfon_Play_End;
    begin
    if Hdr_Prepared then
        begin
        { заголовок нельзя освобождать, пока устройство его держит }
        if (Hdr.dwFlags and WHDR_Done)= 0 then
            Newfon_Play_Stop;
        waveOutUnprepareHeader(Wave_Out,@Hdr,sizeof(Hdr));
        Hdr_Prepared:= false;
        end;
    end;

{ Каталог, где лежит сама программа }
function  Exe_Dirc: string;
    var
        Buf:            array[0..MAX_PATH] of char;
        S:              string;
        C:              longint;

    begin
    Exe_Dirc:= '';
    C:= GetModuleFileName(0,Buf,sizeof(Buf)-1);
    if C<= 0 then
        exit;
    if C> 255 then
        C:= 255;
    SetLength(S,C);
    Move(Buf,S[1],C);
    for C:= length(S) downto 1 do
        if S[C]= '\' then
            begin
            Exe_Dirc:= copy(S,1,C-1);
            exit;
            end;
    end;

{ Прочитать настройки уровня драйвера.

  Ключи и их пределы взяты у прежнего драйвера  SDRV,  раздел
  "readme.txt" про  setup.bat:

    accel  3..13   ускорение темпа речи;  10 - нормальное,
                   4 - максимальное ускорение, 13 - максимальное
                   замедление.  Ядро принимает 1..15 с той же
                   нейтралью 10, так что число идёт насквозь.
    pause  0..255  относительный размер пауз, начальное значение 100.

  Файла нет  -  остаются умолчания, а они равны прежнему поведению. }
procedure Read_Cfg;
    var
        F:              text;
        S:              string;
        Name:           string;
        Num_Str:        string;
        C:              longint;
        N:              longint;
        Err:            integer;

    begin
    S:= Newfon_Dirc;
    if S<> '' then
        if S[length(S)]<> '\' then
            S:= S +'\';
    assign(F,S +Newfon_Cfg);
    {$I-}
    reset(F);
    {$I+}
    if ioresult<> 0 then
        exit;
    while not eof(F) do
        begin
        {$I-}
        readln(F,S);
        {$I+}
        if ioresult<> 0 then
            break;
        C:= pos(';',S);          { точка с запятой  -  примечание }
        if C> 0 then
            S:= copy(S,1,C-1);
        C:= pos('=',S);
        if C= 0 then
            continue;
        Name:= '';
        for N:= 1 to C-1 do
            if S[N]> ' ' then
                Name:= Name +upcase(S[N]);
        Num_Str:= '';
        for N:= C+1 to length(S) do
            if S[N]> ' ' then
                Num_Str:= Num_Str +S[N];
        val(Num_Str,N,Err);
        if Err<> 0 then
            continue;
        if Name= 'ACCEL' then
            Cfg.Acceleration:= N;
        if Name= 'PAUSE' then
            begin
            { -1  -  как у прежнего драйвера:  паузы пропорциональны accel }
            if N< 0 then
                Pause_Auto:= true
            else
                if N<= Newfon_Pause_Max then
                    begin
                    Pause_Auto:= false;
                    Cfg.Pause:= N;
                    end;
            end;
        end;
    close(F);
    ioresult;
    end;

function  Load_Lib: boolean;
    var
        Name:           array[0..MAX_PATH] of char;
        S:              string;

    begin
    Load_Lib:= false;
    S:= Newfon_Dirc;
    if S<> '' then
        begin
        if S[length(S)]<> '\' then
            S:= S +'\';
        S:= S +Newfon_Lib;
        Move(S[1],Name,length(S));
        Name[length(S)]:= #0;
        Lib:= LoadLibrary(Name);
        end
    else
        Lib:= 0;
    if Lib= 0 then
        begin
        Move(Newfon_Lib[1],Name,length(Newfon_Lib));
        Name[length(Newfon_Lib)]:= #0;
        Lib:= LoadLibrary(Name);
        end;
    if Lib= 0 then
        exit;
    pointer(NF_Config_Init):= GetProcAddress(Lib,'newfon_config_init');
    pointer(NF_Voice_Name):=  GetProcAddress(Lib,'newfon_voice_name');
    pointer(NF_Transfer):=    GetProcAddress(Lib,'newfon_transfer');
    if (NF_Config_Init= nil) or (NF_Voice_Name= nil) or (NF_Transfer= nil) then
        begin
        FreeLibrary(Lib);
        Lib:= 0;
        exit;
        end;
    Load_Lib:= true;
    end;

{ Досчитать паузы, если они привязаны к ускорению.
  У прежнего драйвера  SDRV  это было умолчанием  (pause -1):
  "паузы после знаков препинаний пропорциональны значению accel". }
procedure Apply_Pause;
    var
        A:              longint;

    begin
    if not Pause_Auto then
        exit;
    A:= Cfg.Acceleration;
    if (A< 1) or (A> 15) then
        A:= 10;                    { ядро в этом случае берёт нейтраль }
    Cfg.Pause:= (100*A) div 10;
    end;

function  Newfon_Ready: boolean;
    begin
    Newfon_Ready:= Loaded;
    if Loaded then
        exit;
    if (Tried) and (Tried_Dirc= Newfon_Dirc) then
        exit;
    Tried:= true;
    Tried_Dirc:= Newfon_Dirc;
    Loaded:= Load_Lib;
    if Loaded then
        begin
        Read_Cfg;
        Apply_Pause;
        end;
    Newfon_Ready:= Loaded;
    end;

procedure Newfon_Voice(N: byte);
    begin
    if N> 3 then
        N:= 0;
    Cfg.Voice:= Dictor_Voice[N];
    end;

procedure Newfon_Tempo(T: byte);
    begin
    if T> Newfon_Rate_Max then
        T:= Newfon_Rate_Max;
    { шкала у  SV  и у ядра одна и та же, пересчитывать нечего }
    Cfg.Speech_Rate:= T;
    end;

procedure Newfon_Silence;
    begin
    Newfon_Play_Stop;
    end;

procedure Newfon_Text(S: string);
    begin
    if not Newfon_Play_Begin(S) then
        begin
        Newfon_Play_End;
        exit;
        end;
    while Newfon_Playing do
        Sleep(5);
    Newfon_Play_End;
    end;

begin
Lib:= 0;
Loaded:= false;
Tried:= false;
Tried_Dirc:= '';
Hdr_Prepared:= false;
{ По умолчанию ищем библиотеку рядом с самой программой  -  не зависим
  от того, из какого каталога её запустили. }
Newfon_Dirc:= Exe_Dirc;
Wave_Out:= 0;
Snd:= nil;
Snd_Size:= 0;
Snd_Len:= 0;
{ Ровно те значения, что ставит  newfon_config_init.  Вызвать её саму
  здесь нельзя:  библиотека грузится позже, а  Set_Viewer_Param  успевает
  до этого позвать  SetDictor  и  Set_Temp,  и их затирать нельзя. }
FillChar(Cfg,sizeof(Cfg),0);
Cfg.Voice:= Newfon_Male_1;
Cfg.Speech_Rate:= Newfon_Rate_Default;
Cfg.Acceleration:= 10;   { нейтраль, как  accel 10  у прежнего драйвера }
Cfg.Pitch:= Newfon_Pitch_Default;
Cfg.Inflection:= Newfon_Inflection_Default;
Cfg.Pause:= 100;
Pause_Auto:= true;   { умолчание прежнего драйвера:  pause -1 }
Cfg.Flags:= Dec_Sep_Point or Dec_Sep_Comma or Use_Legacy_Rate_Algo;
end.
