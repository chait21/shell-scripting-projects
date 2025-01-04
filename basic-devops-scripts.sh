#!/bin/bash

# 1. Disk Space Check
check_disk_space() {
    echo "=== Checking Disk Space ==="
    # Check for filesystems using more than 80% space
    df -h | awk '{print $5 " " $6}' | while read -r usage mount; do
        used=${usage%\%}
        if [ "$used" -gt 80 ]; then
            echo "WARNING: $mount is $usage full!"
        fi
    done
}

# 2. Process Memory Usage Check
check_memory_usage() {
    echo "=== Top 5 Memory-Consuming Processes ==="
    ps aux | sort -rn -k 4 | head -5 | awk '{print $4 "% - " $11}'
}

# 3. Log File Size Monitor
check_log_sizes() {
    echo "=== Large Log Files (>100MB) ==="
    find /var/log -type f -size +100M -exec ls -lh {} \;
}

# 4. Service Status Check
check_services() {
    echo "=== Checking Critical Services ==="
    services=("nginx" "docker" "sshd" "mysql")
    
    for service in "${services[@]}"; do
        if systemctl is-active "$service" >/dev/null 2>&1; then
            echo "$service is running"
        else
            echo "WARNING: $service is not running!"
        fi
    done
}

# 5. Network Connection Check
check_network() {
    echo "=== Checking Network Connectivity ==="
    # Check basic connectivity
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        echo "Internet connectivity: OK"
    else
        echo "WARNING: Internet connectivity issues!"
    fi
    
    # Check listening ports
    echo "Listening ports:"
    netstat -tulpn | grep LISTEN
}

# 6. File Cleanup (files older than 7 days)
cleanup_old_files() {
    echo "=== Cleaning Up Old Files ==="
    directory=$1
    if [ -d "$directory" ]; then
        find "$directory" -type f -mtime +7 -exec rm -f {} \;
        echo "Cleaned files older than 7 days in $directory"
    else
        echo "Directory $directory not found!"
    fi
}

# 7. CPU Load Check
check_cpu_load() {
    echo "=== CPU Load Average ==="
    load_avg=$(uptime | awk -F'load average:' '{ print $2 }')
    echo "Current load average: $load_avg"
    
    # Get CPU core count
    cores=$(nproc)
    echo "Number of CPU cores: $cores"
}

# 8. Docker Container Health
check_docker_health() {
    echo "=== Docker Container Status ==="
    docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    # Show stopped containers
    echo -e "\nStopped Containers:"
    docker ps -f "status=exited" --format "{{.Names}}"
}

# 9. Quick System Info
system_info() {
    echo "=== System Information ==="
    echo "Hostname: $(hostname)"
    echo "Kernel: $(uname -r)"
    echo "CPU: $(lscpu | grep 'Model name' | cut -f 2 -d ":")"
    echo "Memory: $(free -h | awk '/^Mem:/ {print $2}')"
    echo "Disk Space: $(df -h / | awk 'NR==2 {print $2}')"
}

# 10. Last Failed SSH Attempts
check_failed_ssh() {
    echo "=== Failed SSH Attempts ==="
    grep "Failed password" /var/log/auth.log | tail -5
}

# 11. Check Server Response Time
check_response_time() {
    url=$1
    echo "=== Checking Response Time for $url ==="
    curl -o /dev/null -s -w "Connect: %{time_connect}s\nTTFB: %{time_starttransfer}s\nTotal: %{time_total}s\n" "$url"
}

# 12. Process Count by User
user_processes() {
    echo "=== Process Count by User ==="
    ps aux | awk '{print $1}' | sort | uniq -c | sort -nr
}

# 13. Find Large Files
find_large_files() {
    directory=${1:-"/"}
    size=${2:-"+100M"}
    echo "=== Finding Files Larger Than $size in $directory ==="
    find "$directory" -type f -size "$size" -exec ls -lh {} \; 2>/dev/null
}

# 14. Check Open File Descriptors
check_file_descriptors() {
    echo "=== Open File Descriptors ==="
    echo "Current open files: $(lsof | wc -l)"
    echo "File descriptor limit: $(ulimit -n)"
}

# 15. Quick Security Check
security_check() {
    echo "=== Basic Security Check ==="
    echo "Last 5 sudo commands:"
    grep sudo /var/log/auth.log | tail -5
    echo -e "\nCurrently logged in users:"
    who
    echo -e "\nOpen SSH sessions:"
    netstat -tnpa | grep 'ESTABLISHED.*sshd'
}

# Main menu for easy usage
show_menu() {
    echo "DevOps Quick Tools Menu:"
    echo "1. Check Disk Space"
    echo "2. Check Memory Usage"
    echo "3. Check Log Sizes"
    echo "4. Check Services"
    echo "5. Check Network"
    echo "6. Clean Old Files"
    echo "7. Check CPU Load"
    echo "8. Check Docker Health"
    echo "9. System Information"
    echo "10. Check Failed SSH Attempts"
    echo "11. Check Response Time"
    echo "12. User Process Count"
    echo "13. Find Large Files"
    echo "14. Check File Descriptors"
    echo "15. Security Check"
    echo "q. Quit"
}

# Script execution
while true; do
    show_menu
    read -r -p "Select an option: " choice
    case $choice in
        1) check_disk_space ;;
        2) check_memory_usage ;;
        3) check_log_sizes ;;
        4) check_services ;;
        5) check_network ;;
        6) read -r -p "Enter directory path: " dir; cleanup_old_files "$dir" ;;
        7) check_cpu_load ;;
        8) check_docker_health ;;
        9) system_info ;;
        10) check_failed_ssh ;;
        11) read -r -p "Enter URL: " url; check_response_time "$url" ;;
        12) user_processes ;;
        13) find_large_files ;;
        14) check_file_descriptors ;;
        15) security_check ;;
        q) exit 0 ;;
        *) echo "Invalid option" ;;
    esac
    echo -e "\nPress Enter to continue..."
    read -r
    clear
done
