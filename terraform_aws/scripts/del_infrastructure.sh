#!/bin/bash
# Получение имени кластера EKS
cluster_name=$(aws eks list-clusters --output text --query 'clusters[0]')

# Получение списка групп узлов для кластера
nodegroup_names=$(aws eks list-nodegroups --cluster-name $cluster_name --output text --query 'nodegroups[]')

# Перебор каждой группы узлов и их удаление
for nodegroup_name in $nodegroup_names; do
    echo "Удаляем группу узлов: $nodegroup_name"
    aws eks delete-nodegroup --cluster-name $cluster_name --nodegroup-name $nodegroup_name
    
    # Ожидание завершения удаления группы узлов
    echo "Ожидаем завершения удаления группы узлов: $nodegroup_name"
    aws eks wait nodegroup-deleted --cluster-name $cluster_name --nodegroup-name $nodegroup_name
    echo "Группа узлов удалена: $nodegroup_name"

    # Удаление узлов в группе
    echo "Удаляем узлы в группе: $nodegroup_name"
    aws ec2 describe-instances --filters "Name=tag:kubernetes.io/cluster/$cluster_name,Values=owned" "Name=tag:k8s.io/cluster-autoscaler/enabled,Values=true" "Name=tag:k8s.io/cluster-autoscaler/node-template/label/k8s.io/cluster-autoscaler/enabled,Values=true" "Name=tag:kubernetes.io/cluster/$cluster_name/node-group/$nodegroup_name,Values=$nodegroup_name" --query 'Reservations[].Instances[].InstanceId' --output text | tr '\t' '\n' | xargs -I {} aws ec2 terminate-instances --instance-ids {}
    echo "Узлы в группе удалены: $nodegroup_name"
done

echo "Все группы узлов и связанные узлы удалены для кластера: $cluster_name"

echo "Ждём 1 минуту"
sleep 60 

#Удаление Load Balancer
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
group_ids=$(aws ec2 describe-security-groups --query 'SecurityGroups[?GroupName!=`default`].[GroupId]' --output text)

# Разбиваем список идентификаторов групп безопасности на отдельные строки
IFS=$'\n' read -rd '' -a group_ids_array <<<"$group_ids"

# Перебираем каждый идентификатор группы безопасности и удаляем его
for group_id in "${group_ids_array[@]}"; do
    if [[ -n "$group_id" ]]; then
        echo "Удаляем группу безопасности: $group_id"
        aws ec2 delete-security-group --group-id "$group_id"
        echo "Группа безопасности удалена: $group_id"
    fi
done

echo "Все группы безопасности, кроме 'default', удалены"