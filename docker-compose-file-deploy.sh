#!/bin/bash

set -e

# YAML 파일을 JSON으로 변환
configs=$(yq eval '.configs' .deploy/config.yml)  # 'eval' 대신 'e'를 사용할 수도 있습니다.

# server 정보 대체
configs=$(echo "$configs" | jq --arg user "${MAIN_EC2_USER}" \
                                 --arg host "${MAIN_EC2_HOST}" \
                                 --arg key "${MAIN_EC2_KEY}" \
                                 'map(if .server.user == "MAIN_EC2_USER_PLACEHOLDER" then .server.user = $user else . end |
                                      if .server.host == "MAIN_EC2_HOST_PLACEHOLDER" then .server.host = $host else . end |
                                      if .server.key == "MAIN_EC2_KEY_PLACEHOLDER" then .server.key = $key else . end)')

# 서버 정보 읽기 및 파일 전송
echo "$configs" | jq -c '.[]' | while IFS= read -r config; do
  file_name=$(echo "$config" | jq -r '.file_name')
  user=$(echo "$config" | jq -r '.server.user')
  host=$(echo "$config" | jq -r '.server.host')
  key=$(echo "$config" | jq -r '.server.key')

  echo "Deploying $file_name to $host as user $user"
  echo "Sending $file_name to $user@$host:/destination/path/"
  scp -i "$key" "$file_name" "$user@$host:/destination/path/"
done
