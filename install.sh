#!/usr/bin/env bash
set -e

echo "=== Полная установка Suckless на Void Linux (без pywal) ==="

# -----------------------------
# 1️⃣ Устанавливаем базовые зависимости
# -----------------------------
echo "[+] Устанавливаю пакеты..."
sudo xbps-install -Sy \
git make gcc pkg-config libX11-devel libXft-devel libXrender-devel libXinerama-devel \
fontconfig-devel harfbuzz-devel acpi picom feh dmenu xorg xorg-xinit \
alsa-utils pulseaudio alsa-plugins pulseaudio-alsa networkmanager

# -----------------------------
# 2️⃣ Видеодрайверы для Intel GPU
# -----------------------------
echo "[+] Устанавливаю драйверы для Intel GMA"
sudo xbps-install -Sy xf86-video-intel mesa-dri mesa-vulkan-intel

# -----------------------------
# 3️⃣ Сервисы
# -----------------------------
echo "[+] Включаем NetworkManager..."
sudo ln -sf /etc/sv/NetworkManager /var/service/
echo "[+] Включаем pulseaudio..."
ln -sf /etc/sv/pulseaudio /var/service/ 2>/dev/null || echo "PulseAudio уже активен"

# -----------------------------
# 4️⃣ Устанавливаем ST
# -----------------------------
ST_DIR="$HOME/st"
ST_REPO="https://git.suckless.org/st"
ST_PATCHES=(
    "https://st.suckless.org/patches/xresources/st-xresources-20200604-9ba7ecf.diff"
    "https://st.suckless.org/patches/alpha/st-alpha-0.8.5.diff"
)

echo "[+] Устанавливаем ST..."
if [ ! -d "$ST_DIR" ]; then
    git clone "$ST_REPO" "$ST_DIR"
fi
cd "$ST_DIR"

for patch in "${ST_PATCHES[@]}"; do
    file=$(basename "$patch")
    [ ! -f "$file" ] && wget "$patch"
    patch -p1 < "$file" || echo "[!] Патч $file возможно уже применён"
done

cat > config.def.h << EOF
#include <X11/Xft/Xft.h>
static int borderpx = 2;
static const char *font = "Iosevka:size=14:antialias=true:autohint=true";
float alpha = 0.85;
#define MODKEY Mod1Mask
#define TERMMOD (ControlMask|ShiftMask)
static Shortcut shortcuts[] = {
    { TERMMOD, XK_C, clipcopy, {.i = 0} },
    { TERMMOD, XK_V, clippaste, {.i = 0} },
    { ControlMask|ShiftMask, XK_KP_Add, zoom, {.f = +1} },
    { ControlMask|ShiftMask, XK_KP_Subtract, zoom, {.f = -1} },
    { TERMMOD, XK_P, zoomreset, {.f = 0} },
};
EOF

sudo make clean install
echo "[+] ST установлен"

# -----------------------------
# 5️⃣ Устанавливаем DWM
# -----------------------------
DWM_DIR="$HOME/dwm"
DWM_REPO="https://git.suckless.org/dwm"
DWM_PATCHES=(
  "https://dwm.suckless.org/patches/pertag/dwm-pertag-6.4.diff"
  "https://dwm.suckless.org/patches/autostart/dwm-autostart-20210826-cb3f58a.diff"
  "https://dwm.suckless.org/patches/systray/dwm-systray-6.4.diff"
  "https://dwm.suckless.org/patches/alpha/dwm-alpha-20220218-0.8.diff"
  "https://dwm.suckless.org/patches/xresources/dwm-xresources-6.4.diff"
  "https://dwm.suckless.org/patches/fullscreen/dwm-fullscreen-6.4.diff"
)

echo "[+] Устанавливаем DWM..."
if [ ! -d "$DWM_DIR" ]; then
    git clone "$DWM_REPO" "$DWM_DIR"
fi
cd "$DWM_DIR"

for patch in "${DWM_PATCHES[@]}"; do
    file=$(basename "$patch")
    [ ! -f "$file" ] && wget "$patch"
    patch -p1 < "$file" || echo "[!] Патч $file возможно уже применён"
done

cat > config.h << 'EOF'
#include <X11/XF86keysym.h>
static const unsigned int borderpx  = 2;
static const unsigned int snap      = 8;
static const int showbar            = 1;
static const int topbar             = 1;
static const char *fonts[]          = { "Iosevka:size=14" };
static const char dmenufont[]       = "Iosevka:size=14";
static char normbgcolor[]           = "#222222";
static char normbordercolor[]       = "#444444";
static char normfgcolor[]           = "#bbbbbb";
static char selfgcolor[]            = "#eeeeee";
static char selbordercolor[]        = "#770000";
static char selbgcolor[]            = "#005577";
static const Layout layouts[] = {
    { "[]=", tile },
    { "><>", NULL },
    { "[M]", monocle },
};
#define MODKEY Mod4Mask
#define TAGKEYS(KEY,TAG) \
    { MODKEY, KEY, view, {.ui = 1 << TAG} }, \
    { MODKEY|ShiftMask, KEY, tag, {.ui = 1 << TAG} },
static const char *termcmd[]  = { "st", NULL };
static const char *dmenucmd[] = { "dmenu_run", NULL };
static Key keys[] = {
    { MODKEY, XK_Return, spawn, {.v = termcmd } },
    { MODKEY, XK_d,      spawn, {.v = dmenucmd } },
    { MODKEY, XK_b,      togglebar, {0} },
    { MODKEY, XK_j,      focusstack, {.i = +1 } },
    { MODKEY, XK_k,      focusstack, {.i = -1 } },
    { MODKEY, XK_h,      setmfact, {.f = -0.05} },
    { MODKEY, XK_l,      setmfact, {.f = +0.05} },
    { MODKEY, XK_space,  setlayout, {0} },
    { MODKEY, XK_f,      togglefullscr, {0} },
    { MODKEY|ShiftMask, XK_c, killclient, {0} },
    { MODKEY|ShiftMask, XK_q, quit, {0} },
    TAGKEYS(XK_1,0) TAGKEYS(XK_2,1) TAGKEYS(XK_3,2) TAGKEYS(XK_4,3)
    TAGKEYS(XK_5,4) TAGKEYS(XK_6,5) TAGKEYS(XK_7,6) TAGKEYS(XK_8,7) TAGKEYS(XK_9,8)
};
EOF

sudo make clean install
echo "[+] DWM установлен"

# -----------------------------
# 6️⃣ Устанавливаем dwmblocks
# -----------------------------
DWMBLOCKS_DIR="$HOME/dwmblocks"
if [ ! -d "$DWMBLOCKS_DIR" ]; then
    git clone https://github.com/torrinfail/dwmblocks.git "$DWMBLOCKS_DIR"
fi
cd "$DWMBLOCKS_DIR"

cat > config.h << 'EOF'
static const Block blocks[] = {
    {" ", "iwgetid -r", 10, 0},
    {" ", "pamixer --get-volume-human", 2, 0},
    {" ", "bash -c '$HOME/.local/bin/dwm_battery.sh'", 30, 0},
    {" ", "date '+%a %d %b %H:%M'", 10, 0},
};
static char delim[] = " | ";
static unsigned int delimLen = 5;
EOF

sudo make clean install
echo "[+] dwmblocks установлен"

# -----------------------------
# 7️⃣ Скрипт батареи
# -----------------------------
mkdir -p ~/.local/bin
cat > ~/.local/bin/dwm_battery.sh << 'EOF'
#!/usr/bin/env bash
read -r status capacity <<< $(acpi | awk -F', ' '/Battery 0:/ {print $1, $2}' | tr -d '%,' | awk '{print $3, $4}')
if [ "$status" = "Charging" ]; then icon=""; 
elif [ "$capacity" -ge 90 ]; then icon=""; 
elif [ "$capacity" -ge 60 ]; then icon=""; 
elif [ "$capacity" -ge 30 ]; then icon=""; 
elif [ "$capacity" -ge 10 ]; then icon=""; 
else icon=""; fi
echo "$icon ${capacity}%"
EOF
chmod +x ~/.local/bin/dwm_battery.sh

# -----------------------------
# 8️⃣ Автозапуск dwm
# -----------------------------
mkdir -p ~/.dwm
cat > ~/.dwm/autostart.sh << 'EOF'
#!/usr/bin/env bash
picom --experimental-backends --daemon &
dwmblocks &
st &
EOF
chmod +x ~/.dwm/autostart.sh

# -----------------------------
# 9️⃣ xinitrc
# -----------------------------
cat > ~/.xinitrc << 'EOF'
#!/bin/sh
exec dwm
EOF
chmod +x ~/.xinitrc

echo
echo "✅ Полная установка завершена!"
echo "💡 Запуск: startx"
echo "💡 ST, DWM, dwmblocks, picom, NetworkManager — всё готово"
