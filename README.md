# Dell-M2800-disable-dGPU
Script Simples para desatiar a dGPU do laptop Dell M2800

O script foi testado no Arch-Linux, mas funciona em qualquer Distro, Prescisa do acpi-call-dkms.
Tem dois modos de fazer isso.

Modo 1:
Esse modo usa tmpfiles para executar na inicializaão do sistema.

Instala o acpi-call-dkms do repositorio da sua Distro;

Copia dos arquivos das pastas "modprobe.d" e "tmpfiles.d" pra a pasta do mesmo nome na sua distro dentro de /etc ou /usr;

Exemplo:
"/etc/modprobe.d/"

Executa esse comando no Terminal:

modprobe acpi_call

Ok, agora é so reiniciar que a placa de video vai estar desligada.

Modo 2:
Esse modo usa o systemd pra executar o serviço toda vez que o pc liga ou volta do sleep.

Instala o acpi-call-dkms do repositorio da sua Distro;

copia o arquivo "disablegpusleep.service" para a pasta "/usr/lib/systemd/user/" ou "/etc/systemd/user/";

Executa esses comandos no Terminal:

modprobe acpi_call

systemctl enable disablegpusleep

Ok, agora é so reiniciar que a placa de video vai estar desligada, desabilita o serviço e reinicia o pc pra ligar novamente a dGPU.


