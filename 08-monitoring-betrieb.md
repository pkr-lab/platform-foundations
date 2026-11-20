# Modul 08 – Monitoring & Betrieb

## Kurzbeschreibung

In diesem Modul lernst du, wie du den Zustand deines Clusters und deiner Anwendungen beobachtest. Du nutzt Kubernetes-Bordmittel, einen Monitoring-Stack mit Prometheus und Grafana sowie optional die Cluster-Oberfläche Headlamp, um Metriken, Logs und Events auszuwerten und Störungen zu analysieren.

## Lernziele

- Beobachtungs-Werkzeuge anwenden (`kubectl logs`, `kubectl describe`, `kubectl get events`, `kubectl top`)
- einen Monitoring-Stack (Prometheus/Grafana) im Lab-Cluster einsetzen
- ein Dashboard mit grundlegenden Metriken für `azubi-portal` erstellen
- die Wirkung von Ressourcen-Limits und Probes verstehen
- Störungen erkennen, analysieren und über GitOps beheben

## Voraussetzungen

- Modul 01–07 abgeschlossen
- `azubi-portal` wird von ArgoCD verwaltet

## Theorie (Kurzüberblick)

### Beobachtung in Kubernetes

Auch ohne sichtbaren Fehler kann eine Anwendung Probleme haben (z. B. hohe Latenz, Ressourcengrenzen). Wichtige Werkzeuge (siehe [Kubernetes Debugging](https://kubernetes.io/docs/tasks/debug/)):

- `kubectl logs` (mit `--previous` auch für abgestürzte Container)
- `kubectl describe`: Details zu Ressourcen (Events, Status, Config)
- `kubectl get events --sort-by=.lastTimestamp`: was ist zuletzt im Namespace passiert?
- `kubectl top`: CPU/Memory von Nodes und Pods (benötigt den Metrics Server)

### Probes

- **readinessProbe**: Ist der Pod bereit, Traffic zu bekommen? Wenn nein, nimmt der Service ihn aus dem Load-Balancing.
- **livenessProbe**: Lebt der Container noch? Wenn nein, startet Kubernetes ihn neu.

Das `azubi-portal`-Chart enthält bereits beide Probes.

### Monitoring-Stack

- [Prometheus](https://prometheus.io/): sammelt und speichert Metriken als Zeitreihen
- [Grafana](https://grafana.com/): visualisiert Metriken in Dashboards
- [Alertmanager](https://prometheus.io/docs/alerting/latest/alertmanager/): verschickt Alarme

Das Chart [`kube-prometheus-stack`](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack) bringt alles zusammen inklusive fertiger Dashboards mit.

## Aufgaben

### Aufgabe 1: Metrics Server bereitstellen

**Ziel:** `kubectl top` zum Laufen bringen.

1. Prüfe, ob `kubectl top nodes` funktioniert. In einem frischen kind-Cluster wird das scheitern.
2. Installiere den [Metrics Server](https://github.com/kubernetes-sigs/metrics-server). Im kind-Cluster haben die Kubelets keine offiziell signierten Zertifikate, deshalb braucht er den Parameter `--kubelet-insecure-tls` (nur im Lab!):

   ```bash
   helm repo update
   helm search repo artifactory/metrics-server --versions | head -n 5
   helm install metrics-server artifactory/metrics-server --version <chart-version> -n kube-system \
     --set 'args={--kubelet-insecure-tls}'
   ```

3. Warte etwa eine Minute und prüfe:

   ```bash
   kubectl top nodes
   kubectl top pods -A --sort-by=memory
   ```

### Aufgabe 2: Prometheus und Grafana installieren

**Ziel:** Einen Monitoring-Stack bereitstellen.

1. Installiere `kube-prometheus-stack` aus dem Artifactory in den Namespace `monitoring`. Das Chart bringt Images von quay.io, registry.k8s.io und Docker Hub mit – alle kommen über den Registry-Mirror:

   ```bash
   helm search repo artifactory/kube-prometheus-stack --versions | head -n 5
   helm install monitoring artifactory/kube-prometheus-stack --version <chart-version> -n monitoring --create-namespace
   kubectl get pods -n monitoring -w
   ```

2. Lies das Grafana-Passwort aus und öffne Grafana unter `http://localhost:9300` (Benutzer `admin`):

   ```bash
   kubectl get secret monitoring-grafana -n monitoring -o jsonpath='{.data.admin-password}' | base64 -d; echo
   kubectl port-forward svc/monitoring-grafana -n monitoring 9300:80
   ```

3. Sieh dir die mitgelieferten Dashboards an, z. B. „Kubernetes / Compute Resources / Namespace (Pods)“.

Tipp: Im Bonus von Modul 07 hast du gesehen, dass du den Stack auch als ArgoCD-Application installieren kannst – das ist der „GitOps-Weg“.

### Aufgabe 3: Dashboard für `azubi-portal` erstellen

**Ziel:** Grundlegende Metriken der eigenen App visualisieren.

1. Erstelle in Grafana ein neues Dashboard mit mindestens drei Panels für den Namespace `azubi-portal`, z. B.:

   | Panel | PromQL |
   | --- | --- |
   | CPU pro Pod | `sum by (pod) (rate(container_cpu_usage_seconds_total{namespace="azubi-portal", container!=""}[5m]))` |
   | Memory pro Pod | `sum by (pod) (container_memory_working_set_bytes{namespace="azubi-portal", container!=""})` |
   | Restarts | `sum by (pod) (kube_pod_container_status_restarts_total{namespace="azubi-portal"})` |

2. Erzeuge Last auf die App und beobachte die Metriken:

   ```bash
   for i in $(seq 1 5000); do curl -s -o /dev/null http://azubi-portal.localhost:8080; done
   ```

3. Exportiere das Dashboard als JSON und lege es in deinem GitOps-Repo ab (z. B. `gitops/cluster/dashboards/azubi-portal.json`).

### Aufgabe 4: Ressourcengrenzen-Experiment

**Ziel:** Verstehen, wie sich Limits auswirken.

1. Setze in `values-lab.yaml` sehr niedrige Limits und merge die Änderung per Merge Request. Die Requests musst du mit absenken: Kubernetes lehnt ein Deployment ab, dessen Requests größer als die Limits sind.

   ```yaml
   resources:
     requests:
       cpu: 5m
       memory: 4Mi
     limits:
       cpu: 5m
       memory: 8Mi
   ```

2. Beobachte mit `kubectl get pods -w`, `kubectl describe pod` und in Grafana, was passiert. Achte auf `OOMKilled`, `CrashLoopBackOff` und CPU-Throttling.
3. Dokumentiere, ab wann das Verhalten problematisch wird und wie du gegensteuern würdest. Setze sinnvolle Werte und merge erneut.

### Aufgabe 5: Fehlkonfiguration analysieren

**Ziel:** Logs, Events und Probes für die Fehlersuche nutzen.

Führe nacheinander je einen der folgenden Fehler per Git ein, finde die Ursache **nur mit Beobachtungs-Werkzeugen** und behebe ihn per `git revert`:

1. Ein Image-Tag, das es im Artifactory nicht gibt → welcher Status, welches Event?
2. `containerPort: 80`, obwohl dein Image auf 8080 lauscht → was melden die Probes? Was zeigt `kubectl get endpoints -n azubi-portal`?
3. Ein `imagePullSecrets`-Eintrag auf ein nicht existierendes Secret, z. B. `artifactory-pull-gibtesnicht` → welche Warnung erscheint in den Events, und hängt der Pull davon ab, ob euer Artifactory eine Anmeldung verlangt?

Notiere zu jedem Fehler: Symptom, verwendeter Befehl, Ursache, Lösung.

### Aufgabe 6 (optional): Headlamp als Cluster-Oberfläche

**Ziel:** Eine grafische Oberfläche für den Cluster kennenlernen.

[Headlamp](https://headlamp.dev/) ist eine Web-Oberfläche für Kubernetes. Die Datei [`kubernetes-headlamp.yaml`](./kubernetes-headlamp.yaml) im Repo-Root installiert sie (Details: [docs/Headlamp.md](./docs/Headlamp.md)).

> **Achtung:** Das Manifest gibt Headlamp über den ServiceAccount `headlamp-admin` **cluster-admin**-Rechte. Das ist nur im lokalen Lab vertretbar – in echten Clustern bekommt jeder Benutzer nur die Rechte, die er braucht.

```bash
kubectl apply -f kubernetes-headlamp.yaml
kubectl -n kube-system get secret headlamp-admin -o jsonpath='{.data.token}' | base64 -d; echo
kubectl port-forward -n kube-system svc/headlamp 9005:80
```

Öffne `http://localhost:9005`, melde dich mit dem Token an und suche dein `azubi-portal` in der Oberfläche. Vergleiche: Welche Informationen findest du schneller in Headlamp, welche schneller mit `kubectl`?

### Bonus-Aufgaben (für Fortgeschrittene)

- **Alerts:** Lege eine `PrometheusRule` mit zwei bis drei Alerts für `azubi-portal` an (Label `release: monitoring`) und prüfe in der Prometheus-Oberfläche unter „Alerts“, ob sie geladen wurden. Löse einen Alert absichtlich aus.
- **Autoscaling:** Lege einen `HorizontalPodAutoscaler` für `azubi-portal` an (z. B. 2–5 Replikas bei 50 % CPU) und erzeuge Last. Warum funktioniert das erst mit dem Metrics Server, und warum muss `replicaCount` dafür aus der GitOps-Steuerung herausgenommen werden?
- **Dashboard per GitOps:** Lege dein Dashboard-JSON in eine ConfigMap im Namespace `monitoring` mit dem Label `grafana_dashboard: "1"`. Der Grafana-Sidecar aus `kube-prometheus-stack` lädt es dann automatisch – ohne Klick im UI.

## Du bist fertig, wenn …

- [ ] `kubectl top pods -A` Werte anzeigt
- [ ] du in Grafana ein eigenes Dashboard mit drei Panels für `azubi-portal` hast
- [ ] du einen `OOMKilled` beobachtet und erklärt hast
- [ ] du alle drei Fehler aus Aufgabe 5 mit Symptom, Ursache und Lösung dokumentiert hast

## Verständnisfragen

1. Was ist der Unterschied zwischen einer readiness- und einer livenessProbe?
2. Was passiert, wenn ein Container sein Memory-Limit überschreitet? Und beim CPU-Limit?
3. Warum gehört `--kubelet-insecure-tls` nicht in einen Produktiv-Cluster?
4. Welche zwei bis drei Alerts wären für `azubi-portal` in einem echten System sinnvoll?

## Häufige Stolperfallen & Tipps

- `kubectl top` meldet `Metrics API not available`: Der Metrics Server braucht nach dem Start etwa eine Minute. Fehlt `--kubelet-insecure-tls`, bleibt er dauerhaft `0/1 READY`.
- Direkt nach der Installation feuern Alerts wie `KubeControllerManagerDown`, `KubeSchedulerDown` oder `etcdInsufficientMembers`: In kind lauschen diese Komponenten nur auf `127.0.0.1`, Prometheus erreicht sie nicht. Im Lab ist das harmlos.
- Pods aus `kube-prometheus-stack` hängen in `ImagePullBackOff`: Die Events zeigen, welche Registry fehlt. Prüfe den Registry-Mirror (Modul 01, Aufgabe 3).
- WSL wird langsam oder Pods werden `Evicted`: Der Monitoring-Stack braucht mehrere GB RAM. Erhöhe in Windows in `%UserProfile%\.wslconfig` unter `[wsl2]` den Wert `memory` (z. B. `memory=8GB`) und starte WSL neu.
- Das Deployment wird mit `must be less than or equal to memory limit` abgelehnt: Requests und Limits passen nicht zusammen (Aufgabe 4).

## Aufräumen

Der Monitoring-Stack verbraucht viel Speicher. Wenn dein Rechner langsam wird:

```bash
helm uninstall monitoring -n monitoring
kubectl delete namespace monitoring
kubectl delete -f kubernetes-headlamp.yaml
```

## Weiterführend

- [Alertmanager](https://prometheus.io/docs/alerting/latest/alertmanager/) und `PrometheusRule`-Ressourcen
- [PromQL-Grundlagen](https://prometheus.io/docs/prometheus/latest/querying/basics/)

Eine Musterlösung findest du unter [solutions/modul-08](./solutions/modul-08/).
