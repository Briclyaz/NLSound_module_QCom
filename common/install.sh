MODID="NLSound"

MIRRORDIR="/data/local/tmp/NLSound"

OTHERTMPDIR="/dev/NLSound"

ADDONS="$OTHERTMPDIR/Addons"

ALTADDONS="$MIRRORDIR/AltAddons"

if [ -f /system/system/build.prop ]; then 
	SYSTEM="/system/system"; 
elif [ -f /system_root/system/build.prop ]; then 
	SYSTEM="/system_root/system"; 
elif [ -f /system/build.prop ]; then  
	SYSTEM="/system"; 
fi

if [ $BOOTMODE != true ] && [ -n "$(cat /etc/fstab | grep /vendor)" ]; then 
	FVENDOR=true; 
elif [ $BOOTMODE != true ] && [ -d $SYSTEM/vendor ]; then 
	FVENDOR=false; 
	VENDOR="$SYSTEM/vendor"; 
else 
	VENDOR="/vendor"; 
fi

SBPROP="$SYSTEM/build.prop";
VBPROP="$VENDOR/build.prop";
BPROPCHECKER="$SBPROP $VBPROP"

PROPS="$SYSTEM/default.prop $SYSTEM/build.prop $VENDOR/build.prop /data/local.prop /default.prop /build.prop"

GET_ROUTE_PROP() {
case $1 in
-pm) grep -m1 "^$3=" "$2" | cut -d= -f2 | cut -d ' ' -f1;;
*) grep -m1 "^$2=" "$1" | cut -d= -f2;;
esac
}

GET_PROP() {
for f in $PROPS; do
if [ -e "$f" ]; then
PROP="$(GET_ROUTE_PROP "$f" "$1")"
if [ -n "$PROP" ]; then
break
fi
fi
done
if [ -z "$PROP" ]; then
getprop "$1" | cut -c1-
else
printf "$PROP"
fi
}

ARCH_CHECKER() {
DARCH="$(GET_PROP "ro.product.cpu.abi")"
case "$DARCH" in
*x86_64*) arch="x86_64"; libarch="lib64"; ui_print "Warning, Arch $arch Not Supported!";;
*x86*) arch="x86"; libarch="lib"; ui_print "Warning, Arch $arch Not Supported!";;
*arm64*) arch="arm64"; libarch="lib64";;
*armeabi*) arch="arm"; libarch="lib";;
*) arch="unknown"; ui_print "Warning, $arch Not Supported/Found!";;
esac
AAPT="$AADDONS/aapt-$arch"
XMLSTARLET="$AADDONS/xmlstarlet-$arch"
SQLITE3="$TMPDIR/SQLite3/sqlite3-$arch"
FKEYCHECK="$ADDONS/keycheck-$arch"
TINYMIX="$AADDONS/tinymix-$arch"
}

BOOTMODE_CHECKER() {
	[ -z $BOOTMODE ] && ps | grep zygote | grep -qv grep && BOOTMODE=true
	[ -z $BOOTMODE ] && ps -A 2>/dev/null | grep zygote | grep -qv grep && BOOTMODE=true
	[ -z $BOOTMODE ] && BOOTMODE=false
}

#author - Lord_Of_The_Lost@Telegram
SET_PERM() {
	chown $2:$3 $1 || return 1
	chmod $4 $1 || return 1
	CON=$5
	[ -z $CON ] && CON=u:object_r:system_file:s0
	chcon $CON $1 || return 1
}

#author - Lord_Of_The_Lost@Telegram
SET_PERM_R() {
find $1 -type d 2>/dev/null | while read dir; do
	SET_PERM $dir $2 $3 $4 $6
done
find $1 -type f -o -type l 2>/dev/null | while read file; do
	SET_PERM $file $2 $3 $5 $6
done
}

#author - Lord_Of_The_Lost@Telegram
SET_PERM_RM() {
	SET_PERM_R $MODPATH/$MODID 0 0 0755 0644; [ -d $MODPATH/system/bin ] && chmod -R 777 $MODPATH/system/bin; [ -d $MODPATH/system/xbin ] && chmod -R 777 $MODPATH/system/xbin;
}

#author - Lord_Of_The_Lost@Telegram
MOVERPATH() {
if [ $BOOTMODE != true ] && [ -d $MODPATH/$MODID/system_root/system ]; then
		mkdir -p $MODPATH/$MODID/system; cp -rf $MODPATH/$MODID/system_root/system/* $MODPATH/$MODID/system; rm -rf $MODPATH/$MODID/system_root
	fi
if [ -d $MODPATH/$MODID/vendor ]; then
		mkdir -p $MODPATH$MIPSV; cp -rf $MODPATH/$MODID/vendor/* $MODPATH$MIPSV; rm -rf $MODPATH/$MODID/vendor
	fi
if [ $BOOTMODE != true ] && [ -d $MODPATH/$MODID/system/system ]; then
		mkdir -p $MODPATH/$MODID/system; cp -rf $MODPATH/$MODID/system/system/* $MODPATH/$MODID/system; rm -rf $MODPATH/$MODID/system/system
	fi
if [ $BOOTMODE != true ] && [ -d $MODPATH/$MODID/system_root/system/system_ext ]; then
		mkdir -p $MODPATH/$MODID/system/system_ext; cp -rf $MODPATH/$MODID/system_root/system/system_ext/* $MODPATH/$MODID/system/system_ext; rm -rf $MODPATH/$MODID/system_root
	fi
}

#author - Lord_Of_The_Lost@Telegram
effects_patching() {
case $1 in
	-pre) CONF=pre_processing; XML=preprocess;;
	-post) CONF=output_session_processing; XML=postprocess;;
esac
case $2 in
	*.conf) if [ ! "$(sed -n "/^$CONF {/,/^}/p" $2)" ]; then
	echo -e "\n$CONF {\n    $3 {\n        $4 {\n        }\n    }\n}" >> $2
		elif [ ! "$(sed -n "/^$CONF {/,/^}/ {/$3 {/,/^    }/p}" $2)" ]; then
			sed -i "/^$CONF {/,/^}/ s/$CONF {/$CONF {\n    $3 {\n        $4 {\n        }\n    }/" $2
		elif [ ! "$(sed -n "/^$CONF {/,/^}/ {/$3 {/,/^    }/ {/$4 {/,/}/p}}" $2)" ]; then
			sed -i "/^$CONF {/,/^}/ {/$3 {/,/^    }/ s/$3 {/$3 {\n        $4 {\n        }/}" $2
	fi;;
	*.xml) if [ ! "$(sed -n "/^ *<$XML>/,/^ *<\/$XML>/p" $2)" ]; then     
	sed -i "/<\/audio_effects_conf>/i\    <$XML>\n       <stream type=\"$3\">\n            <apply effect=\"$4\"\/>\n        <\/stream>\n    <\/$XML>" $2
		elif [ ! "$(sed -n "/^ *<$XML>/,/^ *<\/$XML>/ {/<stream type=\"$3\">/,/<\/stream>/p}" $2)" ]; then     
			sed -i "/^ *<$XML>/,/^ *<\/$XML>/ s/    <$XML>/    <$XML>\n        <stream type=\"$3\">\n            <apply effect=\"$4\"\/>\n        <\/stream>/" $2
		elif [ ! "$(sed -n "/^ *<$XML>/,/^ *<\/$XML>/ {/<stream type=\"$3\">/,/<\/stream>/ {/^ *<apply effect=\"$4\"\/>/p}}" $2)" ]; then
			sed -i "/^ *<$XML>/,/^ *<\/$XML>/ {/<stream type=\"$3\">/,/<\/stream>/ s/<stream type=\"$3\">/<stream type=\"$3\">\n            <apply effect=\"$4\"\/>/}" $2
	fi;;
esac
}

#author - Lord_Of_The_Lost@Telegram
patch_xml() {
  local Name0=$(echo "$3" | sed -r "s|^.*/.*\[@(.*)=\".*\".*$|\1|")
  local Value0=$(echo "$3" | sed -r "s|^.*/.*\[@.*=\"(.*)\".*$|\1|")
  [ "$(echo "$4" | grep '=')" ] && Name1=$(echo "$4" | sed "s|=.*||") || local Name1="value"
  local Value1=$(echo "$4" | sed "s|.*=||")
  case $1 in
  "-s"|"-u"|"-i")
    local SNP=$(echo "$3" | sed -r "s|(^.*/.*)\[@.*=\".*\".*$|\1|")
    local NP=$(dirname "$SNP")
    local SN=$(basename "$SNP")
    if [ "$5" ]; then
      [ "$(echo "$5" | grep '=')" ] && local Name2=$(echo "$5" | sed "s|=.*||") || local Name2="value"
      local Value2=$(echo "$5" | sed "s|.*=||")
    fi
    if [ "$6" ]; then
      [ "$(echo "$6" | grep '=')" ] && local Name3=$(echo "$6" | sed "s|=.*||") || local Name3="value"
      local Value3=$(echo "$6" | sed "s|.*=||")
    fi
    if [ "$7" ]; then
      [ "$(echo "$7" | grep '=')" ] && local Name4=$(echo "$7" | sed "s|=.*||") || local Name4="value"
      local Value4=$(echo "$7" | sed "s|.*=||")
    fi
  ;;
  esac
  case "$1" in
    "-d") xmlstarlet ed -L -d "$3" "$2";;
    "-u") xmlstarlet ed -L -u "$3/@$Name1" -v "$Value1" "$2";;
    "-s")
      if [ "$(xmlstarlet sel -t -m "$3" -c . "$2")" ]; then
        xmlstarlet ed -L -u "$3/@$Name1" -v "$Value1" "$2"
      else
        xmlstarlet ed -L -s "$NP" -t elem -n "$SN-$MODID" \
        -i "$SNP-$MODID" -t attr -n "$Name0" -v "$Value0" \
        -i "$SNP-$MODID" -t attr -n "$Name1" -v "$Value1" \
        -r "$SNP-$MODID" -v "$SN" "$2"
      fi;;
    "-i")
      if [ "$(xmlstarlet sel -t -m "$3[@$Name1=\"$Value1\"]" -c . "$2")" ]; then
        xmlstarlet ed -L -d "$3[@$Name1=\"$Value1\"]" "$2"
      fi
      if [ -z "$Value3" ]; then
        xmlstarlet ed -L -s "$NP" -t elem -n "$SN-$MODID" \
        -i "$SNP-$MODID" -t attr -n "$Name0" -v "$Value0" \
        -i "$SNP-$MODID" -t attr -n "$Name1" -v "$Value1" \
        -i "$SNP-$MODID" -t attr -n "$Name2" -v "$Value2" \
        -r "$SNP-$MODID" -v "$SN" "$2"
      elif [ "$Value4" ]; then
        xmlstarlet ed -L -s "$NP" -t elem -n "$SN-$MODID" \
        -i "$SNP-$MODID" -t attr -n "$Name0" -v "$Value0" \
        -i "$SNP-$MODID" -t attr -n "$Name1" -v "$Value1" \
        -i "$SNP-$MODID" -t attr -n "$Name2" -v "$Value2" \
        -i "$SNP-$MODID" -t attr -n "$Name3" -v "$Value3" \
        -i "$SNP-$MODID" -t attr -n "$Name4" -v "$Value4" \
        -r "$SNP-$MODID" -v "$SN" "$2"
      elif [ "$Value3" ]; then
        xmlstarlet ed -L -s "$NP" -t elem -n "$SN-$MODID" \
        -i "$SNP-$MODID" -t attr -n "$Name0" -v "$Value0" \
        -i "$SNP-$MODID" -t attr -n "$Name1" -v "$Value1" \
        -i "$SNP-$MODID" -t attr -n "$Name2" -v "$Value2" \
        -i "$SNP-$MODID" -t attr -n "$Name3" -v "$Value3" \
        -r "$SNP-$MODID" -v "$SN" "$2"
      fi
      ;;
  esac
}

#author - Lord_Of_The_Lost@Telegram
memes_confxml() {
case $FILE in
	*.conf) sed -i "/$1 {/,/}/d" $FILE
		sed -i "/$2 {/,/}/d" $FILE
		sed -i "s/^effects {/effects {\n  $1 {\n    library $2\n    uuid $5\n  }/g" $FILE
		sed -i "s/^libraries {/libraries {\n  $2 {\n    path $3\/$4\n  }/g" $FILE;;
	*.xml) sed -i "/$1/d" $FILE
		sed -i "/$2/d" $FILE
		sed -i "/<libraries>/ a\        <library name=\"$2\" path=\"$4\"\/>" $FILE
		sed -i "/<effects>/ a\        <effect name=\"$1\" library=\"$2\" uuid=\"$5\"\/>" $FILE;;
esac
}

libs_checker(){
	ASDK="$(GREP_PROP "ro.build.version.sdk")"
	DYNLIB=true
	[ $ASDK -lt 26 ] && DYNLIB=false
	[ -z $DYNLIB ] && DYNLIB=false
	if $DYNLIB; then 
		DYNLIBPATCH="\/vendor"; 
	else 
		DYNLIBPATCH="\/system"; 
	fi
}

altmemes_confxml() {
case $1 in
	*.conf) local SPACES=$(sed -n "/^output_session_processing {/,/^}/ {/^ *music {/p}" $1 | sed -r "s/( *).*/\1/")
		local EFFECTS=$(sed -n "/^output_session_processing {/,/^}/ {/^$SPACES\music {/,/^$SPACES}/p}" $1 | grep -E "^$SPACES +[A-Za-z]+" | sed -r "s/( *.*) .*/\1/g")
		for EFFECT in $EFFECTS; do
		local SPACES=$(sed -n "/^effects {/,/^}/ {/^ *$EFFECT {/p}" $1 | sed -r "s/( *).*/\1/")
		[ "$EFFECT" != "atmos" ] && sed -i "/^effects {/,/^}/ {/^$SPACES$EFFECT {/,/^$SPACES}/ s/^/#/g}" $1
	done;;
	*.xml) local EFFECTS=$(sed -n "/^ *<postprocess>$/,/^ *<\/postprocess>$/ {/^ *<stream type=\"music\">$/,/^ *<\/stream>$/ {/<stream type=\"music\">/d; /<\/stream>/d; s/<apply effect=\"//g; s/\"\/>//g; p}}" $1)
		for EFFECT in $EFFECTS; do
		[ "$EFFECT" != "atmos" ] && sed -ri "s/^( *)<apply effect=\"$EFFECT\"\/>/\1<\!--<apply effect=\"$EFFECT\"\/>-->/" $1
		done;;
esac
}

SD625=$(grep "ro.board.platform=msm8953" $BPROPCHECKER)
SD660=$(grep "ro.board.platform=sdm660" $BPROPCHECKER)
SD662=$(grep "ro.board.platform=bengal" $BPROPCHECKER)
SD665=$(grep "ro.board.platform=trinket" $BPROPCHECKER)
SD690=$(grep "ro.board.platform=lito" $BPROPCHECKER)
SD710=$(grep "ro.board.platform=sdm710" $BPROPCHECKER)
SD720G=$(grep "ro.board.platform=atoll" $BPROPCHECKER)
SD730=$(grep "ro.board.platform=sm6150" $BPROPCHECKER)
SD765G=$(grep "ro.board.platform=lito" $BPROPCHECKER)
SD820=$(grep "ro.board.platform=msm8996" $BPROPCHECKER)
SD835=$(grep "ro.board.platform=msm8998" $BPROPCHECKER)
SD845=$(grep "ro.board.platform=sdm845" $BPROPCHECKER)
SD855=$(grep "ro.board.platform=msmnile" $BPROPCHECKER)
SD865=$(grep "ro.board.platform=kona" $BPROPCHECKER)
SD888=$(grep "ro.board.platform=lahaina" $BPROPCHECKER)

RN5PRO=$(grep -E "ro.product.vendor.device=whyred.*" $BPROPCHECKER)
RN6PRO=$(grep -E "ro.product.vendor.device=tulip.*" $BPROPCHECKER)
R7Y3=$(grep -E "ro.product.vendor.device=onclite.*" $BPROPCHECKER)
RN7=$(grep -E "ro.product.vendor.device=lavender.*" $BPROPCHECKER)
RN7PRO=$(grep -E "ro.product.vendor.device=violet.*" $BPROPCHECKER)
RN8=$(grep -E "ro.product.vendor.device=ginkgo.*" $BPROPCHECKER)
RN8T=$(grep -E "ro.product.vendor.device=willow.*" $BPROPCHECKER)
RN9S=$(grep -E "ro.product.vendor.device=curtana.*" $BPROPCHECKER)
RN9PRO=$(grep -E "ro.product.vendor.device=joyeuse.*" $BPROPCHECKER)
RN95G=$(grep -E "ro.product.vendor.device=cannon.*" $BPROPCHECKER)
RN9T=$(grep -E "ro.product.vendor.device=cannong.*" $BPROPCHECKER)
R9T=$(grep -E "ro.product.vendor.device=lime.*" $BPROPCHECKER)

RN10PROMAX=$(grep -E "ro.product.vendor.device=sweetin.*" $BPROPCHECKER)
RN10PRO=$(grep -E "ro.product.vendor.device=sweet.*" $BPROPCHECKER)
RK305G=$(grep -E "ro.product.vendor.device=picasso.*" $BPROPCHECKER)
RK304G=$(grep -E "ro.product.vendor.device=phoenix.*" $BPROPCHECKER)
RK30U=$(grep -E "ro.product.vendor.device=cezanne.*" $BPROPCHECKER)
RK30i5G=$(grep -E "ro.product.vendor.device=picasso48m.*" $BPROPCHECKER)
RK40=$(grep -E "ro.product.vendor.device=alioth.*" $BPROPCHECKER)

MI9SE=$(grep -E "ro.product.vendor.device=grus.*" $BPROPCHECKER)
MICC9E=$(grep -E "ro.product.vendor.device=laurus.*" $BPROPCHECKER)
MICC9=$(grep -E "ro.product.vendor.device=pyxis.*" $BPROPCHECKER)
MINOTECC9PRO=$(grep -E "ro.product.vendor.device=tucana.*" $BPROPCHECKER)
MINOTE10LITE=$(grep -E "ro.product.vendor.device=toco.*" $BPROPCHECKER)
MINOTE10LITEZOOM=$(grep -E "ro.product.vendor.device=vangogh.*" $BPROPCHECKER)
MI9=$(grep -E "ro.product.vendor.device=cepheus.*" $BPROPCHECKER)
MI9T=$(grep -E "ro.product.vendor.device=davinci.*" $BPROPCHECKER)
MI10=$(grep -E "ro.product.vendor.device=umi.*" $BPROPCHECKER)
MI10Ultra=$(grep -E "ro.product.vendor.device=cas.*" $BPROPCHECKER)
MI10i5GRN95G=$(grep -E "ro.product.vendor.device=gauguin.*" $BPROPCHECKER)
MI10LITE=$(grep -E "ro.product.vendor.device=vangogh.*" $BPROPCHECKER)
MI10T=$(grep -E "ro.product.vendor.device=apollo.*" $BPROPCHECKER)
MI10PRO=$(grep -E "ro.product.vendor.device=cmi.*" $BPROPCHECKER)
MI11=$(grep -E "ro.product.vendor.device=venus.*" $BPROPCHECKER)
MI11Lite5G=$(grep -E "ro.product.vendor.device=renoir.*" $BPROPCHECKER)
MI11Lite4G=$(grep -E "ro.product.vendor.device=courbet.*" $BPROPCHECKER)
K20P=$(grep -E "ro.product.vendor.device=raphael.*|ro.product.vendor.device=raphaelin.*|ro.product.vendor.device=raphaels.*" $BPROPCHECKER)
MI8=$(grep -E "ro.product.vendor.device=dipper.*" $BPROPCHECKER)
MI8P=$(grep -E "ro.product.vendor.device=equuleus.*" $BPROPCHECKER)
MI9P=$(grep -E "ro.product.vendor.device=crux.*" $BPROPCHECKER)

MIA2LITE=$(grep -E "ro.product.vendor.device=daisy.*" $BPROPCHECKER)
MIA2=$(grep -E "ro.product.vendor.device=jasmine.*" $BPROPCHECKER)
MIA3=$(grep -E "ro.product.vendor.device=laurel.*" $BPROPCHECKER)

POCOF1=$(grep -E "ro.product.vendor.device=beryllium.*" $BPROPCHECKER)
POCOF2P=$(grep -E "ro.product.vendor.device=lmi.*" $BPROPCHECKER)
POCOF3=$(grep -E "ro.product.vendor.device=alioth.*" $BPROPCHECKER)
POCOF3P=$(grep -E "ro.product.vendor.device=vayu.*" $BPROPCHECKER)
POCOM2P=$(grep -E "ro.product.vendor.device=gram.*" $BPROPCHECKER)
POCOM3=$(grep -E "ro.product.vendor.device=citrus.*" $BPROPCHECKER)
POCOX3=$(grep -E "ro.product.vendor.device=surya.*" $BPROPCHECKER)
POCOX3Pro=$(grep -E "ro.product.vendor.device=vayu.*" $BPROPCHECKER)

DEVICE=$(getprop ro.product.vendor.device)

ACONF="$(find $SYSTEM $VENDOR -type f -name "audio_configs*.xml")"
APINF="$(find $SYSTEM $VENDOR -type f -name "audio_platform_info*.xml")"
AECFGS="$(find $SYSTEM $VENDOR -type f -name "*audio_effects*.conf" -o -name "*audio_effects*.xml")"
MPATHS="$(find $SYSTEM $VENDOR -type f -name "mixer_paths*.xml")"
#MCGAX="$(find $SYSTEM $VENDOR -type f -name "*media_codecs_google_c2_audio*.xml" -o -name "*media_codecs_google_audio*.xml" -o -name "*media_codecs_vendor_audio*.xml")"
APIXML="$VENDOR/etc/audio_platform_info.xml"
APIIXML="$VENDOR/etc/audio_platform_info_intcodec.xml"
APIEXML="$VENDOR/etc/audio_platform_info_extcodec.xml"
DEVFEA="$VENDOR/etc/device_features/$DEVICE.xml"; DEVFEAA="$SYSTEM/etc/device_features/$DEVICE.xml"
IOPOLICY="$(find $SYSTEM $VENDOR -type f -name "audio_io_policy.conf")"
AUDIOPOLICY="$(find $SYSTEM $VENDOR -type f -name "audio_policy_configuration.xml")"
SNDTRGS="$(find $SYSTEM $VENDOR -type f -name "*sound_trigger_mixer_paths*.xml")"

NEWdirac=$MODPATH/common/NLSound/newdirac

STEP1=false
STEP2=false
STEP3=false
STEP4=false
STEP5=false
STEP6=false
STEP7=false
STEP8=false
STEP9=false
STEP10=false
STEP11=false
STEP12=false
STEP13=false
STEP14=false
STEP15=false

ALL=false

mkdir -p $MODPATH/tools
cp -f $MODPATH/common/addon/External-Tools/tools/$ARCH32/* $MODPATH/tools/

  for OMIX in ${MPATHS}; do
	MIX="$MODPATH$(echo $OMIX | sed "s|^/vendor|/system/vendor|g")"
	mkdir -p `dirname $MIX`
	cp -f $MAGISKMIRROR$OMIX $MIX
	sed -i 's/\t/  /g' $MIX
	done

deep_buffer() {
	echo -e '\n#PATCH DEEP BUFFER\naudio.deep_buffer.media=false\nvendor.audio.deep_buffer.media=false\nqc.audio.deep_buffer.media=false\nro.qc.audio.deep_buffer.media=false\npersist.vendor.audio.deep_buffer.media=false' >> $MODPATH/system.prop
		for OACONF in $ACONF; do
		ACONF="$MODPATH$(echo $OACONF | sed "s|^/vendor|/system/vendor|g")"
			patch_xml -u $ACONF '/configs/property[@name="audio.deep_buffer.media"]' "false"
		done
}
	
patch_volumes() {
	for OMIX in $MPATHS; do
    MIX="$MODPATH$(echo $OMIX | sed "s|^/vendor|/system/vendor|g")"
    mkdir -p `dirname $MIX`
	cp -f $MAGISKMIRROR$OMIX $MIX
	sed -i 's/\t/  /g' $MIX
		patch_xml -u $MIX '/mixer/ctl[@name="RX0 Digital Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="RX1 Digital Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="RX2 Digital Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="RX3 Digital Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="RX4 Digital Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="RX5 Digital Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="RX6 Digital Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="RX7 Digital Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="RX8 Digital Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="RX0 Mix Digital Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="RX1 Mix Digital Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="RX2 Mix Digital Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="RX3 Mix Digital Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="RX4 Mix Digital Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="RX5 Mix Digital Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="RX6 Mix Digital Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="RX7 Mix Digital Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="RX8 Mix Digital Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="WSA_RX0 Digital Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="WSA_RX1 Digital Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="WSA_RX2 Digital Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="WSA_RX3 Digital Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="WSA_RX4 Digital Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="WSA_RX5 Digital Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="WSA_RX6 Digital Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="WSA_RX7 Digital Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="WSA_RX8 Digital Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="RX_RX0 Digital Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="RX_RX1 Digital Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="RX_RX2 Digital Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="RX_RX3 Digital Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="RX_RX4 Digital Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="RX_RX5 Digital Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="RX_RX6 Digital Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="RX_RX7 Digital Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="RX_RX8 Digital Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="RX_RX0 Mix Digital Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="RX_RX1 Mix Digital Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="RX_RX2 Mix Digital Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="RX_RX3 Mix Digital Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="RX_RX4 Mix Digital Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="RX_RX5 Mix Digital Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="RX_RX6 Mix Digital Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="RX_RX7 Mix Digital Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="RX_RX8 Mix Digital Volume"]' "90"
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX_RX0 Digital Volume"]' "90"
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX_RX1 Digital Volume"]' "90"
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX_RX2 Digital Volume"]' "90"
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX_RX3 Digital Volume"]' "90"
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX0 Digital Volume"]' "90"
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX1 Digital Volume"]' "90"
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX2 Digital Volume"]' "90"
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX3 Digital Volume"]' "90"
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX4 Digital Volume"]' "90"
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX5 Digital Volume"]' "90"
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX6 Digital Volume"]' "90"
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX7 Digital Volume"]' "90"
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX8 Digital Volume"]' "90"
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="WSA_RX0 Digital Volume"]' "90"
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="WSA_RX1 Digital Volume"]' "90"
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="WSA_RX2 Digital Volume"]' "90"
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="WSA_RX3 Digital Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="LINEOUT1 Volume"]' "16"
		patch_xml -u $MIX '/mixer/ctl[@name="LINEOUT2 Volume"]' "16"
		patch_xml -u $MIX '/mixer/ctl[@name="HPHL Volume"]' "18"
		patch_xml -u $MIX '/mixer/ctl[@name="HPHR Volume"]' "18"
		echo -e '\nro.config.media_vol_steps=30' >> $MODPATH/system.prop
	done
}

patch_microphone() {
	for OMIX in $MPATHS; do
    MIX="$MODPATH$(echo $OMIX | sed "s|^/vendor|/system/vendor|g")"
	mkdir -p `dirname $MIX`
	cp -f $MAGISKMIRROR$OMIX $MIX
	sed -i 's/\t/  /g' $MIX
	if ! $HIFI; then
		patch_xml -u $MIX '/mixer/ctl[@name="ADC1 Volume"]' "12"
		patch_xml -u $MIX '/mixer/ctl[@name="ADC2 Volume"]' "12"
		patch_xml -u $MIX '/mixer/ctl[@name="ADC3 Volume"]' "12"
		patch_xml -u $MIX '/mixer/ctl[@name="ADC4 Volume"]' "12"
		patch_xml -u $MIX '/mixer/ctl[@name="DEC0 Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="DEC1 Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="DEC2 Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="DEC3 Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="DEC4 Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="DEC5 Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="DEC6 Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="DEC7 Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="DEC8 Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="TX_DEC0 Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="TX_DEC1 Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="TX_DEC2 Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="TX_DEC3 Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="TX_DEC4 Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="TX_DEC5 Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="TX_DEC6 Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="TX_DEC7 Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="TX_DEC8 Volume"]' "90"
	else
		patch_xml -u $MIX '/mixer/ctl[@name="ADC1 Volume"]' "12"
		patch_xml -u $MIX '/mixer/ctl[@name="ADC2 Volume"]' "12"
		patch_xml -u $MIX '/mixer/ctl[@name="ADC3 Volume"]' "12"
		patch_xml -u $MIX '/mixer/ctl[@name="ADC4 Volume"]' "12"
		patch_xml -u $MIX '/mixer/ctl[@name="DEC0 Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="DEC1 Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="DEC2 Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="DEC3 Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="DEC4 Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="DEC5 Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="DEC6 Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="DEC7 Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="DEC8 Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="TX_DEC0 Volume"]' "88"
		patch_xml -u $MIX '/mixer/ctl[@name="TX_DEC1 Volume"]' "88"
		patch_xml -u $MIX '/mixer/ctl[@name="TX_DEC2 Volume"]' "88"
		patch_xml -u $MIX '/mixer/ctl[@name="TX_DEC3 Volume"]' "88"
		patch_xml -u $MIX '/mixer/ctl[@name="TX_DEC4 Volume"]' "88"
		patch_xml -u $MIX '/mixer/ctl[@name="TX_DEC5 Volume"]' "88"
		patch_xml -u $MIX '/mixer/ctl[@name="TX_DEC6 Volume"]' "88"
		patch_xml -u $MIX '/mixer/ctl[@name="TX_DEC7 Volume"]' "88"
		patch_xml -u $MIX '/mixer/ctl[@name="TX_DEC8 Volume"]' "88"
		
	fi
		patch_xml -u $MIX '/mixer/path[@name="adc1"]/ctl[@name="ADC1 Volume"]' "12"
		patch_xml -u $MIX '/mixer/path[@name="adc2"]/ctl[@name="ADC2 Volume"]' "12"
		patch_xml -u $MIX '/mixer/path[@name="adc3"]/ctl[@name="ADC3 Volume"]' "12"
		patch_xml -u $MIX '/mixer/path[@name="asr-mic"]/ctl[@name="ADC1 Volume"]' "12"
		patch_xml -u $MIX '/mixer/path[@name="asr-mic"]/ctl[@name="ADC3 Volume"]' "12"
	done
}

iir_patches() {
	for OMIX in $MPATHS; do
    MIX="$MODPATH$(echo $OMIX | sed "s|^/vendor|/system/vendor|g")"
	mkdir -p `dirname $MIX`
	cp -f $MAGISKMIRROR$OMIX $MIX
	sed -i 's/\t/  /g' $MIX
		patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band1"][@id="0"]' "268833620"
		patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band1"][@id="1"]' "537398060"
		patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band1"][@id="2"]' "267510580"
		patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band1"][@id="3"]' "537398060"
		patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band1"][@id="4"]' "267908744"
		patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band2"][@id="0"]' "266468108"
		patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band2"][@id="1"]' "544862876"
		patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band2"][@id="2"]' "262421829"
		patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band2"][@id="3"]' "544862876"
		patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band2"][@id="4"]' "260454481"
		patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band3"][@id="0"]' "262913321"
		patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band3"][@id="1"]' "559557058"
		patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band3"][@id="2"]' "252311547"
		patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band3"][@id="3"]' "559557058"
		patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band3"][@id="4"]' "246789412"
		patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band4"][@id="0"]' "294517138"
		patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band4"][@id="1"]' "572289454"
		patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band4"][@id="2"]' "210943778"
		patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band4"][@id="3"]' "572289454"
		patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band4"][@id="4"]' "237025461"
		patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band5"][@id="0"]' "329006442"
		patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band5"][@id="1"]' "711929387"
		patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band5"][@id="2"]' "110068469"
		patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band5"][@id="3"]' "711929387"
		patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Band5"][@id="4"]' "170639455"
		patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Enable Band0"]' "1"
		patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Enable Band1"]' "1"
		patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Enable Band2"]' "1"
		patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Enable Band3"]' "1"
		patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Enable Band4"]' "1"
		patch_xml -u $MIX '/mixer/ctl[@name="IIR0 Enable Band5"]' "1"
		patch_xml -u $MIX '/mixer/ctl[@name="IIR0 INP0 Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="IIR0 INP1 Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="IIR0 INP2 Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="IIR0 INP3 Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="IIR0 INP4 Volume"]' "90"
		patch_xml -u $MIX '/mixer/ctl[@name="IIR0 INP5 Volume"]' "90"
		
		patch_xml -u $MIX '/mixer/ctl[@name="IIR0 INP0 MUX"]' "RX0"
		patch_xml -u $MIX '/mixer/ctl[@name="IIR0 INP1 MUX"]' "RX0"
		patch_xml -u $MIX '/mixer/ctl[@name="IIR0 INP2 MUX"]' "RX0"
		patch_xml -u $MIX '/mixer/ctl[@name="IIR0 INP3 MUX"]' "RX0"
		patch_xml -u $MIX '/mixer/ctl[@name="IIR0 INP1 MUX"]' "RX1"
		patch_xml -u $MIX '/mixer/ctl[@name="IIR0 INP2 MUX"]' "RX1"
		patch_xml -u $MIX '/mixer/ctl[@name="IIR0 INP3 MUX"]' "RX1"
		patch_xml -u $MIX '/mixer/ctl[@name="IIR0 INP1 MUX"]' "RX2"
		patch_xml -u $MIX '/mixer/ctl[@name="IIR0 INP2 MUX"]' "RX2"
		patch_xml -u $MIX '/mixer/ctl[@name="IIR0 INP3 MUX"]' "RX2"
		patch_xml -u $MIX '/mixer/ctl[@name="IIR0 INP1 MUX"]' "RX3"
		patch_xml -u $MIX '/mixer/ctl[@name="IIR0 INP2 MUX"]' "RX3"
		patch_xml -u $MIX '/mixer/ctl[@name="IIR0 INP3 MUX"]' "RX3"
		patch_xml -u $MIX '/mixer/ctl[@name="IIR0 INP1 MUX"]' "RX4"
		patch_xml -u $MIX '/mixer/ctl[@name="IIR0 INP2 MUX"]' "RX4"
		patch_xml -u $MIX '/mixer/ctl[@name="IIR0 INP3 MUX"]' "RX4"
		patch_xml -u $MIX '/mixer/ctl[@name="IIR0 INP1 MUX"]' "RX5"
		patch_xml -u $MIX '/mixer/ctl[@name="IIR0 INP2 MUX"]' "RX5"
		patch_xml -u $MIX '/mixer/ctl[@name="IIR0 INP3 MUX"]' "RX5"
	done
}

audio_platform_info_int() {
	for OAPLI in $APINF; do
	APLI="$MODPATH$(echo $OAPLI | sed "s|^/vendor|/system/vendor|g")"
	mkdir -p `dirname $APLI`
	cp -f $MAGISKMIRROR$OAPLI $APLI
	sed -i 's/\t/  /g' $APLI
		patch_xml -s $APLI '/audio_platform_info_intcodec/config_params/param[@key="native_audio_mode"]' "multiple_mix_dsp"
		patch_xml -s $APLI '/audio_platform_info_intcodec/config_params/param[@key="hifi_filter"]' "true"
		patch_xml -s $APLI '/audio_platform_info_intcodec/bit_width_configs/device[@name="SND_DEVICE_OUT_HEADPHONES"]' "bit_width=24"
		patch_xml -s $APLI '/audio_platform_info_intcodec/bit_width_configs/device[@name="SND_DEVICE_OUT_SPEAKER_REVERSE"]' "bit_width=24"
		patch_xml -s $APLI '/audio_platform_info_intcodec/bit_width_configs/device[@name="SND_DEVICE_OUT_SPEAKER_PROTECTED"]' "bit_width=24"
		patch_xml -s $APLI '/audio_platform_info_intcodec/bit_width_configs/device[@name="SND_DEVICE_OUT_HEADPHONES_44_1"]' "bit_width=24"
		patch_xml -s $APLI '/audio_platform_info_intcodec/bit_width_configs/device[@name="SND_DEVICE_OUT_GAME_SPEAKER"]' "bit_width=24"
		patch_xml -s $APLI '/audio_platform_info_intcodec/bit_width_configs/device[@name="SND_DEVICE_OUT_GAME_HEADPHONES"]' "bit_width=24"
		patch_xml -s $APLI '/audio_platform_info_intcodec/bit_width_configs/device[@name="SND_DEVICE_OUT_BT_A2DP"]' "bit_width=24"	 
		patch_xml -u $APLI '/audio_platform_info_intcodec/app_types/app[@mode="default"]' "bit_width=24"
		patch_xml -u $APLI '/audio_platform_info_intcodec/app_types/app[@mode="default"]' "max_rate=192000"
	if [ ! "$(grep '<app_types>' $APLI)" ]; then
		sed -i "s/<\/audio_platform_info_intcodec>/  <app_types> \n    <app uc_type=\"PCM_PLAYBACK\" mode=\"default\" bit_width=\"24\" id=\"69936\" max_rate=\"192000\" \/> \n    <app uc_type=\"PCM_PLAYBACK\" mode=\"default\" bit_width=\"24\" id=\"69940\" max_rate=\"192000\" \/> \n  <app_types> \n<\/audio_platform_info_intcodec>/" $APLI		  
	else
	for i in 69936 69940; do
		[ "$(xmlstarlet sel -t -m "/audio_platform_info_extcodec/app_types/app[@uc_type=\"PCM_PLAYBACK\"][@mode=\"default\"][@id=\"$i\"]" -c . $APLI)" ] || sed -i "/<audio_platform_info_extcodec>/,/<\/audio_platform_info_extcodec>/ {/<app_types>/,/<\/app_types>/ s/\(^ *\)\(<\/app_types>\)/\1  <app uc_type=\"PCM_PLAYBACK\" mode=\"default\" bit_width=\"24\" id=\"$i\" max_rate=\"192000\" \/> \n\1\2/}" $APLI			
    done
	fi
	
	for OMIX in $MPATHS; do
    MIX="$MODPATH$(echo $OMIX | sed "s|^/vendor|/system/vendor|g")"
		patch_xml -s $MIX '/mixer/ctl[@name="EC Reference Bit Format"]' "S24_LE"
		patch_xml -s $MIX '/mixer/ctl[@name="EC Reference SampleRate"]' "KHZ_192"
		patch_xml -s $MIX '/mixer/path[@name="echo-reference"]/ctl[@name="EC Reference Bit Format"]' "S24_LE"
		patch_xml -s $MIX '/mixer/path[@name="echo-reference"]/ctl[@name="EC Reference SampleRate"]' "KHZ_192"
		patch_xml -s $MIX '/mixer/path[@name="echo-reference a2dp"]/ctl[@name="EC Reference Bit Format"]' "S24_LE"
		patch_xml -s $MIX '/mixer/path[@name="echo-reference a2dp"]/ctl[@name="EC Reference SampleRate"]' "KHZ_96"
		patch_xml -s $MIX '/mixer/ctl[@name="Display Port RX Bit Format"]' "S24_3LE"
		patch_xml -s $MIX '/mixer/ctl[@name="Display Port RX SampleRate"]' "KHZ_192"
		patch_xml -s $MIX '/mixer/ctl[@name="SEC_MI2S_RX Format"]' "S24_3LE"
		patch_xml -s $MIX '/mixer/ctl[@name="SEC_MI2S_RX SampleRate"]' "KHZ_192"
		patch_xml -s $MIX '/mixer/ctl[@name="WSA_CDC_DMA_0 RX Format"]' "DSD_DOP"
		patch_xml -s $MIX '/mixer/ctl[@name="WSA_CDC_DMA_RX_0 Format"]' "S24_3LE"
		patch_xml -s $MIX '/mixer/ctl[@name="WSA_CDC_DMA_RX_0 SampleRate"]' "KHZ_192"
		patch_xml -s $MIX '/mixer/ctl[@name="WSA_CDC_DMA_0 TX Format"]' "DSD_DOP"
		patch_xml -s $MIX '/mixer/ctl[@name="WSA_CDC_DMA_TX_0 Format"]' "S24_3LE"
		patch_xml -s $MIX '/mixer/ctl[@name="WSA_CDC_DMA_TX_0 SampleRate"]' "KHZ_192"
		patch_xml -s $MIX '/mixer/ctl[@name="RX_CDC_DMA_0 RX Format"]' "DSD_DOP"
		patch_xml -s $MIX '/mixer/ctl[@name="RX_CDC_DMA_RX_0 Format"]' "S24_3LE"
		patch_xml -s $MIX '/mixer/ctl[@name="RX_CDC_DMA_RX_0 SampleRate"]' "KHZ_192"
		patch_xml -s $MIX '/mixer/ctl[@name="RX_CDC_DMA_RX_5 Channels"]' "Two"
		patch_xml -s $MIX '/mixer/ctl[@name="RX_CDC_DMA_5 RX Format"]' "DSD_DOP"
		patch_xml -s $MIX '/mixer/ctl[@name="RX_CDC_DMA_RX_5 Format"]' "S32_LE"
		patch_xml -s $MIX '/mixer/ctl[@name="RX_CDC_DMA_RX_5 SampleRate"]' "KHZ_192"
		patch_xml -s $MIX '/mixer/ctl[@name="DSD_L Switch"]' "1"
		patch_xml -s $MIX '/mixer/ctl[@name="DSD_R Switch"]' "1"
		patch_xml -s $MIX '/mixer/ctl[@name="ASM Bit Width"]' "24"
		patch_xml -s $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX_CDC_DMA_0 RX Format"]' "DSD_DOP"
		patch_xml -s $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX_CDC_DMA_RX_0 Format"]' "S24_3LE"
		patch_xml -s $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX_CDC_DMA_RX_0 SampleRate"]' "KHZ_192"
		patch_xml -s $MIX '/mixer/path[@name="handset"]/ctl[@name="RX_CDC_DMA_RX_0 Format"]' "S24_3LE"
		patch_xml -s $MIX '/mixer/ctl[@name="WSA_CDC_DMA_RX_0 Port Mixer SLIM_7_TX"]' "1"
		patch_xml -s $MIX '/mixer/ctl[@name="RX_CDC_DMA_RX_0 Port Mixer SLIM_7_TX"]' "1"
		patch_xml -s $MIX '/mixer/path[@name="headphones-dsd"]/ctl[@name="SLIM_2_RX Format"]' "DSD_DOP"
		
		
		if $HIFI; then
			patch_xml -s $MIX '/mixer/ctl[@name="SLIM_7_RX Format"]' "S24_3LE"
			patch_xml -s $MIX '/mixer/ctl[@name="SLIM_7_RX SampleRate"]' "KHZ_192"
			patch_xml -s $MIX '/mixer/ctl[@name="SLIMBUS_7_RX Format"]' "S24_3LE"
			patch_xml -s $MIX '/mixer/ctl[@name="SLIMBUS_7_RX SampleRate"]' "KHZ_192"
			patch_xml -s $MIX '/mixer/ctl[@name="headphones"]/ctl[@name="SLIM_5_RX Format"]' "S24_3LE"
			patch_xml -s $MIX '/mixer/ctl[@name="PRIM_MI2S_RX Format"]' "S24_3LE"
			patch_xml -s $MIX '/mixer/ctl[@name="PRIM_MI2S_TX Format"]' "S24_3LE"
		else
			#kekwait
			patch_xml -s $MIX '/mixer/ctl[@name="MEM"]' "by_NLSound"
		fi
		
		if [ "$RN5PRO" ] || [ "$MI9" ] || [ "$MI8" ] || [ "$MI8P" ] || [ "$MI9P" ] || [ "$MIA2" ]; then
			patch_xml -s $MIX '/mixer/path[@name="headphones-44.1"]/ctl[@name="SLIM_5_RX Format"]' "S24_3LE"
		fi
	done

	for OSNDTRG in ${SNDTRGS}; do
	STG="$MODPATH$(echo $OSNDTRG | sed "s|^/vendor|/system/vendor|g")"
	mkdir -p `dirname $STG`
	cp -f $MAGISKMIRROR$OSNDTRG $STG
	sed -i 's/\t/  /g' $STG
		patch_xml -s $STG '/mixer/path[@name="echo-reference"]/ctl[@name="EC Reference Bit Format"]' "S24_LE"
		patch_xml -s $STG '/mixer/path[@name="echo-reference"]/ctl[@name="EC Reference SampleRate"]' "KHZ_192"
		patch_xml -s $STG '/mixer/path[@name="echo-reference a2dp"]/ctl[@name="EC Reference Bit Format"]' "S24_LE"
		patch_xml -s $STG '/mixer/path[@name="echo-reference a2dp"]/ctl[@name="EC Reference SampleRate"]' "KHZ_96"
	done
done
}

audio_platform_info_ext() {
	for OAPLI in $APINF; do
	APLI="$MODPATH$(echo $OAPLI | sed "s|^/vendor|/system/vendor|g")"
	mkdir -p `dirname $APLI`
	cp -f $MAGISKMIRROR$OAPLI $APLI
	sed -i 's/\t/  /g' $APLI
		patch_xml -s $APLI '/audio_platform_info_extcodec/config_params/param[@key="native_audio_mode"]' "multiple_mix_dsp"
		patch_xml -s $APLI '/audio_platform_info_extcodec/config_params/param[@key="hifi_filter"]' "true"
		patch_xml -s $APLI '/audio_platform_info_extcodec/bit_width_configs/device[@name="SND_DEVICE_OUT_HEADPHONES"]' "bit_width=24"
		patch_xml -s $APLI '/audio_platform_info_extcodec/bit_width_configs/device[@name="SND_DEVICE_OUT_SPEAKER_REVERSE"]' "bit_width=24"
		patch_xml -s $APLI '/audio_platform_info_extcodec/bit_width_configs/device[@name="SND_DEVICE_OUT_SPEAKER_PROTECTED"]' "bit_width=24"
		patch_xml -s $APLI '/audio_platform_info_extcodec/bit_width_configs/device[@name="SND_DEVICE_OUT_HEADPHONES_44_1"]' "bit_width=24"
		patch_xml -s $APLI '/audio_platform_info_extcodec/bit_width_configs/device[@name="SND_DEVICE_OUT_GAME_SPEAKER"]' "bit_width=24"
		patch_xml -s $APLI '/audio_platform_info_extcodec/bit_width_configs/device[@name="SND_DEVICE_OUT_GAME_HEADPHONES"]' "bit_width=24"
		patch_xml -s $APLI '/audio_platform_info_extcodec/bit_width_configs/device[@name="SND_DEVICE_OUT_BT_A2DP"]' "bit_width=24"	 
		patch_xml -u $APLI '/audio_platform_info_extcodec/app_types/app[@mode="default"]' "bit_width=24"
		patch_xml -u $APLI '/audio_platform_info_extcodec/app_types/app[@mode="default"]' "max_rate=192000"
	if [ ! "$(grep '<app_types>' $APLI)" ]; then
		sed -i "s/<\/audio_platform_info_extcodec>/  <app_types> \n    <app uc_type=\"PCM_PLAYBACK\" mode=\"default\" bit_width=\"24\" id=\"69936\" max_rate=\"192000\" \/> \n    <app uc_type=\"PCM_PLAYBACK\" mode=\"default\" bit_width=\"24\" id=\"69940\" max_rate=\"192000\" \/> \n  <app_types> \n<\/audio_platform_info_extcodec>/" $APLI		  
	else
	for i in 69936 69940; do
		[ "$(xmlstarlet sel -t -m "/audio_platform_info_extcodec/app_types/app[@uc_type=\"PCM_PLAYBACK\"][@mode=\"default\"][@id=\"$i\"]" -c . $APLI)" ] || sed -i "/<audio_platform_info_extcodec>/,/<\/audio_platform_info_extcodec>/ {/<app_types>/,/<\/app_types>/ s/\(^ *\)\(<\/app_types>\)/\1  <app uc_type=\"PCM_PLAYBACK\" mode=\"default\" bit_width=\"24\" id=\"$i\" max_rate=\"192000\" \/> \n\1\2/}" $APLI			
    done
	fi
	
	for OMIX in $MPATHS; do
    MIX="$MODPATH$(echo $OMIX | sed "s|^/vendor|/system/vendor|g")"
		patch_xml -s $MIX '/mixer/ctl[@name="EC Reference Bit Format"]' "S24_LE"
		patch_xml -s $MIX '/mixer/ctl[@name="EC Reference SampleRate"]' "KHZ_192"
		patch_xml -s $MIX '/mixer/path[@name="echo-reference"]/ctl[@name="EC Reference Bit Format"]' "S24_LE"
		patch_xml -s $MIX '/mixer/path[@name="echo-reference"]/ctl[@name="EC Reference SampleRate"]' "KHZ_192"
		patch_xml -s $MIX '/mixer/path[@name="echo-reference a2dp"]/ctl[@name="EC Reference Bit Format"]' "S24_LE"
		patch_xml -s $MIX '/mixer/path[@name="echo-reference a2dp"]/ctl[@name="EC Reference SampleRate"]' "KHZ_96"
		patch_xml -s $MIX '/mixer/ctl[@name="Display Port RX Bit Format"]' "S24_3LE"
		patch_xml -s $MIX '/mixer/ctl[@name="Display Port RX SampleRate"]' "KHZ_192"
		patch_xml -s $MIX '/mixer/ctl[@name="SEC_MI2S_RX Format"]' "S24_3LE"
		patch_xml -s $MIX '/mixer/ctl[@name="SEC_MI2S_RX SampleRate"]' "KHZ_192"
		patch_xml -s $MIX '/mixer/ctl[@name="WSA_CDC_DMA_0 RX Format"]' "DSD_DOP"
		patch_xml -s $MIX '/mixer/ctl[@name="WSA_CDC_DMA_RX_0 Format"]' "S24_3LE"
		patch_xml -s $MIX '/mixer/ctl[@name="WSA_CDC_DMA_RX_0 SampleRate"]' "KHZ_192"
		patch_xml -s $MIX '/mixer/ctl[@name="WSA_CDC_DMA_0 TX Format"]' "DSD_DOP"
		patch_xml -s $MIX '/mixer/ctl[@name="WSA_CDC_DMA_TX_0 Format"]' "S24_3LE"
		patch_xml -s $MIX '/mixer/ctl[@name="WSA_CDC_DMA_TX_0 SampleRate"]' "KHZ_192"
		patch_xml -s $MIX '/mixer/ctl[@name="RX_CDC_DMA_0 RX Format"]' "DSD_DOP"
		patch_xml -s $MIX '/mixer/ctl[@name="RX_CDC_DMA_RX_0 Format"]' "S24_3LE"
		patch_xml -s $MIX '/mixer/ctl[@name="RX_CDC_DMA_RX_0 SampleRate"]' "KHZ_192"
		patch_xml -s $MIX '/mixer/ctl[@name="RX_CDC_DMA_RX_5 Channels"]' "Two"
		patch_xml -s $MIX '/mixer/ctl[@name="RX_CDC_DMA_5 RX Format"]' "DSD_DOP"
		patch_xml -s $MIX '/mixer/ctl[@name="RX_CDC_DMA_RX_5 Format"]' "S32_LE"
		patch_xml -s $MIX '/mixer/ctl[@name="RX_CDC_DMA_RX_5 SampleRate"]' "KHZ_192"
		patch_xml -s $MIX '/mixer/ctl[@name="DSD_L Switch"]' "1"
		patch_xml -s $MIX '/mixer/ctl[@name="DSD_R Switch"]' "1"
		patch_xml -s $MIX '/mixer/ctl[@name="ASM Bit Width"]' "24"
		patch_xml -s $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX_CDC_DMA_0 RX Format"]' "DSD_DOP"
		patch_xml -s $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX_CDC_DMA_RX_0 Format"]' "S24_3LE"
		patch_xml -s $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX_CDC_DMA_RX_0 SampleRate"]' "KHZ_192"
		patch_xml -s $MIX '/mixer/path[@name="handset"]/ctl[@name="RX_CDC_DMA_RX_0 Format"]' "S24_3LE"
		patch_xml -s $MIX '/mixer/ctl[@name="WSA_CDC_DMA_RX_0 Port Mixer SLIM_7_TX"]' "1"
		patch_xml -s $MIX '/mixer/ctl[@name="RX_CDC_DMA_RX_0 Port Mixer SLIM_7_TX"]' "1"
		patch_xml -s $MIX '/mixer/path[@name="headphones-dsd"]/ctl[@name="SLIM_2_RX Format"]' "DSD_DOP"
		
		
		if $HIFI; then
			patch_xml -s $MIX '/mixer/ctl[@name="SLIM_7_RX Format"]' "S24_3LE"
			patch_xml -s $MIX '/mixer/ctl[@name="SLIM_7_RX SampleRate"]' "KHZ_192"
			patch_xml -s $MIX '/mixer/ctl[@name="SLIMBUS_7_RX Format"]' "S24_3LE"
			patch_xml -s $MIX '/mixer/ctl[@name="SLIMBUS_7_RX SampleRate"]' "KHZ_192"
			patch_xml -s $MIX '/mixer/ctl[@name="headphones"]/ctl[@name="SLIM_5_RX Format"]' "S24_3LE"
			patch_xml -s $MIX '/mixer/ctl[@name="PRIM_MI2S_RX Format"]' "S24_3LE"
			patch_xml -s $MIX '/mixer/ctl[@name="PRIM_MI2S_TX Format"]' "S24_3LE"
		else
			#kekwait
			patch_xml -s $MIX '/mixer/ctl[@name="MEM"]' "by_NLSound"
		fi
		
		if [ "$RN5PRO" ] || [ "$MI9" ] || [ "$MI8" ] || [ "$MI8P" ] || [ "$MI9P" ] || [ "$MIA2" ]; then
			patch_xml -s $MIX '/mixer/path[@name="headphones-44.1"]/ctl[@name="SLIM_5_RX Format"]' "S24_3LE"
		fi
	done
	
	for OSNDTRG in ${SNDTRGS}; do
	STG="$MODPATH$(echo $OSNDTRG | sed "s|^/vendor|/system/vendor|g")"
	mkdir -p `dirname $STG`
	cp -f $MAGISKMIRROR$OSNDTRG $STG
	sed -i 's/\t/  /g' $STG
		patch_xml -s $STG '/mixer/path[@name="echo-reference"]/ctl[@name="EC Reference Bit Format"]' "S24_LE"
		patch_xml -s $STG '/mixer/path[@name="echo-reference"]/ctl[@name="EC Reference SampleRate"]' "KHZ_192"
		patch_xml -s $STG '/mixer/path[@name="echo-reference a2dp"]/ctl[@name="EC Reference Bit Format"]' "S24_LE"
		patch_xml -s $STG '/mixer/path[@name="echo-reference a2dp"]/ctl[@name="EC Reference SampleRate"]' "KHZ_96"
	done
done
}

audio_platform_info() {
	for OAPLI in $APINF; do
	APLI="$MODPATH$(echo $OAPLI | sed "s|^/vendor|/system/vendor|g")"
	mkdir -p `dirname $APLI`
	cp -f $MAGISKMIRROR$OAPLI $APLI
	sed -i 's/\t/  /g' $APLI
		patch_xml -s $APLI '/audio_platform_info/config_params/param[@key="native_audio_mode"]' "multiple_mix_dsp"
		patch_xml -s $APLI '/audio_platform_info/config_params/param[@key="hifi_filter"]' "true"
		patch_xml -s $APLI '/audio_platform_info/bit_width_configs/device[@name="SND_DEVICE_OUT_HEADPHONES"]' "bit_width=24"
		patch_xml -s $APLI '/audio_platform_info/bit_width_configs/device[@name="SND_DEVICE_OUT_SPEAKER_REVERSE"]' "bit_width=24"
		patch_xml -s $APLI '/audio_platform_info/bit_width_configs/device[@name="SND_DEVICE_OUT_SPEAKER_PROTECTED"]' "bit_width=24"
		patch_xml -s $APLI '/audio_platform_info/bit_width_configs/device[@name="SND_DEVICE_OUT_HEADPHONES_44_1"]' "bit_width=24"
		patch_xml -s $APLI '/audio_platform_info/bit_width_configs/device[@name="SND_DEVICE_OUT_GAME_SPEAKER"]' "bit_width=24"
		patch_xml -s $APLI '/audio_platform_info/bit_width_configs/device[@name="SND_DEVICE_OUT_GAME_HEADPHONES"]' "bit_width=24"
		patch_xml -s $APLI '/audio_platform_info/bit_width_configs/device[@name="SND_DEVICE_OUT_BT_A2DP"]' "bit_width=24"	 
		patch_xml -u $APLI '/audio_platform_info/app_types/app[@mode="default"]' "bit_width=24"
		patch_xml -u $APLI '/audio_platform_info/app_types/app[@mode="default"]' "max_rate=192000"
	if [ ! "$(grep '<app_types>' $APLI)" ]; then
		sed -i "s/<\/audio_platform_info>/  <app_types> \n    <app uc_type=\"PCM_PLAYBACK\" mode=\"default\" bit_width=\"24\" id=\"69936\" max_rate=\"192000\" \/> \n    <app uc_type=\"PCM_PLAYBACK\" mode=\"default\" bit_width=\"24\" id=\"69940\" max_rate=\"192000\" \/> \n  <app_types> \n<\/audio_platform_info>/" $APLI		  
	else
	for i in 69936 69940; do
		[ "$(xmlstarlet sel -t -m "/audio_platform_info_extcodec/app_types/app[@uc_type=\"PCM_PLAYBACK\"][@mode=\"default\"][@id=\"$i\"]" -c . $APLI)" ] || sed -i "/<audio_platform_info_extcodec>/,/<\/audio_platform_info_extcodec>/ {/<app_types>/,/<\/app_types>/ s/\(^ *\)\(<\/app_types>\)/\1  <app uc_type=\"PCM_PLAYBACK\" mode=\"default\" bit_width=\"24\" id=\"$i\" max_rate=\"192000\" \/> \n\1\2/}" $APLI			
    done
	fi
	
	for OMIX in $MPATHS; do
    MIX="$MODPATH$(echo $OMIX | sed "s|^/vendor|/system/vendor|g")"
		patch_xml -s $MIX '/mixer/ctl[@name="EC Reference Bit Format"]' "S24_LE"
		patch_xml -s $MIX '/mixer/ctl[@name="EC Reference SampleRate"]' "KHZ_192"
		patch_xml -s $MIX '/mixer/path[@name="echo-reference"]/ctl[@name="EC Reference Bit Format"]' "S24_LE"
		patch_xml -s $MIX '/mixer/path[@name="echo-reference"]/ctl[@name="EC Reference SampleRate"]' "KHZ_192"
		patch_xml -s $MIX '/mixer/path[@name="echo-reference a2dp"]/ctl[@name="EC Reference Bit Format"]' "S24_LE"
		patch_xml -s $MIX '/mixer/path[@name="echo-reference a2dp"]/ctl[@name="EC Reference SampleRate"]' "KHZ_96"
		patch_xml -s $MIX '/mixer/ctl[@name="Display Port RX Bit Format"]' "S24_3LE"
		patch_xml -s $MIX '/mixer/ctl[@name="Display Port RX SampleRate"]' "KHZ_192"
		patch_xml -s $MIX '/mixer/ctl[@name="SEC_MI2S_RX Format"]' "S24_3LE"
		patch_xml -s $MIX '/mixer/ctl[@name="SEC_MI2S_RX SampleRate"]' "KHZ_192"
		patch_xml -s $MIX '/mixer/ctl[@name="WSA_CDC_DMA_0 RX Format"]' "DSD_DOP"
		patch_xml -s $MIX '/mixer/ctl[@name="WSA_CDC_DMA_RX_0 Format"]' "S24_3LE"
		patch_xml -s $MIX '/mixer/ctl[@name="WSA_CDC_DMA_RX_0 SampleRate"]' "KHZ_192"
		patch_xml -s $MIX '/mixer/ctl[@name="WSA_CDC_DMA_0 TX Format"]' "DSD_DOP"
		patch_xml -s $MIX '/mixer/ctl[@name="WSA_CDC_DMA_TX_0 Format"]' "S24_3LE"
		patch_xml -s $MIX '/mixer/ctl[@name="WSA_CDC_DMA_TX_0 SampleRate"]' "KHZ_192"
		patch_xml -s $MIX '/mixer/ctl[@name="RX_CDC_DMA_0 RX Format"]' "DSD_DOP"
		patch_xml -s $MIX '/mixer/ctl[@name="RX_CDC_DMA_RX_0 Format"]' "S24_3LE"
		patch_xml -s $MIX '/mixer/ctl[@name="RX_CDC_DMA_RX_0 SampleRate"]' "KHZ_192"
		patch_xml -s $MIX '/mixer/ctl[@name="RX_CDC_DMA_RX_5 Channels"]' "Two"
		patch_xml -s $MIX '/mixer/ctl[@name="RX_CDC_DMA_5 RX Format"]' "DSD_DOP"
		patch_xml -s $MIX '/mixer/ctl[@name="RX_CDC_DMA_RX_5 Format"]' "S32_LE"
		patch_xml -s $MIX '/mixer/ctl[@name="RX_CDC_DMA_RX_5 SampleRate"]' "KHZ_192"
		patch_xml -s $MIX '/mixer/ctl[@name="DSD_L Switch"]' "1"
		patch_xml -s $MIX '/mixer/ctl[@name="DSD_R Switch"]' "1"
		patch_xml -s $MIX '/mixer/ctl[@name="ASM Bit Width"]' "24"
		patch_xml -s $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX_CDC_DMA_0 RX Format"]' "DSD_DOP"
		patch_xml -s $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX_CDC_DMA_RX_0 Format"]' "S24_3LE"
		patch_xml -s $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX_CDC_DMA_RX_0 SampleRate"]' "KHZ_192"
		patch_xml -s $MIX '/mixer/path[@name="handset"]/ctl[@name="RX_CDC_DMA_RX_0 Format"]' "S24_3LE"
		patch_xml -s $MIX '/mixer/ctl[@name="WSA_CDC_DMA_RX_0 Port Mixer SLIM_7_TX"]' "1"
		patch_xml -s $MIX '/mixer/ctl[@name="RX_CDC_DMA_RX_0 Port Mixer SLIM_7_TX"]' "1"
		patch_xml -s $MIX '/mixer/path[@name="headphones-dsd"]/ctl[@name="SLIM_2_RX Format"]' "DSD_DOP"
		
		
		if $HIFI; then
			patch_xml -s $MIX '/mixer/ctl[@name="SLIM_7_RX Format"]' "S24_3LE"
			patch_xml -s $MIX '/mixer/ctl[@name="SLIM_7_RX SampleRate"]' "KHZ_192"
			patch_xml -s $MIX '/mixer/ctl[@name="SLIMBUS_7_RX Format"]' "S24_3LE"
			patch_xml -s $MIX '/mixer/ctl[@name="SLIMBUS_7_RX SampleRate"]' "KHZ_192"
			patch_xml -s $MIX '/mixer/ctl[@name="headphones"]/ctl[@name="SLIM_5_RX Format"]' "S24_3LE"
			patch_xml -s $MIX '/mixer/ctl[@name="PRIM_MI2S_RX Format"]' "S24_3LE"
			patch_xml -s $MIX '/mixer/ctl[@name="PRIM_MI2S_TX Format"]' "S24_3LE"
		else
			#kekwait
			patch_xml -s $MIX '/mixer/ctl[@name="MEM"]' "by_NLSound"
		fi
		
		if [ "$RN5PRO" ] || [ "$MI9" ] || [ "$MI8" ] || [ "$MI8P" ] || [ "$MI9P" ] || [ "$MIA2" ]; then
			patch_xml -s $MIX '/mixer/path[@name="headphones-44.1"]/ctl[@name="SLIM_5_RX Format"]' "S24_3LE"
		fi
	done
	
	for OSNDTRG in ${SNDTRGS}; do
	STG="$MODPATH$(echo $OSNDTRG | sed "s|^/vendor|/system/vendor|g")"
	mkdir -p `dirname $STG`
	cp -f $MAGISKMIRROR$OSNDTRG $STG
	sed -i 's/\t/  /g' $STG
		patch_xml -s $STG '/mixer/path[@name="echo-reference"]/ctl[@name="EC Reference Bit Format"]' "S24_LE"
		patch_xml -s $STG '/mixer/path[@name="echo-reference"]/ctl[@name="EC Reference SampleRate"]' "KHZ_192"
		patch_xml -s $STG '/mixer/path[@name="echo-reference a2dp"]/ctl[@name="EC Reference Bit Format"]' "S24_LE"
		patch_xml -s $STG '/mixer/path[@name="echo-reference a2dp"]/ctl[@name="EC Reference SampleRate"]' "KHZ_96"
	done
done
}

companders() {
	for OMIX in $MPATHS; do
    MIX="$MODPATH$(echo $OMIX | sed "s|^/vendor|/system/vendor|g")"
		patch_xml -u $MIX '/mixer/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/ctl[@name="COMP0 RX2"]' 0
		patch_xml -u $MIX '/mixer/ctl[@name="COMP1"]' 0
		patch_xml -u $MIX '/mixer/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/ctl[@name="RX_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/ctl[@name="HPHL_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/ctl[@name="HPHR_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="asr-mic"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="asr-mic"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="asr-mic"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="asr-mic"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="asr-mic"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="asr-mic"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="asr-mic"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="asr-mic"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/path[@name="asr-mic"]/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="asr-mic"]/ctl[@name="COMP0 RX2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="asr-mic"]/ctl[@name="COMP1"]' 0
		patch_xml -u $MIX '/mixer/path[@name="asr-mic"]/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="asr-mic"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="asr-mic"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="asr-mic"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="asr-mic"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="asr-mic"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="asr-mic"]/ctl[@name="RX_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="asr-mic"]/ctl[@name="HPHL_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="asr-mic"]/ctl[@name="HPHR_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc1"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc1"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc1"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc1"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc1"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc1"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc1"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc1"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/path[@name="adc1"]/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="adc1"]/ctl[@name="COMP0 RX2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc1"]/ctl[@name="COMP1"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc1"]/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc1"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc1"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc1"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc1"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc1"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc1"]/ctl[@name="RX_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc1"]/ctl[@name="HPHL_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc1"]/ctl[@name="HPHR_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc2"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc2"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc2"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc2"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc2"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc2"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc2"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc2"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/path[@name="adc2"]/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="adc2"]/ctl[@name="COMP0 RX2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc2"]/ctl[@name="COMP1"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc2"]/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc2"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc2"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc2"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc2"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc2"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc2"]/ctl[@name="RX_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc2"]/ctl[@name="HPHL_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc2"]/ctl[@name="HPHR_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc3"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc3"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc3"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc3"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc3"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc3"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc3"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc3"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/path[@name="adc3"]/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="adc3"]/ctl[@name="COMP0 RX2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc3"]/ctl[@name="COMP1"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc3"]/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc3"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc3"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc3"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc3"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc3"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc3"]/ctl[@name="RX_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc3"]/ctl[@name="HPHL_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="adc3"]/ctl[@name="HPHR_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="va-enroll-mic"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="va-enroll-mic"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="va-enroll-mic"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="va-enroll-mic"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="va-enroll-mic"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="va-enroll-mic"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="va-enroll-mic"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="va-enroll-mic"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/path[@name="va-enroll-mic"]/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="va-enroll-mic"]/ctl[@name="COMP0 RX2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="va-enroll-mic"]/ctl[@name="COMP1"]' 0
		patch_xml -u $MIX '/mixer/path[@name="va-enroll-mic"]/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="va-enroll-mic"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="va-enroll-mic"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="va-enroll-mic"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="va-enroll-mic"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="va-enroll-mic"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="va-enroll-mic"]/ctl[@name="RX_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="va-enroll-mic"]/ctl[@name="HPHL_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="va-enroll-mic"]/ctl[@name="HPHR_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-and-headphones"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-and-headphones"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-and-headphones"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-and-headphones"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-and-headphones"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-and-headphones"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-and-headphones"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-and-headphones"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-and-headphones"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-and-headphones"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/path[@name="speaker-and-headphones"]/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="speaker-and-headphones"]/ctl[@name="COMP0 RX2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-and-headphones"]/ctl[@name="COMP1"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-and-headphones"]/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-and-headphones"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-and-headphones"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-and-headphones"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-and-headphones"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-and-headphones"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-and-headphones"]/ctl[@name="RX_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-and-headphones"]/ctl[@name="HPHL_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-and-headphones"]/ctl[@name="HPHR_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/path[@name="speaker"]/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="speaker"]/ctl[@name="COMP0 RX2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker"]/ctl[@name="COMP1"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker"]/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker"]/ctl[@name="RX_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker"]/ctl[@name="HPHL_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker"]/ctl[@name="HPHR_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/path[@name="speaker-mono"]/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="speaker-mono"]/ctl[@name="COMP0 RX2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono"]/ctl[@name="COMP1"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono"]/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono"]/ctl[@name="RX_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono"]/ctl[@name="HPHL_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono"]/ctl[@name="HPHR_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono-2"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono-2"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono-2"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono-2"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono-2"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono-2"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono-2"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono-2"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/path[@name="speaker-mono-2"]/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="speaker-mono-2"]/ctl[@name="COMP0 RX2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono-2"]/ctl[@name="COMP1"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono-2"]/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono-2"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono-2"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono-2"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono-2"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono-2"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono-2"]/ctl[@name="RX_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono-2"]/ctl[@name="HPHL_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="speaker-mono-2"]/ctl[@name="HPHR_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="handset"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="handset"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="handset"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="handset"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="handset"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="handset"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="handset"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="handset"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/path[@name="handset"]/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="handset"]/ctl[@name="COMP0 RX2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="handset"]/ctl[@name="COMP1"]' 0
		patch_xml -u $MIX '/mixer/path[@name="handset"]/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="handset"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="handset"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="handset"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="handset"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="handset"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="handset"]/ctl[@name="RX_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="handset"]/ctl[@name="HPHL_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="handset"]/ctl[@name="HPHR_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/path[@name="headphones"]/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="headphones"]/ctl[@name="COMP0 RX2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="COMP1"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="RX_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="COMP0 RX1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="COMP0 RX2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="HPHL_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones"]/ctl[@name="HPHR_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="COMP0 RX2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="COMP1"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="RX_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="COMP0 RX1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="COMP0 RX2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="HPHL_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-ce"]/ctl[@name="HPHR_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="COMP0 RX2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="COMP1"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="RX_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="COMP0 RX1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="COMP0 RX2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="HPHL_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-no-ce"]/ctl[@name="HPHR_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-karaoke"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-karaoke"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-karaoke"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-karaoke"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-karaoke"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-karaoke"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-karaoke"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-karaoke"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/path[@name="headphones-karaoke"]/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="headphones-karaoke"]/ctl[@name="COMP0 RX2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-karaoke"]/ctl[@name="COMP1"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-karaoke"]/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-karaoke"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-karaoke"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-karaoke"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-karaoke"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-karaoke"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-karaoke"]/ctl[@name="RX_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-karaoke"]/ctl[@name="COMP0 RX1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-karaoke"]/ctl[@name="COMP0 RX2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-karaoke"]/ctl[@name="HPHL_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-karaoke"]/ctl[@name="HPHR_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-44.1"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-44.1"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-44.1"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-44.1"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-44.1"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-44.1"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-44.1"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-44.1"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/path[@name="headphones-44.1"]/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="headphones-44.1"]/ctl[@name="COMP0 RX2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-44.1"]/ctl[@name="COMP1"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-44.1"]/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-44.1"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-44.1"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-44.1"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-44.1"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-44.1"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-44.1"]/ctl[@name="RX_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-44.1"]/ctl[@name="HPHL_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-44.1"]/ctl[@name="HPHR_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-dsd"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-dsd"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-dsd"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-dsd"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-dsd"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-dsd"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-dsd"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-dsd"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/path[@name="headphones-dsd"]/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="headphones-dsd"]/ctl[@name="COMP0 RX2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-dsd"]/ctl[@name="COMP1"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-dsd"]/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-dsd"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-dsd"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-dsd"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-dsd"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-dsd"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-dsd"]/ctl[@name="RX_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-dsd"]/ctl[@name="HPHL_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-dsd"]/ctl[@name="HPHR_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-headphones"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-headphones"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-headphones"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-headphones"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-headphones"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-headphones"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-headphones"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-headphones"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/path[@name="anc-headphones"]/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="anc-headphones"]/ctl[@name="COMP0 RX2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-headphones"]/ctl[@name="COMP1"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-headphones"]/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-headphones"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-headphones"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-headphones"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-headphones"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-headphones"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-headphones"]/ctl[@name="RX_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-headphones"]/ctl[@name="HPHL_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-headphones"]/ctl[@name="HPHR_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-headphones"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-headphones"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-headphones"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-headphones"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-headphones"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-headphones"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-headphones"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-headphones"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/path[@name="voice-headphones"]/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="voice-headphones"]/ctl[@name="COMP0 RX2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-headphones"]/ctl[@name="COMP1"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-headphones"]/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-headphones"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-headphones"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-headphones"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-headphones"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-headphones"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-headphones"]/ctl[@name="RX_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-headphones"]/ctl[@name="HPHL_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-headphones"]/ctl[@name="HPHR_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="tty-headphones"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="tty-headphones"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="tty-headphones"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="tty-headphones"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="tty-headphones"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="tty-headphones"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="tty-headphones"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="tty-headphones"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/path[@name="tty-headphones"]/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="tty-headphones"]/ctl[@name="COMP0 RX2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="tty-headphones"]/ctl[@name="COMP1"]' 0
		patch_xml -u $MIX '/mixer/path[@name="tty-headphones"]/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="tty-headphones"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="tty-headphones"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="tty-headphones"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="tty-headphones"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="tty-headphones"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="tty-headphones"]/ctl[@name="RX_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="tty-headphones"]/ctl[@name="HPHL_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="tty-headphones"]/ctl[@name="HPHR_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="true-native-mode"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="true-native-mode"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="true-native-mode"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="true-native-mode"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="true-native-mode"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="true-native-mode"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="true-native-mode"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="true-native-mode"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/path[@name="true-native-mode"]/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="true-native-mode"]/ctl[@name="COMP0 RX2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="true-native-mode"]/ctl[@name="COMP1"]' 0
		patch_xml -u $MIX '/mixer/path[@name="true-native-mode"]/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="true-native-mode"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="true-native-mode"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="true-native-mode"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="true-native-mode"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="true-native-mode"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="true-native-mode"]/ctl[@name="RX_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="true-native-mode"]/ctl[@name="HPHL_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="true-native-mode"]/ctl[@name="HPHR_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-generic"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-generic"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-generic"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-generic"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-generic"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-generic"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-generic"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-generic"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/path[@name="headphones-generic"]/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="headphones-generic"]/ctl[@name="COMP0 RX2"]' 0
		patch_xml -s $MIX '/mixer/path[@name="headphones-generic"]/ctl[@name="COMP1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="headphones-generic"]/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-generic"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-generic"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-generic"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-generic"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-generic"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-generic"]/ctl[@name="RX_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-generic"]/ctl[@name="COMP0 RX1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-generic"]/ctl[@name="COMP0 RX2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-generic"]/ctl[@name="HPHL_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="headphones-generic"]/ctl[@name="HPHR_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-headphones"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-headphones"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-headphones"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-headphones"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-headphones"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-headphones"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-headphones"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-headphones"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/path[@name="voice-anc-headphones"]/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="voice-anc-headphones"]/ctl[@name="COMP0 RX2"]' 0
		patch_xml -s $MIX '/mixer/path[@name="voice-anc-headphones"]/ctl[@name="COMP1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="voice-anc-headphones"]/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-headphones"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-headphones"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-headphones"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-headphones"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-headphones"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-headphones"]/ctl[@name="RX_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-headphones"]/ctl[@name="COMP0 RX1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-headphones"]/ctl[@name="COMP0 RX2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-headphones"]/ctl[@name="HPHL_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-headphones"]/ctl[@name="HPHR_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-fb-headphones"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-fb-headphones"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-fb-headphones"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-fb-headphones"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-fb-headphones"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-fb-headphones"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-fb-headphones"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-fb-headphones"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/path[@name="voice-anc-fb-headphones"]/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="voice-anc-fb-headphones"]/ctl[@name="COMP0 RX2"]' 0
		patch_xml -s $MIX '/mixer/path[@name="voice-anc-fb-headphones"]/ctl[@name="COMP1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="voice-anc-fb-headphones"]/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-fb-headphones"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-fb-headphones"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-fb-headphones"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-fb-headphones"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-fb-headphones"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-fb-headphones"]/ctl[@name="RX_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-fb-headphones"]/ctl[@name="COMP0 RX1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-fb-headphones"]/ctl[@name="COMP0 RX2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-fb-headphones"]/ctl[@name="HPHL_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voice-anc-fb-headphones"]/ctl[@name="HPHR_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="aac-initial"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="aac-initial"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="aac-initial"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="aac-initial"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="aac-initial"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="aac-initial"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="aac-initial"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="aac-initial"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/path[@name="aac-initial"]/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="aac-initial"]/ctl[@name="COMP0 RX2"]' 0
		patch_xml -s $MIX '/mixer/path[@name="aac-initial"]/ctl[@name="COMP1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="aac-initial"]/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="aac-initial"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="aac-initial"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="aac-initial"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="aac-initial"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="aac-initial"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="aac-initial"]/ctl[@name="RX_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="aac-initial"]/ctl[@name="COMP0 RX1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="aac-initial"]/ctl[@name="COMP0 RX2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="aac-initial"]/ctl[@name="HPHL_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="aac-initial"]/ctl[@name="HPHR_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-on"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-on"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-on"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-on"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-on"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-on"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-on"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-on"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/path[@name="anc-on"]/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="anc-on"]/ctl[@name="COMP0 RX2"]' 0
		patch_xml -s $MIX '/mixer/path[@name="anc-on"]/ctl[@name="COMP1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="anc-on"]/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-on"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-on"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-on"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-on"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-on"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-on"]/ctl[@name="RX_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-on"]/ctl[@name="COMP0 RX1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-on"]/ctl[@name="COMP0 RX2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-on"]/ctl[@name="HPHL_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-on"]/ctl[@name="HPHR_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc2-on"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc2-on"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc2-on"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc2-on"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc2-on"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc2-on"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc2-on"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc2-on"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/path[@name="anc2-on"]/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="anc2-on"]/ctl[@name="COMP0 RX2"]' 0
		patch_xml -s $MIX '/mixer/path[@name="anc2-on"]/ctl[@name="COMP1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="anc2-on"]/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc2-on"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc2-on"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc2-on"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc2-on"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc2-on"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc2-on"]/ctl[@name="RX_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc2-on"]/ctl[@name="COMP0 RX1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc2-on"]/ctl[@name="COMP0 RX2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc2-on"]/ctl[@name="HPHL_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc2-on"]/ctl[@name="HPHR_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphones"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphones"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphones"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphones"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphones"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphones"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphones"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphones"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/path[@name="anc-off-headphones"]/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="anc-off-headphones"]/ctl[@name="COMP0 RX2"]' 0
		patch_xml -s $MIX '/mixer/path[@name="anc-off-headphones"]/ctl[@name="COMP1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="anc-off-headphones"]/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphones"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphones"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphones"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphones"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphones"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphones"]/ctl[@name="RX_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphones"]/ctl[@name="COMP0 RX1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphones"]/ctl[@name="COMP0 RX2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphones"]/ctl[@name="HPHL_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphones"]/ctl[@name="HPHR_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphone-combo"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphone-combo"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphone-combo"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphone-combo"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphone-combo"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphone-combo"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphone-combo"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphone-combo"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/path[@name="anc-off-headphone-combo"]/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="anc-off-headphone-combo"]/ctl[@name="COMP0 RX2"]' 0
		patch_xml -s $MIX '/mixer/path[@name="anc-off-headphone-combo"]/ctl[@name="COMP1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="anc-off-headphone-combo"]/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphone-combo"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphone-combo"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphone-combo"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphone-combo"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphone-combo"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphone-combo"]/ctl[@name="RX_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphone-combo"]/ctl[@name="COMP0 RX1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphone-combo"]/ctl[@name="COMP0 RX2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphone-combo"]/ctl[@name="HPHL_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="anc-off-headphone-combo"]/ctl[@name="HPHR_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voiceanc-headphone"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voiceanc-headphone"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voiceanc-headphone"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voiceanc-headphone"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voiceanc-headphone"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voiceanc-headphone"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voiceanc-headphone"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voiceanc-headphone"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/path[@name="voiceanc-headphone"]/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="voiceanc-headphone"]/ctl[@name="COMP0 RX2"]' 0
		patch_xml -s $MIX '/mixer/path[@name="voiceanc-headphone"]/ctl[@name="COMP1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="voiceanc-headphone"]/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voiceanc-headphone"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voiceanc-headphone"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voiceanc-headphone"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voiceanc-headphone"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voiceanc-headphone"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voiceanc-headphone"]/ctl[@name="RX_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voiceanc-headphone"]/ctl[@name="COMP0 RX1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voiceanc-headphone"]/ctl[@name="COMP0 RX2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voiceanc-headphone"]/ctl[@name="HPHL_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="voiceanc-headphone"]/ctl[@name="HPHR_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="ADSP testfwk"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="ADSP testfwk"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="ADSP testfwk"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="ADSP testfwk"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="ADSP testfwk"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="ADSP testfwk"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="ADSP testfwk"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="ADSP testfwk"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/path[@name="ADSP testfwk"]/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="ADSP testfwk"]/ctl[@name="COMP0 RX2"]' 0
		patch_xml -s $MIX '/mixer/path[@name="ADSP testfwk"]/ctl[@name="COMP1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="ADSP testfwk"]/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="ADSP testfwk"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="ADSP testfwk"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="ADSP testfwk"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="ADSP testfwk"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="ADSP testfwk"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="ADSP testfwk"]/ctl[@name="RX_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="ADSP testfwk"]/ctl[@name="COMP0 RX1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="ADSP testfwk"]/ctl[@name="COMP0 RX2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="ADSP testfwk"]/ctl[@name="HPHL_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="ADSP testfwk"]/ctl[@name="HPHR_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="COMP0 RX2"]' 0
		patch_xml -s $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="COMP1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="RX_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="COMP0 RX1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="COMP0 RX2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="HPHL_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="bt-a2dp"]/ctl[@name="HPHR_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback headphones"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback headphones"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback headphones"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback headphones"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback headphones"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback headphones"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback headphones"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback headphones"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/path[@name="deep-buffer-playback headphones"]/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="deep-buffer-playback headphones"]/ctl[@name="COMP0 RX2"]' 0
		patch_xml -s $MIX '/mixer/path[@name="deep-buffer-playback headphones"]/ctl[@name="COMP1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="deep-buffer-playback headphones"]/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback headphones"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback headphones"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback headphones"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback headphones"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback headphones"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback headphones"]/ctl[@name="RX_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback headphones"]/ctl[@name="COMP0 RX1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback headphones"]/ctl[@name="COMP0 RX2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback headphones"]/ctl[@name="HPHL_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="deep-buffer-playback headphones"]/ctl[@name="HPHR_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/path[@name="low-latency-playback"]/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="low-latency-playback"]/ctl[@name="COMP0 RX2"]' 0
		patch_xml -s $MIX '/mixer/path[@name="low-latency-playback"]/ctl[@name="COMP1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="low-latency-playback"]/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback"]/ctl[@name="RX_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback"]/ctl[@name="COMP0 RX1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback"]/ctl[@name="COMP0 RX2 Switch"]' 0	
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback"]/ctl[@name="HPHL_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback"]/ctl[@name="HPHR_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback headphones"]/ctl[@name="COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback headphones"]/ctl[@name="COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback headphones"]/ctl[@name="COMP3 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback headphones"]/ctl[@name="COMP4 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback headphones"]/ctl[@name="COMP5 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback headphones"]/ctl[@name="COMP6 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback headphones"]/ctl[@name="COMP7 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback headphones"]/ctl[@name="COMP8 Switch"]' 0
		patch_xml -s $MIX '/mixer/path[@name="low-latency-playback headphones"]/ctl[@name="COMP0 RX1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="low-latency-playback headphones"]/ctl[@name="COMP0 RX2"]' 0
		patch_xml -s $MIX '/mixer/path[@name="low-latency-playback headphones"]/ctl[@name="COMP1"]' 0
		patch_xml -s $MIX '/mixer/path[@name="low-latency-playback headphones"]/ctl[@name="COMP2"]' 0
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback headphones"]/ctl[@name="SpkrLeft COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback headphones"]/ctl[@name="SpkrRight COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback headphones"]/ctl[@name="WSA_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback headphones"]/ctl[@name="WSA_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback headphones"]/ctl[@name="RX_COMP1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback headphones"]/ctl[@name="RX_COMP2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback headphones"]/ctl[@name="COMP0 RX1 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback headphones"]/ctl[@name="COMP0 RX2 Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback headphones"]/ctl[@name="HPHL_COMP Switch"]' 0
		patch_xml -u $MIX '/mixer/path[@name="low-latency-playback headphones"]/ctl[@name="HPHR_COMP Switch"]' 0
		patch_xml -s $MIX '/mixer/ctl[@name="Compress Playback 16 Volume"]' 0
		patch_xml -s $MIX '/mixer/ctl[@name="Compress Playback 15 Volume"]' 0
		patch_xml -s $MIX '/mixer/ctl[@name="Compress Playback 29 Volume"]' 0
		patch_xml -s $MIX '/mixer/ctl[@name="Compress Playback 30 Volume"]' 0
		patch_xml -s $MIX '/mixer/ctl[@name="Compress Playback 31 Volume"]' 0
		patch_xml -s $MIX '/mixer/ctl[@name="Compress Playback 32 Volume"]' 0
        patch_xml -s $MIX '/mixer/ctl[@name="Compress Playback 41 Volume"]' 0
        patch_xml -s $MIX '/mixer/ctl[@name="Compress Playback 42 Volume"]' 0
        patch_xml -s $MIX '/mixer/ctl[@name="Compress Playback 43 Volume"]' 0
        patch_xml -s $MIX '/mixer/ctl[@name="Compress Playback 44 Volume"]' 0
        patch_xml -s $MIX '/mixer/ctl[@name="Compress Playback 45 Volume"]' 0
	done
}

audio_codec() {
if find $SYSTEM $VENDOR -type f -name "audio_configs*.xml" >/dev/null; then
	for OACONF in $ACONFS; do
	ACONF="$MODPATH$(echo $OACONF | sed "s|^/vendor|/system/vendor|g")"
		patch_xml -u $ACONF '/configs/property[@name="audio.offload.disable"]' "false"
		patch_xml -u $ACONF '/configs/property[@name="audio.offload.min.duration.secs"]' "30"
		patch_xml -u $ACONF '/configs/property[@name="persist.vendor.audio.sva.conc.enabled"]' "false"
		patch_xml -u $ACONF '/configs/property[@name="persist.vendor.audio.va_concurrency_enabled"]' "false"
		patch_xml -u $ACONF '/configs/property[@name="vendor.audio.av.streaming.offload.enable"]' "false"
		patch_xml -u $ACONF '/configs/property[@name="vendor.audio.offload.track.enable"]' "true"
		patch_xml -u $ACONF '/configs/property[@name="vendor.audio.offload.multiple.enabled"]' "false"
		patch_xml -u $ACONF '/configs/property[@name="vendor.audio.rec.playback.conc.disabled"]' "false"
		patch_xml -u $ACONF '/configs/property[@name="vendor.voice.conc.fallbackpath"]' ""
		patch_xml -u $ACONF '/configs/property[@name="vendor.voice.dsd.playback.conc.disabled"]' "true"
		patch_xml -u $ACONF '/configs/property[@name="vendor.voice.path.for.pcm.voip"]' "true"
		patch_xml -u $ACONF '/configs/property[@name="vendor.voice.playback.conc.disabled"]' "false"
		patch_xml -u $ACONF '/configs/property[@name="vendor.voice.record.conc.disabled"]' "false"
		patch_xml -u $ACONF '/configs/property[@name="vendor.voice.voip.conc.disabled"]' "false"
		patch_xml -u $ACONF '/configs/property[@name="audio_extn_formats_enabled"]' "true"
		patch_xml -u $ACONF '/configs/property[@name="audio_extn_hdmi_spk_enabled"]' "true"
		patch_xml -u $ACONF '/configs/property[@name="use_xml_audio_policy_conf"]' "true"
		patch_xml -u $ACONF '/configs/property[@name="voice_concurrency"]' "false "
		patch_xml -u $ACONF '/configs/property[@name="afe_proxy_enabled"]' "false"
		patch_xml -u $ACONF '/configs/property[@name="compress_voip_enabled"]' "false"
		patch_xml -u $ACONF '/configs/property[@name="fm_power_opt"]' "true"
		patch_xml -u $ACONF '/configs/property[@name="record_play_concurrency"]' "false"
		patch_xml -u $ACONF '/configs/property[@name="vendor.audio.use.sw.alac.decoder"]' "true"
		patch_xml -u $ACONF '/configs/property[@name="vendor.audio.use.sw.ape.decoder"]' "true"
		patch_xml -u $ACONF '/configs/property[@name="vendor.audio.use.sw.mpegh.decoder"]' "false"
		patch_xml -u $ACONF '/configs/property[@name="vendor.audio.flac.sw.decoder.24bit"]' "true"
		patch_xml -u $ACONF '/configs/property[@name="vendor.audio.hw.aac.encoder"]' "false"
		patch_xml -u $ACONF '/configs/property[@name="aac_adts_offload_enabled"]' "true"
		patch_xml -u $ACONF '/configs/property[@name="alac_offload_enabled"]' "true"
		patch_xml -u $ACONF '/configs/property[@name="ape_offload_enabled"]' "true"
		patch_xml -u $ACONF '/configs/property[@name="flac_offload_enabled"]' "true"
		patch_xml -u $ACONF '/configs/property[@name="pcm_offload_enabled_16"]' "false "
		patch_xml -u $ACONF '/configs/property[@name="pcm_offload_enabled_24"]' "false "
		patch_xml -u $ACONF '/configs/property[@name="qti_flac_decoder"]' "true"
		patch_xml -u $ACONF '/configs/property[@name="vorbis_offload_enabled"]' "true"
		patch_xml -u $ACONF '/configs/property[@name="wma_offload_enabled"]' "true"
	done
fi
}

device_features_system() {
	for ODEVFEA in $DEVFEA; do 
	DEVFEA="$MODPATH$(echo $ODEVFEA | sed "s|^/vendor|/system/vendor|g")"
	mkdir -p `dirname $DEVFEA`
	cp -f $MAGISKMIRROR$ODEVFEA $DEVFEA
	sed -i 's/\t/  /g' $DEVFEA
		patch_xml -s $DEVFEA '/features/bool[@name="support_a2dp_latency"]' "true"
		patch_xml -s $DEVFEA '/features/bool[@name="support_samplerate_48000"]' "true"
		patch_xml -s $DEVFEA '/features/bool[@name="support_samplerate_96000"]' "true"
		patch_xml -s $DEVFEA '/features/bool[@name="support_samplerate_192000"]' "true"
		patch_xml -s $DEVFEA '/features/bool[@name="support_low_latency"]' "true"
		patch_xml -s $DEVFEA '/features/bool[@name="support_mid_latency"]' "false"
		patch_xml -s $DEVFEA '/features/bool[@name="support_high_latency"]' "false"
		patch_xml -s $DEVFEA '/features/bool[@name="support_interview_record_param"]' "false"
	done
}

device_features_vendor() {
	for ODEVFEAA in $DEVFEAA; do 
	DEVFEAA="$MODPATH$(echo $ODEVFEAA | sed "s|^/vendor|/system/vendor|g")"
	mkdir -p `dirname $DEVFEAA`
	cp -f $MAGISKMIRROR$ODEVFEAA $DEVFEAA
	sed -i 's/\t/  /g' $DEVFEAA
		patch_xml -s $DEVFEAA '/features/bool[@name="support_a2dp_latency"]' "true"
		patch_xml -s $DEVFEAA '/features/bool[@name="support_samplerate_48000"]' "true"
		patch_xml -s $DEVFEAA '/features/bool[@name="support_samplerate_96000"]' "true"
		patch_xml -s $DEVFEAA '/features/bool[@name="support_samplerate_192000"]' "true"
		patch_xml -s $DEVFEAA '/features/bool[@name="support_low_latency"]' "true"
		patch_xml -s $DEVFEAA '/features/bool[@name="support_mid_latency"]' "false"
		patch_xml -s $DEVFEAA '/features/bool[@name="support_high_latency"]' "false"
		patch_xml -s $DEVFEAA '/features/bool[@name="support_interview_record_param"]' "false"
		patch_xml -s $DEVFEAA '/features/bool[@name="support_voip_record"]' "true"
		patch_xml -s $DEVFEAA '/features/integer[@name="support_inner_record"]' "1"
		patch_xml -s $DEVFEAA '/features/bool[@name="support_hifi"]' "true"
	done
}

dirac() {
	for OFILE in $AECFGS; do
	FILE="$MODPATH$(echo $OFILE | sed "s|^/vendor|/system/vendor|g")"
	mkdir -p `dirname $FILE`
	cp -f $MAGISKMIRROR$OFILE $FILE
		altmemes_confxml $FILE
		memes_confxml "dirac_gef" "$MODID" "$DYNLIBPATCH\/lib\/soundfx" "libdiraceffect.so" "3799D6D1-22C5-43C3-B3EC-D664CF8D2F0D"
		effects_patching -post "$FILE" "music" "dirac_gef"
	done
	mkdir -p $MODPATH$SYSTEM/vendor/etc/dirac $MODPATH$SYSTEM/vendor/lib/rfsa/adsp $MODPATH$SYSTEM/vendor/lib/soundfx
	cp -f $NEWdirac/diracvdd.bin $MODPATH$SYSTEM/vendor/etc/
	cp -f $NEWdirac/interfacedb $MODPATH$SYSTEM/vendor/etc/dirac
	cp -f $NEWdirac/dirac_resource.dar $MODPATH$SYSTEM/vendor/lib/rfsa/adsp
	cp -f $NEWdirac/dirac.so $MODPATH$SYSTEM/vendor/lib/rfsa/adsp
	cp -f $NEWdirac/libdirac-capiv2.so $MODPATH$SYSTEM/vendor/lib/rfsa/adsp
	cp -f $NEWdirac/libdiraceffect.so $MODPATH$SYSTEM/vendor/lib/soundfx
echo -e "\n# Patch dirac
persist.dirac.acs.controller=gef
persist.dirac.gef.oppo.syss=true
persist.dirac.config=64
persist.dirac.gef.exs.did=50,50
persist.dirac.gef.ext.did=500,500,500,500
persist.dirac.gef.ins.did=0,0,0
persist.dirac.gef.int.did=0,0,0,0
persist.dirac.gef.ext.appt=0x00011130,0x00011134,0x00011136
persist.dirac.gef.exs.appt=0x00011130,0x00011131
persist.dirac.gef.int.appt=0x00011130,0x00011134,0x00011136
persist.dirac.gef.ins.appt=0x00011130,0x00011131
persist.dirac.gef.exs.mid=268512739
persist.dirac.gef.ext.mid=268512737
persist.dirac.gef.ins.mid=268512738
persist.dirac.gef.int.mid=268512736
persist.dirac.path=/vendor/etc/dirac
ro.dirac.acs.storeSettings=1
persist.dirac.acs.ignore_error=1
ro.audio.soundfx.dirac=true
ro.vendor.audio.soundfx.type=dirac
persist.audio.dirac.speaker=true" >> $MODPATH/system.prop
} 

mixer() {
	for OMIX in $MPATHS; do
	MIX="$MODPATH$(echo $OMIX | sed "s|^/vendor|/system/vendor|g")"
	if $HIFI; then
		patch_xml -u $MIX '/mixer/ctl[@name="RX HPH Mode"]' "CLS_H_HIFI"
		patch_xml -u $MIX '/mixer/ctl[@name="RX_HPH_PWR_MODE"]' "LOHIFI"
		patch_xml -s $MIX '/mixer/ctl[@name="RX1 HPF cut off"]' "CF_NEG_3DB_4HZ"
		patch_xml -s $MIX '/mixer/ctl[@name="RX2 HPF cut off"]' "CF_NEG_3DB_4HZ"
		patch_xml -s $MIX '/mixer/ctl[@name="RX3 HPF cut off"]' "CF_NEG_3DB_4HZ"
		patch_xml -s $MIX '/mixer/ctl[@name="RX4 HPF cut off"]' "CF_NEG_3DB_4HZ"
		patch_xml -s $MIX '/mixer/ctl[@name="RX5 HPF cut off"]' "CF_NEG_3DB_4HZ"
		patch_xml -s $MIX '/mixer/ctl[@name="TX1 HPF cut off"]' "CF_NEG_3DB_4HZ"
		patch_xml -s $MIX '/mixer/ctl[@name="TX2 HPF cut off"]' "CF_NEG_3DB_4HZ"
		patch_xml -s $MIX '/mixer/ctl[@name="TX3 HPF cut off"]' "CF_NEG_3DB_4HZ"
		patch_xml -s $MIX '/mixer/ctl[@name="TX4 HPF cut off"]' "CF_NEG_3DB_4HZ"
		patch_xml -s $MIX '/mixer/ctl[@name="TX5 HPF cut off"]' "CF_NEG_3DB_4HZ"
	else
		patch_xml -u $MIX '/mixer/ctl[@name="RX HPH Mode"]' "HD2"
		patch_xml -u $MIX '/mixer/ctl[@name="RX HPH HD2 Mode"]' "On"
		patch_xml -s $MIX '/mixer/ctl[@name="RX1 HPF cut off"]' "MIN_3DB_4Hz"
		patch_xml -s $MIX '/mixer/ctl[@name="RX2 HPF cut off"]' "MIN_3DB_4Hz"
		patch_xml -s $MIX '/mixer/ctl[@name="RX3 HPF cut off"]' "MIN_3DB_4Hz"
		patch_xml -s $MIX '/mixer/ctl[@name="RX4 HPF cut off"]' "MIN_3DB_4Hz"
		patch_xml -s $MIX '/mixer/ctl[@name="RX5 HPF cut off"]' "MIN_3DB_4Hz"
		patch_xml -s $MIX '/mixer/ctl[@name="TX1 HPF cut off"]' "MIN_3DB_4Hz"
		patch_xml -s $MIX '/mixer/ctl[@name="TX2 HPF cut off"]' "MIN_3DB_4Hz"
		patch_xml -s $MIX '/mixer/ctl[@name="TX3 HPF cut off"]' "MIN_3DB_4Hz"
		patch_xml -s $MIX '/mixer/ctl[@name="TX4 HPF cut off"]' "MIN_3DB_4Hz"
		patch_xml -s $MIX '/mixer/ctl[@name="TX5 HPF cut off"]' "MIN_3DB_4Hz"
	fi
	if [ "$RN5PRO" ] || [ "$MI9" ] || [ "$MI8" ] || [ "$MI8P" ] || [ "$MI9P" ] || [ "$MIA2" ]; then
		patch_xml -s $MIX '/mixer/ctl[@name="TAS2557 ClassD Edge"]' "7"
		patch_xml -s $MIX '/mixer/ctl[@name="TAS2557 Volume"]' "30"
		echo -e '\nro.sound.alsa=TAS2557' >> $MODPATH/system.prop
	fi
		patch_xml -s $MIX '/mixer/ctl[@name="headphones]/ctl[@name="PowerCtrl"]' "0"
		patch_xml -s $MIX '/mixer/ctl[@name="TFA Profile"]' "speaker"
		patch_xml -u $MIX '/mixer/ctl[@name="RX INT1 MIX3 DSD HPHL Switch"]' "1"
		patch_xml -u $MIX '/mixer/ctl[@name="RX INT2 MIX3 DSD HPHR Switch"]' "1"
		patch_xml -s $MIX '/mixer/ctl[@name="HiFi Function"]' "On"
		patch_xml -s $MIX '/mixer/ctl[@name="HiFi Filter"]' "1"
		patch_xml -u $MIX '/mixer/ctl[@name="Adsp Working Mode"]' "full"
		patch_xml -s $MIX '/mixer/ctl[@name="Adsp Working Mode"]' "full"
		patch_xml -s $MIX '/mixer/ctl[@name="TFA987X_ALGO_STATUS"]' "ENABLE"
		patch_xml -s $MIX '/mixer/ctl[@name="TFA987X_TX_ENABLE"]' "ENABLE"
		patch_xml -s $MIX '/mixer/ctl[@name="Amp DSP Enable"]' "1" 
		patch_xml -s $MIX '/mixer/ctl[@name="BDE AMP Enable"]' "1"
		patch_xml -s $MIX '/mixer/ctl[@name="Amp Volume Location"]' "1"
		patch_xml -s $MIX '/mixer/ctl[@name="A2DP_SLIM7_UL_HL Switch"]' "1"
		patch_xml -s $MIX '/mixer/ctl[@name="SLIM7_RX_DL_HL Switch"]' "1"
		patch_xml -s $MIX '/mixer/ctl[@name="Ext Spk Boost"]' "ENABLE"
		patch_xml -s $MIX '/mixer/ctl[@name="PowerCtrl"]' "0"
        patch_xml -s $MIX '/mixer/ctl[@name="RCV AMP PCM Gain"]' "20"
        patch_xml -s $MIX '/mixer/ctl[@name="AMP PCM Gain"]' "20"
        patch_xml -s $MIX '/mixer/ctl[@name="RCV Boost Target Voltage"]' "170"
        patch_xml -s $MIX '/mixer/ctl[@name="Boost Target Voltage"]' "170"
		patch_xml -s $MIX '/mixer/ctl[@name="MultiMedia1 EQ Enable"]' "Off"
		patch_xml -s $MIX '/mixer/ctl[@name="MultiMedia2 EQ Enable"]' "Off"
		patch_xml -s $MIX '/mixer/ctl[@name="MultiMedia3 EQ Enable"]' "Off"
		if ["$POCOX3"]; then
			patch_xml -u $MIX '/mixer/ctl[@name="TAS256X PLAYBACK VOLUME LEFT"]' "56"
			patch_xml -u $MIX '/mixer/ctl[@name="TAS256X LIM MAX ATTN LEFT"]' "0"
			patch_xml -u $MIX '/mixer/ctl[@name="TAS256X LIM INFLECTION POINT LEFT"]' "0"
			patch_xml -u $MIX '/mixer/ctl[@name="TAS256X LIM ATTACT RATE LEFT"]' "0"
			patch_xml -u $MIX '/mixer/ctl[@name="TAS256X LIM RELEASE RATE LEFT"]' "7"
			patch_xml -u $MIX '/mixer/ctl[@name="TAS256X LIM ATTACK STEP LEFT"]' "0"
			patch_xml -u $MIX '/mixer/ctl[@name="TAS256X LIM RELEASE STEP LEFT"]' "3"
			patch_xml -u $MIX '/mixer/ctl[@name="TAS256X RX MODE LEFT"]' "Receiver"
			patch_xml -u $MIX '/mixer/ctl[@name="TAS256X BOOST VOLTAGE LEFT"]' "15"
			patch_xml -u $MIX '/mixer/ctl[@name="TAS256X BOOST CURRENT LEFT"]' "63"
			patch_xml -u $MIX '/mixer/ctl[@name="TAS256X PLAYBACK VOLUME RIGHT"]' "56"
			patch_xml -u $MIX '/mixer/ctl[@name="TAS256X LIM MAX ATTN RIGHT"]' "0"
			patch_xml -u $MIX '/mixer/ctl[@name="TAS256X LIM INFLECTION POINT RIGHT"]' "0"
			patch_xml -u $MIX '/mixer/ctl[@name="TAS256X LIM ATTACT RATE RIGHT"]' "0"
			patch_xml -u $MIX '/mixer/ctl[@name="TAS256X LIM RELEASE RATE RIGHT"]' "7"
			patch_xml -u $MIX '/mixer/ctl[@name="TAS256X LIM ATTACK STEP RIGHT"]' "0"
			patch_xml -u $MIX '/mixer/ctl[@name="TAS256X LIM RELEASE STEP RIGHT"]' "3"
			patch_xml -u $MIX '/mixer/ctl[@name="TAS256X BOOST VOLTAGE RIGHT"]' "12"
			patch_xml -u $MIX '/mixer/ctl[@name="TAS256X BOOST CURRENT RIGHT"]' "55"
			patch_xml -u $MIX '/mixer/ctl[@name="TAS256X VBAT LPF LEFT"]' "DISABLE"
			patch_xml -u $MIX '/mixer/ctl[@name="TAS256X VBAT LPF RIGHT"]' "DISABLE"
			patch_xml -u $MIX '/mixer/ctl[@name="TAS256x Profile id"]' "1"
			patch_xml -u $MIX '/mixer/ctl[@name="TAS25XX_SMARTPA_ENABLE"]' "ENABLE"
			patch_xml -u $MIX '/mixer/ctl[@name="Amp Output Level"]' "2"
			patch_xml -u $MIX '/mixer/ctl[@name="TAS25XX_ALGO_PROFILE"]' "MUSIC" 
		fi
	done
}

io_policy(){
	for OIOPOLICY in $IOPOLICY; do
	IOPOLICY="$MODPATH$(echo $OIOPOLICY | sed "s|^/vendor|/system/vendor|g")"
	mkdir -p `dirname $IOPOLICY`
	cp -f $MAGISKMIRROR$OIOPOLICY $IOPOLICY
	sed -i 's/AUDIO_OUTPUT_FLAG_DIRECT/AUDIO_OUTPUT_FLAG_DIRECT_PCM/g' $IOPOLICY
	sed -i 's/AUDIO_OUTPUT_FLAG_DIRECT_PCM_PCM/AUDIO_OUTPUT_FLAG_DIRECT_PCM/g' $IOPOLICY
	done
	}

audio_policy() {
	for OAUDIOPOLICY in $AUDIOPOLICY; do
	AUDIOPOLICY="$MODPATH$(echo $OAUDIOPOLICY | sed "s|^/vendor|/system/vendor|g")"
	mkdir -p `dirname $AUDIOPOLICY`
	cp -f $MAGISKMIRROR$OAUDIOPOLICY $AUDIOPOLICY
	sed -i 's/speaker_drc_enabled="true"/speaker_drc_enabled="false"/g' $AUDIOPOLICY
	done
}

clear_screen() {
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
	ui_print " "
}

prop() {
echo -e "\n#
persist.vendor.audio.spv4.enable=true
persist.vendor.audio.avs.afe_api_version=9
ro.vendor.audio.spk.clean=false
ro.vendor.audio.surround.support=false
ro.vendor.audio.scenario.support=false

ro.mediacodec.min_sample_rate=7350
ro.mediacodec.max_sample_rate=2822400
vendor.audio.flac.sw.decoder.24bit=true
vendor.audio.aac.sw.decoder.24bit=true
vendor.audio.use.sw.alac.decoder=true
flac.sw.decoder.24bit.support=true
vendor.audio.flac.sw.encoder.24bit=true
vendor.audio.aac.sw.encoder.24bit=true
vendor.audio.use.sw.ape.decoder=true
vendor.audio.vorbis.complexity.default=8
vendor.audio.vorbis.quality=100
vendor.audio.aac.complexity.default=8
vendor.audio.aac.quality=100
vendor.audio.tunnel.encode=true
tunnel.audio.encode=true
qc.tunnel.audio.encode=true
audio.decoder_override_check=true
mpq.audio.decode=true
audio.nat.codec.enabled=1
use.non-omx.mp3.decoder=false
use.non-omx.aac.decoder=false
use.non-omx.flac.decoder=false

media.stagefright.enable-player=true
media.stagefright.enable-http=true
media.stagefright.enable-aac=true
media.stagefright.enable-qcp=true
media.stagefright.enable-fma2dp=true
media.stagefright.enable-scan=true
media.stagefright.audio.sink=128
media.stagefright.thumbnail.prefer_hw_codecs=true
mmp.enable.3g2=true
media.aac_51_output_enabled=true
mm.enable.smoothstreaming=true
vendor.audio.parser.ip.buffer.size=262144
vendor.mm.enable.qcom_parser=63963135
persist.mm.enable.prefetch=true

av.offload.enable=true
vendor.av.offload.enable=true
qc.av.offload.enable=true
audio.offload.buffer.size.kb=32
vendor.audio.offload.buffer.size.kb=32
vendor.audio.offload.multiaac.enable=true

lpa.decode=false
lpa30.decode=false
lpa.use-stagefright=false
lpa.releaselock=false

af.thread.throttle=0
af.fast.track.multiplier=2
ro.af.client_heap_size_kbyte=7168

vendor.audio_hal.in_period_size=144
vendor.audio_hal.period_multiplier=3 
vendor.audio.hal.output.suspend.supported=true

audio.playback.mch.downsample=false
ro.vendor.audio.playbackScene=true
vendor.audio.playback.dsp.pathdelay=0
vendor.audio.playback.mch.downsample=false
persist.vendor.audio.playback.mch.downsample=false

vendor.audio.feature.external_dsp.enable=true
vendor.audio.feature.external_speaker.enable=true
vendor.audio.feature.external_speaker_tfa.enable=true
vendor.audio.feature.ext_hw_plugin=true
vendor.audio.feature.ras.enable=false
vendor.audio.feature.afe_proxy.enable=true
vendor.audio.feature.src_trkn.enable=true
vendor.audio.feature.spkr_prot.enable=true
vendor.audio.feature.kpi_optimize.enable=true
vendor.audio.feature.power_mode.enable=true 
vendor.audio.feature.compress_meta_data.enable=false
vendor.audio.feature.compr_cap.enable=false
vendor.audio.feature.ssrec.enable=true
vendor.audio.feature.dynamic_ecns.enable=true
vendor.audio.feature.concurrent_capture.enable=true
vendor.audio.feature.snd_mon.enable=true
vendor.audio.feature.deepbuffer_as_primary.enable=false
vendor.audio.feature.devicestate_listener.enable=false
vendor.audio.feature.thermal_listener.enable=false
vendor.audio.feature.hifi_audio.enable=true

ro.hardware.hifi.support=true
ro.audio.hifi=true
ro.vendor.audio.hifi=true
persist.audio.hifi=true
persist.audio.hifi.volume=72
persist.audio.hifi.int_codec=true
persist.vendor.audio.hifi=true
persist.vendor.audio.hifi.int_codec=true

effect.reverb.pcm=1
vendor.audio.safx.pbe.enabled=true
vendor.audio.soundfx.usb=false
vendor.audio.keep_alive.disabled=false
ro.vendor.audio.3d.audio.support=true
ro.vendor.audio.soundfx.usb=false
ro.vendor.audio.sfx.speaker=false
ro.vendor.audio.sfx.earadj=false
ro.vendor.audio.sfx.scenario=false
ro.vendor.audio.sfx.audiovisual=false
ro.vendor.audio.sfx.independentequalizer=false
ro.vendor.audio.surround.support=true
ro.vendor.audio.vocal.support=true
ro.vendor.audio.voice.change.support=true
ro.vendor.audio.voice.change.youme.support=true
persist.vendor.audio.ambisonic.capture=true
persist.vendor.audio.ambisonic.auto.profile=true
persist.vendor.audio.misound.disable=true

vendor.audio.hdr.record.enable=true
vendor.audio.3daudio.record.enable=true
ro.qc.sdk.audio.ssr=false
ro.vendor.audio.sdk.ssr=false
ro.vendor.audio.afe.record=false
ro.vendor.audio.recording.hd=true
ro.ril.enable.amr.wideband=1
persist.audio.lowlatency.rec=true

vendor.power.pasr.enabled=true
vendor.audio.matrix.limiter.enable=0
vendor.audio.enable.mirrorlink=false
vendor.audio.capture.enforce_legacy_copp_sr=true
vendor.audio.snd_card.open.retries=50
vendor.audio.volume.headset.gain.depcal=true
vendor.audio.tfa9874.dsp.enabled=true
vendor.audio.spkr_prot.tx.sampling_rate=48000
ro.audio.soundtrigger.lowpower=false
ro.vendor.audio.soundtrigger.adjconf=true
ro.vendor.audio.game.mode=true
ro.vendor.audio.game.vibrate=true
ro.vendor.audio.sos=true
ro.vendor.audio.multiroute=true
ro.vendor.audio.enhance.support=true
ro.vendor.audio.gain.support=true
persist.vendor.audio.ha_proxy.enabled=true
persist.vendor.audio.ll_playback_bargein=true
persist.vendor.audio.bcl.enabled=false
persist.vendor.audio.hw.binder.size_kbyte=1024
persist.vendor.audio.format.24bit=true
persist.vendor.audio.delta.refresh=true" >> $MODPATH/system.prop
}

improve_bluetooth() {
echo -e "\n# Bluetooth

qcom.hw.aac.encoder=true
audio.effect.a2dp.enable=1
vendor.audio.effect.a2dp.enable=1
vendor.audio.hw.aac.encoder=true
vendor.bt.pts.pbap=true
ro.bluetooth.emb_wp_mode=false
ro.bluetooth.wipower=false 
ro.vendor.bluetooth.wipower=false
persist.service.btui.use_aptx=1
persist.bt.enableAptXHD=true
persist.bt.a2dp.aptx_disable=false
persist.bt.a2dp.aptx_hd_disable=false
persist.bt.a2dp.aac_disable=false
persist.bt.sbc_hd_enabled=1
persist.vendor.btstack.enable.splita2dp=true
persist.vendor.btstack.connect.peer_earbud=true
persist.vendor.btstack.enable.twsplussho=true
persist.vendor.btstack.enable.swb=true
persist.vendor.btstack.enable.swbpm=true
persist.vendor.btstack.enable.lpa=false
persist.vendor.btstack.avrcp.pos_time=1000
persist.vendor.bt.a2dp.aac_whitelist=false
persist.vendor.bt.a2dp.addr_check_enabled_for_aac=true
persist.vendor.bt.aac_frm_ctl.enabled=true
persist.vendor.bt.aac_vbr_frm_ctl.enabled=true
persist.vendor.qcom.bluetooth.aac_frm_ctl.enabled=true
persist.vendor.qcom.bluetooth.enable.splita2dp=true 
persist.vendor.qcom.bluetooth.twsp_state.enabled=false
persist.vendor.qcom.bluetooth.a2dp_mcast_test.enabled=false
persist.vendor.qcom.bluetooth.aptxadaptiver2_1_support=true
persist.vendor.qcom.bluetooth.enable.swb=true
persist.bluetooth.disableabsvol=true
persist.bluetooth.sbc_hd_higher_bitrate=1
persist.sys.fflag.override.settings_bluetooth_hearing_aid=true" >> $MODPATH/system.prop
}

AUTO_EN() {
	ui_print " "
    ui_print " - You selected AUTO installation mode - "
    AUTO_In=true
	
	clear_screen
	ui_print " "
	ui_print " - The installation has started! - "
	
	ui_print " "
	ui_print "     Please wait until it is completed. "
	ui_print "     The installation time can vary from "
	ui_print "     one minute to ten minutes depending "
	ui_print "     on your device and the ROM used "
	
	if [ $AUTO_In = true ]; then
		deep_buffer
	fi
	
	if [ $AUTO_In = true ]; then
		iir_patches
	fi
 
	ui_print " "
	ui_print "   ########================================= 20% done!"
	
	if [ -f $sys_tem/vendor/etc/audio_platform_info.xml ]; then
		audio_platform_info
	 elif [ -f $sys_tem/vendor/etc/audio_platform_info_extcodec.xml ]; then
		audio_platform__info_ext
	  elif [ -f $sys_tem/vendor/etc/audio_platform_info_intcodec.xml ]; then
		 audio_platform_info_int
	 fi
	
	if [ $AUTO_In = true ]; then
		companders
	fi
	
	ui_print " "
	ui_print "   ##################====================== 45% done!"
	
	if [ $AUTO_In = true ]; then
		audio_codec
	fi
	
	ui_print " "
	ui_print "   ########################================ 60% done!"
	
	if [ $AUTO_In = true ]; then
	  if [ -f $sys_tem/etc/device_features/$DEVICE.xml ]; then
		device_features_system
	  elif [ -f $sys_tem/vendor/etc/device_features/$DEVICE.xml ]; then
		device_features_vendor
	  fi
	fi
	
	if [ $AUTO_In = true ]; then
		mixer
	fi
	
	SET_PERM_RM
	MOVERPATH
	
	ui_print " "
    ui_print "   ######################################## 100% done!"
	
	ui_print " "
	ui_print " - All done! "
}

AUTO_RU() {
	ui_print " "
	ui_print " - Вы выбрали режим установки АВТО - "
    AUTO_In=true
	
	clear_screen
	ui_print " "
	ui_print " - Установка началась! - "
	
	ui_print " "
	ui_print "     Пожалуйста дождитесь завершения. "
	ui_print "     Время установки может варьироваться "
	ui_print "     от одной до пяти минут в зависимости от "
	ui_print "     вашего устройства и используемой прошивки. "
	
	if [ $AUTO_In = true ]; then
		deep_buffer
	fi
	
	if [ $AUTO_In = true ]; then
		iir_patches
	fi
 
	ui_print " "
	ui_print "   ########================================= 20% done!"
	
	if [ -f $sys_tem/vendor/etc/audio_platform_info.xml ]; then
		audio_platform_info
	 elif [ -f $sys_tem/vendor/etc/audio_platform_info_extcodec.xml ]; then
		audio_platform__info_ext
	  elif [ -f $sys_tem/vendor/etc/audio_platform_info_intcodec.xml ]; then
		 audio_platform_info_int
	 fi
	
	if [ $AUTO_In = true ]; then
		companders
	fi
	
	ui_print " "
	ui_print "   ##################====================== 45% done!"
	
	if [ $AUTO_In = true ]; then
		audio_codec
	fi
	
	ui_print " "
	ui_print "   ########################================ 60% done!"
	
	if [ $AUTO_In = true ]; then
	  if [ -f $sys_tem/etc/device_features/$DEVICE.xml ]; then
		device_features_system
	  elif [ -f $sys_tem/vendor/etc/device_features/$DEVICE.xml ]; then
		device_features_vendor
	  fi
	fi
	
	if [ $AUTO_In = true ]; then
		mixer_lite
	fi
	
	SET_PERM_RM
	MOVERPATH
	
	ui_print " "
    ui_print "   ######################################## 100% готово!"
	
	ui_print " "
	ui_print " - Всё готово! "
}

English() {
	  clear_screen
	
	  ENG_CHK=1
	  ui_print " "
	  ui_print " - You selected English language! -"
	  ui_print " "
	  
	  if [ "$SD662" ] || [ "$SD665" ] || [ "$SD690" ] || [ "$SD710" ] || [ "$SD720G" ] || [ "$SD730" ] || [ "$SD765G" ] || [ "$SD820" ] || [ "$SD835" ] || [ "$SD845" ] || [ "$SD855" ] || [ "$SD865" ] || [ "$SD888" ]; then
		HIFI=true
	  ui_print " "
	  ui_print " - Device with support Hi-Fi detected! -"
	  else
		HIFI=false
	  ui_print " "
	  ui_print " - Device without support Hi-Fi detected! -"
	  fi
	  
	  ui_print " - Select installation mode: "
	  ui_print " "
	  ui_print " - NOTE: [VOL+] - select, [VOL-] - confirm "
	  ui_print " "
	  ui_print " 1. Auto (Only the most necessary things"
	  ui_print "    for your device will be installed)"
	  ui_print " "
	  ui_print " 2. Manual (You configure the module yourself)"
	  ui_print " "
	  ui_print " "
	  ui_print " 3. Install all (For experienced users, may cause problems)"
	  ui_print " "
	  ui_print "        Selected: "
	  ui_print " "
	  
	  while true; do
	  ui_print "------>    $ENG_CHK    step"
	  ui_print " "
	  if $VKSEL; then
		ENG_CHK=$((ENG_CHK + 1))
		ALL=true
	  else
		break
	  fi
		
	  if [ $ENG_CHK -gt 3 ]; then
		ENG_CHK=1
	  fi
done

case $ENG_CHK in
	1) AUTO_EN;;
	2) ENG_Manual;;
	3) All_En;;
esac
}

Russian() {
	  clear_screen
	  
	  RU_CHK=1
	  ui_print " "
	  ui_print " - Вы выбрали Русский язык! -"
	  ui_print " "
	  
	  if [ "$SD662" ] || [ "$SD665" ] || [ "$SD690" ] || [ "$SD710" ] || [ "$SD720G" ] || [ "$SD730" ] || [ "$SD765G" ] || [ "$SD820" ] || [ "$SD835" ] || [ "$SD845" ] || [ "$SD855" ] || [ "$SD865" ] || [ "$SD888" ]; then
		HIFI=true
	  ui_print " "
	  ui_print " - Обнаружено устройство с поддержкой Hi-Fi! -"
	  else
		HIFI=false
	  ui_print " "
	  ui_print " - Обнаружено устройство без поддержки Hi-Fi! -"
	  fi
	  
	  ui_print " - Выберите режим установки: "
	  ui_print " "
	  ui_print " - Заметка: [VOL+] - выбор, [VOL-] - подтверждение "
	  ui_print " "
	  ui_print " 1. Авто (Только самое необходимое для"
	  ui_print "    вашего устройства будет установлено)"
	  ui_print " "
	  ui_print " 2. Ручной (Вы самостоятельно настраиваете модуль)"
	  ui_print " "
	  ui_print " "
	  ui_print " 3. Установить всё (Для опытных пользователей, может вызвать проблемы)"
	  ui_print " "
	  ui_print "        Выбран: "
	  ui_print " "
	  while true; do
	  ui_print "------>    $RU_CHK    пункт"
	  ui_print " "
	  if $VKSEL; then
		RU_CHK=$((RU_CHK + 1))
		ALL=true
	  else
		break
	  fi
		
	  if [ $RU_CHK -gt 3 ]; then
		RU_CHK=1
	  fi
done

case $RU_CHK in
	1) AUTO_RU;;
	2) RU_Manual;;
	3) All_Ru;;
esac
}
	
ENG_Manual() {
	  clear_screen
	  ui_print " "
	  ui_print " - You selected Manual mode - "
	  ui_print " "
	  ui_print " - Configurate me, pls >.< - "
	  ui_print " "
	  
	  sleep 1
	  ui_print " - Disable Deep Buffer -"
	  ui_print "***************************************************"
	  ui_print "* [1/14]                                          *"
	  ui_print "*                                                 *"
	  ui_print "*               This option disable               *"
	  ui_print "*            deep buffer in your device.          *"
	  ui_print "*         If you want more low frequencies,       *"
	  ui_print "*                skip this option.                *"
	  ui_print "*                                                 *"
	  ui_print "***************************************************"
	ui_print "   Disable deep buffer?"
	sleep 1
	ui_print " "
	ui_print "   Vol Up = YES, Vol Down = NO"
	if chooseport; then
		STEP1=true
	fi

	ui_print " "
	ui_print " - Improve volume levels and change media volume steps -"
	  ui_print "***************************************************"
	  ui_print "* [2/14]                                          *"
	  ui_print "*                                                 *"
	  ui_print "*               A T T E N T I O N!                *"
	  ui_print "*   Confirming this option may harm your device!  *"
	  ui_print "*NLSound Team is not responsible for your devices!*"
	  ui_print "*              Choose at your own risk!           *"
	  ui_print "*                                                 *"
	  ui_print "***************************************************"
	ui_print "   Improve volume levels and media volume steps?"
	sleep 1
	ui_print " "
	ui_print "   Vol Up = YES, Vol Down = NO"
	if chooseport; then
	  STEP2=true
		
	fi

	ui_print " "
	ui_print " - Improve microphones levels -"
	  ui_print "***************************************************"
	  ui_print "* [3/14]                                          *"
	  ui_print "*                                                 *"
	  ui_print "*             This option improving               *"
	  ui_print "*     microphone volume levels and quality in     *"
	  ui_print "*                 your device.                    *"
	  ui_print "*                                                 *"
	  ui_print "***************************************************"
	ui_print "   Improve microphone levels?"
	sleep 1
	ui_print " "
	ui_print "   Vol Up = YES, Vol Down = NO"
	if chooseport; then
	  STEP3=true
	fi

	ui_print " "
	ui_print " - IIR patches -"
	  ui_print "***************************************************"
	  ui_print "* [4/14]                                          *"
	  ui_print "*                                                 *"
	  ui_print "* IIR affects the final frequency response curve. *"
	  ui_print "*   headphones. The default setting is with an    *"
	  ui_print "* emphasis on the upper limit of low frequencies  *"
	  ui_print "* and the lower bound of the midrange frequencies *"
	  ui_print "*Once applied, these boundaries will be reinforced*"
	  ui_print "*        [Recommended for installation]           *"
	  ui_print "*                                                 *"
	  ui_print "***************************************************"
	ui_print "   Install IIR patches?"
	sleep 1
	ui_print " "
	ui_print "   Vol Up = YES, Vol Down = NO"
	if chooseport; then
	  STEP4=true
	fi

	ui_print " "
	ui_print " - Patching audio platform files -"
	  ui_print "***************************************************"
	  ui_print "* [5/14]                                          *"
	  ui_print "*                                                 *"
	  ui_print "* Confirming this option will allow the module to *"
	  ui_print "*      use a different audio codec algorithm      *"
	  ui_print "* for your favorite songs, and will also improve  *"
	  ui_print "*    the sound quality during video recording     *"
	  ui_print "*        [Recommended for installation]           *"
	  ui_print "*                                                 *"
	  ui_print "***************************************************"
	ui_print "   Patching audio platform files?"
	sleep 1
	ui_print " "
	ui_print "   Vol Up = YES, Vol Down = NO"
	if chooseport; then
	  STEP5=true
	fi

	ui_print " "
	ui_print " - Disable сompanders -"
	  ui_print "***************************************************"
	  ui_print "* [6/14]                                          *"
	  ui_print "*                                                 *"
	  ui_print "*    Companding-exists for audio compression.     *"
	  ui_print "*    Because of this algorithm, you can hear      *"
	  ui_print "*  the hiss in the path is even lossless audio.   *"
	  ui_print "*     This algorithm does not work properly.      *"
	  ui_print "*    Everything he does is pointlessly making     *"
	  ui_print "* things worse the quality of your favorite audio *"
	  ui_print "*        [Recommended for installation]           *"
	  ui_print "*                                                 *"
	  ui_print "***************************************************"
	ui_print "    Disable companders?"
	sleep 1
	ui_print " "
	ui_print "    Vol Up = YES, Vol Down = NO"
	if chooseport; then
	  STEP6=true
	fi

	ui_print " "
	ui_print " - Configurating interal audio codec -"
	  ui_print "***************************************************"
	  ui_print "* [7/14]                                          *"
	  ui_print "*                                                 *"
	  ui_print "*            This option configuring              *"
	  ui_print "*       your device's internal audio codec.       *"
	  ui_print "*                                                 *"
	  ui_print "***************************************************"
	ui_print "   Configurate?"
	sleep 1
	ui_print " "
	ui_print "   Vol Up = YES, Vol Down = NO"
	if chooseport; then
	   STEP7=true
	fi
	 
	ui_print " "
	ui_print " - Patch device_features files -"
	  ui_print "***************************************************"
	  ui_print "* [8/14]                                          *"
	  ui_print "*                                                 *"
	  ui_print "*        This step will do the following:         *"
	  ui_print "*        - Unlocks the sampling frequency         *"
	  ui_print "*          of the audio up to 192000 kHz;         *"
	  ui_print "*        - Enable HD record in camcorder;         *"
	  ui_print "*        - Increase VoIP recor quality;           *"
	  ui_print "*        - Enable support for hd voice            *"
	  ui_print "*          recording quality;                     *"
	  ui_print "*        - Enable Hi-Fi support (on some devices) *"
	  ui_print "*                                                 *"
	  ui_print "*  And much more . . .                            *"
	  ui_print "*                                                 *"
	  ui_print "***************************************************"
	ui_print "    Install this step?"
	sleep 1
	ui_print " "
	ui_print "    Vol Up = YES, Vol Down = NO"
	if chooseport; then
		STEP8=true
	fi

	ui_print " "
	ui_print " - Added new dirac -"
	  ui_print "***************************************************"
	  ui_print "* [9/14]                                          *"
	  ui_print "*                                                 *"
	  ui_print "* This option will add a new dirac to the system  *"
	  ui_print "*   If you encounter wheezing from the outside    *"
	  ui_print "*    speaker, first of all when reinstalling      *"
	  ui_print "*               skip this step.                   *"
	  ui_print "***************************************************"
	ui_print "   Added new dirac?"
	sleep 1
	ui_print " "
	ui_print "   Vol Up = YES, Vol Down = NO"
	if chooseport; then
		STEP9=true
	fi

	ui_print " "
	ui_print " - Install other patches in mixer_paths - "
	  ui_print "***************************************************"
	  ui_print "* [10/14]                                         *"
	  ui_print "*                                                 *"
	  ui_print "*        Contains experimental settings           *"
	  ui_print "*          If you encounter problems              *"
	  ui_print "*     after installation - skip this step.        *"
	  ui_print "*                                                 *"
	  ui_print "***************************************************"
	ui_print "   Install patches in mixer_paths files?"
	sleep 1
	ui_print " "
	ui_print "   Vol Up = YES, Vol Down = NO"
	if chooseport; then
	  STEP10=true
	fi
	  
	ui_print " "
	ui_print " - Install tweaks in prop file - "
	  ui_print "***************************************************"
	  ui_print "* [11/14]                                         *"
	  ui_print "*                                                 *"
	  ui_print "*    This option will change the sound quality    *"
	  ui_print "*                  the most.                      *"
	  ui_print "*             May cause problems.                 *"
	  ui_print "*                                                 *"
	  ui_print "***************************************************"
	ui_print "   Install?"
	sleep 1
	ui_print " "
	ui_print "   Vol Up = YES, Vol Down = NO"
	if chooseport; then
	  STEP11=true
	fi
	
	ui_print " "
	ui_print " - Improve Bluetooth - "
	  ui_print "***************************************************"
	  ui_print "* [12/14]                                         *"
	  ui_print "*                                                 *"
	  ui_print "*   This option will improve the audio quality    *"
	  ui_print "*    in Bluetooth, as well as fix the problem     *"
	  ui_print "*      of disappearing the AAC codec switch       *"
	  ui_print "*                                                 *"
	  ui_print "***************************************************"
	ui_print "   Install?"
	sleep 1
	ui_print " "
	ui_print "   Vol Up = YES, Vol Down = NO"
	if chooseport; then
	  STEP12=true
	fi
	
	ui_print " "
	ui_print " - Switch audio output from DIRECT to DIRECT_PCM - "
	  ui_print "***************************************************"
	  ui_print "* [13/14]                                         *"
	  ui_print "*                                                 *"
	  ui_print "*  This option will switch DIRECT to DIRECT_PCM,  *"
	  ui_print "*      which will improve the sound detail.       *"
	  ui_print "*         [Recommended for installation]          *"
	  ui_print "*                                                 *"
	  ui_print "***************************************************"
	ui_print "   Install?"
	sleep 1
	ui_print " "
	ui_print "   Vol Up = YES, Vol Down = NO"
	if chooseport; then
	  STEP13=true
	fi
	
	ui_print " "
	ui_print " - Turn off useless DRC - "
	  ui_print "***************************************************"
	  ui_print "* [14/14]                                         *"
	  ui_print "*                                                 *"
	  ui_print "*    Limit the dynamic range of the soundtrack    *"
	  ui_print "*       (the difference between the loudest       *"
	  ui_print "*             and the quietest sounds)            *"
	  ui_print "*                                                 *"
	  ui_print "***************************************************"
	ui_print "   Install?"
	sleep 1
	ui_print " "
	ui_print "   Vol Up = YES, Vol Down = NO"
	if chooseport; then
	  STEP14=true
	fi
	
	ui_print " "
	ui_print " - Processing. . . . -"
	ui_print " "
	ui_print " - You can minimize Magisk and use the device -"
	ui_print " - and then come back here to reboot and apply the changes. -"
	
	if [ $STEP1 = true ]; then
		deep_buffer
	fi
	
	if [ $STEP2 = true ]; then
		patch_volumes
	fi

    ui_print " "
    ui_print "   ########================================ 20% done!"
	
	if [ $STEP3 = true ]; then
		patch_microphone
	fi
	
	if [ $STEP4 = true ]; then
		iir_patches
	fi
 
    ui_print " "
    ui_print "   ################======================== 40% done!"
	
	if [ $STEP5 = true ]; then
     if [ -f $APII ]; then
		audio_platform_info_int
	 elif [ -f $APIE ]; then
        audio_platform__info_ext
     elif [ -f $API ]; then
        audio_platform_info
     fi
	fi
	
	if [ $STEP6 = true ]; then
		companders
	fi
  
    ui_print " "
    ui_print "   ########################================ 60% done!"
	
	if [ $STEP7 = true ]; then
		audio_codec
	fi
	
	if [ $STEP8 = true ]; then
      if [ -f $DEVFEA ]; then
		device_features_system
      elif [ -f $DEVFEAA ]; then
        device_features_vendor
      fi
	fi

    ui_print " "
    ui_print "   ################################======== 80% done!"
	
	if [ $STEP9 = true ]; then
		dirac
	fi
	
	if [ $STEP10 = true ]; then
		mixer
	fi
	
	if [ $STEP11 = true ]; then
		prop
	fi
	
	if [ $STEP12 = true ]; then
		improve_bluetooth
	fi
	
	if [ $STEP13 = true ]; then
		io_policy
	fi
	
	if [ $STEP14 = true ]; then
		audio_policy
	fi
	
	SET_PERM_RM
	MOVERPATH
	
	ui_print " "
    ui_print "   ######################################## 100% done!"
	
    ui_print " "
    ui_print " - All done! With love, NLSound Team. - "
    ui_print " "
}

RU_Manual() {
	 clear_screen
	 ui_print " "
	 ui_print " - Вы выбрали РУЧНОЙ режим установки - "
	 ui_print " "
	 ui_print " - Настрой меня, пожалуйста >.< -"
	 ui_print " "

	sleep 1
	ui_print " - Отключение глубокого буффера -"
	  ui_print "**************************************************"
	  ui_print "* [1/14]                                         *"
	  ui_print "*                                                *"
	  ui_print "*             Эта опция отключит                 *"
	  ui_print "*     глубокий буффер в вашем устройстве.        *"
	  ui_print "*     Если вам недостаточно низких частот,       *"
	  ui_print "*            пропустите этот пункт.              *"
	  ui_print "*                                                *"
	  ui_print "**************************************************"
	ui_print "   Отключить глубокий буффер?"
	sleep 1
	ui_print " "
	ui_print "   Vol Up = ДА, Vol Down = НЕТ"
	if chooseport; then
		STEP1=true
	fi

	ui_print " "
	ui_print " - Увеличить уровни и шаги громкости медиа -"
	  ui_print "**************************************************"
	  ui_print "* [2/14]                                         *"
	  ui_print "*                                                *"
	  ui_print "*                О С Т О Р О Ж Н О!              *"
	  ui_print "*          Подтверждение этой опции может        *"
	  ui_print "*          нанести вред вашему устройству!       *"
	  ui_print "*      NLSound Team не несёт ответственности     *"
	  ui_print "*               за ваше устройство!              *"
	  ui_print "*          Выбирать на свой страх и риск!        *"
	  ui_print "*                                                *"
	  ui_print "**************************************************"
	ui_print "   Увеличить уровни и шаги громкости медиа?"
	sleep 1
	ui_print " "
	ui_print "   Vol Up = ДА, Vol Down = НЕТ"
	if chooseport; then
	  STEP2=true
	fi

	ui_print " "
	ui_print " - Увеличить громкости микрофонов -"
	  ui_print "**************************************************"
	  ui_print "* [3/14]                                         *"
	  ui_print "*                                                *"
	  ui_print "*                 Эта опция увеличит             *"
	  ui_print "*           уровни громкостей микрофонов в       *"
	  ui_print "*                  вашем устройстве.             *"
	  ui_print "*                                                *"
	  ui_print "**************************************************"
	ui_print "   Увеличить громкости микрофонов?"
	sleep 1
	ui_print " "
	ui_print "   Vol Up = ДА, Vol Down = НЕТ"
	if chooseport; then
	  STEP3=true
	fi

	ui_print " "
	ui_print " - IIR патчи -"
	  ui_print "**************************************************"
	  ui_print "* [4/14]                                         *"
	  ui_print "*                                                *"
	  ui_print "*    IIR влияет на итоговую кривую АЧХ ваших     *"
	  ui_print "* наушников. По-умолчанию используется настройка *"
	  ui_print "*  с акцентом на верхнюю границу низких частот   *"
	  ui_print "*       и нижнюю границу средних частот.         *"
	  ui_print "*  После применения эти границы будут усилены.   *"
	  ui_print "*        [Рекомендуется для установки]           *"
	  ui_print "*                                                *"
	  ui_print "**************************************************"
	ui_print "   Установить IIR патчи?"
	sleep 1
	ui_print " "
	ui_print "   Vol Up = ДА, Vol Down = НЕТ"
	if chooseport; then
	  STEP4=true
	fi

	ui_print " "
	ui_print " - Патчинг audio_platform файлов -"
	  ui_print "**************************************************"
	  ui_print "* [5/14]                                         *"
	  ui_print "*                                                *"
	  ui_print "*    Подтверждение этой опции позволит модулю    *"
	  ui_print "* использовать иной алгоритм работы аудио кодека *"
	  ui_print "* для ваших любимых композиций, а также улучшит  *"
	  ui_print "*       качество звука при видеосъёмке.          *"
	  ui_print "*        [Рекомендуется для установки]           *"
	  ui_print "*                                                *"
	  ui_print "**************************************************"
	ui_print "   Патчить audio platform файлы?"
	sleep 1
	ui_print " "
	ui_print "   Vol Up = ДА, Vol Down = НЕТ"
	if chooseport; then
	  STEP5=true
	fi

	ui_print " "
	ui_print " - Отключение компандеров -"
	  ui_print "**************************************************"
	  ui_print "* [6/14]                                         *"
	  ui_print "*                                                *"
	  ui_print "* Компандирование - существует для сжатия аудио. *"
	  ui_print "*     Из-за этого алгоритма вы можете слышать    *"
	  ui_print "*      шипение в тракте даже lossless аудио.     *"
	  ui_print "*   Этот алгоритм не работает должным образом.   *"
	  ui_print "*   Всё, что он делает - бессмысленно ухудшает   *"
	  ui_print "*        качество вашего любимого аудио.         *"
	  ui_print "*         [Рекомендуется для установки]          *"
	  ui_print "*                                                *"
	  ui_print "**************************************************"
	ui_print "    Отключить компандеры?"
	sleep 1
	ui_print " "
	ui_print "    Vol Up = ДА, Vol Down = НЕТ"
	if chooseport; then
	  STEP6=true
	fi

	ui_print " "
	ui_print " - Настройка внутреннего аудио кодека -"
	  ui_print "**************************************************"
	  ui_print "* [7/14]                                         *"
	  ui_print "*                                                *"
	  ui_print "*               Эта опция настроит               *"
	  ui_print "*   внутреннний аудио кодек вашего устройства.   *"
	  ui_print "*                                                *"
	  ui_print "**************************************************"
	ui_print "   Настроить?"
	sleep 1
	ui_print " "
	ui_print "   Vol Up = ДА, Vol Down = НЕТ"
	if chooseport; then
	   STEP7=true
	fi
	 
	ui_print " "
	ui_print " - Патчинг device_features файлов -"
	  ui_print "**************************************************"
	  ui_print "* [8/14]                                         *"
	  ui_print "*                                                *"
	  ui_print "*  Этот шаг сделает следующее:                   *"
	  ui_print "*   - Разблокирует частоты дискретизации         *"
	  ui_print "*     вплоть до 192000 kHz;                      *"
	  ui_print "*   - Активирует режим чувствительности для      *"
	  ui_print "*     Bluetooth наушников;                       *"
	  ui_print "*   - Включит HD запись аудио;                   *"
	  ui_print "*   - Улучшит качество Voip записи;              *"
	  ui_print "*   - Включит поддержку Hi-Fi (для под. ус-тв);  *"
	  ui_print "*                                                *"
	  ui_print "*  И многое другое . . .                         *"
	  ui_print "*                                                *"
	  ui_print "**************************************************"
	ui_print "    Установить этот пункт?"
	sleep 1
	ui_print " "
	ui_print "    Vol Up = ДА, Vol Down = НЕТ"
	if chooseport; then
		STEP8=true
	fi

	ui_print " "
	ui_print " - Добавление нового dirac -"
	  ui_print "**************************************************"
	  ui_print "* [9/14]                                         *"
	  ui_print "*                                                *"
	  ui_print "*     Эта опция добавит новый dirac в систему    *"
	  ui_print "*    Если вы столкнётесь с хрипами из внешнего   *"
	  ui_print "*  динамика, в первую очередь при переустановке  *"
	  ui_print "*             пропустите данный пункт.           *"
	  ui_print "*                                                *"
	  ui_print "**************************************************"
	ui_print "   Добавить новый dirac?"
	sleep 1
	ui_print " "
	ui_print "   Vol Up = ДА, Vol Down = НЕТ"
	if chooseport; then
		STEP9=true
	fi

	ui_print " "
	ui_print " - Установить другие патчи в mixer_paths файлы - "
	  ui_print "**************************************************"
	  ui_print "* [10/14]                                        *"
	  ui_print "*                                                *"
	  ui_print "*       Содержит экспериментальные настройки     *"
	  ui_print "*        Если вы столкнулись с проблемами        *"
	  ui_print "*   после установки - пропустите данный пункт.   *"
	  ui_print "*                                                *"
	  ui_print "**************************************************"
	ui_print "   Установить патчи в mixer_paths файлы?"
	sleep 1
	ui_print " "
	ui_print "   Vol Up = ДА, Vol Down = НЕТ"
	if chooseport; then
		STEP10=true
	fi
	
	ui_print " "
	ui_print " - Установить твики в prop файл - "
	  ui_print "***************************************************"
	  ui_print "* [11/14]                                         *"
	  ui_print "*                                                 *"
	  ui_print "*  Эта опция сильнее всех изменит качество звука  *"
	  ui_print "*          Может вызвать проблемы.                *"
	  ui_print "*                                                 *"
	  ui_print "***************************************************"
	ui_print "   Установить?"
	sleep 1
	ui_print " "
	ui_print "   Vol Up = ДА, Vol Down = НЕТ"
	if chooseport; then
	  STEP11=true
	fi
	
	ui_print " "
	ui_print " - Улучшить Bluetooth - "
	  ui_print "***************************************************"
	  ui_print "* [12/14]                                         *"
	  ui_print "*                                                 *"
	  ui_print "*        Эта опция улучшит качество аудио         *"
	  ui_print "*     в Bluetooth, а также исправит проблему с    *"
	  ui_print "*      исчезновением переключателя ААС кодека.    *"
	  ui_print "*            Может вызвать проблемы.              *"
	  ui_print "*                                                 *"
	  ui_print "***************************************************"
	ui_print "   Установить?"
	sleep 1
	ui_print " "
	ui_print "   Vol Up = ДА, Vol Down = НЕТ"
	if chooseport; then
	  STEP12=true
	fi
	
	ui_print " "
	ui_print " - Переключает роут звука с DIRECT на DIRECT_PCM - "
	  ui_print "***************************************************"
	  ui_print "* [13/14]                                         *"
	  ui_print "*                                                 *"
	  ui_print "*    Эта опция переключит DIRECT на DIRECT_PCM,   *"
	  ui_print "*       и улучшит качество итогового звука.       *"
	  ui_print "*                                                 *"
	  ui_print "***************************************************"
	ui_print "   Установить?"
	sleep 1
	ui_print " "
	ui_print "   Vol Up = ДА, Vol Down = НЕТ"
	if chooseport; then
	  STEP13=true
	fi
	
	ui_print " "
	ui_print " - Отключить бесполезную DRC функцию - "
	  ui_print "***************************************************"
	  ui_print "* [14/14]                                         *"
	  ui_print "*                                                 *"
	  ui_print "* Ограничивает динамический диапазон аудио треков *"
	  ui_print "*      если разница между низкими и высокими      *"
	  ui_print "*           частотами слишком большая.            *"
	  ui_print "*          [Рекомендуется к установке]            *"
	  ui_print "*                                                 *"
	  ui_print "***************************************************"
	ui_print "   Установить?"
	sleep 1
	ui_print " "
	ui_print "   Vol Up = ДА, Vol Down = НЕТ"
	if chooseport; then
	  STEP14=true
	fi
	
	ui_print " "
	ui_print " - Обработка. . . . -"
	ui_print " "
	ui_print " - Вы можете свернуть Magisk и пользоваться устройством -"
	ui_print " - а затем вернуться сюда для перезагрузки и применения изменений. -"
    
	if [ $STEP1 = true ]; then
		deep_buffer
	fi
	
	if [ $STEP2 = true ]; then
		patch_volumes
	fi

    ui_print " "
    ui_print "   ########================================ 20% done!"
	
	if [ $STEP3 = true ]; then
		patch_microphone
	fi
	
	if [ $STEP4 = true ]; then
		iir_patches
	fi
 
    ui_print " "
    ui_print "   ################======================== 40% done!"
	
	if [ $STEP5 = true ]; then
     if [ -f $APII ]; then
		audio_platform_info_int
	 elif [ -f $APIE ]; then
        audio_platform__info_ext
     elif [ -f $API ]; then
        audio_platform_info
     fi
	fi
	
	if [ $STEP6 = true ]; then
		companders
	fi
  
    ui_print " "
    ui_print "   ########################================ 60% done!"
	
	if [ $STEP7 = true ]; then
		audio_codec
	fi
	
	if [ $STEP8 = true ]; then
      if [ -f $DEVFEA ]; then
		device_features_system
      elif [ -f $DEVFEAA ]; then
        device_features_vendor
      fi
	fi

    ui_print " "
    ui_print "   ################################======== 80% done!"
	
	if [ $STEP9 = true ]; then
		dirac
	fi
	
	if [ $STEP10 = true ]; then
		mixer
	fi
	
	if [ $STEP11 = true ]; then
		prop
	fi
	
	if [ $STEP12 = true ]; then
		improve_bluetooth
	fi
	
	if [ $STEP13 = true ]; then
		io_policy
	fi
	
	if [ $STEP14 = true ]; then
		audio_policy
	fi

	SET_PERM_RM
	MOVERPATH
	
	ui_print " "
    ui_print "   ######################################## 100% готово!"
	
    ui_print " "
    ui_print " - Всё готово! С любовью, NLSound Team. - "
    ui_print " "
}

All_En() {
	clear_screen
	ui_print " "
	ui_print " - You selected INSTALL ALL "
	ui_print " "
	ui_print " - Installation started! Please, wait..."
	
	if [ $ALL = true ]; then
		deep_buffer
		patch_microphone
		patch_volumes
		iir_patches
		
		if [ -f $APII ]; then
			audio_platform_info_int
		elif [ -f $APIE ]; then
			audio_platform_info_ext
		elif [ -f $API ]; then
			audio_platform_info
		fi
		
		companders
		audio_codec
		device_features_system
		device_features_vendor
		dirac
		mixer
		prop
		improve_bluetooth
		io_policy
		audio_policy
	fi
	
	SET_PERM_RM
	MOVERPATH
	
	ui_print " "
	ui_print " - All done!"
	ui_print " "
}

All_Ru() {
	clear_screen
	ui_print " "
	ui_print " - Вы выбрали УСТАНОВИТЬ ВСЁ "
	ui_print " "
	ui_print " - Установка начата! Пожалуйста, подождите..."
	
	if [ $ALL = true ]; then
		deep_buffer
		patch_microphone
		patch_volumes
		iir_patches
		
		if [ -f $APII ]; then
			audio_platform_info_int
		elif [ -f $APIE ]; then
			audio_platform_info_ext
		elif [ -f $API ]; then
			audio_platform_info
		fi
		
		companders
		audio_codec
		device_features_system
		device_features_vendor
		dirac
		mixer
		prop
		improve_bluetooth
		io_policy
		audio_policy
	fi
	
	SET_PERM_RM
	MOVERPATH
	
	ui_print " "
	ui_print " - Всё готово!"
	ui_print " "
}

ui_print " "
ui_print " - Select language -"
ui_print " "
ui_print " - NOTE: [VOL+] - select, [VOL-] - confirm "
sleep 1
LANG=1
ui_print " "
ui_print "   1. English "
ui_print "   2. Русский "
ui_print " "
ui_print "      Selected: "
while true; do
	ui_print "      $LANG"
	if $VKSEL; then
		LANG=$((LANG + 1))
	else
		break
	fi
		
	if [ $LANG -gt 2 ]; then
		LANG=1
	fi
done

case $LANG in
	1) English;;
	2) Russian;;
esac

