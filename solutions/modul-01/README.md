# Lösung Modul 01

## Einrichtung prüfen

```bash
ps -p 1 -o comm=
podman info --format '{{.Host.Security.Rootless}}'
stat -fc %T /sys/fs/cgroup
cat /sys/fs/cgroup/user.slice/user-$(id -u).slice/user@$(id -u).service/cgroup.controllers
echo $KIND_EXPERIMENTAL_PROVIDER
ls /etc/containerd/certs.d
```

Erwartet: `systemd`, `true`, `cgroup2fs`, eine Liste mit mindestens `cpu memory pids`, `podman` und die vier Verzeichnisse `docker.io`, `ghcr.io`, `quay.io`, `registry.k8s.io`.

## Container mit Podman

```bash
podman login <artifactory-host>
podman run -d --rm --name web-test -p 8081:80 <artifactory-host>/<docker-remote-repo>/nginx:1.28.0
podman top web-test user huser
podman stop web-test
```

`podman top` zeigt in der Spalte `USER` den Benutzer im Container (`root`) und in `HUSER` den Benutzer auf dem Host – deinen eigenen. Root im Container ist bei rootless Podman auf dem Host nur dein normaler Benutzer.

## Cluster

```bash
kind create cluster --name lab --config kind.yaml \
  --image <artifactory-host>/<docker-remote-repo>/kindest/node:<version>
kubectl run mirror-test --image=docker.io/library/busybox:1.36.1 --restart=Never --command -- echo "Mirror funktioniert"
kubectl logs mirror-test
kubectl delete pod mirror-test
```

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
5. `1.28.0` zeigt immer auf dieselbe Version. `stable` und `latest` werden bei neuen Releases auf ein anderes Image umgehängt; dann läuft ohne Änderung im Manifest plötzlich eine andere Version, und ein Fehler lässt sich schwer nachvollziehen.
6. Im Cluster lädt containerd im Node-Container die Images, nicht Podman. containerd kennt weder dein Login noch die Artifactory-Adressen; es braucht den Registry-Mirror unter `/etc/containerd/certs.d` bzw. ein Pull-Secret.
7. Prozesse im Container haben auf dem Host nur die Rechte deines Benutzers. Einschränkung: Host-Ports unter 1024 lassen sich nicht belegen, und kind braucht cgroup v2 mit Delegation.

## Namespaces – mögliche Stichpunkte

- Trennung von Teams, Projekten oder Umgebungen
- eigene Rechte (RBAC) und Quotas pro Namespace
- gleiche Ressourcennamen in verschiedenen Namespaces möglich
