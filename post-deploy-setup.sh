#!/bin/bash

# --- 1. Install Ollama ---
echo "Installing Ollama..."
curl -fsSL https://ollama.ai/install.sh | sh

# --- 2. Configure Ollama for Network Access (0.0.0.0) ---
echo "Configuring Ollama for network access..."
sudo mkdir -p /etc/systemd/system/ollama.service.d
sudo tee /etc/systemd/system/ollama.service.d/override.conf > /dev/null <<'EOF'
[Service]
Environment="OLLAMA_HOST=0.0.0.0:11434"
EOF

# --- 3. Reload Systemd and Restart Ollama Service ---
echo "Applying network configuration..."
sudo systemctl daemon-reload
sudo systemctl restart ollama

# --- 4. Pull the Correct Model (Q4_K_S) and Create an Alias ---
# Your A10 GPU with 12GB VRAM is a good fit for this Q4 quant (~13GB).
echo "Pulling the Dolphin-Mistral Q4_K_S model..."
ollama pull hf.co/mradermacher/Dolphin-Mistral-24B-Venice-Edition-i1-GGUF:Q4_K_S

echo "Creating a simple alias 'dolphin-mistral' for the model..."
ollama cp hf.co/mradermacher/Dolphin-Mistral-24B-Venice-Edition-i1-GGUF:Q4_K_S dolphin-mistral

# --- 5. Create and Enable a Persistent Service to Keep the Model Running ---
# This service ensures the 'dolphin-mistral' model is always loaded, even after a reboot.
echo "Creating a systemd service to keep the model running..."
USERNAME=$(whoami)
sudo tee /etc/systemd/system/ollama-keep-alive.service > /dev/null <<EOF
[Unit]
Description=Ollama Keep Model Alive Service
Requires=ollama.service
After=ollama.service

[Service]
User=$USERNAME
Group=$(id -gn \$USERNAME)
Restart=always
RestartSec=10
ExecStart=/usr/local/bin/ollama run dolphin-mistral

[Install]
WantedBy=multi-user.target
EOF

# --- 6. Enable and Start the Keep-Alive Service ---
echo "Enabling and starting the keep-alive service..."
sudo systemctl daemon-reload
sudo systemctl enable --now ollama-keep-alive.service

echo "Setup complete!"
echo "--------------------------------------------------"
echo "To check the status, you can use the following commands:"
echo "  - To see the running model: ollama ps"
echo "  - To check network port:  ss -ltnp | grep 11434"
echo "  - To monitor GPU usage:   nvidia-smi"
echo "  - To check service logs:  journalctl -u ollama-keep-alive -f"
echo "--------------------------------------------------"
