
one time
[Manage Docker as a non-root user](https://docs.docker.com/engine/install/linux-postinstall/#manage-docker-as-a-non-root-user)

```bash
docker run --privileged --rm tonistiigi/binfmt --install all
docker buildx create --use --name multiarch
```

build

```bash
docker buildx build --platform linux/arm64 -f Dockerfile.arm64 -t pdf_signature_arm64 .
```

Extract the Built App

```bash
mkdir output
docker run --rm -v $(pwd)/output:/output pdf_signature_arm64 cp -r /app /output
mkdir output/lib
# docker run --rm -v $(pwd)/output:/output pdf_signature_arm64 ldd /app/pdf_signature
docker run --rm -v $(pwd)/output:/output pdf_signature_arm64 sh -c "ldd /app/pdf_signature | grep '=>' | awk '{print \$3}' | grep -v libc | xargs -I {} cp -L {} /output/lib"
# docker run --rm -v $(pwd)/output:/output pdf_signature_arm64 ls /app/lib
# tree output/
```
