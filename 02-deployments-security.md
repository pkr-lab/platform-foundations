# Modul 02 – Manuelle Deployments & Basis-Security

## Kurzbeschreibung

In diesem Modul vertiefst du deine Kubernetes-Grundlagen. Du beschreibst Anwendungen als YAML-Deployments und Services, arbeitest mit ConfigMaps und Secrets, machst deine App per Ingress erreichbar und lernst erste Security-Konzepte kennen: RBAC, gehärtete Pods (`securityContext`, Pod Security Standards) und NetworkPolicies.

## Lernziele

- Deployments und Services per YAML definieren und ausrollen
- ConfigMaps und Secrets erstellen und in Pods verwenden – und wissen, warum Secrets nicht verschlüsselt sind
- grundlegende RBAC-Konzepte verstehen und testen (ServiceAccount, Role, RoleBinding)
- Pods mit `securityContext` härten und Pod Security Standards anwenden
- eine NetworkPolicy entwerfen und deren Wirkung überprüfen
- eine App über einen Ingress-Controller erreichbar machen

## Voraussetzungen

- Modul 01 abgeschlossen (kind-Cluster läuft, `kubectl` funktioniert)

## Theorie (Kurzüberblick)

### Deployments und Services

Ein [Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) verwaltet eine Gruppe identischer Pods. Es sorgt dafür, dass die gewünschte Anzahl an Replikas läuft und dass Rollouts/Updates kontrolliert stattfinden.

Ein [Service](https://kubernetes.io/docs/concepts/services-networking/service/) stellt eine stabile Netzwerkschnittstelle vor eine Gruppe von Pods. Er löst u. a. das Problem, dass Pod-IPs sich ändern können. Typische Service-Typen sind `ClusterIP` (Standard, nur im Cluster erreichbar) und `NodePort` (Port auf den Nodes öffnen).

### ConfigMaps und Secrets

[ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/) speichern nicht-sensible Konfiguration (z. B. URLs, Feature-Flags). [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/) sind für sensible Daten wie Passwörter oder Tokens gedacht. Beide können als Umgebungsvariablen oder als Dateien in Containern zur Verfügung gestellt werden.

> **Wichtig:** Die Werte in einem Secret sind nur **base64-kodiert, nicht verschlüsselt**. Jeder, der das Secret lesen darf, kann es mit `base64 -d` zurückwandeln. Schutz entsteht erst durch RBAC (wer darf Secrets lesen?) und – außerhalb des Clusters – durch Werkzeuge wie Sealed Secrets oder SOPS (siehe [Modul 05](./05-gitlab-gitops-struktur.md)). Secrets gehören **nie im Klartext** in ein Git-Repository.

### RBAC (Role-Based Access Control)

Mit [RBAC](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) steuerst du, welcher Nutzer/ServiceAccount welche Aktionen auf welchen Ressourcen ausführen darf:

- `ServiceAccount`: technische Identität für Pods
- `Role` / `ClusterRole`: definieren, welche Aktionen erlaubt sind (z. B. `get`, `list`, `watch` auf `pods`)
- `RoleBinding` / `ClusterRoleBinding`: verknüpfen Rollen mit Benutzern oder ServiceAccounts

### Pod-Härtung und Pod Security Standards

Viele Container laufen standardmäßig als `root`. Mit einem [`securityContext`](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/) legst du fest, dass ein Container z. B. nicht als root läuft, keine Rechte eskalieren darf und ein schreibgeschütztes Dateisystem hat.

Die [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/) definieren drei Stufen (`privileged`, `baseline`, `restricted`). Über Labels am Namespace kann Kubernetes Pods, die gegen eine Stufe verstoßen, warnen (`warn`), protokollieren (`audit`) oder ablehnen (`enforce`).

### NetworkPolicies

[NetworkPolicies](https://kubernetes.io/docs/concepts/services-networking/network-policies/) steuern, welcher Traffic zwischen Pods erlaubt ist. Ohne Policy ist aller Pod-zu-Pod-Traffic erlaubt. Sobald eine Policy einen Pod auswählt, ist für diesen Pod nur noch erlaubt, was die Policy explizit zulässt.

Ob NetworkPolicies durchgesetzt werden, hängt vom Netzwerk-Plugin (CNI) ab. Das Standard-CNI von kind (`kindnet`) setzt NetworkPolicies ab **kind v0.24** durch. Prüfe deine Version mit `kind version`. Bei älteren Versionen ist die Aufgabe nur eine Syntax- und Konzeptübung.

### Ingress

Ein [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/) beschreibt, wie HTTP-Anfragen von außen (z. B. anhand des Hostnamens) an Services weitergeleitet werden. Damit das funktioniert, braucht der Cluster einen **Ingress-Controller**. Im Lab verwenden wir [Traefik](https://doc.traefik.io/traefik/). Er lauscht auf den Node-Ports 80/443, die `kind.yaml` auf deine Host-Ports 8080/8443 abbildet.

> Hinweis: Das früher sehr verbreitete Projekt `ingress-nginx` wurde von der Kubernetes-Community eingestellt. Der Nachfolger des Ingress-Konzepts ist die [Gateway API](https://gateway-api.sigs.k8s.io/), die auch Traefik unterstützt.

## Aufgaben

### Aufgabe 1: `azubi-portal` als Deployment und Service beschreiben

**Ziel:** Die Beispiel-App `azubi-portal` mit Deployment und Service im Cluster bereitstellen.

1. Lege einen Namespace `azubi-portal` an:

   ```bash
   kubectl create namespace azubi-portal
   ```

2. Erstelle eine YAML-Datei `azubi-portal.yaml` mit folgendem Grundgerüst und ergänze fehlende Teile nach Bedarf:

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

3. Wende die YAML-Datei an und prüfe, ob alles erstellt wurde:

   ```bash
   kubectl apply -f azubi-portal.yaml
   kubectl get deploy,po,svc -n azubi-portal
   kubectl port-forward svc/azubi-portal -n azubi-portal 9080:80
   ```

Hinweis: Dieses Deployment + Service dienen im Helm-Modul als Vorlage für das `azubi-portal`-Chart.

### Aufgabe 2: ConfigMap und Secret für `azubi-portal` nutzen

**Ziel:** Konfiguration und geheime Daten in deine Pods einbinden.

1. Erstelle eine ConfigMap mit `WELCOME_MESSAGE=Hallo im Azubi-Portal`.
2. Erstelle ein Secret mit einem fiktiven Passwort.
3. Passe dein Deployment so an, dass:
   - die ConfigMap als Umgebungsvariable injiziert wird (`envFrom` oder `env.valueFrom.configMapKeyRef`)
   - das Secret als Umgebungsvariable oder als Datei im Container verfügbar ist
4. Rolle das Deployment aus und prüfe im Container, ob die Werte ankommen:

   ```bash
   kubectl exec -n azubi-portal deploy/azubi-portal -- env | grep -E 'WELCOME|PASSWORD'
   ```

5. Lies das Secret aus und dekodiere es. Was sagt dir das über die Sicherheit von Secrets?

   ```bash
   kubectl get secret azubi-portal-secret -n azubi-portal -o jsonpath='{.data.PASSWORD}' | base64 -d
   ```

Beispiel-ConfigMap und -Secret:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: azubi-portal-config
  namespace: azubi-portal
data:
  WELCOME_MESSAGE: "Hallo im Azubi-Portal"
---
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

**Ziel:** Ein einfaches RBAC-Szenario umsetzen und testen.

1. Erstelle einen ServiceAccount `azubi-portal-sa` im Namespace `azubi-portal`.
2. Erstelle eine Role, die ausschließlich `get` und `list` auf Pods in diesem Namespace erlaubt.
3. Erstelle ein RoleBinding, das den ServiceAccount mit der Role verknüpft.
4. Passe dein Deployment an, sodass die Pods mit dem ServiceAccount laufen (`spec.template.spec.serviceAccountName`).
5. Teste die Rechte mit `kubectl auth can-i`, ohne dich als ServiceAccount anmelden zu müssen:

   ```bash
   kubectl auth can-i list pods -n azubi-portal --as=system:serviceaccount:azubi-portal:azubi-portal-sa
   kubectl auth can-i delete pods -n azubi-portal --as=system:serviceaccount:azubi-portal:azubi-portal-sa
   kubectl auth can-i get secrets -n azubi-portal --as=system:serviceaccount:azubi-portal:azubi-portal-sa
   ```

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

### Aufgabe 4: Pods härten mit `securityContext` und Pod Security Standards

**Ziel:** Verstehen, warum Container nicht als root laufen sollten und wie Kubernetes das erzwingen kann.

1. Setze am Namespace `azubi-portal` Labels, damit Kubernetes bei Verstößen gegen den Standard `restricted` warnt:

   ```bash
   kubectl label namespace azubi-portal \
     pod-security.kubernetes.io/warn=restricted \
     pod-security.kubernetes.io/audit=restricted
   ```

2. Wende dein Deployment erneut an (`kubectl apply -f azubi-portal.yaml`) und lies die Warnungen. Welche Punkte bemängelt Kubernetes?
3. Ergänze im Container einen `securityContext` mit `runAsNonRoot: true` und beobachte mit `kubectl get pods` und `kubectl describe pod`, was passiert. Warum startet das offizielle Nginx-Image nicht mehr?
4. Wechsle auf das Image `docker.io/nginxinc/nginx-unprivileged:stable`. Es läuft als normaler Benutzer und lauscht auf Port **8080**. Passe `containerPort` und `targetPort` im Service an.
5. Ergänze den `securityContext`, bis keine Warnungen mehr erscheinen:

   ```yaml
   securityContext:
     runAsNonRoot: true
     allowPrivilegeEscalation: false
     capabilities:
       drop: ["ALL"]
     seccompProfile:
       type: RuntimeDefault
   ```

6. Optional: Stelle `pod-security.kubernetes.io/enforce=restricted` ein und versuche, das alte root-Image zu deployen.

### Aufgabe 5: Eine NetworkPolicy testen

**Ziel:** Verstehen, wie NetworkPolicies den Traffic beeinflussen.

1. Lege einen Namespace `np-test` an und deploye dort eine einfache Web-App (Deployment + Service `webapp`) mit dem Label `app=webapp`.
2. Starte zwei Test-Pods, einen mit Label `role=client` und einen ohne:

   ```bash
   kubectl run client -n np-test --labels=role=client --image=docker.io/curlimages/curl:8.10.1 --command -- sleep 3600
   kubectl run fremd -n np-test --image=docker.io/curlimages/curl:8.10.1 --command -- sleep 3600
   ```

3. Teste vor der Policy aus beiden Pods den Zugriff: `kubectl exec -n np-test client -- curl -s -m 3 webapp`.
4. Wende die folgende NetworkPolicy an und teste erneut. Welcher Pod kommt noch durch?

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

5. Ändere das Label des Pods `fremd` (`kubectl label pod fremd -n np-test role=client`) und teste erneut.

### Aufgabe 6: `azubi-portal` per Ingress erreichbar machen

**Ziel:** Die App ohne Port-Forwarding unter `http://azubi-portal.localhost:8080` aufrufen.

1. Installiere Traefik als Ingress-Controller. Die Werte sorgen dafür, dass Traefik auf dem Node mit `ingress-ready=true` direkt die Ports 80/443 belegt:

   ```bash
   helm repo add traefik https://traefik.github.io/charts
   helm repo update
   helm install traefik traefik/traefik -n traefik --create-namespace \
     -f solutions/modul-02/traefik-values.yaml
   kubectl get pods -n traefik
   ```

   Sieh dir die Datei [solutions/modul-02/traefik-values.yaml](./solutions/modul-02/traefik-values.yaml) an und erkläre, was die einzelnen Werte bewirken.

2. Lege einen Ingress für `azubi-portal` an:

   ```yaml
   apiVersion: networking.k8s.io/v1
   kind: Ingress
   metadata:
     name: azubi-portal
     namespace: azubi-portal
   spec:
     ingressClassName: traefik
     rules:
       - host: azubi-portal.localhost
         http:
           paths:
             - path: /
               pathType: Prefix
               backend:
                 service:
                   name: azubi-portal
                   port:
                     number: 80
   ```

3. Öffne `http://azubi-portal.localhost:8080` im Browser oder teste mit `curl -H 'Host: azubi-portal.localhost' http://localhost:8080`.

Hinweis: Alle Namen unter `*.localhost` zeigen in modernen Browsern automatisch auf `127.0.0.1`, ein Eintrag in der `hosts`-Datei ist nicht nötig.

### Bonus-Aufgaben (für Fortgeschrittene)

- Ergänze Ressourcen-Requests/-Limits und beobachte mit `kubectl describe pod`, wie sie angezeigt werden.
- Ergänze `readinessProbe` und `livenessProbe` im Deployment. Was passiert, wenn der Probe-Pfad falsch ist?
- Ergänze `readOnlyRootFilesystem: true`. Welche Verzeichnisse braucht Nginx trotzdem beschreibbar (Tipp: `emptyDir`)?
- Schreibe eine „Default Deny“-NetworkPolicy für `azubi-portal` und erlaube nur Traffic aus dem Namespace `traefik`.

## Du bist fertig, wenn …

- [ ] `azubi-portal` mit 2 Replikas läuft und die Werte aus ConfigMap und Secret im Container sichtbar sind
- [ ] `kubectl auth can-i` für den ServiceAccount `list pods` mit `yes` und `delete pods` mit `no` beantwortet
- [ ] das Deployment ohne Pod-Security-Warnungen (`restricted`) angewendet wird
- [ ] du die Wirkung der NetworkPolicy mit `curl` nachweisen kannst
- [ ] `http://azubi-portal.localhost:8080` die Portal-Seite zeigt

## Verständnisfragen

1. Warum ist ein Secret im Git-Repository auch dann unsicher, wenn es base64-kodiert ist?
2. Was ist der Unterschied zwischen `Role` und `ClusterRole`?
3. Warum ist `runAsNonRoot` sinnvoll, obwohl der Container ja isoliert ist?
4. Was passiert mit dem Traffic zu einem Pod, sobald *irgendeine* NetworkPolicy ihn auswählt?
5. Welche Aufgabe hat der Ingress-Controller, welche das Ingress-Objekt?

## Häufige Stolperfallen & Tipps

- `kubectl apply` schlägt mit YAML-Fehlern fehl: prüfe Einrückungen und Doppelpunkt-Syntax sehr genau.
- Ressourcen landen im falschen Namespace: kontrolliere `metadata.namespace` oder den Parameter `-n`.
- Pods starten nicht: `kubectl describe pod` (Events, z. B. `ImagePullBackOff`, `CreateContainerConfigError`) und `kubectl logs` helfen.
- Nach dem Wechsel auf `nginx-unprivileged` ist die Seite nicht erreichbar: `targetPort` im Service muss auf `8080` zeigen.
- Ingress liefert `404`: stimmt der Host-Name im Ingress mit dem im Browser überein? Stimmt `ingressClassName`?

## Aufräumen

Den Namespace `azubi-portal` brauchst du in Modul 03 nicht mehr in dieser Form – dort installierst du die App per Helm neu. Traefik bleibt installiert.

```bash
kubectl delete namespace azubi-portal np-test
```

## Weiterführend

- Kubernetes-Dokumentation zu [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/), [Secrets – Good Practices](https://kubernetes.io/docs/concepts/security/secrets-good-practices/) und [RBAC Good Practices](https://kubernetes.io/docs/concepts/security/rbac-good-practices/)
- [Gateway API](https://gateway-api.sigs.k8s.io/) als Nachfolger von Ingress

Eine Musterlösung findest du unter [solutions/modul-02](./solutions/modul-02/).
