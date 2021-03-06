# Kubernetes v1.13+ Installation/Configurations

This directory contains example manifests for deploying the plugin to Kubernetes.

Documentation on how to write these manifests can be found [here](https://github.com/kubernetes/community/blob/master/contributors/design-proposals/storage/container-storage-interface.md#recommended-mechanism-for-deploying-csi-drivers-on-kubernetes)

To deploy all necessary components, customize these files and apply them:
Apply all from within this directory:
```bash
kubectl apply -f *.yaml
```

## Kubernetes  Cluster Prerequisites
Kubernetes documentation for CSI support can be found [here](https://kubernetes-csi.github.io/)

* Kubernetes version 1.13 or higher
* BlockVolume support requires kubelet has the [feature gates](https://kubernetes.io/docs/reference/command-line-tools-reference/feature-gates/) BlockVolume and CSIBlockVolume set to true.
    Example in /var/lib/kubelet/config.yaml
    ```yaml
    ...
    featureGates:
      BlockVolume: true
      CSIBlockVolume: true
      VolumeSnapshotDataSource: true
    ...
    ```
* VolumeSnapshot support requires the VolumeSnapshotDataSource feature flag
* Each host should have support for NFS v4.2 or v3 with the relevant network ports open between the host and storage

### NOTE on Google Kubernetes Engine
GKE does not allow the creation of ClusterRoles
that are more powerful than the given user. An insecure work around to this is
to give the user creating the role cluster-admin privileges.

```bash
kubectl create clusterrolebinding i-am-root --clusterrole=cluster-admin --user=<current user>
```

## Example Usage

### Create a Filesystem Volume
Example PVC

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: myfilesystem
  namespace: default
spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 100Gi
  storageClassName: hs-storage
```

### Create an Application Using the Filesystem Volume
Example Pod
```yaml
kind: Pod
apiVersion: v1
metadata:
  name: my-app
spec:
  containers:
    - name: my-app
      image: alpine
      volumeMounts:
      - mountPath: "/data"
        name: data-dir
      command: [ "ls", "-al", "/data" ]
  volumes:
    - name: data-dir
      persistentVolumeClaim:
        claimName: myfilesystem
```

### Create a Raw Volume
Example PVC

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mydevice
  namespace: default
spec:
  volumeMode: Block
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 100Gi
  storageClassName: hs-storage
```

### Create an Application Using the Raw Volume
Example Pod
```yaml
kind: Pod
apiVersion: v1
metadata:
  name: my-app
spec:
  containers:
    - name: my-app
      image: alpine
      volumeDevices:
      - devicePath: "/dev/xvda"
        name: data-dir
      command: [ "stat", "/dev/xvda" ]
  volumes:
    - name: data-dev
      persistentVolumeClaim:
        claimName: mydevice
```

### Create a Snapshot
```yaml
apiVersion: snapshot.storage.k8s.io/v1alpha1
kind: VolumeSnapshot
metadata:
  name: data-snapshot
spec:
  snapshotClassName: hs-snapshots
  source:
    name: mydevice
    kind: PersistentVolumeClaim
```