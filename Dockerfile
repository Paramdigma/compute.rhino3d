# escape=`

# see https://discourse.mcneel.com/t/docker-support/89322 for troubleshooting

# NOTE: use 'process' isolation to build image (otherwise rhino fails to install)

### builder image
FROM mcr.microsoft.com/dotnet/sdk:5.0 as builder

# copy everything, restore nuget packages and build app
COPY src/ ./src/
RUN dotnet build -c Release src/compute.sln

### main image
# tag must match windows host for build (and run, if running with process isolation)
# e.g. 1903 for Windows 10 version 1903 host
FROM mcr.microsoft.com/windows/server:ltsc2022

# install rhino (with “-package -quiet” args)
# NOTE: edit this if you use a different version of rhino!
# the url below will always redirect to the latest rhino 7 (email required)
# https://www.rhino3d.com/download/rhino-for-windows/7/latest/direct?email=EMAIL
RUN curl -fSLo rhino_installer.exe https://files.mcneel.com/dujour/exe/20210319/rhino_en-us_7.4.21078.01001.exe `
    && .\rhino_installer.exe -package -quiet `
    && del .\rhino_installer.exe

# (optional) use the package manager to install plug-ins
# RUN ""C:\Program Files\Rhino 7\System\Yak.exe"" install jswan

# copy compute app to image
COPY --from=builder ["/src/bin/Release/compute.geometry", "/app"]
WORKDIR /app

# bind compute.geometry to port 80
ENV RHINO_COMPUTE_URLS="http://+:80"
EXPOSE 80

# uncomment to build core-hour billing credentials into image (not recommended)
# see https://developer.rhino3d.com/guides/compute/core-hour-billing/
# ENV RHINO_TOKEN="TOKEN"
LABEL org.opencontainers.image.source="https://github.com/paramdigma/compute.rhino3d"

CMD ["compute.geometry.exe"]
