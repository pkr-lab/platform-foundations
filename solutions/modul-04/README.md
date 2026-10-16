# Lösung Modul 04

## Ablauf

1. In JFrog unter **Artifactory → Packages** nach `nginx` suchen, Pakettyp **Docker**.
2. Version `stable` auswählen und den angezeigten Pull-Befehl kopieren.
3. `docker` durch `podman` ersetzen und das Image laden:

   ```bash
   podman login dev-repos-prod-web.services.debeka.de
   podman pull dev-repos-prod-web.services.debeka.de/<repository>/nginx:stable
   podman images
   ```

4. Die Image-Adresse ohne Tag als `image.repository` und den Tag als `image.tag` in die `values-lab.yaml` übernehmen, siehe [values-lab.yaml](./values-lab.yaml).
5. Falls der Cluster das Image nicht laden darf, Pull-Secret mit dem technischen Benutzer anlegen:

   ```bash
   kubectl create secret docker-registry artifactory-pull -n azubi-portal \
     --docker-server=dev-repos-prod-web.services.debeka.de \
     --docker-username=<technischer-benutzer> \
     --docker-password=<token>
   helm upgrade azubi-portal ~/k8s-lab/azubi-portal-chart -n azubi-portal -f values-lab.yaml
   ```

`<repository>` ist der Repository-Name aus dem kopierten Pull-Befehl.

## Antworten auf die Verständnisfragen

1. Artifactory cacht die Images, funktioniert im Firmennetz ohne direkten Internetzugang, umgeht die Download-Limits von Docker Hub und prüft die Images auf Sicherheitslücken.
2. Statt `docker.io/library/nginx` beginnt die Adresse mit dem Artifactory-Host und dem Repository-Namen, z. B. `dev-repos-prod-web.services.debeka.de/<repository>/nginx`.
3. `latest` kann jederzeit auf ein anderes Image zeigen. Mit einem festen Tag ist klar, welche Version läuft, und ein Deployment lässt sich reproduzieren.
