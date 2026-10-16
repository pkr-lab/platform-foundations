# Modul 02 – Manuelle Deployments & Basis-Security

## Kurzbeschreibung

In diesem Modul vertiefst du deine Kubernetes-Grundlagen. Du beschreibst Anwendungen als YAML-Deployments und Services, arbeitest mit ConfigMaps und Secrets und lernst erste Security-Konzepte wie RBAC und NetworkPolicies kennen.

## Lernziele

- Deployments und Services per YAML definieren und ausrollen
- ConfigMaps und Secrets erstellen und in Pods verwenden
- grundlegende RBAC-Konzepte verstehen (ServiceAccount, Role, RoleBinding)
- eine einfache NetworkPolicy entwerfen und deren Wirkung überprüfen

## Voraussetzungen

- Modul 01 abgeschlossen (kind-Cluster läuft, `kubectl` funktioniert)

## Theorie (Kurzüberblick)

### Deployments und Services

Ein [Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) verwaltet eine Gruppe identischer Pods. Es sorgt dafür, dass die gewünschte Anzahl an Replikas läuft und dass Rollouts/Updates kontrolliert stattfinden.

Ein [Service](https://kubernetes.io/docs/concepts/services-networking/service/) stellt eine stabile Netzwerkschnittstelle vor eine Gruppe von Pods. Er löst u. a. das Problem, dass Pod-IPs sich ändern können. Typische Service-Typen sind `ClusterIP` (Standard, nur im Cluster erreichbar) und `NodePort` (Port auf den Nodes öffnen).

### ConfigMaps und Secrets

[ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/) speichern nicht-sensible Konfiguration (z. B. URLs, Feature-Flags). [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/) sind für sensible Daten wie Passwörter oder Tokens gedacht. Beide können als Umgebungsvariablen oder als Dateien in Containern zur Verfügung gestellt werden.

### RBAC (Role-Based Access Control)

Mit [RBAC](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) steuerst du, welcher Nutzer/ServiceAccount welche Aktionen auf welchen Ressourcen ausführen darf. Wichtige Objekte:

- `ServiceAccount`: technische Identität für Pods
- `Role` / `ClusterRole`: definieren, welche Aktionen erlaubt sind (z. B. `get`, `list`, `watch` auf `pods`)
- `RoleBinding` / `ClusterRoleBinding`: verknüpfen Rollen mit Benutzern oder ServiceAccounts

### NetworkPolicies

[NetworkPolicies](https://kubernetes.io/docs/concepts/services-networking/network-policies/) steuern, welcher Traffic zwischen Pods erlaubt ist. Standardmäßig ist in vielen Clustern aller Pod-zu-Pod-Traffic erlaubt. Mit NetworkPolicies kannst du den Traffic einschränken (z. B. nur innerhalb eines Namespaces oder von bestimmten Labels).

Wichtig: Ob NetworkPolicies tatsächlich durchgesetzt werden, hängt vom verwendeten Netzwerk-Plugin (CNI) ab. Im Standard-kind-Cluster werden viele Policies nicht ausgewertet. Du kannst die Ressourcen in diesem Modul daher als Syntax- und Konzeptübung betrachten; für echte Tests brauchst du einen Cluster mit CNI, das NetworkPolicies unterstützt (z. B. Calico oder Cilium).

## Aufgaben

### Aufgabe 1: `azubi-portal` als Deployment und Service beschreiben

**Ziel:** Die Beispiel-App `azubi-portal` mit Deployment und Service im Cluster bereitstellen.

1. Lege einen Namespace `azubi-portal` an:

   ```bash
   kubectl create namespace azubi-portal
   ```

2. Erstelle eine YAML-Datei (z. B. `azubi-portal.yaml`), die mindestens folgendes Grundgerüst enthält und ergänze fehlende Teile nach Bedarf:

   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: azubi-portal
     namespace: azubi-portal
     labels:
       app: azubi-portal
   spec:
     replicas: 2
     selector:
       matchLabels:
         app: azubi-portal
     template:
       metadata:
         labels:
           app: azubi-portal
       spec:
         containers:
           - name: azubi-portal
             image: docker.io/library/nginx:stable
             ports:
               - containerPort: 80
   ---
   apiVersion: v1
   kind: Service
   metadata:
     name: azubi-portal
     namespace: azubi-portal
     labels:
       app: azubi-portal
   spec:
     type: ClusterIP
     selector:
       app: azubi-portal
     ports:
       - port: 80
         targetPort: 80
         protocol: TCP
   ```

   Ergänze bei Bedarf weitere Felder (z. B. Ressourcengrenzen, Labels), wenn du sie aus der Dokumentation kennst.

3. Wende die YAML-Datei mit `kubectl apply -f azubi-portal.yaml` an.
4. Prüfe mit `kubectl get deploy,po,svc -n azubi-portal`, ob alles wie erwartet erstellt wurde.

Hinweis: Dieses Deployment + Service dienen später im Helm-Modul als Vorlage für das `azubi-portal`-Chart.

Beispielbefehle:

```bash
kubectl apply -f azubi-portal.yaml
kubectl get deploy,po,svc -n azubi-portal
```

### Aufgabe 2: ConfigMap und Secret für `azubi-portal` nutzen

**Ziel:** Konfiguration und geheime Daten in deine Pods einbinden.

1. Erstelle eine ConfigMap, die mindestens einen Konfigurationswert enthält, z. B. `WELCOME_MESSAGE=Hallo im Azubi-Portal`.
2. Erstelle ein Secret mit einem fiktiven Passwort oder Token.
3. Passe dein Deployment aus Aufgabe 1 so an, dass:
   - die ConfigMap als Umgebungsvariable in den Container injiziert wird (z. B. `WELCOME_MESSAGE`)
   - das Secret entweder als Umgebungsvariable oder als Datei im Container zur Verfügung steht
4. Rolle das aktualisierte Deployment aus und überprüfe mit `kubectl describe pod`, ob ConfigMap und Secret wie erwartet referenziert werden.

Beispiel-ConfigMap:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: azubi-portal-config
  namespace: azubi-portal
data:
  WELCOME_MESSAGE: "Hallo im Azubi-Portal"
```

Beispiel-Secret (mit `stringData`, damit du Klartext-Werte testen kannst):

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: azubi-portal-secret
  namespace: azubi-portal
type: Opaque
stringData:
  PASSWORD: "supergeheim"
```

### Aufgabe 3: ServiceAccount und RoleBinding für `azubi-portal` einführen

**Ziel:** Ein einfaches RBAC-Szenario umsetzen.

1. Erstelle einen ServiceAccount (z. B. `azubi-portal-sa`) im Namespace `azubi-portal`.
2. Erstelle eine Role, die ausschließlich `get` und `list` auf Pods in diesem Namespace erlaubt.
3. Erstelle ein RoleBinding, das diesen ServiceAccount mit der Role verknüpft.
4. Passe dein Deployment an, sodass die Pods mit dem ServiceAccount `azubi-portal-sa` laufen.
5. Prüfe mit `kubectl describe rolebinding -n azubi-portal`, ob die Verknüpfung korrekt ist.

Hinweis: Du musst das Verhalten hier nicht bis ins Detail testen, wichtig ist das Verständnis für den Aufbau der RBAC-Ressourcen.

Beispiel-Role und RoleBinding:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: azubi-portal-read-pods
  namespace: azubi-portal
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: azubi-portal-read-pods-binding
  namespace: azubi-portal
subjects:
  - kind: ServiceAccount
    name: azubi-portal-sa
    namespace: azubi-portal
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: azubi-portal-read-pods
```

Beispiel-Befehl zum Anlegen des ServiceAccounts (statt YAML kannst du auch diesen Weg nutzen):

```bash
kubectl create serviceaccount azubi-portal-sa -n azubi-portal
```

### Aufgabe 4: Eine einfache NetworkPolicy testen

**Ziel:** Verstehen, wie NetworkPolicies den Traffic beeinflussen.

1. Lege einen eigenen Namespace für dieses Experiment an, z. B. `np-test`.
2. Deploye dort eine einfache Web-App (Deployment + Service), ähnlich Aufgabe 1, und versehe die Pods mit einem Label wie `app=webapp`.
3. Erstelle eine NetworkPolicy, die z. B. nur eingehenden Traffic von Pods mit einem bestimmten Label oder nur aus demselben Namespace erlaubt.
4. Starte einen zusätzlichen Test-Pod im Namespace (z. B. mit einem Tools-Image), versehe ihn mit einem Label wie `role=client`, und greife von dort mit `curl` auf den Service zu.
5. Beobachte, wann der Zugriff laut Theorie funktionieren sollte und wann nicht (z. B. nachdem du Labels anpasst oder die NetworkPolicy änderst). Beachte dabei, dass im kind-Standard-Setup die Policy evtl. nicht technisch enforced wird.

Hinweis: Je nach Cluster-Netzwerkplugin kann das Verhalten von NetworkPolicies variieren. Für das Lab reicht es, das Prinzip zu verstehen.

Beispiel-NetworkPolicy (nur Traffic von Pods mit Label `role=client` erlauben):

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-clients
  namespace: np-test
spec:
  podSelector:
    matchLabels:
      app: webapp
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              role: client
``` 

### Bonus-Aufgaben (für Fortgeschrittene)

- Erweitere dein `azubi-portal`-Deployment um Ressourcen-Requests/-Limits und beobachte mit `kubectl describe pod`, wie sie angezeigt werden.
- Ergänze weitere Konfigurationswerte in der `azubi-portal-config`-ConfigMap (z. B. einen Seitentitel) und nutze sie in deinem Container (z. B. über Umgebungsvariablen oder ein Startskript).
- Erzeuge ein zweites Deployment im Namespace `azubi-portal` und passe deine NetworkPolicy so an, dass nur bestimmte Pods auf den `azubi-portal`-Service zugreifen dürfen.

## Häufige Stolperfallen & Tipps

- `kubectl apply` schlägt mit YAML-Fehlern fehl: prüfe Einrückungen und Doppelpunkt-Syntax sehr genau.
- Ressourcen werden im falschen Namespace angelegt: kontrolliere, ob in `metadata.namespace` der erwartete Namespace (z. B. `azubi-portal`) gesetzt ist oder ob du `-n` im Befehl korrekt verwendest.
- Pods starten nicht: nutze `kubectl describe pod` und `kubectl logs`, um Events (z. B. ImagePullErrors) und Container-Logs zu prüfen.
- Bei RBAC-Problemen (z. B. `Forbidden`-Fehler) hilft ein Blick in Role/RoleBinding sowie die verwendeten ServiceAccounts.

## Weiterführend

- Lese in der Kubernetes-Dokumentation die Kapitel zu Deployments, Services, ConfigMaps, Secrets und RBAC.
- Überlege dir weitere Szenarien, in denen du NetworkPolicies einsetzen würdest (z. B. Isolation zwischen Teams oder Umgebungen).
