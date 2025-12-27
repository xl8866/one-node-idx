#!/usr/bin/env sh

########################
# 基础变量
########################
PORT="${PORT:-8080}"
UUID="${UUID:-2584b733-9095-4bec-a7d5-62b473540f7a}"

########################
# 哪吒监控配置（必须改）
########################
NEZHA_SERVER="z.kkkk.hidns.co:80"   # 哪吒面板域名或IP
NEZHA_PORT="5555"                  # 哪吒端口（默认 5555）
NEZHA_KEY="ZPRVZUoCu50Wz0ZiL4mSf2zZelRDh1K5"   # Agent Key
NEZHA_TLS="1"                      # 1=TLS  0=非TLS

########################
# 1. init directory
########################
mkdir -p app/xray
cd app/xray

########################
# 2. download and extract Xray
########################
wget -q https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip
unzip -o Xray-linux-64.zip
rm -f Xray-linux-64.zip
chmod +x xray

########################
# 3. add config file
########################
wget -q -O config.json https://raw.githubusercontent.com/vevc/one-node/refs/heads/main/google-idx/xray-config-template.json
sed -i "s/\$PORT/$PORT/g" config.json
sed -i "s/\$UUID/$UUID/g" config.json

########################
# 4. create startup.sh
########################
wget -q https://raw.githubusercontent.com/vevc/one-node/refs/heads/main/google-idx/startup.sh
sed -i "s#\$PWD#$PWD#g" startup.sh
chmod +x startup.sh

########################
# 5. start Xray
########################
nohup $PWD/startup.sh >/dev/null 2>&1 &

########################
# 6. install Nezha Agent
########################
mkdir -p /opt/nezha
cd /opt/nezha

wget -q https://github.com/nezhahq/agent/releases/latest/download/nezha-agent_linux_amd64.zip
unzip -o nezha-agent_linux_amd64.zip
rm -f nezha-agent_linux_amd64.zip
chmod +x nezha-agent

########################
# 7. start Nezha Agent
########################
if [ "$NEZHA_TLS" = "1" ]; then
  nohup ./nezha-agent \
    -s ${NEZHA_SERVER}:${NEZHA_PORT} \
    -p ${NEZHA_KEY} \
    --tls >/dev/null 2>&1 &
else
  nohup ./nezha-agent \
    -s ${NEZHA_SERVER}:${NEZHA_PORT} \
    -p ${NEZHA_KEY} >/dev/null 2>&1 &
fi

########################
# 8. print node info
########################
echo '---------------------------------------------------------------'
echo "Xray 已启动"
echo "哪吒监控已连接"
echo ""
echo "VLESS 节点："
echo "vless://$UUID@example.domain.com:443?encryption=none&security=tls&alpn=http%2F1.1&fp=chrome&type=xhttp&path=%2F&mode=auto#idx-xhttp"
echo '---------------------------------------------------------------'
