
TARGET_DIR=$1
LOG_FILE="vault_sweep.log"

if [ -z "$TARGET_DIR" ]; then
    echo "Usage: ./vault_sweep.sh <target_directory>"
    exit 1
fi

touch "$LOG_FILE"
chmod 600 "$LOclaG_FILE"

log() {
    local level=$1
    local msg=$2
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] [$level] $msg" | tee -a "$LOG_FILE"
}

log "INFO" "Starting Vault Sweep on $TARGET_DIR"


find "$TARGET_DIR" -type f -name "*.sh" | while read -r file; do
    if grep -qE "rm -rf /|mkfs|shutdown|reboot|curl.*\|.*sh|wget.*\|.*bash|/dev/tcp/" "$file"; then
        log "WARN" "$file _ Reason: Contains dangerous execution commands."
    fi

    perms=$(ls -l "$file" | awk '{print $1}')
    if [[ "$perms" == *w*w*w* ]] || [[ "${perms:8:1}" == "w" ]]; then
        log "WARN" "$file _ Reason: World write permission detected ($perms)"
        
        read -p "Fix permissions for $file? (yes/no): " fix_perm < /dev/tty
        if [ "$fix_perm" == "yes" ]; then
            chmod o-w "$file"
            log "FIX" "$file removed world write permission"
        fi
    fi
done


find "$TARGET_DIR" -type f -name ".env*" ! -name "*.sanitized" | while read -r env_file; do
    sanitized_file="${env_file}.sanitized"
    > "$sanitized_file"
    
    valid_count=0
    invalid_count=0
    rejected_keys=""

    while IFS= read -r line || [ -n "$line" ]; do
        if [[ -z "$line" ]]; then continue; fi

        if [[ "$line" == *" "*=* ]] || [[ "$line" == *=*" "* ]]; then
            invalid_count=$((invalid_count+1))
            rejected_keys="$rejected_keys $line(spaces)"
            continue
        fi

        key=$(echo "$line" | cut -d'=' -f1)
        value=$(echo "$line" | cut -d'=' -f2-)

        if [[ ! "$key" =~ ^[A-Z_][A-Z0-9_]*$ ]]; then
            invalid_count=$((invalid_count+1))
            rejected_keys="$rejected_keys $key(invalid_chars)"
            continue
        fi

        if [[ "$key" =~ (PASSWORD|SECRET|TOKEN) ]] || [[ "$line" == *"export PATH"* ]]; then
            invalid_count=$((invalid_count+1))
            rejected_keys="$rejected_keys $key(restricted_keyword)"
            continue
        fi

        if [[ "$value" == \"*\" ]]; then
            invalid_count=$((invalid_count+1))
            rejected_keys="$rejected_keys $key(unnecessary_quotes)"
            continue
        fi

        echo "$line" >> "$sanitized_file"
        valid_count=$((valid_count+1))

    done < "$env_file"

    log "INFO" "$env_file Valid: $valid_count, Invalid: $invalid_count"
    if [ "$invalid_count" -gt 0 ]; then
        log "SKIP" "$env_file Rejected:$rejected_keys"
    fi
done


find "$TARGET_DIR" -type f \( -name "*.js" -o -name "*.py" \) | while read -r file; do
    grep -nE "apiKey.*=|sk-[a-zA-Z0-9]{10,}" "$file" | while read -r match; do
        line_no=$(echo "$match" | cut -d':' -f1)
        log "WARN" "$file:$line_no _ Reason: Hardcoded API key found."
    done
done

log "INFO" "Vault Sweep Complete."