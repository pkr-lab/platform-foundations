# Modul 01 – Lab-Umgebung & Container/Kubernetes-Grundlagen

## Kurzbeschreibung

In diesem Modul richtest du deine lokale Lab-Umgebung ein und machst erste Schritte mit Containern (Podman) und Kubernetes. Ziel ist, dass du einen lokalen `kind`-Cluster starten kannst und grundlegende Kubernetes-Begriffe kennst.

Viel musst du dir selber erarbeiten durch Google Suche oder benutzen eines KI-Chat-bots

## Lernziele

- Podman nutzen, um Container zu starten, zu stoppen und zu inspizieren
- einen lokalen `kind`-Cluster in WSL mit Podman erstellen und erreichen
- grundlegende `kubectl`-Befehle ausführen (`get`, `describe`, `logs`)
- die Begriffe Node, Pod, Deployment, Service und Namespace grob einordnen können

## Voraussetzungen

- WSL (Ubuntu) ist installiert und lauffähig
- grundlegende Shell-Kenntnisse (Navigation, einfache Befehle)
- die Tools aus [docs/Tools-und-Versionen.md](./docs/Tools-und-Versionen.md) sind installiert oder werden in diesem Modul installiert

## Theorie (Kurzüberblick)

### Container & Podman

Container sind leichtgewichtige, isolierte Laufzeitumgebungen für Anwendungen. Sie teilen sich den Kernel des Hostsystems und sind schneller und ressourcenschonender als klassische VMs.

[Podman](https://podman.io/docs) ist ein Container-Werkzeug, das weitgehend Docker-kompatibel ist, aber ohne zentralen Daemon arbeiten kann. Du kannst damit Images ziehen, Container starten/stoppen und Logs ansehen.

Ein **Image** ist die unveränderliche Vorlage (Dateisystem + Startbefehl), ein **Container** ist eine laufende Instanz davon. Images liegen in einer **Registry** (z. B. Docker Hub oder ein firmeninternes Artifactory, siehe [Modul 04](./04-artifactory-artefakte.md)).

### Kubernetes & kind

[Kubernetes](https://kubernetes.io/docs/concepts/overview/what-is-kubernetes/) orchestriert viele Container auf mehreren Rechnern (Nodes) in einem Cluster. Wichtige Begriffe:

- **Cluster**: Gesamtheit aus Control Plane und Worker Nodes
- **Node**: einzelner Knoten (VM/Server), auf dem Pods laufen
- **Pod**: kleinste Ausführungseinheit in Kubernetes (enthält typischerweise einen oder wenige Container)
- **Deployment**: beschreibt, wie viele identische Pods laufen sollen und sorgt für Rollouts/Self-Healing
- **Service**: stellt stabile Erreichbarkeit für Pods bereit (feste IP/DNS, Load-Balancing)
- **Namespace**: logische Trennung von Ressourcen innerhalb des Clusters

[`kind`](https://kind.sigs.k8s.io/) (Kubernetes in Docker) startet einen vollständigen Kubernetes-Cluster lokal in Containern – ideal für Labs. Jeder Kubernetes-Node ist dabei selbst ein Container.

### Die Datei `kind.yaml` (Unternehmens-Setup)

Die Datei [`kind.yaml`](./kind.yaml) im Repo-Root enthält eine Konfiguration, die zu unserer Unternehmensumgebung passt. Details findest du in [docs/kind-Konfiguration.md](./docs/kind-Konfiguration.md).

- Die Ports 80 und 443 im Cluster werden auf die Host-Ports **8080** (HTTP) und **8443** (HTTPS) gemappt. Sie sind für den Ingress-Controller reserviert (Modul 02).

> **Port-Konvention im Lab:** 8080/8443 gehören dem kind-Cluster. Für `kubectl port-forward` nutzen wir deshalb immer **andere** Ports, z. B. `9080` (azubi-portal), `9443` (ArgoCD), `9300` (Grafana), `9005` (Headlamp). Für Podman-Tests nutzen wir `8081`. Eine Übersicht steht in [docs/Ports.md](./docs/Ports.md).

## Aufgaben

### Aufgabe 1: Podman und Container-Basics

**Ziel:** Einen Container mit Podman starten, über den Browser erreichen und wieder stoppen.

1. Starte WSL (Ubuntu) und prüfe mit `podman --version`, ob Podman installiert ist. Wenn nicht: `sudo apt update && sudo apt install -y podman`.
2. Ziehe ein Webserver-Image, z. B. `docker.io/library/nginx:stable`.
3. Starte einen Container im Hintergrund, der Port 8081 auf deinem Host bereitstellt (`8081:80`).
4. Öffne im Browser auf deinem Windows-System `http://localhost:8081` und prüfe, ob du die Nginx-Startseite siehst.
5. Sieh dir die Logs des Containers an, liste laufende Container auf und stoppe deinen Container anschließend wieder.

Beispielbefehle:

```bash
podman pull docker.io/library/nginx:stable
podman run -d --rm --name web-test -p 8081:80 docker.io/library/nginx:stable
podman ps
podman logs web-test
podman stop web-test
```

Überlege: Warum ist `nginx:stable` besser als `nginx` ohne Tag (also implizit `latest`)?

### Aufgabe 2: kind mit Podman vorbereiten und Cluster erstellen

**Ziel:** Einen lokalen Kubernetes-Cluster mit `kind` in WSL erstellen.

kind ist ursprünglich für Docker gebaut. Mit Podman sind ein paar Vorbereitungen nötig:

1. **Cluster erstellen.** 

   ```bash
   cd ~/platform-foundations
   kind create cluster --name lab --config kind.yaml
   ```

2. Prüfe, ob der Cluster läuft:

   ```bash
   sudo -E kind get clusters
   kubectl config get-contexts
   kubectl get nodes
   kubectl get pods -A
   ```

> Hinweis: Lösche den Cluster während des Labs nur, wenn du ihn wirklich nicht mehr brauchst (`kind delete cluster --name lab`). Die meisten Module bauen auf demselben Cluster auf.

### Aufgabe 3: Erste Schritte mit kubectl

**Ziel:** Den Zustand des Clusters abfragen und grundlegende Kubernetes-Objekte inspizieren.

1. Rufe die Liste der Nodes ab.
2. Lass dir alle Pods in allen Namespaces anzeigen.
3. Wähle einen Pod (z. B. aus dem Namespace `kube-system`) und nutze `describe`, um Details zu sehen (Events, Labels, Container-Status).
4. Notiere dir kurz, was dir an `describe` auffällt (z. B. Events, Image-Namen, Labels).
5. Lass dir mit `kubectl config get-contexts` alle verfügbaren Kontexte anzeigen und prüfe mit `kubectl config current-context`, welcher aktuell aktiv ist (er sollte `kind-lab` heißen).

Beispielbefehle:

```bash
kubectl get nodes -o wide
kubectl get pods -A
kubectl describe pod <pod-name> -n kube-system
kubectl logs <pod-name> -n kube-system
```

### Aufgabe 4: Eine einfache Demo-App im Cluster deployen

**Ziel:** Eine eigene Anwendung als Deployment + Service im Cluster ausrollen.

1. Erstelle ein YAML-File `demo.yaml`, das ein Deployment für Nginx mit 2 Replikas beschreibt.
2. Ergänze im gleichen File (getrennt durch `---`) einen Service vom Typ `ClusterIP`, der auf dein Deployment zeigt.
3. Wende die Konfiguration mit `kubectl apply -f demo.yaml` an.
4. Prüfe mit `kubectl get pods` und `kubectl get svc`, ob deine Ressourcen laufen.
5. Mach die App per Port-Forwarding erreichbar und öffne `http://localhost:9080`.

Tipp: Mit `kubectl create deployment demo --image=docker.io/library/nginx:stable --dry-run=client -o yaml` erzeugt kubectl dir ein YAML-Grundgerüst.

```bash
kubectl port-forward svc/<service-name> 9080:80
```

### Aufgabe 5: Namespaces ausprobieren

**Ziel:** Ressourcen in unterschiedlichen Namespaces anlegen und gezielt abfragen.

1. Lege zwei Namespaces an, z. B. `dev` und `test`.
2. Deploye deine Demo-App aus Aufgabe 4 in beide Namespaces (z. B. mit `kubectl apply -f demo.yaml -n dev`).
3. Zeige dir für jeden Namespace die Deployments und Services separat an.
4. Überlege: Warum sind Namespaces in größeren Clustern hilfreich? Schreibe 2–3 Stichpunkte dazu auf.

## Du bist fertig, wenn …

- [ ] `kubectl get nodes` einen Node `lab-control-plane` im Status `Ready` zeigt
- [ ] du einen Nginx-Container mit Podman starten, im Browser öffnen und stoppen kannst
- [ ] deine Demo-App in `dev` und `test` läuft und per Port-Forwarding erreichbar ist

## Verständnisfragen

1. Was ist der Unterschied zwischen einem Image und einem Container?
2. Warum startet Kubernetes Pods neu, wenn du einen Pod eines Deployments löschst – und warum passiert das bei einem einzeln erstellten Pod nicht?
3. Wozu braucht ein Deployment einen `selector`?
4. Warum können wir für Port-Forwarding nicht Port 8080 verwenden?

## Aufräumen

```bash
kubectl delete -f demo.yaml
kubectl delete namespace dev test
```

## Weiterführend

- [Kubernetes Concepts](https://kubernetes.io/docs/concepts/) – Abschnitte zu Pods und Deployments
- [kind Quick Start](https://kind.sigs.k8s.io/docs/user/quick-start/) und [kind mit Podman (rootless)](https://kind.sigs.k8s.io/docs/user/rootless/)
- Probiere weitere `kubectl`-Befehle aus (z. B. `kubectl get all -A`, `kubectl explain deployment.spec`).

Eine Musterlösung findest du unter [solutions/modul-01](./solutions/modul-01/).
