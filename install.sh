#!/bin/bash

VERBOSE=false
DIR=$(dirname -- "$(realpath -- "${BASH_SOURCE[0]}")")
OS_NAME=$(grep -E "^ID_LIKE=" /etc/os-release | cut -d'=' -f2 | tr -d '"')
SERVICESLOCAL="/usr/lib/systemd/user"
ISROOT=""

log(){
    if $VERBOSE; then
        echo $1
        echo ""
    fi
}

handle_uninstall(){
    read -n 1 -p "Press 'Y' for Yes or 'N' for No: " choice
    echo ""
    if [[ "$choice" != "Y" && "$choice" != "y" ]]; then
        exit 0
    fi

    echo "You picked Yes!"
    log "Removing service from systemd"
    $ISROOT systemctl disable --now disablegpu disablegpusleep
    $ISROOT rm "$SERVICESLOCAL/disablegpu.service" &> /dev/null
    $ISROOT rm "$SERVICESLOCAL/disablegpusleep.service" &> /dev/null

    log "Removing macpi_call.conf"
    $ISROOT rm /etc/modules-load.d/macpi_call.conf &> /dev/null

    echo "Uninstall complete."
}

editservice(){
    local file="$1"
    local newfilename="$2"
    local line=$3
    local REPLACE=$4
    sed ""$line"i $REPLACE" $DIR/"$file" > $DIR/"$newfilename".service &> /dev/null
}

handle_services(){
    local based=$1
    local DEBIANREPLACE="ExecStart=/bin/bash /usr/share/doc/acpi-call-dkms/examples/turn_off_gpu.sh"
    local FEDORAREPLACE="ExecStart=/bin/bash /usr/doc/acpi_call*/examples/turn_off_gpu.sh"
    local ARCHREPLACE="ExecStart=/bin/bash /usr/share/acpi_call/examples/turn_off_gpu.sh"
    if [[ "$based" == "debian" ]]; then
        #cp example1.service normal.service
        #sed "s|$FIND|$DEBIANREPLACE|g" example1.service > normal.service // FIND REPLACE OPTION
        # LINE OPTION
        log "Editing services"
        {
            editservice "example1" "normal" 6 "$DEBIANREPLACE"
            editservice "example2" "sleep" 7 "$DEBIANREPLACE"
        } || {
            log "The files example1 and example2 not found"
            exit 1
        }
    fi

    if [[ "$based" == "fedora" ]]; then
        log "Editing services"
        {
            editservice "example1" "normal" 6 "$FEDORAREPLACE"
            editservice "example2" "sleep" 7 "$FEDORAREPLACE"
        } || {
            log "The files example1 and example2 not found"
            exit 1
        }
    fi

    if [[ "$based" == "arch" ]]; then
        log "Editing services"
        {
            editservice "example1" "normal" 6 "$ARCHREPLACE"
            editservice "example2" "sleep" 7 "$ARCHREPLACE"
        } || {
            log "The files example1 and example2 not found"
            echo "Error installing, enable verbose with -v"
            exit 1
        }
    fi

    #MOVE SERVICES CREATED TO USER LOCAL SERVICES
    log "Moving services"
    $ISROOT mv $DIR/normal.service $SERVICESLOCAL/disablegpu.service
    $ISROOT mv $DIR/sleep.service $SERVICESLOCAL/disablegpusleep.service

    log "Enabling the service on system"
    $ISROOT systemctl enable --now disablegpusleep.service disablegpu.service

}

enable_acpi(){
    log "Enabling module acpi_call on kernel"

    if ! $ISROOT modprobe acpi_call > /dev/null 2>&1; then
       log "Error enabling acpi_call on Kernel"
       log "Cancelling install"
       exit 1
    fi

    {
        echo "acpi_call" | $ISROOT tee -a /etc/modules-load.d/macpi_call.conf &> /dev/null
    } || {
        log "Error creating macpi_call.conf on modules-load.d/"
        log "Cancelling install"
        exit 1
    }
}

acpi_call(){
    #IF NOT PASSED ARGUMENT EXIT FUNCTION
    if [[ $1 == "" ]]; then
        return 1
    fi

    #VERIFY IF ACPI CALL DKMS IS INSTALLED
    if ls $1 &> /dev/null; then
        log "Acpi_call is installed"
        return 0
    fi

    log "Instaling acpi call dkms"

    if [[ "$OS_NAME" == "debian" ]]; then
        $ISROOT apt install acpi-call-dkms -y
    elif [[ "$OS_NAME" == "fedora" ]]; then
        $ISROOT dnf copr enable rhea/acpi_call
        $ISROOT dnf install acpi_call-dkms -y
    else
        $ISROOT pacman -Syu acpi_call-dkms -y
    fi

    enable_acpi
}

install(){
    if [[ "$OS_NAME" == "debian" ]]; then
        log "System is Debian based, configuring for it"
        acpi_call "/usr/share/doc/acpi-call-dkms/"
        handle_services $OS_NAME
        exit 0

    elif [[ "$OS_NAME" == "fedora" ]]; then
        log "System is Fedora based, configuring for it"
        acpi_call "/usr/src/acpi_call-1.*/"
        exit 0
    
    elif [[ "$OS_NAME" == "arch" ]]; then
        log "System is Arch based, configuring for it"
        acpi_call "/usr/src/acpi_call-1.*"
        exit 0
    else
        log "System based not compatible exiting"
        exit 1

    fi
}

echo "initializing script..."

if [[ "$EUID" -eq 0  ]]; then
    #IF ROOT IS PASSED BLANK VARIABLE, COMMAND DONT NEED SUDO MORE
    ISROOT=""
elif command -v sudo &> /dev/null; then
    ISROOT="sudo"
fi

echo $ISROOT

if ls "$SERVICESLOCAL" &> /dev/null; then
    HAS_SYSTEMD=true
else
    echo "Exiting system hasn't systemd init"
    exit 1
fi

if [[ "$1" == "-v" || "$2" == "-v" ]]; then
    echo "Verbose enabled"
    VERBOSE=true
fi

if [[ "$1" == "-u" ]]; then
    echo "Uninstalling"
    handle_uninstall
    exit 0
fi

echo "Installing"
echo "For uninstall use -u"
#install
enable_acpi