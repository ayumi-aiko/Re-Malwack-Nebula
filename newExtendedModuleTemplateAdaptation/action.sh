MODDIR="/data/adb/modules/Re-Malwack"
persist_dir="/data/adb/Re-Malwack"

# Trigger April Fools prank :)
# Only starts at April 1st
if [ "$(date +%m%d)" = "0401" ] && [ ! -f "$persist_dir/get_pranked" ]; then
    # Chance of happening: 50%
    if [ "$(shuf -i 0-1 -n 1)" = "0" ]; then 
        sleep 2
        echo ""
        echo "- FATAL ERROR OCCURED!\033[0m\n"
        sleep 2
        touch $persist_dir/get_pranked
        clear
        echo "!!!!!!!!!!!!!!!!"
        echo "!!!  DANGER  !!!"
        echo "!!!!!!!!!!!!!!!!"
        sleep 3
        echo "- Your device is now hacked."
        sleep 1.5
        echo "- Bricking the device in"
        sleep 0.5
        echo "3..."
        sleep 1
        echo "2..."
        sleep 1
        echo "1..."
        sleep 3
        am start -a android.intent.action.VIEW -d "https://youtu.be/dQw4w9WgXcQ" 2>&1
        echo "- Happy April Fools!"
        echo "- XD"
        exit
        log_message "Happy April Fools!"
    fi
else
    rm -f $persist_dir/get_pranked    
fi

# print banner
banner1=$(cat <<'EOF'
    ____             __  ___      __                    __            
   / __ \___        /  |/  /___ _/ /      ______ ______/ /__          
  / /_/ / _ \______/ /|_/ / __ `/ / | /| / / __ `/ ___/ //_/       
 / _, _/  __/_____/ /  / / /_/ / /| |/ |/ / /_/ / /__/ ,<             
/_/ |_|\___/     /_/  /_/\__,_/_/ |__/|__/\__,_/\___/_/|_|           
EOF
)
banner2=$(cat <<'EOF'
██████╗ ███████╗    ███╗   ███╗ █████╗ ██╗     ██╗    ██╗ █████╗  ██████╗██╗  ██╗
██╔══██╗██╔════╝    ████╗ ████║██╔══██╗██║     ██║    ██║██╔══██╗██╔════╝██║ ██╔╝
██████╔╝█████╗█████╗██╔████╔██║███████║██║     ██║ █╗ ██║███████║██║     █████╔╝ 
██╔══██╗██╔══╝╚════╝██║╚██╔╝██║██╔══██║██║     ██║███╗██║██╔══██║██║     ██╔═██╗ 
██║  ██║███████╗    ██║ ╚═╝ ██║██║  ██║███████╗╚███╔███╔╝██║  ██║╚██████╗██║  ██╗
╚═╝  ╚═╝╚══════╝    ╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝ ╚══╝╚══╝ ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝
EOF
)
if command -v shuf >/dev/null 2>&1; then
    random_index=$(shuf -i 1-2 -n 1)
else
    random_index=$(( ($(date +%s) % 2) + 1 ))
fi
case $random_index in
    1) echo "$banner1" ;;
    2) echo "$banner2" ;;
esac
echo " "
echo " ====================================================================" 
if ! sh "$MODDIR/rmlwk.sh" --update-hosts --quiet; then
    echo "- Failed to update hosts."
    exit 1
fi