{$define ukr1}
{$define spon}
{$define fonon}
UNIT INTER;     (* Интерфейсные константы и типы для связи модулей *)
                (* системы МУЛЬТИПРОЦЕССИСТ                        *)

INTERFACE (*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
var ASCII (*Основной код клавиатуры  *),
    AuxiC (*Расширеный код клавиатуры *): char;
CONST
{$ifdef Reader}
  MaxLid = 250;     (* Ограничение размера строки текста           *)
{$else}
  MaxLid = 160{255};     (* Ограничение размера строки текста           *)
{$endif}
  MaxSortLid = 30{255}; (* Огр.раз. сортируемого участка строки текста *)
  MaxSav = 50;    (* Количество одновр.захваченных участков памяти *)

    Russian = 0;      {Русский язык для CyrLang}
    Ukrainian = 1;    {Украинский язык для CyrLang}
    English = 0;      {Английский язык для LatLang}
    German = 1;             {немецкий язык для LatLang}
     UkrLexCoding = 0;
     UkrWordCoding = 1;
    {Малые умлауты}
    A_umlaut = 'Д';
    O_umlaut = 'Ф';
    U_umlaut = 'Б';
    {Большие умлауты}
    A_umlaut_ = 'О';
    O_umlaut_ = 'Щ';
    U_umlaut_ = 'Ъ';
    {Транскрипция умлаутов}
    _A_umlaut = 'e';
    _O_umlaut = 'ё';
    _U_umlaut = 'ю';
{$Ifdef ukr1}
   Ukr_Apo = '`'; (* Украинский апостроф  *)
   Ukr_Ge  = #242; (* Заглавное твёрдое Гэ *)
   _Ukr_Ge = #243; (* строчное твёрдое Гэ *)
   Ukr_Ye  = #244; (* Заглавное 'Ї' *)
   _Ukr_Ye = #245; (* строчное  'ї' *)
   Ukr_I   = #246; (* Заглавное 'Ў' *)
   _Ukr_I  = #247; (* строчное  'ў' *)
   Ukr_Yi  = #248; (* Заглавное '°' *)
   _Ukr_Yi = #249; (* строчное  '∙' *)
{$else}
   Ukr_Apo = '`'; (* Украинский апостроф  *)
   Ukr_Ge  = #248; (* Заглавное твёрдое Гэ *)
   _Ukr_Ge = #249; (* строчное твердое 'є' *)
   Ukr_Ye  = #242; (* Заглавное 'Ї' *)
   _Ukr_Ye = #243; (* строчное  'ї' *)
   Ukr_I   = 'I'; (* Заглавное 'Ў' *)
   _Ukr_I  = 'i'; (* строчное  'ў' *)
   Ukr_Yi  = #244; (* Заглавное '°' *)
   _Ukr_Yi = #245; (* строчное  '∙' *)
{$EndIf}


  UpCode : array[char] of char       (* Коды символов для преобразования *)
                                     (* строчных букв в прописные.       *)
                                     (*   Формируются процедурой USTSCR  *)
  = ({0} {1} {2} {3} {4} {5} {6} {7} {8} {9} {A} {B} {C} {D} {E} {F}
 {0} #00,'','','','','','','','',' ',' ','','',' ','','',
 {1} '','','','','','','','','','',#26,#27,'','','','',
 {2} ' ','!','"','#','$','%','&',#39,'(',')','*','+',',','-','.','/',
 {3} '0','1','2','3','4','5','6','7','8','9',':',';','<','=','>','?',
 {4} '@','A','B','C','D','E','F','G','H','I','J','K','L','M','N','O',
 {5} 'P','Q','R','S','T','U','V','W','X','Y','Z','[','\',']','^','_',
 {6} '`','A','B','C','D','E','F','G','H','I','J','K','L','M','N','O',
 {7} 'P','Q','R','S','T','U','V','W','X','Y','Z','{','|','}','~','',
 {8} 'А','Б','В','Г','Д','Е','Ж','З','И','Й','К','Л','М','Н','О','П',
 {9} 'Р','С','Т','У','Ф','Х','Ц','Ч','Ш','Щ','Ъ','Ы','Ь','Э','Ю','Я',
 {A} 'А','Б','В','Г','Д','Е','Ж','З','И','Й','К','Л','М','Н','О','П',
 {B} '░','▒','▓','│','┤','╡','╢','╖','╕','╣','║','╗','╝','╜','╛','┐',
 {C} '└','┴','┬','├','─','┼','╞','╟','╚','╔','╩','╦','╠','═','╬','╧',
 {D} '╨','╤','╥','╙','╘','╒','╓','╫','╪','┘','┌','█','▄','▌','▐','▀',
 {E} 'Р','С','Т','У','Ф','Х','Ц','Ч','Ш','Щ','Ъ','Ы','Ь','Э','Ю','Я',
 {F} 'Ё','Ё','Є','Є','Ї','Ї','Ў','Ў','°','°','·','√','№','¤','¤',' ');

Type TuLim = set of char;
    type LongToWord = record
                        LowW,    (* Старшее слово *)
                        HighW : word;     (* Младшее слово *)
                      end ;    (*LongToWord *)
Const DigLim : TuLim = ['0'..'9'];
      DigSignLim =  ['0'..'9','-'];
      NumLim : TuLim = ['+','-','.','0'..'9'];
      WordLim : TuLim = [#032..#255];
      CharLim : TuLim =[#$20..#$AF,#$E0..#$F1];
      RazdLim : TuLim = [{'''',}'"',' ', '.', ',', ';', '!', '?', '/','\',
                              '|','{', '}', '[', ']', '(', ')', #0];

   EngVowels = ['A','E','I','O','U', 'Y'];
   EngConsonants = ['A' .. 'Z'] - EngVowels;
{!S! 11/19/96 }
   RusVowels = ['А', 'Е',  'И', 'О', 'У', 'Ы', 'Э', 'Ю', 'Я',
                         'Ё', Ukr_Ye, Ukr_I, Ukr_Yi] - ['I'];
   RusConsonants = ['А' .. 'Я', Ukr_Ge] - RusVowels;
   Consonants = EngConsonants + RusConsonants;
   Vowels = EngVowels + RusVowels;
   EngAlphabet = EngConsonants + EngVowels;
   RusAlphabet = RusConsonants + RusVoWels;
   Alphabet = Engalphabet + RusAlphabet;

      (* Коды аварийных ситуаций :                                 *)
   NoMemory = 257; (* Нет памяти для размещения динамич. массива   *)
   ShortBuf = 258; (* Переполнение байтового  массива (BB)         *)
   ShortOgl = 259; (* Переполнение страницы оглавления (SB)        *)
   OverBlok = 260; (* Разрушено оглавление (Перекрытие тел блоков) *)
   CloseFil = 261; (* Попытка работать с закрытым файлом           *)
   ShortMas = 262; (* Попытка выйти за границу массива             *)
   FalseInd = 263; (* Неверное значение инекса                     *)
   FalseCapt= 264; (* Попытка захватить занятый участок памяти     *)
  NoCloseWin= 265; (* Попытка закрыть не последнее открытое окно   *)
      (* Коды в пределах 1 - 255 устанавливаются операц.системой   *)


  { КОНСТАНТЫ КОДОВ КЛАВИШ                                             }
  { Главный код                                                        }
  CSlCod      = #00;
  CBack       = #08;
  CTab        = #09;
  CCtrl_Enter = #10;
  CEnter      = #13;
  CEsc        = #27;
  CBlank      = #32;
  cCtrl_Back = 127;

  CCtrl_A = #01;  CCtrl_H = #08;  CCtrl_O = #15;  CCtrl_V = #22;
  CCtrl_B = #02;  CCtrl_I = #09;  CCtrl_P = #16;  CCtrl_W = #23;
  CCtrl_C = #03;  CCtrl_J = #10;  CCtrl_Q = #17;  CCtrl_X = #24;
  CCtrl_D = #04;  CCtrl_K = #11;  CCtrl_R = #18;  CCtrl_Y = #25;
  CCtrl_E = #05;  CCtrl_L = #12;  CCtrl_S = #19;  CCtrl_Z = #26;
  CCtrl_F = #06;  CCtrl_M = #13;  CCtrl_T = #20;
  CCtrl_G = #07;  CCtrl_N = #14;  CCtrl_U = #21;

  { Вспомогательный код                                                }
  { Буквенно-цифровые клавиши                                          }
  CAlt_A  = #30;  CAlt_H  = #35;  CAlt_O  = #24;  CAlt_V  = #47;
  CAlt_B  = #48;  CAlt_I  = #23;  CAlt_P  = #25;  CAlt_W  = #17;
  CAlt_C  = #46;  CAlt_J  = #36;  CAlt_Q  = #16;  CAlt_X  = #45;
  CAlt_D  = #32;  CAlt_K  = #37;  CAlt_R  = #19;  CAlt_Y  = #21;
  CAlt_E  = #18;  CAlt_L  = #38;  CAlt_S  = #31;  CAlt_Z  = #44;
  CAlt_F  = #33;  CAlt_M  = #50;  CAlt_T  = #20;
  CAlt_G  = #34;  CAlt_N  = #49;  CAlt_U  = #22;

  CAlt_1  = #120; CAlt_4  = #123; CAlt_7  = #126; CAlt_0     = #129;
  CAlt_2  = #121; CAlt_5  = #124; CAlt_8  = #127; CAlt_Minus = #130;
  CAlt_3  = #122; CAlt_6  = #125; CAlt_9  = #128; CAlt_Equal = #131;

  { Функциональные клавиши                                             }
  CF1  = #59;  CShift_F1  = #84 ;  CCtrl_F1  = #94 ;  CAlt_F1  = #104;
  CF2  = #60;  CShift_F2  = #85 ;  CCtrl_F2  = #95 ;  CAlt_F2  = #105;
  CF3  = #61;  CShift_F3  = #86 ;  CCtrl_F3  = #96 ;  CAlt_F3  = #106;
  CF4  = #62;  CShift_F4  = #87 ;  CCtrl_F4  = #97 ;  CAlt_F4  = #107;
  CF5  = #63;  CShift_F5  = #88 ;  CCtrl_F5  = #98 ;  CAlt_F5  = #108;
  CF6  = #64;  CShift_F6  = #89 ;  CCtrl_F6  = #99 ;  CAlt_F6  = #109;
  CF7  = #65;  CShift_F7  = #90 ;  CCtrl_F7  = #100;  CAlt_F7  = #110;
  CF8  = #66;  CShift_F8  = #91 ;  CCtrl_F8  = #101;  CAlt_F8  = #111;
  CF9  = #67;  CShift_F9  = #92 ;  CCtrl_F9  = #102;  CAlt_F9  = #112;
  CF10 = #68;  CShift_F10 = #93 ;  CCtrl_F10 = #103;  CAlt_F10 = #113;

  { Клавиши управления курсором       (Alt-кодов  нет)                 }
  CHome = #71;   CShift_Home = #71;   CCtrl_Home = #119;
  CUp   = #72;   CShift_Up   = #72;   CCtrl_Up   = #11; {нет кода}
  CPgUp = #73;   CShift_PgUp = #73;   CCtrl_PgUp = #132;
  CLeft = #75;   CShift_Left = #75;   CCtrl_Left = #115;
  C_5   = #76;   CShift_5    = #76;   CCtrl_5    = #10; {нет кода}
  CRight= #77;   CShift_Right= #77;   CCtrl_Right= #116;
  CEnd  = #79;   CShift_End  = #79;   CCtrl_End  = #117;
  CDown = #80;   CShift_Down = #80;   CCtrl_Down = #12; { нет кода}
  CPgDn = #81;   CShift_PgDn = #81;   CCtrl_PgDn = #118;
  CIns  = #82;   CShift_Ins  = #05;   CCtrl_Ins  = #09; {04}
  CDel  = #83;   CShift_Del  = #04;   CCtrl_Del  = #06;

  CShift_Ins2  = #07;
  CCtrl_Shift_Left  = #115;
  CCtrl_Shift_Right = #116;

  { Прочие                                                             }
  CShift_Tab = #15;  CCtrl_PrtScr = #114;  CCtrl_Break= #0;

  (* CFunc  ((B2>#58)and(B2<#69))OR((B2>#83)and(B2<#114)) *)


TYPE
   TuLin = string[MaxLid]; (* буферная строка для обмена с BUF     *)
   TuSortLin = string[MaxSortLid];
                           (* буферная строка для сортировки текста  *)

   TText = STRING[MaxLid]; (* Тип идентификатора или строки текста *)
   TuSav = record     (* Для слежения за захватом оператив.памяти  *)
              MSav : word; (* Номер посленего занятого участка     *)
                           (* 0 - при запуске программы, растет    *)
                           (* при выелении памяти по очередную     *)
                           (* структуру анных и уменьшается только *)
                           (* при аварийном завершении программы   *)
              SSav : array[0..MaxSav] of
                record
                  AdrSav: pointer;
                  LenSav: word;
                end;
             end;

TestLine = Function(var MLin:TULin;    (* Проверяемая строка       *)
                    var NErr: integer; (* Номер ошибочного символа *)
                    var ec: word       (* Код ошибки               *)
                    ):boolean;
                         (* Тип процедуры проверки введеной строки *)

var Sav : TuSav; (* Глобальная структура для распределения памяти  *)

const MaxStSon = 100;

type
  TuElStS = record (* Элемент стека для обхода дерева *)
              RegNEl, (* Рег.номер понятия в текущей вершине *)
              AddSInf (* Это поле пока не используется *)
                : word;
            end;
  TuStSons = record (* стек рег.ном. понятий и сыновей при обходе дерева *)
                 NStSon : integer; (* число заполненных элементов *)
                 MStSon : array[0..MaxStSon] of TuElStS;
               end;

var StSons : TuStSons; (* Для запоминания пути обхода дерева *)


{$IfDef PROON}

Type  TuStat =array[1..8] of real;
      TuProto = record
       Com: string[15]; (* имя польз. или ид-р команды *)
       par: TuStat ; (* Статистические данные *)
      end;

var    Proto : file of TuProto; (* Файл протокола *)

const  TabStat05: TuStat =( 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0 );
       TabStat10: TuStat =(10.0,20.0,30.0,40.0,50.0,60.0,70.0,80.0 );

{$EndIf}

var TELM,TelmOld, (* 0-откл.звук, 1-на внут.динам, 2-на парал.интерф. *)
    NVoice,   (* номер голоса 0..3 *)
    TVoice,   (* общий темп речи 0-быстро...150-медленно *)
    TVoice2,  (* темп речи при чтении текста в целом     *)
    VVoice    (* громкость 0-255  *)
     : integer;

(*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
 procedure Noice(Tel, (* 0-не говор, 1-на внут.динам, 2-на парал.интерф. *)
                 Tip, (* тип звука *)
                 Lon, (* длительность *)
                 P1,  (* основной тон *)
                 P2,  (* амплитуда осн.тона 1..255 *)
                 P3,  (* доп. параметры *)
                 P4
                  : integer );
    (* Процедура вывода звукового сигнала *)

(*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
(* Универсальные процеуры захвата - освобожения памяти                *)
(*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
PROCEDURE CaptSM     (* Захват опер.памяти для сохранения *)
            (SizeBuf : word; (* Размер захватываемого участка (байт)  *)
              var NU : word; (* Номер участка памяти (изначально - 0 )*)
              var ec : word  (* Код завершения                        *)
            );
(*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
PROCEDURE FreeSM     (* Освобождение опер.пам, выдел.для сохранения   *)
            ( var NU : word;  (* Номер участка памяти                 *)
              var ec : word   (* Код завершения                       *)
            );

(*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒**▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
(* Функции разбора строки параметров                                  *)
(*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
  (*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
 (* Функция проверяет, находится ли в строке MM  N-я фраза среди    *)
 (* других фраз, разделенных символами RR.                          *)
 (* Все, что предшествует первому символу RR или следует за послед- *)
 (* ним таким символом - игнорируется.                              *)
 (*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
 Function NomFrase(MM : string;
                    N : integer;
                    RR: char;
                var i1, (* начало найденной фразы *)
                    i2 : integer (* номер за концом фразы *)
                ): boolean;
 (*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
 (* Функция проверяет, находится ли фраза AA в строке MM  среди     *)
 (* других фраз, разделенных символами RR.                          *)
 (* Все, что предшествует первому символу RR или следует за послед- *)
 (* ним таким символом - игнорируется.                              *)
 (*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
 Function FindFrase(MM : string;
                    AA : string;
                    RR: char;
                var i1, (* начало найденной фразы *)
                    i2 : integer (* номер за концом фразы *)
                ): integer;
 (*▒**▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
 (* Процедура проверяет, находится ли в строке MM  N-я фраза среди  *)
 (* других фраз, разделенных символами RR.                          *)
 (* Все, что предшествует первому символу RR или следует за послед- *)
 (* ним таким символом - игнорируется.                              *)
 (* Найденная фраза удаляется.                                      *)
 (*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
 Procedure DelFrase(var MM : string;
                    N : integer;
                    RR: char
                );
  var I1,I2, J,k : integer;

 (*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
 (* Процедура вставляет в строку MM  N-ю фразу.                     *)
 (* Если в строке меньше N фраз, разделенных символами RR, то       *)
 (* фраза добавляется к концу строки                                *)
 (* Все, что предшествует первому символу RR или следует за послед- *)
 (* ним таким символом - игнорируется.                              *)
 (*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
 Procedure InsFrase(var MM : string;
                    AA : string;
                    N : integer;
                    RR: char;
                var I1,I2 : integer
                );

 (*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
 (* Функция проверяет, находится ли в строке MM начиная с позиции N *)
 (* слово с префиксом PREF. При этом игнорируются разделители, пере-*)
 (* численные в глоб.множ. RAZDLIM.                                 *)
 (*     После успешной проверки N устанавливается за префиксом.     *)
 (*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
 Function NextWord(MM : string;
               Pref: string;
           var   N : integer): boolean;
 (*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
 (* Функция ищет в строке MM начиная с позиции N  слово с префиксом *)
 (* PREF и возвращает следующее за ним слово в качестве значения.   *)
 (* При этом игнорируются разделители, перечисленные в глоб.множест-*)
 (* ве RAZDLIM.                                                     *)
 (*     После успешного поиска N устанавливается за префиксом.      *)
 (* В случае пустого префикса возвращается первое за N слово.       *)
 (*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
 Function StrPar(MM : string;
               Pref: string;
           var WRes: TuLin;
           var   N : integer): boolean;

 (*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
 (* Функция ищет в строке MM начиная с позиции N  слово с префиксом *)
 (* PREF и возвращает следующее за ним целое число в пар. WRES.     *)
 (* При этом игнорируются разделители, перечисленные в глоб.множест-*)
 (* ве RAZDLIM.                                                     *)
 (*     После успешного поиска N устанавливается за префиксом.      *)
 (* В случае пустого префикса возвращается первое за N целое.       *)
 (*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
function IntPar(MM: string;
               Pref: string;
           var WRes, N: integer ): boolean;

 (*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
 (* Функция ищет в строке MM начиная с позиции N  слово с префиксом *)
 (* PREF и возвращает следующее за ним  число в парам. WRES.        *)
 (* При этом игнорируются разделители, перечисленные в глоб.множест-*)
 (* ве RAZDLIM.                                                     *)
 (*     После успешного поиска N устанавливается за префиксом.      *)
 (* В случае пустого префикса возвращается первое за N число.       *)
 (*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
function RealPar(MM: string;
               Pref: string;
           var WRes: real;
           var   N : integer ): boolean;


(*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
(* Функции преобразования представления переменных                    *)
(*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)


 Function IntToStr(x:integer; n:byte):string;

 Function RealToStr(x:real; n,m:byte):string;

 Function StrToReal(S:string):real;

 Function TestInt( var MLin:TULin;      (* Проверяемая строка       *)
                   var NErr : integer;  (* Номер ошибочного символа *)
                   var ec: word         (* Код ошибки               *)
                    ):boolean;
 (* Процедурa проверки вводимой строки на соответствие целому числу *)

 Function TestReal( var MLin:TULin;     (* Проверяемая строка       *)
                   var NErr : integer;  (* Номер ошибочного символа *)
                   var ec: word         (* Код ошибки               *)
                    ):boolean;
 (* Процедурa проверки вводимой строки на соответствие действ.числу *)

 Function TestWord( var MLin:TULin;     (* Проверяемая строка       *)
                   var NErr : integer;  (* Номер ошибочного символа *)
                   var ec: word         (* Код ошибки               *)
                    ):boolean;
 (* Процедурa проверки вводимой строки на соответствие действ.числу *)

 (* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *)
 (*    Функция проверяет интервал времени, прощедший с момента        *)
 (* последней засечки.  Если он истек, то делается новая засечка      *)
 (* и возвращается истина. Иначе - возвращается ложь                  *)
 (* Для первой засечки задать TK > 900000                             *)
 (* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *)
 Function CheckInterv(var TK   : real; (* последняя засечка *)
                    Interv : real (* Интервал в секундах *)
                        ) : boolean;


{$IfDef PROON}
 (* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *)
 (*    Процедурa выводит статистические параметры в файл протокола    *)
 (* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *)
  Procedure InProto( AA:string;     (* Текст     *)
                     P1,P2,P3,P4,P5,P6,P7,P8 : real  (* параметры *)
                    );

 (* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *)
 (*    Функция засекает время, и кроме этого увеличивает  в массиве   *)
 (* Stat счетчик кластера, соответствующего интервалу с момента       *)
 (* последней засечки.                                                *)
 (*    Интервалы кластеров берутся из таблицы  TabStat                *)
 (* Для первой засечки задать TK > 900000                             *)
 (* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *)
 Function CheckTime(var TK   : real; (* последняя засечка *)
                    var Stat : TuStat; (* кластеры *)
                    var TabStat : TuStat (* правая граница интервала *)
                        ) : real;

{$EndIf}

{!S! 11/23/96 }
    (*Очистка буфера клавиатуры *)
procedure cbk;

    (*Чтение символа из буфера клавиатуры *)
function preskey:boolean;

 (*заглавные буквы превращает в строчные*)
 function StrChar (s : string) : string;

           (*Возвращает размер кластера в байтах *)
           (*накопителя с номером DiskNum (0 - текущий диск) *)
function GetClusterSize (DiskNum : Byte) : word;




(* Путь к каталогу, содержащему EXE-файл вызвавшей программы *)
Function SourcePath : string;

procedure Pause (PauseLeng : longint);

(* Статус клавишей-переключателей *)

function InsertStatus : boolean;
function CapsLockStatus : boolean;
function NumLockStatus : boolean;
function ScrollLockStatus : boolean;
function AltPressed : boolean;
function CtrlPressed : boolean;
function LeftShiftPressed : boolean;
function RightShiftPressed : boolean;
function ShiftPressed : boolean;

procedure clearBlank(var MM : TULin);

function UpStr (S : string) : string;


type tClearLineDirect = (DeleteFrom,LeaveIn);
{Если аргуменьт  Direct имеет значение DeleteFrom, функция возвращает строку аргумента Lin,}
{ удаляя из неё все символы, указаные аргументом Symbols}
{Если же Аргумент Direct имеет значение LeaveIn, то возвращённая строка будет содержать}
{ только те встреченные в аргументе Lin символы, которые указывает аргумент Symbols}
function ClearLine(Symbols : tULim; Direct : tClearLineDirect; Lin : string) : tULin;


function GetFreeMemSize : longint; {Возвращает размер свободной станд.пам в байтах }

Implementation (*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
Uses Windows, Keyboard, Dos
{!S! 07/27/97 - Озвучить переключатели }
  {$IFDEF SPON}
    , SPICK
  {$ENDIF}
   ;


{!S! 07/27/97 - Озвучить переключатели }
  {$IFDEF SPON}
           {Флаги переключателей}
VAR
    CapsLock_on,
    NumLock_on,
    ScrollLock_on : boolean;
  {$ENDIF}

(* Статус клавишей-переключателей *)
function InsertStatus : boolean;
    var REGs : registers;
  begin {InsertStatus}
    REGs.AH := 2;
    intr ($14, REGs);
    InsertStatus := (REGs.AL and 128) > 0;
  end;  {InsertStatus}
function CapsLockStatus : boolean;
    VAR REGs : registers;
  begin {CapsLockStatus}
    REGs.AH := 2;
    intr ($16, REGs);
    CapsLockStatus := (REGs.AL and 64) > 0;
  end;  {CapsLockStatus}

function NumLockStatus : boolean;
    VAR REGs : registers;
  begin {NumLockStatus}
    REGs.AH := 2;
    intr ($16, REGs);
    NumLockStatus := (REGs.AL and 32) > 0;
  end;  {NumLockStatus}

function ScrollLockStatus : boolean;
    VAR REGs : registers;
  begin {ScrollLockStatus}
    REGs.AH := 2;
    intr ($16, REGs);
    ScrollLockStatus := (REGs.AL and 16) > 0;
  end;  {ScrollLockStatus}

function AltPressed : boolean;
    VAR REGs : registers;
  begin {AltPressed}
    REGs.AH := 2;
    intr ($16, REGs);
    AltPressed := (REGs.AL and 8) > 0;
  end;  {AltPressed}

function CtrlPressed : boolean;
    VAR REGs : registers;
  begin {CtrlPressed}
    REGs.AH := 2;
    intr ($16, REGs);
    CtrlPressed := (REGs.AL and 4) > 0;
  end;  {CtrlPressed}

function LeftShiftPressed : boolean;
    VAR REGs : registers;
  begin {LeftShiftPressed}
    REGs.AH := 2;
    intr ($16, REGs);
    LeftShiftPressed := (REGs.AL and 2) > 0;
  end;  {LeftShiftPressed}

function RightShiftPressed : boolean;
    var REGs : registers;
  begin {RightShiftPressed}
    REGs.AH := 2;
    intr ($16, REGs);
    RightShiftPressed := (REGs.AL and 1) > 0;
  end;  {RightShiftPressed}

function ShiftPressed : boolean;
    VAR REGs : registers;
  begin {ShiftPressed}
    REGs.AH := 2;
    intr ($16, REGs);
    ShiftPressed := (REGs.AL and 3) > 0;
  end;  {ShiftPressed}


procedure Noice(Tel, (* 0-не говор, 1-на внут.динам, 2-на парал.интерф. *)
                 Tip, (* тип звука *)
                 Lon, (* длительность импульса в миллисек *)
                 P1,  (* основной тон в Гц *)
                 P2,  (* громкость *)
                 P3,  (* длительность паузы в миллисек *)
                 P4   (* количество импульсов *)
                  : integer );
    (* Процедура вывода звукового сигнала *)
  var
  NPe : word; (* число периодов в звуковом сигнале *)
  TPe : word;
  APe : byte;
  i : word;

procedure TON; (* формирует основной тон *)
   var i : word;


begin (*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
 if (TEL<=1) or (TEL=4)
 then begin (* простой меандр частотой P1 и длительностью Lon *)
            (* на встроенный динамик *)
         {sound(P1); Pause(Lon); nosound;}
      end
 else if TEL=2
      then begin  (* простой меандр частотой P1, длительностью Lon *)
                  (* и громкостью P2 на COVOX                      *)
              NPe:= round((Lon/1000)*P1);
              TPe:= round(500/P1);
              APe:= byte(P2);
              {for i:=1 to Npe
              do begin
                   Port[$378]:=APe;
                   Pause(TPe);
                   Port[$378]:=0;
                   Pause(TPe);
                 end;}
           end;
end; (* TON *)
begin  (*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
 case TIP of
   0: TON; (* одиночный сигнал *)
   1: begin
        for  i:=1 to P4 do
          begin
             TON;
             Pause(P3);
          end;
      end;
  end; (* case *)
{$IfNDef SP_Comm}
  CBK;
{$EndIf}
end; (* Noice *)

PROCEDURE CaptSM     (* Захват опер.памяти для сохранения *)
            (SizeBuf : word; (* Размер захватываемого участка (байт)  *)
              var NU : word; (* Номер участка памяти (изначально - 0 )*)
                 (* Если при входе в процедуру задать NU=0, то данный *)
                 (*    участок получит новый (уникальный) номер. Этот *)
                 (*    номер следует запомнить для дальнейшего осво-  *)
                 (*    бождения памяти.                               *)
                 (* Если же требуется выделить память для участка с   *)
                 (*    заранее заданным номером, то он уже должен быть*)
                 (*    в списке Sav и иметь нулевую длину и адрес.    *)
                 (* Следовательно, при попытке дважды выделеить память*)
                 (*    одному участку ничего плохого не произойдет.   *)
                 (*    Останется старое распределение памяти и возвра-*)
                 (*    тится предупреждающий код EC = FalseCapt       *)
              var ec : word  (* Код завершения                        *)
            );
begin (*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
  ec:=0;
  with Sav do
   begin
     if Nu = 0
     then
       begin
         if MSav < MaxSav
         then begin
                inc(MSav);
                Nu:=MSav;
              end
                else ec:=ShortMas;
       end
     else if Nu > MSav then ec:= FalseInd;

     if ec=0
     then with Sav.SSav[Nu] do
       begin
         if (LenSav>0) or (AdrSav <> Nil)
         then ec:=FalseCapt
         else
           if (SizeBuf>0) {and (MaxAvail > SizeBuf)}
           then begin
                  GetMem(AdrSav,SizeBuf);
                  LenSav:=SizeBuf;
                end
           else ec:= NoMemory;
       end;
   end;
end; (* CaptSM *)

(*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
PROCEDURE FreeSM     (* Освобождение опер.пам, выдел.для сохранения   *)
            ( var NU : word;  (* Номер освобождаемого участка памяти  *)
              var ec : word   (* Код завершения                       *)
            );
begin (*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
  ec:=0;
  with Sav do
   begin
     if (Nu=0) or (Nu > MSav) then ec:= FalseInd
     else with Sav.SSav[Nu] do
       begin
          if (LenSav>0) and (AdrSav<>Nil)
          then FreeMem(AdrSav,LenSav);
          LenSav:=0;
          AdrSav:=nil;
          if Nu=MSav then dec(MSav);
       end;
   end;
end; (* FreeSM *)

(*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
Function IntToStr(x:integer; n:byte):string;
Var s : string;
    i : integer;
Begin
  i:=0;
  Str(x:n,s);
  While (i<=length(s)) and (s[i+1]=' ') do inc(i);
  if i>0 then delete(s,1,i);
  IntToStr := s;
End;
(*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
Function RealToStr(x:real; n,m:byte):string;
Var s : string;
    i : integer;
Begin
  i:=0;
  Str(x:n:m,s);
  While (i<=length(s)) and (s[i+1]=' ') do inc(i);
  if i>0 then delete(s,1,i);
  RealToStr := s;
End;
(*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
Function StrToReal(S:string):real;
Var i : integer;
    x : real;
Begin
  i:=Pos(' ',s);
  While (length(s)>0) and (i>0) do
  delete(s,i,1);
  i:=0;
  Val(s,x,i);
  if i>0 then   StrToReal :=0
         else   StrToReal :=X ;
End;
 (*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
 (* Функция проверяет, находится ли в строке MM  N-я фраза среди    *)
 (* других фраз, разделенных символами RR.                          *)
 (* Все, что предшествует первому символу RR или следует за послед- *)
 (* ним таким символом - игнорируется.                              *)
 (*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒**▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
 Function NomFrase(MM : string;
                    N : integer;
                    RR: char;
                var i1, (* начало найденной фразы *)
                    i2 : integer (* номер за концом фразы *)
                ): boolean;
  var J,k : integer;
begin (*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
  j:=length(MM);
  NomFrase:=false;
  i1:=1;
  k:=0;
  while (i1<j) and (k<N) do
    begin
      if MM[i1]=RR then inc(k);
      inc(i1);
    end;
  if i1<j then
    begin
     i2:=i1;
     while (i2<=j) and (MM[i2]<>RR) do inc(i2);
     if (i2<=j) and (MM[i2]=RR)
     then NomFrase:=true
     else begin i1:=0; i2:=0; end;
    end;
end; (* NomFrase *)

 (*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
 (* Функция проверяет, находится ли фраза AA в строке MM  среди     *)
 (* других фраз, разделенных символами RR.                          *)
 (* Все, что предшествует первому символу RR или следует за послед- *)
 (* ним таким символом - игнорируется.                              *)
 (*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
 Function FindFrase(MM : string;
                    AA : string;
                    RR: char;
                var i1, (* начало найденной фразы *)
                    i2 : integer (* номер за концом фразы *)
                ): integer;
  var J,l,i,k : integer;
      W,W1 : boolean;
begin (*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
  j:=length(MM);
  FindFrase:=0;
  W:=true;
  i:=1;
  k:=0;
  while (i<j) and W do
    begin
      while (i<j) and (MM[i]<>RR) do inc(i);
      if MM[i]=RR
      then
        begin
          inc(k);
          l:=1;
          W1:=true;
          i1:=i+1;
          inc(i);
          while (i<=j)  and (l<=length(AA))
          do begin
              if MM[i]=' '
              then inc(i)
              else if AA[l]=' '
              then inc(l)
              else begin
                     W1:=W1 and (UpCode[AA[l]]=UpCode[MM[i]]);
                     if (MM[i]<>RR) then inc(i) else W1:=false;
                     inc(l);
                   end;
             end;
          if W1 and (MM[i]=RR) and (l>length(AA))
          then begin
                 W:=false;
                 FindFrase:=k;
                 i2:=i;
               end;
        end;
    end;

  if W then
    begin
       i1:=0;
       i2:=0;
       K:=0;
       FindFrase:=0;
    end;
end; (* FindFrase *)

 (*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
 (* Процедура проверяет, находится ли в строке MM  N-я фраза среди  *)
 (* других фраз, разделенных символами RR.                          *)
 (* Все, что предшествует первому символу RR или следует за послед- *)
 (* ним таким символом - игнорируется.                              *)
 (* Найденная фраза удаляется.                                      *)
 (*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
 Procedure DelFrase(var MM : string;
                    N : integer;
                    RR: char
                );
  var I1,I2, J,k : integer;
begin (*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
  if NomFrase(MM,N,RR,i1,i2)
  then delete(MM,i1,1+i2-i1);
end; (* DelFrase *)

 (*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
 (* Процедура вставляет в строку MM  N-ю фразу.                     *)
 (* Если в строке меньше N фраз, разделенных символами RR, то       *)
 (* фраза добавляется к концу строки                                *)
 (* Все, что предшествует первому символу RR или следует за послед- *)
 (* ним таким символом - игнорируется.                              *)
 (* Найденная фраза удаляется.                                      *)
 (*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
 Procedure InsFrase(var MM : string;
                    AA : string;
                    N : integer;
                    RR: char;
                var I1,I2 : integer
                );
  var i,J,k,j1 : integer;
begin (*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
  J:=length(MM);
  k:=0;
  i:=1;
  j1:=0;
  while (i<=J) and (k<N) do
    begin
      if MM[i]=RR
      then begin
             inc(k);
             j1:=i;
           end
      else inc(i);
    end;

  if k=N  (* место найдено *)
  then  begin
          insert(RR+AA,MM,i);
          I1:=i+1;
          I2:=I1+length(AA);
        end
  else  begin (* добавить в конец *)
          if j1=0 then
            begin
              MM:=MM+RR;
              j1:=length(MM);
            end;
          for i:=1 to N-k
          do begin
              insert(RR,MM,j1);
              inc(j1);
             end;
          k:=n;
          insert(AA,MM,j1);
        end;
end; (* InsFrase *)



 (*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
 (* Функция проверяет, находится ли в строке MM начиная с позиции N *)
 (* слово с префиксом PREF. При этом игнорируются разделители, пере-*)
 (* численные в глоб.множ. RAZDLIM.                                 *)
 (*     После успешной проверки N устанавливается за префиксом.     *)
 (*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
 Function NextWord(MM : string;
               Pref: string;
           var   N : integer): boolean;

 var LB,RB : byte;
     sb    : string;
     i     : integer;
begin (*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
  NextWord:=false;
  sb:=copy(MM,N,length(MM)-N+1);
  LB:=pos(Pref,Sb);
  if Lb>0
  then
    begin
      i:=1;
      while (i<LB) and (sb[i] in RazdLim) do inc(i);
      if i>=Lb
      then begin
             N:=N+LB+length(Pref)-1;
             NextWord:=true;
           end;
    end;
end; (* NextWord *)

 (*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
 (* Функция ищет в строке MM начиная с позиции N  слово с префиксом *)
 (* PREF и возвращает следующее за ним слово в качестве значения.   *)
 (* При этом игнорируются разделители, перечисленные в глоб.множест-*)
 (* ве RAZDLIM.                                                     *)
 (*     После успешного поиска N устанавливается за префиксом.      *)
 (* В случае пустого префикса возвращается первое за N слово.       *)
 (*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
 Function StrPar(MM : string;
               Pref: string;
           var WRes: TuLin;
           var   N : integer): boolean;

 var LB,RB : byte;
     sb    : string;
     i     : integer;
begin (*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
  StrPar:=false;
  WRes:='';
  sb:=copy(MM,N,length(MM)-N+1);
  LB:=pos(Pref,Sb);
  if (Lb=0) and (Pref='')  then Lb:=1;
  if Lb>0
  then
    begin
      inc(Lb,length(Pref));
      while (Lb<=length(sb))
        and (sb[Lb] in RazdLim)
      do inc(Lb);
      RB:=Lb;
      while (Rb<=length(sb)) and not (sb[Rb] in RazdLim)
      do inc(RB);
      if RB>LB
      then begin
             WRes:=copy(sb,Lb,Rb-Lb);
             StrPar:=true;
             N:=N+RB-1;
           end;
    end;
end; (* StrPar *)
 (*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
 (* Функция ищет в строке MM начиная с позиции N  слово с префиксом *)
 (* PREF и возвращает следующее за ним целое число в пар. WRES.     *)
 (* При этом игнорируются разделители, перечисленные в глоб.множест-*)
 (* ве RAZDLIM.                                                     *)
 (*     После успешного поиска N устанавливается за префиксом.      *)
 (* В случае пустого префикса возвращается первое за N целое.       *)
 (*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
function IntPar(MM: string;
               Pref: string;
           var WRes, N: integer ): boolean;

 var LB,RB : byte;
     sb,sb1: TuLin;
     i,N1, ResBuf   : integer;
     W, BB      : boolean;
begin (*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
  BB := false;
  ResBuf := WRes;
  WRes:=0;
  Lb:=1;  N1:=N;
  W:=StrPar(MM,Pref,Sb,N1);
  if W then
    begin
      {while (Lb<=length(Sb)) and not (Sb[Lb] in ['+','-','0'..'9'])
      do inc(Lb);}
      RB:=Lb+1;
      while (Rb<=length(Sb)) and  (Sb[Rb] in ['0'..'9'] )
      do inc(RB);
      if RB>LB
      then begin
             sb1:=copy(Sb,Lb,Rb-Lb);
             val(Sb1,WRes,i);
             BB :=(i=0);
             N:=N1+RB-length(sb)-1;
           end;
    end;
  if not BB then WRes := ResBuf;
  IntPar := BB;
end; (* IntPar *)
 (*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒**▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
 (* Функция ищет в строке MM начиная с позиции N  слово с префиксом *)
 (* PREF и возвращает следующее за ним  число в парам. WRES.        *)
 (* При этом игнорируются разделители, перечисленные в глоб.множест-*)
 (* ве RAZDLIM.                                                     *)
 (*     После успешного поиска N устанавливается за префиксом.      *)
 (* В случае пустого префикса возвращается первое за N число.       *)
 (*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒**▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
function RealPar(MM: string;
               Pref: string;
           var WRes: real;
           var   N : integer ): boolean;

 var LB,RB : byte;
     sb,sb1: TuLin;
     i,N1  : integer;
     W     : boolean;
begin (*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
  RealPar:=false;
  WRes:=0;
  Lb:=1; N1:=N;
  W:=StrPar(MM,Pref,Sb,N1);

  if W then
    begin
      {while (Lb<=length(Sb)) and not (Sb[Lb] in ['+','-','.','0'..'9'])
      do inc(Lb);}
      RB:=Lb+1;
      while (Rb<=length(sb)) and (sb[Rb] in ['+','-','.','0'..'9','E','Е'{кир}])
      do inc(RB);
      if RB>LB
      then begin
             sb1:=copy(sb,Lb,Rb-Lb);
             val(Sb1,WRes,i);
             RealPar:=(i=0);
             N:=N1+RB-length(sb)-1;
           end;
    end;
end; (* RealPar *)

 (*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
 {$F+}
 Function TestInt( var MLin:TULin;      (* Проверяемая строка       *)
                   var NErr : integer;  (* Номер ошибочного символа *)
                   var ec: word         (* Код ошибки               *)
                    ):boolean;
 (* Процедурa проверки вводимой строки на соответствие целому числу *)
 var i:integer;
     R: real;
 begin (*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
     ec:=0;
     Val(MLin,r,NErr);
     if Abs(r) > 32625
     then begin
            NErr:=1;
            ec:=2;
            TestInt:=false;
          end
     else begin
            Val(MLin,i,NErr);
            if NErr>0
            then begin
                   TestInt:= NErr=0;
                   ec:=1;
                 end;
          end;
 end; (* TestInt *)

 Function TestReal( var MLin:TULin;     (* Проверяемая строка       *)
                   var NErr : integer;  (* Номер ошибочного символа *)
                   var ec: word         (* Код ошибки               *)
                    ):boolean;
 (* Процедурa проверки вводимой строки на соответствие действ.числу *)
 var i:real;
 begin (*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
     ec:=0;
     Val(MLin,i,NErr);
     if NErr > 0
     then begin
            TestReal:= NErr=0;
            ec:=1;
          end;
 end; (* TestReal *)

 Function TestWord( var MLin:TULin;     (* Проверяемая строка       *)
                   var NErr : integer;  (* Номер ошибочного символа *)
                   var ec: word         (* Код ошибки               *)
                    ):boolean;
 (* Процедурa проверки вводимой строки на соответствие              *)
 var i:real;
 begin (*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
     ec:=0;
     TestWord:= true;
 end; (* TestWord *)

 {$F-}
{$IfDef PROON}
  Procedure InProto( AA:string;     (* Текст     *)
                     P1,P2,P3,P4,P5,P6,P7,P8 : real  (* параметры *)
                    );
 (* Процедурa выводит параметры в файл протокола *)
var BB : TuProto;
begin
 BB.Com:='                 ';
 BB.Com:=AA;
 BB.Par[1]:=P1;
 BB.Par[2]:=P2;
 BB.Par[3]:=P3;
 BB.Par[4]:=P4;
 BB.Par[5]:=P5;
 BB.Par[6]:=P6;
 BB.Par[7]:=P7;
 BB.Par[8]:=P8;
 Write(Proto,BB);
end; (* InProto*)

 (* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *)
 (*    Функция засекает время, и кроме этого увеличивает  в массиве   *)
 (* Stat счетчик кластера, соответствующего интервалу с момента       *)
 (* последней засечки.                                                *)
 (*    Интервалы кластеров берутся из таблицы  TabStat                *)
 (* Для первой засечки задать TK > 900000                             *)
 (* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *)
 Function CheckTime(var TK   : real; (* последняя засечка *)
                    var Stat : TuStat; (* кластеры *)
                    var TabStat : TuStat (* правая граница интервала *)
                        ) : real;
 var Th,Tm,Ts,Ts100 : word;
 Time1,Int : Real;
 i:integer;
 begin (* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *)
   GETTIME(Th,Tm,Ts,Ts100);
   Time1:=Th*3600.0+Tm*60.0+Ts+Ts100*0.01;
   Int:= Time1-TK; (* интервал от последней засечки *)
   if Int>0
   then begin
          i:=1;
          while (i<8) and (Int>TabStat[i]) do inc(i);
          Stat[i]:=Stat[i]+1;
        end;
   CheckTime:=Time1;
 end; (* CheckTime *)


{$EndIf}

 (* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *)
 (*    Функция проверяет интервал времени, прощедший с момента        *)
 (* последней засечки.  Если он истек, то делается новая засечка      *)
 (* и возвращается истина. Иначе - возвращается ложь                  *)
 (* Для первой засечки задать TK = 0                                  *)
 (* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *)
 Function CheckInterv(var TK   : real; (* последняя засечка *)
                    Interv : real (* Интервал в секундах *)
                        ) : boolean;
 var Th,Tm,Ts,Ts100 : word;
 Time1,Int : Real;
 begin (* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *)
   GETTIME(Th,Tm,Ts,Ts100);
   Time1:=Th*3600.0+Tm*60.0+Ts+Ts100*0.01;
   Int:= Time1-TK; (* интервал от последней засечки *)
   if Int>=Interv
   then begin
          TK:=Time1;
          CheckInterv:=true;
        end
   else CheckInterv:=false;
 end; (* CheckInterv *)

{!S! 11/22/96 }
    (*Очистка буфера клавиатуры *)
procedure cbk;
 var e: TKeyEvent;
  begin
 while keypressed do
 e:=GetKeyEvent;
  end (*CBK*);
    (*Чтение символа из буфера клавиатуры *)
function preskey:boolean;
 var
   e: TKeyEvent;
 begin
{!S! 07/27/97 - Озвучить переключатели }
  {$IFDEF SPON}
    if CapsLockStatus
     then
      if not CapsLock_on
       then
        begin
          CapsLock_on := true;
          SText ('Больши+е.');
        end
       else
     else
      if CapsLock_on
       then
        begin
          CapsLock_on := false;
          SText ('Ма+лые.');
        end;
    if NumLockStatus
     then
      if not NumLock_on
       then
        begin
          NumLock_on := true;
          SText ('Ци+фры.');
        end
       else
     else
      if NumLock_on
       then
        begin
          NumLock_on := false;
          SText ('Курсо+р.');
        end;
    if ScrollLockStatus
     then
      if not ScrollLock_on
       then
        begin
          ScrollLock_on := true;
          SText ('Со скро+ллингом.');
        end
       else
     else
      if ScrollLock_on
       then
        begin
          ScrollLock_on := false;
          SText ('Без скроллинга.');
        end;
  {$ENDIF}
 ASCII:=#0;
 AuxiC:=#0;
 preskey:=true;
 if keypressed then  begin
 e:=GetKeyEvent;
 ascii:=chr(e and $FF);
 if ascii=chr(0) then
 auxic:=chr((e shl 8) and $FF) end
 else preskey:=false;
 end (*PresKey*);
function strchar (s : string) : string;
 {заглавные буквы превращает в строчные}
  var i : integer;
  begin
 for i := 1 to length (s) do begin
  case s [i] of
 'A'..'Z', 'А'..'П' : s[i] := chr (ord (s [i]) + 32);
 'Р'..'Я' : s[i] := chr (ord (s [i]) + 80);
 'Ё',Ukr_Ge,Ukr_Ye,Ukr_Yi,Ukr_I : s[i] := chr (ord (s [i]) +1);
   end {case};
  end {for};
 strchar := s;
    end {strchar};


function GetClusterSize (DiskNum : Byte) : word;
           (*Возвращает размер кластера в байтах *)
           (*накопителя с номером DiskNum (0 - текущий диск) *)
    var REGs : registers;
  begin (*▒GetCklasterSize▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
    regs.AH:=$01C;
    REGs.DL := DiskNum  {};
    INTR($21,REGs);
   GetClusterSize := REGs.AL * REGs.CX {Количество секторов в кластере на их размер в байтах };
end; (* GetClusterSize *)



(* Путь к каталогу, содержащему EXE-файл вызвавшей программы *)
Function SourcePath : string;
  var S : string;
  begin {SourcePath}
    S := ParamStr(0);
    while S[Length(S)] <> '\'
     do
      Delete(S, Length(S), 1);
    Delete(S, Length(S), 1);
    SourcePath := S;
  end;  {SourcePath}

procedure Pause (PauseLeng : Longint);
      (* Пауза в реальном времени *)
      (* В PauzeLeng - милисекунды *)
  begin     (*Pause*)
    Sleep(PauseLeng);
  end;      (*Pause*)

procedure clearBlank(var MM : TULin);
    {Очистка конца строки от пробелов }
  begin {clearBlank}
    while (MM[Length(MM)] = CBlank)
      and (Length(MM) > 0)
     do
      Delete(MM, Length(MM), 1);;
  end;  {clearBlank}

function UpStr (S : string) : string;
 {строчные буквы превращает в заглавные}
    var I : integer;
    begin {UpStr}
      for I := 1 to Length(S)
       do
        begin
          S[I] := UpCode[S[I]];
        end;
      UpStr := S;
    end;  {UpStr}

function ClearLine(Symbols : tULim; Direct : tClearLineDirect; Lin : string) : tULin;
    var I : integer;
        LBuf : tULin;
  begin {ClearLine}
    LBuf := '';
    For I := 1 to Length(Lin)
     do
      if    ((Direct = DeleteFrom) and (not (Lin[I] in Symbols)))
         or ((Direct = LeaveIn) and (Lin[I] in Symbols))
       then
        LBuf := LBuf + Lin[I];
    ClearLine := LBuf;
  end;  {ClearLine}

function GetFreeMemSize : longint; {Возвращает размер свободной станд.пам в байтах }
    type tLink = ^tRec;
         tRec = record
                 Next : tLink;
                 Balast : longint;
             end;  {tRec}
    var FirstPtr,Ptr1,Ptr2 : tLink;
        Rec : tRec;
        Num : longint;
  begin {GetFreeMemSize}
    GetFreeMemSize := $1000000; // FIXME
  end;  {GetFreeMemSize}


begin (*▒ INTER ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
  With  Sav do
    begin
      for MSav:=0 to MaxSav
      do with SSav[MSav] do
        begin
          AdrSav:=nil;
          LenSav:=0;
        end;
    MSav:=0;
    end;
{!S! 07/27/97 - Озвучить переключатели }
  {$IFDEF SPON}
           {Инициализация флагов переключателей}
    CapsLock_on := CapsLockStatus;
    NumLock_on := NumLockStatus;
    ScrollLock_on := ScrollLockStatus;
  {$ENDIF}
end.

