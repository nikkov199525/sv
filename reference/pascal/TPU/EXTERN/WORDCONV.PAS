unit wordconv;
interface
uses Objects,dos;

const
    Discret:        byte = 0;
    MaxMarg:        byte = 8;
    MaxBack:        byte = 16;
    Es_Sym:         string[32] = '.,)]};: ';

function Word97_CharDecode: Char;
function Word97_UnicharDecode(uch: Word): byte;
procedure trans_w97_txt(var Word97_F,Txt_F:  pathstr);

implementation
uses line;
{Š®­¢¥àâ¥à Word 97 to Dos}

{ ’¥ªáâ ­ ç¨­ ¥âáï ¯® á¬¥é¥­¨î 600h }
{ —¨â âì ¤¢  ¡ ©â , 0000 - ª®­¥æ â¥ªáâ , ¨­ ç¥ à áª®¤¨à®¢ âì äã­ªæ¨¥©
  Word97_UnicharDecode }
{ ®«ãç ¥¬ Dos á¨¬¢®« }
{ ¥á«¨ $0D, ¤®¡ ¢¨âì $0A }


function Word97_UnicharDecode(uch: Word): byte; assembler;

asm
                {or     ax, ax
                jz      loc_0_1B4}
                mov     ax, uch
                cmp     ax, 7
                jz      @@1
                cmp     ax, 0Dh
                jz      @@2
                cmp     ax, 20h ; {' '}
                jb      @@3
                cmp     ax, 0FFh
                jbe     @@2
                cmp     ax, 0410h
                jb      @@3
                cmp     ax, 044Fh
                ja      @@3
                sub     ax, 0352h

@@1:            add     ax, 2

@@2:            call    Word97_CharDecode

@@3:
end;

function Word97_CharDecode: Char; assembler;
asm
        cmp             al, 0C0h ; {'À'}
        jb              @@2
        cmp             al, 0EFh ; {'ï'}
        ja              @@1
        sub             al, 40h ;  {'@'}
        jmp             @@6
// ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
@@1:    sub             al, 10h
        jmp             @@6
// ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
@@2:    cmp             al, 0A8h ; {'¨'}
        jnz             @@3
        mov             al, 0F0h ; {'ð'}
        jmp             @@6
// ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
@@3:    cmp             al, 0B8h ; {'¸'}
        jnz             @@4
        mov             al, 0F1h ; {'ñ'}
        jmp             @@6
// ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
@@4:    cmp             al, 0ABh ; {'«'}
        jz              @@5
        cmp             al, 0BBh ; {'»'}
        jnz             @@6

@@5:    mov             al, 22h  ; {'"'}

@@6:
end;

var
  FileIn, FileOut: TBufStream;
  Unichar: Word;
  Ch: Byte;
procedure trans_w97_txt(var Word97_F,Txt_F:  pathstr);
    var
        Symbs:          byte;

begin
  FileIn.Init(Word97_F, stOpenRead, $4000);
  FileOut.Init(Txt_F, stCreate, $4000);
  FileIn.Seek($600);
  while FileIn.Status = stOk do
  begin
    FileIn.Read(Unichar, 2);
    if Unichar = 0 then break;
    Ch:=Word97_UnicharDecode(Unichar);
    FileOut.Write(Ch, 1);
    if ch = $0D
    then begin
      ch:=$0A;
      FileOut.Write(Ch, 1);
    Symbs:= 0;
    end;
    if Discret> 0 then
        begin
        inc(Symbs);
        if (Find_Sym(chr(ch),ES_Sym)> 0) and
           ((Symbs> Discret-MaxBack) and (Symbs< Discret+MaxMarg)) then
            begin
            Ch:= $0D;
            FileOut.Write(Ch, 1);
            Ch:= $0A;
            FileOut.Write(Ch, 1);
            Symbs:= 0;
            end;
        if Symbs= Discret+MaxMarg then
            begin
            Ch:= $0D;
            FileOut.Write(Ch, 1);
            Ch:= $0A;
            FileOut.Write(Ch, 1);
            Symbs:= 0;
            end;
        end;
  end;
  FileIn.Done;
  FileOut.Done;
end;

begin
Discret:= 0;
end.