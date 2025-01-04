#!/bin/bash

# 1. Log Rotation and Cleanup
# Deletes logs older than 7 days
cleanup_logs() {
    echo "Starting log cleanup process..."
    find /var/log -name "*.log" -type f -mtime +7 -exec rm {} \;
    echo "Log cleanup completed at $(date)"
}

# 2. Docker Container Health Check
check_docker_containers() {
    echo "Checking Docker container health..."
    containers=$(docker ps --format '{{.Names}}')
    
    for container in $containers; do
        status=$(docker inspect --format '{{.State.Status}}' "$container")
        if [ "$status" != "running" ]; then
            echo "WARNING: Container $container is not running. Status: $status"
            # Send alert (example using email)
            echo "Container $container is down!" | mail -s "Docker Alert" admin@example.com
        fi
    done
}

# 3. Database Backup Script
backup_database() {
    BACKUP_DIR="/backup/mysql"
    MYSQL_USER="backup_user"
    MYSQL_PASS="your_password"
    DATE=$(date +%Y%m%d)
    
    # Create backup directory if it doesn't exist
    mkdir -p "$BACKUP_DIR"
    
    # Backup all databases
    mysqldump -u "$MYSQL_USER" -p"$MYSQL_PASS" --all-databases | gzip > "$BACKUP_DIR/full_backup_$DATE.sql.gz"
    
    # Remove backups older than 30 days
    find "$BACKUP_DIR" -name "full_backup_*.sql.gz" -mtime +30 -delete
}

# 4. System Resource Monitoring
monitor_resources() {
    # Set thresholds
    CPU_THRESHOLD=80
    MEMORY_THRESHOLD=90
    DISK_THRESHOLD=85
    
    # Get current usage
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d. -f1)
    MEMORY_USAGE=$(free | grep Mem | awk '{print ($3/$2) * 100}' | cut -d. -f1)
    DISK_USAGE=$(df -h / | tail -n1 | awk '{print $5}' | cut -d% -f1)
    
    # Check and alert
    if [ "$CPU_USAGE" -gt "$CPU_THRESHOLD" ]; then
        echo "High CPU usage: $CPU_USAGE%" | mail -s "CPU Alert" admin@example.com
    fi
    
    if [ "$MEMORY_USAGE" -gt "$MEMORY_THRESHOLD" ]; then
        echo "High memory usage: $MEMORY_USAGE%" | mail -s "Memory Alert" admin@example.com
    fi
    
    if [ "$DISK_USAGE" -gt "$DISK_THRESHOLD" ]; then
        echo "High disk usage: $DISK_USAGE%" | mail -s "Disk Alert" admin@example.com
    fi
}

# 5. Application Deployment Script
deploy_application() {
    APP_NAME="myapp"
    DEPLOY_DIR="/var/www/$APP_NAME"
    BACKUP_DIR="/var/www/backups"
    GIT_REPO="git@github.com:username/$APP_NAME.git"
    
    # Create backup of current version
    if [ -d "$DEPLOY_DIR" ]; then
        echo "Backing up current version..."
        tar -czf "$BACKUP_DIR/$APP_NAME-$(date +%Y%m%d%H%M%S).tar.gz" -C "$DEPLOY_DIR" .
    fi
    
    # Pull latest code
    if [ -d "$DEPLOY_DIR/.git" ]; then
        cd "$DEPLOY_DIR" || exit
        git pull origin master
    else
        git clone "$GIT_REPO" "$DEPLOY_DIR"
    fi
    
    # Install dependencies
    if [ -f "$DEPLOY_DIR/package.json" ]; then
        cd "$DEPLOY_DIR" || exit
        npm install
    fi
    
    # Restart application
    systemctl restart "$APP_NAME"
}

# 6. Log Analysis Script
analyze_logs() {
    LOG_FILE="/var/log/nginx/access.log"
    
    echo "=== Log Analysis Report ==="
    echo "Top 10 IP Addresses:"
    awk '{print $1}' "$LOG_FILE" | sort | uniq -c | sort -nr | head -n 10
    
    echo -e "\nTop 10 Requested URLs:"
    awk '{print $7}' "$LOG_FILE" | sort | uniq -c | sort -nr | head -n 10
    
    echo -e "\nHTTP Status Code Distribution:"
    awk '{print $9}' "$LOG_FILE" | sort | uniq -c | sort -nr
}

# 7. SSL Certificate Monitor
check_ssl_certificates() {
    DOMAINS=("example.com" "api.example.com" "store.example.com")
    THRESHOLD_DAYS=30
    
    for domain in "${DOMAINS[@]}"; do
        expiry_date=$(openssl s_client -connect "$domain":443 -servername "$domain" 2>/dev/null | openssl x509 -noout -enddate | cut -d= -f2)
        expiry_epoch=$(date -d "$expiry_date" +%s)
        current_epoch=$(date +%s)
        days_left=$(( (expiry_epoch - current_epoch) / 86400 ))
        
        if [ "$days_left" -lt "$THRESHOLD_DAYS" ]; then
            echo "Warning: SSL certificate for $domain expires in $days_left days" | 
                mail -s "SSL Certificate Expiry Alert" admin@example.com
        fi
    done
}

# 8. Kubernetes Pod Health Check
check_kubernetes_pods() {
    # Get all pods in non-running state
    problem_pods=$(kubectl get pods --all-namespaces | grep -v "Running" | grep -v "Completed")
    
    if [ -n "$problem_pods" ]; then
        echo "Problem pods found:"
        echo "$problem_pods"
        
        # Send alert
        echo "$problem_pods" | mail -s "Kubernetes Pod Alert" admin@example.com
    fi
}

# 9. AWS Resource Cleanup
cleanup_aws_resources() {
    # List and terminate stopped EC2 instances older than 30 days
    OLD_INSTANCES=$(aws ec2 describe-instances \
        --filters "Name=instance-state-name,Values=stopped" \
        --query 'Reservations[].Instances[?LaunchTime<=`'$(date -d '30 days ago' --iso-8601=seconds)'`].InstanceId' \
        --output text)
    
    for instance in $OLD_INSTANCES; do
        echo "Terminating instance: $instance"
        aws ec2 terminate-instances --instance-ids "$instance"
    done
    
    # Delete unattached EBS volumes
    UNATTACHED_VOLUMES=$(aws ec2 describe-volumes \
        --filters "Name=status,Values=available" \
        --query 'Volumes[].VolumeId' \
        --output text)
    
    for volume in $UNATTACHED_VOLUMES; do
        echo "Deleting volume: $volume"
        aws ec2 delete-volume --volume-id "$volume"
    done
}

# 10. Continuous Integration Helper
run_ci_checks() {
    echo "Running CI checks..."
    
    # Run unit tests
    if ! npm test; then
        echo "Unit tests failed!"
        exit 1
    fi
    
    # Run linter
    if ! npm run lint; then
        echo "Linting failed!"
        exit 1
    fi
    
    # Run security scan
    if ! npm audit; then
        echo "Security audit failed!"
        exit 1
    fi
    
    # Build application
    if ! npm run build; then
        echo "Build failed!"
        exit 1
    fi
    
    echo "All CI checks passed successfully!"
}

# Usage example:
case "$1" in
    "cleanup-logs")
        cleanup_logs
        ;;
    "check-docker")
        check_docker_containers
        ;;
    "backup-db")
        backup_database
        ;;
    "monitor")
        monitor_resources
        ;;
    "deploy")
        deploy_application
        ;;
    "analyze-logs")
        analyze_logs
        ;;
    "check-ssl")
        check_ssl_certificates
        ;;
    "check-k8s")
        check_kubernetes_pods
        ;;
    "cleanup-aws")
        cleanup_aws_resources
        ;;
    "ci-checks")
        run_ci_checks
        ;;
    *)
        echo "Usage: $0 {cleanup-logs|check-docker|backup-db|monitor|deploy|analyze-logs|check-ssl|check-k8s|cleanup-aws|ci-checks}"
        exit 1
        ;;
esac
