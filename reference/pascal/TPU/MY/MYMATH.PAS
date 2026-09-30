unit mymath;

interface

function  Degree(FNumber:  real;SNumber:  longint):  real;
function  Percent(Part:  real;Full:  real):  longint;
function  Definer_2(A11,A12,A21,A22:  real):  real;
function  Definer_3(A11,A12,A13,A21,A22,A23,A31,A32,A33:  real):  real;
function  Definer_4(A11,A12,A13,A14,A21,A22,A23,A24,A31,A32,A33,A34,A41,A42,A43,A44:  REAL):  real;

implementation

function  Degree(FNumber:  real;SNumber:  longint):  real;
    var
        Counter:        longint;
        BegNum:         real;

    begin
    if SNumber= 0 then
        begin
        DEgree:= 1;
        exit;
        end;
    BegNum:= FNumber;
    for Counter:= 1 to SNumber-1 do
        FNumber:= FNumber *BegNum;
    Degree:= FNumber;
    end;

function  Percent(Part:  real;Full:  real):  longint;
    begin
    if Full=0 then exit;
    Percent:= round((Part*100)/Full);
    end;

function  Definer_2(A11,A12,A21,A22:  real):  real;
    begin
    Definer_2:= A11*A22 - A12*A21;
    end;

function  Definer_3(A11,A12,A13,A21,A22,A23,A31,A32,A33:  real):  real;
    begin
    Definer_3:= (A11*A22*A33) +(A12*A23*A31) +(A13*A21*A32)
               -(A13*A22*A31) -(A12*A21*A33) -(A11*A23*A32);
    end;

function  Definer_4(A11,A12,A13,A14,A21,A22,A23,A24,A31,A32,A33,A34,A41,A42,A43,A44:  REAL):  real;
    var
        Result:         real;

    begin
    Result:= A11*Definer_3(A22,A23,A24,A32,A33,A34,A42,A43,A44);
    Result:= Result +(-A12*Definer_3(A21,A23,A24,A31,A33,A34,A41,A43,A44));
    Result:= Result +(A13*Definer_3(A21,A22,A24,A31,A32,A34,A41,A42,A44));
    Result:= Result +(-A14*Definer_3(A21,A22,A23,A31,A32,A33,A41,A42,A43));
    Definer_4:= Result;
    end;

begin
end.