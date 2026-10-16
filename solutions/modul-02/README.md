# Lösung Modul 02

| Datei | Inhalt |
| --- | --- |
| [azubi-portal.yaml](./azubi-portal.yaml) | Endstand von Aufgabe 1–4 und 6: Namespace mit Pod-Security-Labels, ConfigMap, Secret, RBAC, gehärtetes Deployment, Service, Ingress |
| [np-test.yaml](./np-test.yaml) | Aufgabe 5: Web-App mit NetworkPolicy |
| [traefik-values.yaml](./traefik-values.yaml) | Aufgabe 6: Werte für den Ingress-Controller Traefik |

Das Secret steht hier nur zu Übungszwecken im Klartext in der Datei. In einem echten Repo gehört es dort nicht hin (siehe Modul 05).

## Erwartete Ergebnisse

- `kubectl auth can-i list pods …` → `yes`, `delete pods` → `no`, `get secrets` → `no`
- Mit dem offiziellen `nginx`-Image und `runAsNonRoot: true` meldet der Pod `CreateContainerConfigError` („container has runAsNonRoot and image will run as root“).
- Nach der NetworkPolicy antwortet `webapp` nur noch dem Pod `client`. `fremd` läuft in einen Timeout, bis er das Label `role=client` bekommt.

## Traefik-Werte erklärt

- `ports.web.hostPort: 80` / `ports.websecure.hostPort: 443`: Traefik belegt direkt die Ports 80/443 des kind-Nodes. Diese leitet `kind.yaml` auf 8080/8443 des Hosts weiter.
- `nodeSelector` und `tolerations`: Traefik läuft auf dem Node mit `ingress-ready=true`, auch wenn er die Rolle control-plane hat.
- `service.type: ClusterIP`: ein LoadBalancer-Service ist durch die hostPorts nicht nötig.
- `ingressClass.isDefaultClass`: Ingress-Objekte ohne `ingressClassName` werden ebenfalls von Traefik bedient.

## Antworten auf die Verständnisfragen

1. base64 ist eine Kodierung, keine Verschlüsselung. Jeder mit Lesezugriff auf das Repo kann den Wert zurückwandeln, und die Git-Historie vergisst nichts.
2. Eine `Role` gilt in einem Namespace, eine `ClusterRole` clusterweit oder für clusterweite Ressourcen wie Nodes.
3. Bricht ein Angreifer aus der Anwendung aus, hat er im Container keine root-Rechte. Das erschwert Ausbrüche auf den Host deutlich.
4. Sobald eine Policy einen Pod für `Ingress` auswählt, ist nur noch der explizit erlaubte eingehende Traffic zugelassen; alles andere wird verworfen.
5. Der Controller ist die laufende Software (Reverse Proxy), die den Traffic annimmt. Das Ingress-Objekt ist die Konfiguration (Regeln), die der Controller liest.
