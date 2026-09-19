# Rusdesk_SRV

Infraestructura para un servidor [RustDesk](https://rustdesk.com/) autoalojado
(`hbbs` + `hbbr`), pensada para desplegarse en una VM Ubuntu Server local (pruebas)
y luego migrar/replicarse hacia el mecanismo de acceso externo elegido
(Tailscale, VPS relay, o DDNS + port forwarding).

El plan completo con el análisis de opciones y la hoja de ruta por fases está
en [`docs/PLAN.md`](docs/PLAN.md).

## Estado

**Desplegado y probado.** El servidor corre en una VM Ubuntu Server 26.04
(VMware Workstation Pro), con Tailscale como mecanismo de acceso externo —
la VM está detrás de CGNAT (sin IP pública real), así que DDNS + port
forwarding no era viable. Confirmado control remoto exitoso desde un cliente
móvil con WiFi apagado (solo datos), validando que el acceso funciona fuera
de la red local. Detalle completo del estado en
[`docs/PLAN.md`](docs/PLAN.md) sección 5.

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
│   ├── setup-tailscale.sh   # Fase 5 — instala Tailscale (opción recomendada)
│   ├── harden-server.sh     # Fase 4 — firewall (ufw) + actualizaciones automáticas
│   └── install-client-windows.ps1  # Fase 6 — instala y preconfigura el cliente en Windows
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

## Acceso externo (Fase 5) — decidido: Tailscale

El ISP asigna CGNAT (sin IP pública real), así que se descartó DDNS + port
forwarding. Se eligió Tailscale sobre un VPS público porque el acceso es
solo para dispositivos propios.

```bash
./scripts/setup-tailscale.sh
```

Instalar Tailscale también en cada dispositivo cliente (misma cuenta), y
apuntar el cliente RustDesk (Configuración > Red) a la IP `100.x.x.x` de la
VM en vez de la IP LAN.

Alternativa no usada, documentada por si el caso de uso cambia a "acceso
público para terceros": migrar `docker-compose.yml` a un VPS con IP pública
(ej. Oracle Cloud Free Tier), abriendo los puertos 21115-21119 (TCP) y 21116
(UDP) en el firewall del proveedor y en `ufw`/`iptables` del VPS.

## Seguridad

**Servidor** — endurecer el firewall una vez que Tailscale esté andando:
```bash
./scripts/harden-server.sh
```
Esto configura `ufw` para que SSH y los puertos de RustDesk solo respondan
por la interfaz `tailscale0` (no por la LAN normal), y activa
`unattended-upgrades` para parches de seguridad automáticos. Si te quedás
sin acceso por red, la consola de la VM en VMware sigue funcionando (no
depende de la red).

**Cliente RustDesk** (repetir en cada dispositivo, Configuración > Seguridad):
- Contraseña permanente, distinta por dispositivo — no reutilizar la misma.
- Desactivar **"Enable Direct IP Access"** — fuerza a que toda conexión pase
  por hbbs/hbbr en vez de ir directo al cliente.
- Whitelist de IPs acotada al rango de Tailscale (`100.64.0.0/10`, o la IP
  exacta de cada dispositivo propio).
- Desactivar permisos que no se usen (transferencia de archivos, audio).

## Despliegue simplificado de clientes

Para no tipear ID Server/Relay Server/Key a mano en cada dispositivo nuevo:

- **Windows**: `scripts/install-client-windows.ps1` — baja el instalador
  oficial más reciente, lo instala en silencio y deja la configuración del
  servidor ya cargada. Correr como Administrador:
  ```powershell
  powershell -ExecutionPolicy Bypass -File install-client-windows.ps1
  ```
  Hay reportes (no confirmados por el proyecto RustDesk) de que en algunas
  versiones el archivo de config no toma efecto si la app ya se abrió antes.
  Si eso pasa, usá **Export Config** desde un cliente que ya funcione
  (Configuración > General) y pegá ese string en **Import Config** del
  dispositivo nuevo — un solo paso en vez de tres campos.
- **Otras plataformas** (Mac, Linux, Android, iOS): usar el mismo mecanismo
  de Export/Import Config, no hay script de instalación automatizada para
  esas plataformas en este repo todavía.

## Puertos que necesita el servidor

| Puerto | Protocolo | Uso |
|---|---|---|
| 21115 | TCP | Prueba de tipo de NAT |
| 21116 | TCP + UDP | Registro de ID / heartbeat |
| 21117 | TCP | Relay (hbbr) |
| 21118 | TCP | Cliente web (opcional) |
| 21119 | TCP | Relay web (opcional) |
