#!/bin/sh

color=#d2d2d2
INTERFACE=$(ip route | awk '/^default/ {print $5; exit}')

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
    get_capacity="$(cat /sys/class/power_supply/*/capacity)"

    echo "^c$color^ $get_capacity%"
}

clock() {
	dte=$(date +"%D")
	time=$(date +"%H:%M")

	echo "^c$color^ $dte  $time"
}

netspeed() {

    if [ -z "$INTERFACE" ]; then
        STATUS="⚠ 离线 "
        xsetroot -name "$STATUS"
        sleep 1
        continue
    fi

    rx1=$(cat /sys/class/net/${INTERFACE}/statistics/rx_bytes 2>/dev/null || echo 0)
    tx1=$(cat /sys/class/net/${INTERFACE}/statistics/tx_bytes 2>/dev/null || echo 0)

    sleep 1

    rx2=$(cat /sys/class/net/${INTERFACE}/statistics/rx_bytes 2>/dev/null || echo 0)
    tx2=$(cat /sys/class/net/${INTERFACE}/statistics/tx_bytes 2>/dev/null || echo 0)

    if [ "$rx2" -lt "$rx1" ] || [ "$tx2" -lt "$tx1" ]; then
        continue
    fi

    rx_rate=$((rx2 - rx1))
    tx_rate=$((tx2 - tx1))

    rx_kb=$((rx_rate / 1024))
    tx_kb=$((tx_rate / 1024))

    STATUS="↓ ${rx_kb}KB/s | ↑ ${tx_kb}KB/s"
    echo "^c$color^$STATUS"
}

main() {
	while true; do
        xsetroot -name "$(netspeed) $(battery) $(ram) $(cpu) $(network) $(volume_alsa) $(clock)"
		sleep 1
	done
}

main
