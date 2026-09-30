/* miniaudio_impl.c -- реализация miniaudio (vendor/miniaudio/miniaudio.h).
 *
 * Отдельный файл на C: заголовок большой, и собирать его реализацию
 * вместе с кодом программы (в 866, с -funsigned-char и прочим) незачем.
 * Нужен только вывод звука, остальное выключено. */

#define MA_NO_DECODING
#define MA_NO_ENCODING
#define MA_NO_WAV
#define MA_NO_FLAC
#define MA_NO_MP3
#define MA_NO_GENERATION
#define MA_NO_RESOURCE_MANAGER
#define MA_NO_NODE_GRAPH
#define MA_NO_ENGINE
#define MA_ENABLE_ONLY_SPECIFIC_BACKENDS
#define MA_ENABLE_WASAPI
#define MA_ENABLE_DSOUND
#define MA_ENABLE_WINMM
#define MA_ENABLE_PULSEAUDIO
#define MA_ENABLE_ALSA
#define MA_ENABLE_JACK
#define MINIAUDIO_IMPLEMENTATION
#include "miniaudio.h"
