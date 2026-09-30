(*немецкоязычный*)
{$define ukr1 }
{.$define fonon}
{.$define spon}


Unit SPICK; (* процедуры речевого вывода *)
(* Ключи компиляции :                                                     *)
(*    SPON - включение процедур синтеза речи                              *)
(*    FONON - используется Фонемофон                                      *)

interface
uses dos,inter;
type
  TUkrTab = string[64];
const
  UkrTab1:  TUkrTab  ='абвгдеїжзиў∙йклмнопрстуфхцчшщюяь'+
                      'АБВГДЕЇЖЗИЎ°ЙКЛМНОПРСТУФХЦЧШЩЮЯЬ';

  var
     AdrFon : word; (* Номер прерывания текущего драйвера речи *)
     NoSpicSim, (* Список символов (как правило, это разделители) *)
                        (* произнесение которых в данный момент запрещено *)
  AddNoSpSym (* Символы, запрещеные для произнесения
                                    в безнаковом режиме чтения процедуры SText *),
   NoSTextSym,
   NoSTextSymBuf (* Буфер *)
              : TuLim;
 Speak_On (* флаг включенной речи   *) : boolean;
 CyrLang,  (* Селектор кириличных языков*)
 LatLang, (*Селектор латиничных языков *)
 UkrCoding {селектор украинских кодировок}
     : Byte;
 EntireSp{Если false, то слова произносятся раздельно, иначе - слитно}
     : boolean;
 CapitalMessage (* Флаг индикатора заглавных букв в SpLine   *)
          : boolean;
     SpLeng, (* язык произнесения текстов, выбор драйвера       *)
     SooLeng (* язык произнесения названий клавиш  *)
             (* по умолчанию - SpLeng                           *)
     :byte; (* 0 - английский, 1 - русский, 2 - украинский язык  *)

const MaxSpBuf = 1020; (* размер буфера для повторения фраз *)
type TuSpBuf = (* фразы разделены #0, пустая начинается с #0 *)
       record
         SpBuf : array[1..MaxSpBuf] of char;
         sp1 : integer; (*Начало*)
         sp2 : integer; (*Конец*)
         WIn : boolean; (*Истина, если разрешена запись в буфер *)
       end;
 var ClBuf : TuSpBuf; (* Кольцевой буфер для повторения сообщений *)

 const MinTWait:real = 0.3;   (* предельный интервал для раздельного *)
                              (* произнесения вводимых букв (сек.)   *)
 var WSBuf : string;  (* буфер для накапливания непроизнесенных букв *)
     TSWait : real ;    (* момент последнего произнесения буквы *)
     YSWait : boolean;  (* истина, если включен режим слитного произнесения *)

procedure InitSp(vers:byte; (* 0 - нет инициализации                 *)
                            (* 1 - вывод на звуковоой синтезатoр *)
                            (* 2 - вывод на параллельный интерфейс *)
                            (* 4 - вывод на Sound Blaster *)
                 Leng:byte  (* 0 - английский язык *)
                            (* 1 - русский язык *)
                            (* 2 - украинский язык *)
                           );

procedure SetTempVoice( temp:byte (* скорость речи 0-150 *)
                );
procedure SetNumVoice( NVoice:byte (* номер голоса 0-3 *)
                );
procedure SetPortVoice(NPort:byte (* номер порта вывода *)
                      (* 0- отключение звука            *)
                      (* 1- внутренний громкоговоритель,*)
                      (* 2- COVOX (Lpt1),               *)
                      (* 3- COVOX (Lpt2),               *)
                      (* 4- Sound Blaster.              *)
                );
procedure SpkMem(  Sent0:string; (* произносимое предложение *)
                   PtrBuf:pointer; (* адрес выходного буфера *)
               var LBuf:longint;   (* размер буфера в байтах *)
               var FBuf7:longint;   (* число записанных байт  *)
               var ec : word   (* код завершения: 7-переполн.*)
               );

{
procedure SetBrk(NKeys:integer (* количество клавиш останова (до 10)*)
                                (*-1 - любая клавиша *)
                                (* 0 - клавиши игнорируются *)
              );
        {   var MasKey:TuKeyKod;  коды клавиш прерывания   }
             (*

------------------
Прототип: int spkSetBrk(int,key_t far* );
Действие: позволяет  задать  клавиши  останова  (не более 10-ти), при
          нажатии   которых    происходит   немедленное    прекращение
          генерации речи  и возврат  в вызывающую  программу.   Первый
          параметр  типа  int  задает  количество прерывающих клавиш и
          интерпретируется следующим образом:

          -при нулевом  значении не  происходит обработки  прерывающих
           клавиш, возможность останова заблокирована;
          -при   0<1-й параметр<=10   происходит   установка    клавиш
           останова, скен- и статус коды которых  помещены в массив  с
           указателем типа key_t far* (2-й параметр);
          -при значении  параметра равным  -1  для  останова разрешены
           все клавиши клавиатуры (см. пример EXAMPLE.C).

          Тип key_t определен в speak.h как:
          typedef struct{
          unsigned char scancode;
          unsigned char status;
          } key_t;

          Статус-байт   должен   содержать  информацию   о   положении
          шифт-клавиш (Shift, Ctrl, Alt), состояние триггерных  клавиш
          (ScrollLock,  NumLock,  CapsLock  и  т.д.)  не  проверяется.
          Структура статус-байта следующая:
          -бит 0 =1, если нажата и не отпущена клавиша RightShift;
          -бит 1 =1, если нажата и не отпущена клавиша LeftShift;
          -бит 2 =1, если нажата и не отпущена клавиша Ctrl;
          -бит 3 =1, если нажата и не отпущена клавиша Alt;

Значение: код ошибки (0, 1 или 2).
*)
function SpInterrupt(var b1,b2 : byte): boolean;

procedure SpContinue;

(*
Функция spkGetKey.
------------------
Прототип: key_type spkGetKey (void);
Действие: получить код клавиши, вызвавшей останов.
Значение: переменная  типа   key_t,  содержащая скен- и статус-коды
          прерывающей  клавиши  (0  -если  останова не произошло) (см.
          пример EXAMPLE.C).

          Статус-код содержит информацию о состоянии шифт- и
          триггерных клавиш, полученную при помощи прерывания 16H
          (функция 2):
          -бит 0 =1, если нажата и не отпущена клавиша RightShift;
          -бит 1 =1, если нажата и не отпущена клавиша LeftShift;
          -бит 2 =1, если нажата и не отпущена клавиша Ctrl;
          -бит 3 =1, если нажата и не отпущена клавиша Alt;
          -бит 4 =1, если зафиксирован скроллинг экрана (ScrollLock);
          -бит 5 =1, если включена цифровая клавиатура (NumLock);
          -бит 6 =1, если зафиксирован верхний регистр (CapsLock);
          -бит 7 =1, если включен режим вставки  (Ins).

          *)


procedure SText00 (Sent00 : string (* произносимое предложение *)
                                  (* без предварительной обработки строки *) );
procedure Stext(Sent1 : string (* произносимое предложение *));

procedure SNamKey(M,A: char (* Основной и дополнительный *)
                             (* код клавиатуры            *));
Procedure SpLine(BBL: TuLin;(* Произносимая строка *)
               var Cur : word; (* Начало произнесения *)
               var BTL: TuLin (* последний (непроизнесенный) участок *)  );

(*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
(* Процедура помещает фразы в кольцевой буфер.           *)
(*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
procedure ToSpBuf(st: string; var Sp: TuSpBuf);

(*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
(* Процедура извлекает фразу N из кольцевого буфера.     *)
(*  N = 1 - последняя занесенная фраза.                  *)
(*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
procedure FromSpBuf(var Sp: TuSpBuf; n:integer; var st: string );


procedure U_R_SText(Sent0:string
(* произносимое предложение украино-русского текста *));


implementation (*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
uses Keyboard, SdrvPrim; {//ss/26.03.2003 20:24:13//}

VAR PTex : string[32] (* См. SNamKey *);
(*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
(* Процедура помещает фразы в кольцевой буфер.           *)
(*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
procedure ToSpBuf(st: string; var Sp: TuSpBuf);
var l:integer; (* размер фразы *)
    i:integer;
    W : boolean;

  procedure RStep(var J1 : integer);
  begin
    inc(j1);
    if j1>MaxSpBuf
    then j1:=1;
  end; (* RStep *)

begin
  l:=length(st);
  if (l>0) and sp.WIn
  then
  begin
  W:=false;
  for i:=1 to l do
    begin
      RStep(sp.sp2);
      sp.SpBuf[sp.sp2]:=St[i];
      if sp.sp2=sp.sp1
      then W := true;
    end;
  RStep(sp.sp2);
  sp.SpBuf[sp.sp2]:=#0;
  if sp.sp2=sp.sp1
  then W := true;
  if sp.sp1<=0 then sp.sp1:=1;

  if W (* было перекрытие начала *)
  then
    begin  (* сдвинуть начало на следующую фразу *)
       sp.sp1:=sp.sp2+1;
       while (sp.sp1<>sp.sp2) and (sp.SpBuf[sp.sp1]<>#0)
       do RStep(sp.sp1);
       RStep(sp.sp1);
    end;
  end;

end; (* ToSpBuf *)

(*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
(* Процедура извлекает фразу N из кольцевого буфера.     *)
(*  N = 1 - последняя занесенная фраза.                  *)
(*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)

procedure FromSpBuf(var Sp: TuSpBuf; n:integer; var st: string );
var l:integer; (* размер фразы *)
    i,j,j1,j2:integer;
    W : boolean; (* истина, если можно продолжать поиск *)

  procedure LStep(var J1 : integer);
  begin
    dec(j1);
    if j1<=0
    then j1:=MaxSpBuf;
  end; (* LStep *)

  procedure RStep(var J1 : integer);
  begin
    inc(j1);
    if j1>MaxSpBuf
    then j1:=1;
  end; (* RStep *)

begin
  if (sp.sp1>0) and (sp.sp2>0) and (n>0) then
  begin
  j:=0;
  j2:=sp.sp2;
  j1:=j2;
  W:=true;
  st:='';
  while (j<n) and W do
    begin
      j2:=j1;
      LStep(j1);
      while (j1<>sp.sp1) and (sp.SpBuf[j1]<>#0) do LStep(j1);
      W:= (j1<>sp.sp1); (* есть следующая фраза *)
      inc(j);
    end;
  if j=n
  then
    begin
      if W then RStep(j1);
      i:=j1;
      while i<>j2 do
        begin
          st:=st+sp.SpBuf[i];
          RStep(i);
        end;
    end;
  end;
end; (* FromSpBuf *)


procedure InitSp(vers:byte; (* 0 - нет инициализации, если драйвер  *)
                            (* уже установлен, то берутся его параметры *)
                            (* 1 - вывод на звуковой синтезатoр *)
                            (* 2 - вывод на параллельный интерфейс *)
                            (* 4 - вывод на Sound Blaster *)
                 Leng:byte  (* 0 - английский язык *)
                            (* 1 - русский язык *)
                            (* 2 - украинский язык *)
                           );

type taa = record (* для разбора параметров драйвера *)
            a1,a2,a3,a4,a5,a6 : word;
          end;
     tbb = ^Taa;  (* для базирования структуры разбора *)

var Regs : registers;
     AdFon : pointer; (* Адрес размещения драйвера в памяти *)
     aa : taa absolute AdFon; (* для арифм.опер. с адресом в памяти *)
     bb : tbb; (* указатель разбора параметров и маски *)
     cc : taa;
     kk: array[1..20] of byte;
     SPar: array[1..10] of word;(* для параметров драйвера *)
     maska: word; (* маска для проверки наличия драйвера в памяти *)
  Begin (*InitSp ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
    telm:=0;
    AdrFon:=0;
    SpLeng:=Leng;
    SooLeng:=Leng;
{$IfDef FONON}
{$IfDef OLD}
    if vers>=0
    then
    begin {0}
      case Leng of
          1:  begin
                AdrFon:=$80;
                maska:=1235;
              end;
          2:  begin
                AdrFon:=$82;
                maska:=$1234;
              end;
      end; {case}
    GetIntVec(AdrFon,AdFon);
    dec(AA.a1,2);  { адрес на 2 байта выше размещения драйвера }
    bb:=AdFon;
    if (bb^.a1=maska)  { есть драйвер }
    then
    begin
      if vers=0  { взять параметры из драйвера }
      then
       begin
          regs.AH:=15;
          regs.AL:=0;
          regs.ES:=Seg(SPar[1]);
          regs.DI:=Ofs(SPar[1]);
          INTR(AdrFon,REGs); (* параметры по адресу ES:DI *)
          if Leng=2
          then
            begin
              if Regs.Ax=0
              then Telm:=SPar[4]
              else Telm:=1;  (* направление вывода речи *)
           (*   Writeln('AX=',regs.ax,' SPar= ',SPar[1],'  ',
              SPar[2],'  ',SPar[3],'  ',SPar[4]); *)
            end
          else
            begin
              bb:=ptr(Regs.Dx,Regs.Ax);
              if (Regs.Ax>255) and (bb^.a4>0) and (bb^.a4<5)
              then Telm:=bb^.a4
              else Telm:=1;  (* направление вывода речи *)
            (*  Writeln('AX=',regs.ax,' bb= ',bb^.a1,'  ',
              bb^.a2,'  ',bb^.a3,'  ',bb^.a4);      *)
            end;
        end
       else
         begin
          Telm:=vers;
            {If (Telm=0) then Telm:=1;}
          regs.AH:=5;
          REGs.AL:=vers;
          INTR(AdrFon,REGs); (* Установить направление вывода речи *)
        end;
   (*       regs.AH:=11;
         { REGs.AL:=0; }
          regs.CX:=word(-1);
          kk[1]:=1;
          kk[2]:=0;
          kk[3]:=29;
          kk[4]:=0;
          kk[5]:=56;
          kk[6]:=0;
          kk[7]:=16;
          kk[8]:=0;
          regs.ES:=Seg(kk[1]);
          regs.SI:=Ofs(kk[1]);
          INTR(AdrFon,REGs); { Установить прерывание от клавиатуры }
    *)
      end
    else
      begin
        AdrFon:=0;
        TELM:=0;
      end;
    end; {0}
{$Else}
  AdrFon:=SdrvInt;
{$EndIf}
{$EndIf}
  end; (* InitSp *)

procedure SetTempVoice( temp:byte
                );
var Regs : registers;
Begin (*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
{$IfDef FONON}
if AdrFon>0 then
begin
   {$ifdef Old}
   regs.AH:=4;
   REGs.AL:=temp; (* Ускоренное произношение *)
   INTR(AdrFon,REGs);
   {$else}
   SpkSetTemp(TspTempo(Temp));
   {$endif}
end;
{$EndIf}
end; (* InsTempVoice *)

procedure SetNumVoice( nvoice : byte (* номер голоса 0-3 *)
                    );
var Regs : registers;
Begin (*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
{$IfDef FONON}
if AdrFon>0 then
begin
   {$ifdef Old}
   regs.AH:=2;
   REGs.AL:=nvoice;  (* Второй мужской голос   *)
   INTR(AdrFon,REGs);
   {$else}
   SpkSetVoice(TspVoice(nvoice));
   {$endif}
end;
{$EndIf}
end; (* InsNunVoice *)

procedure SetPortVoice(NPort:byte (* номер порта вывода *)
                      (* 0- отключение звука            *)
                      (* 1- внутренний громкоговоритель,*)
                      (* 2- COVOX (Lpt1),               *)
                      (* 3- COVOX (Lpt2),               *)
                      (* 4- Sound Blaster.              *)
                );
var Regs : registers;
Begin (*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
{$IfDef FONON}
if AdrFon>0 then
begin
   {$ifdef Old}
   regs.AH:=5;
   Telm:=NPort;
   REGs.AL:=Telm;
   INTR(AdrFon,REGs);
   {$else}
   SpkSetOutput(TspOutput(nport));
   {$endif}
end;
{$EndIf}
end; (* InsNunVoice *)

function SpInterrupt(var b1,b2 : byte): boolean;
var Regs : registers;
begin
{$IfDef FONON}
if AdrFon>0 then
begin
   {$ifdef Old}
    b1:=0;
    b2:=0;
   regs.AH:=13;
   regs.Al:=0;
   INTR(AdrFon,REGs);
   if regs.AX=0 then SpInterrupt:=false
   else begin
          b1:= regs.AL; (* Скен-код *)
          b2:= regs.AH; (* статус :
          -бит 0 =1, если нажата и не отпущена клавиша RightShift;
          -бит 1 =1, если нажата и не отпущена клавиша LeftShift;
          -бит 2 =1, если нажата и не отпущена клавиша Ctrl;
          -бит 3 =1, если нажата и не отпущена клавиша Alt;
          -бит 4 =1, если зафиксирован скроллинг экрана (ScrollLock);
          -бит 5 =1, если включена цифровая клавиатура (NumLock);
          -бит 6 =1, если зафиксирован верхний регистр (CapsLock);
          -бит 7 =1, если включен режим вставки  (Ins).
                                    *)
          SpInterrupt:=true;
   end;
   {$else}
   RunError(303);
   {$endif}
end;
{$EndIf}
end; (* SpInterrupt  *)

procedure SpContinue;
var Reg : registers;
    Sent:string[2];
begin
{$IfDef FONON}
if AdrFon>0 then
begin
   reg.AH:=10;
   INTR(AdrFon,REG);
     REG.es:=Seg(Sent);
     REG.si:=Ofs(Sent)+1;
     REG.cx:=1;
     Sent[1]:=',';
     reg.ax:=256;
   INTR(AdrFon,REG);
end;
{$EndIf}
end; (* SpContinue *)

procedure SpkMem(  Sent0:string; (* произносимое предложение *)
                   PtrBuf:pointer; (* адрес выходного буфера *)
               var LBuf:longint;   (* размер буфера в байтах *)
               var FBuf7:longint;   (* число записанных байт  *)
               var ec : word   (* код завершения: 7-переполн.*)
               );
var Reg : registers;
    Sent:string[2];
    ss:array[1..2] of word absolute PtrBuf;
    sl:array[1..2] of word absolute LBuf;
begin
{$IfDef FONON}
if AdrFon>0 then
begin
   reg.AH:=9;
   REG.es:=SS[2];
   REG.di:=SS[1];
   REG.dx:=sl[2];
   REG.cx:=sl[1];
   REG.bx:=seg(FBuf7);
   REG.si:=ofs(FBuf7);
   INTR(AdrFon,REG);
   ec:=reg.ax;
{   ASM
    push    SI
    push    DI
    push    ES
        LES     DI,pointer               ;ES:DI= buffer address
        mov     cx,WORD PTR length+0     ;DX:CX= buffer size
        mov     dx,WORD PTR length+2
        mov     SI,WORD PTR act_length+0 ;BX:SI= address to return of actual
        mov     bx,WORD PTR act_length+2 ;  speech size
        mov     AH,MEMR_FUN              ;AH = Switch Speech To Memory function
    int     INTERRUPT                ;call Speech Driver
        pop ES
    pop DI
    pop SI
    ret
}
end;
{$EndIf}
end; (* SpkMem *)



procedure InitKeys(var UkrTab1 : TUkrTab);

type taa = record
            a1,a2 : word;
          end;

var Regs : registers;
     AdFon : pointer;
     aa : taa absolute AdFon;
     CodeTab: string[64];
Begin (*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
{$IfDef FONON}
if AdrFon>0 then
begin
  if SpLeng=2
  then
    begin
     regs.AH:=16;  (* загрузить таблицу *)
     REGs.AL:= 0;
     AdFon:=@UkrTab1[1];
     regs.Es:=aa.a2;
     REGs.Si:=aa.a1;
     INTR(AdrFon,REGs);
    end;
end
{$EndIf}
end; (* InitKeys *)


(*▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)



procedure SText00 (Sent00 : string (* произносимое предложение *)
                                  (* без предварительной обработки строки *) );
     var REG : registers;
f : text;
     begin {SText00}
{$IfDef SentTest}
assign (f, 'test.spk');
{$I-} append (f); {$I+}
 if IOResult = 2 then reWrite(F);
 writeln (f, sent00,Length(Sent00));
 close (f);
 {$EndIf}
  {$IfDef FonOn}

    if (AdrFon > 0) and Speak_On then
      begin  {Обращение к драйверу синтезатора речи}
     {$ifdef Old}
{     Sent00 := copy (Sent00, 1, 250) (*Воизбежание переполнения*);}
     REG.ES:=Seg(Sent00);
     REG.SI := Ofs(Sent00) +1;
     REG.CX:=length(Sent00) +1;
     Sent00 [Reg.CX]:=',';
     reg.AX:=256;
          Intr(AdrFon,REG);
     {$else}
     SdrvPrim.SText00(Sent00);
     {$endif}
    end {Speak_On};
  {$EndIf}
  end {SText00};




procedure U_R_SText(Sent0:string
(* произносимое предложение украино-русского текста *));
 var
     Sent: string;
     i,k,l,{:word;}
             SameSymCounter {Количество подряд идущих одинаковых символов } : byte;
             SameSym : char;
 nules : boolean; {флаг произнесения  незначащих нулей }
 Silence : boolean; { Индикатор непроизносимых символов  }


function CharName (Ch : char) : TULin;
    {Возвращает название символа Ch}
      var BBuf : boolean;
  begin {CharName}
    BBuf := Speak_on;
    Speak_On := false {Выключаем звук};
    SNamKey (Ch, #0) {Название в PTex};
    Speak_On := BBuf {Включить звук};
    CharName := PTex;
  end {CharName};

 procedure WordFinder;
         {ставит k  на начало последовательности русских или латинских букв}
  procedure ManySameSymbols;
    { Заменяет  длинные последовательности одинаковых символов }
    { На вербальное сообщение }
  begin {ManySameSymbols}
    if (SameSym <> Sent0[K -1])
       and not (Sent0[K -1] in NoSTextSym + [#0..cBlank])
     then
      begin
        if Length (Sent) < 100
         then
          if SameSymCounter <= 20
           then
            Sent := Sent + ', Не+сколько '
           else
            if  SameSymCounter <= 80
             then
              Sent := Sent + ', Многа '
             else
              Sent := Sent + 'Очень многа ';
            if Length (Sent) < 175
             then
              Sent := Sent + ' символов ' + CharName (Sent0[K -1]) + ', ';
            SameSym := Sent0[K -1];
      end;
    I := K;
    SameSymCounter := 0;
  end;     {ManySameSymbols}

  begin {wordfinder}
    while (not (upcode [sent0 [k]] in Alphabet))
      and (k <= l)
      do
      begin
        inc (k);
          {Отслеживание длинных последовательностей одинаковых символов }
        if (Sent0[K] = Sent0[K -1])
          and (not (Sent0[K] in ['0' .. '9']))
        then inc (SameSymCounter)
        else
          if SameSymCounter > 3
            then
              if I < K - SameSymCounter
                then
                  begin
                    K := K - SameSymCounter;     { Сначало обработать участок слева}
                    (*SameSymCounter := 0;*)
                  end
                else ManySameSymbols
            else SameSymCounter := 0;
      end;
  end {wordfinder};

 function WordTester : boolean;
(*!S! 04/09/97*)
      {Дает добро на произнесение слова как абривиатуры }
 var
     WordBeg : boolean {Флаг начала слова};
     NoAb : boolean {Флаг недопустимых в абривиатуре букв};
     BB : boolean {false если в слове найдена хоть одна строчная буква};
     RusWord : boolean {false если в слове найдена хоть одна нерусская буква};
     NumVowels : byte {счетчик гласных букв в слове};
     slovo : string [5] {Зарезервированое слово };
 begin {wordtester}
{Writeln (#7);}
    NoAb := False;
    BB := true {false если в слове найдена хоть одна строчная буква};
{    RusWord := true;}
    WordBeg := true {Флаг начала слова};
    NumVowels := 0 {счетчик гласных букв в слове};
            {перебираем все буквы от i до конца слова}
 while  (upcode [sent0 [k]] in Alphabet) {Пока одни только буквы}
                   and (not (sent0 [k] in Alphabet) {k-ая - большая}
                        or not (upcode [sent0 [k +1]] in Alphabet) {а после нее - маленькая}
                        or  (sent0 [k +1] in Alphabet) {и только - маленькая}
                        or WordBeg) {и разрешен останов}
                   and (not (Sent0[k] in Alphabet) {Останов напервой}
                        or  BB)                    {после череды маленmких, большой букве}
                   and (k <= l) {И строка не исчерпана}
                       do begin
                                   if upcode [sent0 [k]] in Vowels then inc (NumVowels);
                                   if not (sent0 [k] in Alphabet) then BB := false;

{                                   if not (sent0 [k] in RusAlphabet) then RusWord := false;}
                                   if upcode [sent0 [k]] in
                                         ['Ы', 'Я', 'Ё', 'Ь', 'Ъ', 'Й']
                                   THEN NoAb := true {Эти буквы не входят в абривиатуры};
                                   WordBeg := false;
                                   inc (k);
                      end {while};
{учтём ударения}
         if (sent0 [i -1] in ['+', '=']) {если стоит ударение }
         and (UpCode[sent0 [i]] in RusAlphabet) {перед русской буквой}
         and (UpCode[sent0 [i -2]] in RusVowels) {и после русской гласной}
      then wordtester := false {то произносим как слитное слово}
      else if k = i + 1 then{Правильно произнесем однобуквенные согласные предлоги }
         if (sent0 [k] in [CBlank, '_'])
         and (upcode [sent0 [i]] in ['Б', 'В', 'К', 'С'])
     or (sent0 [k] in ['''', Ukr_Apo]){перед апострофомм}
         and (upcode [sent0 [i]] in ['Б', 'В', 'Д', 'К', 'Л', 'М', 'П']) {в украинском слове}
         and (upcode [sent0 [k +1]] in [Ukr_Yi, Ukr_Ye, 'Ю', 'Я']) {иперед сложными гласными}
      then wordtester := false
        else { учтём все остальные одинокие английские и русские буквы, включая гласные}
                       wordtester := true
         else begin              {Проверим зарезервированые слова}
         if NumVowels > 0 then begin {прямой перебор }
              slovo := copy (sent0, i, k - i);
            if (slovo = 'USA')
       or (slovo = 'ОБСЕ')
           then wordtester := true
              else {Второй уровень более тонкой проверки}
            if BB
               and not NoAb
               and ((NumVowels = 1)
               and ((Sent0[i] in Vowels)
                or (Sent0[k -1] in Vowels))
               or (NumVowels = K -I)) {Это Если одни только заглавные гласные }
               and (Slovo <> 'ГДЕ') {Исключения}
               and (Slovo <> 'ДА')
               and (Slovo <> 'ДО')
               and (Slovo <> 'ЗА')
               and (Slovo <> 'ИЗ')
               and (Slovo <> 'КТО')
               and (Slovo <> 'МНЕ')
               and (Slovo <> 'НА')
               and (Slovo <> 'НЕ')
               and (Slovo <> 'ОН')
               and (Slovo <> 'ПО')
               and (Slovo <> 'США')
               and (Slovo <> 'ЧТО')
                        then WordTester := true
         else wordtester := false;
         end {перебор}
         else wordtester := true;
         end {else};
 end {wordtester} ;



 procedure Abriviation;
      {составляет аббревиатуру - произнесение по буквам }
 begin {abriviation}
      { улучшим звучание украинских однобуквенных лексем }
      if (CyrLang=Ukrainian) and (k = i + 1)
         and (sent0 [k] = CBlank)
         and (upcode [sent0 [i]] in ['Й', 'З'])
      then begin
        sent := sent + sent0 [i] + sent0 [i];
         inc (i);
      end {then}
      else begin
           Sent := Sent + '-';
   while i < k do begin
      sent := sent + CharName (Sent0[i]) + ' ';
      inc (i);
   end {while};
      end {else};
      wordfinder {и продвигаемся дальше по строке к следующему слову };
 end {abriviation};







procedure SentMaker;
  const MaxFragLen = 15 {Максимальная длина корректно произносимой записи числа};
        Puncts =['.', '?', '!', ';', ','] {Интонирующие символы};
  var NumBeg {Позиция старшей цифры},
      NamePos {Позиция  псевдоимени класса },
      NumLength {Количество знаков в записи числа} : byte;
      ClassName {ПсевдоИмя слишком большого класса числа } : char;
  begin {SentMaker}
    NumLength := 0;
        {теперь начинаем обработку символов,
         требующих вербальной фонетической адаптации}
    while i < k
     do
      begin
        if not (Sent0[i] in ['0'..'9'])
         then
          begin
            if (NumLength > MaxFragLen)
             then
              begin {Отделяем корректно произносимые фрагменты длинных чисел}
                NamePos := length (Sent) - MaxFragLen {Позиция  псевдоимени класса };
                NumBeg := length (Sent) - Numlength  {Позиция старшей цифры};
                ClassName := 'A';
                while NamePos > NumBeg
                 do
                  begin
                    insert (',' + CharName (ClassName)+ ';', Sent, NamePos);
                    dec (NamePos, 3);
                    inc (ClassName);
                    if ClassName = #91 then ClassName := 'А';
                  end;
              end;
            NumLength := 0;
          end;
            {начнем с символов влияющих на произношение даже при их запрете}
            {в основном это знаки пунктуации}
        if (sent0[i] in Puncts) and not silence
         then Sent := Sent +sent0[i];
        Silence := Sent0[I] in NoSTextSym;
        if Sent0[i] = '.' then Nules := false;
            case {1} sent0[i] of
               '-': if not ('-' in nostextsym)
                      then Sent := Sent +CharName ('-');
               ':' :
                      if sent0[i +1] ='='
                        then begin
                           sent:=sent+' ,Присво+ить, ';
                           inc(i);
                         end
                        else if not (':' in nostextsym) then
                      if CyrLang=Ukrainian then Sent := Sent + 'Двукр' else sent := sent +' ,Дво, '
                        else sent := sent + ':';
         else {case 2}{отрабатываем остальные символы }
         if sent0 [i] in NoSTextSym then
                              Sent := sent + ' '
            {Вместо запрещенного символа}
         else {обработаем незапрещенные символы }
         if LatLang=German
         then {Немецкая транскрипция}
        case {2} UpCode[sent0[i]] of
            'C' :
                begin
                  if (I<K-1)
                  and (UpCode[sent0[i+1]] ='H')
                   then
                    begin
                      if not (UpCode[sent0[i-1]] ='S')
                       then
                        sent:=sent+'х';
                      inc(i);
                    end
                   else
                    if (I<K-1)
                    and ((UpCode[sent0[i+1]] in ['E', 'I'])
                     or (UpCode[sent0[i+1]] = 'Y')
                    and not (UpCode[sent0[i+2]] in EngVowels))
                     then
                      sent:=sent+'Ц'
                     ELSE
                      sent:=sent+'К';
                end;
            'E':
                begin
                  if (I<K-1)
                  and (UpCode[sent0[i+1]] ='I')
                   then
                    begin
                      if UpCode[Sent0[I-1]] = 'L'
                       then
                        sent:=sent+'яй'
                       else
                        sent:=sent+'ай';
                      inc(i);
                    end
                   else
                    if (I<K-1)
                    and (UpCode[sent0[i+1]] ='U')
                     then
                      begin
                        if UpCode[Sent0[I-1]] = 'L'
                         then
                          sent:=sent+'ёй'
                         else
                          sent:=sent+'ой';
                        inc(i);
                      end
                     else
                      if (UpCode[Sent0[I-1]] = 'L')
                       then
                        sent:=sent+'Е'
                       else
                        sent:=sent+'Э';
                end;
            'H' :
                begin
                  if not (UpCode[Sent0[I-1]] in Vowels)
                   then
                    sent:=sent+'Х';
                end;
            'I' :
                begin
                  if (I<K-1)
                  and (UpCode[sent0[i+1]] ='E')
                   then
                    begin
                      sent:=sent+'ИИ';
                      inc(i);
                    end
                   else
                    sent:=sent+'И';
                end;
            'J': sent:=sent+'й';
            'L':
                begin
                  if (I<K-1)
                  and (UpCode[sent0[i+1]] in EngConsonants)
                  or (I = K-1)
                   then
                    sent:=sent+'ль'
                   else
                    sent := sent+'л';
                end;
            'O' : sent:=sent+'О';
            'P':
                begin
                  if (I<K-1)
                  and (UpCode[sent0[i+1]] ='H')
                   then
                    begin
                      sent:=sent+'Ф';
                      inc(i);
                    end
                   else
                    sent:=sent+'П';
                end;
            'Q' : sent:=sent+'К';
            'S':
                begin
                  if (I<K-2)
                  and (UpCode[sent0[i+1]] in EngConsonants - ['S','Z'])
                   then
                    begin
                      sent:=sent+'Ш';
                    end
                   else
                    if (I<K-1)
                  and (UpCode[sent0[i+1]] in Vowels)
                  and (UpCode[sent0[i-1]] <> 'S')
                   then
                    sent:=sent+'З'
                   else
                    sent:=sent+'С';
                end;
            'T' :
                begin
                  if (I<K-2)
                  and (UpCode[sent0[i+1]] = 'C')
                  and (UpCode[sent0[i+2]] = 'H')
                   then
                    begin
                      sent:=sent+'Ч';
                      inc(i,2);
                    end
                   else
                     sent := sent+'Т';
                end;
            'U' : sent := sent + 'У';
            'V' : sent := sent + 'Ф';
            'W' : sent := sent + 'В';
               'X':   if (I<K-1)
                      and (UpCode[sent0[i -1]] in Vowels)
                      and  (UpCode[sent0[i +1]] in Vowels)
                      then sent:=sent+'ГЗ'
                       else sent := sent +'КС';
            'Y' :
                begin
                  if (UpCode[Sent0[I-1]] in Consonants)
                  and ((UpCode[Sent0[I+1]] in Consonants)
                   or (I=K-1)
                   or not (UpCode[Sent0[I+1]] in Alphabet))
                   then
                    Sent := Sent +'И'
                   else
                    Sent := Sent +'Й';
                end;
            'Z' :
                begin
                  if                   (UpCode[sent0[i-1]] <> 'S')
                   then
                    sent := sent + 'Ц'
                   else
                    sent := sent + 'С';
                end;
            'Ж' : if (UpCode[Sent0[i -1]] in RusAlphabet) then Sent := Sent +'Ж'
                                                     else Sent := Sent +'ЖЖ';

{!S! 11/19/96 Предлогаю ввести в Inter новые константы:}
               Ukr_Ge : begin
                      sent := sent +'г';
                   end;
               Ukr_Ye : begin
                      sent := sent +'е';
                   end;
               Ukr_I: begin
                      sent := sent +'и';
                   end;
               Ukr_Yi : begin
                      sent := sent +'йи';
                   end;
               'Ц' : begin
                      if CyrLang=Ukrainian then sent  := sent + 'ТС'
                      else sent := sent + 'Ц';
                   end {Ц};
               'Ё', 'Ы', 'Ъ', 'Э' : begin {включение русского }
                      sent := sent + sent0 [i];
                   end {русский };
               'Ь' :  if upcode[ sent0 [i +1]] = 'О'
                      then begin
                      sent := sent + 'ё';
                      inc (i);
                   end {'Ь'}
                    else sent := sent + 'Ь';
 'Е' : if CyrLang=Ukrainian then sent := sent + 'Э'
  else sent := sent + 'Е';
 'И' : if CyrLang=Ukrainian then sent := sent + 'Ы'
  else sent := sent + 'И';
{!S! 11/19/96 Прямой и альтернативный апострофы  }
              '''', Ukr_Apo : {!S!}
                  if I = 1 then Sent := Sent + CharName (Sent0[i]) +','
                           else
                      case upcode [sent0 [i -1]] of
                           'A'..'Z': if upcode [sent0 [i +1]] <> 'S'
                                     then sent:=sent+',' +CharName (Sent0[I]) +',';
{!S! 11/19/96 Здесь была причина зависания на апострафах в английских словах }
                      'Б', 'В', 'Д', 'К', 'Л', 'М', 'П' :
                           if upcode [sent0 [i +1]]
                            in [Ukr_Yi, Ukr_Ye, 'Ю', 'Я']
                          then begin
                             sent := sent + 'Ь';
                           end
                              else sent:=sent +',' +CharName (Sent0[I]) +',';
                                else sent:=sent +',' +CharName (Sent0[I]) +',';
                   end {case Апострофы };
               '$' : begin
                       Sent := Sent +' ДОЛЛАР';
                       if (Sent0[i -1] = '1') then Sent := Sent +', '
                                          else
                         if (Sent0[i -1] in ['2' .. '4']) then Sent := Sent +'А, '
                                                       else
                  if CyrLang=Ukrainian then Sent := Sent + 'ИВ,'
                     else Sent := Sent +'ОВ, ';
                     end {'$'};
               '%' : begin
                       if CyrLang=Ukrainian then Sent := Sent +'Видсот'
                             else  Sent := Sent +' ПРОЦЕНТ';
                       if (Sent0[i -1] = '1') then
                                if CyrLang=Ukrainian then Sent := Sent + 'ОК,'
                                else Sent := Sent +', '
                                          else
                         if (Sent0[i -1] in ['2' .. '4']) then
                                    if CyrLang=Ukrainian then Sent := Sent + 'КА,'
                                    else Sent :=Sent +'А, '
                             else if CyrLang=Ukrainian then Sent := Sent + 'КИВ,'
                             else Sent := Sent +'ОВ, ';
                     end {%};

               '^': sent:=sent+' ,Крыш, ';
               '|': sent:=sent+' ,Верт, ';
               '+': if (not (upcode [sent0 [i - 1]] in RusVowels))
                        then sent:=sent+' Плюс '
                        else Sent := Sent +'+';
               '=': if (not (upcode [sent0 [i - 1]] in RusVowels))
                        then sent:=sent+' ,Равно, ';
(*               '(' : Sent := Sent +' - ОТКРЫ+ТЬ СКО+БКУ - ';
               ')' : Sent := Sent +' - ЗАКРЫ+ТЬ СКО+БКУ - ';*)
               '.', '!', '?', ';', ',',
               '~', '@', '#', '&', '*', '_',
                         '(', ')', '[', ']', '{', '}', '<', '>', '/', '\', '"' :
                                   Begin {Взять из SNamKey }
                                     Sent := Sent +' ,' +CharName (Sent0[i]) +', ';
                                   end { из SNamKey };
               '0' .. '9' : begin
                      if (Sent0 [i] = '0')
                          and (sent0 [i +1] = '.')
                          and ((not (nules or (sent0 [i -1] in ['0' .. '9']))) or nules)
                          and ('.' in nostextsym)
                        then sent := sent + 'ноль 0'
                        else
                      if (Sent0 [i] = '0')
                          and (not (((Sent0 [i - 1] in ['0' .. '9'])
                          or ('.' in nostextsym)
                          and ((sent0 [i -1] = '.') or (sent0 [i +1] = '.'))))
                          or nules)
                        then begin
                          sent := sent + ' Ноль ';
                          nules := true;
                        end
                        else  begin
                          sent := sent +Sent0[i];
                          nules := false;
                          inc (NumLength);
                        end;
                      if not (Sent0 [i +1]   in ['0' .. '9', '.']) then sent := sent +',';
                      end {0..9};
               else {case 2} sent:=sent+UpCode[Sent0[i]];
          end (* case 2*)
          else {Английская транскрипция }
         case {2} UpCode[sent0[i]] of
{!S! 11/19/96 }
               'C': if (I<K-1) and (UpCode[sent0[i+1]] ='H')
                      then begin
                           sent:=sent+'Ч';
                           inc(i);
                         end
                    else
{!S! 11/22/96 }
                      if (I<K-1)
                     and ((UpCode[sent0[i+1]] in ['E', 'I'])
                      or (UpCode[sent0[i+1]] = 'Y')
                       and not (UpCode[sent0[i+2]] in EngVowels))
                    then  sent:=sent+'Ц'
                   ELSE sent:=sent+'К';
{!S! 11/19/96 }
             'E': if (I<K-1) and (UpCode[sent0[i+1]] ='W')
                    then begin
                           sent:=sent+'ЬЮ';
                           inc(i);
                         end
                    else if (I<K-1) and (UpCode[sent0[i+1]] ='A')
                    then begin
                           sent:=sent+'И';
                           inc(i);
                         end
                    else if (I<K-1) and (UpCode[sent0[i+1]] ='E')
                    then begin
                           sent:=sent+'ИИ';
                           inc(i);
                         end
                    else sent:=sent+'Э';
               'H': sent:=sent+'Х';
               'J': sent:=sent+'ДЖ';
{!S! 11/19/96 }
               'O': if (I<K-1) and (UpCode[sent0[i+1]] ='O')
                    then begin
                           sent:=sent+'УУ';
                           inc(i);
                         end
                    else sent:=sent+'О';
{!S! 11/19/96 }
               'P': if (I<K-1) and (UpCode[sent0[i+1]] ='H')
                    then begin
                           sent:=sent+'Ф';
                           inc(i);
                         end
                    else sent:=sent+'П';
               'Q': sent:=sent+'К';
{!S! 11/19/96 }
               'S': if (I<K-1) and (UpCode[sent0[i+1]] ='H')
                    then begin
                           sent:=sent+'Ш';
                           inc(i);
                         end
                    else sent:=sent+'С';
{!S! 11/19/96 }
               'T': if (I<K-1) and (UpCode[sent0[i+1]] ='H')
                    then begin
                           sent:=sent+'З';
                           inc(i);
                         end
                    else sent:=sent+'T';
{!S! 11/19/96 }
{!S! 11/19/96  }
               'X':   if (I<K-1)
                      and (UpCode[sent0[i -1]] in Vowels)
                      and  (UpCode[sent0[i +1]] in Vowels)
                      then sent:=sent+'ГЗ'
                       else sent := sent +'КС';
               'W': sent:=sent+'В';
{!S! 11/19/96 }
               'Y' : if (UpCode[Sent0[I-1]] in Consonants)
                     and ((UpCode[Sent0[I+1]] in Consonants)
                      or (I=K-1)
                      or not (UpCode[Sent0[I+1]] in Alphabet))
                       then Sent := Sent +'Ы'
                       else Sent := Sent +'Й';
{!S! 12/3/96 }
               'Z': if (I<K-1) and (UpCode[sent0[i+1]] ='H')
                    then begin
                           sent:=sent+'ЖЖ';
                           inc(i);
                         end
                    else sent:=sent+'З';
               'Ж' : if (UpCode[Sent0[i -1]] in RusAlphabet) then Sent := Sent +'Ж'
                                                     else Sent := Sent +'ЖЖ';

{!S! 11/19/96 Предлогаю ввести в Inter новые константы:}
               Ukr_Ge : begin
                      sent := sent +'г';
                   end;
               Ukr_Ye : begin
                      sent := sent +'е';
                   end;
               Ukr_I: begin
                      sent := sent +'и';
                   end;
               Ukr_Yi : begin
                      sent := sent +'йи';
                   end;
               'Ц' : begin
                      if CyrLang=Ukrainian then sent  := sent + 'ТС'
                      else sent := sent + 'Ц';
                   end {Ц};
               'Ё', 'Ы', 'Ъ', 'Э' : begin {включение русского }
                      sent := sent + sent0 [i];
                   end {русский };
               'Ь' :  if upcode[ sent0 [i +1]] = 'О'
                      then begin
                      sent := sent + 'ё';
                      inc (i);
                   end {'Ь'}
                    else sent := sent + 'Ь';
 'Е' : if  CyrLang=Ukrainian then sent := sent + 'Э'
  else sent := sent + 'Е';
 'И' : if CyrLang=Ukrainian then sent := sent + 'Ы'
  else sent := sent + 'И';
{!S! 11/19/96 Прямой и альтернативный апострофы  }
              '''', Ukr_Apo : {!S!}
                  if I = 1 then Sent := Sent + CharName (Sent0[i]) +','
                           else
                      case upcode [sent0 [i -1]] of
                           'A'..'Z': if upcode [sent0 [i +1]] <> 'S'
                                     then sent:=sent+',' +CharName (Sent0[I]) +',';
{!S! 11/19/96 Здесь была причина зависания на апострафах в английских словах }
                      'Б', 'В', 'Д', 'К', 'Л', 'М', 'П' :
                          begin
                            if upcode [sent0 [i +1]]
                              in [Ukr_Yi, Ukr_Ye, 'Ю', 'Я']
                             then
                              begin
                                sent := sent + 'Ь';
                              end
                             else sent:=sent +',' +CharName (Sent0[I]) +',';
                          end;
                           else sent:=sent +',' +CharName (Sent0[I]) +',';
                   end {case Апострофы };
               '$' : begin
                       Sent := Sent +' ДОЛЛАР';
                       if (Sent0[i -1] = '1') then Sent := Sent +', '
                                          else
                         if (Sent0[i -1] in ['2' .. '4']) then Sent := Sent +'А, '
                                                       else
                  if CyrLang=Ukrainian then Sent := Sent + 'ИВ,'
                     else Sent := Sent +'ОВ, ';
                     end {'$'};
               '%' : begin
                       if CyrLang=Ukrainian then Sent := Sent +'Видсот'
                             else  Sent := Sent +' ПРОЦЕНТ';
                       if (Sent0[i -1] = '1') then
                                if CyrLang=Ukrainian then Sent := Sent + 'ОК,'
                                else Sent := Sent +', '
                                          else
                         if (Sent0[i -1] in ['2' .. '4']) then
                                    if CyrLang=Ukrainian then Sent := Sent + 'КА,'
                                    else Sent :=Sent +'А, '
                             else if  CyrLang=Ukrainian then Sent := Sent + 'КИВ,'
                             else Sent := Sent +'ОВ, ';
                     end {%};

               '^': sent:=sent+' ,Крыш, ';
               '|': sent:=sent+' ,Верт, ';
               '+': if (not (upcode [sent0 [i - 1]] in RusVowels))
                        then sent:=sent+' Плюс '
                        else Sent := Sent +'+';
               '=': if (not (upcode [sent0 [i - 1]] in RusVowels))
                        then sent:=sent+' ,Равно, ';
(*               '(' : Sent := Sent +' - ОТКРЫ+ТЬ СКО+БКУ - ';
               ')' : Sent := Sent +' - ЗАКРЫ+ТЬ СКО+БКУ - ';*)
               '.', '!', '?', ';', ',',
               '~', '@', '#', '&', '*', '_',
                         '(', ')', '[', ']', '{', '}', '<', '>', '/', '\', '"' :
                                   Begin {Взять из SNamKey }
                                     Sent := Sent +' ,' +CharName (Sent0[i]) +', ';
                                   end { из SNamKey };
               '0' .. '9' : begin
                      if (Sent0 [i] = '0')
                          and (sent0 [i +1] = '.')
                          and ((not (nules or (sent0 [i -1] in ['0' .. '9']))) or nules)
                          and ('.' in nostextsym)
                        then sent := sent + 'ноль 0'
                        else
                      if (Sent0 [i] = '0')
                          and (not (((Sent0 [i - 1] in ['0' .. '9'])
                          or ('.' in nostextsym)
                          and ((sent0 [i -1] = '.') or (sent0 [i +1] = '.'))))
                          or nules)
                        then begin
                          sent := sent + ' Ноль ';
                          nules := true;
                        end
                        else  begin
                          sent := sent +Sent0[i];
                          nules := false;
                          inc (NumLength);
                        end;
                      if not (Sent0 [i +1]   in ['0' .. '9', '.']) then sent := sent +',';
                      end {0..9};
               else {case 2} sent:=sent+UpCode[Sent0[i]];
          end; (* case 2*)
          end {case 1};
          inc(i) {переходим к следующему символу};
        end {while};
        WordFinder;
 end {SentMaker};

function InsUmlauts(Lin : string) : string;

procedure DivideWords(var Lin : string; Prep : string);
    var Lin1 : string;
  begin {DivideWords}
    Lin1 := UpStr(Lin);
    if Pos(Prep,Lin1) > 0
     then
      insert(cBlank,Lin,Pos(Prep,Lin1) +Length(Prep));
  end;  {DivideWords}

    var I : integer;

  begin {InsUmlauts}
    DivideWords(Lin,' AUS');
    for I := 1 to Length(Lin)
     do
      begin
        if (Lin[I] in [A_umlaut,O_umlaut,U_umlaut,A_umlaut_,O_umlaut_,U_umlaut_]) and
           ((UpCode[Lin[I-1]] in EngAlphabet) or
           (UpCode[Lin[I+1]] in EngAlphabet))
         then
          begin
              case Lin[I] of
                  A_umlaut,A_umlaut_ :
                      begin
                        Lin[I] := _A_umlaut;
                      end;
                  O_umlaut,O_umlaut_ :
                      begin
                        Lin[I] := _O_umlaut;
                      end;
                  U_umlaut, U_umlaut_ :
                      begin
                        Lin[I] := _U_umlaut;
                      end;
              end;  {case}
          end;
      end;
    InsUmlauts := Lin;
  end;  {InsUmlauts}




  procedure
  DelSpaces(var MM : string); {Удаление последовательностей пробелов}
        var I  : integer;
            SB : string;
            B  : boolean;
    begin {DelSpaces}
      SB := '';
      for I := 1 to Length(MM)
       do
        begin
          if MM[I] <> cBlank then B := true;
          if B
           then
            begin
                  if UkrCoding = UkrWordCoding
                   then
                    case MM[I] of
                        #242 : MM[I] := Ukr_Ye; (* Заглавное 'Ї' *)
                        #243 : MM[I] := _Ukr_Ye; (* строчное  'ї' *)
                        #244 : MM[I] := Ukr_Yi; (* Заглавное '°' *)
                        #245 : MM[I] := _Ukr_Yi; (* строчное  '∙' *)
                        #248 : MM[I] := Ukr_Ge ; (* Заглавное твёрдое Гэ *)
                        #249 : MM[I] := _Ukr_Ge; (* строчное твёрдое Гэ *)
                    end;  {case}
                    case MM[I] of
                        '''','`' :
                            begin
                              if (CyrLang = Ukrainian) and
                                 (I > 1) and (I < Length(MM)) and
                                 (UpCode[MM[I-1]] in RusConsonants) and
                                 (((UkrCoding = UkrLexCoding) and
                                 (UpCode[MM[I+1]] in ['Я','Ю',Ukr_Ye,Ukr_Yi])) or
                                 ((UkrCoding = UkrWordCoding) and
                                 (UpCode[MM[I+1]] in ['Я','Ю',#242,#244])))
                               then {Подставляем вместо апострофа твёрдый знак}
                                begin
                                  SB := SB +'ъ';
                                end
                               else
                                begin
                                  SB := SB + MM[I];
                                end;
                            end;
                        else {case} SB := SB + MM[I];
                    end;  {case}
            end;
          if MM[I] = cBlank then B := false;
        end;
      MM := SB;
    end;  {DelSpaces}

begin { * U_R_stext *▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒* }
  Silence := true;

    SameSymCounter := 0;
    SameSym := #0;
{$ifdef spon}
 if speak_on then
 begin
{$IfDef SimpleFon}
    SText00 (Sent0);
{$else}
  DelSpaces(Sent0);
  nules := false;
{!S! 11/22/96 - Добавляя в начале два пробела и тестируя строку с третьей позиции
    мы избегаем множества проверок корректности индексирования }
     sent0:=CBlank+CBlank+sent0+CBlank+CBlank;
  if LatLang=German then Sent0 := InsUmlauts(Sent0);{Подставляем умляуты в строку текста}
     l:=length(Sent0);
     sent0:=sent0+CBlank;
     sent := CBlank;
     i:=3;
     k:=1;
     wordfinder;
     while i < l do
                      begin {Подвергаем фонетическому анализу каждый символ Sent0}
              {И формируем произносимую строку Sent}
                   {До тех пор пока действительно не закончится слово}
       if UpCode[Sent0[i]] in Alphabet then
              if WordTester then Abriviation
                            else SentMaker
                        else SentMaker;
              if Length(Sent) > 200
                then
                  begin (* Чтобы не переполнить строку *)
                    SText00 (Sent);
                    Sent := CBlank;
                    if KeyPressed then I := L (*Непродолжать чтения *);
                  end;
                end {i<l};
                SText00 (Sent);
{$EndIf}
 end {speak_on};
{$endif}
end; { U_R_Stext }

PROCEDURE SText (Sent1:string
           (* произносимое предложение русского текста *));
            VAR CyrLangBuf : Byte;
 BEGIN {STEXT}
         CyrLangBuf := CyrLang;
         CyrLang := Russian;
         U_R_Stext (sent1);
         CyrLang := CyrLangBuf;
END {STEXT};

PROCEDURE Ukr_SText (Sent1:string
           (* произносимое предложение украинского текста *));
            VAR CyrLangBuf : Byte;
 BEGIN {UKR_STEXT}
         CyrLangBuf := CyrLang;
         CyrLang := Ukrainian;
         U_R_Stext (sent1);
         CyrLang := CyrLangBuf;
END {UKR_STEXT};



 (* ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒ a ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒ *)

{$I SNamKey1.Pas}

Procedure SpLine(BBL : TuLin;(* Произносимая строка *)
               var Cur : word; (* Начало произнесения *)
               var BTL : TuLin (* последний (непроизнесенный) участок *)  );


  var PunctMarks : TuLim (*Знаки препинания*);
BEGIN (*SpLine*)
  if EntireSp
   then
    PunctMarks := AddNoSpSym - ['-',cBlank] + [':',#0]
   else
    PunctMarks := AddNoSpSym - ['-'] + [':',#0];
  if CyrLang = Ukrainian then Punctmarks := PunctMarks - [''''];
  while BBL [length (BBL)] = CBlank do     {убераем пробелы из конца}
      Delete(BBL, Length(BBL), 1);
  if (Length (BBL) > 1)
      and (BBL [length (BBL)] = '-')
      and (upcode [BBL [length (BBL) -1]] in alphabet)
        then Delete(BBL, Length(BBL), 1) {Перенос слова}
    else
    begin {Если нет переноса,дописать в конец строки пробел }
      BBL := BBL+CBlank;
    end;
    if Cur > Length(BBL) then Cur := Length(BBL);
    if BBL[Length(BBL)]=#0 then BBL := BBL + #1;
    while (Cur <= length (BBL))
      and (not keypressed) do begin {По фразам внутри строки}
 if (CapitalMessage)
         and (BBL [cur] in Alphabet)
         and ((Cur = 1) or not (BBL [cur -1] in Alphabet))
    then begin { индикатор заглавной буквы }
            Noice(Telm,0,30,240,80,0,0);
            Pause(350);
          end;
  repeat {Наращиваем произносимую строку BTL за счет передовой строки BBL}
    BTL := BTL + BBL [cur];
    If not EntireSp
     then
      if UpCode [BBL [cur]] in EngAlphabet then PunctMarks := PunctMarks +[CBlank];
                  {В английском тексте слова читаются отдельно}
      if UpCode [BBL [cur]] in RusAlphabet then PunctMarks := PunctMarks -[CBlank];
             {А в русском - слитно}
    inc (cur);
  until (cur > length (BBL)) (*Строка исчерпана*)
      or (BBL [cur -1] in PunctMarks)
         and (not (BBL [cur] in PunctMarks)) (*Окончилась последовательность разделителей*)
         and (BBL [cur]<> '=')
      or (CapitalMessage) (* надо сигнализировать о большой букве*)
         and (BBL [cur] in Alphabet)
         and ((Cur = 1) or not (BBL [cur -1] in Alphabet));
 if (cur <= length (bbl)) (* если это еще не конец строки и буфер не переполнен *)
    or (length (BTL) > 80) then
     begin {Произносим, если на знаке препинания}
                   NoSTextSymBuf := NoSTextSym {Запомним};
                     NoSTextSym := NoSpicSim {режим чтения };
                    U_R_STEXT(BTL);
                     NoSTextSym := NoSTextSymBuf {Возвращаемся в режим реплик};
    BTL :=  '';
   end;
         end {По фразам внутри строки};
END {SpLine};





begin (*▒▒Spick ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
   TELM:=1;
  AddNoSpSym := [#2..#255] -Alphabet -['a'..'z','а'..'я','Б','ё',_Ukr_I,_Ukr_Ye,_Ukr_Yi,_Ukr_ge,
                 '0'..'9','+','=','#','%','$']
                 (*$IFDEF SP_COMM*) - ['*','`'](*$EndIf*);
  {символы запрещенные к произнесению
                                    в безнаковом режиме чтения процедуры SText}
   NoSTextSym := AddNoSpSym;
   NoSpicSim := [#0];
 Speak_On := true;
 CyrLang := Russian;
 LatLang := English;
 UkrCoding := UkrWordCoding;
 EntireSp := false;
 CapitalMessage := false;
   {Time1:=125;}
   NoSpicSim:=[#0];
   ClBuf.sp1:=0;
   ClBuf.sp2:=0;
   ClBuf.WIn:=true;
   WSBuf:='';
   TSWait:=0;
   YSWait:=False;
  { fillchar(ClBuf.spBuf,MaxSpBuf,#0); }
  InitSp (0,1);
END. (* SPICK *)
