
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
