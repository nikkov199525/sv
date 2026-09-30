
procedure SNamKey(M,A: char (* Основной и дополнительный *)
                             (* код клавиатуры            *));
    (* Процедура произносит название клавиши *)
var  REG : registers;
  begin (*▒▒▒SNamkey▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒*)
    PTex:='                              .';
    If (UkrCoding = UkrWordCoding) and Speak_on
     then
      begin
          case M of
              #248 : M := Ukr_Ge; (* Заглавное твёрдое Гэ *)
              #249 : M := _Ukr_Ge; (* строчное твердое 'є' *)
              #242 : M := Ukr_Ye; (* Заглавное 'Ї' *)
              #243 : M := _Ukr_Ye; (* строчное  'ї' *)
              #244 : M := Ukr_Yi; (* Заглавное '°' *)
              #245 : M := _Ukr_Yi; (* строчное  '∙' *)
          end;  {case}
       end;
     if (M in Alphabet)
          and (speak_on)
     then begin
            Noice(Telm,0,30,240,80,0,0);
            {Pause(350);}
          end;
     if M<>#0
     then
      if LatLang=German
      then {Немецкие аббревиатуры }
      case M of
          //A_umlaut,A_umlaut_ : PTex := 'А умлаут';
          //O_umlaut, O_umlaut_ : PTex := 'О умлаут';
          //U_umlaut, U_umlaut_ : PTex := 'У умлаут';
          CEsc : PTex := 'Эск';
         CBack : PTex:='Заб';
        CEnter : if CyrLang=Ukrainian then PTex := 'Ввид' else   PTex:='Вво+д';
            CBlank : PTex:= 'ПР';
            '!': if CyrLang=Ukrainian then PTex := 'Оклык' else  PTex:='Воскл';
            '"': if CyrLang=Ukrainian then PTex := 'Лапкы+' else PTex:='Кавы';
            '#': if CyrLang=Ukrainian then PTex := 'номэр' else PTex:='Номер';
            '$': PTex:='Доллар';
            '%': if CyrLang=Ukrainian then PTex := 'Видсоток' else PTex:='Процент';
            '&': PTex:= 'Ампэрсэнд';
           '''': PTex:= ' ,Апо, ';
            '(': if CyrLang=Ukrainian then PTex := 'ЛиДуж' else PTex:='Леско';
            ')': if CyrLang=Ukrainian then PTex := 'ПраДуж' else PTex:='Праско';
            '*': if CyrLang=Ukrainian then PTex := 'Зирка' else PTex:='Звё';
            '+': PTex:='Плю+с';
            ',': if CyrLang=Ukrainian then PTex := 'Кома' else PTex:='Зап';
            '-': if CyrLang=Ukrainian then PTex := 'дэфис' else PTex:='дефис';
            '.': if CyrLang=Ukrainian then PTex := 'крапка' else PTex:='Тэчк';
            '/': if CyrLang=Ukrainian then PTex := 'дриб' else PTex := 'дробь';
            '0': if CyrLang=Ukrainian then PTex := 'Нуль' else PTex:='0';
            '1': if CyrLang=Ukrainian then PTex := 'одын' else PTex:='1';
            '2': PTex:='2';
            '3': if CyrLang=Ukrainian then PTex := 'тры' else PTex:='3';
            '4': if CyrLang=Ukrainian then PTex := 'чотыры' else PTex:='4';
            '5': if CyrLang=Ukrainian then PTex := 'Пъять' else PTex:='5';
            '6': if CyrLang=Ukrainian then PTex := 'шисть' else PTex:='6';
            '7': if CyrLang=Ukrainian then PTex := 'Симь' else PTex:='7';
            '8': if CyrLang=Ukrainian then PTex := 'Висимь' else PTex:='8';
            '9': if CyrLang=Ukrainian then PTex := 'дэвъять' else PTex:='9';
            ':': if CyrLang=Ukrainian then PTex := 'двукрапка' else PTex:='Двоеточ';
            ';': if CyrLang=Ukrainian then PTex := 'КрапКома' else PTex:='Тэч зап';
            '<': if CyrLang=Ukrainian then PTex := 'Мэншэ' else PTex:='Ме+ньше';
            '=': if CyrLang=Ukrainian then PTex := 'Доривнюе' else  PTex:='Равно';
            '>': if CyrLang=Ukrainian then PTex := 'Бильшэ' else  PTex:='Бо+льше';
            '?': if CyrLang=Ukrainian then PTex := 'запыт' else PTex:='Вопр';
            '@': PTex:='Эт';
            '[': if CyrLang=Ukrainian then PTex := 'ЛиКваД' else PTex:='Леквас';
            ']': if CyrLang=Ukrainian then PTex := 'ПраКваД' else PTex:='Праквас';
            '\': PTex:='БэкСлэ+ш';
            '^': PTex:='Кры+шка';
            '_': PTex:='По+д';
            '`': if CyrLang=Ukrainian then PTex := 'Звор Апо' else PTex:='Обр апо';
            '{': if CyrLang=Ukrainian then PTex := 'ЛиФиД' else PTex:='Лефис';
            '}': if CyrLang=Ukrainian then PTex := 'ПраФиД' else PTex:='Прафис';
            '|': if CyrLang=Ukrainian then PTex := 'Вэртыкаль' else PTex:='Вертикаль';
            '~': PTex:='Ти+льда';
        'F','f': PTex:='Эф';
        'I','i' : PTex := 'и';
        'J','j': PTex := 'йот';
        'M','m':
                 if speak_on then PTex := 'Ээм'
                             else PTex := 'эм';
        'N','n': PTex:='Эн';
        'Q','q': PTex := 'Ку';
        'S','s': PTex:='Эс';
        'V','v' : PTex := 'фау';
        'X','x': PTex:='икс';
        'Y','y': PTex:='игрек';
        'Z','z': PTex:='Зэт';
        'A','a','А','а': PTex:='А';
        'B','b','Б','б': PTex:='Бэ';
        'W','w','В','в': PTex:='Вэ';
        'G','g','Г','г': PTex:='Гэ';
        'D','d','Д','д': PTex:='Дэ';
        'Е','е': PTex:='Е';
        'Ж','ж': PTex:='Жжэ';
        'З','з': PTex:='Зэ';
        'И','и': PTex:='И';
        'Й','й': PTex:='И+ЙЙ';
        'K','k','К','к': PTex:='Ка';
        'L','l','Л','л': PTex:='Эль';
        'М','м': PTex:='Эмм';
        'Н','н': PTex:='Эн';
        'O','o','О','о': PTex:='О';
        'P','p','П','п': PTex:='Пэ';
        'R','r','Р','р': PTex:='Эр';
        'С','с': PTex:='Эс';
        'T','t','Т','т': PTex:='Тэ';
        'U','u','У','у': PTex:='У';
        'Ф','ф': PTex:='Эф';
        'H','h','Х','х': PTex:='Ха';
        'C','c','Ц','ц': PTex:='Цэ';
        'Ч','ч': PTex:='Чэ';
        'Ш','ш': PTex:='Ша';
        'Щ','щ': PTex:='Ща';
        'Ъ','ъ': PTex:='твЁ';
        'Ы','ы': PTex:='ы';
        'Ь','ь': PTex:='мя';
        'E','e','Э','э': PTex:='э';
        'Ю','ю': PTex:='йю';
        'Я','я': PTex:='йя';
        'Ё','ё': PTex:='Ё';
        Ukr_Ge, _Ukr_Ge :PTex := 'ТВЭРДЭ+ гэ+';
        Ukr_Ye, _Ukr_Ye :if speak_on then PTex := 'Укр-ЙЭ'
             else PTex := 'йэ';
        Ukr_I, _Ukr_I :if speak_on then PTex := 'Укр-И'
               else  PTex := 'и';
        Ukr_Yi, _Ukr_Yi :PTex:= 'ЙЙИИ';
      end (*case*)
      else {Английские аббревиатуры}
      case M of
          CEsc : PTex := 'Эск';
         CBack : PTex:='Заб';
        CEnter : if CyrLang=Ukrainian then PTex := 'Ввид' else   PTex:='Вво+д';
            CBlank : PTex:= 'ПР';
            '!': if CyrLang=Ukrainian then PTex := 'Оклык' else  PTex:='Воскл';
            '"': if CyrLang=Ukrainian then PTex := 'Ла+пкы+' else PTex:='Кавы';
            '#': if CyrLang=Ukrainian then PTex := 'номэр' else PTex:='Номер';
            '$': PTex:='Доллар';
            '%': if CyrLang=Ukrainian then PTex := 'Видсоток' else PTex:='Процент';
            '&': PTex:= 'Ампэрсэнд';
           '''': PTex:= ' ,Апо, ';
            '(': if CyrLang=Ukrainian then PTex := 'ЛиДуж' else PTex:='Леско';
            ')': if CyrLang=Ukrainian then PTex := 'ПраДуж' else PTex:='Праско';
            '*': if CyrLang=Ukrainian then PTex := 'Зирка' else PTex:='Звё';
            '+': PTex:='Плю+с';
            ',': if CyrLang=Ukrainian then PTex := 'Кома' else PTex:='Зап';
            '-': if CyrLang=Ukrainian then PTex := 'Мынус' else PTex:='Ми+нус';
            '.': if CyrLang=Ukrainian then PTex := 'крапка' else PTex:='Тэчк';
            '/': if CyrLang=Ukrainian then PTex := 'дриб' else PTex := 'дробь';
            '0': if CyrLang=Ukrainian then PTex := 'Нуль' else PTex:='0';
            '1': if CyrLang=Ukrainian then PTex := 'одын' else PTex:='1';
            '2': PTex:='2';
            '3': if CyrLang=Ukrainian then PTex := 'тры' else PTex:='3';
            '4': if CyrLang=Ukrainian then PTex := 'чотыры' else PTex:='4';
            '5': if CyrLang=Ukrainian then PTex := 'Пъять' else PTex:='5';
            '6': if CyrLang=Ukrainian then PTex := 'шисть' else PTex:='6';
            '7': if CyrLang=Ukrainian then PTex := 'Симь' else PTex:='7';
            '8': if CyrLang=Ukrainian then PTex := 'Висимь' else PTex:='8';
            '9': if CyrLang=Ukrainian then PTex := 'дэвъять' else PTex:='9';
            ':': if CyrLang=Ukrainian then PTex := 'двукрапка' else PTex:='Двоеточ';
            ';': if CyrLang=Ukrainian then PTex := 'КрапКома' else PTex:='Тэч зап';
            '<': if CyrLang=Ukrainian then PTex := 'Мэншэ' else PTex:='Ме+ньше';
            '=': if CyrLang=Ukrainian then PTex := 'Доривнюе' else  PTex:='Равно';
            '>': if CyrLang=Ukrainian then PTex := 'Бильшэ' else  PTex:='Бо+льше';
            '?': if CyrLang=Ukrainian then PTex := 'запыт' else PTex:='Вопр';
            '@': PTex:='Эт';
            '[': if CyrLang=Ukrainian then PTex := 'ЛиКваД' else PTex:='Леквас';
            ']': if CyrLang=Ukrainian then PTex := 'ПраКваД' else PTex:='Праквас';
            '\': PTex:='БэкСлэ+ш';
            '^': PTex:='Кры+шка';
            '_': PTex:='По+д';
            '`': if CyrLang=Ukrainian then PTex := 'Звор Апо' else PTex:='Обр апо';
            '{': if CyrLang=Ukrainian then PTex := 'ЛиФиД' else PTex:='Лефис';
            '}': if CyrLang=Ukrainian then PTex := 'ПраФиД' else PTex:='Прафис';
            '|': if CyrLang=Ukrainian then PTex := 'Вэртыкаль' else PTex:='Вертикаль';
            '~': PTex:='Ти+льда';
        'A','a': PTex:='Эй';
        'B','b': PTex:='Би';
        'C','c': PTex:='Си';
        'D','d': PTex:='Ди';
        'E','e': PTex:='И';
        'F','f': PTex:='Эф';
        'G','g': PTex:='Джи';
        'H','h': PTex:='Эйч';
        'I','i':
            begin
              if Speak_on or (CyrLang <> Ukrainian)
               then
                begin
                  PTex := 'ай';
                end
               else
                begin
                  PTex := 'и+';
                end;
            end;
        'J','j': PTex:='Джэй';
        'K','k': PTex:='Кэй';
        'L','l': PTex:='Эл';
        'M','m':
                 if speak_on then PTex := 'Ээм'
                             else PTex := 'эм';
        'N','n': PTex:='Эн';
        'O','o': PTex:='Оу';
        'P','p': PTex:='Пи';
        'Q','q': PTex:='Къю';
        'R','r': PTex:='Ар';
        'S','s': PTex:='Эс';
        'T','t': PTex:='Ти';
        'U','u': PTex:='Ю';
        'V','v': PTex:='Ви';
        'W','w': PTex:='Дабъйу';
        'X','x': PTex:='Экс';
        'Y','y': PTex:='Вай';
        'Z','z': PTex:='Зэт';
        'А','а': PTex:='А';
        'Б','б': PTex:='Бэ';
        'В','в': PTex:='Вэ';
        'Г','г': PTex:='Гэ';
        'Д','д': PTex:='Дэ';
        'Е','е': PTex:='Е';
        'Ж','ж': PTex:='Жжэ';
        'З','з': PTex:='Зэ';
        'И','и': PTex:='И';
        'Й','й': PTex:='И+ЙЙ';
        'К','к': PTex:='Ка';
        'Л','л': PTex:='Эль';
        'М','м': PTex:='Эмм';
        'Н','н': PTex:='Эн';
        'О','о': PTex:='О';
        'П','п': PTex:='Пэ';
        'Р','р': PTex:='Эр';
        'С','с': PTex:='Эс';
        'Т','т': PTex:='Тэ';
        'У','у': PTex:='У';
        'Ф','ф': PTex:='Эф';
        'Х','х': PTex:='Ха';
        'Ц','ц': PTex:='Цэ';
        'Ч','ч': PTex:='Чэ';
        'Ш','ш': PTex:='Ша';
        'Щ','щ': PTex:='Ща';
        'Ъ','ъ': PTex:='твЁ';
        'Ы','ы': PTex:='ы';
        'Ь','ь': PTex:='мя';
        'Э','э': PTex:='э';
        'Ю','ю': PTex:='йю';
        'Я','я': PTex:='йя';
        'Ё','ё': PTex:='Ё';
{!S! 11/19/96 }
        Ukr_Ge, _Ukr_Ge :PTex := 'ТВЭРДЭ+ гэ+';
        Ukr_Ye, _Ukr_Ye :if speak_on then PTex := 'Укр-ЙЭ'
             else PTex := 'йэ';
        Ukr_I, _Ukr_I :if speak_on then PTex := 'Укр-И'
               else  PTex := 'и';
        Ukr_Yi, _Ukr_Yi :PTex:= 'ЙЙИИ';
          end (*case*)
     else case A of (* Служебная клавиша *)
  CPgUp   : if CyrLang=Ukrainian then PTex := 'Попэрэдня Сторинка' else PTex:='Страни+ца вверх';
  CPgDn   : if CyrLang=Ukrainian then PTex := 'Наступна Сторинка' else  PTex:='Страни+ца вниз';
  CUp     : if CyrLang=Ukrainian then PTex := 'угору' else PTex:='Вве+рх';
  CDown   : if CyrLang=Ukrainian then PTex := 'Унызу' else PTex:='Вни+з';
  CLeft   : if CyrLang=Ukrainian then PTex := 'Ливо+руч' else PTex:='Вле+во';
  CRight  : if CyrLang=Ukrainian then PTex := 'Право+руч' else PTex:='Впра+во';
  CHome   : if CyrLang=Ukrainian then PTex := 'на початок' else  PTex:='В нача+ло';
  CEnd    : if CyrLang=Ukrainian then PTex := 'укинэтсь' else PTex:='В коне+ц';
  CIns    : PTex:='Вста+вка';
  CDel    : if CyrLang=Ukrainian then PTex := 'Зныщэння' else PTex:='Удале+ние';
  CF1     : if CyrLang=Ukrainian then       PTex := 'ЭФ одын' else PTex:='Эф 1';
  CF2     : PTex:='Эф 2';
  CF3     : if CyrLang=Ukrainian then PTex := 'ЭФ тры' else PTex:='Эф 3';
  CF4     : if CyrLang=Ukrainian then PTex := 'ЭФ Чотыры' else PTex:='Эф 4';
  CF5     : if CyrLang=Ukrainian then PTex := 'ЭФ пъять' else PTex:='Эф 5';
  CF6     : if CyrLang=Ukrainian then PTex := 'ЭФ шисть' else PTex:='Эф 6';
  CF7     : if CyrLang=Ukrainian then PTex := 'ЭФ симь' else  PTex:='Эф 7';
  CF8     : if CyrLang=Ukrainian then PTex := 'ЭФ висимь' else PTex:='Эф 8';
  CF9     : if CyrLang=Ukrainian then PTex := 'ЭФ дэвъять' else  PTex:='Эф 9';
  CF10    : if CyrLang=Ukrainian then PTex := 'ЭФ дэсять' else PTex:='Эф 10';
          end; (*case*)
    if Speak_on then SText00 (PTex);
end; (* SNamKey *)
