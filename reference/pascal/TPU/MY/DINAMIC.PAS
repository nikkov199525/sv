unit dinamic;

interface
type
    tbeep=           record
                        Status:         boolean;
                        end;

var
    Wave:           tBeep;

const
    S_Edge=         1;
    S_Err=          2;
    S_Cap=          3;
    S_Space=        4;
    S_StartP=       5;
    S_Tick=         6;
    S_Selected=     7;
    S_Break=        8;

procedure Beep(Freq,Delay:  longint);
procedure Signal(Variant:  byte);
procedure Play(const s: String);

implementation
uses MMSystem, SysUtils, Music;

const 
  PlaySoundFlags = SND_SYNC;

procedure Beep(Freq, Delay: longint);
var
  s: AnsiString;
begin
  if not Wave.Status then 
    exit;
  s:=Format('@%d:%d', [Freq, Delay]);
  PlayMusicA(PChar(s), PlaySoundFlags);
end;

procedure Signal(Variant:  byte);
begin
  if not Wave.Status then
    exit;
  case Variant of
    S_Edge: PlayMusicA('@2000:15', PlaySoundFlags);
    S_Err: PlayMusicA('@1000:20', PlaySoundFlags);
    S_Cap: PlayMusicA('@500:25', PlaySoundFlags);
    S_Space: PlayMusicA('@3000:15', PlaySoundFlags);
    S_StartP: PlayMusicA('@1000:18 @500:18 @250:18', PlaySoundFlags);
    S_Tick: {PlayMusicA('@1000:1', PlaySoundFlags)};
    S_Selected: PlayMusicA('@1000:150', PlaySoundFlags);
    S_Break: PlayMusicA('@800:100', PlaySoundFlags); 
  end;
end;

procedure Play(const s: String);
var
  sz: AnsiString;
begin
  if not Wave.Status then
    exit;
  sz:=s;
  PlayMusicA(PChar(sz), PlaySoundFlags); 
end;

begin
  Wave.Status:=True;
end.
