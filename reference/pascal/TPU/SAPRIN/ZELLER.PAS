unit Zeller;
interface

function    DayOfWeek( D, M, Y: Integer): Integer;

implementation

{=============================================}
function    DayOfWeek( D, M, Y: Integer): Integer;
{
Функция     Вычисление дня недели для любого календарного дня
            по формуле Зеллера
Параметры   D, M, Y: Integer День, Месяц, Год
Результат   День недели 0- Воскресенье... 6-Суббота
}
var
   C:  integer;
   Z:  integer;
   Dm: integer;
begin       {DayOfWeek}
if Y< 100 then
   Inc( Y, 1900);
if M< 3 then
   Inc( M, 10)
else
    Dec( M, 2);
if M> 10 then
   Dec( Y);
C:= Y div 100;
Y:= Y mod 100;
Z:= Trunc( 2.6* M- 0.1);
(*
У Форсайта ( "Паскаль для всех" )стр 21 и далее
формула дана как Z:= Trunc( 2.6* M- 0.2) но дает неверные результаты
*)
Dm:= Z+ D+ Y+ ( Y div 4)+( C div 4) - ( 2* C);
DayOfWeek:= ( Dm+ 777) mod 7;
end;        {DayOfWeek}

end.


