# Modul 06 – Monitoring & Betrieb

## Kurzbeschreibung

In diesem Modul lernst du, wie du den Zustand deines Clusters und deiner Anwendungen beobachtest. Du nutzt grundlegende Kubernetes-Werkzeuge sowie einen einfachen Monitoring-Stack, um Metriken und Logs auszuwerten und einfache Störungsszenarien zu analysieren.

## Lernziele

- grundlegende Beobachtungs-Werkzeuge anwenden (`kubectl logs`, `kubectl describe`, `kubectl top`)
- einen einfachen Monitoring-Stack (z. B. Prometheus/Grafana oder vergleichbar) im Lab-Cluster einsetzen
- ein Dashboard mit grundlegenden Metriken für eine Beispiel-App erstellen
- einfache Störungen erkennen, analysieren und Gegenmaßnahmen ableiten

## Voraussetzungen

- Modul 01–05 abgeschlossen

## Theorie (Kurzüberblick)

### Beobachtung in Kubernetes

Ohne sichtbaren Fehler kann eine Anwendung trotzdem Probleme haben (z. B. hohe Latenz, Ressourcengrenzen). Wichtige Werkzeuge (siehe auch [Kubernetes Debugging & Monitoring](https://kubernetes.io/docs/tasks/debug/)):

- `kubectl logs`: Container-Logs ansehen
- `kubectl describe`: Details zu Ressourcen (Events, Status, Config)
- `kubectl top`: Ressourcenverbrauch (CPU/Memory) von Nodes und Pods anzeigen (vorausgesetzt, Metrics Server ist vorhanden)

### Monitoring-Stack (Beispiel Prometheus/Grafana)

Ein Monitoring-Stack sammelt Metriken und visualisiert sie. Typische Komponenten:

- [Prometheus](https://prometheus.io/): Sammlung und Speicherung von Metriken
- [Grafana](https://grafana.com/): Visualisierung in Dashboards

## Aufgaben

### Aufgabe 1: Metrics Server oder Monitoring-Stack bereitstellen

**Ziel:** Grundlage für Metriken schaffen.

1. Prüfe, ob `kubectl top nodes` und `kubectl top pods` in deinem Cluster funktionieren.
2. Falls nicht, installiere entweder den Kubernetes [Metrics Server](https://kubernetes.io/docs/tasks/debug/debug-cluster/resource-metrics-pipeline/) oder einen einfachen Monitoring-Stack, der diese Funktionalität mitbringt (z. B. ein Tutorial-Setup für Prometheus/Grafana).
3. Verifiziere, dass du CPU- und Memory-Werte für Pods/Nodes sehen kannst.

Beispiel:

```bash
kubectl top nodes
kubectl top pods -A
```

Beispiel für einen einfachen Monitoring-Stack mit Helm (optional, wenn du Prometheus/Grafana nutzen möchtest):

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install monitoring prometheus-community/kube-prometheus-stack -n monitoring --create-namespace
```

### Aufgabe 2: Einfaches Dashboard für deine App erstellen

**Ziel:** Grundlegende Metriken einer Beispiel-App visualisieren.

1. Wähle eine App aus vorherigen Modulen (z. B. deine `webapp`).
2. Identifiziere Metriken, die für dich interessant sind (z. B. CPU-Usage, Memory-Usage, Pod-Restarts).
3. Erstelle in Grafana (oder einem anderen Tool) ein Dashboard mit mindestens 2–3 Panels, die diese Metriken zeigen.
4. Erzeuge kurz Last auf deiner App (z. B. via `curl` in einer Schleife) und beobachte die Metriken.

### Aufgabe 3: Ressourcengrenzen-Experiment

**Ziel:** Verstehen, wie Ressourcengrenzen sich auswirken.

1. Passe das Deployment deiner App so an, dass CPU- oder Memory-Limits relativ niedrig gesetzt werden.
2. Erzeuge Last auf die App und beobachte im Monitoring sowie in `kubectl describe pod`, was passiert (z. B. Throttling, OOMKills, Restarts).
3. Dokumentiere kurz, ab wann das Verhalten problematisch wird und wie du gegensteuern würdest (z. B. Limits erhöhen, App optimieren). Achte in `kubectl describe pod` insbesondere auf Events wie `OOMKilled` oder `BackOff`.

### Aufgabe 4: Fehlkonfiguration analysieren

**Ziel:** Logs und Events für Fehlersuche nutzen.

1. Führe eine absichtliche Fehlkonfiguration ein (z. B. falsche URL in einer Umgebungsvariable, fehlende ConfigMap, falscher Port).
2. Roll die Änderung über GitOps/Helm aus.
3. Nutze `kubectl logs` und `kubectl describe pod`/`kubectl describe deploy`, um die Ursache zu identifizieren.
4. Korrigiere die Konfiguration und verifiziere, dass das Problem behoben ist.

## Weiterführend

- Informiere dich über Alerting-Konzepte (z. B. Alertmanager) und überlege, welche einfachen Alerts in einem echten System sinnvoll wären.
- Experimentiere mit weiteren Dashboards (z. B. Node-Auslastung, etcd-Metriken, wenn verfügbar).
