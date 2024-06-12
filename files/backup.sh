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

ddnsgo_config_path='ddns-go/.ddns_go_config.yaml'
ddnsgo_composefile_path='ddns-go/docker-compose.yaml'

semaphore_config_path='semaphore/config.json'
semaphore_database_path='semaphore/database.boltdb'
semaphore_composefile_path='semaphore/docker-compose.yaml'

echo "localFilePath $localFilePath"
echo "oneDrivePath $oneDrivePath"
# echo $client_id
# echo $client_secret
# echo $tenant_id


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





urlencode() {
    src_url=$(echo -n "$1" | xxd -plain | tr -d '\n' | sed 's/\(..\)/%\1/g')
    echo $src_url
}

# $1 localFilePath
# $2 oneDrivePath 
upload(){
    echo 上传文件$1 到 oneDrive $2
    response=$(curl --location --request PUT "https://graph.microsoft.com/v1.0/users/me@lvhongyuan.site/drive/root:/$2:/content" \
    --header "Authorization: Bearer $access_token" \
    --header 'User-Agent: Apifox/1.0.0 (https://apifox.com)' \
    --header 'Content-Type: application/octet-stream' \
    --data-binary "@$1" \
    -w "%{http_code}" \
    -o /dev/null)

    # 检查响应状态码并输出相应信息
    if [ $response -eq 200 ]; then
    echo "文件上传成功"
    elif [ $response -eq 201 ]; then
    echo "文件创建成功"
    else
    echo "上传失败，状态码：$response"
    fi
}

echo '开始备份'

case  $backup_soft_name in
    "alist")
        # 上传 alist
        if [[ -e $localFilePath/$alist_config_Path ]]; then
            echo "alist Backup File exists."
            docker stop alist
            upload $localFilePath/$alist_config_Path $(urlencode $oneDriveBackupFolder)/$alist_config_Path
            upload $localFilePath/$alist_data_path $(urlencode $oneDriveBackupFolder)/$alist_data_path
            upload $localFilePath/$alist_composefile_path $(urlencode $oneDriveBackupFolder)/$alist_composefile_path
            docker start alist
        else
            echo -e "${YELLOW}alist Backup File does not exist.${NC}"
            # echo "alist Backup File does not exist."
        fi
        ;;
    "ddns-go")
        # 上传 ddns-go
        if [[ -e $localFilePath/$ddnsgo_config_path ]]; then
            echo "ddns-go Backup File exists."
            # echo $(urlencode $oneDriveBackupFolder/$ddnsgo_config_path)
            # upload $localFilePath/$ddnsgo_config_path $(urlencode $oneDriveBackupFolder/$ddnsgo_config_path)
            # echo $(urlencode $oneDriveBackupFolder)/$ddnsgo_config_path
            # upload $localFilePath/$ddnsgo_config_path $(urlencode $oneDriveBackupFolder)/$ddnsgo_config_path
            upload $localFilePath/$ddnsgo_config_path $(urlencode $oneDriveBackupFolder)/$ddnsgo_config_path
            upload $localFilePath/$ddnsgo_composefile_path $(urlencode $oneDriveBackupFolder)/$ddnsgo_composefile_path
        else
            echo -e "${YELLOW}ddns-go Backup File $localFilePath/$ddnsgo_config_path does not exist.${NC}"
            # echo "ddns-go Backup File does not exist."
        fi
        ;;
    "semaphore")
        # 上传 semaphore
        if [[ -e $localFilePath/$semaphore_config_path ]]; then
            echo "semaphore Backup File exists."
            upload $localFilePath/$semaphore_config_path $(urlencode $oneDriveBackupFolder)/$semaphore_config_path
            upload $localFilePath/$semaphore_database_path $(urlencode $oneDriveBackupFolder)/$semaphore_database_path
            upload $localFilePath/$semaphore_composefile_path $(urlencode $oneDriveBackupFolder)/$semaphore_composefile_path
        else
            echo -e "${YELLOW}semaphore Backup File does not exist.${NC}"
            # echo "semaphore Backup File does not exist."
        fi

        echo '备份完成'
        ;;
    *)
        echo "未匹配到任何备份名"
        ;;
  esac







