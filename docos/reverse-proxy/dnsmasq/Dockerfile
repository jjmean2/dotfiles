FROM alpine:latest

# dnsmasq 설치
RUN apk add --no-cache dnsmasq

# DNS 기본 포트 명시
EXPOSE 53/udp 53/tcp

# 포그라운드 실행 (-k) 및 root 권한 처리
ENTRYPOINT ["dnsmasq", "-k", "--user=root"]
