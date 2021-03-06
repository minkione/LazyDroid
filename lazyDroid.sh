#!/bin/bash
# lazzyDroid
# 2017 By Dani Martinez (@dan1t0) / NCCGroup

VERSION="0.4"

#######################
#     CHANGE THIS     #
#######################
APKTOOL="apktool"
JARSIGNER="jarsigner"
ADB="adb"
AAPT="aapt"

KEYSTORE="keystore.key"
KEYALIAS="danito"

MYSHELL="gnome-terminal"
#######################


RED='\033[0;31m'
NC='\033[0m'
YEL='\033[0;33m'
GREEN='\033[0;32m'



function checkfile {
    if [ ! -f "${1}" ]
    then
        echo "${1} not found!. Press Enter to continue"
        read kk
        menu
    fi
}



function sign {
    APK_FULL_PATH=$1

    APK=$(basename $APK_FULL_PATH)
    APK_PATH=$(dirname $APK_FULL_PATH)
    APK_DIR=$(sed 's/.apk//' <<< $APK)
    NEW_APK=${APK_PATH}/${APK_DIR}_signed.apk

    echo "---> Signing ${APK}..."
    cp ${APK_FULL_PATH} ${NEW_APK}
    $JARSIGNER -verbose -sigalg SHA1withRSA -digestalg SHA1 -keystore $KEYSTORE ${NEW_APK} $KEYALIAS > /dev/null
    if [ $? -eq "0" ]
    then
        echo "---> ${NEW_APK} Created and signed sucessfully"
        echo ""
        install ${NEW_APK}
    else
        echo "---> Something was wrong trying to sign the app. Press Enter to continue"
        rm ${NEW_APK}
        read kk
        menu
    fi
}



function sign2 {
    echo -n "- Enter apk: "
    read APK_FULL_PATH
    checkfile "${APK_FULL_PATH}"
    sign "${APK_FULL_PATH}"
}



function install {
    echo -n "Do you want to install $(basename ${1})? [y/n] "
    read kk
    case "$kk" in
    [yY])
        echo ""
        ${ADB} install -r ${1}
        echo ""
        echo -n "Press Enter to continue..."
        read kk
        ;;
    *)
        :
esac
}



function build {
    if [ ! -d "${1}" ]; then
        echo "${1} not found!"
        read kk
        menu
    fi
    echo -n "---> Building apk: ${2} ... "
    ${APKTOOL} b $1 -o $2 > /dev/null
    if [ $? -eq "0" ]
    then
        echo " DONE"
        echo -n "Do you want to delete the folder ${1}? [y/n] "
        read kk
        case "$kk" in
        [yY])
            rm -r ${1}
            echo -n "Deleted! Press Enter to continue... "
            read kk
            ;;
        *)
            :
    esac
    else
        echo "---> Something was wrong trying to build the apk. Press Enter to continue"
        read kk
        menu
    fi
}



function build2 {
    echo -n "- Enter app folder to build: "
    read PATH_build
    build "${PATH_build}" "${PATH_build}.apk"
}



function set_something {
    value=$1
    echo -n "- Enter apk: "
    read APK_FULL_PATH
    checkfile "$APK_FULL_PATH"

    APK=$(basename $APK_FULL_PATH)
    APK_PATH=$(dirname $APK_FULL_PATH)
    APK_DIR=$(sed 's/.apk//' <<< $APK)
    NEW_APK=${APK_PATH}/${APK_DIR}_signed.apk

    echo "- Unpacking $APK_FULL_PATH ... "
    $APKTOOL d $APK_FULL_PATH -o ${APK_DIR} > /dev/null
    if [ $? -eq "0" ]
    then
        echo "---> DONE"
        echo ""
    else
        echo "---> Something was wrong trying to change the ${value} value. Press Enter to continue"
        read kk
        menu
    fi

    cd ${APK_DIR}

    echo "- Checking ${value} flag ..."
    grep "${value}=\"true\"" AndroidManifest.xml > /dev/null
    if [ $? -eq "0" ]
    then
        echo "---> The ${value} value is set to true. Nothing to do here"
        cd ..
        rm -rf ${APK_DIR}
    else

        grep "${value}=\"false\"" AndroidManifest.xml > /dev/null
        if [ $? -eq "0" ]
        then
            echo "---> ${value}=\"false\" Found"
            echo "---> Changing value to true"

            if [ "${value}" == "debuggable" ]
            then
                sed -i 's/debuggable="false"/debuggable="true"/g' AndroidManifest.xml
            else
                sed -i 's/allowBackup="false"/allowBackup="true"/g' AndroidManifest.xml
            fi

            if [ $? -eq "0" ]
            then
                echo "---> Flag ${value}=true was changed successfully"
                cd ..
                build "${APK_DIR}" "${APK_PATH}/${APK_DIR}_${value}.apk"
            else
                echo "---> Something was wrong trying to change the ${value} value. Press Enter to continue"
                read kk
                menu
            fi
        else
            echo "---> The ${value} flag was not found"
            if [ "${value}" == "debuggable" ]
            then
                sed -i 's/<application/<application android:debuggable="true"/g' AndroidManifest.xml
            else
                sed -i 's/<application/<application android:allowBackup="true"/g' AndroidManifest.xml
            fi

            if [ $? -eq "0" ]
                then
                    echo "---> Flag ${value}=true was added successfully"
                    cd ..
                    build "${APK_DIR}" "${APK_PATH}/${APK_DIR}_${value}.apk"
                else
                    echo "---> Something was wrong trying to add the flag ${value}. Press Enter to continue"
                    read kk
                    menu
                fi
        fi
    fi
    echo ""

}



function smartLog {
    echo -n "Execute the app and enter the name: "
    read packageName
    ${ADB} shell "ps | grep $packageName" > /tmp/pids
    PIDS="$(wc -l /tmp/pids | cut -d" " -f1)"
    DATE=$(date +"%Y%m%d%H%M%S")
    FOLDER=$PWD

    if [ $PIDS = "0" ]
    then
        echo "Package not found"
        read kk
    else
        if [ "$PIDS" -gt "0" ]
        then
            if [ "${PIDS}" -gt "1" ]
            then
                echo ""
                echo " PID     Package Name"
                cat /tmp/pids | awk '{print $2 "   " $9}'
                echo
                echo -n "Enter the PID: "
                read PIDD_

                grep " ${PIDD_} " /tmp/pids > /dev/null
                if [ $? -eq "1" ]
                then
                    rm /tmp/pids
                    echo "PID not found"
                    read kk
                else
                    echo ""
                    echo " PID     Package Name"
                    cat /tmp/pids | grep ${PIDD_}| awk '{print $2 "   " $9}'
                    echo
                    packageName=$(cat /tmp/pids | grep ${PIDD_} | awk '{print $9}'| tr -d '\r')
                    rm /tmp/pids
                    echo  "Log stored on '${FOLDER}/${packageName}_${DATE}.log'"
                    echo -n "Press Enter to continue... "
                    read kk
                    ${MYSHELL} -e "${ADB} logcat | grep ${PIDD_} | tee -a "${FOLDER}/${packageName}_${DATE}.log"" &
                fi
            else
                PIDD_="$(cat /tmp/pids | awk '{print $2}')"
                packageName=$(cat /tmp/pids | grep ${PIDD_} | awk '{print $9}'| tr -d '\r')
                rm /tmp/pids
                echo "Log stored on '${FOLDER}/${packageName}_${DATE}.log'"
                echo -n "Press Enter to continue... "
                read kk
                ${MYSHELL} -e "${ADB} logcat | grep ${PIDD_} | tee -a "${FOLDER}/${packageName}_${DATE}.log"" &
            fi

        fi
    fi
}



function extractApp {
    INIT_APPS=/tmp/init_apps
    END_APPS=/tmp/end_apps

    echo "---> Extracting the installed apps... "
    ${ADB} shell pm list packages | cut -d: -f2- > ${INIT_APPS}
    napp=$(wc -l ${INIT_APPS} | cut -d" " -f1)
    echo "---> $napp Apps installed"

    echo -n "---> Install the app from Market and press enter... "
    read kk

    echo "---> Extracting the new app installed ... "
    ${ADB} shell pm list packages | cut -d: -f2- > ${END_APPS}

    newapp=$(grep -v -F -x -f ${INIT_APPS} ${END_APPS} | tr -d '\r' )
    if [ -z "$newapp" ]; then
        echo "---> New App is not detected"
        rm -f ${END_APPS}
        exit
    fi
    echo "---> DONE"
    echo "---> The new app is ${newapp}"
    pathAPK=$(${ADB} shell pm path ${newapp} | cut -d : -f2- | tr -d '\r')
    echo " --> The apk is stored in ${pathAPK}"

    rm -f ${END_APPS}
    rm -f ${INIT_APPS}
    echo -n "Do you want to download the apk? [y/n] "
    read kk
    case "$kk" in
    [yY])
        ${ADB} shell su -c "cp ${pathAPK} /sdcard/${newapp}.apk"
        ${ADB} pull /sdcard/${newapp}.apk . > /dev/null

        checkfile ${newapp}.apk
        echo "---> ${newapp}.apk Downloaded sucessfully. Press Enter to Continue..."
        read kk
        ;;
    *)
        :
    esac
}



function getSnapshot {
    APPS=/tmp/apps

    echo ""
    echo "What do you want to download?"
    echo " 1) Application data folder (/data/data/..)"
    echo " 2) /sdcard/"
    echo " 3) Other mobile folder"
    echo -n "Select an option: "
    read opt
    echo ""

    case "$opt" in
    1)
        echo "---> Extracting the installed apps... "
        ${ADB} shell pm list packages | cut -d: -f2- > ${APPS}
        napp=$(wc -l ${APPS} | cut -d" " -f1)
        echo "---> $napp Apps installed"
        echo ""
        echo -n "Enter the App name (Press Enter to list all): "
        read apk_name
        if [ $(echo ${apk_name} | wc -c ) -eq "1" ]
        then
            cat ${APPS}
        else
            grep ${apk_name} ${APPS} > /dev/null
            if [ $? -eq "0" ]
            then
                echo ""
                echo "Apps found:"
                cat ${APPS} | grep ${apk_name}
                echo
            else
                echo "App not found"
                exit 1
            fi
        fi

        echo ""
        echo -n "Select the Package to get the snapshot: "
        read app
        grep -w ${app} ${APPS} > /dev/null
        if [ $? -eq "1" ]
        then
            rm ${APPS}
            echo "Package not found. Press Enter to continue..."
            read kk
            menu
        else
            echo "Downloading App ..."
            ${ADB} shell su -c "cp -r /data/data/${app} /sdcard/" > /dev/null
            ${ADB} pull "/sdcard/${app}" . > /dev/null
            ${ADB} shell "rm -rf /sdcard/${app}"
            DATE=$(date +"%Y%m%d%H%M%S")
            mv ${app} ${app}_${DATE}

            if [ $? -eq "0" ]
            then
                echo "App data downloaded sucessfully"
                echo "Folder ${app}_${DATE} created sucessfully."
                echo -n "Press Enter to continue... "

            else
                echo "---> Something was wrong. Press Enter to continue"
                read kk
                menu
            fi
        fi
        rm ${APPS}
        ;;
    2)
        echo ""
        echo "Downloading /sdcard/ ..."
        ${ADB} pull "/sdcard/" . > /dev/null
        DATE=$(date +"%Y%m%d%H%M%S")
        mv sdcard sdcard_${DATE}
        if [ $? -eq "0" ]
        then
            echo "---> /sdcard/ folder download sucessfully"
            echo "---> Folder sdcard_${DATE} created sucessfully."
            echo ""
            echo -n "Press Enter to continue... "
        else
            echo "---> Something was wrong. Press Enter to continue"
            read kk
            menu
        fi
        ;;
    3)
        echo ""
        echo -n "Enter the folder to download: "
        read folder
        DATE=$(date +"%Y%m%d%H%M%S")
        ${ADB} pull "${folder}" . > /tmp/log_${DATE}
        grep "does not exist" /tmp/log_${DATE} > /dev/null

        if [ $? ]
        then
            echo -n "Error: $(cat /tmp/log_${DATE} | sed 's/${ADB}: //' | sed 's/error: //')"
            echo -n " . Press Enter to Continue..."
            read kk
            menu
        else
            echo "---> ${folder} download sucessfully"
            mv ${folder} ${folder}_${DATE}
            echo "---> Folder ${folder}_${DATE} created sucessfully."
            echo ""
            echo -n "Press Enter to continue... "
        fi
        rm /tmp/log_${DATE}
        ;;
    *)
        echo -n "$option Invalid option, press Enter to continue... ";
        read foo
        exit 1
        ;;
    esac
    read kk
}



function compare {
    COUNTER=0
    NFILES=0
    MFILES=0
    NFOLDER=0
    DFILES=0

    echo -n "[0] First folder to compare: "
    read firstf
    if [ ! -d "${firstf}" ]; then
        echo -n "${firstf} Folder not found. Press Enter to continue..."
        read kk
        menu
    fi
    echo -n "[1] Second folder to compare: "
    read secondf
    if [ ! -d "${secondf}" ]; then
        echo -n "${secondf} Folder not found. Press Enter to continue..."
        read kk
        menu
    fi

    diff --brief -Nr ${firstf} ${secondf} > /tmp/different
    echo ""
    echo "- Modified Files -"

    cat /tmp/different | grep "Files" | grep "differ" | awk '{print $2 " " $4}' > /tmp/diff_files
    while read line; do
        COUNTER=$((COUNTER+1))

        file1=$(echo "$line" | cut -d" " -f1)
        file2=$(echo "$line" | cut -d" " -f2)
        if [[ -f "${file1}" && -f "${file2}" ]]
        then
            MFILES=$((MFILES+1))
            lines_f1=$(wc -l ${file1} | cut -d" " -f1)
            lines_f2=$(wc -l ${file2} | cut -d" " -f1)
            if [ ${lines_f1} -eq "0" ]; then
                lines_f1=1
            fi
            if [ ${lines_f2} -eq "0" ]; then
                lines_f2=1
            fi

            size_f1=$(ls -lh ${file1} | awk '{print $5}')
            size_f2=$(ls -lh ${file2} | awk '{print $5}')

            echo -e " ${COUNTER} ${YEL}modified!${NC}"
            echo "[0] ${file1} (${lines_f1} lines) (size ${size_f1})"
            echo "[1] ${file2} (${lines_f2} lines) (size ${size_f2})"
            echo "[x] File Type:$(file ${file1} | cut -d" " -f2,3,4,5,6,7,8,9,10,11,12)"
            echo ""
        else
            if [ -f "${file1}" ]
            then
                DFILES=$((DFILES+1))
                lines_f1=$(wc -l ${file1} | cut -d" " -f1)
                size_f1=$(ls -lh ${file1} | awk '{print $5}')
                if [ ${lines_f1} -eq "0" ]; then
                    lines_f1=1
                fi

                echo -e " ${COUNTER} ${RED}deleted!${NC}"
                echo "[0] ${file1} (${lines_f1} lines) (size ${size_f1})"
                echo "[x] File Type:$(file ${file1} | cut -d" " -f2,3,4,5,6,7,8,9,10,11,12)"
                echo ""
            else
                if [ -f "${file2}" ]
                then
                    NFILES=$((NFILES+1))
                    lines_f2=$(wc -l ${file2} | cut -d" " -f1)
                    size_f2=$(ls -lh ${file2} | awk '{print $5}')
                    if [ ${lines_f2} -eq "0" ]; then
                        lines_f2=1
                    fi

                    echo -e " ${COUNTER} ${GREEN}created!${NC}"
                    echo "[1] ${file2} (${lines_f2} lines) (size ${size_f2})"
                    echo "[x] File Type:$(file ${file2} | cut -d" " -f2,3,4,5,6,7,8,9,10,11,12)"
                    echo ""
                fi
            fi
        fi
    done < /tmp/diff_files
    echo ""

    diff --brief -r ${firstf} ${secondf} > /tmp/different
    cat /tmp/different| grep Only | awk '{gsub(/: /,""); print $3$4}' > /tmp/tocheck
    echo "- Sumary -"
    echo "Created files: ${NFILES}"
    echo "Deleted files: ${DFILES}"
    echo "Modified files ${MFILES}"
    echo "Total Changes: ${COUNTER}"
    echo ""
    echo ""
    echo "- Created Folders -"
    while read line; do
        file "$line" | grep ": directory" | cut -d":" -f1
    done < /tmp/tocheck
    echo ""
    rm /tmp/different
    rm /tmp/tocheck
    rm /tmp/diff_files

    echo -n "Press Enter to continue..."
    read kk
}



function frida_lib {
    A=`dirname $(realpath $0)`
    if [ ! -d "${A}/frida_libs" ]; then
        echo "frida_libs Folder not found. Please execute getfridalibs.sh and come back"
        echo -n "Press Enter to continue..."
        read kk
        menu
    fi

    echo ""
    echo "What architecture is your device?"
    echo " 1) arm64"
    echo " 2) arm64-v8a"
    echo " 3) armeabi"
    echo " 4) armeabi-v7a"
    echo " 5) x86_64"
    echo " 6) x86"
    echo " 7) Try to detect it via ADB"
    echo ""
    echo -n "Select an option: "
    read opt
    echo ""

    OPT1="arm64"
    OPT2="arm64-v8a"
    OPT3="armeabi"
    OPT4="armeabi-v7a"
    OPT5="x86_64"
    OPT6="x86"

    case $opt in
        1)
            arch=$OPT1
            ;;
        2)
            arch=$OPT2
            ;;
        3)
            arch=$OPT3
            ;;
        4)
            arch=$OPT4
            ;;
        5)
            arch=$OPT5
            ;;
        6)
            arch=$OPT6
            ;;
        7)
            echo -n "Trying to extract the info from ADB... "
            arch=$(${ADB} shell "getprop ro.product.cpu.abi" | tr -d '\r')
            brand=$(${ADB} shell "getprop ro.product.brand" | tr -d '\r')
            model=$(${ADB} shell "getprop ro.product.model" | tr -d '\r')
            echo "${brand} ${model} ${arch}"
            echo
            ;;
        *)
            echo -n "Invalid option, press Enter to continue... "
            read foo
            menu
            ;;
    esac

    echo -n "Architecture: ${arch}. Is it correct? [y/n] "
    read kk
    case "$kk" in
    [yY])
        echo -n "Select the APK to inject the frida gadget: "
        read APK
        checkfile "${APK}"

        package=$(aapt dump badging ${APK} |grep "^package: name=" |cut -f 2 -d "'")
        if [ -z "$package" ]; then
        	echo "---> ERROR: Can't get package name from APK"
            menu
        fi
        echo ""
        echo "---> Package: ${package}"

        launchable_activity=$(aapt dump badging ${APK}  |grep "^launchable-activity: name=" |cut -f 2 -d "'")
        if [ -z "$launchable_activity" ]; then
        	echo "---> ERROR: Can't get main activity"
            menu
        fi
        echo "---> Launchable-activity: $launchable_activity"

        echo -n "---> Unpacking ${APK}... "
        APK_DIR=$(sed 's/.apk//' <<< $APK)
        ${APKTOOL} d -f ${APK} -o ${APK_DIR}> /dev/null
        echo " DONE"


        aapt dump permissions ${APK} |grep "'android.permission.INTERNET'" >/dev/null
        if [ $? != 0 ]; then
        	echo "---> Injecting android.permission.INTERNET"
        	awk '/<manifest / { print; print "<uses-permission android:name=\"android.permission.INTERNET\"/>"; next }1' ${APK_DIR}/AndroidManifest.xml > ${APK_DIR}/AndroidManifest.xml.1
        	mv ${APK_DIR}/AndroidManifest.xml.1 ${APK_DIR}/AndroidManifest.xml
        else
        	echo "---> Already has INTERNET permission"
        fi

        activity_path=$(echo ${launchable_activity} |sed -e "s:\.:/:g")
        file_to_patch="${APK_DIR}/smali/${activity_path}.smali"

        if [ ! -f "${file_to_patch}" ]; then
        	echo "---> ERROR: Can't find file ${file_to_patch}"
        	menu
        fi

        echo "---> Patching ${file_to_patch}"

        line=$(cat ${file_to_patch} |grep -n "^# .*methods$" |head -n 1 |cut -f 1 -d ":")
        if [ -z "$line" ]; then
        	echo "ERROR: Can't find line to patch"
        	exit 1
        fi


        head -n ${line} ${file_to_patch} > ${file_to_patch}.1
        cat >> ${file_to_patch}.1 <<-EOF
        .method static constructor <clinit>()V
            .locals 1

            .prologue
            const-string v0, "frida-gadget"

            invoke-static {v0}, Ljava/lang/System;->loadLibrary(Ljava/lang/String;)V

            return-void
        .end method
EOF

        lines=$(cat ${file_to_patch} |wc -l)
        count=$(( $lines - $line ))
        tail -n ${count} ${file_to_patch} >> ${file_to_patch}.1
        mv ${file_to_patch}.1 ${file_to_patch}

        echo -n "---> Injecting the shared libraries..."
        cp -r frida_libs/${arch} ${APK_DIR}/lib/
        echo " DONE"
        echo ""

        build "${APK_DIR}" "${APK_DIR}_frida.apk"

        if [ ! -f "${APK_DIR}_frida.apk" ]; then
        	echo "---> ERROR: failed to rebuild the patched APK"
        	menu
        fi
        echo "---> Patched APK: ${APK_DIR}_frida.apk"

        sign "${APK_DIR}_frida.apk"

        echo ""
        echo "---> Now execute the APK and run 'frida -U Gadget' or ..."
        echo -n "Do you want to launch the app and the frida agent? [y/n] "
        read resp

        case "$resp" in
        [yY])
            adb shell "am start -n ${package}/${launchable_activity}"
            sleep 2
            ${MYSHELL} -e "frida -U Gadget" &
            echo ""
            ;;
        *)
            :
        esac

        echo -n "---> Press enter to continue "
        read kk

        clear
        menu
        ;;
    *)
        :
    esac
    clear
    menu
}



function menu {
    echo "LazyDroid ${VERSION} by Dani Martinez @dan1t0 - NCC Group"
    echo ""
    echo ""
    echo "Select an option: "
    echo " 1) Set apk to debuggable=true"
    echo " 2) Set apk to allowBackup=true"
    echo " 3) Sign apk"
    echo " 4) Build apk"
    echo " 5) Extract app log from Android device"
    echo " 6) Extract apk file to an installed application from Market"
    echo " 7) Download installed application data snapshot, /sdcard/ or mobile folder"
    echo " 8) Compare two different snapshots"
    echo " 9) Insert Frida gadget in the APK"
    echo ""
    echo " 0) Exit"
    echo
    echo -n "Select one option [1 - 9] "
    read option
    echo
    case $option in
        1) echo "Option 1 selected:";
            set_something "debuggable";;
        2) echo "Option 2 selected:";
            set_something "allowBackup";;
        3) echo "Option 3 selected";
            sign2;;
        4) echo "Option 4 selected";
            build2;;
        5) echo "Option 5 selected";
            smartLog;;
        6) echo "Option 6 selected";
            extractApp;;
        7) echo "Option 7 selected";
            getSnapshot;;
        8) echo "Option 8 selected";
            compare;;
        9) echo "Option 9 selected";
            frida_lib;;
        0) echo "See you soon";
            exit 1;;
        *) echo -n "Invalid option, press Enter to continue... ";
            read foo;;
    esac
}



while :
do
    clear
    menu
done
