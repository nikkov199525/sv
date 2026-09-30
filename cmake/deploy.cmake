# deploy.cmake -- данные рядом с программой.
#
#   cmake -DSRC=<runtime> -DPLATFORM=windows|linux -DDST=<папка пакета>
#         -P cmake/deploy.cmake
#
# В пакет идёт runtime/ целиком (с подкаталогами), кроме runtime/windows и
# runtime/linux, и сверху -- runtime/<PLATFORM>: там SV.DCL и помощники
# распаковки архивов и fb2 для этой ОС.
#
# SV.CFG, SV.INI и SV.DCL -- настройки, которые пользователь правит под
# себя: если они уже лежат в папке пакета, их не трогаем. Остальное
# (справка, помощники) обновляется всегда.

function(deploy_tree from)
    file(GLOB_RECURSE files RELATIVE "${from}" "${from}/*")
    foreach(name ${files})
        if(name MATCHES "^(windows|linux)/")
            continue()
        endif()
        if(name MATCHES "^SV\\.(CFG|INI|DCL)$" AND EXISTS "${DST}/${name}")
            continue()
        endif()
        get_filename_component(dir "${DST}/${name}" DIRECTORY)
        file(MAKE_DIRECTORY "${dir}")
        file(COPY_FILE "${from}/${name}" "${DST}/${name}" ONLY_IF_DIFFERENT)
        if(name MATCHES "\\.sh$")
            file(CHMOD "${DST}/${name}" PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE
                 GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)
        endif()
    endforeach()
endfunction()

file(MAKE_DIRECTORY "${DST}")
deploy_tree("${SRC}")
deploy_tree("${SRC}/${PLATFORM}")
