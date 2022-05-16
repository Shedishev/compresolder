@echo off
rem 1.) robocopy переносит файлы старше определенной даты из указанной директории с параметром мультипоточности,
rem 2.) 7z архивирует папку с перенесенными файлами,
rem 3.) добавляет MD5 хэш архива к логам robocopy.
1>nul chcp 65001
rem Сверяем часы
for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
set "YY=%dt:~2,2%" & set "YYYY=%dt:~0,4%" & set "MM=%dt:~4,2%" & set "DD=%dt:~6,2%"
set "HH=%dt:~8,2%" & set "Min=%dt:~10,2%" & set "Sec=%dt:~12,2%"
set "timeStamp=%YYYY%-%MM%-%DD%_%HH%-%Min%"
set "timeStampLess=%YYYY%-%MM%-%DD%"
rem Смотрим установлен ли архиватор
set zip="%ProgramFiles%\7-Zip\7z.exe"
if not exist %zip% (
  echo 7-Zip не установлен по пути: %zip%
  GOTO End
  )
rem Дата 
set /p OlderThan=" Напишите дату в формате ГГГГММДД (напр. %YYYY%%MM%%DD%)? "
rem Цель
set FROM=%~dp0
rem Временная папка
set TO=%~dp0TempARH
set OUTPUT=%timeStamp%-output.log
rem При запуске скрипта есть выбор, автоматически через 10 секунд запустится архивация.
echo  #*******************************#
echo  * Архивирование и удаление
echo  * файлов и папок
echo  * старше %OlderThan%
echo  * в директории
echo  * %FROM%
echo  * начнется через 10 секунд
echo  *-------------------------------*
echo  * Запуск - нажми 1              *
echo  * Отмена - нажми 2              *
echo  #*******************************#
Choice /c 12 /t 10 /d 1
rem Переменные ErrorLevel определяют выбор пользователя или по истечению 10 секунд запускается процесс.
If Errorlevel 2 Goto :Cancel
If Errorlevel 1 Goto :Start
Goto End
:Start
::mode 50,3
color 0e
echo               %timeStamp%
echo   Процесс займёт некоторое время. Ожидайте...
rem переносим файлы во временную директорию.
echo Перемещаем файлы.
ROBOCOPY %FROM% %TO% /MT /MOVE /S /COPYALL /DCOPY:DAT /MINAGE:%OlderThan% /log+:%OUTPUT%
rem MT - multithread; S - subdirectories; COPYALL - File attrib; /DCOPY - data,attrib,timestamps
echo Завершили перемещение файлов.
rem Сжимаем файлы в архив с параметрами максимальной компрессии. Может сильно нагрузить CPU.
echo Сжимаем перемещенные файлы. (В новом окне)
set ARH=%~dp0%timeStamp%-ARH.7z
START "Compressing Backup. DO NOT CLOSE" /low /W /B %zip% a -mx=9 -mfb=273 -ms=on -r %ARH% %TO%\
rem 7z switch definitions https://superuser.com/questions/281573/what-are-the-best-options-to-use-when-compressing-files-using-7-zip/1449735
rem Добавляем хэш-файл
set "MD5="
For /f "skip=1 Delims=" %%# in (
  'certutil -hashfile "%ARH%" MD5'
) Do If not defined MD5 set MD5=%%#
set MD5=%MD5: =%
echo MD5 hash of %ARH% is %MD5% >> %OUTPUT%
echo Прибираемся...
IF EXIST "%TO%" RMDIR /s /q "%TO%"
Echo  #*******************************#
Echo  *          Готово...            *
Echo  *-------------------------------*
Echo  * Архив - %ARH%
Echo  * Лог - %OUTPUT%
Echo  #*******************************#
:Cancel
echo Отмена.
goto End
:End
1>nul chcp 866
echo Finished.
color 0a
ENDLOCAL
