unit sdrvxpapi;
// $Id: sdrvxpapi.pas 22f944c04cc6 2014/06/08 09:40:45 serg $
Interface
uses Windows;

const
  REG_SDRVX_NODE = 'SDRV for Windows';
  REGSTR_SOFTWARE = 'Software\';
  REGSTR_SDRV = REGSTR_SOFTWARE + REG_SDRVX_NODE;
  REGSTR_SDRVXP_API_LIBRARY_KEY = 'sdrvxpapi.dll';
  SDRVXP_API_INVOKE_NAME = 'Invoke';

type
  PVDXD_APC_QUERY = ^VDXD_APC_QUERY;
  VDXD_APC_QUERY = record
    FUNC: DWORD;
    DONE: DWORD;
    VM: DWORD;
    LEN: DWORD;
    DATA: char;
  end;

  lpVDXD_APC_QUERY_TTS = ^VDXD_APC_QUERY_TTS;
  VDXD_APC_QUERY_TTS = packed record
    FUNC: DWORD;
    DONE: DWORD;
    VM: DWORD;
    LEN: DWORD;
    Dictor: WORD;
    Tempo: WORD;
    Volume: WORD;
    Reserved0: WORD;
    Reserved1: DWORD;
    Reserved2: DWORD;
    ALen: WORD;
    Reserved3: Array[0..7] of Char;
    AText: record end;
  end;

  TSDRVXPApiInvoke = procedure (pQuery: PVDXD_APC_QUERY); stdcall;

const
  APC_QUERY_DllInit     = $80000000;
  APC_QUERY_DllDone     = $80000001;
  
  APC_QUERY_BeginPlay   = $00000001;
  APC_QUERY_PlayBlock   = $00000002;
  APC_QUERY_IsPlaying   = $00000003;
  APC_QUERY_StopPlay    = $00000004;
  APC_QUERY_RestartPlay = $00000005;
  APC_QUERY_REG_INFO    = $00000006;
  APC_QUERY_EndPlay     = $00000007;
  APC_QUERY_AbortTick   = $00000008;

Implementation

end.
