#!/system/bin/sh

# File for storing the number of restarts
BOOT_COUNT_FOLDER="/data/NLSound"
BOOT_COUNT_FILE="/data/NLSound/boot_count"
mkdir -p "$BOOT_COUNT_FOLDER"

# Check if the boot count file exists and read its value
if [ -f "$BOOT_COUNT_FILE" ]; then
  BOOT_COUNT=$(cat "$BOOT_COUNT_FILE")
else
  BOOT_COUNT=0
fi

# Increment the boot count and store it back in the file
BOOT_COUNT=$((BOOT_COUNT + 1))
echo "$BOOT_COUNT" >"$BOOT_COUNT_FILE"

# If the boot count is 2 or more, consider it a boot loop
if [ "$BOOT_COUNT" -ge 2 ]; then
  # Create the remove file in the NLSound module directory
  touch /data/adb/modules/NLSound/remove

  # Bootloop notification
  mkdir -p "/data/adb/modules/Notification"

  # Remove the boot count folder to reset the count
  rm -rf "$BOOT_COUNT_FOLDER"

  # Reboot the device
  reboot
fi

[ -d "$MODDIR/tools/tinymix" ] && alias tinymix="$MODDIR/tools/tinymix"

# Wait until the system has fully booted
until [ "$(getprop sys.boot_completed)" = "1" ]; do
  sleep 4
done

# Remove the boot count folder after successful boot
rm -rf "$BOOT_COUNT_FOLDER"

# Disable audio safe volume
settings put global audio_safe_volume_state 0

# Delete specific properties related to media resolution limits
resetprop -p --delete media.resolution.limit.16bit
resetprop -p --delete media.resolution.limit.24bit
resetprop -p --delete media.resolution.limit.32bit

resetprop -p --delete audio.resolution.limit.16bit
resetprop -p --delete audio.resolution.limit.24bit
resetprop -p --delete audio.resolution.limit.32bit

# Path to the module folder where the patched files should be located
MODULE_PATH="/data/adb/modules/NLSound/system"

# Function for file verification
check_files() {
  for file in $1; do
    if [ "$2" == "true" ]; then
      if [ ! -f "$MODULE_PATH$file" ]; then
        success=false
        break
      fi
    elif [ -f "$MODULE_PATH$file" ]; then
      success=false
      break
    fi
  done
}

# Checking module files (files_path, should_exist)
success=true
check_files "$MCODECS"       "$STEP6"
check_files "$ACONFS"        "$STEP6"
check_files "$RESOURCES"     "$STEP6"
check_files "$DEVFEAS"       "$STEP7"
check_files "$DEVFEASNEW"    "$STEP7"
check_files "$DCODECS"       "$STEP15"
check_files "$DAXES"         "$STEP15"
check_files "$IOPOLICYS"     "true"
check_files "$OUTPUTPOLICYS" "true"
check_files "$MPATHS"        "true"
check_files "$AUDIOPOLICYS"  $([ "$BITNES" != "Skip" ] && echo "true" || echo "false")
check_files "$MICXAR"        $([ "$BITNES" != "Skip" ] || [ "$SAMPLERATE" != "Skip" ] && echo "true" || echo "false")
check_files "$APIXMLS"       $([ "$BITNES" != "Skip" ] || [ "$SAMPLERATE" != "Skip" ] && echo "true" || echo "false")
