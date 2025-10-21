# 🚀 Automated Docker Deployment Script

This project provides a **robust Bash script** that automates the setup, deployment, and configuration of a **Dockerized application** on a **remote Linux server** (e.g., a DigitalOcean droplet).  

It handles everything — from cloning your Git repository, setting up Docker and Nginx, to validating that your application is live and accessible.

---

## 🧰 Features

✅ Automated setup of Docker, Docker Compose, Nginx  
✅ Secure SSH-based deployment  
✅ Automatic cloning of your Git repository (with branch + PAT support)  
✅ Reverse proxy configuration with Nginx  
✅ Built-in validation and error handling  
✅ Optional cleanup mode (`--cleanup`)  
✅ Detailed log output for debugging  

---

## 🧩 Prerequisites

Before using the script, make sure you have:

1. **A remote Linux server (e.g., Ubuntu on DigitalOcean)**  
2. **SSH access** to the server (via private key, not password)  
3. **Dockerized application** (must contain `Dockerfile` or `docker-compose.yml`)  
4. **Git repository** URL for your application  
5. **Personal Access Token (PAT)** if the repo is private  
6. **Your SSH private key path** (e.g., `~/.ssh/id_rsa`)

---

## 🔑 Generating an SSH Key (if you don’t have one)

Run the following on your local machine (Mac/Linux):

```bash
mkdir -p ~/.ssh/keyz
ssh-keygen -t ed25519 -f ~/.ssh/keyz/digitaloceankey -C "your_email@example.com"
