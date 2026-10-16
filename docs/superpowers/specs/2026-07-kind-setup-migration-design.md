# Design: Migration kind-Setup aus altem Azubi-Lab ins neue Lab

## 1. Ziel

Altes kind-Setup aus `zcpm-azubi-lab` in das neue, modulare Lab im Repo-Root integrieren.

Wichtig:

- Unternehmensrelevante Einstellungen (Zertifikate, Registry-Zugriff) bleiben erhalten.
- Azubi arbeitet im neuen Lab mit demselben technischen Setup wie im alten Lab.
- Dokumentation bleibt auf Azubi-Niveau (Schritt-für-Schritt), aber knapp.

## 2. Rahmenbedingungen

- Arbeitsumgebung: Windows-Client mit WSL (Ubuntu) und Podman.
- Kubernetes-Lab-Cluster: lokales kind-Cluster in WSL.
- Clustername: `lab` (einheitlich in allen Modulen und Beispielen).
- Container-Laufzeit: Podman/Docker-kompatibel, kind läuft in Container-Backend.
- Firmenvorgaben:
  - Firmen-CA / TLS-Inspection relevant.
  - Interne Container-Registry soll real genutzt werden (konkreter Hostname im Lab).
- kind wird im neuen Lab nicht als „Blackbox“ behandelt, sondern im Modul 01 erklärt.

## 3. Technisches kind-Setup

### 3.1 kind-Konfiguration

Neue Datei im Repo-Root:

- Pfad: `./kind.yaml`
- Inhalt basiert auf altem `zcpm-azubi-lab/03-setup-kind/kind.yaml` und wird übernommen:

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

Eigenschaften:

- Port-Mappings:
  - `http` im Cluster → Host-Port `8080`.
  - `https` im Cluster → Host-Port `8443`.
- Zertifikats-Mounts (verbindliche Vorgabe):
  - Firmen-CA und Containerd-CAs aus dem Host stehen im Cluster zur Verfügung.
  - Voraussetzung für Zugriff auf interne Container-Registry.

### 3.2 Cluster-Erstellung

Standard-Befehl im ganzen Lab:

```bash
kind create cluster --name lab --config kind.yaml
```

Weitere Standardbefehle:

- Cluster prüfen: `kind get clusters`
- Cluster löschen (nur dokumentiert, nicht als Standard-Schritt):

  ```bash
  kind delete cluster --name lab
  ```

## 4. Integration ins neue Lab

### 4.1 Modul 01 – kind-Unterkapitel

Datei: `01-grundlagen.md`

Erweiterung um Unterabschnitt, z. B.: `### Lokales kind-Cluster (Unternehmens-Setup)`.

Inhalt (Schritt-für-Schritt, Azubi-freundlich):

- Kurz erklären, dass `kind` im Unternehmen mit zusätzlicher Zertifikats- und Port-Konfiguration genutzt wird.
- Hinweis, dass `kind.yaml` im Repo-Root liegt und bereits Firmenvorgaben abbildet (Ports, Zertifikate).
- Konkrete Schritte:
  1. In Repo-Root wechseln.
  2. `kind create cluster --name lab --config kind.yaml` ausführen.
  3. Mit `kubectl get nodes` und `kubectl get pods -A` prüfen, ob Cluster läuft.
  4. Hinweis auf Ports `8080` und `8443` als Standard für spätere Übungen.
- Hinweis, dass Zertifikats-Mounts nötig sind, damit Cluster mit interner Registry und Firmen-CA funktioniert.

Formulierung bleibt auf dem Niveau des alten README (`zcpm-azubi-lab/03-setup-kind/README.md`), aber an neue Struktur angepasst.

### 4.2 Nutzung der Port-Mappings

Grundsatz: `8080` und `8443` werden im gesamten Lab als Standard-Host-Ports verwendet.

- Modul 01: erste Demo-App/Port-Forward-Beispiele können bereits auf `8080` referenzieren.
- Spätere Module (Deployments, GitOps, ggf. Dashboards):
  - Web-Apps/Ingress-Ressourcen nutzen konsequent `8080` für HTTP.
  - `8443` kann für HTTPS-artige Beispiele genutzt werden (z. B. ArgoCD-UI, wenn gewünscht).

Alle Beispiele und Aufgaben nutzen diese Ports konsistent, damit Azubi nicht zwischen unterschiedlichen Port-Schemata wechseln muss.

### 4.3 Firmen-Registry im Lab

Ziel: Azubi zieht Images aus der internen Firmen-Registry in den `lab`-Cluster.

Design-Entscheidungen:

- Azubi nutzt **nur Pull-Workflows** aus der Registry (kein Build/Push-Training im Lab).
- Beispiele in YAML/Helm verwenden **konkreten Registry-Hostname** aus der Firma (wird im nächsten Schritt bei der Implementierung eingesetzt).
- Hinweise in den Modulen:
  - Kurze Erklärung, warum Firmen-Registry existiert (Sicherheit, Kontrolle, Performance).
  - Hinweis, dass Zertifikate im `kind`-Cluster dafür bereits vorbereitet sind.

Konkrete Einbindung erfolgt in den jeweiligen Modul-Dateien (z. B. Modul 02/03), nicht in dieser Design-Datei.

## 5. Headlamp-Integration

Headlamp aus dem alten Lab bleibt Teil des neuen Labs, aber nicht als Pflichtbestandteil von Modul 01.

Design:

- Headlamp wird als **eigenes Untermodul in einem späteren Modul** eingebaut, z. B. in Monitoring/Betrieb oder als eigener Optional-Block.
- Inhalt lehnt sich an altes `03-setup-kind/README.md` an:
  - ServiceAccount `headlamp-admin` mit `cluster-admin`-ClusterRoleBinding.
  - Apply des offiziellen Headlamp-Manifests.
  - Token-Erzeugung per `kubectl create token`.
  - Port-Forward `kubectl port-forward -n kube-system service/headlamp 9005:80`.
- Headlamp wird klar als **optional** markiert, um Security-Gefühl (ClusterAdmin) und Zusatz-Aufwand transparent zu machen.

Details (konkrete Platzierung in welchem Modul) werden bei der Ausarbeitung der Module umgesetzt.

## 6. Dokumentationsanpassungen

Geplante Änderungen im Repo:

1. Neue Datei `kind.yaml` im Repo-Root mit oben definierter Konfiguration.
2. Erweiterung von `01-grundlagen.md` um ein eigenes Unterkapitel für das Unternehmens-kind-Setup:
   - Schritt-für-Schritt-Anleitung (Cluster erstellen, prüfen, Standard-Ports).
   - Kurzbegründung für Zertifikats-Mounts und Port-Mappings.
3. In späteren Modulen (z. B. Deployments, Helm, GitOps) konsistente Verwendung von:
   - Clustername `lab`.
   - Host-Ports `8080`/`8443` in Beispielen (Ingress, Services, UIs).
   - Interner Firmen-Registry-URL in Beispiel-Images.
4. Headlamp-Untermodul in einem späteren Modul (optional), basierend auf altem Lab.

## 7. Offene Punkte für Implementierung

- Konkreter Hostname der Firmen-Registry muss beim Schreiben der Module eingesetzt werden.
- Genaue Modul-Position für Headlamp-Untermodul (z. B. in Monitoring/Betrieb) wird beim Modul-Finetuning entschieden.
- Prüfen, ob es im Unternehmen zusätzliche Vorgaben für kind (z. B. Proxy-Settings, weitere Mounts) gibt, die in `kind.yaml` ergänzt werden müssen.
