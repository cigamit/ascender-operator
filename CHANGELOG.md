# Changelog

This is a list of high-level changes for each release of `ascender-operator`. A full list of commits can be found at `https://github.com/ctrliq/ascender-operator/releases/tag/<version>`.

# 0.19.0 (Mar 23, 2022)

- Fix corrupted spec for the service with nodeport type (kurokobo) - dbaf64e
- Add ability to deploy with OLM & added logo (Christian Adams) - 86c31a4
- Fix backup & restore issues with special characters in the postgres password (kurokobo) - 589a375
- Use centos:stream8 container where applicable (Shane McDonald)- 12a58d7
