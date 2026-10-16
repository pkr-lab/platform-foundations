# Lösung Modul 07

## Erwartete Fehlerbilder aus Aufgabe 5

| Fehler | Symptom | Befehl | Ursache |
| --- | --- | --- | --- |
| ungültiges Image-Tag | `ErrImagePull` / `ImagePullBackOff` | `kubectl describe pod` → Events | Image existiert nicht in der Registry |
| `containerPort: 8080` bei normalem Nginx | Pods `Running`, aber `0/1 READY`, Restarts durch livenessProbe | `kubectl describe pod`, `kubectl get endpoints -n azubi-portal` (leer) | Nginx lauscht auf 80, Probes und Service zeigen auf 8080 |
| fehlendes Pull-Secret | `ImagePullBackOff`, Event mit `unauthorized` bzw. Hinweis auf fehlendes Secret | `kubectl describe pod`, `kubectl get events -n azubi-portal` | Secret existiert nicht im Namespace |

## Ressourcengrenzen

- Memory über dem Limit → der Container wird vom Kernel beendet (`OOMKilled`) und neu gestartet, bei Wiederholung `CrashLoopBackOff`.
- CPU über dem Limit → kein Absturz, sondern Drosselung (Throttling). Die App wird langsam.

## Alerts

Beispiel-Alerts als `PrometheusRule`: [azubi-portal-alerts.yaml](./azubi-portal-alerts.yaml). Das Label `release: monitoring` sorgt dafür, dass der Prometheus aus `kube-prometheus-stack` die Regeln einliest.

## Antworten auf die Verständnisfragen

1. Die readinessProbe entscheidet, ob ein Pod Traffic bekommt. Die livenessProbe entscheidet, ob der Container neu gestartet wird.
2. Memory: `OOMKilled` und Neustart. CPU: Throttling, kein Neustart.
3. Der Metrics Server prüft dann die Zertifikate der Kubelets nicht. Ein Angreifer könnte sich als Kubelet ausgeben (Man-in-the-Middle).
4. Zum Beispiel: keine verfügbaren Pods, häufige Restarts, Memory nahe am Limit, hohe Fehlerrate am Ingress.
