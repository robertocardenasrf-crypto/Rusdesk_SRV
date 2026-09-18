# Rusdesk_SRV

Infraestructura para un servidor [RustDesk](https://rustdesk.com/) autoalojado
(`hbbs` + `hbbr`), pensada para desplegarse en una VM Ubuntu Server local (pruebas)
y luego migrar/replicarse hacia el mecanismo de acceso externo elegido
(Tailscale, VPS relay, o DDNS + port forwarding).

El plan completo con el análisis de opciones y la hoja de ruta por fases está
en [`docs/PLAN.md`](docs/PLAN.md).

## Estado

Este repo cubre el **código y la configuración del servidor** (Fases 3-6 del
plan). Las Fases 1-2 (instalar VMware Workstation, crear las VMs, configurar
red bridged) son pasos manuales en tu propio equipo — no se pueden ejecutar
desde este entorno, ya que corre en un contenedor aislado en la nube, no en tu
PC.

## Estructura

```
.
├── docker-compose.yml       # hbbs + hbbr, modo --net=host
├── .env.example             # variables de entorno (copiar a .env)
├── rustdesk-server/data/    # claves y estado del servidor (NO se versiona)
├── scripts/
│   ├── install-docker.sh    # Fase 3 — instala Docker en Ubuntu Server
│   ├── deploy.sh            # Fase 3 — levanta hbbs/hbbr, imprime la key pública
│   ├── backup-keys.sh       # Fase 4 — respalda id_ed25519 / id_ed25519.pub
│   └── setup-tailscale.sh   # Fase 5 — instala Tailscale (opción recomendada)
└── docs/
    └── PLAN.md               # plan original completo
```

## Uso rápido (en la VM servidor Ubuntu Server)

1. Cloná este repo en la VM:
   ```bash
   git clone <url-de-este-repo> Rusdesk_SRV
   cd Rusdesk_SRV
   ```

2. Instalá Docker:
   ```bash
   ./scripts/install-docker.sh
   ```

3. Levantá el servidor:
   ```bash
   ./scripts/deploy.sh
   ```
   Esto crea `.env` desde `.env.example` si no existe, levanta `hbbs`/`hbbr`
   con `docker compose`, y muestra la clave pública del servidor una vez
   generada.

4. Configurá cada cliente RustDesk: **Configuración > Red > ID/Relay Server**
   con la IP del servidor y la clave pública impresa en el paso anterior.

5. Respaldá las claves fuera de la VM:
   ```bash
   ./scripts/backup-keys.sh ~/backups-rustdesk
   ```

## Acceso externo (Fase 5)

Según lo definido en `docs/PLAN.md` sección 4, la decisión pendiente es entre:

- **Tailscale** (recomendado si solo vas a conectar tus propios dispositivos):
  ```bash
  ./scripts/setup-tailscale.sh
  ```
  Después, apuntá los clientes RustDesk a la IP `100.x.x.x` de Tailscale en vez
  de la IP LAN.

- **VPS como servidor principal** (Oracle Cloud Free Tier u otro): migrar este
  mismo `docker-compose.yml` al VPS, abrir los puertos 21115-21119 (TCP) y
  21116 (UDP) en el firewall del proveedor y en `ufw`/`iptables` del VPS, y
  usar la IP pública del VPS como `RUSTDESK_RELAY_HOST`.

- **DDNS + port forwarding**: solo viable si el ISP asigna IP pública real
  (sin CGNAT). Verificar esto antes de invertir tiempo en esta opción.

## Puertos que necesita el servidor

| Puerto | Protocolo | Uso |
|---|---|---|
| 21115 | TCP | Prueba de tipo de NAT |
| 21116 | TCP + UDP | Registro de ID / heartbeat |
| 21117 | TCP | Relay (hbbr) |
| 21118 | TCP | Cliente web (opcional) |
| 21119 | TCP | Relay web (opcional) |
