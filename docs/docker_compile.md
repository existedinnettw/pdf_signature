
one time
[Manage Docker as a non-root user](https://docs.docker.com/engine/install/linux-postinstall/#manage-docker-as-a-non-root-user)

```bash
docker run --privileged --rm tonistiigi/binfmt --install all
docker buildx create --use --name multiarch
```

build (single-arch, locally loadable)

```bash
# amd64
docker buildx build --platform linux/amd64 -f Dockerfile.arm64 -t pdf_signature:amd64 --load .

# arm64
docker buildx build --platform linux/arm64 -f Dockerfile.arm64 -t pdf_signature:arm64 --load .
```

build (multi-arch manifest, push to registry)

```bash
# requires a registry you can push to, e.g. ghcr.io/<org>/pdf_signature:latest
docker buildx build \
	--platform linux/amd64,linux/arm64 \
	-f Dockerfile.arm64 \
	-t <your-registry>/pdf_signature:latest \
	--push .
```

Extract the Built App (from a single-arch image)

```bash
mkdir output
# select the architecture tag you built above
# e.g. pdf_signature:arm64 or pdf_signature:amd64
docker run --rm -v $(pwd)/output:/output pdf_signature:arm64 cp -r /app /output
mkdir output/lib
# docker run --rm -v $(pwd)/output:/output pdf_signature:arm64 ldd /app/pdf_signature
docker run --rm -v $(pwd)/output:/output pdf_signature:arm64 sh -c "ldd /app/pdf_signature | grep '=>' | awk '{print \$3}' | grep -v libc | xargs -I {} cp -L {} /output/lib"
# docker run --rm -v $(pwd)/output:/output pdf_signature:arm64 ls /app/lib
# tree output/
```

Notes

- The Dockerfile uses Ubuntu 18.04 to keep glibc at 2.27 for broad compatibility. If 18.04 mirrors are unavailable in your environment, consider switching to 20.04 (glibc 2.31) and testing on your target distros, or point apt to old-releases.
- CMake binaries are fetched per-arch; Flutter target-platform is selected automatically (linux-x64 on amd64, linux-arm64 on arm64).
