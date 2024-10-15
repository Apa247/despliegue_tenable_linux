#!/bin/bash

# Variables
NESSUS_KEY="e54e8015d23c427c9a7fc2574b94ba08c9b1580c6c2dd9a828eeedbc39b080e4"
AGENT_GROUP=""
AGENT_HOST="sensor.cloud.tenable.com"
AGENT_PORT=443
PKGS_PATH="."
GPG_KEY="tenable-4096.gpg"
AGENT_FILE=""

# Función para seleccionar el grupo
select_group() {
    echo "Seleccione el grupo al que desea añadir el agente:"
    PS3="Elija una opción (1-5): "
    options=("ING_TV-SOPTEC" "ING_TV-ATSIN" "INGTV-Des_Produccion" "ING_RADIO" "ING_RADIO-Alcance_TI")

    select group in "${options[@]}"; do
        case $group in
            "ING_TV-SOPTEC"|"ING_TV-ATSIN"|"INGTV-Des_Produccion"|"ING_RADIO"|"ING_RADIO-Alcance_TI")
                AGENT_GROUP=$group
                echo "Grupo seleccionado: $group"
                break
                ;;
            *) echo "Opción inválida, intente nuevamente." ;;
        esac
    done
}

# Detectar sistema operativo y definir archivo de agente
detect_os_and_agent_file() {
    if [[ -f /etc/redhat-release ]]; then
        OS="RedHat"
        VERSION_ID=$(grep -oE '[0-9]+' /etc/redhat-release | head -n1)
        case $VERSION_ID in
            7) AGENT_FILE="NessusAgent-10.7.3-el7.x86_64.rpm" ;; # CentOS/RedHat 7
            8) AGENT_FILE="NessusAgent-10.7.3-el8.x86_64.rpm" ;; # CentOS/RedHat 8
            9) AGENT_FILE="NessusAgent-10.7.3-el9.x86_64.rpm" ;; # CentOS/RedHat 9
            *) echo "Versión de RedHat no soportada."; exit 1 ;;
        esac
    elif [[ -f /etc/debian_version ]]; then
        OS="Debian"
        VERSION_ID=$(lsb_release -cs)
        case $VERSION_ID in
            "buster") AGENT_FILE="NessusAgent-10.7.3-debian10_amd64.deb" ;; # Debian 10
            "bullseye") AGENT_FILE="NessusAgent-10.7.3-debian10_amd64.deb" ;; # Debian 11
            "bookworm") AGENT_FILE="NessusAgent-10.7.3-debian10_amd64.deb" ;; # Debian 12
            "xenial") AGENT_FILE="NessusAgent-10.7.3-ubuntu1604_amd64.deb" ;; # Ubuntu 16.04
            "bionic") AGENT_FILE="NessusAgent-10.7.3-ubuntu1604_amd64.deb" ;; # Ubuntu 18.04
            "focal") AGENT_FILE="NessusAgent-10.7.3-ubuntu1604_amd64.deb" ;; # Ubuntu 20.04
            "jammy") AGENT_FILE="NessusAgent-10.7.3-ubuntu1604_amd64.deb" ;; # Ubuntu 22.04
            *) echo "Versión de Debian/Ubuntu no soportada."; exit 1 ;;
        esac
    else
        echo "Sistema operativo no soportado."
        exit 1
    fi
}

# Función para eliminar Nessus Agent completamente
purge_agent() {
    echo "Eliminando completamente el Nessus Agent si ya está instalado..."
    if [[ $OS == "RedHat" ]]; then
        if rpm -q NessusAgent; then
            /opt/nessus_agent/sbin/nessuscli agent unlink --force
            systemctl stop nessusagent
            systemctl disable nessusagent
            yum remove -y NessusAgent
            rm -rf /opt/nessus_agent /etc/nessus /var/nessus /var/log/nessus /var/lib/nessus /var/run/nessus
            echo "Eliminación completada."
        else
            echo "Nessus Agent no está instalado."
        fi
    elif [[ $OS == "Debian" ]]; then
        if dpkg -l | grep -q nessus-agent; then
            /opt/nessus_agent/sbin/nessuscli agent unlink --force
            systemctl stop nessusagent
            systemctl disable nessusagent
            dpkg --purge nessus-agent
            rm -rf /opt/nessus_agent /etc/nessus /var/nessus /var/log/nessus /var/lib/nessus /var/run/nessus
            echo "Eliminación completada."
        else
            echo "Nessus Agent no está instalado."
        fi
    fi
}

# Función para instalar Nessus Agent
install_agent() {
    echo "Instalando Nessus Agent..."

    # Seleccionar grupo
    select_group

    # Detectar OS y archivo de agente
    detect_os_and_agent_file

    # Ruta actual
    CURRENT_PATH=$(pwd)

    # Eliminar completamente Nessus Agent si ya estaba instalado
    purge_agent

    # Importar GPG (solo RedHat)
    if [[ $OS == "RedHat" ]]; then
        rpm --import "$CURRENT_PATH/$GPG_KEY"
    fi

    # Instalar paquete
    if [[ $OS == "RedHat" ]]; then
        yum localinstall -y "$CURRENT_PATH/$AGENT_FILE"
    elif [[ $OS == "Debian" ]]; then
        apt update -y
        apt install -y "$CURRENT_PATH/$AGENT_FILE"
    fi

    # Verifica si el archivo nessuscli existe antes de continuar
    if [[ -f /opt/nessus_agent/sbin/nessuscli ]]; then
        # Vincular el agente
        /opt/nessus_agent/sbin/nessuscli agent link --cloud --key="$NESSUS_KEY" --groups="$AGENT_GROUP"
    else
        echo "Error: NessusCLI no se encontró después de la instalación."
        exit 1
    fi

    # Iniciar servicio Nessus
    systemctl enable nessusagent
    systemctl start nessusagent

    echo "Instalación y configuración completadas."
}

# Función para desinstalar Nessus Agent y limpiar restos
uninstall_agent() {
    echo "Desinstalando Nessus Agent..."

    # Detectar OS
    detect_os_and_agent_file

    # Eliminar completamente Nessus Agent si ya estaba instalado
    purge_agent

    echo "Desinstalación y limpieza completadas."
}

# Menú principal
echo "Seleccione una opción:"
PS3="Elija una opción (1-3): "
options=("Instalar Nessus Agent" "Desinstalar Nessus Agent" "Salir")
select opt in "${options[@]}"; do
    case $opt in
        "Instalar Nessus Agent")
            install_agent
            break
            ;;
        "Desinstalar Nessus Agent")
            uninstall_agent
            break
            ;;
        "Salir")
            echo "Saliendo..."
            exit 0
            ;;
        *) echo "Opción inválida, intente nuevamente." ;;
    esac
done