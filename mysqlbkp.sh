#!/bin/sh

scriptsDir=`pwd`  # 定义脚本目录
mysqlDir=/usr/local/mysql  # 定义数据库目录
user=root  # 定义用于备份数据库的用户名和密码
userPWD=111111
dataBackupDir=/tmp/mysqlbackup  # 定义备份目录
eMailFile=$dataBackupDir/email.txt  # 定义邮件正文文件
eMail=alter@somode.com  # 定义邮件地址
logFile=$dataBackupDir/mysqlbackup.log  # 定义备份日志文件
DATE=`date -I`

echo "" > $eMailFile
echo $(date +"%y-%m-%d %H:%M:%S") >> $eMailFile
cd $dataBackupDir

dumpFile=mysql_$DATE.sql  # 定义备份文件名
GZDumpFile=mysql_$DATE.sql.tar.gz

$mysqlDir/bin/mysqldump -u$user -p$userPWD \
--opt --default-character-set=utf8 --extended-insert=false \
--triggers -R --hex-blob --all-databases \
--flush-logs --delete-master-logs \
--delete-master-logs \
-x > $dumpFile   # 使用mysqldump备份数据库，请根据具体情况设置参数

if [[ $? == 0 ]]; then
tar czf $GZDumpFile $dumpFile >> $eMailFile 2>&1
echo "BackupFileName:$GZDumpFile" >> $eMailFile
echo "DataBase Backup Success!" >> $eMailFile
rm -f $dumpFile   # 压缩备份文件

cd $dataBackupDir/daily
rm -f *   # Delete daily backup files.

$scriptsDir/rmBackup.sh  # Delete old backup files(mtime>2).

# 如果不需要将备份传送到备份服务器，请将标绿的行注释掉
# Move Backup Files To Backup Server. 适合Linux（MySQL服务器）到Linux（备份服务器）
#   $scriptsDir/rsyncBackup.sh
#  if (( !$? )); then
#  echo "Move Backup Files To Backup Server Success!" >> $eMailFile
#  else
#  echo "Move Backup Files To Backup Server Fail!" >> $eMailFile
#  fi

else
echo "DataBase Backup Fail!" >> $emailFile
fi

echo "------------------------" >> $logFile
cat $eMailFile >> $logFile  # 写日志文件

cat $eMailFile | mail -s "MySQL Backup" $eMail   # 发送邮件通知
