


          {КАРТАВЦЕВ С. А. }
UNIT SayForm; { прoцедуры речевого вывода }

INTERFACE

    USES dos, spick, inter;

    VAR
      WordLine:string;    {Процедуры правильного произнесения числительных размещают}
                          {здесь сформированую строку}

 procedure InitSay(vers:byte);
 { 0 - звук отключен                 }
                           { 1 - вывод на звуковой синтезатoр }
                           { 2 - вывод на параллельный интерфейс }

procedure SayStr (Sent:string)
 { произносимое предложение };

procedure SayStr0 (Sent : String);    {
        {произносит предложение со всеми знаками пунктуации}

procedure SayStr1 (Sent : string);
      {Произносит предложение без знаков пунктуации}

procedure SayChar (M,A: char);
                             {Основной и дополнительный }
                             {код клавиатуры            }

 Procedure SayText (BBL: TuLin;{ Произносимая строка }
               var Kur : word; { Начало произнесения }
               var BTL: TuLin { последний (непроизнесенный) участок }  );



 function PartL (s : string; dv : char; i : integer) : string;
 {Возвращает i-тую (i = 0, 1, 2 ...) часть строки s, выделяемую символом dv}

   {произнесение порядкового числительного}
          procedure sayordnum (num {число} : longint;
       cline {командная строка типа 'в\ый\ раз' и т. п.} : string);
 procedure sayreal (num:real; mantnum : integer);
 { произнесение вещественного числа с mantnum знаками после точки}

 procedure saystand (p : real);
 {произнесение числа в стандартном виде}

 procedure saynum (num:real); {произнесение   чисел всех типов
    с точностью до трех знаков}


{правильное произношение словосочетания с числительным }
 procedure sayright (n : real; cl : string);
 procedure sayimeniteln (n : real; cl : string);
 procedure sayright1 (n : real; cl : string);
 procedure sayroditeln (num : real; cline : string);
 procedure sayright2 (num : real; cline : string);
 procedure saydateln (num : real; cline : string);
 procedure sayright3 (num : real; cline : string);
 procedure sayviniteln (n : real; cl : string);
 procedure sayright4 (n : real; cl : string);
 procedure saytvoriteln (num : real; cline : string);
 procedure sayright5 (num : real; cline : string);
 procedure saypredlogn (num : real; cline : string);
 procedure sayright6 (num : real; cline : string);



function MonthName (MonthNum : Byte) : string;
     {Возвращает название месяца под номером MonthNum}

Procedure Say_Year (YearNum : integer) {Правильно произносит год };

procedure SaySystemInform (CH : char) { Произносит системную информацию };

procedure SayTime;

procedure SayDate;

procedure SayRightByteSize(Num : longint);    {Произносит размер в байтах}



 procedure ReadStr(var line:string);
 procedure readlnstr (var line:string);
   {ввод строки}

 procedure readint(var num:integer);
 procedure readlnint(var num:integer);
 {ввод целого числа}

 procedure readword(var num:word);
 procedure readlnword(var num:word);
 {ввод положительных чисел}

 procedure readreal(var num:real);
 procedure readlnreal(var num:real);
 {ввод вещественных чисел}

 procedure readshort (var num:shortint);
 procedure readlnshort (var num:shortint);
    {ввод коротких целых чисел}

 procedure readlong(var num:longint);
 procedure readlnlong(var num:longint);
 {ввод длинных положытельных чисел}

 procedure  readbyte(var num:byte);
  procedure readlnbyte(var num:byte);
    {ввод коротких положительных чисел}

 procedure readchar (var pr:char);
      {озвученный ввод текста}

implementation
{блок процедур Картавцева С. А.}
   var
   text,minus,point,expan:boolean;
  l:string;
  say:string;
  err:integer;



procedure InitSay(vers:byte);
  begin     initsp (vers, 1); end;

procedure Saystr (Sent:string);
   begin SText (Sent); end;

procedure SayStr0 (Sent : string);
    var Buf : TULim;
  begin {SayStr0}
    Buf := NoSTextSym;
    NoSTextSym := [#0];
    SayStr (Sent);
    NoSTextSym := Buf;
  end;   {SayStr0}

procedure SayStr1 (Sent : string);
    var Buf : TULim;
  begin {SayStr0}
    Buf := NoSTextSym;
    NoSTextSym := AddNoSpSym;
    SayStr (Sent);
    NoSTextSym := Buf;
  end;   {SayStr0}
procedure Saytext (bbl : tulin; var kur : word; var btl : tulin);
   begin spline (bbl, kur, btl); end;

procedure Saychar (M,A: char);
  begin
 if (m <> #0)
 and (m <> CBack)
 and (m <> CTab)
  and (m <> CEnter)
 and (m <> CEsc)
  and (m < #32)
   or (m > #175)
  and (m < #224)
  or ( m > #249)
   then begin
 saystr ('си+мвол');
 saynum ( ord(m)); end
 else snamkey (m, a);
 end {saychar};


procedure sayordnum (num : longint; cline : string);
  var
 first : boolean;
 numstr : string [20];
 ok : string [2];
 i, j, k : integer;
  function partl (i : byte) : string;
 {возвращает i-тую часть строки}
  begin
 partl := copy (cline,
  pos (chr (i - 1), cline) + 1,
  pos (chr (i), cline) -
  pos (chr (i - 1),cline) - 1);
   end {partl};
 {функции ниже возвращают названия порядковых числительных}
   function case1 (sym : char) : string;
 begin
    case sym of
 '1' : case1 := ' пе+рв';
 '2' : case1 := ' втор';
 '3' : case1 := ' тре+т';
 '4' : case1 := ' четвё+рт';
 '5' : case1 := ' пя+т';
 '6' : case1 := ' шест';
 '7' : case1 := ' седьм';
 '8' : case1 := ' восьм';
 '9' : case1 := ' девят';
  end; {case}
    end; {case1}
   function case10 (sym : char) : string;
  begin
   case sym of
 '1' : case10 := ' деся+т';
 '2' : case10 := ' двадца+т';
 '3' : case10 := ' тридца+т';
 '4' : if i < 3 then case10 := ' сороко+в'
      else case10 := ' сорока+';
 '7' : case10 := ' семидеся+т';
 '9' : case10 := ' девяно+ст';
   else case10 := case1 (sym) + 'идеся+т';
    end;end {case10};
   function case11 (sym : char) : string;
   begin
   case sym of
 '1' : case11 := ' оди+ннадцат';
 '2' : case11 := ' двена+дцат';
 '3' : case11 := ' трина+дцат';
 '4' : case11 := ' четы+рнадцат';
  '7' : case11 := ' семна+дцат';
 '8' : case11 := ' восемна+дцат';
  else case11 := case1 (sym) + 'на+дцат';
   end {case};
   end {case11};
   function case100 (sym : char) : string;
   begin
  case sym of
 '1' : case100 := '';
 '2' : case100 := ' двух';
 '3' : case100 := ' трёх';
 '4' : case100 := ' четырёх';
 '7' : case100 := ' семи';
  else case100 := case1 (sym) + 'и';
   end {case};
   end {case100};
  begin {SayOrdNum}
    wordline := '';
          {разделители : \, - }
    for i := 1 to length (cline)
     do
      if cline [i] = '-'
       then cline [i] := '\';
    cline := '\' + cline + '\\\\\';
  {маркеровщик}
    for i := 0 to 4
     do cline [pos ('\', cline)] := chr (i);
    if partl (2) = ''
     then insert ('ый',cline,  pos (#1, cline) + 1);
    str (num, numstr);
    if num = 0
     then wordline := ' нулев'
     else {остальное}
      begin
        i := length (numstr);
        while numstr [i] = '0'
         do dec (i) {счетчик нулей};
        i := length (numstr) - i;
        wordline := numstr;
        case i of  {обработка первого разряда}
            0 : if numstr [length (numstr) - 1] = '1'
                 then
                  begin
                    delete (wordline, length (wordline) - 1, 2);
                    wordline := wordline + '00' + case11 (numstr [length (numstr)]);
                  end {11}
                 else
                  begin
                    wordline [length (wordline)] := '0';
                    wordline := wordline+ case1 (numstr [length (numstr)]);
                  end {0};
            1 : begin
                  wordline [length (wordline) - 1] := '0';
                  wordline := wordline + case10 (numstr [length (numstr) - 1]);
                end {1};
            2 : begin
                  wordline [length (wordline) - 2] := '0';
                  wordline := wordline + case100 (numstr [length (numstr) - 2]) + 'со+т';
                end {2};
          else {case}   {обработчик больших чисел}
            begin
              j := 3 * (i div 3   );
              numstr := '   ' + numstr;
              wordline := '      ' + wordline;
              delete (wordline, length (wordline) - j - 2, 3);
              wordline := wordline + '000';
               {разряд сотен}
              if numstr [length (numstr) - j - 2] = '1'
               then wordline := wordline + ' сто'
               else
                if     (numstr [length (numstr) - j - 2] <> '0')
                   and (numstr [length (numstr) - j - 2] <> CBlank)
                 then  wordline := wordline + case100 (numstr [length (numstr) - j - 2]) + ' сот';
                {разряд десятков}
                if     (numstr [length (numstr) - j - 1] = '1')
                   and (numstr [length (numstr) - j] <> '0')
                 then {второй десяток}
                  wordline := wordline + case11 (numstr [length (numstr) - j]) + 'и'
                 else {первый десяток}
                  begin
                    if numstr [length (numstr) - j - 1] in ['1'..'9']
                     then wordline := wordline + case10 (numstr [length (numstr) - j - 1]);
                    if numstr [length (numstr) - j - 1] in ['1'..'3', '5'..'9']
                     then wordline := wordline + 'и';
                {разряд единиц}
                    if numstr [length (numstr) - j] in ['1'..'9']
                     then wordline := wordline+ case100 (numstr [length (numstr) - j]);
                    if numstr [length (numstr) - j] = '1'
                     then wordline := wordline + ' одна';
                  end {первый десяток};
                case i of
                    3..5 : wordline := wordline + ' ты+сячн';
                    6..8 : wordline := wordline + ' милио+нн';
                    9  : wordline := wordline + ' миллиа+рдн';
                end {case};
            end {обработчик};
        end {case};
      end {остальное};
    i := 1;
    while    (wordline [i] = '-')
          or (wordline [i] = '0')
          or (wordline [i] = cblank)
     do delete (wordline, i, 1);
  {обработка окончания числительного}
 {очистить от пробелов вторую часть}
    for i := pos (chr (1), cline) to pos (chr (2), cline)
     do if cline [i] = cblank
         then delete  (cline, i, 1);
  {трансформация окончания}
    if     (partl  (2) = 'ый')
       and (num = 0)
     then wordline := wordline + 'ой';
    if     (partl  (2) = 'ЫЙ')
       and (num = 0)
     then wordline := wordline + 'ОЙ';
    if numstr [length (numstr) - 1] <> '1'
     then
      begin
        case numstr [length (numstr)] of
            '2', '6', '7', '8' : if  partl  (2) = 'ый'
                                  then wordline := wordline + 'ой'
                                  else
                                   if  partl  (2) = 'ЫЙ'
                                    then    wordline := wordline + 'ОЙ'
                                    else wordline := wordline + partl (2);
          else     {case}
            if not ((num = 0)
               and ((partl (2) = 'ый')
                or (partl (2) = 'ЫЙ')))
             then  wordline := wordline + partl (2);
        end  {case};
        if numstr [length (numstr)] = '3'
         then
          case wordline [length (wordline) - length (partl (2)) + 1] of
              'а','у' : wordline [length (wordline) - 1] := 'ь';
              'А','У' : wordline [length (wordline) - 1] := 'Ь';
              'ы' : wordline [length (wordline) - 1] := 'и';
              'Ы' : wordline [length (wordline) - 1] := 'И';
              'о' : begin
                      wordline [length (wordline) - length (partl (2)) + 1] := 'ь';
                      if wordline [length (wordline)] <> 'е'
                       then insert ('ь', wordline , length (wordline) - 2);
                    end;
              'О' : begin
                      wordline [length (wordline) - length (partl (2)) + 1] := 'Ь';
                      if wordline [length (wordline)] <> 'Е'
                       then insert ('Ь', wordline, length (wordline) - 2);
                    end;
          end {case};
      end {иначе}
     else wordline := wordline + partl (2);
    case wordline [length (wordline) - 1] of
        'г' : wordline [length (wordline) - 1] := 'в';
        'Г' : wordline [length (wordline) - 1] := 'В';
    end {case};
    if num < 0
     then wordline :=  ' минус ' + wordline;
    if pos ('пи', strchar (partl (4))) > 0
     then write (partl (1));
    if num = 2
     then {соединительная гласная}
      case cline [pos (#1, cline) - 1] of
          'в', 'к', 'с' : begin
                            wordline := 'о ' + wordline;
                            if pos ('пи', strchar (partl (4))) > 0
                             then write ('о');
                          end;
          'В', 'К', 'С' : begin
                            wordline := 'О ' + wordline;
                            if pos ('пи', strchar (partl (4))) > 0
                             then write ('О');
                          end;
      end {case};
    ok := copy (wordline, length (wordline) - 1, 2);
    if ok = 'во'
     then ok := 'го';
    if ok = 'ВО'
     then ok := 'ГО';
 {обработка ключей}
 {пиши - вывод на монитор}
    if pos ('пи', strchar (partl (4))) > 0
     then write (num, '-', ok,  ' ', partl (3));
 {напиши вывод с переходом на следующую строку}
    if pos ('на', strchar (partl (4))) > 0
     then writeln;
 {молчи - без произнесения}
    if pos ('мо', strchar (partl (4))) = 0
     then  saystr (partl (1) + wordline + partl (3));
 {ок - в wordline помещается только окончание}
    if pos ('ок', strchar (partl (4))) > 0
     then wordline := ok;
  end {SayOrdNum};



procedure saynum (num:real);
var say {число в строковой форме для произнесения} : string [19];
 begin {saynum}
 if num = 0 then saystr ('ноль')
 else begin
 str (abs (num) :15:3,say);
 if pos ('.', say) > 0 then
  while say[length(say)] ='0' do
   delete (say,length(say),1);
 if say [length (say)] = '.' then    delete (say,length(say),1);
 if num < 0 then saystr ('ми+нус' + say)
 else saystr (say);
 end {else};
end {saynum};


procedure sayreal (num : real; mantnum : integer);
 var
 endw, say, mant : string;
 i, expnum : integer;
 begin {sayreal}
 expnum := 0;
 if mantnum >= 0
 then str (abs (num):1:mantnum, say)
 else begin str (abs (num), say); {если меньше нуля, то стандартный вывод}
 val (copy (say, 15, 3), expnum, i) {взяли экспаненту};
 delete (say, 14, 4); end;
 while say [length (say)] = '0' do {убераем нули}
 delete (say, length (say), 1);
 if say [length(say)] = '.' {и точку}
 then delete (say,length (say), 1);
 if num < 0 then saystr ('ми+нус');
 if not ((length (say) - pos ('.', say) <= 3)
 or (pos ('.', say) = 0))
  then begin{обрабатываем мантису}
 mant := copy (say, pos ('.', say) + 1, length (say) - pos ('.', say)) {берём мантису};
 if (mant [length (mant)] = '1'){подбераем окончания для дробной части}
 and (mant [length(mant) - 1] <> '1')
 then begin
 endw := 'ая ';
 delete (mant, length (mant), 1);
 mant := mant + '0 одна+ ';   end
 else   endw := 'ых ';
 if (mant [length (mant)] = '2')
 and (mant [length(mant) - 1] <> '1')
 then begin
 delete (mant, length (mant), 1);
 mant := mant + '0 две+ ';
 end;
 if mantnum < 0
 then begin
 val (copy (say, 1, 2), mantnum, i);
 sayright (mantnum, 'ж-цел-ая-ых-ых'); end
 else  sayright (abs (int (num)), 'ж-цел-ая-ых-ых');
{сформируем дробную часть}
 case length (say) - pos ('.', say)  of
 4 : mant := mant + ' де+сятиты+сячн' + endw;
 5 :  mant := mant + ' сстоты+сячн' + endw;
 6 : mant := mant + ' ми+ли+о+нн' + endw;
 7 : mant := mant + ' дде+сятимилио+нн' + endw;
 8 : mant := mant + ' ссто+милио+нн' + endw;
 9 : mant := mant + ' милиа+рдн' + endw;
 10 : mant := mant + ' дде+сятимилиа+рдн' + endw;
 end {case};
 saystr  (mant);
 end {если мантиса не длиннее 3 - просто произносим}
 else  saystr (say);
 if expnum <> 0  then begin{займёмся экспанентой}
 saystr ('на дде+сять в сте+пени');
 saynum (expnum); end;
 end {sayreal};

procedure saystand (p : real);
 begin sayreal (p, -1); end;

function partl (s : string; dv : char; i : integer) : string;
 {Возвращает i-тую (i = 0, 1, 2 ...) часть строки s, выделяемую символом dv}
 var j {счетчик символов до (i - 1)-ого разделителя},
 k {счетчик разделителей},
 l {до i-ого} : integer;
 begin {partl}
 {добавляем (-1)-ый разделитель}
 s := dv + s;
 {ищем (i - 1)-ый разделитель}
 j := 1;
 k := -1;
 while ((s [j] <> dv)
 or (k <> i - 1))
 and (j <= length (s)) do
 begin
 inc (j);
 if dv = s [j] then inc (k);
 end;
 {теперь - i-тый}
 l := j + 1;
 while (s [l] <> dv)
 and (l <= length (s)) do inc (l);
 inc (j);
 partl := copy (s, j, l - j);
 end {partl};


procedure rightsay (num : real; CLine : string; odn : char);

{ Произносит словосочетание с числительным в именительном}
{ или родительном падеже, причем, падеж зависит от параметра Odn:}
{ "А" - Именительный;  "У" - винительный. }
    var
         say {число} : string;
         nul {0 или пробел} : char;
         i, j {счётчик} : integer;

  function pl (n : integer) : string;
 {упрощение partl}
   begin {pl}
     case n of
         00 : pl := partl (partl (cline, '-', 0), '/', 0);
         10 : pl := partl (partl (cline, '-', 0), '/', 1);
       else pl := partl (cline, '-', n);
     end {case};
   end { pl};

  begin {rightsay}
{переводим все буквы в строчный регистр}
    cline := strchar (cline);
 {Заменяем \ на -}
    for i := 1 to length (cline) do if cline [i] = '\' then cline [i] := '-';
{формируем число для произнесения}
    str (abs (num):1:3,say);
{уберем лишние нули в конце}
    while say[length (say)] = '0' do delete (say,length (say),1);
{и точку}
    if say [length (say)] = '.' then delete (say, length (say), 1);
{для дробных в винительном}
    if     (pos ('.', say) > 0)
       and (odn = 'у')
    then {если дробный винительный}
    begin {Произнести целую и дробную части в винительном падеже}
      rightsay (int (num), 'ж/' + pl (10) + '-це+л-ую-ых-ых- -', 'у');
      cline := cline + #200 + wordline;
      val (copy (say, pos ('.', say) + 1, 3), i, j);
      if length (say) - pos ('.', say) = 1 then rightsay (i, 'ж-деся+т-ую-ых-ых', 'у');
      if length (say) - pos ('.', say) = 2 then rightsay (i, 'ж-со+т-ую-ых-ых', 'у');
      if length (say) - pos ('.', say) = 3 then rightsay (i, 'ж-ты+сячн-ую-ых-ых', 'у');
      cline := cline + wordline;
      wordline := pl (1) + pl (3);
      say := '';
    end {дробные}
 else begin {остальное}
 if num = 0 then say := ' ноль ';
{готовим окончание}
 if length (say) = 1 then nul := ' '
 else nul := '0';
{начинаем подбор форм числительного  и существительного}
{форма для 0, 4-9}
 wordline := pl (1) + pl (4);
{для 1-4}
 if not ((say[length (say) - 1] = '1')
 or (pos ('.', say) > 0))
 then begin
{для 1}
 if say[length (say)] = '1' then
 wordline := pl (1) + pl (2);
{для 2-4}
 if (say [length (say)] >= '2')
 and (say [length (say)] <= '4')
 then wordline:= pl (1) + pl (3);
{подбераем числительное в соответствии с родом}
 {для женского}
  if cline [1] = 'ж' then begin
 {вместо один - одна}
 if say[length (say)] = '1' then begin
 delete (say, length (say), 1);
 say := say + nul + ' odn' + odn + '+ '; end;
 {вместо два - две}
 if say [length (say)] = '2' then begin
 delete (say, length (say), 1);
 say:= say + nul + ' две '; end;
    end;
 {для среднего}
{вместо один - одно}
 if (cline [1] = 'с')
 and (say [length (say)] = '1')
 then begin
 delete (say,length (say),1);
 wordline := pl (1) + pl (2);
 say := say + nul + 'одно+ '; end;
 end;
{для дробных}
 if pos ('.', say) > 0
 then wordline := pl (1) + pl (3);
{для отрицательного}
 if num < 0 then say := 'minus' + say;
{предлог} say := pl (10) + cblank + say;
 end {остальное};
 wordline := wordline + pl (5);
{исследуем ключи}
{пиши - вывод на монитор}
 if pos ('пи', pl (0)) > 0
 then write (pl (10) + cblank, num:4:3, ' ', wordline);
{напиши - вывод с переходом на следующую строку}
 if pos ('на',pl (0)) > 0
 then writeln;
{слово - проiзносится только существительное}
 if pos ('слово', pl (0)) > 0
 then   say := '';
{число - произносится только число}
 if pos ('число', pl (0)) = 0
 then say := say + cblank +  wordline + cblank;
{молчи - ничего не произносится}
 if pos ('мо', pl (0)) = 0
 then saystr (say);
{текст - в wordline помещается строка для печати : без числа}
 if (pos ('те', pl (0)) = 0)
 and (pos ('||', pl (0)) = 0)
 then if say = cblank +  wordline + cblank
 then wordline := partl (cline, #200, 1) + cblank +wordline
 else wordline := say;
 {|| - Объеденить строки для печати и произнесения, разделив их символом "||"}
 if pos ('||', pl (0)) = 0 then WordLine := WordLine +Say;

 end {rightsay};

procedure rightsay2 (num : real; cline, endstr : string);
    var
 SYM {буфер для рекурсии},
 rod {род существительного : ж, м, с}: char;
 numstr {число в строковой форме} : string [20];
 say {число в текстовой форме} : string;
 nslen {длина numstr},
 pointpos {позиция точки в numstr},
 i {счетчик} : integer;
 k {для рекурсии} : real;

 function pl (n : integer) : string;
 {упрощение partl}
 begin {pl}
 if endstr [1] = 'р'  then begin
 if n = 4 then n := 3;
 if n = 5 then n := 2;
 end;
 case n of
 0 : pl := partl (partl (cline, '-', 0), '/', 0);
 10 : pl := partl (partl (cline, '-', 0), '/', 1);
 else pl := partl (cline, '-', n);
 end {case};
 end { pl};
 function cp (p : byte) : string;
 begin {cp}
 cp := partl (endstr, ' ', p);
 end {cp};
 function nameofnum (fignum, clnum : byte; rodw : char;
 numstr : string) : string;
 {функция выбора числительных}
 var nslen : integer;
 namofcl {name of class},
 class1, class2, class3 : string [40];
 begin {nameofnum}
 class1 := '';
 class2 := '';
 class3 := '';
 nslen := length (numstr);
 {подбор окончания}
 if clnum > 1
 then if (clnum = 2)
 then if (copy (numstr, nslen -5, 3) <> '000')
 then namofcl := cp (1)
 else namofcl := ''
 else namofcl := cp (2)
 else namofcl := '';
 {разряд едениц}
 if numstr [fignum - 1] = '1' then begin
  case numstr [fignum] of
 '0' : class1 := 'десят' + cp (3) + '+ ';
 '1' : class1 := 'оди+ннацат';
 '2' : class1 := 'двена+дцат';
 '3' : class1 := 'трина+дцат';
 '4' : class1 := 'четы+рнадцат';
 '5' : class1 := 'пятна+дцат';
 '6' : class1 := 'шестна+дцат';
 '7' : class1 := 'семна+дцат';
 '8' : class1 := 'восемна+дцат';
 '9' : class1 := 'девятна+дцат';
 end {case};
 case numstr [fignum] of
 '1' .. '9' : class1 := class1 + cp  (3) + ' ';
 end {case};
 end
 else  begin
 case numstr [fignum] of
 '0' : if length (numstr) <= 2 then class1  := 'нул' + cp (4) + ' ';
 '1' : begin
 if (rodw = 'ж')
 or (clnum = 2) then class1 := 'одно+й '
 else class1 := 'одн' + cp (5);
 if clnum > 1 then
 if clnum = 2 then namofcl := cp (3)
 else namofcl := cp (6); end;
 '2' : class1 := 'дву' + cp (7) + ' ';
 '3' : class1 := 'тр' + cp (13) + ' ';
 '4' : class1 := 'четыр' + cp (9);
 '5' : class1 := 'пят';
 '6' : class1 := 'шест';
 '7' : class1 := 'сем';
 '8' : class1 := 'восм';
 '9' : class1 := 'девят';
 end {case};
 case numstr [fignum] of
 '5' .. '9' : class1 := class1 + cp (8) + ' ';
 end {case};
 {десятки}
 case numstr [fignum - 1] of
 '2' : class2 := 'двадцат';
 '3' : class2 := 'тридцат';
 '4' : class2 := 'сорока+ ';
 '5' : class2 := 'пяти+десят';
 '6' : class2 := 'шести+десят';
 '7' : class2 := 'семи+десят';
 '8' : class2 := 'восми+десят';
 '9' : class2 := 'девяно+ста';
 end {case};
 case numstr [fignum - 1] of
 '2', '3' : class2 := class2 + cp (8) + ' ';
 '5' .. '8' : class2 := class2 + cp (3) + ' ';
 end {case};
 end {десятки};
 if ((numstr [fignum - 2] > '0')
 and (numstr [fignum - 2] <= '9'))
 and (pos (' ', copy (numstr, 2, length (numstr) - 1)) = 0) then {сотни}
 if numstr [fignum - 2] = '1'
 then class3 := 'ста+ '
 else begin
 insert (' ', numstr, fignum - 2);
 inc (fignum);
 class3 := nameofnum (fignum - 2, 1, 'ж', numstr);
 delete (class3, length (class3), 1);
 delete (class3, pos ('+', class3), 1);
 class3 := class3 + cp (10) + ' ';
 dec (fignum);
 delete (numstr, fignum - 2, 1);
 end {сотни};
 {подбор названия класса}
 case clnum of
 2 : if copy (numstr,  nslen - 5, 3) <> '000' then namofcl := 'ты+сяч' + namofcl;
 3 : if copy (numstr,  nslen - 8, 3) <> '000' then namofcl :=  'миллио+н' + namofcl
 else namofcl := '';
 4 :  if copy (numstr,  nslen - 11, 3) <> '000' then namofcl := 'миллиа+рд' + namofcl
 else namofcl := '';
 5 : namofcl := 'триллио+н' + namofcl;
 end {case};
 nameofnum := class3 + class2 + class1 + namofcl;
 end {nameofnum};

begin {rightsay2}
 say := '';
 cline := cline + '------';
 {меняем \ на -}
 for i := 1 to length (cline) do
 if cline [i] = '\' then cline [i] := '-';
 {формируем число для произнесения}
 str (abs (num):1:3,numstr);
 numstr := ' ' + numstr;
{уберем лишние нули в конце}
 while numstr[length (numstr)] = '0' do
 delete (numstr,length (numstr),1);
 {и точку}
 if numstr [length (numstr)] = '.'
 then delete (numstr, length (numstr), 1);
 nslen := length (numstr);
 pointpos := pos ('.', numstr);
 {начинаем подбор форм числительного}
 if pointpos = 0 then begin {для целых}
{форма для 10 и т. п.}
 wordline:= pl (1) + pl (3);
{для 1}
 if (numstr[nslen] = '1')
 and (numstr[nslen - 1] <>  '1')
 then  wordline := pl (1) + pl (2);
{для 0, 1000 и т. п.}
 if (copy (numstr, nslen - 1, 2) = '00')
 and (numstr [nslen - 2] <> '1')
 or (num = 0)
 then wordline := pl (1) + pl (4);
{подбeраем числительное в соответствии с родом}
 say := strchar (pl (0));
 rod := say [1];
 say :=  nameofnum (nslen, 1, rod, numstr);
 if nslen > 4 then
 say := nameofnum (nslen - 3, 2, rod, numstr) + say;
 if nslen > 7 then
 say := nameofnum (nslen - 6, 3, rod, numstr) + say;
 if nslen > 10 then
 say := nameofnum (nslen - 9, 4, rod, numstr) + say;
 if nslen > 13 then
 say := nameofnum (nslen - 12, 5, rod, numstr) + say;
 end {для целых}
{для дробных}
 else begin
 cline := cline + #200 + pl (1) + pl (5);
 sym := endstr [1];
 if cp (0) = 'п' then endstr [1] := 'р';
 rightsay2 (abs (int (num)), 'ж молчи-цел-ой-ы' + cp (11) + '-ых', endstr);
 say := wordline;
 val (copy (numstr, pointpos + 1, 3), k, i);
 if nslen -pointpos = 1 then rightsay2 (k, 'ж молчи-деся+т-ой-ы' + cp (11), endstr);
 if nslen -pointpos = 2 then rightsay2 (k, 'ж молчи-со+т-ой-ы'  + cp (11), endstr);
 if nslen - pointpos = 3 then rightsay2 (k, 'ж молчи-ты+сячн-ой-ы' + cp (11), endstr);
 say := say + cblank + wordline;
 wordline := cblank + partl (cline, #200, 1);
 endstr [1] := sym;
 end {дробные};
 if num < 0 then say := ' ми+нус ' + say;
 if (endstr [1] = 'п') {займёмся предлогом}
 and (strchar (pl (10)) = 'о')
 then if num = 1
 then say := 'об ' + say
 else say := 'о '  + say
 else say := pl (10) + say;
 wordline := wordline + pl (6);
{исследуем ключи}
{пиши - вывод на монитор}
 if pos ('пи', pl (0)) > 0
 then write (pl (10) + cblank, num:4:3, ' ', wordline);
{напиши - вывод с переходом на следующую строку}
 if pos ('на',pl (0)) > 0
 then writeln;
{слово - проiзносится только существительное}
 if pos ('слово', pl (0)) > 0
 then   say := '';
{число - произносится только число}
 if pos ('число', pl (0)) = 0
 then say := say +cblank +  wordline + cblank;
{молчи - ничего не произносится}
 if pos ('мо', pl (0)) = 0 then saystr (say);
{текст - в wordline помещается строка для печати : без числа}
 if pos ('те', pl (0)) = 0
 then wordline := say;
 end {rightsay2};


procedure sayright (n : real; cl : string);
  begin
    rightsay (n, cl, 'а');
  end;
procedure sayimeniteln (n : real; cl : string);
 begin rightsay (n, cl, 'а'); end;
procedure sayright1 (n : real; cl : string);
 begin rightsay (n, cl, 'а'); end;

procedure sayroditeln (num : real; cline : string);
 begin rightsay2 (num, cline,
 'р  ов и я+ ово+ а +х и+ ё+х со+т х ста+ ё+х '); end;
procedure sayright2 (num : real; cline : string);
 begin
 rightsay2 (num, cline,
 'р  ов и я+ ово+ а +х и+ ё+х со+т х ста+ ё+х '); end;

procedure saydateln (num : real; cline : string);
 begin rightsay2 (num, cline,
 'д ам ам и ю+ ому+ у +м и+ ё+м ста+м м ста+м ё+м '); end;
procedure sayright3 (num : real; cline : string);
 begin rightsay2 (num, cline,
 'д ам ам и ю+ ому+ у +м и+ ё+м ста+м м ста+м ё+м '); end;

procedure sayviniteln (n : real; cl : string);
 begin rightsay (n, cl, 'у'); end;
procedure sayright4 (n : real; cl : string);
 begin rightsay (n, cl, 'у'); end;

procedure saytvoriteln (num : real; cline : string);
 begin rightsay2 (num, cline,
 'т ами ами ью ё+м и+м ом мя+ ью+ ьмя+ ста+ми ми ста+ми емя+ '); end;
procedure sayright5 (num : real; cline : string);
 begin rightsay2 (num, cline,
 'т ами ами ью ё+м и+м ом мя+ ью+ ьмя+ ста+ми ми ста+ми емя+ '); end;

procedure saypredlogn (num : real; cline : string);
 begin rightsay2 (num, cline,
 'п ах ах и е+ о+м е +х и+ ё+х ста+х х ста+х ё+х '); end;
procedure sayright6(num : real; cline : string);
  begin {sayright6}
    rightsay2 (num, cline,
               'п ах ах и е+ о+м е +х и+ ё+х ста+х х ста+х ё+х ');
  end;    {sayright6}

function MonthName (MonthNum : Byte) : string;
     {Возвращает название месяца под номером MonthNum}
  begin {MonthName}
               case Monthnum of
                  1 : MonthName := 'Января+';
                  2 : MonthName := 'Февраля+';
                  3 : MonthName := 'Ма+рта';
                  4 : MonthName := 'Апре+ля';
                  5 : MonthName := 'Ма+я';
                  6 : MonthName := 'Ию+ня';
                  7 : MonthName := 'Ию+ля';
                  8 : MonthName := 'А+вгуста';
                  9 : MonthName := 'Сентября+';
                 10 : MonthName := 'Октября+';
                 11 : MonthName := 'Ноября+';
                 12 : MonthName := 'Декабря+';
                      else MonthName := '';
               end {case};
  end {MonthName};

Procedure Say_Year (YearNum : integer);
  begin {Say_Year}
    if YearNum < 2000 then YearNum := YearNum - 1900;
    SayOrdNum (YearNum, '\ого\ го+да.');
  end {Say_Year};

procedure SaySystemInform (CH : char);
    var DT : DateTime;
        Num : longint;
        S : string[$40];
  begin {SaySystemInform}
    case CH of
        CCtrl_C :
            begin      {Произнести размер кластера на текущем диске}
              SayStr('Разме+р кла+стера ');
              SayRightByteSize(GetClusterSize(0));
            end;       {Ctrl_C}
        CCtrl_T :
            With DT
             do
              begin {Произнести текущее время}
                SText (' Сейча+с ');
                GetTime (Hour, Min, Year, year);
                SayRight (Hour, 'м \час\\а\ов');
                Sayright (Min, 'ж \минут\а\ы\\.');
              end {Ctrl_T};
        CCtrl_D :
            with DT
             do
              begin {Произнести дату}
                SText ('Сево+дня');
                GetDate (Year, Month, Day, hour);
                Case hour of
                    0 : SText ('Воскресе+нье');
                    1 : SText ('Понеде+льник');
                    2 : SText ('Вто+рник');
                    3 : SText ('среда+');
                    4 : SText ('Четве+рг');
                    5 : SText ('Пя+тница');
                    6 : Stext ('Суббо+та');
                end {case};
                SayOrdNum (Day, '\ое\' + MonthName (Month));
                Say_Year (Year);
              end {Ctrl_D};
        CCtrl_F :
            begin {Произнести справку о наличии свободного места на диске}
              Num := DiskFree (0);
              SText ('на ди+ске свобо+дно');
              SayRightByteSize(Num);
            end {Ctrl_F};
        CCtrl_O :
            begin {справка о свободной ОП}
              SayStr('Станда+ртной па+мяти свобо+дно');
{$ifdef sp_comm}
              SayRightByteSize((GetFreeMemSize div $400 +214)*$400);
{$else}
              SayRightByteSize((GetFreeMemSize div $400)*$400);
{$endif}
            end {Ctrl_O};
        CCtrl_S :
            begin {Произнести справку о размере диска}
              Num := DiskSize (0);
              SayStr('Разме+р ди+ска');
              SayRightByteSize(Num);
            end {Ctrl_S};
        CCtrl_W :
            begin        {Произнести спецификацию текущего каталога}
              GetDir(0,S);
              SayStr('Теку+щий катало+г: ' +S);
            end;        {Ctrl_W}
    end {case};
  end {SaySystemInform};


procedure SayTime;
    var DT : DateTime;
  begin {SayTime}
    With DT
     do
      begin {Произнести текущее время}
        SText (' Сейча+с ');
        GetTime (Hour, Min, Year, year);
        SayRight (Hour, 'м \час\\а+\о+в');
        if Min = 0
        then SText('Ро+вно')
        else Sayright (Min, 'ж \мину+т\а\ы\\.');
      end
  end; {SayTime}

procedure SayDate;
    var DT : DateTime;
  begin {SayDate}
    with DT
     do
      begin {Произнести дату}
        SText ('Сево+дня');
        GetDate (Year, Month, Day, hour);
            Case hour of
                0 : SText ('Воскресе+нье');
                1 : SText ('Понеде+льник');
                2 : SText ('Вто+рник');
                3 : SText ('среда+');
                4 : SText ('Четве+рг');
                5 : SText ('Пя+тница');
                6 : Stext ('Суббо+та');
            end;  {case}
          SayOrdNum (Day, '\ое\' + MonthName (Month));
          Say_Year (Year);
        end;
  end;  {SayDate}



procedure SayRightByteSize(Num : longint);
      {  Произносит размер в байтах }
    const Halves = 'С половиной ';
          KB = $400;
          MB =  1012000(* $100000*);
          GB = MB*1000(* $40000000*);
    var S,Lin : string[12];
        Unity : longint;
  begin {SayRightByteSize}
    if Num < KB
     then
      begin
        S:= 'Байт';
        Unity := 1;
      end
     else
      if Num < MB
       then
        begin
          S := 'Килобайт';
          Unity := KB;
        end
       else
        if Num < GB
         then
          begin
            S := 'Мегобайт';
            Unity := MB;
          end
         else
          begin
            S := 'Гигабайт';
            Unity := GB;
          end;
    if (Num mod Unity  = 0)
     then {Если ровное число}
      begin {Произнести как количество целых}
        SayRight (Num div Unity, 'м \' +S +'\\а\ов\.');
      end
     else
      begin
        Str((Num / Unity):1:2,Lin);
        SayStr(Lin + cBlank +S +'а.');
      end
  end; {SayRightByteSize}


procedure readline (var s : string);
{внутренняя процедура вызываемая процедурами речевого ввода.}
 var
 rlminus,rlpoint,rlexpan,test {внутренние флаги настройки режима ввода}: boolean;
 err {счётчик} : integer;
 snum {вспомогательная} : real;
 label start {начало};
 begin {readline}
 start:
{сканируем внешние флаги}
 rlminus := minus;
 rlpoint := point;
 rlexpan := point;
 cbk;
 s:='';
 repeat {общий цикл}
 repeat {запирающий цикл}
 test := true {ввод разрешён};
 repeat until preskey;
{условный {приём символов зависит от настройки флагов}
 if not( ((ascii >= '0') and (ascii <= '9') {цифры}
 or (auxic >= cf1) and (auxic <= cf5) {функциональные}
 or (auxic = #86) {shift-f3}
 or (ascii = cback)
 or (ascii = center)
     and (not ((text = false)
     and (s = '')))
 or (ascii = cesc)
 or   (ascii='-') and (rlminus)
 or ((ascii = ctab)
 or (ascii='.')) and (rlpoint)
 or ((ascii = cblank)
 or (ascii = 'E')
 or (ascii = 'e')) and (rlexpan))
 or (text=true))
 then begin
 saystr ('нет');
   test:=false;   end;
   until  test {запирающий};
 rlminus := false {только первым символом};
 if (ascii = ctab) and (text=false)
  then ascii := '.'; {табуляция заменяет точку в real}
  if ascii = '.'
 then   rlpoint := false;{точка единственная}
 if (ascii = cblank) and (text = false)
  then ascii := 'E';{пробел заменяет экспаненту}
  if (ascii = 'E')
 or (ascii = 'e')
 then begin{корректируем режим}
  rlexpan := false;
  rlpoint := false;
  rlminus := true;
 end;
  if ascii > #31
 then begin {выводим}
 write(ascii);
 s := s + ascii;
 end;
 if ascii = cback
 then begin
 saystr ('Стёр');
  ascii := s [length (s)];
   if ascii = '.'
 then   rlpoint := true;
  if ascii = '-'
 then   rlminus := true;
  if (ascii='e') or (ascii ='E')
   then begin {здесь?}
  rlexpan := true;
 rlminus := true; end;
   delete(s,length(s),1);
  write ( cback, cblank,cback); end;
 if ((ascii='e')
 or (ascii = 'E')
 or (ascii = cblank))
  and (text=false)
  then begin ascii:=#0;
 saystr ('на де+сять в сте+пени');
  end;
  saychar (ascii, #0);
  if ascii = cesc then begin
  for err:=length(s) downto 1
 do    write( cback, cblank, cback);
 saystr ('строка+ очи+щена.'); cbk;
  goto start;
       end;
  if auxic = cf1 then begin
   saystr('назва+ния кла+виш.');
 repeat
   repeat until preskey;
  saychar (ascii,auxic);
 until (ascii = cesc) or (auxic = cf1);
 saystr ('коне+ц подска+зки.'); cbk;
 end;
 if auxic = cf2 then begin
  val (s,snum,err);
  if err=0
 then    saynum (snum)
  else saystr (s);
 cbk;  end;
 if auxic = cf3 then begin
 err:=0;
 while (err<length(s))
  and (preskey=false) do begin
  inc(err);
 saychar (s [err], #0);
 end; cbk; end;
 if auxic = #86 then begin
 err := length (s);
 while (err >= 1)
  and (preskey = false) do begin
 saychar (s [err], #0);
  dec (err);
 end; cbk; end;
if auxic = cf4
 then saychar (s [length (s)], #0);
  if auxic = cf5 then begin
  saystr ('длина+ строки+');
 saynum (length (s));
    end;
 until ascii = center;
 end {readline};



procedure readstr (var line:string);
  begin
  text:=true;
  readline(line);
   end;

procedure readlnstr(var line:string);
    begin  readstr(line);    writeln;     end;

procedure readshort (var num:shortint);
    begin
 text := false;
 point := false;
 minus := true;
 readline (l);
 val (l,num,err);
    end;
procedure readlnshort (var num:shortint);
   begin readshort (num); writeln; end;

procedure readword(var num:word);
        begin
  text:=false;
  minus:=false;
  point:=false;
  readline(l);
  val (l,num,err);
    end;

procedure readlnword(var num:word);
        begin readword(num);    writeln     end;

procedure readlong(var num:longint);
        begin
  text:=false;
  minus:=true;
  point:=false;
 readline (l);
  val (l,num,err);
    end;

procedure readlnlong(var num:longint);
        begin  readlong(num);  writeln;     end;

procedure readbyte(var num:byte);
        begin
  text:=false;
  minus:=false;
  point:=false;
  readline(l);
  val (l,num,err);
    end;




procedure readlnbyte(var num:byte);
        begin  readbyte(num);   writeln;     end;

procedure readint(var num:integer);
        begin
  text:=false;
  minus:=true;
  point:=false;
  readline(l);
  val (l,num,err);
    end;

procedure readlnint(var num:integer);
      begin  readint(num);   writeln;     end;

procedure readreal(var num:real);
      begin
 text:=false;
  minus:=true;
  point:=true;
   readline(l);
 val (l,num,err);
    end;

procedure readlnreal(var num:real);
    begin  readreal(num);    writeln;     end;

procedure readchar (var pr:char);
      begin
   repeat until preskey;
 write (ascii);
   snamkey (ascii,auxic);
      end {readchar};

BEGIN     {SayForm}
 ascii := #0;
 auxic := #0;
 wordline := '';
END.    {SayForm}

