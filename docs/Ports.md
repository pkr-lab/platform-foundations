# Port-Übersicht

Im Lab laufen viele Dienste gleichzeitig. Damit sich keine Ports überschneiden, gilt folgende Konvention:

| Host-Port | Verwendet von | Wie |
| --- | --- | --- |
| 8080 | kind-Node Port 80 → Traefik (HTTP-Ingress) | `extraPortMappings` in `kind.yaml` |
| 8443 | kind-Node Port 443 → Traefik (HTTPS-Ingress) | `extraPortMappings` in `kind.yaml` |
| 8081 | Podman-Testcontainer aus Modul 01 | `podman run -p 8081:80` |
| 9080 | `azubi-portal`, Demo-Apps | `kubectl port-forward … 9080:<port>` |
| 9443 | ArgoCD-UI | `kubectl port-forward svc/argocd-server -n argocd 9443:443` |
| 9300 | Grafana | `kubectl port-forward svc/monitoring-grafana -n monitoring 9300:80` |
| 9005 | Headlamp | `kubectl port-forward -n kube-system svc/headlamp 9005:80` |

Die Ports 8080 und 8443 sind belegt, solange der kind-Cluster läuft. Ein `kubectl port-forward` auf diese Ports scheitert mit `address already in use`.

## Hostnamen über den Ingress

| URL | Ziel |
| --- | --- |
| `http://azubi-portal.localhost:8080` | Service `azubi-portal` im Namespace `azubi-portal` |

Namen unter `*.localhost` werden von modernen Browsern automatisch auf `127.0.0.1` aufgelöst. Mit `curl` funktioniert alternativ `curl -H 'Host: azubi-portal.localhost' http://localhost:8080`.
