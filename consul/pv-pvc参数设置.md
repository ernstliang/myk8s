# pv/pvc参数设置

consul_pvc.yaml中 persistentVolumeReclaimPolicy 设置的policy是`Recycle` <br>
但从[官网文档](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)看`Recycle`策略是要被废弃的

> Warning: The Recycle reclaim policy is deprecated. Instead, the recommended approach is to use dynamic provisioning.

Consul集群的volume数据是要保存的，看另外两种Reclaim策略:

## Retain
The Retain reclaim policy allows for manual reclamation of the resource. When the `PersistentVolumeClaim` is deleted, the `PersistentVolume` still exists and the volume is considered “released”. But it is not yet available for another claim because the previous claimant’s data remains on the volume. An administrator can manually reclaim the volume with the following steps.

1. Delete the `PersistentVolume`. The associated storage asset in external infrastructure (such as an AWS EBS, GCE PD, Azure Disk, or Cinder volume) still exists after the PV is deleted.
2. Manually clean up the data on the associated storage asset accordingly.
3. Manually delete the associated storage asset, or if you want to reuse the same storage asset, create a new `PersistentVolume` with the storage asset definition.

## Delete
For volume plugins that support the `Delete` reclaim policy, deletion removes both the `PersistentVolume` object from Kubernetes, as well as the associated storage asset in the external infrastructure, such as an AWS EBS, GCE PD, Azure Disk, or Cinder volume. Volumes that were dynamically provisioned inherit the reclaim policy of their `StorageClass`, which defaults to Delete. The administrator should configure the StorageClass according to users’ expectations, otherwise the PV must be edited or patched after it is created. See [Change the Reclaim Policy of a PersistentVolume](https://kubernetes.io/docs/tasks/administer-cluster/change-pv-reclaim-policy/).

## Why change reclaim policy of a PersistentVolume
`PersistentVolumes` can have various reclaim policies, including “Retain”, “Recycle”, and “Delete”. For dynamically provisioned `PersistentVolumes`, the default reclaim policy is “Delete”. This means that a dynamically provisioned volume is automatically deleted when a user deletes the corresponding `PersistentVolumeClaim`. This automatic behavior might be inappropriate if the volume contains precious data. In that case, it is more appropriate to use the “Retain” policy. With the “Retain” policy, if a user deletes a `PersistentVolumeClaim`, the corresponding PersistentVolume is not be deleted. Instead, it is moved to the `Released` phase, where all of its data can be manually recovered.


