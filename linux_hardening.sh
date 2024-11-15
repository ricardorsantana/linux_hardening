#!/bin/bash

# Hardening Ubuntu
# Nome: LNXHardening
# Descrição: Script de automação para aplicação de hardening de servidores linux
# Referência: # https://github.com/euandros/lnxhardening/blob/main/lnxhardening.sh
# Função para exibir ASCII art e informações do menu

clear
echo ""
echo ""
echo "==================================================="
echo "LNX Hardening - Script de Automação para Servidores"
echo "==================================================="
echo "Usuário: $(whoami)"
echo "Data e Hora de Execução: $(date '+%Y-%m-%d %H:%M:%S')"
echo "==================================================="
echo ""
echo ""

# Garanta que o script seja executado como root
if [[ $EUID -ne 0 ]]; then
   echo ""
   echo "Este script deve ser executado como root" 1>&2
   echo "Tente 'sudo ./linux_hardening.sh' "
   echo ""
   exit 1
fi

echo "Aplicando o Hardening ao Sistema Linux Ubuntu/Debian..."
# Passo 1: Documentar as informações do host
echo -e "\e[33mPasso 1: Documentando as informações do host\e[0m"
echo "Hostname: $(hostname)"
echo "Versão do Kernel: $(uname -r)"
echo "Distribuição: $(lsb_release -d | cut -f2)"
echo "Informações da CPU: $(lscpu | grep 'Modelo')"
echo "Informações de memória: $(free -h | awk '/Mem/{print $2}')"
echo "Informações do disco: $(lsblk | grep disco)"
echo ""
 
# Passo 2: Proteção do BIOS
echo -e "\e[33mPasso 2: Proteção do BIOS\e[0m"
echo "Verificando se a proteção do BIOS está ativada..."
if [ -f /sys/devices/system/cpu/microcode/reload ]; then
  echo "A proteção do BIOS está ativada"
else
  echo "A proteção do BIOS não está ativada"
fi
echo ""
 
# Passo 3: Criptografia do disco rígido
echo -e "\e[33mPasso 3: Criptografia do disco rígido\e[0m"
echo "Verificando se a criptografia do disco rígido está ativada..."
if [ -d /etc/luks ]; then
  echo "A criptografia do disco rígido está ativada"
else
  echo "A criptografia do disco rígido não está ativada"
fi
echo ""
 
# Passo 4: Particionamento do disco
echo -e "\e[33mPasso 4: Particionamento do disco\e[0m"
echo "Verificando se o particionamento do disco já foi feito..."
if [ -d /home -a -d /var -a -d /usr ]; then
  echo "O particionamento do disco já foi feito"
else
  echo "O particionamento do disco não foi feito ou está incompleto"

sudo fdisk /dev/sda
sudo mkfs.ext4 /dev/sda1
sudo mkswap /dev/sda2
sudo swapon /dev/sda2
sudo mount /dev/sda1 /mnt
echo ""
fi

# Passo 5: Bloquear o diretório de boot
echo -e "\e[33mPasso 5: Bloquear o diretório de boot\e[0m"
echo "Bloqueando o diretório de boot..."
sudo chmod 700 /boot
echo ""

# Passo 6: Desativar o uso de USB
echo -e "\e[33mPasso 6: Desativar o uso de USB\e[0m"
echo "Desativando o uso de USB..."
echo 'blacklist usb-storage' | sudo tee /etc/modprobe.d/blacklist-usbstorage.conf
echo ""
 
# Passo 7: Atualizar o sistema
echo -e "\e[33mPasso 7: Atualizar o sistema\e[0m"
sudo apt-get update && sudo apt-get upgrade -y
echo ""
 
# Passo 8: Verificar os pacotes instalados
echo -e "\e[33mPasso 8: Verificar os pacotes instalados\e[0m"
dpkg --get-selections | grep -v deinstall
echo ""
 
# Passo 9: Verificar as portas abertas
echo -e "\e[33mPasso 9: Verificar as portas abertas\e[0m"
sudo netstat -tulpn
echo ""
 
# Passo 10: Segurança do SSH
echo -e "\e[33mPasso 10: Reforçar a segurança do SSH\e[0m"
sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/g' /etc/ssh/sshd_config
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
sudo systemctl restart ssh
echo ""
 
# Passo 11: Ativar o SELinux
echo -e "\e[33mPasso 11: Ativar o SELinux\e[0m"
echo "Verificando se o SELinux está instalado..."
if [ -f /etc/selinux/config ]; then
  echo "O SELinux já está instalado"
else
  echo "O SELinux não está instalado, instalando agora..."
  sudo apt-get install policycoreutils selinux-utils selinux-basics -y
fi
echo "Ativando o SELinux..."
sudo selinux-activate
echo ""
 
# Passo 12: Configurar parâmetros de rede
echo -e "\e[33mPasso 12: Configurar parâmetros de rede\e[0m"
echo "Configurando parâmetros de rede..."
sudo sysctl -p
echo ""
 
# Passo 13: Gerenciar políticas de senha
echo -e "\e[33mPasso 13: Gerenciar políticas de senha\e[0m"
echo "Modificando as políticas de senha..."
sudo sed -i 's/PASS_MAX_DAYS\t99999/PASS_MAX_DAYS\t90/g' /etc/login.defs
sudo sed -i 's/PASS_MIN_DAYS\t0/PASS_MIN_DAYS\t7/g' /etc/login.defs
sudo sed -i 's/PASS_WARN_AGE\t7/PASS_WARN_AGE\t14/g' /etc/login.defs
echo ""
 
# Passo 14: Permissões e verificações
echo -e "\e[33mPasso 14: Permissões e verificações\e[0m"
echo "Configurando as permissões corretas em arquivos sensíveis..."
sudo chmod 700 /etc/shadow /etc/gshadow /etc/passwd /etc/group
sudo chmod 600 /boot/grub/grub.cfg
sudo chmod 644 /etc/fstab /etc/hosts /etc/hostname /etc/timezone /etc/bash.bashrc
echo "Verificando a integridade dos arquivos do sistema..."
sudo debsums -c
echo ""
 
# Passo 15: Reforço adicional do processo de distribuição
echo -e "\e[33mPasso 15: Reforço adicional do processo de distribuição\e[0m"
echo "Desabilitando despejos de núcleo..."
sudo echo '* hard core 0' | sudo tee /etc/security/limits.d/core.conf
echo "Restringindo o acesso aos logs do kernel..."
sudo chmod 640 /var/log/kern.log
echo "Configurando as permissões corretas nos scripts de inicialização..."
sudo chmod 700 /etc/init.d/*
echo ""
 
# Passo 16: Remover serviços desnecessários
echo -e "\e[33mPasso 16: Remover serviços desnecessários\e[0m"
echo "Removendo serviços desnecessários..."
sudo apt-get purge rpcbind rpcbind-* -y
sudo apt-get purge nis -y
echo ""
 
# Passo 17: Verificar a segurança dos arquivos-chave
echo -e "\e[33mPasso 17: Verificar a segurança dos arquivos-chave\e[0m"
echo "Verificando a segurança dos arquivos-chave..."
sudo find /etc/ssh -type f -name 'ssh_host_*_key' -exec chmod 600 {} \;
echo ""
 
# Passo 18: Limitar o acesso root usando o SUDO
echo -e "\e[33mPasso 18: Limitar o acesso root usando o SUDO\e[0m"
echo "Limitando o acesso root usando o SUDO..."
sudo apt-get install sudo -y
sudo groupadd admin
sudo usermod -aG admin "$(whoami)"
sudo sed -i 's/%sudo\tALL=(ALL:ALL) ALL/%admin\tALL=(ALL:ALL) ALL/g' /etc/sudoers
echo ""
 
# Passo 19: Permitir apenas root para acessar o CRON
echo -e "\e[33mPasso 19: Restringir o acesso ao CRON\e[0m"
echo "Permitindo apenas root para acessar o CRON..."
sudo chmod 600 /etc/crontab
sudo chown root:root /etc/crontab
sudo chmod 600 /etc/cron.hourly/*
sudo chmod 600 /etc/cron.daily/*
sudo chmod 600 /etc/cron.weekly/*
sudo chmod 600 /etc/cron.monthly/*
sudo chmod 600 /etc/cron.d/*
echo ""
 
# Passo 20: Configurações básicas de acesso remoto e SSH
echo -e "\e[33mPasso 20: Configurações básicas de acesso remoto e SSH\e[0m"
echo "Desabilitando o login root via SSH..."
sudo sed -i 's/PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config
echo "Desabilitando autenticação por senha via SSH..."
etsudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
echo "Desabilitando o encaminhamento X11 via SSH..."
sudo sed -i 's/X11Forwarding yes/X11Forwarding no/g' /etc/ssh/sshd_config
echo "Recarregando o serviço SSH..."
sudo systemctl reload ssh
echo ""
 
# Passo 21: Desabilitar o Xwindow
echo -e "\e[33mPasso 21: Desabilitar o Xwindow\e[0m"
echo "Desabilitando o Xwindow..."
sudo systemctl set-default multi-user.target
echo ""
 
# Passo 22: Minimizar a instalação de pacotes
echo -e "\e[33mPasso 22: Minimizar a instalação de pacotes\e[0m"
echo "Instalando apenas pacotes essenciais..."
sudo apt-get install --no-install-recommends -y systemd-sysv apt-utils
sudo apt-get --purge autoremove -y
echo ""
 
# Passo 23: Verificar contas com senhas vazias
echo -e "\e[33mPasso 23: Verificar contas com senhas vazias\e[0m"
echo "Verificando contas com senhas vazias..."
sudo awk -F: '($2 == "" ) {print}' /etc/shadow
echo ""
 
# Passo 24: Monitorar atividades do usuário
echo -e "\e[33mPasso 24: Monitorar atividades do usuário\e[0m"
echo "Instalando auditd para monitoramento de atividades do usuário..."
sudo apt-get install auditd -y
echo "Configurando o auditd..."
sudo echo "-w /var/log/auth.log -p wa -k authentication" | sudo tee -a /etc/audit/rules.d/audit.rules
sudo echo "-w /etc/passwd -p wa -k password-file" | sudo tee -a /etc/audit/rules.d/audit.rules
sudo echo "-w /etc/group -p wa -k group-file" | sudo tee -a /etc/audit/rules.d/audit.rules
sudo systemctl restart auditd
echo ""
 
# Passo 25: Instalar e configurar fail2ban
echo -e "\e[33mPasso 25: Instalar e configurar fail2ban\e[0m"
echo "Instalando fail2ban..."
sudo apt-get install fail2ban -y
echo "Configurando fail2ban..."
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sudo sed -i 's/bantime  = 10m/bantime  = 1h/g' /etc/fail2ban/jail.local
sudo sed -i 's/maxretry = 5/maxretry = 3/g' /etc/fail2ban/jail.local
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
echo ""
 
# Passo 26: Detecção de rootkits
echo -e "\e[33mPasso 26: Instalando e executando a detecção de rootkits...\e[0m"
sudo apt-get install rkhunter -y
sudo rkhunter --update
sudo rkhunter --propupd
sudo rkhunter --check
echo ""
 
# Passo 27: Monitorar logs do sistema
echo -e "\e[33mPasso 27: Monitorar logs do sistema\e[0m"
echo "Instalando logwatch para monitoramento de logs do sistema..."
sudo apt-get install logwatch -y
echo ""

# Passo 28: Ajustando Timezone e NTP
echo -e "\e[33mPasso 28: Ajustando a Localidade Timezone e NTP do Sistema...\e[0m"
sudo locale-gen pt_BR.UTF-8
sudo timedatectl set-timezone "America/Sao_Paulo"
sudo sed -i 's/#NTP=/NTP=a.st1.ntp.br/g' /etc/systemd/timesyncd.conf
sudo sed -i 's/#FallbackNTP=ntp.ubuntu.com/NTP=a.ntp.br/g' /etc/systemd/timesyncd.conf
sudo systemctl restart systemd-timesyncd.service
echo ""

# Passo 29: Adicionando Banner no Login
echo -e "\e[33mPasso 29: Adicionando Banner no Login...\e[0m"
sudo sed -i 's/#Banner none/Banner \/etc\/nano_banner/g' /etc/ssh/sshd_config
sudo mv nano_banner /etc/nano_banner
sudo systemctl restart ssh
cat /etc/nano_banner
echo ""

## Passo 30: Ativar autenticação de dois fatores
#echo -e "\e[33mPasso 30: Ativar autenticação de dois fatores\e[0m"
#echo "Instalando o Google Authenticator para autenticação de dois fatores..."
#sudo apt-get install libpam-google-authenticator -y
#echo "Ativando autenticação de dois fatores..."
#sudo google-authenticator
#echo "Editando as configurações do PAM para autenticação de dois fatores..."
#sudo sed -i 's/ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/g' /etc/ssh/sshd_config
#sudo sed -i 's/UsePAM no/UsePAM yes/g' /etc/ssh/sshd_config
#sudo sed -i 's/#auth required pam_google_authenticator.so/auth required 
