#!/usr/bin/env sh

############################
# Xray 基础变量
############################
PORT="${PORT:-8080}"
UUID="${UUID:-8f638494-7ef4-41ba-a801-c4fd22845d84}"

############################
# 哪吒监控（环境变量风格）
# v1 示例： nz.example.com:8008
# v0 示例： nz.example.com + NEZHA_PORT
############################
NEZHA_SERVER="${z.kkkk.hidns.co:80}"
NEZHA_PORT="${NEZHA_PORT:-}"
NEZHA_KEY="${ZPRVZUoCu50Wz0ZiL4mSf2zZelRDh1K5}"

############################
# 1. init directory
############################
mkdir -p app/xray
cd app/xray || exit 1

############################
# 2. download and extract Xray
############################
wget -q https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip
unzip -o Xray-linux-64.zip
rm -f Xray-linux-64.zip
chmod +x xray

############################
# 3. add config file
############################
wget -q -O config.json https://raw.githubusercontent.com/vevc/one-node/refs/heads/main/google-idx/xray-config-template.json
sed -i "s/\$PORT/$PORT/g" config.json
sed -i "s/\$UUID/$UUID/g" config.json

############################
# 4. create startup.sh
############################
wget -q https://raw.githubusercontent.com/vevc/one-node/refs/heads/main/google-idx/startup.sh
sed -i "s#\$PWD#$PWD#g" startup.sh
chmod +x startup.sh

############################
# 5. install Nezha Agent
############################
mkdir -p "$HOME/nezha"
cd "$HOME/nezha" || exit 1

wget -q https://github.com/nezhahq/agent/releases/latest/download/nezha-agent_linux_amd64.zip
unzip -o nezha-agent_linux_amd64.zip
rm -f nezha-agent_linux_amd64.zip
chmod +x nezha-agent

############################
# 6. start Nezha Agent（自动识别 v0 / v1）
############################
if [ -n "$NEZHA_SERVER" ] && [ -n "$NEZHA_KEY" ]; then
  TLS_FLAG=""

  if echo "$NEZHA_SERVER" | grep -q ":"; then
    # v1：server 已包含端口，默认 TLS
    SERVER="$NEZHA_SERVER"
    TLS_FLAG="--tls"
  else
    # v0：根据端口判断 TLS
    SERVER="${NEZHA_SERVER}:${NEZHA_PORT}"
    case "$NEZHA_PORT" in
      443|8443|2096|2087|2083|2053)
        TLS_FLAG="--tls"
        ;;
    esac
  fi

  echo "[Nezha] Connecting to $SERVER $TLS_FLAG"
  ./nezha-agent -s "$SERVER" -p "$NEZHA_KEY" $TLS_FLAG &
else
  echo "[Nezha] 未设置 NEZHA_SERVER / NEZHA_KEY，跳过监控"
fi

############################
# 7. start Xray（前台主进程）
############################
cd "$PWD" || exit 1
./startup.sh &

############################
# 8. print node info
############################
echo '---------------------------------------------------------------'
echo "Xray + 哪吒监控 已启动"
echo ""
echo "VLESS 节点："
echo "vless://$UUID@example.domain.com:443?encryption=none&security=tls&alpn=http%2F1.1&fp=chrome&type=xhttp&path=%2F&mode=auto#idx-xhttp"
echo '---------------------------------------------------------------'

############################
# 9. keep alive（IDX 防回收）
############################
wait
