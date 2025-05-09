#/bin/bash
docker rmi safepic/dvwa-training:latest
docker --debug build -t safepic/dvwa-training .
