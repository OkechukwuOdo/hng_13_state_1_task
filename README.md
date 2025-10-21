# 🚀 Automated Docker Deployment Script

This project provides a fully automated Bash script (deploy.sh) to deploy a Dockerized application from a Git repository to a remote Linux server (e.g., a DigitalOcean droplet).
It handles everything from pulling the latest code, setting up Docker & Nginx, to running your app and validating deployment.

---

## 🧰 Features

✅ Secure SSH-based connection to the remote server
✅ Automatic installation of Docker, Docker Compose, and Nginx**
✅ Git repository cloning with Personal Access Token (PAT) authentication**
✅ Automatic detection of Dockerfile or docker-compose.yml**
✅ Rsync-based project file transfer**
✅ Nginx reverse proxy configuration**
✅ Automated deployment validation**
✅ Optional cleanup mode**

---

## 🧩 Prerequisites

Before using the script, make sure you have:

1. A remote Linux server (e.g., Ubuntu on DigitalOcean) 
2. **SSH access** to the server (via private key, not password)  
3. **Dockerized application** (must contain `Dockerfile` or `docker-compose.yml`)  
4. **Git repository** URL for your application  
5. **Personal Access Token (PAT)** if the repo is private  
6. **Your SSH private key path** (e.g., `~/.ssh/id_rsa`)

---

## 🔑 Generating an SSH Key (if you don’t have one)

## ⚙️ Usage
Clone the repository
Make the script executable
Run the deployment
