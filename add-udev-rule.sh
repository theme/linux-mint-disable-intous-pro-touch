#!/usr/bin/env bash

PWD=`pwd`
USER=`whoami`

if [ "$SUDO_USER" != "" ] && [ "$USER" != "$SUDO_USER" ]; then
        USER=$SUDO_USER
fi

SERVICE_FN="disable-intous-touch.service"
UDEVRULE_FN="99-intous.rules"
CMD_FN="disable-intous-touch.sh"

function install(){

cat > /etc/systemd/system/$SERVICE_FN <<EOF

[Unit]
Description=wacom intous Pro M touch disabler

[Service]
Type=oneshot
RemainAfterExit=no
ExecStart=$PWD/$CMD_FN

[Install]
WantedBy=multi-user.target

EOF

cat > /etc/udev/rules.d/$UDEVRULE_FN <<EOF


ACTION=="add", SUBSYSTEM=="input", ATTR{name}=="Wacom Intuos Pro M Finger", TAG+="systemd", ENV{SYSTEMD_WANTS}="$SERVICE_FN"

EOF

cat > $PWD/$CMD_FN <<EOF
#!/usr/bin/env bash

sleep 2

export XAUTHORITY=/home/$USER/.Xauthority
export DISPLAY=:0

/usr/bin/xsetwacom set 'Wacom Intuos Pro M Finger touch' TOUCH off

exit 0

EOF

sudo chown $USER $PWD/$CMD_FN
sudo chmod a+x $PWD/$CMD_FN

}

function uninstall(){

    if [ -f /etc/systemd/system/$SERVICE_FN ]; then
        rm /etc/systemd/system/$SERVICE_FN
    fi

    if [ -f /etc/udev/rules.d/$UDEVRULE_FN ]; then
        rm /etc/udev/rules.d/$UDEVRULE_FN
    fi

    if [ -f $PWD/$CMD_FN ]; then
        rm $PWD/$CMD_FN
    fi
}

install
# uninstall

udevadm control --reload-rules

systemctl daemon-reload
systemctl disable $SERVICE_FN
systemctl enable $SERVICE_FN

systemctl restart systemd-udevd.service

