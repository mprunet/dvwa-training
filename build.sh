#/bin/bash
docker rmi safepic/dvwa-training:latest
docker build -t safepic/dvwa-training .
