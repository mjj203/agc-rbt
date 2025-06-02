# Releasable Basemap Tiles (RBT)

## What is RBT?
RBT (Releasable Basemap Tiles) is a web application that provides map tiles for military and coalition partners. Think of it like Google Maps, but designed for military use with maps that can be safely shared internationally.

### Why RBT is Better Than Older Map Systems
RBT uses **Vector Tiles** instead of the older **Raster Tiles** (like CADRG - Compressed ARC Digitized Raster Graphics) that the military has traditionally used. Here's why this matters:

**Think of it like this:**
- **Raster tiles (old way)** are like digital photographs of maps - they're made of pixels and have a fixed size and quality
- **Vector tiles (RBT's way)** are like digital drawings made of mathematical shapes and text that can be resized perfectly

**Key Advantages of Vector Tiles:**

🎯 **Better Quality at Any Zoom Level**
- Raster: Text becomes blurry when you zoom in (like enlarging a photo)
- Vector: Text and lines stay crisp at any zoom level

📦 **Smaller File Sizes**
- Raster: Large image files that take up lots of storage and bandwidth
- Vector: Compact mathematical descriptions that are 60-80% smaller

🌐 **Works Better Offline**
- Raster: Need to download many large image files for different zoom levels
- Vector: Download once, works smoothly at all zoom levels

⚡ **Faster Loading**
- Raster: Must load new images when zooming or panning
- Vector: Smooth transitions because data is already there

🎨 **Customizable Appearance**
- Raster: Fixed colors and styles (what you see is what you get)
- Vector: Can change colors, hide/show layers, adjust for day/night use

🔄 **Better for Coalition Sharing**
- Smaller files mean faster transfer over military networks
- Single vector dataset works for multiple use cases (instead of separate raster sets)
- Partners can customize the display for their specific needs

This makes RBT particularly valuable for military operations where bandwidth is limited, storage space is precious, and maps need to work reliably in various conditions.

## What You'll Need
This application runs using Docker, which is like a virtual container that packages everything needed to run the software. Don't worry if you're new to these tools - we'll guide you through each step.

The [AGC](https://www.agc.army.mil/) Releasable Basemap Tiles (RBT) prototype is important because the capability can be easily shared with international coalition partners and doesn't need to go through the current approval process associated with traditional Limited Distribution (LIMDIS) data. The National System for Geospatial Intelligence (NSG) RBT prototype is based on modern technology and provides access to like-in-kind Standard Map Products such as Topographic Map (TM), Joint Operations Graphic (JOG), and Tactical Pilotage Chart (TPC) in Vector Tiles format. This format enables rapid transfer across a network or accessed offline from a tile cache. By implementing simple changes in how modern maps are produced and accessed, international coalition partners will be able to track plans and activities using the same basemaps as U.S. services without delays associated with release of classified information.

The RBT prototype is funded by [NGA](https://www.nga.mil/) and development, demonstration and enhancement will continue with the help of the Army Geospatial Enterprise [AGE](https://www.agc.army.mil/Army-Geospatial-Enterprise/About/) community, [LazarusAI](https://www.lazarusai.com), and [Axis Maps](https://www.axismaps.com/).

## How It Works (Simple Version)
RBT uses several components working together:
- **TileserverGL**: Serves the map tiles (the actual map images)
- **MapProxy**: Helps convert between different map formats  
- **Docker**: Packages everything together so it runs the same on any computer
- **Kubernetes/Docker Compose**: Tools that manage and run the application

# Architecture

The RBT prototype is deployed as a containerized application using a modified version of [TileserverGL](https://github.com/mjj203/tileserver-gl) that uses [MapLibre](https://maplibre.org/) instead of [MapboxGL](https://www.mapbox.com/mapbox-gljs), and enables **EPSG:3395** projections for both WMTS and TileJSON endpoints. Additionally, [MapProxy](https://mapproxy.org/) is deployed to enable **EPSG:4326** Raster Tiles via OGC WMTS Endpoints by caching the Raster Tiles created dynamically from the TileserverGL deployment.

The RBT stack is optimized for deployment into a Kubernetes environment in the cloud or on-premises using helm charts. Local deployments can use **Docker Compose** after setting up the local environment with the required tools and getting S3 credentials from our team to download our MBTiles data for TileserverGL using the **AWSCLI**.

# Installation

Before cloning this repo, you will need to ensure **Git**, **Git Large File Storage (LFS)**, **AWSCLI**, and **Docker** are installed and enabled on your system.

## Before You Start

### Computer Requirements
- Windows 10/11, macOS, or Linux
- At least 400GB of available disk space (the map data is very large)
- Internet connection for downloading components
- Minimum 8GB of RAM recommended

### Skills You'll Need
- Basic familiarity with using a terminal/command prompt
- Ability to copy and paste commands
- Don't worry if you're new to this - we'll guide you through each step!

### What If I Get Stuck?
- Each command should be run one at a time
- If you see an error, don't panic - scroll down to our Troubleshooting section
- Commands that start with `sudo` may ask for your password

## Installation Guide

### Phase 1: Get Permission and Credentials
Before starting, you need special access to download the map data:
1. Email [Tom Boggess](Thomas.J.Boggess@usace.army.mil) to request S3 credentials
2. Wait for approval and credentials (this may take a few days)
3. Once you receive credentials, configure AWS CLI by running:
   ```
   aws configure --profile rbt
   ```
   Enter the provided Access Key ID, Secret Access Key, and set the region to `us-east-1`

### Phase 2: Install Required Software
You need to install several tools. Don't worry - we'll explain what each one does:

#### What is AWS CLI?
AWS CLI is a tool that lets you download files from Amazon's cloud storage (where our map data is stored).

#### What is Git?
Git is a tool for downloading and managing code projects. Git LFS handles large files.

#### What is Docker?
Docker packages applications so they run consistently on any computer.

### Phase 3: Download the Map Data
After installing the software and cloning the repository, you'll need to download the map data from S3 using your credentials. The exact command will be provided by the RBT team when you receive your credentials.

## Windows Installation

### Step 1: Enable WSL (Windows Subsystem for Linux)
WSL lets you run Linux commands on Windows. This is needed because our application works best on Linux.

**For Windows 10/11 (Easy Method):**
1. Open PowerShell as Administrator (right-click Start menu → "Windows PowerShell (Admin)")
2. Run: `wsl --install`
3. Restart your computer when prompted

**For Older Windows (Manual Method):**
Follow the manual installation steps provided below in the "Windows Setup" section.

### Step 2: Choose Your Docker Setup
You have two options - pick the one that sounds easier to you:

**Option A: Docker Desktop (Beginner-Friendly)**
- Has a graphical interface
- Easier to manage
- See "Windows install with Docker Desktop" section below

**Option B: Docker Engine (Command-Line Only)**
- More lightweight
- Command-line only
- See "Windows install without Docker Desktop" section below

## Linux Setup

### Installing on Linux

These commands will install all required software and start RBT. You can copy and paste the entire block into your terminal.

**FEDORA/RHEL/CENTOS:**

```bash
# Download and install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    sudo ./aws/install

# Remove old Docker versions (if any exist)
sudo dnf remove docker docker-client \
    docker-client-latest docker-common \
    docker-latest docker-latest-logrotate \
    docker-logrotate docker-selinux \
    docker-engine-selinux docker-engine

# Install Docker repository management tools
sudo dnf -y install dnf-plugins-core

# Add Docker's official repository
sudo dnf config-manager \
    --add-repo \
    https://download.docker.com/linux/fedora/docker-ce.repo

# Install Docker, Git, and Git LFS
sudo dnf install docker-ce docker-ce-cli \
    containerd.io docker-buildx-plugin \
    docker-compose-plugin git-all git-lfs

# Enable Git LFS support
git lfs install

# Clone the RBT project and start it
git clone https://github.com/mjj203/agc-rbt.git && \
    cd agc-rbt && \
    docker compose up -d
```

**Ubuntu/Debian:**

```
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    sudo ./aws/install;
sudo apt-get remove docker docker-engine \
    docker.io containerd runc;
sudo apt-get update && \
    sudo apt-get install ca-certificates \
    curl gnupg lsb-release;
sudo update-ca-certificates; 
sudo mkdir -m 0755 -p /etc/apt/keyrings;
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg;
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo chmod a+r /etc/apt/keyrings/docker.gpg;
sudo apt-get update;
sudo apt-get install \
    docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin \
    git-all git-lfs;
git lfs install;
git clone https://github.com/mjj203/agc-rbt.git && \
    cd agc-rbt && \
    docker compose up -d;
```

## Windows Setup

For Windows, ensure [Windows Subsystem for Linux](https://learn.microsoft.com/en-us/windows/wsl/) is installed by following [WSL](https://learn.microsoft.com/en-us/windows/wsl/install) for the latest Windows 10/11 or [Manual WSL](https://learn.microsoft.com/en-us/windows/wsl/install-manual) for older versions. Once WSL is enabled, then follow the [Windows install directions](https://docs.docker.com/desktop/install/windows-install/) and download the [installer](https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe).

Manual install of WSL2 using PowerShell as an admin:

```
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
```

Now restart your machine before proceeding to the next steps.

[Download the WSL2 Linux Kernel update](https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi). Double-click to run - you will be prompted for elevated permissions, select 'yes' to approve this installation.

```
wsl --set-default-version 2
wsl --install -d Ubuntu-24.04
```

Once you have installed WSL, you will need to create a user account and password for your newly installed Linux distribution. See the [Best practices](https://learn.microsoft.com/en-us/windows/wsl/setup/environment#set-up-your-linux-username-and-password) for setting up a WSL development environment guide to learn more.

### Windows install without Docker Desktop

Now install **git**, **git-lfs**, **docker**, and **awscli** in your WSL Ubuntu distribution by opening the distro from the Windows Start Menu and running the below commands.

```
sudo apt-get remove docker docker-engine docker.io containerd runc;
sudo apt-get update;
sudo apt-get install ca-certificates curl gnupg lsb-release;
sudo update-ca-certificates; 
sudo mkdir -m 0755 -p /etc/apt/keyrings;
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg;
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null;
sudo chmod a+r /etc/apt/keyrings/docker.gpg;
sudo apt-get update;
sudo apt-get install \
    docker-ce docker-ce-cli containerd.io docker-buildx-plugin \
    docker-compose-plugin git-all git-lfs;
git lfs install;
git clone https://github.com/mjj203/agc-rbt.git && \
    cd agc-rbt && \
    docker compose up -d;
```

### Windows install with Docker Desktop

If you prefer to use the Docker Desktop GUI instead of Docker Engine, then install Docker Desktop by [downloading](https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe) the latest version and then follow the [Docker WSL](https://docs.docker.com/desktop/features/wsl/) and [Microsoft WSL](https://learn.microsoft.com/en-us/windows/wsl/install) instructions to enable Docker in WSL.

Next, start Docker Desktop from the Windows Start menu.

Select Settings and then General.

    Select the Use WSL 2 based engine and Expose daemon on tcp://localhost:2375 check boxes.
    
![settings general](images/settings_general.png)

Now select Settings -> Resources -> WSL Integration.

    Select the Enable integration with my default WSL distro check box, and turn on additional distros if desired.

![wsl integration](images/wsl_integration.png)

To confirm that Docker has been installed, open your WSL distribution (e.g. Ubuntu) and display the version and build number by entering:

```
docker --version
```

From the WSL distribution you can now clone the repo and run **docker compose**:

```
sudo apt-get install git-all git-lfs;
git lfs install;
git clone https://github.com/mjj203/agc-rbt.git && \
    cd agc-rbt && \
    docker compose up -d;
```

## Common Issues and Solutions

### "Command not found" Error
This usually means the software isn't installed or isn't in your system's PATH.
- **Solution**: Try reinstalling the software or restart your terminal

### "Permission denied" Error
This means you need administrator privileges.
- **Solution**: Add `sudo` before the command (on Linux/Mac)

### Docker Won't Start
- **Windows**: Make sure Docker Desktop is running
- **Linux**: Try `sudo systemctl start docker`
- **Mac**: Make sure Docker Desktop is running

### "Cannot connect to AWS" Error
- **Solution**: Make sure you've configured AWS CLI with `aws configure --profile rbt`

## After Installation

### How to Know It's Working
1. Open your web browser
2. Go to `http://localhost:8080`
3. You should see The TileserverGL main page
4. Go to `http://localhost:80/wmts/1.0.0/WMTSCapabilities.xml`
5. You should see the MapProxy Generated WMTS

### How to Stop the Application
Run: `docker compose down --remove-orphans`

### How to Start It Again
Run: `docker compose up -d`

### Where to Get Help
- Check the Troubleshooting section above
- Contact the RBT program manager for support

## Glossary of Terms

- **CLI**: Command Line Interface - typing commands instead of clicking buttons
- **Docker**: Software that packages applications in containers
- **Container**: A packaged application with all its dependencies
- **Repository/Repo**: A project's code and files stored online
- **Terminal**: The application where you type commands
