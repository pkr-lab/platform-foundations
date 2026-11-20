# Lösung Modul 05

| Datei | Inhalt |
| --- | --- |
| [Containerfile](./Containerfile) | Endstand mit Multi-Stage-Build und Build-Argument `APP_VERSION` (Aufgabe 4) |
| [index.html](./index.html) | Startseite mit Platzhalter `__VERSION__` |
| [containerignore](./containerignore) | im Arbeitsordner als `.containerignore` ablegen |
| [values-lab.yaml](./values-lab.yaml) | Werte für das Chart mit eigenem Image (Aufgabe 6) |

## Einfaches Containerfile (Aufgabe 1)

```dockerfile
FROM <artifactory-host>/<docker-remote-repo>/nginxinc/nginx-unprivileged:1.28.0
COPY index.html /usr/share/nginx/html/index.html
EXPOSE 8080
```

## Bauen, prüfen, pushen

```bash
cd ~/k8s-lab/azubi-portal-image
podman build --build-arg APP_VERSION=1.0.0 -t azubi-portal:1.0.0 .
podman history localhost/azubi-portal:1.0.0
podman inspect --format '{{.Config.User}}' localhost/azubi-portal:1.0.0
podman run --rm localhost/azubi-portal:1.0.0 id
podman tag localhost/azubi-portal:1.0.0 <artifactory-host>/<docker-local-repo>/azubi-portal:1.0.0
podman push <artifactory-host>/<docker-local-repo>/azubi-portal:1.0.0
```

Erwartet: `podman inspect` liefert `101`, `id` zeigt `uid=101(nginx)`. Das offizielle `nginx`-Image liefert einen leeren Benutzer, startet also als root.

## Neue Version ausrollen

```bash
podman build --build-arg APP_VERSION=1.0.1 -t azubi-portal:1.0.1 .
podman tag localhost/azubi-portal:1.0.1 <artifactory-host>/<docker-local-repo>/azubi-portal:1.0.1
podman push <artifactory-host>/<docker-local-repo>/azubi-portal:1.0.1
cd ~/k8s-lab/azubi-portal-chart
helm upgrade azubi-portal . -n azubi-portal -f values-lab.yaml
kubectl rollout status deploy/azubi-portal -n azubi-portal
kubectl rollout history deploy/azubi-portal -n azubi-portal
```

## Variante B ohne Push

```bash
podman save -o ~/k8s-lab/azubi-portal-1.0.0.tar localhost/azubi-portal:1.0.0
kind load image-archive ~/k8s-lab/azubi-portal-1.0.0.tar --name lab
```

```yaml
image:
  repository: localhost/azubi-portal
  tag: "1.0.0"
  pullPolicy: Never
htmlFromConfigMap: false
```

## Layer und Cache

- `podman history` zeigt oben die eigenen Layer (`COPY …`), darunter die des Basis-Images.
- Ohne Änderung kommen alle Schritte aus dem Cache.
- Nach einer Änderung an `index.html` kommt `FROM` weiter aus dem Cache, `COPY` und alles danach werden neu gebaut.
- Im Multi-Stage-Build tauchen die Alpine-Layer im fertigen Image nicht auf; nur die kopierte `index.html` landet in einem neuen Layer.

## Antworten auf die Verständnisfragen

1. Das `Containerfile` ist der Bauplan, das Image das gebaute, unveränderliche Ergebnis, der Container eine laufende Instanz des Images.
2. Podman nutzt den Cache nur bis zur ersten geänderten Anweisung. Alles danach wird neu gebaut. Selten geänderte Schritte gehören deshalb nach oben.
3. Läuft der Prozess als root und wird die Anwendung angegriffen, hat der Angreifer im Container alle Rechte. Kubernetes prüft `runAsNonRoot` anhand der User-ID im Image; bei einem Namen wie `nginx` kann es nicht sicher entscheiden und verweigert den Start.
4. `EXPOSE` dokumentiert den Port der Anwendung. Es öffnet keinen Port und veröffentlicht nichts – das passiert mit `podman run -p` bzw. mit einem Kubernetes-Service.
5. Werkzeuge, die nur zum Bauen gebraucht werden, landen nicht im fertigen Image. Es wird kleiner und bietet weniger Angriffsfläche.
6. Eine Version soll immer denselben Inhalt haben. Sonst weiß niemand, was wirklich läuft, Kubernetes lädt das Image wegen `IfNotPresent` nicht neu, und ein Rollback auf `1.0.0` bringt nicht den alten Stand zurück.
7. Ein Push legt das Image zentral und versioniert im Artifactory ab, jeder berechtigte Cluster kann es laden. `kind load` kopiert das Image nur in den lokalen kind-Node – das gibt es in keinem echten Cluster.
