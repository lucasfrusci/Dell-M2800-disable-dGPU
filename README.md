# Dell-M2800-disable-dGPU
Script Simples para desatiar a dGPU do laptop Dell M2800

O script foi testado no Arch-Linux, mas funciona em qualquer Distro, Prescisa do acpi-call-dkms.
Tem tres modos de fazer isso.

***Recomendo fazer o 1 ou o 2 pq é modular é mais facil de desativar.***  

## Modo 1:
Esse modo usa o script bash, é basicamente o modo 2 só que automatizado.
```
> bash install.sh
```
`-u para desinstalar -v para verbose.`
## Modo 2:
Esse modo usa o systemd pra executar o serviço toda vez que o pc liga ou volta do sleep.

Instala o acpi-call-dkms do repositorio da sua Distro;

Copiar o arquivo `disablegpu.service disablegpusleep.service` para a pasta "/usr/lib/systemd/user/" ou "/etc/systemd/user/";
```
> sudo cp disablegpu.service disablegpusleep.service /usr/lib/systemd/user/
```

Ativar o modulo acpi_call no kernel:
```
> modprobe acpi_call

> systemctl enable --now disablegpu disablegpusleep
```
Ok, agora é so reiniciar que a placa de video vai estar desligada, desabilita o serviço e reinicia o pc pra ligar novamente a dGPU.

## Modo 3:
Esse modo usa tmpfiles para executar na inicializaão do sistema.

Instala o acpi-call-dkms do repositorio da sua Distro;

Copia dos arquivos das pastas `modprobe.d e tmpfiles.d` pra a pasta do mesmo nome na sua distro dentro de /etc ou /usr;
```
> sudo cp radeon.conf /etc/modprobe.d/

> sudo cp acpi_call.conf removegpu.conf /etc/tmpfiles.d/
```

Ativa o modulo acpi_call iniciar junto com boot.
```
> sudo echo acpi_call >> /etc/modules-load.d/modules.conf
```

Executa esse comando no Terminal:

```
> modprobe acpi_call
```
Ok, agora é so reiniciar que a placa de video vai estar desligada.