# Modul 01 – Lab-Umgebung & Container/Kubernetes-Grundlagen

## Kurzbeschreibung

In diesem Modul richtest du deine lokale Lab-Umgebung ein: WSL mit **rootless Podman**, den Zugang zum JFrog Artifactory und einen lokalen `kind`-Cluster. Danach machst du erste Schritte mit Containern und Kubernetes. Ziel ist, dass du einen lokalen Cluster starten kannst, der seine Images aus dem Artifactory bezieht, und grundlegende Kubernetes-Begriffe kennst.

Nicht jeder Befehl ist bis ins letzte Detail erklärt. Recherchiere selbst in der offiziellen Dokumentation, mit einer Suchmaschine oder einem KI-Assistenten – und frag nach, wenn du nicht weiterkommst.

## Lernziele

- WSL und Podman so einrichten, dass Container ohne root-Rechte laufen (rootless)
- ein Image im JFrog Artifactory finden, mit Podman herunterladen und als Container starten, inspizieren und stoppen
- einen lokalen `kind`-Cluster erstellen, der seine Images ebenfalls über das Artifactory bezieht
- grundlegende `kubectl`-Befehle ausführen (`get`, `describe`, `logs`)
- die Begriffe Node, Pod, Deployment, Service und Namespace grob einordnen

## Voraussetzungen

- WSL 2 mit Ubuntu 24.04 ist installiert
- grundlegende Shell-Kenntnisse (Navigation, einfache Befehle)
- ein Benutzerkonto für das JFrog Artifactory und die Werte für die Platzhalter aus [docs/Artifactory.md](./docs/Artifactory.md#platzhalter) – beides bekommst du von deinem Ausbilder
- die Firmen-CA als `.crt`-Datei (vom Ausbilder)
- die Tools aus [docs/Tools-und-Versionen.md](./docs/Tools-und-Versionen.md) sind installiert oder werden in diesem Modul installiert

## Theorie (Kurzüberblick)

### Container & Podman

Container sind leichtgewichtige, isolierte Laufzeitumgebungen für Anwendungen. Sie teilen sich den Kernel des Hostsystems und sind schneller und ressourcenschonender als klassische VMs.

[Podman](https://podman.io/docs) ist ein Container-Werkzeug, das weitgehend Docker-kompatibel ist, aber ohne zentralen Daemon arbeitet. Fast jeder `docker`-Befehl funktioniert auch als `podman`-Befehl.

Ein **Image** ist die unveränderliche Vorlage (Dateisystem + Startbefehl), ein **Container** ist eine laufende Instanz davon. Images liegen in einer **Registry**.

### Rootless

Podman kann Container als normaler Benutzer starten (**rootless**). Ein Prozess, der im Container als `root` läuft, hat auf dem Host dann nur die Rechte deines Benutzers. Bricht jemand aus dem Container aus, ist er nicht automatisch root auf deinem Rechner. Im Lab arbeitest du deshalb **ohne `sudo`** mit Podman und kind.

Einschränkung: Als normaler Benutzer kannst du keine Host-Ports unter 1024 belegen. Deshalb nutzt das Lab die Ports 8080, 8443 und 8081 (siehe [docs/Ports.md](./docs/Ports.md)).

### Images kommen aus dem Artifactory

Bei uns ist das **JFrog Artifactory** der einzige Weg zu Images – direkte Downloads von Docker Hub & Co. sind gesperrt. Die Image-Adresse sieht deshalb anders aus:

| Außerhalb der Firma | Bei uns |
| --- | --- |
| `docker.io/library/nginx:1.28.0` | `<artifactory-host>/<docker-remote-repo>/nginx:1.28.0` |

Die richtige Adresse zeigt dir Artifactory unter **Packages**. In [Modul 04](./04-artifactory-artefakte.md) lernst du Artifactory genauer kennen; die wichtigsten Infos stehen in [docs/Artifactory.md](./docs/Artifactory.md).

Verwende immer einen **festen Tag** wie `1.28.0`. Tags wie `latest` oder `stable` sind beweglich: Sie zeigen heute auf eine andere Version als in drei Monaten.

### Kubernetes & kind

[Kubernetes](https://kubernetes.io/docs/concepts/overview/what-is-kubernetes/) orchestriert viele Container auf mehreren Rechnern (Nodes) in einem Cluster. Wichtige Begriffe:

- **Cluster**: Gesamtheit aus Control Plane und Worker Nodes
- **Node**: einzelner Knoten (VM/Server), auf dem Pods laufen
- **Pod**: kleinste Ausführungseinheit in Kubernetes (enthält typischerweise einen oder wenige Container)
- **Deployment**: beschreibt, wie viele identische Pods laufen sollen und sorgt für Rollouts/Self-Healing
- **Service**: stellt stabile Erreichbarkeit für Pods bereit (feste IP/DNS, Load-Balancing)
- **Namespace**: logische Trennung von Ressourcen innerhalb des Clusters

[`kind`](https://kind.sigs.k8s.io/) (Kubernetes in Docker) startet einen vollständigen Kubernetes-Cluster lokal in Containern – ideal für Labs. Jeder Kubernetes-Node ist dabei selbst ein Podman-Container.

Wichtig: Im Cluster zieht nicht Podman die Images, sondern **containerd** im Node-Container. Deshalb braucht der Cluster einen eigenen Weg ins Artifactory, den **Registry-Mirror** (Aufgabe 3).

### Die Datei `kind.yaml` (Unternehmens-Setup)

Die Datei [`kind.yaml`](./kind.yaml) im Repo-Root enthält eine Konfiguration, die zu unserer Unternehmensumgebung passt. Details findest du in [docs/kind-Konfiguration.md](./docs/kind-Konfiguration.md).

- Die Ports 80 und 443 im Cluster werden auf die Host-Ports **8080** (HTTP) und **8443** (HTTPS) gemappt. Sie sind für den Ingress-Controller reserviert (Modul 02).
- Die Firmen-CA und die Registry-Mirror-Konfiguration aus `/etc/containerd/certs.d` werden in den Node eingehängt.

> **Port-Konvention im Lab:** 8080/8443 gehören dem kind-Cluster. Für `kubectl port-forward` nutzen wir deshalb immer **andere** Ports, z. B. `9080` (azubi-portal), `9443` (ArgoCD), `9300` (Grafana), `9005` (Headlamp). Für Podman-Tests nutzen wir `8081`. Eine Übersicht steht in [docs/Ports.md](./docs/Ports.md).

## Aufgaben

### Aufgabe 1: WSL und rootless Podman einrichten

**Ziel:** Podman läuft ohne `sudo` und erfüllt die Voraussetzungen für kind.

1. Prüfe, ob systemd in WSL läuft. Die Ausgabe muss `systemd` lauten:

   ```bash
   ps -p 1 -o comm=
   ```

   Falls nicht: Trage in `/etc/wsl.conf` Folgendes ein, führe in der Windows-PowerShell `wsl --shutdown` aus und starte WSL neu.

   ```ini
   [boot]
   systemd=true
   ```

2. Installiere Podman und prüfe die Version (mindestens 4.x):

   ```bash
   sudo apt update && sudo apt install -y podman
   podman --version
   ```

3. Prüfe, ob Podman rootless arbeitet und dein Benutzer eigene User-ID-Bereiche hat. Beide `grep`-Befehle müssen eine Zeile ausgeben:

   ```bash
   podman info --format '{{.Host.Security.Rootless}}'
   grep "^$USER:" /etc/subuid
   grep "^$USER:" /etc/subgid
   ```

4. kind braucht **cgroup v2**. Die Ausgabe muss `cgroup2fs` lauten, sonst siehe [docs/Fehlerbehebung.md](./docs/Fehlerbehebung.md#kind-mit-rootless-podman):

   ```bash
   stat -fc %T /sys/fs/cgroup
   ```

5. Erlaube systemd, deinem Benutzer die Ressourcen-Controller (CPU, Memory, …) zu übergeben (**Delegation**):

   ```bash
   sudo mkdir -p /etc/systemd/system/user@.service.d
   printf '[Service]\nDelegate=yes\n' | sudo tee /etc/systemd/system/user@.service.d/delegate.conf
   sudo systemctl daemon-reload
   ```

   Starte WSL mit `wsl --shutdown` neu und prüfe, dass die Ausgabe `cpu`, `memory` und `pids` enthält:

   ```bash
   cat /sys/fs/cgroup/user.slice/user-$(id -u).slice/user@$(id -u).service/cgroup.controllers
   ```

6. Sag kind dauerhaft, dass es Podman statt Docker verwenden soll:

   ```bash
   echo 'export KIND_EXPERIMENTAL_PROVIDER=podman' >> ~/.bashrc
   source ~/.bashrc
   ```

7. Installiere die Firmen-CA in WSL, damit Podman und später der Cluster dem Artifactory vertrauen:

   ```bash
   sudo cp <firmen-ca>.crt /usr/local/share/ca-certificates/
   sudo update-ca-certificates
   ```

8. Installiere `kind`, `kubectl` und `helm` (siehe [docs/Tools-und-Versionen.md](./docs/Tools-und-Versionen.md)) und klone dieses Lab-Repo:

   ```bash
   git clone <url-dieses-lab-repos> ~/platform-foundations
   ```

Ab hier gilt: **kein `sudo` vor `podman` oder `kind`.** Mit `sudo` landest du in einer zweiten, getrennten Podman-Umgebung von root und findest deine Container und deinen Cluster nicht wieder.

### Aufgabe 2: Erstes Image aus dem Artifactory

**Ziel:** Ein Image im Artifactory finden, mit Podman herunterladen und als Container starten.

1. Öffne `https://<artifactory-host>/` und melde dich an.
2. Öffne **Artifactory → Packages**, suche nach `nginx` und wähle den Pakettyp **Docker**. Wähle die Version `1.28.0` und kopiere den angezeigten Pull-Befehl. Ersetze `docker` durch `podman`.
3. Melde Podman am Artifactory an (Benutzer und Token, siehe [docs/Artifactory.md](./docs/Artifactory.md#anmelden)), lade das Image und starte einen Container auf Port 8081:

   ```bash
   podman login <artifactory-host>
   podman pull <artifactory-host>/<docker-remote-repo>/nginx:1.28.0
   podman images
   podman run -d --rm --name web-test -p 8081:80 <artifactory-host>/<docker-remote-repo>/nginx:1.28.0
   podman ps
   ```

4. Öffne im Browser auf deinem Windows-System `http://localhost:8081` oder teste in WSL mit `curl -s localhost:8081 | head -n 5`.
5. Sieh dir den Container genauer an:

   ```bash
   podman logs web-test
   podman exec -it web-test sh
   podman inspect web-test --format '{{.Config.Image}}'
   podman top web-test user huser
   podman stop web-test
   ```

   In der Shell aus `podman exec` kannst du dich umsehen (`cat /etc/os-release`, `ls /usr/share/nginx/html`) und mit `exit` wieder herauskommen. Was zeigt `podman top` in den Spalten `USER` und `HUSER`? Was sagt das über rootless Podman aus?

### Aufgabe 3: Registry-Mirror für den Cluster einrichten

**Ziel:** Der kind-Cluster lädt Images, die auf docker.io, quay.io, ghcr.io oder registry.k8s.io verweisen, automatisch über das Artifactory.

Hintergrund und Aufbau der Dateien stehen in [docs/Artifactory.md](./docs/Artifactory.md#registry-mirror-für-den-kind-cluster).

1. Ersetze im folgenden Skript die Platzhalter durch eure Werte und führe es aus. Es legt pro Registry eine `hosts.toml` an:

   ```bash
   for eintrag in "docker.io=<docker-remote-repo>" "quay.io=<quay-remote-repo>" "ghcr.io=<ghcr-remote-repo>" "registry.k8s.io=<k8s-remote-repo>"; do
     registry="${eintrag%%=*}"
     repo="${eintrag#*=}"
     sudo mkdir -p "/etc/containerd/certs.d/$registry"
     printf 'server = "https://%s"\n\n[host."https://<artifactory-host>/v2/%s"]\n  capabilities = ["pull", "resolve"]\n  override_path = true\n' "$registry" "$repo" \
       | sudo tee "/etc/containerd/certs.d/$registry/hosts.toml" > /dev/null
   done
   ```

2. Kontrolliere das Ergebnis:

   ```bash
   ls /etc/containerd/certs.d
   cat /etc/containerd/certs.d/docker.io/hosts.toml
   ```

Das Verzeichnis `/etc/containerd/certs.d` muss existieren, bevor du den Cluster erstellst, sonst bricht `kind create cluster` ab.

### Aufgabe 4: kind-Cluster erstellen

**Ziel:** Einen lokalen Kubernetes-Cluster mit `kind` und rootless Podman erstellen, dessen Node-Image aus dem Artifactory kommt.

1. Prüfe mit `kind version`, welche kind-Version du hast. In den [Release Notes von kind](https://github.com/kubernetes-sigs/kind/releases) steht, welches Node-Image `kindest/node:<version>` zu deiner kind-Version gehört. Suche dieses Image im Artifactory unter **Packages**.
2. Erstelle den Cluster mit dem Node-Image aus dem Artifactory:

   ```bash
   cd ~/platform-foundations
   kind create cluster --name lab --config kind.yaml \
     --image <artifactory-host>/<docker-remote-repo>/kindest/node:<version>
   ```

3. Prüfe, ob der Cluster läuft:

   ```bash
   kind get clusters
   podman ps
   kubectl config current-context
   kubectl get nodes
   kubectl get pods -A
   ```

4. Teste den Registry-Mirror. Das Image ist absichtlich mit seiner Docker-Hub-Adresse angegeben – containerd soll es trotzdem über das Artifactory holen:

   ```bash
   kubectl run mirror-test --image=docker.io/library/busybox:1.36.1 --restart=Never --command -- echo "Mirror funktioniert"
   kubectl get pod mirror-test
   kubectl logs mirror-test
   kubectl delete pod mirror-test
   ```

   Bleibt der Pod in `ErrImagePull` oder `ImagePullBackOff` hängen, zeigt `kubectl describe pod mirror-test` im Abschnitt Events den Grund (siehe [docs/Fehlerbehebung.md](./docs/Fehlerbehebung.md)).

> Hinweis: Nach einem Neustart von WSL ist der Node-Container gestoppt. Starte ihn mit `podman start lab-control-plane`. Lösche den Cluster nur, wenn du ihn wirklich nicht mehr brauchst (`kind delete cluster --name lab`) – die meisten Module bauen auf demselben Cluster auf.

### Aufgabe 5: Erste Schritte mit kubectl

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

### Aufgabe 6: Eine einfache Demo-App im Cluster deployen

**Ziel:** Eine eigene Anwendung als Deployment + Service im Cluster ausrollen.

1. Erstelle ein YAML-File `demo.yaml`, das ein Deployment für Nginx mit 2 Replikas beschreibt. Verwende als Image die Artifactory-Adresse aus Aufgabe 2.
2. Ergänze im gleichen File (getrennt durch `---`) einen Service vom Typ `ClusterIP`, der auf dein Deployment zeigt.
3. Wende die Konfiguration mit `kubectl apply -f demo.yaml` an.
4. Prüfe mit `kubectl get pods` und `kubectl get svc`, ob deine Ressourcen laufen.
5. Mach die App per Port-Forwarding erreichbar und öffne `http://localhost:9080`.

Tipp: kubectl erzeugt dir ein YAML-Grundgerüst:

```bash
kubectl create deployment demo --image=<artifactory-host>/<docker-remote-repo>/nginx:1.28.0 --replicas=2 --dry-run=client -o yaml
kubectl port-forward svc/<service-name> 9080:80
```

Hängen die Pods mit `ImagePullBackOff` und `401 Unauthorized` in den Events, verlangt das Artifactory auch für den Cluster eine Anmeldung. Frag deinen Ausbilder – die Lösung mit einem Pull-Secret lernst du in Modul 04 (Vorgriff: [docs/Artifactory.md](./docs/Artifactory.md#zugriff-aus-dem-cluster-pull-secret)).

### Aufgabe 7: Namespaces ausprobieren

**Ziel:** Ressourcen in unterschiedlichen Namespaces anlegen und gezielt abfragen.

1. Lege zwei Namespaces an, z. B. `dev` und `test`.
2. Deploye deine Demo-App aus Aufgabe 6 in beide Namespaces (z. B. mit `kubectl apply -f demo.yaml -n dev`).
3. Zeige dir für jeden Namespace die Deployments und Services separat an.
4. Überlege: Warum sind Namespaces in größeren Clustern hilfreich? Schreibe 2–3 Stichpunkte dazu auf.

### Bonus-Aufgaben (für Fortgeschrittene)

- Lege einen Ordner `~/web` mit einer eigenen `index.html` an und hänge ihn als Volume in einen Nginx-Container ein (`podman run … -v ~/web:/usr/share/nginx/html:ro …`). Was passiert, wenn du die Datei änderst, während der Container läuft?
- Starte einen Container mit einer Umgebungsvariablen (`-e GRUSS=hallo`) und lies sie mit `podman exec <name> env` aus.
- Lege mit `podman network create labnet` ein eigenes Netzwerk an, starte darin einen Nginx-Container mit `--name web` und rufe ihn aus einem zweiten Container (`curlimages/curl:8.10.1` aus dem Artifactory) über den Namen `web` auf.
- Probiere weitere `kubectl`-Befehle aus: `kubectl get all -A`, `kubectl explain deployment.spec`, `kubectl get pod <name> -o yaml`.

## Du bist fertig, wenn …

- [ ] `podman info --format '{{.Host.Security.Rootless}}'` den Wert `true` liefert und du Podman und kind ohne `sudo` nutzt
- [ ] du einen Nginx-Container mit einem Image aus dem Artifactory starten, im Browser öffnen und stoppen kannst
- [ ] `kubectl get nodes` einen Node `lab-control-plane` im Status `Ready` zeigt
- [ ] der Pod `mirror-test` erfolgreich „Mirror funktioniert“ ausgegeben hat
- [ ] deine Demo-App in `dev` und `test` läuft und per Port-Forwarding erreichbar ist

## Verständnisfragen

1. Was ist der Unterschied zwischen einem Image und einem Container?
2. Warum startet Kubernetes Pods neu, wenn du einen Pod eines Deployments löschst – und warum passiert das bei einem einzeln erstellten Pod nicht?
3. Wozu braucht ein Deployment einen `selector`?
4. Warum können wir für Port-Forwarding nicht Port 8080 verwenden?
5. Warum ist `nginx:1.28.0` besser als `nginx:stable` oder `nginx:latest`?
6. Warum reicht dein `podman login` nicht aus, damit der kind-Cluster Images aus dem Artifactory laden kann?
7. Welchen Sicherheitsvorteil hat rootless Podman, und welche Einschränkung bringt es mit sich?

## Häufige Stolperfallen & Tipps

- `short-name … did not resolve to an alias`: Podman kennt den kurzen Namen nicht. Gib immer die vollständige Artifactory-Adresse an.
- `unauthorized` beim Pull: `podman login <artifactory-host>` vergessen oder Token abgelaufen.
- `x509: certificate signed by unknown authority`: Die Firmen-CA fehlt in WSL (Aufgabe 1, Schritt 7).
- `kind create cluster` meldet etwas zu cgroups oder `rootless`: Schritte 4 und 5 aus Aufgabe 1 prüfen, Details in [docs/Fehlerbehebung.md](./docs/Fehlerbehebung.md#kind-mit-rootless-podman).
- `kind get clusters` zeigt nichts, obwohl der Cluster existiert: Hast du `sudo` verwendet? Mit `sudo` siehst du die Container von root, nicht deine.
- Nach einem WSL-Neustart antwortet `kubectl` nicht: `podman start lab-control-plane`.

## Aufräumen

```bash
kubectl delete -f demo.yaml
kubectl delete namespace dev test
podman rmi <artifactory-host>/<docker-remote-repo>/nginx:1.28.0
```

Den Cluster `lab` brauchst du in den folgenden Modulen weiter.

## Weiterführend

- [Kubernetes Concepts](https://kubernetes.io/docs/concepts/) – Abschnitte zu Pods und Deployments
- [kind Quick Start](https://kind.sigs.k8s.io/docs/user/quick-start/) und [kind mit rootless Podman](https://kind.sigs.k8s.io/docs/user/rootless/)
- [Podman – Rootless Tutorial](https://github.com/containers/podman/blob/main/docs/tutorials/rootless_tutorial.md)

Eine Musterlösung findest du unter [solutions/modul-01](./solutions/modul-01/).
