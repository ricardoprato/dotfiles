# Optimizaciones del sistema

Referencia paso a paso para replicar las optimizaciones en una instalación limpia.
Probado en Arch Linux con 14 GB RAM, NVMe, Hyprland.

---

## 1. Zen Browser (about:config)

Abrir `about:config` y ajustar:

| Parámetro | Valor | Efecto |
|---|---|---|
| `browser.tabs.unloadOnLowMemory` | `true` | Descarga tabs inactivos cuando la RAM baja |
| `browser.sessionhistory.max_entries` | `10` | Reduce historial por tab (default: 50) |
| `dom.ipc.processCount` | `4` | Limita procesos de contenido (default: 8) |
| `browser.cache.memory.capacity` | `51200` | Limita cache en memoria a ~50 MB |

---

## 2. earlyoom

Instalar y habilitar:

```bash
sudo pacman -S earlyoom
sudo systemctl enable --now earlyoom
```

Editar `/etc/default/earlyoom`:

```
EARLYOOM_ARGS="-m 5 -s 5 -r 60 -n --avoid '(^|/)(init|systemd|Xorg|sshd|Hyprland|waybar|odoo-bin)$' --prefer '(^|/)(zen-bin|Isolated Web Co|discord|Discord|electron)$'"
```

Qué hace cada flag:
- `-m 5` — Actuar cuando quede menos de 5% de RAM libre
- `-s 5` — Actuar cuando quede menos de 5% de swap libre
- `-r 60` — Reportar estado de memoria cada 60s al journal
- `-n` — Enviar notificación via D-Bus al matar un proceso
- `--avoid` — Proteger sesión gráfica (Hyprland, waybar) y Odoo
- `--prefer` — Si hay que matar algo, priorizar browser tabs y Discord (fáciles de recuperar)

---

## 3. Swappiness

```bash
sudo sysctl vm.swappiness=10
echo "vm.swappiness=10" | sudo tee /etc/sysctl.d/99-swappiness.conf
```

**Por qué 10:** El sistema usa zram (swap comprimido en RAM). Con swappiness=60 (default) el kernel mueve páginas a zram demasiado agresivamente, gastando CPU en compresión/descompresión. Con 10 prefiere mantener páginas en RAM sin comprimir.

Verificar:

```bash
cat /proc/sys/vm/swappiness  # debe mostrar 10
```

---

## 4. Swap file (8 GB en NVMe)

Complementa el zram (4 GB, prioridad 100) con un swap en disco de menor prioridad.

```bash
sudo dd if=/dev/zero of=/swapfile bs=1M count=8192 status=progress
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon -p 10 /swapfile
echo '/swapfile none swap sw,pri=10 0 0' | sudo tee -a /etc/fstab
```

Resultado esperado de `swapon --show`:

```
NAME       TYPE      SIZE PRIO
/dev/zram0 partition   4G  100   ← zram primero (rápido, en RAM)
/swapfile  file        8G   10   ← NVMe como fallback
```

---

## 5. Limpieza de disco

Comandos seguros para liberar espacio en cachés:

```bash
# Yay build cache (el más grande, seguro de borrar)
rm -rf ~/.cache/yay/*

# Pacman — mantener solo la última versión de cada paquete
sudo paccache -rk1

# Spotify cache
rm -rf ~/.cache/spotify/*

# npm cache
npm cache clean --force

# pip cache
pip cache purge

# Journal logs — limitar a 500 MB
sudo journalctl --vacuum-size=500M

# HuggingFace cache
rm -rf ~/.cache/huggingface/*

# Playwright cache
rm -rf ~/.cache/ms-playwright/*
```

---

## 6. Docker

Deshabilitar cuando no se use para ahorrar recursos en background:

```bash
# Parar y deshabilitar
sudo systemctl stop docker containerd
sudo systemctl disable docker containerd

# Volver a habilitar cuando se necesite
sudo systemctl start docker
```
