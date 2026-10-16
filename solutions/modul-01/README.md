# Lösung Modul 01

## Demo-App

```bash
kubectl apply -f demo.yaml
kubectl port-forward svc/demo 9080:80
kubectl create namespace dev
kubectl create namespace test
kubectl apply -f demo.yaml -n dev
kubectl apply -f demo.yaml -n test
kubectl get deploy,svc -n dev
```

Die Datei [demo.yaml](./demo.yaml) enthält bewusst kein `metadata.namespace`, damit sie mit `-n` in beliebige Namespaces angewendet werden kann.

## Antworten auf die Verständnisfragen

1. Ein **Image** ist die unveränderliche Vorlage, ein **Container** eine laufende Instanz davon. Aus einem Image können beliebig viele Container entstehen.
2. Ein Deployment verwaltet über ein ReplicaSet die gewünschte Anzahl Pods. Fehlt ein Pod, erzeugt der Controller einen neuen. Ein einzeln erstellter Pod hat keinen Controller, der ihn ersetzt.
3. Über den `selector` erkennt das Deployment, welche Pods zu ihm gehören. Er muss zu den Labels im Pod-Template passen.
4. Port 8080 auf dem Host ist durch das Port-Mapping in `kind.yaml` bereits vom kind-Node belegt.

## Namespaces – mögliche Stichpunkte

- Trennung von Teams, Projekten oder Umgebungen
- eigene Rechte (RBAC) und Quotas pro Namespace
- gleiche Ressourcennamen in verschiedenen Namespaces möglich
