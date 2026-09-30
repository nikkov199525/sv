unit htmtrans;
{$I-,V-}
interface
uses mem,  dos;

const
  maxavail = $1000000; // FIXME

type
    tTag=           string[20];

const
    Width=          72;
    Tab_Size=       5;
    Tag_Open=       '<';
    Tag_Close=      '>';
    Save_Link:      boolean = false;

var
    Usage_Mem:      tMemory;

procedure Htm2Txt(Htm_File,Txt_File:  pathstr);

implementation
uses line,transfrm;


procedure Htm2Txt(Htm_File,Txt_File:  pathstr);
    const
        BufSize=        $2000;

    type
        tBuffer=        array[0..BufSize] of char;
        tpBuffer=       ^tBuffer;
        tSpSymb=        record
                            FSym:           string[7];
                            ISym:           string[5];
                            end;

    const {//ss/19.04.2003 13:24:48//}
        Sym:            array[1..38] of tSpSymb =(
          (fSym: '&nbsp;'; iSym: ' '),
          (fSym: '&lt;'; iSym: '<'),
          (fSym: '&gt;'; iSym: '>'),
          (fSym: '&laquo;'; iSym: '"'),
          (fSym: '&raquo;'; iSym: '"'),
          (fSym: '&amp;'; iSym: '&'),
          (fSym: '&brvbar;'; iSym: '|'),
          (fSym: '&cdots;'; iSym: '...'),
          (fSym: '&copy;'; iSym: '(c)'),
          (fSym: '&deg;'; iSym: 'град.'),
          (fSym: '&emsp;'; iSym: ' '),
          (fSym: '&endash;'; iSym: '-'),
          (fSym: '&ensp;'; iSym: ' '),
          (fSym: '&frac12;'; iSym: '1/2'),
          (fSym: '&frac14;'; iSym: '1/4'),
          (fSym: '&frac34;'; iSym: '3/4'),
          (fSym: '&iexcl;'; iSym: '!'),
          (fSym: '&iquest;'; iSym: '?'),
          (fSym: '&ldots;'; iSym: '...'),
          (fSym: '&mdash;'; iSym: '-'),
          (fSym: '&middot;'; iSym: '.'),
          (fSym: '&ndash;'; iSym: '-'),
          (fSym: '&para;'; iSym: ''),
          (fSym: '&plusmn;'; iSym: '+/-'),
          (fSym: '&quot;'; iSym: '"'),
          (fSym: '&quadsp;'; iSym: '    '),
          (fSym: '&reg;'; iSym: '(R)'),
          (fSym: '&sect;'; iSym: '(s)'),
          (fSym: '&shy;'; iSym: '-'),
          (fSym: '&sp;'; iSym: ' '),
          (fSym: '&sup1;'; iSym: '^1'),
          (fSym: '&sup2;'; iSym: '^2'),
          (fSym: '&sup3;'; iSym: '^3'),
          (fSym: '&thinsp;'; iSym: ' '),
          (fSym: '&times;'; iSym: ' x '),
          (fSym: '&trade;'; iSym: 'TM'),
          (fSym: '&vdots;'; iSym: '|'),
          (fSym: '&hellip;'; iSym: '...') {//ss/22.04.2003 18:00:43//}
        );
    var
        Html:           file;
        NormText:       text;
        Tag_Opened:     boolean;
        Tag_Param:      string;
        RealSize:       word;
        Wrk_S:          string;
        Select:         boolean;
        Links:          toMemory;
        CSym:           word;
        Link:           string;
        Buf:            tpBuffer;
        Tag:            tTag;
        IOR:            integer;
        Pre:            boolean;
        OL:             longint;
        P2:             byte;
        S:              string;
        C:              word;
        P:              byte;

    procedure Save_S(St:  string);
        var
            SNum:           string[3];
            Num:            byte;
            Err:            integer;

        begin
        CSym:= 1;
        repeat
            while pos(Sym[CSym].FSym,St)> 0 do
                begin
                P:= pos(Sym[CSym].FSym,St);
                delete(St,P,length(Sym[CSym].FSym));
                insert(Sym[CSym].ISym,St,P);
                end;
            inc(CSym);
        until CSym> sizeof(Sym) div sizeof(Sym[1]);
        while (pos('&#',St)> 0) and (pos(';',St)> 0) do
            begin
            P:= pos(';',Right(St,length(St)-pos('&#',St)))+1;
            P2:= pos('&#',St);
            SNum:= copy(St,P2+2,P-3);
            val(SNum,Num,Err);
            if Err= 0 then
                begin
                delete(St,P2,P);
                insert(chr(Num),St,P2);
                end;
            end;
        writeln(NormText,St);
        end;

    begin
    if maxavail< sizeof(tBuffer)+1 then exit;
    IOR:= ioresult;
    assign(Html,Htm_File);
    filemode:= 0;
    reset(Html,1);
    filemode:= 2;
    if ioresult<> 0 then exit;
    assign(NormText,Txt_File);
    rewrite(NormText);
    if ioresult<> 0 then
        begin
        close(Html);
        exit;
        end;
    Tag:= '';
    S:= '';
    OL:= -1;
    Pre:= false;
    new(Buf);
    Select:= false;
    if Save_Link then
        begin
        Links.Sorce:= '';
        Links.Define(Usage_Mem,sizeof(string));
        end;
    Link:= '';
    while not eof(Html) do
        begin
        blockread(Html,Buf^,BufSize,RealSize);
        for C:= 0 to RealSize-1 do
            begin
            if (((Buf^[C]= #$D) and (Buf^[C+1]= #$A)) or (Buf^[C]= #$A))
               and ((S[length(S)]<> ' ') and (not Empty(S))) and (not Select)
               and (not Pre) then
                S:= S+' ';
            if ((Buf^[C]= #$D) and (Buf^[C+1]= #$A)) or (Buf^[C]= #$A) then
                begin
                if Pre then
                    begin
                    Save_s(S);
                    S:= '';
                    end;
                continue;
                end;
            if Buf^[C]= Tag_Open then
                begin
                Tag_Opened:= true;
                Tag:= '';
                Tag_Param:= '';
                continue;
                end;
            if (Buf^[C]= Tag_Close) and (Tag_Opened) then
                begin
                Tag_Opened:= false;
                if Tag= 'PRE' then
                    begin
                    Save_S(S);
                    Pre:= true;
                    end;
                if Tag= '/PRE' then
                    begin
                    Save_S(S);
                    Pre:= false;
                    end;
                if Tag= 'IMG ' then
                    if Left(Upper(Trim(Tag_Param)),3)= 'SRC' then
                        begin
                        P:= pos('''',Right(Tag_Param,length(Tag_Param)-pos('''',Tag_Param)))+1;
                        if P= 1 then
                            P:= pos('"',Right(Tag_Param,length(Tag_Param)-pos('"',Tag_Param)))+1;
                        P2:= pos('''',Tag_Param);
                        if P2= 0 then
                            P2:= pos('"',Tag_Param);
                        Link:= copy(Tag_Param,P2+1,P-2);
                        if RPos('/',Link)> 0 then
                            S:= S+Right(Link,RPos('/',Link)-1)
                        else
                            S:= S+Link;
                        end;
                if (Tag= 'A ') and (Save_Link) then
                    if Left(Upper(Trim(Tag_Param)),4)= 'HREF' then
                        begin
                        P:= pos('''',Right(Tag_Param,length(Tag_Param)-pos('''',Tag_Param)))+1;
                        if P= 1 then
                            P:= pos('"',Right(Tag_Param,length(Tag_Param)-pos('"',Tag_Param)))+1;
                        P2:= pos('''',Tag_Param);
                        if P2= 0 then
                            P2:= pos('"',Tag_Param);
                        if (P= 0) or (P2= 0) then
                            continue;
                        Link:= copy(Tag_Param,P2+1,P-2);
                        if Links.add(Link) then
                            S:= S+'['+LToS(Links.HowManyElem)+' ';
                        end;
                if (Tag= '/A') and (not Empty(Link)) and (Save_Link) then
                    begin
                    S:= S+']';
                    Link:= '';
                    end;
                if left(Tag,7)= 'SELECT ' then
                    begin
                    Select:= true;
                    S:= S+' [';
                    end;
                if Tag= '/SELECT' then
                    begin
                    Select:= false;
                    S:= S+']';
                    writeln(NormText,S);
                    S:= '';
                    end;
                if Left(Tag,7)= 'OPTION ' then
                    begin
                    if Right(RTrim(S),1)<> '[' then
                        S:= S+', ';
                    end;
                if Left(Tag,3)= 'HR ' then
                    begin
                    if not Empty(S) then
                        Save_S(S);
                    Wrk_S:= Space(3)+Replicate('_',Width-6);
                    Save_S(Wrk_S);
                    S:= '';
                    end;
                if Tag= 'OL' then OL:= 0;
                if Tag= '/OL' then OL:= -1;
                if (Tag= 'LI') and (OL> -1) then
                    begin
                    inc(OL);
                    Save_S(S);
                    str(OL,Wrk_S);
                    S:= Wrk_S+'.  ';
                    end;
                if Tag= '/P' then
                    if not Empty(S) then
                        begin
                        Save_S(S);
                        S:= '';
                        end;
                if Tag= 'P' then
                    begin
                    if not Empty(S) then
                        Save_S(S);
                    S:= Space(Tab_Size);
                    end;
                if Tag= 'TITLE' then
                    writeln(NormText);
                if Tag= '/TITLE' then
                    begin
                    Save_S(Space((Width-length(Trim(S))) div 2)+Trim(S));
                    writeln(NormText);
                    writeln(NormText);
                    S:= '';
                    end;
                if Tag= 'BR' then
                    begin
                    Save_S(S);
                    S:= '';
                    end;
                if Tag= 'DD' then
                    begin
                    if not Empty(S) then
                        Save_S(S);
                    S:= Space(Tab_Size);
                    end;
                continue;
                end;
            if (Tag_Opened) and (Tag[length(Tag)]<> ' ') then
                Tag:= Tag+upcase(Buf^[C]);
            if (Tag_Opened) and (Tag[length(Tag)]= ' ') then
                Tag_Param:= Tag_Param+upcase(Buf^[C]);
            if ((not Tag_Opened))
               and ((Buf^[C]<> ' ') or ((S[length(S)]<> ' ') and (S<> '')))
               and (not Pre) then
                S:= S+Buf^[C];
            if (Pre) and (Not Tag_Opened) then
                S:= S+Buf^[C];
            if (length(S)> Width) and (not Pre) then
                begin
                Wrk_S:= Right(S,RPos(' ',S));
                S:= Left(S,length(S)-RPos(' ',S));
                if Tag= 'TITLE' then
                    S:= Space((Width-length(S)) div 2)+S;
                Save_S(S);
                S:= LTrim(Wrk_S);
                end;
            end;
        end;
    if not Empty(S) then
        Save_S(S);
    if (Save_Link) and (Links.HowManyElem> 0) then
        begin
        S:= '';
        Save_s(S);
        for C:= 1 to Links.HowManyElem do
            if Links.Pick(C,Link) then
                begin
                S:= LToS(C)+'.'+Space(4-length(LToS(C)))+Link;
                Save_S(S);
                end;
        end;
    dispose(Buf);
    if Save_Link then
        Links.Undefine;
    close(Html);
    close(NormText);
    end;

begin
Usage_Mem:= mem.low;
end.