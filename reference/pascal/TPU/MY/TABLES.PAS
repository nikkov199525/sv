unit tables;

interface

type
    tOutputDevice=  (TactileDisplay,Printer);
    tRecode=        array[#0..#255] of string[3];
    tpRecode=       ^tRecode;
    tDefinition=    array[#0..#255] of byte;
    tpDefinition=   ^tDefinition;
    tReput=         array[#0..#255] of char;
    tpReput=        ^tReput;
    toRecode=       object
                        public
                            Recode:         tRecode;
                            Installed:      boolean;

                        constructor Install;
                        end;
    toDefinition=   object
                        public
                            Definition:     tDefinition;
                            Installed:      boolean;

                        constructor Install;
                        end;
    toBrl2Evr=      object
                        public
                            Brl2Evr:        tReput;
                            Installed:      boolean;

                        constructor Install;
                        end;
    toEvr2Brl=      object
                        public
                            Evr2Brl:        tReput;
                            Installed:      boolean;

                        constructor Install;
                        end;
    toDos2Win=      object
                        public
                            Dos2Win:        tReput;
                            Installed:      boolean;

                        constructor Install;
                        end;
    toWin2Dos=      object
                        public
                            Win2Dos:        tReput;
                            Installed:      boolean;

                        constructor Install;
                        end;
    toKoi2Dos=      object
                        public
                            Koi2Dos:        tReput;
                            Installed:      boolean;

                        constructor Install;
                        end;
    toDos2Koi=      object
                        public
                            Dos2Koi:        tReput;
                            Installed:      boolean;

                        constructor Install;
                        end;

function  Load_XLT(XLT_Name:  string;var Table:  tReput):  boolean;

implementation

var
    IOR:            word;

constructor toRecode.Install;
    var
        Counter:        byte;

    begin
    if Installed then
      Exit;
    Installed:= false;
    for Counter:= 0 to 32 do
        Recode[chr(Counter)]:= chr(Counter);
    Recode[#33]:= #43;
    Recode[#34]:= #56#48;
    Recode[#35]:= #110;
    Recode[#36]:= #36;
    Recode[#37]:= #35#106#48;
    Recode[#38]:= #38;
    Recode[#39]:= #46;
    Recode[#40]:= #40;
    Recode[#41]:= #41;
    Recode[#42]:= #42;
    Recode[#43]:= #43;
    Recode[#44]:= #49;
    Recode[#45]:= #45;
    Recode[#46]:= #52;
    Recode[#47]:= #44#47;
    Recode[#48]:= #106;
    for Counter:= 49 to 57 do
        Recode[chr(Counter)]:= chr(Counter+48);
    Recode[#58]:= #51;
    Recode[#59]:= #59;
    Recode[#60]:= #237;
    Recode[#61]:= #55;
    Recode[#62]:= #111;
    Recode[#63]:= #53;
    for counter:= 64 to 91 do
        Recode[chr(Counter)]:= chr(Counter);
    Recode[#92]:= #34#240;
    for counter:= 93 to 95 do
        Recode[chr(Counter)]:= chr(Counter);
    Recode[#96]:= #61;
    for counter:= 97 to 122 do
        Recode[chr(Counter)]:= chr(Counter);
    Recode[#123]:= #58;
    Recode[#124]:= #124;
    Recode[#125]:= #44;
    Recode[#126]:= #219;
    for Counter:= 127 to 255 do
        Recode[chr(Counter)]:= chr(Counter);
    Installed:= true;
    end;

constructor TODefinition.Install;
    var
        Counter:        byte;

    begin
    if Installed then
      Exit;
    Installed:= false;
    for Counter:= 0 to 31 do
        Definition[chr(Counter)]:= $01;
    Definition[#32]:= $00;
    Definition[#33]:= $02;
    Definition[#34]:= $03;
    for Counter:= 35 to 38 do
        Definition[chr(Counter)]:= $04;
    for Counter:= 39 to 47 do
        Definition[chr(Counter)]:= $02;
    for Counter:= 48 to 57 do
        Definition[chr(Counter)]:= $05;
    for Counter:= 58 to 63 do
        Definition[chr(Counter)]:= $02;
    Definition[#64]:= $04;
    for Counter:= 65 to 90 do
        Definition[chr(Counter)]:= $06;
    for Counter:= 91 to 93 do
        Definition[chr(Counter)]:= $02;
    for Counter:= 94 to 96 do
        Definition[chr(Counter)]:= $04;
    for Counter:= 97 to 122 do
        Definition[chr(Counter)]:= $07;
    for Counter:= 123 to 127 do
        Definition[chr(Counter)]:= $04;
    for Counter:= 128 to 159 do
        Definition[chr(Counter)]:= $08;
    for Counter:= 160 to 175 do
        Definition[chr(Counter)]:= $09;
    for Counter:= 176 to 223 do
        Definition[chr(Counter)]:= $0A;
    for Counter:= 224 to 239 do
        Definition[chr(Counter)]:= $09;
    definition[#240]:= $08;
    definition[#241]:= $09;
    for Counter:= 242 to 255 do
        Definition[chr(Counter)]:= $0A;
    Installed:= true;
    end;

constructor toBrl2Evr.Install;
    var
        Counter:        byte;

    begin
    if Installed then
      Exit;
    Installed:= false;
    for Counter:= 0 to 32 do
        Brl2Evr[chr(Counter)]:= chr(Counter);
    Brl2Evr[#33]:= #95;
    Brl2Evr[#34]:= #94;
    Brl2Evr[#35]:= #93;
    Brl2Evr[#36]:= #123;
    Brl2Evr[#37]:= #64;
    Brl2Evr[#38]:= #137;
    Brl2Evr[#39]:= #94;
    for Counter:= 40 to 43 do
        Brl2Evr[chr(Counter)]:= chr(Counter);
    Brl2Evr[#44]:= #125;
    Brl2Evr[#45]:= #45;
    Brl2Evr[#46]:= #39;
    Brl2Evr[#47]:= #47;
    Brl2Evr[#48]:= #37;
    Brl2Evr[#49]:= #44;
    Brl2Evr[#50]:= #59;
    Brl2Evr[#51]:= #58;
    Brl2Evr[#52]:= #46;
    Brl2Evr[#53]:= #63;
    Brl2Evr[#54]:= #33;
    Brl2Evr[#55]:= #61;
    Brl2Evr[#56]:= #34;
    Brl2Evr[#57]:= #42;
    Brl2Evr[#58]:= #123;
    Brl2Evr[#59]:= #59;
    Brl2Evr[#60]:= #36;
    Brl2Evr[#61]:= #96;
    Brl2Evr[#62]:= #91;
    Brl2Evr[#63]:= #38;
    Brl2Evr[#64]:= #41;
    for Counter:= 65 to 90 do
        Brl2Evr[chr(Counter)]:= chr(Counter);
    Brl2Evr[#91]:= #154;
    Brl2Evr[#92]:= #47;
    Brl2Evr[#93]:= #156;
    Brl2Evr[#94]:= #63;
    Brl2Evr[#95]:= #124;
    Brl2Evr[#96]:= #92;
    for Counter:= 97 to 122 do
        Brl2Evr[chr(Counter)]:= chr(Counter);
    Brl2Evr[#123]:= #40;
    Brl2Evr[#124]:= #124;
    Brl2Evr[#125]:= #41;
    Brl2Evr[#126]:= #63;
    for Counter:= 127 to 218 do
        Brl2Evr[chr(Counter)]:= chr(Counter);
    Brl2Evr[#219]:= #126;
    for Counter:= 220 to 255 do
        Brl2Evr[chr(Counter)]:= chr(Counter);
    Installed:= true;
    end;

constructor toEvr2Brl.Install;
    var
        Counter:        byte;

    begin
    if Installed then
      Exit;
    Installed:= false;
    for Counter:= 0 to 32 do
        Evr2Brl[chr(Counter)]:= chr(Counter);
    Evr2Brl[#33]:= #54;
    Evr2Brl[#34]:= #56;
    Evr2Brl[#35]:= #35;
    Evr2Brl[#36]:= #36;
    Evr2Brl[#37]:= #48;
    Evr2Brl[#38]:= #38;
    Evr2Brl[#39]:= #46;
    for Counter:= 40 to 43 do
        Evr2Brl[chr(Counter)]:= chr(Counter);
    Evr2Brl[#44]:= #49;
    Evr2Brl[#45]:= #45;
    Evr2Brl[#46]:= #52;
    Evr2Brl[#47]:= #47;
    Evr2Brl[#48]:= #106;
    for Counter:= 49 to 57 do
        Evr2Brl[chr(Counter)]:= chr(Counter+48);
    Evr2Brl[#58]:= #51;
    Evr2Brl[#59]:= #59;
    Evr2Brl[#60]:= #237;
    Evr2Brl[#61]:= #55;
    Evr2Brl[#62]:= #111;
    Evr2Brl[#63]:= #53;
    Evr2Brl[#64]:= #64;
    for Counter:= 65 to 90 do
        Evr2Brl[chr(Counter)]:= chr(Counter);
    Evr2Brl[#91]:= #62;
    Evr2Brl[#92]:= #96;
    Evr2Brl[#93]:= #35;
    Evr2Brl[#94]:= #34;
    Evr2Brl[#95]:= #33;
    Evr2Brl[#96]:= #61;
    for Counter:= 97 to 122 do
        Evr2Brl[chr(Counter)]:= chr(Counter);
    Evr2Brl[#123]:= #58;
    Evr2Brl[#124]:= #124;
    Evr2Brl[#125]:= #44;
    Evr2Brl[#126]:= #219;
    for Counter:= 127 to 255 do
        Evr2Brl[chr(Counter)]:= chr(Counter);
    Installed:= true;
    end;

constructor toDos2Win.Install;
    var
        Counter:        byte;

    begin
    if Installed then
      Exit;
    Installed:= false;
    for Counter:= $00 to $7F do
        Dos2Win[chr(Counter)]:= chr(Counter);
    for Counter:= 128 to 175 do
        Dos2Win[chr(Counter)]:= chr(Counter+64);
    for Counter:= $B0 to $DF do
        Dos2Win[chr(Counter)]:= chr(Counter);
    for Counter:= 224 to 239 do
        Dos2Win[chr(Counter)]:= chr(Counter+16);
    Dos2Win[#$f0]:= '¨';
    Dos2Win[#$f1]:= '¸';
    for Counter:= $F2 to $FF do
        Dos2Win[chr(Counter)]:= chr(Counter);
    Installed:= true;
    end;

constructor toWin2Dos.Install;
    var
        Counter:        byte;

    begin
    if Installed then
      Exit;
    Installed:= false;
    for Counter:= $00 to $BF do
        Win2Dos[chr(Counter)]:= chr(Counter);
    for Counter:= $C0 to $EF do
        Win2Dos[chr(Counter)]:= chr(Counter-$40);
    for Counter:= $F0 to $FF do
        Win2Dos[chr(Counter)]:= chr(Counter-$10);
    Win2Dos[#$82]:= '`';
    Win2Dos[#$84]:= '"';
    Win2Dos[#$85]:= '.';
    Win2Dos[#$91]:= '`';
    Win2Dos[#$92]:= '`';
    Win2Dos[#$93]:= '"';
    Win2Dos[#$94]:= '"';
    Win2Dos[#$96]:= '-';
    Win2Dos[#$97]:= '-';
    Win2Dos[#$8B]:= '`';
    Win2Dos[#$9B]:= '`';
    Win2Dos[#$AB]:= '"';
    Win2Dos[#$BB]:= '"';
    Win2Dos[#$A0]:= ' ';
    Win2Dos[#$B8]:= 'ñ';
    Win2Dos[#$A8]:= 'ð';
    Installed:= true;
    end;

constructor toKoi2Dos.Install;
    var
        Counter:        byte;

    begin
    if Installed then
      Exit;
    Installed:= false;
    for Counter:= 0 to 127 do
        Koi2Dos[chr(Counter)]:= chr(Counter);
    Koi2Dos[#128]:= #196;
    Koi2Dos[#129]:= #179;
    Koi2Dos[#130]:= #218;
    Koi2Dos[#131]:= #191;
    Koi2Dos[#132]:= #192;
    Koi2Dos[#133]:= #217;
    Koi2Dos[#134]:= #195;
    Koi2Dos[#135]:= #180;
    Koi2Dos[#136]:= #194;
    Koi2Dos[#137]:= #193;
    Koi2Dos[#138]:= #197;
    Koi2Dos[#139]:= #223;
    Koi2Dos[#140]:= #220;
    Koi2Dos[#141]:= #219;
    Koi2Dos[#142]:= #221;
    Koi2Dos[#143]:= #222;
    Koi2Dos[#144]:= #176;
    Koi2Dos[#145]:= #177;
    Koi2Dos[#146]:= #178;
    Koi2Dos[#147]:= #244;
    Koi2Dos[#148]:= #254;
    Koi2Dos[#149]:= #249;
    Koi2Dos[#150]:= #251;
    Koi2Dos[#151]:= #247;
    Koi2Dos[#152]:= #243;
    Koi2Dos[#153]:= #242;
    Koi2Dos[#154]:= #255;
    Koi2Dos[#155]:= #245;
    Koi2Dos[#156]:= #248;
    Koi2Dos[#157]:= #253;
    Koi2Dos[#158]:= #250;
    Koi2Dos[#159]:= #246;
    Koi2Dos[#160]:= #205;
    Koi2Dos[#161]:= #186;
    Koi2Dos[#162]:= #213;
    Koi2Dos[#163]:= #241;
    Koi2Dos[#164]:= #214;
    Koi2Dos[#165]:= #201;
    Koi2Dos[#166]:= #184;
    Koi2Dos[#167]:= #183;
    Koi2Dos[#168]:= #187;
    Koi2Dos[#169]:= #212;
    Koi2Dos[#170]:= #211;
    Koi2Dos[#171]:= #200;
    Koi2Dos[#172]:= #190;
    Koi2Dos[#173]:= #189;
    Koi2Dos[#174]:= #188;
    Koi2Dos[#175]:= #198;
    Koi2Dos[#176]:= #199;
    Koi2Dos[#177]:= #204;
    Koi2Dos[#178]:= #181;
    Koi2Dos[#179]:= #240;
    Koi2Dos[#180]:= #182;
    Koi2Dos[#181]:= #185;
    Koi2Dos[#182]:= #209;
    Koi2Dos[#183]:= #210;
    Koi2Dos[#184]:= #203;
    Koi2Dos[#185]:= #207;
    Koi2Dos[#186]:= #208;
    Koi2Dos[#187]:= #202;
    Koi2Dos[#188]:= #216;
    Koi2Dos[#189]:= #215;
    Koi2Dos[#190]:= #206;
    Koi2Dos[#191]:= #252;
    Koi2Dos[#192]:= #238;
    Koi2Dos[#193]:= #160;
    Koi2Dos[#194]:= #161;
    Koi2Dos[#195]:= #230;
    Koi2Dos[#196]:= #164;
    Koi2Dos[#197]:= #165;
    Koi2Dos[#198]:= #228;
    Koi2Dos[#199]:= #163;
    Koi2Dos[#200]:= #229;
    Koi2Dos[#201]:= #168;
    Koi2Dos[#202]:= #169;
    Koi2Dos[#203]:= #170;
    Koi2Dos[#204]:= #171;
    Koi2Dos[#205]:= #172;
    Koi2Dos[#206]:= #173;
    Koi2Dos[#207]:= #174;
    Koi2Dos[#208]:= #175;
    Koi2Dos[#209]:= #239;
    Koi2Dos[#210]:= #224;
    Koi2Dos[#211]:= #225;
    Koi2Dos[#212]:= #226;
    Koi2Dos[#213]:= #227;
    Koi2Dos[#214]:= #166;
    Koi2Dos[#215]:= #162;
    Koi2Dos[#216]:= #236;
    Koi2Dos[#217]:= #235;
    Koi2Dos[#218]:= #167;
    Koi2Dos[#219]:= #232;
    Koi2Dos[#220]:= #237;
    Koi2Dos[#221]:= #233;
    Koi2Dos[#222]:= #231;
    Koi2Dos[#223]:= #234;
    Koi2Dos[#224]:= #158;
    Koi2Dos[#225]:= #128;
    Koi2Dos[#226]:= #129;
    Koi2Dos[#227]:= #150;
    Koi2Dos[#228]:= #132;
    Koi2Dos[#229]:= #133;
    Koi2Dos[#230]:= #148;
    Koi2Dos[#231]:= #131;
    Koi2Dos[#232]:= #149;
    Koi2Dos[#233]:= #136;
    Koi2Dos[#234]:= #137;
    Koi2Dos[#235]:= #138;
    Koi2Dos[#236]:= #139;
    Koi2Dos[#237]:= #140;
    Koi2Dos[#238]:= #141;
    Koi2Dos[#239]:= #142;
    Koi2Dos[#240]:= #143;
    Koi2Dos[#241]:= #159;
    Koi2Dos[#242]:= #144;
    Koi2Dos[#243]:= #145;
    Koi2Dos[#244]:= #146;
    Koi2Dos[#245]:= #147;
    Koi2Dos[#246]:= #134;
    Koi2Dos[#247]:= #130;
    Koi2Dos[#248]:= #156;
    Koi2Dos[#249]:= #155;
    Koi2Dos[#250]:= #135;
    Koi2Dos[#251]:= #152;
    Koi2Dos[#252]:= #157;
    Koi2Dos[#253]:= #153;
    Koi2Dos[#254]:= #151;
    Koi2Dos[#255]:= #154;
    Installed:= true;
    end;

constructor toDos2Koi.Install;
    var
        Counter:        byte;

    begin
    if Installed then
      Exit;
    Installed:= false;
    for Counter:= 0 to 127 do
        Dos2Koi[chr(Counter)]:= chr(Counter);
    Dos2Koi[#196]:= #128;
    Dos2Koi[#179]:= #129;
    Dos2Koi[#218]:= #130;
    Dos2Koi[#191]:= #131;
    Dos2Koi[#192]:= #132;
    Dos2Koi[#217]:= #133;
    Dos2Koi[#195]:= #134;
    Dos2Koi[#180]:= #135;
    Dos2Koi[#194]:= #136;
    Dos2Koi[#193]:= #137;
    Dos2Koi[#197]:= #138;
    Dos2Koi[#223]:= #139;
    Dos2Koi[#220]:= #140;
    Dos2Koi[#219]:= #141;
    Dos2Koi[#221]:= #142;
    Dos2Koi[#222]:= #143;
    Dos2Koi[#176]:= #144;
    Dos2Koi[#177]:= #145;
    Dos2Koi[#178]:= #146;
    Dos2Koi[#244]:= #147;
    Dos2Koi[#254]:= #148;
    Dos2Koi[#249]:= #149;
    Dos2Koi[#251]:= #150;
    Dos2Koi[#247]:= #151;
    Dos2Koi[#243]:= #152;
    Dos2Koi[#242]:= #153;
    Dos2Koi[#255]:= #154;
    Dos2Koi[#245]:= #155;
    Dos2Koi[#248]:= #156;
    Dos2Koi[#253]:= #157;
    Dos2Koi[#250]:= #158;
    Dos2Koi[#246]:= #159;
    Dos2Koi[#205]:= #160;
    Dos2Koi[#186]:= #161;
    Dos2Koi[#213]:= #162;
    Dos2Koi[#241]:= #163;
    Dos2Koi[#214]:= #164;
    Dos2Koi[#201]:= #165;
    Dos2Koi[#184]:= #166;
    Dos2Koi[#183]:= #167;
    Dos2Koi[#187]:= #168;
    Dos2Koi[#212]:= #169;
    Dos2Koi[#211]:= #170;
    Dos2Koi[#200]:= #171;
    Dos2Koi[#190]:= #172;
    Dos2Koi[#189]:= #173;
    Dos2Koi[#188]:= #174;
    Dos2Koi[#198]:= #175;
    Dos2Koi[#199]:= #176;
    Dos2Koi[#204]:= #177;
    Dos2Koi[#181]:= #178;
    Dos2Koi[#240]:= #179;
    Dos2Koi[#182]:= #180;
    Dos2Koi[#185]:= #181;
    Dos2Koi[#209]:= #182;
    Dos2Koi[#210]:= #183;
    Dos2Koi[#203]:= #184;
    Dos2Koi[#207]:= #185;
    Dos2Koi[#208]:= #186;
    Dos2Koi[#202]:= #187;
    Dos2Koi[#216]:= #188;
    Dos2Koi[#215]:= #189;
    Dos2Koi[#206]:= #190;
    Dos2Koi[#252]:= #191;
    Dos2Koi[#238]:= #192;
    Dos2Koi[#160]:= #193;
    Dos2Koi[#161]:= #194;
    Dos2Koi[#230]:= #195;
    Dos2Koi[#164]:= #196;
    Dos2Koi[#165]:= #197;
    Dos2Koi[#228]:= #198;
    Dos2Koi[#163]:= #199;
    Dos2Koi[#229]:= #200;
    for Counter:= 168 to 175 do
        Dos2Koi[chr(Counter)]:= chr(Counter+33);
    Dos2Koi[#239]:= #209;
    Dos2Koi[#224]:= #210;
    Dos2Koi[#225]:= #211;
    Dos2Koi[#226]:= #212;
    Dos2Koi[#227]:= #213;
    Dos2Koi[#166]:= #214;
    Dos2Koi[#162]:= #215;
    Dos2Koi[#236]:= #216;
    Dos2Koi[#235]:= #217;
    Dos2Koi[#167]:= #218;
    Dos2Koi[#232]:= #219;
    Dos2Koi[#237]:= #220;
    Dos2Koi[#233]:= #221;
    Dos2Koi[#231]:= #222;
    Dos2Koi[#234]:= #223;
    Dos2Koi[#158]:= #224;
    Dos2Koi[#128]:= #225;
    Dos2Koi[#129]:= #226;
    Dos2Koi[#150]:= #227;
    Dos2Koi[#132]:= #228;
    Dos2Koi[#133]:= #229;
    Dos2Koi[#148]:= #230;
    Dos2Koi[#131]:= #231;
    Dos2Koi[#149]:= #232;
    for Counter:= 136 to 143 do
        Dos2Koi[chr(Counter)]:= chr(Counter+97);
    Dos2Koi[#159]:= #241;
    for Counter:= 144 to 147 do
        Dos2Koi[chr(Counter)]:= chr(Counter+98);
    Dos2Koi[#134]:= #246;
    Dos2Koi[#130]:= #247;
    Dos2Koi[#156]:= #248;
    Dos2Koi[#155]:= #249;
    Dos2Koi[#135]:= #250;
    Dos2Koi[#152]:= #251;
    Dos2Koi[#157]:= #252;
    Dos2Koi[#153]:= #253;
    Dos2Koi[#151]:= #254;
    Dos2Koi[#154]:= #255;
    Installed:= true;
    end;

function  Load_XLT(XLT_Name:  string;var Table:  tReput):  boolean;
    var
        XLT:            file;
        Buf:            array[0..$FF] of byte;
        RealSize:       word;
        C:              word;

    begin
    Load_XLT:= false;
    assign(XLT,XLT_Name);
    IOR:= ioresult;
    filemode:= 0;
    reset(XLT,1);
    filemode:= 2;
    if ioresult<> 0 then
        exit;
    blockread(XLT,Buf,sizeof(Buf),RealSize);
    if ioresult<> 0 then
        exit;
    for C:= 0 to $FF do
        Table[chr(C)]:= chr(C);
    C:= 0;
    while C< RealSize-1 do
        begin
        Table[chr(Buf[C])]:= chr(Buf[C+1]);
        inc(C,2);
        end;
    close(XLT);
    Load_XLT:= true;
    end;

begin
end.