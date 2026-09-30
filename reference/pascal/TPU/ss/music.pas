unit Music;

interface
uses Windows;

function PlayMusicA(m: PChar; flags: Cardinal): BOOL; stdcall; external 'music.dll';

implementation

end.
