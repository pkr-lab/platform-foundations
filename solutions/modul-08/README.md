# Lösung Modul 08

## Erwartete Fehlerbilder aus Aufgabe 5

| Fehler | Symptom | Befehl | Ursache |
| --- | --- | --- | --- |
| Image-Tag, das es nicht gibt | `ErrImagePull` / `ImagePullBackOff`, Event mit `manifest unknown` bzw. `not found` | `kubectl describe pod` → Events | Image existiert nicht im Artifactory |
| `containerPort: 80` bei `nginx-unprivileged` bzw. eigenem Image | Pods `Running`, aber `0/1 READY`, Restarts durch livenessProbe | `kubectl describe pod`, `kubectl get endpoints -n azubi-portal` (leer) | Nginx lauscht auf 8080, Probes und Service zeigen auf 80 |
| Pull-Secret existiert nicht | Warnung `FailedToRetrieveImagePullSecret`; verlangt das Artifactory eine Anmeldung, zusätzlich `ImagePullBackOff` mit `401 Unauthorized` | `kubectl get events -n azubi-portal`, `kubectl describe pod` | Secret existiert nicht im Namespace |

Ist das Artifactory ohne Anmeldung lesbar, startet der Pod in Fall 3 trotzdem – nur die Warnung bleibt. Genau deshalb lohnt sich ein Blick in die Events, auch wenn alles läuft.

## Ressourcen-Experiment

Mit Requests 5m/4Mi und Limits 5m/8Mi startet Nginx meist gar nicht erst sauber: Der Container wird beim Start oder unter Last mit `OOMKilled` beendet und landet in `CrashLoopBackOff`. Sinnvolle Werte für das Lab sind die Chart-Standardwerte (Requests 10m/32Mi, Limits 100m/64Mi).

## Ressourcengrenzen

- Memory über dem Limit → der Container wird vom Kernel beendet (`OOMKilled`) und neu gestartet, bei Wiederholung `CrashLoopBackOff`.
- CPU über dem Limit → kein Absturz, sondern Drosselung (Throttling). Die App wird langsam.

## Installation

```bash
helm install metrics-server artifactory/metrics-server --version <chart-version> -n kube-system --set 'args={--kubelet-insecure-tls}'
helm install monitoring artifactory/kube-prometheus-stack --version <chart-version> -n monitoring --create-namespace
```

## Bonus: Alerts und Autoscaling

Beispiel-Alerts als `PrometheusRule`: [azubi-portal-alerts.yaml](./azubi-portal-alerts.yaml). Das Label `release: monitoring` sorgt dafür, dass der Prometheus aus `kube-prometheus-stack` die Regeln einliest.

```bash
kubectl apply -f azubi-portal-alerts.yaml
kubectl autoscale deployment azubi-portal -n azubi-portal --min=2 --max=5 --cpu-percent=50
kubectl get hpa -n azubi-portal -w
```

Der HPA braucht CPU-Werte vom Metrics Server. Solange ArgoCD mit `selfHeal` das Feld `replicas` aus Git durchsetzt, setzt es die Änderungen des HPA zurück. Lösung: `replicas` im Chart weglassen, wenn ein HPA aktiv ist, oder in der Application `ignoreDifferences` für `/spec/replicas` setzen.

## Antworten auf die Verständnisfragen

1. Die readinessProbe entscheidet, ob ein Pod Traffic bekommt. Die livenessProbe entscheidet, ob der Container neu gestartet wird.
2. Memory: `OOMKilled` und Neustart. CPU: Throttling, kein Neustart.
3. Der Metrics Server prüft dann die Zertifikate der Kubelets nicht. Ein Angreifer könnte sich als Kubelet ausgeben (Man-in-the-Middle).
4. Zum Beispiel: keine verfügbaren Pods, häufige Restarts, Memory nahe am Limit, hohe Fehlerrate am Ingress.
