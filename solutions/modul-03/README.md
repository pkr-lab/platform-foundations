# Lösung Modul 03

Eine Beispiel-`values-lab.yaml` liegt in [values-lab.yaml](./values-lab.yaml).

```bash
helm search repo artifactory/podinfo --versions | head -n 5
helm install demo artifactory/podinfo --version <chart-version> -n demo --create-namespace --set replicaCount=2
cd ~/k8s-lab/azubi-portal-chart
helm upgrade --install azubi-portal . -n azubi-portal --create-namespace -f values-lab.yaml
helm upgrade azubi-portal . -n azubi-portal -f values-lab.yaml --set image.tag=gibtesnicht
helm history azubi-portal -n azubi-portal
helm rollback azubi-portal 2 -n azubi-portal
helm package . -d ~/k8s-lab/packages
```

## Antworten auf die Verständnisfragen

1. `values.yaml` enthält die Standardwerte des Charts. Umgebungsspezifische Abweichungen stehen in einer eigenen Datei. So bleibt das Chart unverändert und mehrere Umgebungen teilen sich dasselbe Chart.
2. `version` versioniert das Chart (Templates, Defaults), `appVersion` die enthaltene Anwendung.
3. `helm template` zeigt die fertig gerenderten Manifeste, ohne den Cluster zu verändern. Fehler in Templates oder Werten fallen sofort auf.
4. Pods lesen eine gemountete ConfigMap nicht automatisch neu ein, und eine geänderte ConfigMap allein löst keinen Rollout aus. Die Checksumme ändert sich mit dem Inhalt der ConfigMap; dadurch ändert sich das Pod-Template und Kubernetes rollt neue Pods aus.

## Woher kommt das Image?

Laut `values.yaml` von podinfo und `azubi-portal` kommen die Images von `ghcr.io` bzw. `docker.io`. containerd im kind-Node leitet diese Registries über die `hosts.toml`-Dateien aus Modul 01 auf die Remote-Repos im Artifactory um. Im Pod steht deshalb weiterhin die Original-Adresse, geladen wurde das Image aber aus dem Artifactory.

## Warum bleiben bei einem kaputten Image-Tag die alten Pods erreichbar?

Das Deployment nutzt standardmäßig die Strategie `RollingUpdate`. Alte Pods werden erst entfernt, wenn neue Pods bereit sind. Da die neuen Pods nie bereit werden, laufen die alten weiter.
