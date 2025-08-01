# Azure VM Ollama Deployment Script

This repository contains automated deployment scripts for setting up an Ollama VM with GPU support on Azure, specifically configured for the Dolphin-Mistral 24B model.

## Overview

The deployment creates an Azure VM with:
- **NVIDIA GPU support** (A10 GPU recommended)
- **Ollama AI server** configured for network access
- **Dolphin-Mistral 24B Q4_K_S model** pre-loaded and ready to use
- **Persistent service** to keep the model running after reboots
- **Auto-restart** functionality for high availability

## Prerequisites

- Azure CLI installed and configured
- Resource Group created in Azure
- Virtual Network and Subnet configured
- Sufficient Azure quotas for GPU VMs

## Quick Deploy

### Option 1: Using the Web Configuration Generator (Recommended)

1. **Clone this repository:**
   ```bash
   git clone https://github.com/frankwiersma/az-vm-ollama-deployment-script.git
   cd az-vm-ollama-deployment-script
   ```

2. **Generate configuration files:**
   - Open `config-generator.html` in your web browser
   - Fill in your Azure environment details (subscription, network, etc.)
   - Click "Generate Configuration Files" to create your `parameters.json`
   - Download the generated `parameters.json` file

3. **Copy template file:**
   ```bash
   cp template.example.json template.json
   ```

4. **Create resource group (if needed):**
   ```bash
   az group create \
     --name your-resource-group \
     --location westeurope
   ```

5. **Deploy using Azure CLI:**
   ```bash
   az deployment group create \
     --resource-group your-resource-group \
     --template-file template.json \
     --parameters @parameters.json \
     --parameters adminPassword="your-secure-password"
   ```

### Option 2: Manual Configuration

1. **Clone this repository:**
   ```bash
   git clone https://github.com/frankwiersma/az-vm-ollama-deployment-script.git
   cd az-vm-ollama-deployment-script
   ```

2. **Copy and customize example files:**
   ```bash
   cp template.example.json template.json
   cp parameters.example.json parameters.json
   ```

3. **Edit parameters.json:**
   Update the following required values in `parameters.json`:
   - `virtualNetworkId`: Your Azure VNet resource ID
   - `subnetName`: Your subnet name
   - `virtualMachineRG`: Your resource group name  
   - `tags`: Update with your organization's tags
   
   **Note:** Do NOT include `adminPassword` in the parameters file for security.

4. **Create resource group (if needed):**
   ```bash
   az group create \
     --name your-resource-group \
     --location westeurope
   ```

5. **Deploy using Azure CLI:**
   ```bash
   az deployment group create \
     --resource-group your-resource-group \
     --template-file template.json \
     --parameters @parameters.json \
     --parameters adminPassword="your-secure-password"
   ```
   
   **Security Best Practice:** Always provide the admin password via command line parameter rather than storing it in files.

## Files Description

### Core Deployment Files
- **`template.example.json`** - Example ARM template (copy to `template.json`)
- **`parameters.example.json`** - Example parameters file (copy to `parameters.json`)
- **`post-deploy-setup.sh`** - Automated Ollama installation and configuration script

### Configuration Tools
- **`config-generator.html`** - Web-based configuration generator (recommended)
- **`deploy.md`** - Detailed deployment guide and troubleshooting
- **`README.md`** - This documentation file

### Usage Files (Generated)
- **`template.json`** - Your customized ARM template (git-ignored)
- **`parameters.json`** - Your environment-specific parameters (git-ignored)

## What Gets Deployed

### Infrastructure
- Azure VM with GPU support (Standard_NC6s_v3 or similar)
- Public IP address with network access
- NVIDIA GPU driver extension
- Auto-shutdown schedule (configurable)

### Software Stack
- **Ollama AI Server** - Latest version installed and configured
- **Dolphin-Mistral 24B Q4_K_S** - High-quality 24B parameter model
- **Network Configuration** - Accessible on port 11434 (0.0.0.0:11434)
- **Systemd Services** - Auto-start and keep-alive functionality

## Post-Deployment

After deployment completes (typically 10-15 minutes), you can:

### Check Status
```bash
# SSH into your VM, then run:
ollama ps                    # See running models
ss -ltnp | grep 11434       # Verify network port
nvidia-smi                   # Check GPU usage
journalctl -u ollama-keep-alive -f  # Monitor service logs
```

### Test the Model
```bash
# Local testing on the VM
curl -X POST http://localhost:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{"model": "dolphin-mistral", "prompt": "Hello, how are you?"}'

# Remote testing (replace with your VM's public IP)
curl -X POST http://YOUR_VM_IP:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{"model": "dolphin-mistral", "prompt": "Hello, how are you?"}'
```

## Configuration Details

### GPU Requirements
- **Minimum**: 12GB VRAM (A10, RTX 3060, etc.)
- **Recommended**: 24GB+ VRAM for better performance
- **Model Size**: ~13GB for Q4_K_S quantization

### Network Access
- **Port**: 11434 (HTTP API)
- **Binding**: 0.0.0.0 (accessible from external networks)
- **Security**: Configure NSG rules as needed for your security requirements

### Service Management
The deployment creates a systemd service that:
- Automatically starts Ollama on boot
- Keeps the model loaded in memory
- Restarts on failure (10-second delay)
- Runs under the VM user account

## Customization

### Different Models
To use a different model, edit `post-deploy-setup.sh`:
```bash
# Replace this line:
ollama pull hf.co/mradermacher/Dolphin-Mistral-24B-Venice-Edition-i1-GGUF:Q4_K_S

# With your preferred model:
ollama pull your-model-name
```

### VM Size
Update `parameters.json` to change VM size:
```json
{
  "virtualMachineSize": {
    "value": "Standard_NC12s_v3"
  }
}
```

## Troubleshooting

### Common Issues

**Model not loading:**
```bash
# Check Ollama service status
sudo systemctl status ollama
sudo systemctl status ollama-keep-alive

# Restart services if needed
sudo systemctl restart ollama
sudo systemctl restart ollama-keep-alive
```

**GPU not detected:**
```bash
# Verify GPU driver installation
nvidia-smi
lspci | grep -i nvidia

# Check Ollama GPU usage
ollama ps
```

**Network connectivity:**
```bash
# Verify port binding
ss -ltnp | grep 11434

# Test local connectivity
curl http://localhost:11434/api/tags
```

## Cost Optimization

- **Spot Instances**: Template configured for Spot pricing by default
- **Auto-Shutdown**: Configurable auto-shutdown schedule
- **Resource Cleanup**: Remember to delete resources when not needed

## Security Considerations

- **Network Security Groups**: Configure appropriate firewall rules
- **SSH Access**: Secure SSH with key-based authentication
- **API Access**: Consider authentication for production use
- **Resource Monitoring**: Monitor for unexpected usage or costs

## Support

For issues or questions:
- Check the troubleshooting section above
- Review Azure VM and Ollama documentation
- Open an issue in this repository

## License

This project is provided as-is for educational and development purposes.
