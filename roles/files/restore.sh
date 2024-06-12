#!/bin/bash
# ANSI颜色码
GREEN='\033[0;32m'
YELLOW='\033[1;33m' # 黄色
NC='\033[0m' # 恢复默认颜色


localFilePath=$1
oneDriveBackupFolder=$2
client_id=$3
client_secret=$4
tenant_id=$5
backup_soft_name=$6

alist_config_Path='alist/config.json'
alist_data_path='alist/data.db'
alist_composefile_path='alist/docker-compose.yaml'

ddnsgo_config_path='ddns-go/.ddns-go_config.yaml'
ddnsgo_composefile_path='ddns-go/docker-compose.yaml'

semaphore_config_path='semaphore/config.json'
semaphore_database_path='semaphore/database.boltdb'
semaphore_composefile_path='semaphore/docker-compose.yaml'

echo '正在获取授权'
# 使用 curl 发送 POST 请求
response=$(curl --location --request POST "https://login.microsoftonline.com/$tenant_id/oauth2/v2.0/token" \
--header 'Host: login.microsoftonline.com' \
--header 'User-Agent: Apifox/1.0.0 (https://apifox.com)' \
--header 'Content-Type: application/x-www-form-urlencoded' \
--data-urlencode "client_id=$client_id" \
--data-urlencode 'scope=https://graph.microsoft.com/.default' \
--data-urlencode "client_secret=$client_secret" \
--data-urlencode 'grant_type=client_credentials')

# 使用 jq 解析 JSON 并提取 access_token
access_token=$(echo $response | jq -r '.access_token')
# 检查access_token是否为空
if [ -n "$access_token" ]; then
  echo "授权成功"
  # 输出 access_token
    # echo "Access Token: $access_token"
else
  echo -e "${YELLOW}警告：授权失败${NC}"
fi


# localFilePath $1
# oneDriveBackupFolder $2
download(){
    response=$(curl --location --request GET "https://graph.microsoft.com/v1.0/users/me@lvhongyuan.site/drive/root:/$2:/content" \
    --header "Authorization: Bearer $access_token" \
    --header 'User-Agent: Apifox/1.0.0 (https://apifox.com)'
    --output-dir "$1" )
        # 检查响应状态码并输出相应信息
    if [ $response -eq 200 ]; then
    echo "文件下载成功 保存路径 $1"
    if [ $response -eq 404 ]; then
    echo "onedrive $2 文件不存在"
    else
    echo "上传失败，状态码：$response"
    fi
}

# restore alist


echo '开始备份'

case  $backup_soft_name in
    "alist")
        echo "restore alist Backup File"
        # 检查 alist 容器是否在运行
        container=$(docker ps --filter "name=alist" --format "{{.Names}}")
        if [ "$container" == "alist" ]; then
            echo "alist 容器正在运行，停止容器..."
            docker stop alist
            download $localFilePath/$alist_config_Path $oneDriveBackupFolder/$alist_config_Path
            download $localFilePath/$alist_data_path $oneDriveBackupFolder/$alist_data_path
            download $localFilePath/$alist_composefile_path $oneDriveBackupFolder/$alist_composefile_path
            docker start alist
        else
            echo "alist 容器未运行。"
            mkdir -p alist
            download $localFilePath/$alist_config_Path $oneDriveBackupFolder/$alist_config_Path
            download $localFilePath/$alist_data_path $oneDriveBackupFolder/$alist_data_path
            download $localFilePath/$alist_composefile_path $oneDriveBackupFolder/$alist_composefile_path
            docker compose -f $localFilePath/$alist_composefile_path up -d
        fi
        ;;
    "ddns-go")
        # 检查 ddns-go 容器是否在运行
        container=$(docker ps --filter "name=ddns-go" --format "{{.Names}}")
        if [ "$container" == "ddns-go" ]; then
            echo "ddns-go 容器正在运行，停止容器..."
            docker stop ddns-go
            download $localFilePath/$ddnsgo_config_path $oneDriveBackupFolder/$ddnsgo_config_path
            download $localFilePath/$ddnsgo_composefile_path $oneDriveBackupFolder/$ddnsgo_composefile_path
            docker start ddns-go
        else
            echo "ddns-go 容器未运行。"
            mkdir -p ddns-go
            download $localFilePath/$ddnsgo_config_path $oneDriveBackupFolder/$ddnsgo_config_path
            download $localFilePath/$ddnsgo_composefile_path $oneDriveBackupFolder/$ddnsgo_composefile_path
            docker compose -f $localFilePath/$ddnsgo_composefile_path up -d
        fi
        ;;
    "semaphore")
        # 检查 semaphore 容器是否在运行
        container=$(docker ps --filter "name=semaphore" --format "{{.Names}}")
        if [ "$container" == "semaphore" ]; then
            echo "semaphore 容器正在运行，停止容器..."
            docker stop semaphore
            download $localFilePath/$ddnsgo_config_path $oneDriveBackupFolder/$ddnsgo_config_path
            download $localFilePath/$semaphore_composefile_path $oneDriveBackupFolder/$semaphore_composefile_path
            docker start semaphore
        else
            echo "semaphore 容器未运行。"
            mkdir -p semaphore
            download $localFilePath/$ddnsgo_config_path $oneDriveBackupFolder/$ddnsgo_config_path
            download $localFilePath/$semaphore_composefile_path $oneDriveBackupFolder/$semaphore_composefile_path
            docker compose -f $localFilePath/$semaphore_composefile_path up -d
        fi

    *)
        echo "未匹配到任何恢复数据名"
        ;;
  esac




# docker stop alist
# download $localFilePath/$alist_config_Path $oneDriveBackupFolder/$alist_config_Path
# download $localFilePath/$alist_data_path $oneDriveBackupFolder/$alist_data_path
# download $localFilePath/$alist_composefile_path $oneDriveBackupFolder/$alist_composefile_path
# docker start alist

# restore ddns-go





# restore semaphore




# mkdir -p ddns-go
# echo "restore alist Backup File"
# docker stop alist
# download $localFilePath/$ddnsgo_config_path $oneDriveBackupFolder/$ddnsgo_config_path
# download $localFilePath/$semaphore_composefile_path $oneDriveBackupFolder/$semaphore_composefile_path
# docker start alist