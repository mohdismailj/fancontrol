#!/bin/bash

function gpiopwm() {
	sleep_low=$(awk -v freq="$2" -v duty="$3"  'BEGIN{print (1/freq)*((100-duty)/100)}')
	sleep_high=$(awk -v freq="$2" -v duty="$3"  'BEGIN{print (1/freq)*((100-(100-duty))/100)}')
  	var_count=0
   	repeat=1000
	while [ $var_count -lt $repeat ]
   	do
        echo 1 > /sys/class/gpio/gpio$1/value
        sleep $sleep_high
        echo 0 > /sys/class/gpio/gpio$1/value
        let var_count=var_count+1
        if [ $var_count -le $repeat ]
	then
		sleep $sleep_low
	fi
    	done
}

echo 164 > /sys/class/gpio/export
echo out > /sys/class/gpio/gpio164/direction
lastcpu=0
duty=15
heat=55
while [ true ]
do
if [ $((`cat /sys/class/thermal/thermal_zone0/temp`)) -gt  $((`cat /sys/class/thermal/thermal_zone1/temp`)) ]
then
cpu=$((`cat /sys/class/thermal/thermal_zone0/temp`/1000))
else
cpu=$((`cat /sys/class/thermal/thermal_zone1/temp`/1000))
fi
pwm=0
if [ "$cpu" -ge "$heat" ]
then
	if [ "$cpu" -ge "$lastcpu" ] && [ "$lastcpu" -ne 0 ]
	then
		duty=$((duty+5))
	fi
	if [ "$duty" -ge 100 ]
        then
		echo "fan on @ heat $cpu"
                echo 1 > /sys/class/gpio/gpio164/value
		pwm=0
	else
		echo "fan duty $duty% @ heat $cpu"
                gpiopwm 164 60 $duty
		pwm=1
        fi
	lastcpu=$cpu
else
	lastcpu=0
	duty=15
	fan=$((`cat /sys/class/gpio/gpio164/value`))
	if [ "$fan" -ne 0 ]
	then
		echo "fan off @ heat $cpu"
        	echo 0 > /sys/class/gpio/gpio164/value
		pwm=0
	fi
fi
if [ "$pwm" -eq 0 ]
then
	sleep 10
fi
done
