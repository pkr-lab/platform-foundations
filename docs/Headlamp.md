# Headlamp (`kubernetes-headlamp.yaml`)

Die Datei [`kubernetes-headlamp.yaml`](../kubernetes-headlamp.yaml) installiert die Web-Oberfläche [Headlamp](https://headlamp.dev/) im Namespace `kube-system`. Sie wird optional in Modul 07 verwendet.

## Ressourcen

| Ressource | Name | Zweck |
| --- | --- | --- |
| ServiceAccount | `headlamp-admin` | Identität, mit der Headlamp und der Benutzer auf die API zugreifen |
| ClusterRoleBinding | `headlamp-admin` | gibt dem ServiceAccount die ClusterRole `cluster-admin` |
| Secret (`service-account-token`) | `headlamp-admin` | langlebiges Token für den Login im UI |
| Service | `headlamp` | Port 80 → Container-Port 4466 |
| Deployment | `headlamp` | ein Pod mit `ghcr.io/headlamp-k8s/headlamp`, fester Versions-Tag, läuft mit `serviceAccountName: headlamp-admin` |

## Benutzung

```bash
kubectl apply -f kubernetes-headlamp.yaml
kubectl -n kube-system get secret headlamp-admin -o jsonpath='{.data.token}' | base64 -d; echo
kubectl port-forward -n kube-system svc/headlamp 9005:80
```

Danach `http://localhost:9005` öffnen und mit dem Token anmelden. Alternativ erzeugt `kubectl create token headlamp-admin -n kube-system` ein kurzlebiges Token.

## Sicherheit

`cluster-admin` erlaubt alles im Cluster. Das ist nur in einem lokalen Lab-Cluster vertretbar. In echten Umgebungen erhält jeder Benutzer eine eigene Identität mit minimalen Rechten, und langlebige Tokens werden vermieden.

## Version aktualisieren

Der Image-Tag ist bewusst fest gesetzt. Neue Versionen stehen auf der [Release-Seite](https://github.com/kubernetes-sigs/headlamp/releases). Zum Aktualisieren den Tag im Deployment anpassen und die Datei erneut anwenden.

## Entfernen

```bash
kubectl delete -f kubernetes-headlamp.yaml
```
