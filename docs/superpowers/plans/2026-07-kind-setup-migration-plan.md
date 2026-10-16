# kind-Setup Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migriere das kind-Setup (inkl. Unternehmens-Zertifikate und Port-Mappings) aus dem alten `zcpm-azubi-lab` in das neue Lab im Repo-Root und verankere es in Modul 01.

**Architecture:** Eine zentrale `kind.yaml` im Repo-Root definiert den Cluster `lab` mit Firmen-Zertifikats-Mounts und festen Ports (8080/8443). Modul 01 bekommt ein Unterkapitel mit Schritt-für-Schritt-Anleitung für die Cluster-Erstellung, alle Beispiele referenzieren den Clusternamen und die Ports konsistent.

**Tech Stack:** Markdown-Dokumentation, kind (kind.x-k8s.io/v1alpha4), kubectl, WSL/Podman.

## Global Constraints

- kind-Konfiguration liegt im Repo-Root als `kind.yaml`.
- Clustername ist konsequent `lab`.
- Port-Mappings: 80→8080, 443→8443.
- Zertifikats-Mounts `/etc/ssl/certs` und `/etc/containerd/certs.d` sind verbindlich.
- Firmen-Registry wird später mit konkretem Hostnamen in Modulen eingebaut (nicht Teil dieses Minimalplans).

---

### Task 1: Zentrales kind.yaml im Repo-Root anlegen

**Files:**
- Create: `kind.yaml`

**Interfaces:**
- Consumes: Design-Vorgaben aus `docs/superpowers/specs/2026-07-kind-setup-migration-design.md`.
- Produces: kind-Cluster-Konfiguration, die von allen Modulen und Azubi-Schritten genutzt wird.

- [ ] **Step 1: kind.yaml mit gewünschter Konfiguration anlegen**

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    extraPortMappings:
      - containerPort: 80
        hostPort: 8080
        protocol: TCP
      - containerPort: 443
        hostPort: 8443
        protocol: TCP
    extraMounts:
      - hostPath: /etc/ssl/certs
        containerPath: /etc/ssl/certs
      - hostPath: /etc/containerd/certs.d
        containerPath: /etc/containerd/certs.d
```

- [ ] **Step 2: (Optional) Manual-Check: Datei gegen altes kind.yaml vergleichen**

Vergleiche Inhalt mit `/workspace/zcpm-azubi-lab/03-setup-kind/kind.yaml`, um sicherzustellen, dass alle relevanten Einstellungen übernommen sind.

---

### Task 2: Modul 01 um kind-Unterkapitel erweitern

**Files:**
- Modify: `01-grundlagen.md`

**Interfaces:**
- Consumes: vorhandene Struktur von Modul 01.
- Produces: Unterkapitel mit klaren Schritten zum Starten des `lab`-Clusters mit `kind.yaml`.

- [ ] **Step 1: Bestehende Struktur von `01-grundlagen.md` analysieren**

Lies `01-grundlagen.md` und identifiziere geeignete Stelle nach der Theorie zu Kubernetes und kind (Bereich um Zeilen 34–47), um ein neues Unterkapitel zu platzieren.

- [ ] **Step 2: Neues Unterkapitel „Lokales kind-Cluster (Unternehmens-Setup)“ einfügen**

Füge nach dem Theorie-Abschnitt zu Kubernetes/kind ein Unterkapitel ein, z. B.:

```markdown
### Lokales kind-Cluster (Unternehmens-Setup)

In unserem Lab verwendest du einen lokalen Kubernetes-Cluster, der mit [kind](https://kind.sigs.k8s.io/) gestartet wird. 
Die Datei `kind.yaml` im Repo-Root enthält eine Konfiguration, die zu unserer Unternehmensumgebung passt:

- Zertifikate vom Host werden ins Cluster gemountet, damit der Cluster z. B. interne Registries mit Firmen-CA nutzen kann.
- Ports 80 und 443 im Cluster werden auf die Host-Ports 8080 (HTTP) und 8443 (HTTPS) gemappt. Diese Ports verwenden wir in den weiteren Modulen als Standard.

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
```

- [ ] **Step 3: Existierende Aufgaben in Modul 01 kurz prüfen**

Prüfe, ob Aufgabe 2 (kind-Cluster erstellen) bereits eigene Befehle nennt, und passe sie minimal an, damit sie auf den neuen Standard verweist (Clustername `lab`, Nutzung von `kind.yaml`), ohne die Aufgabenstruktur komplett zu ändern.

---

### Task 3: Konsistenz der Cluster-Namen und Ports in Modul 01 sichern

**Files:**
- Modify: `01-grundlagen.md`

**Interfaces:**
- Consumes: alle Stellen in Modul 01, die Cluster-Namen oder Ports verwenden.
- Produces: konsistente Verwendung von `lab`, `8080`, `8443` innerhalb von Modul 01.

- [ ] **Step 1: `01-grundlagen.md` nach Clustername und Ports durchsuchen**

Suche nach `azubi-lab`, `kind create cluster`, `8080`, `8443` in `01-grundlagen.md` und notiere alle Stellen.

- [ ] **Step 2: Clustername auf `lab` vereinheitlichen**

Passe alle Beispielbefehle mit `kind create cluster` oder Kontext-Namen so an, dass `lab` der verwendete Name ist, z. B.:

```bash
kind create cluster --name lab --config kind.yaml
kubectl config get-contexts
kubectl config current-context
```

Falls im Text „azubi-lab“ erwähnt wird, ersetze durch „lab“ oder formuliere neutral („dein Cluster“), je nach Kontext.

- [ ] **Step 3: Ports in Beispielen überprüfbar machen**

Stelle sicher, dass in Beispielen für Port-Mappings oder Port-Forwardings (z. B. Podman/nginx, `kubectl port-forward`) der Port 8080 konsistent verwendet wird und dass es keinen Widerspruch zu den kind-Port-Mappings gibt.

Beispiel:

```bash
kubectl port-forward svc/<service-name> 8080:80
```

Falls 8443 in Modul 01 verwendet werden soll, erkläre kurz, dass dies dem HTTPS-Port-Mapping des Clusters entspricht.

---

### Task 4: Kurzer Hinweis im Root-README auf kind.yaml

**Files:**
- Modify: `README.md`

**Interfaces:**
- Consumes: bestehende Modulübersicht im Root-README.
- Produces: Einzeilige Erwähnung des zentralen kind-Setups, damit Betreuende es schnell finden.

- [ ] **Step 1: Root-README öffnen und Modulübersicht prüfen**

Lies `README.md` und identifiziere eine Stelle im Abschnitt „Module“ oder direkt darunter, an der ein kurzer Hinweis auf `kind.yaml` sinnvoll ist.

- [ ] **Step 2: Hinweis auf kind-Setup ergänzen**

Füge einen kurzen Satz ein, z. B. unterhalb der Modul-Auflistung oder im Abschnitt „Voraussetzungen“:

```markdown
Im Repo-Root liegt eine `kind.yaml`, die ein lokales `kind`-Cluster namens `lab` mit zu unserer Umgebung passenden Zertifikats-Mounts und Port-Mappings (8080/8443) definiert. Die Einrichtung wird in Modul 01 beschrieben.
```

---

### Task 5: Manuelle Verifikation des Setups

**Files:**
- Read-only Nutzung von: `kind.yaml`, `01-grundlagen.md`, `README.md`.

**Interfaces:**
- Consumes: implementierte Änderungen.
- Produces: Bestätigung, dass ein Azubi das Setup mit den Anleitungen nachvollziehen kann.

- [ ] **Step 1: Dry-Run der Dokumentationsschritte im Kopf oder in Testumgebung**

Simuliere (oder führe in einer Test-WSL-Umgebung aus):

1. Repo klonen / in bestehendes Repo wechseln.
2. `kind create cluster --name lab --config kind.yaml` ausführen.
3. `kubectl get nodes` und `kubectl get pods -A` prüfen.
4. Beispiel-Port-Forward oder Podman-Demo aus Modul 01 nachvollziehen und prüfen, dass Port 8080/8443 logisch konsistent verwendet wird.

- [ ] **Step 2: Prüfen, ob irgendwo noch veraltete Namen/Konfiguration stehen**

Suche im Repo (mindestens in `01-grundlagen.md` und `README.md`) nach „azubi-lab“ und stelle sicher, dass keine veralteten Cluster-Namen oder nicht mehr gültigen kind-Befehle übrig sind.

- [ ] **Step 3: Dokumentiere eventuell offene Punkte**

Notiere in einem kurzen Kommentar (z. B. in einem internen Dokument oder als TODO im Plan), falls für spätere Arbeiten noch Registry-Hostnamen oder weitere Unternehmens-Details eingetragen werden müssen, die nicht Teil dieser Minimalmigration sind.
