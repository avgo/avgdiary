#!/bin/bash

function PrintUsage() {
	AppName=`basename $0`
	
	echo "ДЕЛАЙ ТАК:"
	echo "    ${AppName} --add         Добавить запись в дневник. Или завести новый."
	echo "    ${AppName} --addbook     Добавить запись в дневник (приобрести книгу). Или завести новый."
	echo "    ${AppName} --addref      Добавить ссылку в дневник. Или завести новый."
	echo "    ${AppName} --addrep      Добавить запись-отчёт в дневник. Или завести новый."
	echo "    ${AppName} --addtask     Добавить задачу в дневник. Или завести новый."
	echo "    ${AppName} --edit        Редактировать сегодняшнюю запись."
	echo "    ${AppName} --help        Вывести справку."
	echo "    ${AppName} --filename    Вывести имя текущего файла."
	echo "    ${AppName} --view-all    Читать весь дневник."
}

if [ $# -ne 1 ]; then
	PrintUsage
	exit 1
fi

Action=$1
ConfFile=~/.avgdiary/avgdiary.conf

test -f "${ConfFile}" && . ${ConfFile}

if test -z "${avg_diary_dir}"; then
	echo "Нужно установить переменную \${avg_diary_dir} следующим образом."
	echo "export avg_diary_dir=<dir>"
	exit 1
fi

if ! test -d "${avg_diary_dir}"; then
	echo "Не получается найти каталог с дневником \"${avg_diary_dir}\"."
	echo "Установите переменную \${avg_diary_dir} к существующему каталогу."
	echo "export avg_diary_dir=<dir>"
	exit 1
fi

# DirName1=`dirname`
# 
# if test "${DirName1}" == "."; then
# 	Path1=`pwd`
# else
# 	Path1="${DirName1}"
# fi

date1=`date +"%Y_%m_%d"`

file_new="${avg_diary_dir}/day_$date1"

function FileAddEntry()
{
	case "${1}" in
	book)           RepStr="КНИГА:    " ;;
	rep)            RepStr="[ОТЧЁТ]    " ;;
	ref)            RepStr="ПОСМОТРЕТЬ:    " ;;
	task)           RepStr="ЗАДАЧА:    " ;;
	esac
	
	if [ -f "$file_new" ]; then

cat >> $file_new << _ACEOF
`date +"%H:%M"`    ${RepStr}

_ACEOF

	else

cat > $file_new << _ACEOF
`date +"%d.%m.%Y, %a"`

`date +"%H:%M"`    ${RepStr}

_ACEOF

	fi
	
	eval "vim ${vim_options} -c 'normal GkA' '${file_new}'"
}

function FileEditEntry() {
	if ! [ -f $file_new ]; then
		echo "Сегодняшний дневник ещё не создан."
		echo "ДЕЛАЙ ТАК:"
		echo "    ${AppName} --add         Добавить запись в дневник."
		exit 1
	fi
	
	eval "vim ${vim_options} $file_new"
}

function PrintFilename() {
	echo "${file_new}"
}

function ViewAll() {
	cat "${avg_diary_dir}"/day_* | less
}

vim_options="-c 'set expandtab'"

case $Action in
--add)         FileAddEntry ;;
--addbook)     FileAddEntry book;;
--addref)      FileAddEntry ref;;
--addrep)      FileAddEntry rep;;
--addtask)     FileAddEntry task;;
--edit)        FileEditEntry ;;
--filename)    PrintFilename ;;
--help)        PrintUsage ;;
--view-all)    ViewAll ;;
*)
	echo Неизвестное действие ${Action}
	PrintUsage
	exit 1
esac