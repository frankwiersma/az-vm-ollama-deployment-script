# 🛠️ Azure VM Ollama Deployment Guide

## 🎯 Overview

This deployment creates a fully automated Ollama AI server on Azure with GPU support, pre-configured with the Dolphin-Mistral 24B model. The VM will be ready to serve AI requests immediately after deployment completes.

## 📋 Prerequisites

Before deploying, ensure you have:

- **Azure CLI** installed and authenticated (`az login`)
- **Resource Group** created in your target region
- **Virtual Network and Subnet** configured
- **GPU VM Quota** available in your subscription (Standard_NV series)
- **Network Security Group** rules for port 11434 (if external access needed)

## 🖥️ VM Configuration

| Setting             | Value                          |
| ------------------- | ------------------------------ |
| **VM Size**         | `Standard_NV18ads_A10_v5`      |
| **GPU**             | NVIDIA A10 (24GB VRAM)        |
| **OS Image**        | Ubuntu 22.04 LTS (Gen2)       |
| **OS Disk**         | Premium SSD, 128 GiB           |
| **Instance Type**   | Spot Instance (cost optimized)|
| **Auto-Shutdown**   | 18:00 W. Europe Time          |

## 🧠 AI Model Details

| Component           | Specification                  |
| ------------------- | ------------------------------ |
| **Model**           | Dolphin-Mistral 24B           |
| **Quantization**    | Q4_K_S (~13GB VRAM)           |
| **Model Alias**     | `dolphin-mistral`              |
| **API Endpoint**    | `http://VM_IP:11434`           |
| **Persistence**     | Auto-loads on boot             |

## 🚀 Quick Deployment

### 1. Clone Repository
```bash
git clone https://github.com/frankwiersma/az-vm-ollama-deployment-script.git
cd az-vm-ollama-deployment-script
```

### 2. Update Parameters
Edit `parameters.json` with your specific values:
```json
{
  "virtualMachineName": {"value": "your-ollama-vm"},
  "virtualNetworkId": {"value": "/subscriptions/.../your-vnet"},
  "subnetName": {"value": "your-subnet"}
}
```
**Note:** Admin password is provided via deployment command for security, not stored in parameters file.

### 3. Create Resource Group (if needed)
```bash
# Create a new resource group (skip if using existing)
az group create \
  --name your-resource-group \
  --location westeurope
```

### 4. Deploy
```bash
# Deploy with password provided securely via command line
az deployment group create \
  --resource-group your-resource-group \
  --template-file template.json \
  --parameters @parameters.json \
  --parameters adminPassword="your-secure-password-here"
```

**Security Note:** The admin password is provided via command line parameter rather than stored in the parameters file to prevent accidental exposure in version control.

## ⏱️ Deployment Timeline

| Phase                    | Duration | Status Check                           |
| ------------------------ | -------- | -------------------------------------- |
| VM Creation              | ~3 min   | Azure Portal - VM Running              |
| GPU Driver Installation  | ~5 min   | SSH: `nvidia-smi`                     |
| Ollama Setup             | ~8 min   | SSH: `ollama ps`                       |
| Model Download           | ~10 min  | SSH: `ollama list`                     |
| **Total Deployment**     | ~15 min  | API: `curl VM_IP:11434/api/tags`       |

## 🔧 Post-Deployment Verification

### 1. SSH Access
```bash
ssh azureuser@YOUR_VM_PUBLIC_IP
```

### 2. Check GPU Status
```bash
nvidia-smi
# Should show A10 GPU with ~13GB used by Ollama
```

### 3. Verify Ollama Service
```bash
ollama ps
# Should show: dolphin-mistral running

systemctl status ollama-keep-alive
# Should show: active (running)
```

### 4. Test API Locally
```bash
curl -X POST http://localhost:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{"model": "dolphin-mistral", "prompt": "Hello! Can you help me with coding?", "stream": false}'
```

### 5. Test External API Access
```bash
# From your local machine
curl -X POST http://YOUR_VM_PUBLIC_IP:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{"model": "dolphin-mistral", "prompt": "What is Azure?", "stream": false}'
```

## 🛠️ Service Management

### Start/Stop/Restart Services
```bash
# Ollama main service
sudo systemctl start/stop/restart ollama

# Keep-alive service (maintains model in memory)
sudo systemctl start/stop/restart ollama-keep-alive

# Check logs
journalctl -u ollama-keep-alive -f
```

### Load Different Models
```bash
# Pull additional models
ollama pull llama2:7b
ollama pull codellama:7b

# Switch active model
ollama run llama2:7b
```

## 🔒 Security Configuration

### Network Security Group Rules
Configure NSG to allow:
- **SSH (22)**: Your IP range only
- **Ollama API (11434)**: Restricted IP ranges for API access
- **HTTPS (443)**: For model downloads

### Firewall Configuration
```bash
# Allow Ollama API through firewall
sudo ufw allow 11434/tcp
sudo ufw enable
```

## 💰 Cost Optimization

### Spot Instance Pricing
- Template configured for Spot instances (up to 90% savings)
- Eviction policy: Deallocate (preserves disk)
- Monitor via Azure Portal for eviction warnings

### Auto-Shutdown Schedule
- Default: 18:00 W. Europe Time
- Modify in ARM template `autoShutdownTime` parameter
- Disable: Set `autoShutdownStatus` to `Disabled`

### Resource Cleanup
```bash
# Delete entire resource group when done
az group delete --name your-resource-group --yes --no-wait
```

## 🐛 Troubleshooting

### Common Issues

**Model not responding:**
```bash
# Check if model is loaded
ollama ps

# Restart keep-alive service
sudo systemctl restart ollama-keep-alive

# Check GPU memory
nvidia-smi
```

**API not accessible externally:**
```bash
# Verify port binding
ss -ltnp | grep 11434

# Check NSG rules in Azure Portal
# Ensure port 11434 is allowed from your IP
```

**Out of GPU memory:**
```bash
# Check GPU usage
nvidia-smi

# Try smaller quantization
ollama pull dolphin-mistral:q4_0  # Smaller version
```

**Deployment failures:**
- Check Azure Activity Log for detailed error messages
- Verify VM size availability in your region
- Ensure sufficient quota for GPU VMs

## 📚 API Usage Examples

### Python Client
```python
import requests

url = "http://YOUR_VM_IP:11434/api/generate"
data = {
    "model": "dolphin-mistral",
    "prompt": "Write a Python function to calculate fibonacci numbers",
    "stream": False
}

response = requests.post(url, json=data)
print(response.json()["response"])
```

### cURL Streaming
```bash
curl -X POST http://YOUR_VM_IP:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{"model": "dolphin-mistral", "prompt": "Explain machine learning", "stream": true}'
```

## 📞 Support

- **Documentation**: [Ollama Official Docs](https://ollama.ai/docs)
- **Model Details**: [Dolphin-Mistral on Hugging Face](https://huggingface.co/mradermacher/Dolphin-Mistral-24B-Venice-Edition-i1-GGUF)
- **Azure GPU VMs**: [Azure N-series Documentation](https://docs.microsoft.com/en-us/azure/virtual-machines/sizes-gpu)

