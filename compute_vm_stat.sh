#!/bin/bash

numa_zero_vcpu=0
numa_one_vcpu=0
#numa_zero_mem=0
#numa_one_mem=0

total_vcpu=$(($(lscpu | grep -i 'Core(s) per socket'|awk '{print $4}')*$(lscpu | grep -i 'Socket(s)'|awk '{print $2}')))
vcpu_node=$(lscpu | grep -i 'Core(s) per socket'|awk '{print $4}')
#echo $total_vcpu

show_vnf() {
vm_name=$1;
nova_name=$(sudo virsh dumpxml $vm_name|grep 'nova:name');
#echo $nova_name;
echo $nova_name|cut -d '>' -f2|cut -d '<' -f1;}

get_num_vcpus () {
vm=$1
num_vcpu=$(sudo virsh dumpxml ${vm} | grep 'nova:vcpus')
echo "CPUs:" && echo $num_vcpu|cut -d '<' -f2|cut -d '>' -f2
#echo $num_vcpu|cut -d '<' -f2|cut -d '>' -f2
}

get_cpu_list () {
vm=$i
vcpu_list=$(sudo virsh dumpxml ${vm} | grep 'vcpu='|awk '{print $3}'|cut -d'=' -f2 |cut -d '/' -f1)
echo $vcpu_list
}

show_vnf_memory () {
vm=$1
nova_mem=$(sudo virsh dumpxml ${vm} |grep 'nova:memory')
echo "Memory:"
echo $nova_mem|cut -d '>' -f2|cut -d '<' -f1;
echo "VM Page Size:"
echo $(sudo virsh dumpxml ${vm} |grep 'page size')
echo $(sudo virsh dumpxml ${vm} |grep 'memory mode')
}

show_vnf_numa_node () {
vm=$i    

numa_zero_vcpu=$numa_zero_vcpu
numa_one_vcpu=$numa_one_vcpu
#numa_zero_mem=$numa_zero_mem
#numa_one_mem=$numa_one_mem

vcpu=$(sudo virsh dumpxml ${vm} | grep -m1 'vcpu='|awk '{print $3}'|cut -d'=' -f2 |cut -d '/' -f1)
eval vcpu=$vcpu
#nova_mem=$(sudo virsh dumpxml ${vm} |grep 'nova:memory'|cut -d '>' -f2|cut -d '<' -f1)

if ((vcpu_node==20));then
  
  if (( vcpu >= 0 && vcpu <= 19 ));then
    echo "VM Numa Node is 0"
    vcpu=$(sudo virsh dumpxml ${vm} | grep 'nova:vcpus'|cut -d '<' -f2|cut -d '>' -f2)
    numa_zero_vcpu=$(($numa_zero_vcpu+$vcpu))
    #numa_zero_mem=$(($numa_zero_mem+$nova_mem))
  elif (( vcpu >= 40 && vcpu <= 59 ));then
   echo "VM Numa Node is 0"
    vcpu=$(sudo virsh dumpxml ${vm} | grep 'nova:vcpus'|cut -d '<' -f2|cut -d '>' -f2)
    numa_zero_vcpu=$(($numa_zero_vcpu+$vcpu))
    #numa_zero_mem=$(($numa_zero_mem+$nova_mem))
  elif (( vcpu >= 20 && vcpu <= 39 ));then
    echo "VM Numa Node is 1"
    vcpu=$(sudo virsh dumpxml ${vm} | grep 'nova:vcpus'|cut -d '<' -f2|cut -d '>' -f2)
    numa_zero_vcpu=$(($numa_zero_vcpu+$vcpu))
    #numa_zero_mem=$(($numa_zero_mem+$nova_mem))
  else
    echo "VM Numa Node is 1"
    vcpu=$(sudo virsh dumpxml ${vm} | grep 'nova:vcpus'|cut -d '<' -f2|cut -d '>' -f2)
    numa_zero_vcpu=$(($numa_zero_vcpu+$vcpu))
    #numa_zero_mem=$(($numa_zero_mem+$nova_mem))
  fi
elif ((vcpu_node==18)); then
 
  if (( vcpu >= 0 && vcpu <= 17 ));then
    echo "VM Numa Node is 0"
    vcpu=$(sudo virsh dumpxml ${vm} | grep 'nova:vcpus'|cut -d '<' -f2|cut -d '>' -f2)
    numa_zero_vcpu=$(($numa_zero_vcpu+$vcpu))
    #numa_zero_mem=$(($numa_zero_mem+$nova_mem))
  elif (( vcpu >= 36 && vcpu <= 53 ));then
    echo "VM Numa Node is 0"
    vcpu=$(sudo virsh dumpxml ${vm} | grep 'nova:vcpus'|cut -d '<' -f2|cut -d '>' -f2)
    numa_zero_vcpu=$(($numa_zero_vcpu+$vcpu))
    #numa_zero_mem=$(($numa_zero_mem+$nova_mem))
  elif (( vcpu >= 18 && vcpu <= 35 ));then
    echo "VM Numa Node is 1"
    vcpu=$(sudo virsh dumpxml ${vm} | grep 'nova:vcpus'|cut -d '<' -f2|cut -d '>' -f2)
    numa_zero_vcpu=$(($numa_zero_vcpu+$vcpu))
    #numa_zero_mem=$(($numa_zero_mem+$nova_mem))
  else
    echo "VM Numa Node is 1"
    vcpu=$(sudo virsh dumpxml ${vm} | grep 'nova:vcpus'|cut -d '<' -f2|cut -d '>' -f2)
    numa_zero_vcpu=$(($numa_zero_vcpu+$vcpu))
    #numa_zero_mem=$(($numa_zero_mem+$nova_mem))
  fi
else
  echo "NUMA Configuration Unknown"
fi
}



for i in $(sudo virsh list --all|grep running|awk '{print $1}'); do show_vnf ${i} && get_num_vcpus ${i} && get_cpu_list ${i} && show_vnf_memory ${i} &&  show_vnf_numa_node ${i} &&  echo -e "\n"; done


free_numa_zero_vcpu=$(($total_vcpu - $numa_zero_vcpu))
free_numa_one_vcpu=$(($total_vcpu - $numa_one_vcpu))

echo "Free NUMA 0 VCPUs:" 
echo $free_numa_zero_vcpu
echo "Free NUMA 1 VCPUs:"
echo $free_numa_one_vcpu

echo "Free NUMA 0 Memory:"
echo $(numactl -H | grep -i "node 0 free" |awk '{print $4}')
echo "Free NUMA 1 Memory:"
echo $(numactl -H | grep -i "node 1 free" |awk '{print $4}')

echo -e "\n"

echo "Hugepages"
echo $(cat /sys/devices/system/node/node*/meminfo | grep -i hugepages_total)
echo $(cat /sys/devices/system/node/node*/meminfo | grep -i hugepages_free)
echo $(cat /sys/devices/system/node/node*/meminfo | grep -i hugepages_surp)
echo "Hugepage Size"
echo $(grep Hugepagesize /proc/meminfo)

echo -e "\n"
