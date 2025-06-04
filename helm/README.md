# RBT Helm Charts

This directory contains Helm charts for deploying the RBT (Releasable Basemap Tiles) stack on Kubernetes/OpenShift.

## Architecture

The RBT stack consists of:
- **TileserverGL**: Serves vector and raster tiles from MBTiles
- **MapProxy**: Provides OGC-compliant WMS/WMTS endpoints with caching
- **Nginx**: Reverse proxy that routes requests to the appropriate service

## Prerequisites

- Kubernetes 1.19+ or OpenShift 4.x
- Helm 3.x
- Persistent volumes for data storage
- Access to Docker images

## Quick Start

### Deploy the full stack:

```bash
# Install from the umbrella chart
cd helm
helm dependency update
helm install rbt . -f values.yaml

# Or install with a specific namespace
helm install rbt . -f values.yaml --namespace rbt --create-namespace
```

### Deploy components individually:

```bash
# Deploy TileserverGL only
helm install tileservergl ./tileservergl -f tileservergl/values.yaml

# Deploy MapProxy with Nginx
helm install mapproxy ./mapproxy -f mapproxy/values.yaml
```

## Configuration

### Global Configuration

Edit `helm/values.yaml` to configure:
- Image repositories and tags
- Resource limits
- Replica counts
- Service names

### Data Requirements

Before deploying, ensure you have:
1. MBTiles data files mounted at the correct paths
2. Style files for TileserverGL
3. Font files for map rendering

### Accessing Services

After deployment:
- Nginx (main entry point): `http://<cluster-ip>:8081`
- TileserverGL UI: `http://<cluster-ip>:8081/tileservergl/`
- MapProxy WMTS: `http://<cluster-ip>:8081/mapproxy/wmts/1.0.0/WMTSCapabilities.xml`
- MapProxy WMS: `http://<cluster-ip>:8081/mapproxy/wms?SERVICE=WMS&REQUEST=GETCAPABILITIES`

## Customization

### Resource Limits

Adjust resource limits in `values.yaml`:

```yaml
tileservergl:
  resources:
    requests:
      memory: "4Gi"
      cpu: "2000m"
    limits:
      memory: "8Gi"
      cpu: "4000m"
```

### Scaling

Increase replicas for better performance:

```yaml
tileservergl:
  replicas: 3
mapproxy:
  replicas: 2
  nginx:
    replicas: 2
```

## Troubleshooting

### Check pod status:
```bash
kubectl get pods -l app=tileservergl
kubectl get pods -l app=mapproxy
kubectl get pods -l app=nginx-proxy
```

### View logs:
```bash
kubectl logs -l app=tileservergl
kubectl logs -l app=mapproxy
kubectl logs -l app=nginx-proxy
```

### Common Issues:

1. **Image pull errors**: Ensure you have access to the Docker registry
2. **PVC mounting fails**: Check persistent volume claims exist
3. **Service connection errors**: Verify service names match between components
4. **Memory issues**: Increase resource limits if pods are getting OOMKilled

## Differences from Docker Compose

The Helm charts provide:
- Kubernetes-native deployment
- Better scalability options
- Resource management
- Health checks and probes
- Rolling updates
- Service discovery

Key differences:
- Uses Kubernetes Services instead of Docker networks
- PersistentVolumeClaims instead of bind mounts
- ConfigMaps for configuration files
- Parameterized values for easy customization 