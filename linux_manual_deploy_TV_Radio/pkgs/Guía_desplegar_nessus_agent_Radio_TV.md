# Desplegar Nessus Agent

# Uso

* Se debe copiar la carpeta entera *pkgs* a la máquina donde se quiera desplegar el agente, comprimida no pesa mas de 150 mb.
* Se debe de acceder a la maquina como administrador (root) o escalar privilegios a root para poder instalar el agente.
* Descomprimir pkgs
* Entrar en la carpeta
* Revisar permisso de Desplegar_nessus_agent.sh

```bash
chmod 700 Desplegar_nessus_agent.sh
```

* Ejecutar Desplegar_nessus_agent.sh

```bash
./Desplegar_nessus_agent.sh
```

* El script preguntara que queremos realizar

```bash
Seleccione una opción:
1) Instalar Nessus Agent
2) Desinstalar Nessus Agent
3) Salir
Elija una opción (1-3):
```

* Si pulsamos Instalar nos preguntara a que grupo queremos añadir la máquina

```
Instalando Nessus Agent...
Seleccione el grupo al que desea añadir el agente:
1) ING_TV-SOPTEC
2) ING_TV-ATSIN
3) INGTV-Des_Produccion
4) ING_RADIO
5) ING_RADIO-Alcance_TI
Elija una opción (1-5):
```

* La instalacion habrá concluido cuando en pantalla aparezca

```bash
Complete!
[info] [agent] Successfully linked to sensor.cloud.tenable.com:443
```
