# Releasable Basemap Tiles (RBT)

The [AGC](https://www.agc.army.mil/) Releasable Basemap Tiles (RBT) prototype is important because the capability can be easily shared with international coalition partners and doesn’t need to go through the current approval process associated with traditional Limited Distribution (LIMDIS) data. The National System for Geospatial Intelligence (NSG) RBT prototype is based on modern technology and provides access to like in kind Standard Map Products such as Topographic Map (TM), Joint Operations Graphic (JOG), and Tactical Pilotage Chart (TPC) in Vector Tiles format. This format enables rapid transfer across a network or accessed offline from a tile cache.  By implementing simple changes in how modern maps are produced and accessed international coalition partners will be able to track plans and activities using the same basemaps as U.S. services without delays associated with release of classified information.

The RBT prototype is funded by [NGA](https://www.nga.mil/) and development, demonstration and enhancement will continue with the help of the Army Geospatial Enterprise [AGE](https://www.agc.army.mil/Army-Geospatial-Enterprise/About/) community, [GDIT](https://www.gdit.com), and [Axis Maps](https://www.axismaps.com/).

# Architecture

The RBT prototype is deployed as a containerized application using a modified version of [TileserverGL](https://github.com/mjj203/tileserver-gl), that uses [MapLibre](https://maplibre.org/) instead of [MapboxGL](https://www.mapbox.com/mapbox-gljs), and enables **EPSG:3395** projections for both WMTS and TileJSON endpoints. Additionally [MapProxy](https://mapproxy.org/) is deployed to enable **EPSG:4326** Raster Tiles via OGC WMTS Endpoints by caching the Raster Tiles created dynamically from the TileserverGL deployment.

The RBT stack is optimized for deployment into a Kubernetes environment in the cloud or onprem using helm charts. Local deployments can use **Docker Compose** after setting up the local environment with the required tools and getting an S3 credential from our team to download our MBTiles data for TileserverGL using the **AWSCLI**.

# Install

Before cloning this repo you will need to ensure **Git**, **Git Large File Storage (LFS)**, **AWSCLI**, and **Docker** are installed and enabled on your system.

1. Contact the RBT program manager [Tom Boggess](Thomas.J.Boggess@usace.army.mil) to request S3 Credentials to download our MBTiles data.
2. Install AWSCLI
- Download and install [AWSCLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) for your OS.
- Configure the **RBT** profile using `aws configure --profile rbt`
3. Install Git
- Download and install [Git](https://git-scm.com/downloads) and [LFS](https://github.com/git-lfs/git-lfs/releases/tag/v3.3.0) for your OS.
- Clone the project locally `git clone https://github.com/mjj203/agc-rbt.git`
4. Install Docker
- Download and install [Docker](https://docs.docker.com/get-docker/) for your OS.
- Deploy with **Docker Compose** inside the `agc-rbt` project with `docker compose up -d`
- Monitor deployment with `docker compose logs`

## Linux Setup

**FEDORA/RHEL/CENTOS:**

```
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    sudo ./aws/install;
sudo dnf remove docker docker-client \
    docker-client-latest docker-common \
    docker-latest docker-latest-logrotate \
    docker-logrotate docker-selinux \
    docker-engine-selinux docker-engine;
sudo dnf -y install dnf-plugins-core;
sudo dnf config-manager \
    --add-repo \
    https://download.docker.com/linux/fedora/docker-ce.repo;
sudo dnf install docker-ce docker-ce-cli \
    containerd.io docker-buildx-plugin \
    docker-compose-plugin git-all git-lfs;
git lfs install;
git clone https://github.com/mjj203/agc-rbt.git && \
    cd agc-rbt && \
    docker compose up -d;
```

**ubuntu/debian:**

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

For windows ensure [Windows Subsystem for Linux](https://learn.microsoft.com/en-us/windows/wsl/) is installed by following [WSL](https://learn.microsoft.com/en-us/windows/wsl/install) for the latest Windows 10/11 or [Manual WSL](https://learn.microsoft.com/en-us/windows/wsl/install-manual) for older versions. Once WSL is enabled, then follow the [Windows install directions](https://docs.docker.com/desktop/install/windows-install/) and download the [installer](https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe).

Manual install of WSL2 using PowerShell as an admin:

```
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
```

Now restart your machine before proceeding to the next steps.

[Download the WSL2 Linux Kernel update](https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi). Double-click to run - you will be prompted for elevated permissions, select ‘yes’ to approve this installation.

```
wsl --set-default-version 2
wsl --install -d Ubuntu-24.04
```

Once you have installed WSL, you will need to create a user account and password for your newly installed Linux distribution. See the [Best practices](https://learn.microsoft.com/en-us/windows/wsl/setup/environment#set-up-your-linux-username-and-password) for setting up a WSL development environment guide to learn more.

### Windows install without Docker Desktop

Now install **git**, **git-lfs**, **docker**, and **awscli** in your WSL ubuntu distribution by opening the distro from the Windows Start Menu and running the below commands.

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

If you prefer to use the Docker Desktop GUI instead of Docker Engine then innstall Docker Desktop by [Downloading](https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe) the latest version and then follow the [Docker WSL](https://docs.docker.com/desktop/features/wsl/) and [Microsoft WSL](https://learn.microsoft.com/en-us/windows/wsl/install) instructions to enable docker in WSL.

Next, start Docker Desktop from the Windows Start menu.

Select Settings and then General.

    Select the Use WSL 2 based engine and Expose daemon on tcp://localhost:2375 check boxes.
    
![settings general](images/settings_general.png)

Now select Settings -> Resources -> WSL Integration.

    Select the Enable integration with my default WSL distro check box, and turn additional distros if desired.

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
