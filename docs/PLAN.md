# Proyecto: Servidor RustDesk propio — Plan y hoja de ruta

## Objetivo
Montar un servidor RustDesk autoalojado, probarlo primero en local con máquinas virtuales, y luego resolver el acceso desde fuera de la red local (sin IP pública disponible).

---

## 1. Problema clave: no hay IP pública

Sin IP pública no se puede abrir puertos en el router de forma tradicional. Opciones analizadas:

| Opción | Funciona para clientes externos "normales" | UDP soportado | Costo | Complejidad |
|---|---|---|---|---|
| **Tailscale** (recomendada) | Sí, pero solo entre tus propios dispositivos (todos deben tener Tailscale instalado) | Sí (VPN completa) | Gratis (hasta 100 dispositivos) | Baja |
| ZeroTier | Igual que Tailscale, alternativa equivalente | Sí | Gratis (nivel básico) | Baja |
| Cloudflare Tunnel | Solo si cada cliente también corre `cloudflared access tcp` | No (UDP no soportado en el free tier) | Gratis (requiere dominio propio) | Media-alta |
| VPS gratis como relay (Oracle Cloud Free Tier) | Sí, para cualquier cliente público, sin instalar nada extra | Sí | Gratis para siempre | Media |
| DDNS + port forwarding en router | Sí, para cualquier cliente | Sí | Gratis | Baja (pero depende de si el ISP da IP real, no CGNAT) |

**Conclusión de la decisión pendiente:** si el objetivo final es que solo tú (o un grupo cerrado de dispositivos tuyos) se conecten → **Tailscale**. Si el objetivo es ofrecer el servicio a terceros con el cliente RustDesk normal sin instalar nada más → la única opción realista sin IP pública es **levantar el servidor RustDesk directamente en el VPS gratuito (Oracle Cloud)** en vez de en casa, o verificar con el ISP si es posible conseguir IP pública/salir de CGNAT.

Esto hay que confirmarlo al inicio del nuevo chat antes de avanzar en la fase de despliegue externo.

---

## 2. Hoja de ruta (fases a ejecutar en el chat de código)

### Fase 1 — Instalar VMware Workstation Pro
- Descargar desde el sitio de Broadcom/VMware (licencia personal gratuita, cuenta Broadcom).
- Verificar VT-x/AMD-V activo en BIOS/UEFI.
- Instalar y reiniciar.

### Fase 2 — Crear la VM con el SO de mejor rendimiento para este proyecto
- Para el **servidor RustDesk**: recomendado **Ubuntu Server** (sin entorno gráfico) — menor consumo de recursos, mejor soporte nativo de Docker, más liviano que un invitado Windows para esta tarea.
- Para **VMs cliente de prueba**: puede usarse Windows (si se quiere probar la experiencia real de usuario) o Ubuntu Desktop/liviano (menor overhead si solo se mide latencia).
- Configuración de red: adaptador **Bridged**, tipo **VMXNET3** (paravirtualizado).
- Instalar VMware Tools en cada VM.
- Si se van a correr varias VMs a la vez: activar "Fit all virtual machine memory into reserved host RAM" y asignar IP fija por VM.

### Fase 3 — Instalar y configurar RustDesk server
- Instalar Docker en la VM servidor.
- Levantar contenedores `hbbs` y `hbbr` con `--net=host --restart=unless-stopped`.
- Generar y respaldar el par de claves (`id_ed25519` / `id_ed25519.pub`).

### Fase 4 — Personalización y administración
- Configurar `always_use_relay`, límites de ancho de banda (`single_bandwidth`, `total_bandwidth`), nivel de log (`RUST_LOG`).
- Definir proceso de rotación de claves.
- Definir monitoreo básico (`docker logs`, `systemctl status`).

### Fase 5 — Resolver el acceso externo (según la decisión de la sección 1)
- Si es Tailscale: instalar en servidor y en cada cliente, configurar MagicDNS, apuntar los clientes RustDesk a la IP `100.x.x.x`.
- Si es VPS como servidor principal: migrar hbbs/hbbr al VPS de Oracle Cloud Free Tier, abrir Security List + firewall interno, reservar IP pública fija.
- Si es DDNS + port forwarding: verificar primero si el ISP asigna IP pública real (no CGNAT) antes de invertir tiempo aquí.

### Fase 6 — Despliegue y pruebas
- Instalar el cliente RustDesk en cada VM de prueba.
- Medir latencia y estabilidad con varias conexiones simultáneas.
- Documentar resultados y ajustar recursos (CPU/RAM) por VM según lo observado.

---

## 3. Comandos de referencia rápida

**Instalar Docker (Ubuntu Server):**
```bash
sudo apt update && sudo apt install -y docker.io
sudo systemctl enable --now docker
```

**Levantar RustDesk server:**
```bash
mkdir -p ~/rustdesk-server/data && cd ~/rustdesk-server

sudo docker run --name hbbs -d --net=host --restart=unless-stopped \
  -v $(pwd)/data:/root \
  rustdesk/rustdesk-server hbbs

sudo docker run --name hbbr -d --net=host --restart=unless-stopped \
  -v $(pwd)/data:/root \
  rustdesk/rustdesk-server hbbr
```

**Obtener la key pública:**
```bash
cat ~/rustdesk-server/data/id_ed25519.pub
```

**Instalar Tailscale:**
```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
tailscale ip -4
```

---

## 4. Pendiente a resolver al iniciar el nuevo chat
1. ~~Confirmar si el ISP asigna IP pública real o si hay CGNAT~~ — **Resuelto: hay CGNAT** (IP pública vista desde afuera no coincide con la IP WAN del router). Descarta DDNS + port forwarding.
2. Confirmar cuántas VMs cliente se van a usar para las pruebas de latencia simultánea. — Pendiente, prueba inicial hecha con 1 PC + 1 celular.
3. Confirmar sistema operativo definitivo para las VMs cliente (Windows vs Ubuntu). — Pendiente.
4. ~~Decidir entre Tailscale o VPS~~ — **Resuelto: Tailscale.** Descartado Radmin VPN como alternativa por no tener cliente Linux (el servidor corre en una VM Ubuntu Server).

## 5. Estado actual (implementado y probado)
- Servidor RustDesk (hbbs + hbbr) corriendo en Docker sobre una VM Ubuntu Server 26.04 en VMware Workstation Pro, IP LAN `192.168.1.18`.
- Tailscale instalado en la VM servidor, IP de tailnet `100.64.234.119`.
- `RUSTDESK_RELAY_HOST` en `.env` apuntando a la IP de Tailscale — el servidor anuncia esa IP a los clientes, no la LAN.
- Probado con cliente RustDesk en PC y en celular (Android/iOS), ambos con Tailscale instalado y logueados en la misma cuenta.
- **Confirmado acceso remoto real**: conexión exitosa desde el celular con WiFi apagado (solo datos móviles) — valida que el túnel de Tailscale resuelve la falta de IP pública/CGNAT, que era el bloqueo original del proyecto.
- Servidor endurecido con `ufw` (SSH y puertos RustDesk solo por `tailscale0`) y `unattended-upgrades` activo.

## 6. Prueba exploratoria: servidor en Windows con Radmin VPN

No reemplaza la decisión de la sección 4 (Tailscale sigue siendo la solución
principal en Ubuntu) — es una instancia paralela e independiente para
evaluar Radmin VPN, ya que no tiene cliente Linux y por eso no pudo usarse
con el servidor actual. Detalle de despliegue en el `README.md`, sección
"Servidor alternativo en Windows".
