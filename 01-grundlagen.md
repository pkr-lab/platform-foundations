# Modul 01 – Lab-Umgebung & Container/Kubernetes-Grundlagen

## Kurzbeschreibung

In diesem Modul richtest du deine lokale Lab-Umgebung ein und machst erste Schritte mit Containern (Podman) und Kubernetes. Ziel ist, dass du einen lokalen `kind`-Cluster starten kannst und grundlegende Kubernetes-Begriffe kennst.

## Lernziele

- Podman nutzen, um Container zu starten, zu stoppen und zu inspizieren
- einen lokalen `kind`-Cluster in WSL erstellen und erreichen
- grundlegende `kubectl`-Befehle ausführen (`get`, `describe`, `logs`)
- die Begriffe Node, Pod, Deployment, Service und Namespace grob einordnen können

## Voraussetzungen

- WSL (Ubuntu) ist installiert und lauffähig
- grundlegende Shell-Kenntnisse (Navigation, einfache Befehle)

## Theorie (Kurzüberblick)

### Container & Podman

Container sind leichtgewichtige, isolierte Laufzeitumgebungen für Anwendungen. Sie teilen sich den Kernel des Hostsystems und sind schneller und ressourcenschonender als klassische VMs.

[Podman](https://podman.io/docs) ist ein Container-Werkzeug, das weitgehend Docker-kompatibel ist, aber ohne zentralen Daemon arbeiten kann. Du kannst damit Images ziehen, Container starten/stoppen und Logs ansehen.

Typische Aktionen:

- Image herunterladen
- Container starten (inklusive Port-Mapping)
- Container-Status prüfen
- Container stoppen und löschen

### Kubernetes & kind

[Kubernetes](https://kubernetes.io/docs/concepts/overview/what-is-kubernetes/) orchestriert viele Container auf mehreren Rechnern (Nodes) in einem Cluster. Wichtige Begriffe:

- **Cluster**: Gesamtheit aus Control Plane und Worker Nodes
- **Node**: einzelner Knoten (VM/Server), auf dem Pods laufen
- **Pod**: kleinste Ausführungseinheit in Kubernetes (enthält typischerweise einen oder wenige Container)
- **Deployment**: beschreibt, wie viele identische Pods laufen sollen und sorgt für Rollouts/Self-Healing
- **Service**: stellt stabile Erreichbarkeit für Pods bereit (feste IP/DNS, Load-Balancing)
- **Namespace**: logische Trennung von Ressourcen innerhalb des Clusters

[`kind`](https://kind.sigs.k8s.io/) (Kubernetes in Docker) erlaubt dir, einen vollständigen Kubernetes-Cluster lokal in Containern zu starten – ideal für Labs.

Hinweis: kind ist ursprünglich für Docker entwickelt. Mit Podman unter WSL kann zusätzliche Konfiguration nötig sein (z. B. ein Docker-kompatibler Socket). Wenn dein Cluster sich nicht starten lässt, schaue in die kind-Dokumentation für Podman oder verwende ein Docker-Backend, falls verfügbar.

### Lokales kind-Cluster (Unternehmens-Setup)

In diesem Lab verwendest du einen lokalen Kubernetes-Cluster, der mit [kind](https://kind.sigs.k8s.io/) gestartet wird.
Die Datei `kind.yaml` im Repo-Root enthält eine Konfiguration, die zu unserer Unternehmensumgebung passt:

- Zertifikate vom Host werden ins Cluster gemountet, damit der Cluster z. B. interne Container-Registries mit Firmen-CA nutzen kann.
- Die Ports 80 und 443 im Cluster werden auf die Host-Ports 8080 (HTTP) und 8443 (HTTPS) gemappt. Diese Ports verwenden wir in den weiteren Modulen als Standard.

#### Cluster erstellen

1. Wechsle in den Root-Ordner dieses Repositories (in WSL):

   ```bash
   cd ~/platform-foundations
   ls
   ```

2. Erstelle den Cluster `lab` mit der bereitgestellten Konfiguration:

   ```bash
   kind create cluster --name lab --config kind.yaml
   ```

3. Prüfe, ob der Cluster läuft:

   ```bash
   kind get clusters
   kubectl get nodes
   kubectl get pods -A
   ```

Wenn du den Cluster später einmal löschen musst, kannst du das mit:

```bash
kind delete cluster --name lab
```

> Hinweis: Lösche den Cluster während des Labs nur, wenn du ihn wirklich nicht mehr brauchst. Für die meisten Module ist es sinnvoll, denselben Cluster weiterzuverwenden.

## Aufgaben

Die folgenden Aufgaben führen dich Schritt für Schritt durch Podman- und Kubernetes-Grundlagen. Nutze gerne die offiziellen Dokumentationen und `--help`-Ausgaben, wenn dir Befehle fehlen.

### Aufgabe 1: Podman und Container-Basics

**Ziel:** Einen Container mit Podman starten, über den Browser erreichen und wieder stoppen.

1. Starte WSL (Ubuntu) und prüfe mit `podman --version`, ob Podman installiert ist. Wenn nicht, installiere Podman gemäß Distribution-Dokumentation.
2. Ziehe ein Webserver-Image, z. B. `docker.io/library/nginx`.
3. Starte einen Container im Vordergrund oder Hintergrund, der Port 8080 auf deinem Host bereitstellt. Beispiel-Port-Mapping: `8080:80`.
4. Öffne im Browser auf deinem Windows-System `http://localhost:8080` und prüfe, ob du die Nginx-Startseite siehst.
5. Liste laufende Container auf und stoppe deinen Container anschließend wieder.

Hinweis: Notiere dir die wichtigsten Befehle, die du verwendet hast.

Beispielbefehle:

```bash
podman pull docker.io/library/nginx
podman run --rm -p 8080:80 docker.io/library/nginx
podman ps
podman stop <container-id-oder-name>
```

### Aufgabe 2: Lokalen kind-Cluster erstellen

**Ziel:** Einen lokalen Kubernetes-Cluster mit `kind` in WSL erstellen.

1. Installiere `kind` gemäß der offiziellen Anleitung (achte auf deine Umgebung: WSL + Podman/Docker-Kompatibilität).
2. Erstelle einen neuen Cluster wie im Abschnitt "Lokales kind-Cluster (Unternehmens-Setup)" beschrieben (Name `lab`, Nutzung von `kind.yaml`).
3. Prüfe, ob der Cluster läuft, indem du dir die von `kind` erzeugte `kubeconfig` anzeigen lässt (normalerweise über `kubectl` bereits eingebunden).

Hinweise:

- Falls `kubectl` noch nicht installiert ist, installiere es jetzt mithilfe der offiziellen Dokumentation.
- Lies die Ausgabe von `kind` genau: dort steht, wie `kubectl` den Cluster findet.

Beispiel:

```bash
kind create cluster --name lab --config kind.yaml
kubectl config get-contexts
kubectl get nodes
```

### Aufgabe 3: Erste Schritte mit kubectl

**Ziel:** Den Zustand des Clusters abfragen und grundlegende Kubernetes-Objekte inspizieren.

 1. Rufe die Liste der Nodes ab.
 2. Lass dir alle Pods in allen Namespaces anzeigen.
 3. Wähle einen Pod (z. B. aus einem System-Namespace) und nutze `describe`, um Details zu sehen (Events, Labels, Container-Status).
 4. Notiere dir kurz, was dir an `describe` auffällt (z. B. Events, Image-Namen, Labels).
 5. Lass dir mit `kubectl config get-contexts` alle verfügbaren Kontexte anzeigen und prüfe mit `kubectl config current-context`, welcher aktuell aktiv ist.
 6. Wenn du mehrere Kontexte hast, wechsle testweise per `kubectl config use-context <name>` zu einem anderen und dann wieder zurück.

Nutze nach Bedarf `kubectl --help` oder die offizielle Referenz.

Beispielbefehle:

```bash
kubectl get nodes
kubectl get pods -A
kubectl describe pod <pod-name> -n <namespace>
```

### Aufgabe 4: Eine einfache Demo-App im Cluster deployen

**Ziel:** Eine eigene Anwendung als Deployment + Service im Cluster ausrollen.

1. Erstelle ein YAML-File, das ein Deployment für eine einfache Web-App beschreibt (z. B. ebenfalls Nginx mit 1–2 Replikas).
2. Erstelle ein zweites YAML-File oder einen zweiten Abschnitt im gleichen File für einen Service, der auf dein Deployment zeigt.
3. Wende die Konfiguration auf den Cluster an.
4. Prüfe mit `kubectl get pods` und `kubectl get svc`, ob deine Ressourcen laufen.
 5. Ermittele, wie du deine App erreichen kannst (z. B. über NodePort, Port-Forwarding oder einen anderen Mechanismus, abhängig von deiner kind-Standardkonfiguration).

Hinweis: Wenn du unsicher bist, wie ein Deployment/Service-YAML aussieht, suche in der offiziellen Kubernetes-Dokumentation nach Beispielen und passe sie an.

Beispiel für ein einfaches Port-Forwarding:

```bash
kubectl port-forward svc/<service-name> 8080:80
```

### Aufgabe 5: Namespaces ausprobieren

**Ziel:** Ressourcen in unterschiedlichen Namespaces anlegen und gezielt abfragen.

1. Lege zwei Namespaces an, z. B. `dev` und `test`.
2. Deploye deine Demo-App aus Aufgabe 4 jeweils in beide Namespaces (du kannst dafür die gleiche YAML-Datei mit Anpassung des Namespace-Feldes nutzen).
3. Zeige dir für jeden Namespace die Deployments und Services separat an.
4. Überlege: Warum sind Namespaces in größeren Clustern hilfreich? Schreibe 2–3 Stichpunkte dazu auf.

## Weiterführend

Wenn du früher fertig bist oder tiefer einsteigen möchtest:

- Schaue dir die offizielle Kubernetes-Übersichtsseite an und lies die Abschnitte zu Pods und Deployments (z. B. [Kubernetes Concepts](https://kubernetes.io/docs/concepts/)).
- Experimentiere mit verschiedenen Podman-Befehlen (Logs anzeigen, Container-Inspektion, eigene Port-Mappings).
- Probiere weitere `kubectl`-Befehle aus (z. B. `kubectl get all -A`).
