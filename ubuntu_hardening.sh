#!/bin/bash

# Hardening Ubuntu
# Descrição: Script de automação para aplicação de hardening de servidores linux
# Referência: # https://github.com/euandros/lnxhardening/blob/main/lnxhardening.sh
#               https://github.com/captainzero93/security_harden_linux/blob/main/improved_harden_linux.sh
# Função para exibir ASCII art e informações do menu


#---------------------------------------------------------------------------------
#                              VARIÁVEIS DO SISTEMA 
#---------------------------------------------------------------------------------

# Variaveis Globais
VERSION="1.0"
VERBOSE=false
BACKUP_DIR="/root/hardening_backup_$(date +%Y%m%d_%H%M%S)"
LOG_FILE="/var/log/ubuntu_hardening.log"
SCRIPT_NAME=$(basename "$0")

#---------------------------------------------------------------------------------
#                              FUNÇÕES DO SISTEMA 
#---------------------------------------------------------------------------------

# Função LOG
log() {
    local message="$(date '+%Y-%m-%d %H:%M:%S'): $1"
    echo "$message" | sudo tee -a "$LOG_FILE"
    $VERBOSE && echo "$message"
}

# Funcão para tratamento de erros
handle_error() {
    log "Error: $1"
    exit 1
}

# Função para instalação de pacotes
install_package() {
    log "Installing $1..."
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "$1" || handle_error "Falha ao instalar $1"
}

# Funcão para exibir a versão
display_version() {
    echo "Script de hardening do Ubuntu Linux - Versao: v$VERSION"
    exit 0
}

# Função para verificar se o script está sendo executado como root
check_permissions() {
    if [ "$EUID" -ne 0 ]; then
        echo ""
        echo "Este script deve ser executado com privilegios de root (sudo)."
        echo "Por favor, execute novamente usando: 'sudo ./$0' "
        echo ""
        exit 1
    fi
}

# Função para verificar requisitos do sistema
check_requirements() {
    if ! command -v lsb_release &> /dev/null; then
        handle_error "Comando lsb_release nao encontrado. Este script requer um sistema baseado em Ubuntu."
    fi

    local os_name=$(lsb_release -si)
    local os_version=$(lsb_release -sr)

    if [[ "$os_name" != "Ubuntu" && "$os_name" != "Debian" ]]; then
        handle_error "Este script e projetado para sistemas baseados em Ubuntu ou Debian. SO detectado: $os_name"
    fi

    if [[ $(echo "$os_version < 18.04" | bc) -eq 1 ]]; then
        handle_error "Este script requer Ubuntu 18.04 ou posterior. Versao detectada: $os_version"
	elif [[ "$os_name" == "Debian" && $(echo "$os_version < 12.0" | bc) -eq 1 ]]; then
	handle_error "Este script requer Debian 12.0 ou posterior. Versao detectada: $os_version"
    fi

    log "Verificacao de requisitos do sistema aprovada. SO identificado: $os_name $os_version"
}

#---------------------------------------------------------------------------------
#                              FUNÇÕES DE BACKUP E RESTORE 
#---------------------------------------------------------------------------------

# Função para backup de arquivos
backup_files() {
    sudo mkdir -p "$BACKUP_DIR" || handle_error "Falha ao criar diretório de backup"
    
    local files_to_backup=(
        "/etc/default/grub"
        "/etc/ssh/sshd_config"
        "/etc/pam.d/common-password"
        "/etc/login.defs"
        "/etc/sysctl.conf"
    )

    for file in "${files_to_backup[@]}"; do
        if [ -f "$file" ]; then
            sudo cp "$file" "$BACKUP_DIR/" || log "Warning: Falha ao fazer backup $file"
        else
            log "Warning: $file Nao encontrado, ignorando o backup"
        fi
    done
    
    log "Backup criado em: $BACKUP_DIR"
}

# Função para restaurar backup
restore_backup() {
    if [ -d "$BACKUP_DIR" ]; then
        for file in "$BACKUP_DIR"/*; do
            sudo cp "$file" "$(dirname "$(readlink -f "$file")")" || log "Warning: Falha ao restaurar $(basename "$file")"
        done
        log "Configuracoes restauradas de $BACKUP_DIR"
    else
        log "Diretorio de backup nao encontrado, nao e possivel restaurar."
    fi
}

#---------------------------------------------------------------------------------
#                              MENU DO SISTEMA 
#---------------------------------------------------------------------------------

# Função para exibir menu ajuda
display_help() {
    echo "Uso: sudo ./$SCRIPT_NAME [OPTIONS]"
    echo "Options:"
    echo "  -h, --help     Exibe esta mensagem de ajuda"
    echo "  -v, --verbose  Habilita saida detalhada"
    echo "  --version      Exibe a versao do script"
    echo "  --dry-run      Executa o script em modo TESTE sem fazer alteracoes no sistema"
    echo "  --restore      Restaurar o sistema a partir do backup mais recente"
    exit 0
}



# Função principal
main() {
    local dry_run=false

    # Analisar argumentos de linha de comando
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                display_help
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            --version)
                display_version
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            --restore)
                restore_backup
                exit 0
                ;;
            *)
                echo "Opção desconhecida: $1"
                display_help
                ;;
        esac
    done

    check_permissions
    check_requirements
    backup_files

    if $dry_run; then
        log "Executando teste. Nenhuma alteração será feita."
    else
        function_display

#        update_system
#        setup_firewall
#        setup_fail2ban
#        setup_clamav
#        disable_root
#        remove_packages
#        setup_audit
#        disable_filesystems
#        secure_boot
#        configure_ipv6
#        setup_apparmor
#        setup_ntp
#        setup_aide
#        configure_sysctl
#        additional_security
#        setup_automatic_updates
    fi
    
    log "Hardening aplicado com sucesso!"

    if ! $dry_run; then
        # Pergunte ao usuário se ele deseja reiniciar
        read -p "Deseja reiniciar o sistema agora para aplicar todas as alterações? (y/N): " restart_now
        case $restart_now in
            [Yy]* ) 
                log "Reiniciando o sistema..."
                sudo reboot
                ;;
            * ) 
                log "Reinicie o sistema manualmente para aplicar todas as alterações."
                ;;
        esac
    fi
}

#---------------------------------------------------------------------------------
#                              INICIO DO SCRIPT 
#---------------------------------------------------------------------------------

# Função display
function_display() {
    log "Iniciando script $SCRIPT_NAME"
    clear
    echo ""
    echo ""
    echo "======================================================"
    echo "Ubuntu Hardening - Script de Automação para Servidores"
    echo "======================================================"
    echo "Usuário: $(whoami)"
    echo "Data e Hora de Execução: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "======================================================"
    echo ""
    echo ""
}



#---------------------------------------------------------------------------------
#                              FIM DO SCRIPT 
#---------------------------------------------------------------------------------


# Execute a função principal
main "$@"


#---------------------------------------------------------------------------------
#---------------------------------------------------------------------------------
