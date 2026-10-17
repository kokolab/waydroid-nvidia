
# Fedora & Hybrid GPU Overrides
if [ -f "/usr/share/vulkan/icd.d/nvidia_icd.x86_64.json" ]; then
    NVIDIA_ICD="/usr/share/vulkan/icd.d/nvidia_icd.x86_64.json"
elif [ -f "/usr/share/vulkan/icd.d/nvidia_icd.json" ]; then
    NVIDIA_ICD="/usr/share/vulkan/icd.d/nvidia_icd.json"
else
    echo "ERROR: NVIDIA Vulkan ICD manifest not found!"
    exit 1
fi

echo "==> Configuring wd-venus systemd user override..."
mkdir -p "$HOME/.config/systemd/user/wd-venus.service.d/"
cat << OVERRIDE > "$HOME/.config/systemd/user/wd-venus.service.d/override.conf"
[Service]
Environment="VK_DRIVER_FILES=$NVIDIA_ICD"
Environment="VK_ICD_FILENAMES=$NVIDIA_ICD"
Environment="MESA_VK_DEVICE_SELECT=10de:*!"
OVERRIDE

systemctl --user daemon-reload
loginctl enable-linger "$USER"
systemctl --user enable --now wd-venus.service

echo "==> Sanitizing /var/lib/waydroid/waydroid_base.prop..."
if [ -f "/var/lib/waydroid/waydroid_base.prop" ]; then
    sudo sed -i "/debug.renderengine.backend/d" /var/lib/waydroid/waydroid_base.prop
    sudo sed -i "/debug.hwui.renderer/d" /var/lib/waydroid/waydroid_base.prop
    sudo sed -i "/ro.surfaceflinger.has_/d" /var/lib/waydroid/waydroid_base.prop

    sudo sh -c "cat << PROP >> /var/lib/waydroid/waydroid_base.prop
debug.renderengine.backend=skiaglthreaded
debug.hwui.renderer=skiagl
ro.surfaceflinger.has_wide_color_display=false
ro.surfaceflinger.has_HDR_display=false
PROP"
fi

echo "==> Patching LXC config for Fedora (disabling AppArmor)..."
if [ -f "/var/lib/waydroid/lxc/waydroid/config" ]; then
    sudo sed -i "s/^lxc.apparmor.profile/#lxc.apparmor.profile/" /var/lib/waydroid/lxc/waydroid/config
fi

echo "==> Debloating Waydroid AOSP & Google bloatware..."
if waydroid status | grep -q "RUNNING"; then
    # AOSP Apps
    sudo waydroid shell -- pm disable-user --user 0 org.lineageos.jelly
    sudo waydroid shell -- pm disable-user --user 0 org.lineageos.aperture
    sudo waydroid shell -- pm disable-user --user 0 org.lineageos.eleven
    sudo waydroid shell -- pm disable-user --user 0 org.lineageos.etar
    sudo waydroid shell -- pm disable-user --user 0 org.lineageos.recorder
    sudo waydroid shell -- pm disable-user --user 0 org.lineageos.waydroidupdater
    sudo waydroid shell -- pm disable-user --user 0 com.android.gallery3d
    sudo waydroid shell -- pm disable-user --user 0 com.android.calculator2
    sudo waydroid shell -- pm disable-user --user 0 com.android.deskclock
    sudo waydroid shell -- pm disable-user --user 0 com.android.contacts
    sudo waydroid shell -- pm disable-user --user 0 com.android.bips
    sudo waydroid shell -- pm disable-user --user 0 com.android.printspooler
    sudo waydroid shell -- pm disable-user --user 0 com.android.egg

    # Google Bloat
    sudo waydroid shell -- pm disable-user --user 0 com.google.android.projection.gearhead
    sudo waydroid shell -- pm disable-user --user 0 com.google.android.feedback
    sudo waydroid shell -- pm disable-user --user 0 com.google.android.googlequicksearchbox
else
    echo "NOTICE: Waydroid session is not running. Start Waydroid and run debloat manually."
fi
