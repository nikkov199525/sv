UNIT Musefect;
INTERFACE

USES INTER;

type tTune = shortint;

VAR SBIsReady : boolean; {Флаг готовности звуковой карты}



procedure SetEffectVolume(Percentage : byte);
  { Устанавливает текущую громкость в процентном соотношении }

function GetEffectVolume : byte;
  { Возвращает текущую величину громкости в процентном соотношении }

procedure TestEffect;

procedure BeginEffect;
procedure EmptyEffect;
procedure NormalLineEffect;
procedure IndentEffect;

function TryActivateAdlib: Boolean; {//ss/25.09.2003//}

IMPLEMENTATION

const MaxVolumeNum = 127;
      MaxVoiceNum = 8; {Максимальный номер голоса}
      NoVoice = -1; {Признак отсутствия голоса}
      FullNote = 2800; (* 2.8 sec *)
  { Определение нот:
     Добавление H повышает на полутон,
     добавление L понижает на полутон }
      C  = 0;  CH = 1;  DL = 1;  D  = 2;  DH = 3;  EL = 3;  E  = 4;  F  = 5;
      FH = 6;  GL = 6;  G  = 7;  GH = 8;  AL = 8;  A  = 9;  AH = 10; BL = 10;
      B  = 11;
  { Определение октавных смещений:
     Добавление к ноте O1 повышает звук на одну октаву, Добавление O2 - на две и т.д.,
     вычитание из ноты O1 понижает звук на одну октаву, вычитание O2 - на две и т.д. }
      O1 = 12; O2 = 24; O3 = 36; O4 = 48;
  { Определение кодов интерпретатора для включения голосов.
     Следующим значениям соответствуют определённые нотные частоты }
  N0 = 0;  N1 = 1;  N2 = 2;  N3 = 3;  N4 = 4;  N5 = 5;  N6 = 6;  N7 = 7;
  N8 = 8;
  { Определение кодов интерпретатора для выключения голосов }
      F0 = 9;  F1 = 10; F2 = 11; F3 = 12; F4 = 13; F5 = 14; F6 = 15; F7 = 16;
      F8 = 17;
  { Определение кодов интерпретатора длительностей:
     W1 - Целая нота;
     W2 - Половинная нота;
     W4 - Четвертная нота и т.д. }
      W1  = 20; W2  = 21; W4   = 22; W8   = 23; W16 = 24;
      W32 = 25; W64 = 26; W128 = 27; W256 = 28;
      W512 = 29; W1024 = 30; W2048 = 31;
  { Определение кода конца проигрывания }
  TheEnd = 99;

VAR VoiceNum : tTune;
    EffectVolume : byte; {громкость: 0..127}

procedure SetEffectVolume(Percentage : byte);
  { Устанавливает текущую громкость в процентном соотношении }
  begin {SetEffectVolume}
    EffectVolume := round(MaxVolumeNum / 100 * Percentage);
  end;  {SetEffectVolume}

function GetEffectVolume : byte;
  { Возвращает текущую величину громкости в процентном соотношении }
  begin {GetEffectVolume}
    GetEffectVolume := round(EffectVolume * 100 / MaxVolumeNum);
  end;  {GetEffectVolume}

procedure TuneInterPreter(Tune1,Tune2 : tTune);
  begin {TuneInterpreter}
  end;  {TuneInterpreter}

procedure TestEffect;
  begin {TestEffect}
  end;  {TestEffect}

procedure BeginEffect;
  begin {BeginEffect}
  end;  {BeginEffect}

procedure EmptyEffect;
  begin {BeginEffect}
  end;  {EmptyEffect}

procedure NormalLineEffect;
  begin {NormalLineEffect}
  end;  {NormalLineEffect}

procedure IndentEffect;
  begin {IndentEffect}
  end;  {IndentEffect}


function  TryActivateAdlib: Boolean; {//ss/25.09.2003//}
begin
  TryActivateAdlib:=False;
end;

BEGIN {UNIT}
  {Инициализация звуковой карты}
  SBIsReady:= false;
  VoiceNum := NoVoice;
END.
