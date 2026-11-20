# Lösung Modul 07

| Datei | Inhalt |
| --- | --- |
| [azubi-portal-application.yaml](./azubi-portal-application.yaml) | Endstand der Application mit automatischem Sync |
| [gitlab-repo-secret.yaml](./gitlab-repo-secret.yaml) | Repo-Zugang deklarativ (Aufgabe 2). **Nicht mit echtem Token committen!** |
| [azubi-portal-oci-application.yaml](./azubi-portal-oci-application.yaml) | Bonus: Chart aus dem Artifactory, Values aus Git |

## ArgoCD installieren

```bash
helm uninstall azubi-portal -n azubi-portal
kubectl delete secret artifactory-pull -n azubi-portal
helm install argocd artifactory/argo-cd --version <chart-version> -n argocd --create-namespace --set dex.enabled=false
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
kubectl port-forward svc/argocd-server -n argocd 9443:443
```

Nach dem Sync zeigt `kubectl exec -n azubi-portal deploy/azubi-portal -- env | grep PASSWORD` den Wert `supergeheim` – der Controller hat das `SealedSecret` entschlüsselt, das Chart bindet es über `existingSecret` ein.

## OCI-Variante

Für die OCI-Variante muss das Helm-OCI-Repo `<artifactory-host>/<helm-oci-repo>` in ArgoCD hinterlegt sein (Typ `helm`, `enableOCI: "true"`, Benutzer und Token eines technischen Benutzers). `repoURL` steht dabei **ohne** `oci://`.

Die `SealedSecret`-Dateien liegen nur im Git-Chart, nicht im OCI-Paket. Die Application setzt deshalb `existingSecret` auf leer. Verlangt das Artifactory eine Anmeldung, braucht der Namespace `azubi-portal-oci` zusätzlich ein eigenes Pull-Secret `artifactory-pull`.

## Antworten auf die Verständnisfragen

1. **Sync Status** vergleicht Git mit dem Cluster (stimmt der Zustand überein?). **Health Status** sagt, ob die Ressourcen funktionieren (laufen die Pods, ist das Deployment fertig ausgerollt?). Eine App kann „Synced“, aber „Degraded“ sein – z. B. bei einem falschen Image-Tag.
2. `prune` löscht Ressourcen, die nicht mehr in Git stehen. `selfHeal` setzt manuelle Änderungen im Cluster zurück. `prune: false` ist sinnvoll, wenn versehentliches Löschen teuer wäre, z. B. bei Ressourcen mit Daten.
3. ArgoCD nutzt Helm nur zum Rendern (`helm template`) und wendet die Manifeste selbst an. Es wird kein Helm-Release-Secret angelegt.
4. Der Revert ist in Git dokumentiert und wird von ArgoCD automatisch umgesetzt. `helm rollback` oder `kubectl` würden von ArgoCD als Drift erkannt und wieder überschrieben.
