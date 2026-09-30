{$M-}
unit Wave;
// $Id: wave.pas 3313987ea6bc 2014/06/08 14:53:48 serg $
interface

type
  TWaveBlock = array of Byte;
  TWaveChunk = array of Word;
  TWaveChunks = array of TWaveChunk;
  PWaveChunks0 = ^TWaveChunks0;
  TWaveChunks0 = array[0..0] of TWaveChunk;

function GenerateSound(freq, duration: Double; volume: Double=1.0): TWaveChunk;

function CreateWave(chunks: PWaveChunks0; chunks_count: Cardinal): TWaveBlock; overload;
function CreateWave(const chunks: TWaveChunks): TWaveBlock; overload;
function CreateWave(const chunks: array of TWaveChunk): TWaveBlock; overload;

implementation
const
  SAMPLE_RATE = 44100.0;
  BITS = 16;
  PI = 3.14159265359;
  MODULO = $10000 / 2 - 1;
  UNSIGNER = 0;
  ATTACK = 0.05;
  DECAY = 0.1;

function GenerateSound(freq, duration, volume: Double): TWaveChunk;
var
  samples, i, attack_samples, decay_samples: Cardinal;
  period: Double;
  angle_step: Double;
  angle: Double;
  vol_var: Double;
  vol_step: Double;
begin
  samples:=trunc(duration*SAMPLE_RATE);
  SetLength(Result, samples);
  if samples=0 then
    Exit;
  if freq<>0.0 then begin
    angle:=0.0;
    period:=2.0*PI*freq;
    angle_step:=({2.0*PI*freq}period)/SAMPLE_RATE;
    attack_samples:=Round(samples*ATTACK);
    decay_samples:=Round(samples*DECAY);
    vol_var:=0.0;
    vol_step:=volume/attack_samples;
    for i:=0 to attack_samples do begin
      vol_var:=vol_var+vol_step;
      Result[i]:=Round((sin(angle)*MODULO*vol_var))+UNSIGNER;
      angle:=angle+angle_step;
    end;
    for i:=attack_samples+1 to High(Result)-decay_samples do begin
      Result[i]:=Round((sin(angle)*MODULO*volume))+UNSIGNER;
      angle:=angle+angle_step;
    end;
    vol_var:=volume;
    vol_step:=volume/decay_samples;
    for i:=High(Result)-decay_samples to High(Result) do begin
      Result[i]:=Round((sin(angle)*MODULO*vol_var))+UNSIGNER;
      angle:=angle+angle_step;
      vol_var:=vol_var-vol_step;
    end;
    {angle:=Result[High(Result)-SLICE];
    angle_step:= angle / SLICE;
    for i:=High(Result)-SLICE to High(Result) do begin
      Result[i]:=Round(angle);
      angle:=angle - angle_step;
    end;}
  end else begin
    for i:=0 to High(Result) do
      Result[i]:=UNSIGNER;
  end;
end;

type
  short = Word;
  long = Cardinal;
  WAVEFMTHEADER = packed record
    FormatTag: short;
    Channels: short;
    SamplesPerSec: long;
    AvgBytesPerSec: long;
    BlockAlign: short;
    BitsPerSample: short;
  end;
  FOURCC = array[0..3] of Char;
  WAVEHEADER = packed record
    WaveHead: FOURCC;
    Fmt: FOURCC;
    FmtSize: long;
    format: WAVEFMTHEADER;
    DataHead: FOURCC;
    DataSize: long;
    data: record end;
  end;
  RIFFWAVEHEADER = record
    RiffHead: FOURCC;
    RiffSize: long;
    wave: WAVEHEADER;
  end;

function CreateWave(chunks: PWaveChunks0; chunks_count: Cardinal): TWaveBlock; overload;
var
  i, total_sampl: Cardinal;
  wave_size, riff_wave_size: Cardinal;
  riff:^RIFFWAVEHEADER;
  cursound: ^short;
begin
  SetLength(Result, 0);
  if chunks_count = 0 then Exit;
  total_sampl:=0;
  for i:=0 to chunks_count-1 do 
    Inc(total_sampl, Length(chunks[i]));
  wave_size:=total_sampl*sizeof(short);
  riff_wave_size:=sizeof(RIFFWAVEHEADER)+wave_size;
  SetLength(Result, riff_wave_size);
  Pointer(riff):=Addr(Result[0]);
  riff.RiffHead:='RIFF';
  riff.RiffSize:=sizeof(WAVEHEADER)+wave_size;
  riff.wave.WaveHead:='WAVE';
  riff.wave.Fmt:='fmt ';
  riff.wave.FmtSize:=sizeof(WAVEFMTHEADER);
  riff.wave.format.FormatTag:=1;
  riff.wave.format.Channels:=1;
  riff.wave.format.SamplesPerSec:=Trunc(SAMPLE_RATE);
  riff.wave.format.AvgBytesPerSec:=Trunc(SAMPLE_RATE)*2;
  riff.wave.format.BlockAlign:=BITS div 8;
  riff.wave.format.BitsPerSample:=BITS;
  riff.wave.DataHead:='data';
  riff.wave.DataSize:=wave_size;
  Pointer(cursound):=Addr(riff.wave.data);
  for i:=0 to chunks_count-1 do begin
    Move(chunks[i][0], cursound^, Length(chunks[i])*sizeof(short));
    Inc(cursound, Length(chunks[i]));
  end;
end;

function CreateWave(const chunks: TWaveChunks): TWaveBlock;
begin
  Result:=CreateWave(@chunks[0], Length(chunks));
end;

function CreateWave(const chunks: array of TWaveChunk): TWaveBlock;
begin
  Result:=CreateWave(@chunks[0], Length(chunks));
end;


end.