// $Id$
unit music;                                                      { version 1.0 }

(******************************************************** 1990 J.C. Kessels ****
Play music in the background.


This unit gives you music capabilities with a BASIC syntax. The music
will be played in the background, so your program can continue with
other things. The music can also be played in the foreground.

This unit is very easy to use. There are only three procedures and one
function interfaced outwards. All the rest is automatic (installing,
uninstalling, interpreting the music, etc.)!


PlayMusic(string);
          Start playing a string of music in the background. The string
          is a normal character string containing music 'commands' as
          described below. If there is already music playing, then it is
          first shut off. All settings are reset to their default.

PlayMusicForeground(string);
          Start playing a string of music, and wait for it to finish. If
          there is already music playing, then it is first shut off. All
          settings are reset to their default.
          This procedure simply calls the "PlayMusic" procedure, and then
          loops until MusicBusy (described later) is true.

MusicOff;
          Turn music off.

if MusicBusy then ...
          Return TRUE if there is currently music playing.

See at the end of this unit for a small demonstration program.





The music-commands syntax is (BASIC compatible):

[>,<]A..G[#,+,-](n)[.]
          Play note A..G in the current octave. There are 12 notes per
          octave: C, C#, D, D#, E, F, F#, G, G#, A, A#, B.
           If the note is prefixed by '>', then it is transposed one octave
            upwards.
           If the note is prefixed by '<', then it is transposed one octave
            downward.
           if the note is followed by '#' or '+', then the note is made
            "sharp" (one note up, 'D' becomes 'D#', 'E' becomes 'F').
           If the note is followed by '-', then the note is made "flat" (one
            note down, 'D' becomes 'C#').
           If the note is followed by a number, then the number specifies the
            length of this note, overriding the default notelength set by 'L'.
           Every period following the notenumber will increase the playtime
            by 3/2.
          Example:   >B+3.
                     >      : transposed
                      B     : note B
                       +    : sharp
                        3   : length 3
                         .  : 3/2 longer
N(n)[.]   Play note "n", in which "n" is a number 0..84. There are 7 octaves,
          12 notes per octave. Note 0 means: silence. The first note in the
          first octave is 'N1'.
           Every period following the notenumber will increase the playtime
            by 3/2.
O(n)      Sets the octave to "n", in which "n" is a number 0..7. Each octave
          goes from note 'C' to 'B'. Octave 3 starts with middle 'C'. Default
          octave is 4.
L(n)      Set the default length of following notes to "n", in which "n" is
          a number 1..64. L1 = whole notes, L2 = half notes, L4 = quarter
          notes, etc. Default length is 4. In one minute fit 120 quarter
          notes ('L4'), adjustable with the 'T' (tempo) command.
T(n)      Set the tempo to "n", in which "n" is a number 32..255. The tempo
          is the number of quarter notes ('L4') that are played per minute.
          The higher the tempo, the faster the music. Default tempo is 120.
MN        Music Normal. Every note plays seven-eights of the time set by
          'L', and is followed by a pause of one-eight. Thus, every note is
          followed by a small silence, making the music more natural.
ML        Music Legato. Every note plays the full time set by 'L'. Thus, every
          note is immediately followed by the next note, making the music a
          bit synthetic.
MS        Music Staccato. Every note plays three-quarters of the time
          set by 'L', and is followed by a pause of one-quarter. Thus, every
          note is followed by a clearly audible silence, making the music
          very rithmic.
P(n)[.]   Insert a pause with a length of "n", in which "n" is a number
          1..64.
           Every period following the number will increase the playtime
            by 3/2.

Not supported (ignored):
MF        Foreground: Cannot switch between foreground/background.
MB        Background: Cannot switch between foreground/background.
Xs$;      Include string: Cannot include substrings.
=n;       Use variable "n": Cannot replace variable's names by their contents.

Spaces are allowed between commands, but not inside commands.
Upper/lowercase is not important.




THEORY.

This unit installs itself in the timertick interrupt $1C (procedure
"MusicNext"). With every timertick a buffer is checked. If there is any
music to be played in the buffer, then a single note from the buffer is
played.




This unit was inspired by a (buggy and incomplete) public domain unit
written by Michael Quinlan, 9/17/85.



J.C. Kessels
Philips de Goedelaan 7
5615 PN Eindhoven
Netherlands
*******************************************************************************)

Interface
uses Wave, Windows, MMSYSTEM{, Logger};

function GenerateMusic(const MusicString: string; AVolume: Double = 0.7): TWaveChunks;
function PlayMusic(const S: string; flags: Cardinal=0; Volume: Double = 0.7): BOOL;

Implementation

Function Power(X, Y : Double) : Double;
begin
  Power := Exp(Y * Ln(X));
end;

procedure AppendBeep(var chunks: TWaveChunks; freq, duration: Double; volume: Double=1.0);
begin
  //Writeln(duration:1:4, ' ', freq:1:4);
  SetLength(chunks, Length(chunks)+1);
  chunks[high(chunks)]:=GenerateSound(freq, duration, volume);
end;


{
JOERGEN DORCH

 About Sounds i Pascal - Here's how I do it:
}

Function Frequency(NoteNum : Integer) : Double;
Const
  Silence = 0;
Var
  Octave, Oct : Integer;


begin
  Octave:=NoteNum div 12;
  Dec(NoteNum, Octave*12-1);
  //Inc(Octave, 2);
  {
    Where Octave is in the range [0..6] and NoteNum in the range [1..12],
   that is C = 1, C# = 2, D = 3 etc.
  }
  //Writeln('o',Octave, 'n', NoteNum);
  Oct := Octave - 3;
  if NoteNum > 0 then
    Frequency := 440.0 * Power(2.0, Oct + ((NoteNum - 10.0) / 12.0))
  else
    Frequency := Silence;
end;


function GenerateMusic(const MusicString: string; AVolume: Double): TWaveChunks;
var
  //MusicString     : string;                         { The string to be played. }
  MusicHere       : Integer;  { Pointer into MusicString, non-zero while playing. }
  MusicDelay1     : Double;             { Clockticks countdown for current note. }
  MusicDelay2     : Double;             { Clockticks countdown for current note. }
  MusicNoteLength : Integer;                               { Current note length. }
  MusicTempo      : Integer;                                     { Current tempo. }
  MusicOctave     : Integer;                                    { Current octave. }
  MusicKind       : Integer;              { 8 = Legato, 7 = Normal, 6 = Staccato. }
  Volume          : Double;
  { Array with coded frequenc ies: 12 notes per octave (C, C#, D, D#, E, F, F#,
    G, G#, A, A#, B), 7 octaves. }
  //Frequency       : array[0..83] of Double;

function GetNumber(min, max, default : word) : word;
{ Get a number from the MusicString, starting at MusicHere. Increment MusicHere
  past the end of the number. If the number is <min or >max then the default
  number is returned. This routine will also skip the Basic syntax for a
  variable: '=name;' }
var
  n : word;
begin
  { Ignore Basic syntax for embedded variable instead of constant, and exit
    with the default. }
  if (MusicHere <= length(MusicString)) and (MusicString[MusicHere] = '=')
  then begin
    while (MusicHere <= length(MusicString)) and (MusicString[MusicHere] <> ';')
    do inc(MusicHere);
    if (MusicHere <= length(MusicString)) and (MusicString[MusicHere] = ';')
    then inc(MusicHere);
    GetNumber := default;
    exit;
  end;

{ Accept a number from the MusicString. The number is finished by anything that
  is not a number '0'..'9'. }
  n := 0;
  while (MusicHere <= length(MusicString)) and
        (MusicString[MusicHere] in ['0'..'9'])
  do  begin
    n := n * 10 + (Ord(MusicString[MusicHere]) - Ord('0'));
    inc(MusicHere);
  end;

  { Test if the number is within range, otherwise return the default. }
  if (n < min) or (n > max)
  then Result := default
  else Result := n;
end;




procedure SetupDelays;
{ Setup MusicDelay1 and MusicDelay2. The first determines the time that a note
  is audible, the second determines a rest between two notes (Legato, Normal,
  Staccato). To do this, accept a note-length number from the MusicString, or
  use the default NoteLength. Also accept trailing dot's from the MusicString,
  which lengthen the note-length by 1.5. }
var
  r : Double;
begin
  { Accept number. }
  r := 1.0/GetNumber(1,512,MusicNoteLength);

{ Note: the number is reciprocal. A high number means a short note. If the
  number is 4, then it is a 'normal' note. Think of the number as: "the number
  of quarter notes that the note will last". }

  while (MusicHere <= length(MusicString)) and          { Accept trailing dot's. }
        (MusicString[MusicHere] = '.') do
  begin
    inc(MusicHere);
    r := r * 1.5;             { Every dot increases the note time by 1.5 times. }
  end;

  { Translate into clocktick delays. The following formula is used:
    There are 120 'standard' notes per minute.
        ticks = ThisNoteLength * ThisTempo * TicksPerStandardNote
        ThisNoteLength = 4 / NoteLength
        ThisTempo = 120 / MusicTempo
        TicksPerStandardNote = TicksPerMinute / 120
        TicksPerMinute = TicksPerSecond * 60
        TicksPerSecond = 18.2
  ticks := 4 * 18.2 * 60 * / (NoteLength * MusicTempo) }
  MusicDelay1 := 60.0*(r*(4.0/MusicTempo));
  //Write('len=', r/4.0:1:1, ' temp=', 4.0/MusicTempo:1:1, ' ');

{ The clockticks are split two ways: every note is followed by a small amount
  of silence (Legato, Normal, Staccato). MusicDelay1 determines the 'on' time,
  MusicDelay2 determines the 'off' time. }
  if MusicKind < 8
  then MusicDelay2 := MusicDelay1 * (8.0 - MusicKind) / 8.0
  else MusicDelay2 := 0.0;
  MusicDelay1:=MusicDelay1-MusicDelay2;
end;

//***********************
var
  note : word;                                          { Temporary variables. }
  ch : char;
  p1, sound_freq, sound_length: Integer;
begin
  SetLength(Result, 0);
  MusicNoteLength := 4;                                        { Setup defaults. }
  MusicTempo := 120;
  MusicOctave := 4;
  MusicKind := 7;
  MusicHere := 1;                            { Start music (at begin of string). }
  Volume    := AVolume;
  { Process commands from MusicString, until a note or a pause can be played. A
    few Basic commands are not supported, these are ignored. }
  while MusicHere <= length(MusicString) do
  begin
    ch := upcase(MusicString[MusicHere]);      { Get character from MusicString. }
    inc(MusicHere);
    case ch of
      '@' : begin
        sound_freq:=GetNumber(0, 22050, 440);
        if MusicString[MusicHere] <> ':' then 
            continue;
        inc(MusicHere);
        sound_length:=GetNumber(0, 10000, 1000);
        AppendBeep(Result, sound_freq, sound_length/1000.0, volume);
      end;
      'O' : MusicOctave := GetNumber(0,7,4);         { Set octave. }
      'L' : MusicNoteLength := GetNumber(1,512,4);    { Set note length. }
      'T' : MusicTempo := Getnumber(32,512,120);     { Set tempo. }
      'V' : Volume := Getnumber(0,100,50)/100*AVolume;
      'M' : if MusicHere <= length(MusicString) then { 'M' commands. }
            begin
              ch := upcase(MusicString[MusicHere]);
              inc(MusicHere);
              case ch of
                'L' : MusicKind := 8;  { Set legato. }
                'N' : MusicKind := 7;  { Set normal. }
                'S' : MusicKind := 6;  { Set staccato. }
              end;
      end;
      'P' : begin                                                       { Pause. }
        SetupDelays;
        AppendBeep(Result, 0.0, MusicDelay1+MusicDelay2, Volume);
      end;
      'A'..'G','>','<' : begin  { Play a note. }
        note := MusicOctave * 12;
        if ch = '>' then
        begin   { Accept '>'. }
          if MusicHere <= length(MusicString)
          then ch := upcase(MusicString[MusicHere]);
          inc(MusicHere);
          if note <= 71 then inc(note, 12);
        end;
        if ch = '<' then begin { Accept '<'. }
          if MusicHere <= length(MusicString)
          then ch := upcase(MusicString[MusicHere]);
          inc(MusicHere);
          if note >= 12 then dec(note,12);
        end;
        case ch of                            { Determine frequency of note. }
              'C' : inc(note,0);  {До}
              'D' : inc(note,2);  {Ре}
              'E' : inc(note,4);  {Ми}
              'F' : inc(note,5);  {Фа}
              'G' : inc(note,7);  {Соль}
              'A' : inc(note,9);  {Ля}
              'B' : inc(note,11); {Си}
        end;
        { Accept '#' or '+' following the letter. }
        if (MusicHere <= length(MusicString)) and
               ( (MusicString[MusicHere] = '#') or (MusicString[MusicHere] = '+') )
        then begin
          inc(MusicHere);
          if note < 10 then inc(note);
        end;
        { Accept '-' following the letter. }
        if (MusicHere <= length(MusicString)) and
            (MusicString[MusicHere] = '-')
        then begin
          inc(MusicHere);
          if note > 0 then dec(note);
        end;
        SetupDelays;                             { Setup note length delays. }
        AppendBeep(Result, Frequency(note), MusicDelay1, volume);
        AppendBeep(Result, 0.0, MusicDelay2, volume);
      end;
      'N' : begin                                        { Play a specific note. }
        note := GetNumber(1,84,0);                     { Accept note number. }

        SetupDelays;                             { Setup note length delays. }
        if note > 0 then { Zero means silence. }
          AppendBeep(Result, Frequency(note-1), MusicDelay1, volume)
        else
          AppendBeep(Result, 0.0, MusicDelay1, volume);
        AppendBeep(Result, 0.0, MusicDelay2, volume);
      end;
      'X' : begin                { Skip the Basic syntax for an embedded string. }
            while (MusicHere <= length(MusicString)) and
              (MusicString[MusicHere] <> ';') do inc(MusicHere);
            if (MusicHere <= length(MusicString)) and
              (MusicString[MusicHere] = ';') then inc(MusicHere);
      end;
      (*'\': if MusicHere <= length(MusicString) then begin {escape}
        ch := upcase(MusicString[MusicHere]);      { Get character from MusicString. }
        inc(MusicHere);
        case ch of
          'I': if SndDev.GetName = 'Adlib' then begin {select AdLib instrument}
              s:='';
              if MusicString[MusicHere] in ['0'..'9']
              then S:=Instruments.KeyAt(GetNumber(0, 30000, 0))
              else while (MusicHere <= length(MusicString)) and
                    (not (MusicString[MusicHere] in [' ', '|', ';']))
              do  begin
                 s:=s+MusicString[MusicHere];
                 inc(MusicHere);
              end;
              Instrument:=PInstrumentItem(Instruments.Get(S));
              if Assigned(Instrument) then begin
                TBDAdlib(SndDev.GetDevice^).SetInstrument(0, Instrument);
                Dispose(Instrument, Done);
             end else begin
                while (MusicHere <= length(MusicString)) and
                    (not (MusicString[MusicHere] in [' ', '|', ';']))
              do inc(MusicHere);
             end;
          end;
        end;
      end;*)
    end; {case}
  end;
end;



function PlayMusic(const S: string; flags: Cardinal; Volume: Double): BOOL;
var
  c: TWaveChunks;
  w: TWaveBlock;
  //f: File;
begin
  //Log('GenerateMusic %s', [s], 3);
  c:=GenerateMusic(s, volume);
  //Log('Chunks: %d', [Length(c)], 3);
  if Length(c)=0 then Exit;
  w:=CreateWave(c);
  //Log('Block: %d', [Length(w)], 3);
  if Length(w)=0 then Exit;
  Result:=PlaySound(@w[0], 0, SND_MEMORY or flags);
  {Assign(f, 'playmusic.wav');
  Rewrite(f, 1);
  BlockWrite(f, w[0], Length(w));
  Close(f);}
  //Log('Done', 3);
end;

end.
