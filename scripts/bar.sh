#!/bin/sh

color=#d2d2d2

fsmon() {
	ROOTPART=$(df -h | awk '/\/$/ { print $3}')
	HOMEPART=$(df -h | awk '/\/home/ { print $3}')
	SWAPPART=$(cat /proc/swaps | awk '/\// { print $4 }')

	echo "^c$color^   $ROOTPART    $HOMEPART    $SWAPPART"
}

ram() {
	mem=$(free -h | awk '/Mem:/ { print $3 }' | cut -f1 -d 'i')
	echo "^c$color^ $mem"
}

cpu() {
	read -r cpu a b c previdle rest < /proc/stat
	prevtotal=$((a+b+c+previdle))
	sleep 0.5
	read -r cpu a b c idle rest < /proc/stat
	total=$((a+b+c+idle))
	cpu=$((100*( (total-prevtotal) - (idle-previdle) ) / (total-prevtotal) ))
	echo ^c$color^ "$cpu"%
}

network() {
	conntype=$(ip route | awk '/default/ { print substr($5,1,1) }')

	if [ -z "$conntype" ]; then
		echo "^c$color^ down"
	elif [ "$conntype" = "e" ]; then
		echo "^c$color^ up"
	elif [ "$conntype" = "w" ]; then
		echo "^c$color^ up"
	fi
}

volume_pa() {
	muted=$(pactl list sinks | awk '/Mute:/ { print $2 }')
	vol=$(pactl list sinks | grep Volume: | awk 'FNR == 1 { print $5 }' | cut -f1 -d '%')

	if [ "$muted" = "yes" ]; then
		echo "^c$color^ muted"
	else
		if [ "$vol" -ge 65 ]; then
			echo "^c$color^ $vol%"
		elif [ "$vol" -ge 40 ]; then
			echo "^c$color^ $vol%"
		elif [ "$vol" -ge 0 ]; then
			echo "^c$color^ $vol%"
		fi
	fi

}

volume_alsa() {

	mono=$(amixer -M sget Master | grep Mono: | awk '{ print $2 }')

	if [ -z "$mono" ]; then
		muted=$(amixer -M sget Master | awk 'FNR == 6 { print $7 }' | sed 's/[][]//g')
		vol=$(amixer -M sget Master | awk 'FNR == 6 { print $5 }' | sed 's/[][]//g; s/%//g')
	else
		muted=$(amixer -M sget Master | awk 'FNR == 5 { print $6 }' | sed 's/[][]//g')
		vol=$(amixer -M sget Master | awk 'FNR == 5 { print $4 }' | sed 's/[][]//g; s/%//g')
	fi

	if [ "$muted" = "off" ]; then
		echo "^c$color^ muted"
	else
		if [ "$vol" -ge 65 ]; then
			echo "^c$color^ $vol%"
		elif [ "$vol" -ge 40 ]; then
			echo "^c$color^ $vol%"
		elif [ "$vol" -ge 0 ]; then
			echo "^c$color^ $vol%"
		fi
	fi
}

battery() {
    get_capacity="$(cat /sys/class/power_supply/BAT0/capacity)"

    echo "^c$color^ $get_capacity"
}

clock() {
	dte=$(date +"%D")
	time=$(date +"%H:%M")

	echo "^c$color^ $dte  $time"
}


function get_bytes {
    interface=$(ip route get 8.8.8.8 2>/dev/null | awk '{print $5}')
    line=$(grep $interface /proc/net/dev | cut -d ':' -f2 | awk '{print "received_bytes="$1, "transmitted_bytes="$9}')
    eval $line
    now=$(date +%s%N)
 }


function get_velocity {
    value=$1
    old_value=$2
    now=$3
    timediff=$(($now - $old_time))
    velKB=$(echo "1000000000*($value-$old_value)/1024/$timediff" | bc)
    if test "$velKB" -gt 1024
    then
        echo $(echo "scale=2; $velKB/1024" |bc)MB/s
    else
        echo ${velKB}KB/s
    fi
}

netspeed() {
    get_bytes
    old_received_bytes=$received_bytes
    old_transmitted_bytes=$transmitted_bytes
    old_time=$now

    get_bytes

    vel_recv=$(get_velocity $received_bytes $old_received_bytes $now)
    vel_trans=$(get_velocity $transmitted_bytes $old_transmitted_bytes $now)

    echo "$vel_recv  $vel_trans "
}

main() {
	while true; do
        xsetroot -name "$(netspeed) $(battery) $(ram) $(cpu) $(network) $(volume_alsa) $(clock)"
		sleep 1
	done
}

main
