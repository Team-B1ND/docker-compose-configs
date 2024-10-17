# yq 바이너리 다운로드 및 설치
mkdir -p $HOME/bin
YQ_VERSION="v4.34.1"  # 원하는 yq 버전으로 설정
echo "Downloading yq for AMD architecture"
curl -L -o $HOME/bin/yq "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64"
chmod +x $HOME/bin/yq
echo "$HOME/bin" >> $GITHUB_PATH  # $HOME/bin을 PATH에 추가

# YAML 파일을 JSON으로 변환
servers=$($HOME/bin/yq eval '.servers' .deploy/config.yml)
echo "::set-output name=servers::$servers"

# SSH 비공개 키를 임시 파일로 저장
echo "${SSH_PRIVATE_KEY}" > private_key
chmod 600 private_key

# 서버 정보 읽기 및 파일 전송
for server in $(echo "${servers}" | jq -c '.[]'); do
  name=$(echo "$server" | jq -r '.name')
  ip=$(echo "$server" | jq -r '.ip')
  user=$(echo "$server" | jq -r '.user')
  files=$(echo "$server" | jq -r '.files | join(" ")')
  echo "Deploying files to $name ($ip) as user $user"
  
  # 파일 전송
  for file in $files; do
    echo "Sending $file to $user@$ip:/destination/path/"
    scp -i private_key "$file" "$user@$ip:/destination/path/"
  done
done
