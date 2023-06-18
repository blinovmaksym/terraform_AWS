#!/bin/bash

Удаление Load Balancer
for elb_name in $(aws elb describe-load-balancers --query 'LoadBalancerDescriptions[].LoadBalancerName' --output text); do
  echo "Удаляем Load Balancer: $elb_name"
  aws elb delete-load-balancer --load-balancer-name "$elb_name"
  echo "Load Balancer удален: $elb_name"
done

echo "Ждём 1 минуту"
sleep 60 

# Получение списка всех NAT Gateway
nat_ids=$(aws ec2 describe-nat-gateways --query 'NatGateways[].NatGatewayId' --output text)
# Удаление каждого NAT Gateway
for nat_id in $nat_ids; do
    echo "Удаляем NAT Gateway: $nat_id"
    aws ec2 delete-nat-gateway --nat-gateway-id "$nat_id"
    echo "NAT Gateway удален: $nat_id"
done

echo "Ждём 1 минуту"
sleep 60 


# Получаем список идентификаторов сетевых интерфейсов, связанных со всеми группами безопасности
interface_ids=$(aws ec2 describe-network-interfaces --query 'NetworkInterfaces[].NetworkInterfaceId' --output text)
# Отключаем сетевые интерфейсы от экземпляров EC2
for interface_id in $interface_ids; do
    echo "Отключаем сетевой интерфейс от экземпляров EC2: $interface_id"
    aws ec2 detach-network-interface --attachment-id "$(aws ec2 describe-network-interfaces --network-interface-ids "$interface_id" --query 'NetworkInterfaces[].Attachment.AttachmentId' --output text)"
    echo "Сетевой интерфейс отключен: $interface_id"
done

echo "Ждём 1 минуту"
sleep 60 

# Удаляем каждый сетевой интерфейс
for interface_id in $interface_ids; do
    echo "Удаляем сетевой интерфейс: $interface_id"
    aws ec2 delete-network-interface --network-interface-id "$interface_id"
    echo "Сетевой интерфейс удален: $interface_id"
done

echo "Ждём 1 минуту"
sleep 60 
#Получаем список идентификаторов групп безопасности, кроме группы по умолчанию
group_ids=$(aws ec2 describe-security-groups --query 'SecurityGroups[?GroupName!=`default`].[GroupId]' --output text)

# Перебираем каждый идентификатор группы безопасности и удаляем его
for group_id in $group_ids; do
    if [[ -n "$group_id" ]]; then
        echo "Удаляем группу безопасности: $group_id"
        aws ec2 delete-security-group --group-id "$group_id"
        echo "Группа безопасности удалена: $group_id"
    fi
done

echo "Все группы безопасности, кроме 'default', удалены"








#test1
# # Получаем список идентификаторов групп безопасности, кроме группы по умолчанию
# group_ids=$(aws ec2 describe-security-groups --query 'SecurityGroups[?GroupName!=`default`].[GroupId]' --output text)

# # Перебираем каждый идентификатор группы безопасности и удаляем его
# echo "$group_ids" | while IFS= read -r group_id; do
#     if [[ -n "$group_id" ]]; then
#         echo "Удаляем группу безопасности: $group_id"
#         aws ec2 delete-security-group --group-id "$group_id"
#         echo "Группа безопасности удалена: $group_id"
#     fi
# done
# echo "Все группы безопасности удалены"





