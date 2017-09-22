#!/bin/bash

DIR="external_sd"
CMD="adb"

function myEcho {
    echo "> $1"
}

function rebootDevice {
    ${CMD} reboot $1
}

function isDeviceAvailable {
    if [ `${CMD} devices | grep -w "device" | wc -l` -eq 1 ]; then
        return 0
    fi
    return 1
}

function waitForDevice {
    LOOP=$1
    if [ -z $1 ]; then LOOP=15; fi
    COUNTER=0
    while [ `${CMD} devices | grep -w "recovery" | wc -l` -eq 0 ]; do
        let COUNTER+=1
        if [ ${COUNTER} -eq ${LOOP} ]; then
            return 1
        fi
        sleep 1
    done
    return 0
}


if isDeviceAvailable; then
    myEcho "Restartuji zarizeni..."
    rebootDevice recovery
    waitForDevice 15
    if [ $? -ne 0 ]; then
        myEcho "Zarizeni nebylo nalezeno"
        exit 1
    fi
    myEcho "Cekam na pripravu zarizeni"
    sleep 10
else
    waitForDevice 1
    if [ $? -ne 0 ]; then
        myEcho "Zarizeni nebylo nalezeno"
        exit 1
    fi
fi

myEcho "Zarizeni je pripraveno"

myEcho "Hledam soubory k instalaci..."

FILES=0
ROM=`${CMD} shell find ${DIR} -iname *xiaomi*.zip -type f`
SUPERSU=`${CMD} shell find ${DIR} -iname *supersu*.zip -type f`

if [ "${ROM}" != "" ]; then
    FILES+=1
    myEcho "Instalace ROM: ${ROM}"
    ${CMD} shell twrp install ${ROM}
fi

if [ "${SUPERSU}" != "" ]; then
    FILES+=1
    myEcho "Instalace SuperSU: ${SUPERSU}"
    ${CMD} shell twrp install ${SUPERSU}
fi

if [ ${FILES} -eq 0 ]; then
    myEcho "Zadne soubory nebyly nalezeny"
    read -n 1 -p "Restartovat zarizeni? (a/n)": r;
    if [ "${r}" = "a" ]; then
        rebootDevice
    fi
    exit 0
fi

myEcho "Mazani cache"
${CMD} shell twrp wipe cache
${CMD} shell twrp wipe dalvik

myEcho "Restart zarizeni"
sleep 1
rebootDevice

sleep 2
exit 0
