{ Win32-бэкенд драйвера речи.

  Авторский оригинал лежит рядом как  SDRVPRIM.SDRVXPApi.INC.author.
  Он через  sdrvxpapi.dll  обращался к  NTVDM,  внутри которой крутилась
  COM-программа драйвера речи.  На 64-разрядной Windows  NTVDM  нет,
  поэтому этот путь мёртв и заменён на ядро  newfon_core  (модуль NEWFON).

  Заменено только то, что упиралось в драйвер.  Всё остальное осталось
  как было:  подпрограммы те же, с теми же именами и параметрами,
  SpkParam  хранит те же поля, а  SText00  по-прежнему опрашивает
  клавиатуру во время произнесения и обрывает речь по нажатию клавиши
  либо по  Ctrl.

  Голоса совпадают один в один:  TSpVoice = (Male1, Female1, Male2,
  Female2)  ложится на  male 1 / female 1 / male 2 / female 2  ядра.
  Темп тоже:  TSpTempo = 0..150,  и у ядра  0..150,  0  -  самый быстрый.

  Громкость  (SpkParam.Volume)  ядром не поддерживается:  поле
  сохраняется и отдаётся через  SpkGetConf,  но на звук не влияет. }

var
  SpkParam: TSpkParam;

function SDrvResult:word;
begin
  SDrvResult:=0;
end;

procedure SText00(stSent: String);
var
  is_ctrl_pressed: Boolean;
begin
  if not SDrvInMemory then
    Exit;
  if Length(stSent) = 0 then
    Exit;
  is_ctrl_pressed:=(GetKeyEventShiftState(PollShiftStateEvent) and kbCtrl) <> 0;

  Newfon_Voice(Ord(SpkParam.Voice));
  Newfon_Tempo(SpkParam.Tempo);

  if not Newfon_Play_Begin(stSent) then begin
    Newfon_Play_End;
    Exit;
  end;

  while True do begin
    if not Newfon_Playing then
      break;
    if (PollKeyEvent <> 0) then begin
      Newfon_Play_Stop;
      break;
    end;

    if is_ctrl_pressed and ((GetKeyEventShiftState(PollShiftStateEvent) and kbCtrl) = 0) then begin
      is_ctrl_pressed:=False;
    end;
    if not is_ctrl_pressed and ((GetKeyEventShiftState(PollShiftStateEvent) and kbCtrl) <> 0) then begin
      Newfon_Play_Stop;
      break;
    end;
    Sleep(1);
  end;

  Newfon_Play_End;
end;

procedure SpkSetVoice(NewVoice: TSpVoice);
Begin
   if not SDrvInMemory then
     Exit;
   SpkParam.Voice:=NewVoice;
end;

procedure SpkSetVolume(NewVolume: TSpVolume);
Begin
   if not SDrvInMemory then
     Exit;
   SpkParam.Volume:=NewVolume;
end;

procedure SpkSetTemp(NewTemp: TSpTempo);
Begin
   if not SDrvInMemory then
     Exit;
   SpkParam.Tempo:=NewTemp;
end;

procedure SpkSetOutput(NewPort: TSpOutput);
Begin
end;

procedure SpkSetPitch(Min, Max: word);
Begin
end;

procedure SpkFile(var f: text);
begin
end;

procedure SpkMem(var pBufAddr: PBuffer; wBufSize: Word);
begin
end;

procedure SpkMemDone(var pBufAddr: PBuffer; wBufSize: Word);
begin
end;

procedure SpkContinue;
begin
end;

procedure SpkSetKeyBreak(const NewKeyT: TKeyTable);
Begin
end;

function SpkGetKeyBreak(var Scan,Status : byte): boolean;
begin
  SpkGetKeyBreak:=False;
end;

function spkGetConf:PSpkParam;
begin
   spkGetConf:=nil;
   if not SDrvInMemory then Exit;
   spkGetConf:=@SpkParam;
end;

procedure spkConfFree(var Param: PSpkParam);
begin
end;

procedure GetWaveHeader;
begin
end;

procedure MakeWaveFile;
begin
end;

procedure SdrvInterfaceInit;
begin
  SDrvInMemory:=False;

  { Раньше здесь искался путь к  sdrvxpapi.dll  в реестре и грузилась она.
    Теперь просто проверяем, поднялось ли ядро  newfon_core;  оно ищет
    свою библиотеку рядом с самой программой. }
  if not Newfon_Ready then
    Exit;

  SDrvInMemory:=True;

  { Номер прерывания драйвера.  Реального прерывания нет, но выше по стеку
    SPICK.InitSp  делает  AdrFon := SdrvInt,  а  SPEECH.PAS  проверяет
    AdrFon > 0,  чтобы понять, есть ли речь.  Оставляем прежнее значение. }
  SdrvInt:=$80;

  SpkParam.Voice:=Male1;
  SpkParam.Tempo:=30;
  SpkParam.Volume:=255;
  SpkParam.Output:=0;
  SpkParam.Pitch:=nil;
  SpkParam.KeyBreak:=nil;
end;

procedure SdrvInterfaceDone;
begin
  if not SDrvInMemory then
    Exit;
  Newfon_Play_Stop;
  SDrvInMemory:=False;
end;
