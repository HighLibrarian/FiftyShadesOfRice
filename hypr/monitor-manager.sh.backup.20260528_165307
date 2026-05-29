#!/bin/bash
# Hyprland Monitor Manager - Integrated display configuration and lid management
# Combines automatic monitor detection with lid-state monitoring

CONFIG_FILE="$HOME/.config/hypr/monitors.conf"
LOG_FILE="/tmp/monitor-manager.log"
INHIBIT_LOCK_FILE="/tmp/monitor-manager-inhibit.lock"

# Monitoring settings
MONITOR_CHECK_INTERVAL=2  # Check monitors every 2 seconds
LID_CHECK_INTERVAL=0.5    # Check lid every 0.5 seconds (more responsive)
DEBOUNCE_DELAY=1          # Wait 1 second after change before applying config
MAX_RETRIES=3             # Max retries for failed configurations
ENABLE_NOTIFICATIONS=true # Show notifications for monitor events
NOTIFICATION_LEVEL="smart" # silent, minimal, smart, verbose
NOTIFICATION_COOLDOWN=300  # 5 minutes cooldown for repeated notifications

# Notification history tracking
declare -gA NOTIFICATION_HISTORY

# These will be loaded from config file
# Declare as global associative array
declare -gA MONITOR_CONFIGS
INTERNAL_MONITOR=""
INTERNAL_CONFIG=""
LID_STATE_FILE=""
AUTO_SWITCH_PROFILE="false"  # Can be overridden in config file

# ============================================================================
# Configuration Loading
# ============================================================================

# Safely parse configuration file without executing arbitrary code
load_config_safely() {
    local config_file="$1"
    
    if [ ! -f "$config_file" ]; then
        return 1
    fi
    
    # Read config line by line, parsing only safe variable assignments
    while IFS= read -r line || [ -n "$line" ]; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue
        
        # Parse associative array assignments: MONITOR_CONFIGS["key"]="value"
        # Do this first to avoid confusion with simple variable assignments
        if [[ "$line" =~ ^[[:space:]]*MONITOR_CONFIGS\[\"([^\"]+)\"\]=\"(.*)\"[[:space:]]*$ ]]; then
            local key="${BASH_REMATCH[1]}"
            local value="${BASH_REMATCH[2]}"
            MONITOR_CONFIGS["$key"]="$value"
        # Parse variable assignments (VARIABLE="value")
        # Use a more flexible regex that captures everything between quotes
        elif [[ "$line" =~ ^[[:space:]]*([A-Z_][A-Z0-9_]*)=\"([^\"]*)\"[[:space:]]*$ ]]; then
            local var_name="${BASH_REMATCH[1]}"
            local var_value="${BASH_REMATCH[2]}"
            
            # Set the variable based on its name
            case "$var_name" in
                INTERNAL_MONITOR|INTERNAL_CONFIG|LID_STATE_FILE|AUTO_SWITCH_PROFILE)
                    # Simple string variables
                    declare -g "$var_name"="$var_value"
                    ;;
                *)
                    # Unknown variable - skip for safety
                    ;;
            esac
        fi
    done < "$config_file"
    
    return 0
}

load_machine_config() {
    local hostname=$(hostname)
    local config_dir="$HOME/.config/hypr/monitor-configs"
    local machine_config="$config_dir/$hostname.conf"
    local default_config="$config_dir/default.conf"
    
    # Try machine-specific config first, then default
    if [ -f "$machine_config" ]; then
        log "Loading configuration for: $hostname"
        load_config_safely "$machine_config"
        return 0
    elif [ -f "$default_config" ]; then
        log "Loading default configuration (no machine-specific config found)"
        load_config_safely "$default_config"
        return 0
    else
        log "ERROR: No configuration file found!"
        log "Expected: $machine_config or $default_config"
        return 1
    fi
}

# ============================================================================
# Utility Functions
# ============================================================================

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $*" | tee -a "$LOG_FILE"
}

notify() {
    local title="$1"
    local message="$2"
    local urgency="${3:-normal}"  # low, normal, critical
    local icon="${4:-video-display}"
    local notification_type="${5:-normal}"  # critical, important, normal, verbose
    local timeout="${6:-0}"  # Timeout in milliseconds, 0 = default
    
    if [ "$ENABLE_NOTIFICATIONS" != true ]; then
        return 0
    fi
    
    # Check notification level
    case "$NOTIFICATION_LEVEL" in
        silent)
            # Only critical notifications
            [ "$notification_type" != "critical" ] && return 0
            ;;
        minimal)
            # Only critical and important
            [[ ! "$notification_type" =~ ^(critical|important)$ ]] && return 0
            ;;
        smart)
            # Skip verbose, check cooldown for normal
            [ "$notification_type" = "verbose" ] && return 0
            
            # For normal notifications, check cooldown
            if [ "$notification_type" = "normal" ]; then
                local notify_key="${title}:${message}"
                local current_time=$(date +%s)
                local last_time=${NOTIFICATION_HISTORY[$notify_key]:-0}
                local elapsed=$((current_time - last_time))
                
                if [ $elapsed -lt $NOTIFICATION_COOLDOWN ]; then
                    log "Notification suppressed (cooldown): $title"
                    return 0
                fi
                
                NOTIFICATION_HISTORY[$notify_key]=$current_time
            fi
            ;;
        verbose)
            # Show all notifications
            ;;
    esac
    
    # Send notification with timeout
    if [ "$timeout" -gt 0 ]; then
        notify-send -u "$urgency" -i "$icon" -t "$timeout" "$title" "$message" 2>/dev/null || true
    else
        notify-send -u "$urgency" -i "$icon" "$title" "$message" 2>/dev/null || true
    fi
    log "Notification: $title - $message"
}

get_lid_state() {
    if [ -f "$LID_STATE_FILE" ]; then
        cat "$LID_STATE_FILE" | awk '{print $2}'
    else
        echo "open"
    fi
}

get_connected_monitors() {
    hyprctl monitors -j | jq -r '.[] | "\(.name)|\(.description)"'
}

get_monitors_hash() {
    # Create a stable hash of monitor configuration for comparison
    get_connected_monitors | sort | md5sum | awk '{print $1}'
}

get_monitor_names() {
    # Get just the monitor names (for comparison)
    hyprctl monitors -j | jq -r '.[].name' | sort
}

get_external_monitor_names() {
    # Get external monitor names (excluding internal and other internal outputs)
    # Only count monitors connected via external ports: HDMI, DP, DisplayPort
    hyprctl monitors -j | jq -r '.[] | select(.name != "'$INTERNAL_MONITOR'" and (.name | test("^(HDMI|DP|DisplayPort)"))) | .name' | sort
}

get_external_monitor_info() {
    # Get the first external monitor (not internal, only external ports)
    # Only count monitors connected via external ports: HDMI, DP, DisplayPort
    hyprctl monitors -j | jq -r '.[] | select(.name != "'$INTERNAL_MONITOR'" and (.name | test("^(HDMI|DP|DisplayPort)"))) | "\(.name)|\(.description)"' | head -n1
}

get_all_external_monitors_info() {
    # Get ALL external monitors (not just the first one)
    # Only count monitors connected via external ports: HDMI, DP, DisplayPort
    hyprctl monitors -j | jq -r '.[] | select(.name != "'$INTERNAL_MONITOR'" and (.name | test("^(HDMI|DP|DisplayPort)"))) | "\(.name)|\(.description)"'
}

manage_suspend_inhibit() {
    local lid_state="$1"
    local external_info=$(get_external_monitor_info)

    # Inhibit suspend ONLY if an external monitor is connected AND the lid is closed.
    if [ -n "$external_info" ] && [ "$lid_state" = "closed" ]; then
        if [ ! -f "$INHIBIT_LOCK_FILE" ]; then
            log "Lid closed with external monitor - inhibiting suspend"
            systemd-inhibit --what=handle-lid-switch --who="monitor-manager" \
                --why="External monitor connected and lid is closed" --mode=block \
                sleep infinity &
            echo $! > "$INHIBIT_LOCK_FILE"
        fi
    else
        # Otherwise, ensure the inhibit lock is removed.
        # This covers: no external monitor, OR external monitor present but lid is open.
        if [ -f "$INHIBIT_LOCK_FILE" ]; then
            log "Condition for suspend inhibit not met, ensuring inhibit lock is removed"
            local inhibit_pid=$(cat "$INHIBIT_LOCK_FILE" 2>/dev/null)
            if [ -n "$inhibit_pid" ] && kill -0 "$inhibit_pid" 2>/dev/null; then
                kill "$inhibit_pid" 2>/dev/null
            fi
            rm -f "$INHIBIT_LOCK_FILE"
        fi
    fi
}

# ============================================================================
# Display Configuration Functions
# ============================================================================

configure_internal_only() {
    log "Configuring internal display only"
    hyprctl keyword monitor "$INTERNAL_MONITOR,$INTERNAL_CONFIG" >/dev/null 2>&1
}

configure_external_monitor() {
    local monitor_name="$1"
    local monitor_desc="$2"
    local send_notification="${3:-false}"  # Optional parameter, default false
    local retries=0
    
    # Try to match the monitor description with known configs
    for desc_pattern in "${!MONITOR_CONFIGS[@]}"; do
        if [[ "$monitor_desc" == *"$desc_pattern"* ]]; then
            local config="${MONITOR_CONFIGS[$desc_pattern]}"
            IFS=',' read -r location resolution position scale <<< "$config"
            
            log "Detected $location monitor: $desc_pattern"
            log "Configuring $monitor_name: $resolution at $position, scale $scale"
            
            # No notification needed here - already handled in daemon_mode
            
            # Try configuration with retries
            while [ $retries -lt $MAX_RETRIES ]; do
                if hyprctl keyword monitor "$monitor_name,$resolution,$position,$scale" >/dev/null 2>&1; then
                    log "Configuration applied successfully"
                    notify "✓ Display Configured" "$monitor_name configured at ${resolution}" "low" "video-display" "verbose"
                    return 0
                fi
                retries=$((retries + 1))
                log "Configuration attempt $retries failed, retrying..."
                sleep 0.5
            done
            log "ERROR: Failed to configure monitor after $MAX_RETRIES attempts"
            notify "⚠️ Configuration Failed" "Failed to configure $monitor_name" "critical" "dialog-error" "critical"
            return 1
        fi
    done
    
    # Fallback: use preferred settings for unknown monitor
    log "Unknown external monitor, using auto configuration"
    log "Monitor: $monitor_desc"
    
    # Apply automatic configuration
    hyprctl keyword monitor "$monitor_name,preferred,auto,auto" >/dev/null 2>&1
    
    # Notification for unknown monitor is handled in daemon_mode
    log "TIP: Run wizard to configure this monitor: hmonitor wizard"
    
    return 0
}

update_display_configuration() {
    local lid_state="$1"
    local send_notification="${2:-false}"  # Optional parameter: whether to send notifications
    
    # Manage suspend inhibit based on external monitor and lid state
    manage_suspend_inhibit "$lid_state"
    
    # Get all external monitors (not just the first one)
    local all_external_monitors=$(get_all_external_monitors_info)
    
    if [ -n "$all_external_monitors" ]; then
        # One or more external monitors are connected
        log "Configuring $(echo "$all_external_monitors" | wc -l) external monitor(s)"
        
        # Configure each external monitor
        while IFS='|' read -r ext_name ext_desc; do
            if [ -n "$ext_name" ]; then
                log "Configuring external monitor: $ext_name"
                configure_external_monitor "$ext_name" "$ext_desc" "$send_notification"
            fi
        done <<< "$all_external_monitors"
        
        # Handle internal display based on lid state
        if [ "$lid_state" = "closed" ]; then
            log "Lid closed with external monitor(s) - disabling internal display"
            hyprctl keyword monitor "$INTERNAL_MONITOR,disable" >/dev/null 2>&1
        else
            log "Lid open with external monitor(s) - enabling internal display"
            hyprctl keyword monitor "$INTERNAL_MONITOR,$INTERNAL_CONFIG" >/dev/null 2>&1
        fi
    else
        # No external monitor, always enable internal
        if [ "$lid_state" = "closed" ]; then
            log "Lid closed without external monitor - system will suspend normally"
            configure_internal_only
        else
            log "Lid open, no external monitor - using internal display"
            configure_internal_only
        fi
    fi
}

# ============================================================================
# Monitor Daemon Mode - Helper Functions
# ============================================================================

# Find and return a matching profile for the given monitor description
find_matching_profile() {
    local monitor_desc="$1"
    local profile_dir="$HOME/.config/hypr/monitor-configs/profiles"
    
    if [ ! -d "$profile_dir" ]; then
        return 1
    fi
    
    # Check each profile to see if it matches
    for profile_file in "$profile_dir"/*.conf; do
        if [ -f "$profile_file" ]; then
            # Check if the profile contains this monitor
            if grep -q "$monitor_desc" "$profile_file" 2>/dev/null; then
                basename "$profile_file" .conf
                return 0
            fi
        fi
    done
    
    return 1
}

# Switch to a specific profile
switch_to_profile() {
    local profile_name="$1"
    local hostname=$(hostname)
    local config_dir="$HOME/.config/hypr/monitor-configs"
    local current_config="$config_dir/$hostname.conf"
    local profile_file="$config_dir/profiles/$profile_name.conf"
    
    if [ ! -f "$profile_file" ]; then
        log "ERROR: Profile file not found: $profile_file"
        return 1
    fi
    
    cp "$profile_file" "$current_config"
    ln -sf "$profile_file" "$config_dir/profiles/.current"
    log "Switched to profile: $profile_name"
    
    # Reload configuration
    if load_machine_config; then
        log "Configuration reloaded from profile: $profile_name"
        return 0
    else
        log "ERROR: Failed to reload configuration after profile switch"
        return 1
    fi
}

# Send monitor connection/disconnection notification
send_monitor_notification() {
    local event_type="$1"  # connected, disconnected, changed
    local monitor_desc="$2"
    local matched_profile="$3"
    
    case "$event_type" in
        connected)
            if [ -n "$matched_profile" ]; then
                notify "✅ Profile Loaded" "Switched to '$matched_profile' profile" "low" "video-display" "important" "3000"
            else
                # Unknown monitor - suggest wizard with longer display time
                local short_desc=$(echo "$monitor_desc" | cut -c1-40)
                notify "🆕 New Monitor Detected" "$short_desc...\n\nRun wizard to configure:\nhmonitor wizard" "normal" "video-display" "important" "15000"
            fi
            ;;
        disconnected)
            notify "🔌 Monitor Disconnected" "External display disconnected" "low" "video-display" "important" "3000"
            ;;
        changed)
            notify "🔄 Display Changed" "Monitor configuration changed" "low" "video-display" "important" "3000"
            ;;
    esac
}

# Handle monitor connection/disconnection events
handle_monitor_change() {
    local last_external_monitors="$1"
    local current_external_monitors="$2"
    local monitor_connected=false
    
    if [ -z "$last_external_monitors" ] && [ -n "$current_external_monitors" ]; then
        # Monitor connected
        monitor_connected=true
        
        # Get current external monitor info for matching
        local current_ext_info=$(get_external_monitor_info)
        if [ -n "$current_ext_info" ]; then
            local ext_desc=$(echo "$current_ext_info" | cut -d'|' -f2)
            
            # Try to find matching profile
            local matched_profile=$(find_matching_profile "$ext_desc")
            
            if [ -n "$matched_profile" ]; then
                log "Detected monitor matches profile: $matched_profile"
                switch_to_profile "$matched_profile"
            fi
            
            # Send notification
            send_monitor_notification "connected" "$ext_desc" "$matched_profile"
        fi
        
    elif [ -n "$last_external_monitors" ] && [ -z "$current_external_monitors" ]; then
        # All monitors disconnected
        send_monitor_notification "disconnected" "" ""
        
    elif [ "$last_external_monitors" != "$current_external_monitors" ]; then
        # Monitor list changed
        send_monitor_notification "changed" "" ""
    fi
    
    echo "$monitor_connected"
}

# ============================================================================
# Monitor Daemon Mode
# ============================================================================

daemon_mode() {
    log "Starting monitor manager daemon"
    
    # Check if daemon is already running and kill it
    # Match both "hmonitor daemon" and "monitor-manager.sh daemon"
    # Use BASHPID to get the actual PID of the current subshell/process
    local current_pid=$BASHPID
    local existing_pids=$(pgrep -f "(hmonitor|monitor-manager.sh).*daemon")
    
    if [ -n "$existing_pids" ]; then
        for pid in $existing_pids; do
            # Skip current process and parent process
            if [ "$pid" != "$current_pid" ] && [ "$pid" != "$$" ] && [ "$pid" != "$PPID" ]; then
                log "Found existing daemon (PID: $pid), stopping it..."
                kill "$pid" 2>/dev/null
            fi
        done
        sleep 1
        # Force kill any remaining processes
        for pid in $existing_pids; do
            if [ "$pid" != "$current_pid" ] && [ "$pid" != "$$" ] && [ "$pid" != "$PPID" ] && kill -0 "$pid" 2>/dev/null; then
                log "Force killing daemon (PID: $pid)"
                kill -9 "$pid" 2>/dev/null
            fi
        done
        log "Old daemon(s) stopped, starting new daemon"
    fi
    
    # Clean up stale lock files from previous abnormal exits
    if [ -f "$INHIBIT_LOCK_FILE" ]; then
        local stale_pid=$(cat "$INHIBIT_LOCK_FILE" 2>/dev/null)
        if [ -n "$stale_pid" ]; then
            # Check if the process is still running
            if ! kill -0 "$stale_pid" 2>/dev/null; then
                log "Cleaning up stale lock file (PID $stale_pid no longer exists)"
                rm -f "$INHIBIT_LOCK_FILE"
            else
                log "Lock file exists with active PID $stale_pid"
            fi
        fi
    fi
    
    # Check if this is first-time setup
    local hostname=$(hostname)
    local config_dir="$HOME/.config/hypr/monitor-configs"
    local machine_config="$config_dir/$hostname.conf"
    
    if [ ! -f "$machine_config" ] && [ ! -f "$config_dir/default.conf" ]; then
        log "First-time setup detected - no configuration found"
        notify "👋 Welcome to Hyprland Monitor Manager!" "No configuration found.\nRun: hmonitor wizard" "normal" "dialog-information" "important" "10000"
        echo ""
        echo "╔═══════════════════════════════════════════════════════════╗"
        echo "║      Welcome to Hyprland Monitor Manager! 👋             ║"
        echo "╚═══════════════════════════════════════════════════════════╝"
        echo ""
        echo "It looks like this is your first time running hmonitor."
        echo "Let's set up your monitor configuration!"
        echo ""
        echo "Please run the configuration wizard:"
        echo "  hmonitor wizard"
        echo ""
        echo "Or create a config file manually at:"
        echo "  $machine_config"
        echo ""
        exit 1
    fi
    
    # Load machine-specific configuration
    if ! load_machine_config; then
        log "FATAL: Failed to load configuration"
        exit 1
    fi
    
    # Validate required variables
    if [ -z "$INTERNAL_MONITOR" ] || [ -z "$LID_STATE_FILE" ]; then
        log "FATAL: Missing required configuration variables"
        exit 1
    fi
    
    local last_lid_state=""
    local last_monitor_hash=""
    local last_external_monitors=""
    local change_pending=false
    local change_timestamp=0
    local monitor_check_counter=0
    
    # Initial configuration
    last_lid_state=$(get_lid_state)
    last_monitor_hash=$(get_monitors_hash)
    last_external_monitors=$(get_external_monitor_names)
    update_display_configuration "$last_lid_state"
    
    log "Daemon initialized successfully"
    log "Internal monitor: $INTERNAL_MONITOR"
    log "Monitoring lid state file: $LID_STATE_FILE"
    log "Known external monitors: ${#MONITOR_CONFIGS[@]}"
    
    # Main monitoring loop with adaptive intervals
    while true; do
        sleep $LID_CHECK_INTERVAL
        monitor_check_counter=$((monitor_check_counter + 1))
        
        local current_lid_state=$(get_lid_state)
        local should_check_monitors=false
        
        # Check monitors less frequently (calculate iterations needed)
        # We check every N iterations where N = MONITOR_CHECK_INTERVAL / LID_CHECK_INTERVAL
        # For example: 2 seconds / 0.5 seconds = check every 4 iterations
        # Convert to deciseconds (tenths of a second) for integer arithmetic
        local monitor_deciseconds=$(echo "$MONITOR_CHECK_INTERVAL * 10" | awk '{printf "%d\n", $1 * $3}')
        local lid_deciseconds=$(echo "$LID_CHECK_INTERVAL * 10" | awk '{printf "%d\n", $1 * $3}')
        local check_frequency=$((monitor_deciseconds / lid_deciseconds))
        
        if [ $((monitor_check_counter % check_frequency)) -eq 0 ]; then
            should_check_monitors=true
        fi
        
        # Check if lid state changed
        if [ "$current_lid_state" != "$last_lid_state" ]; then
            log "Lid state changed: $last_lid_state -> $current_lid_state"
            change_pending=true
            change_timestamp=$(date +%s)
            last_lid_state="$current_lid_state"
            should_check_monitors=true  # Force monitor check on lid change
        fi
        
        # Check if monitor configuration changed
        if [ "$should_check_monitors" = true ]; then
            local current_monitor_hash=$(get_monitors_hash)
            local current_external_monitors=$(get_external_monitor_names)
            
            if [ "$current_monitor_hash" != "$last_monitor_hash" ]; then
                log "Monitor configuration changed (hash: $current_monitor_hash)"
                
                # Handle the monitor change event using extracted helper function
                local monitor_connected=$(handle_monitor_change "$last_external_monitors" "$current_external_monitors")
                
                change_pending=true
                change_timestamp=$(date +%s)
                last_monitor_hash="$current_monitor_hash"
                last_external_monitors="$current_external_monitors"
            fi
        fi
        
        # Apply configuration after debounce delay
        if [ "$change_pending" = true ]; then
            local current_time=$(date +%s)
            local elapsed=$((current_time - change_timestamp))
            
            if [ $elapsed -ge $DEBOUNCE_DELAY ]; then
                log "Debounce period elapsed, applying configuration"
                # Only send notifications if this was a monitor connection event
                local send_notifications="false"
                if [ "${monitor_connected:-false}" = "true" ]; then
                    send_notifications="true"
                fi
                update_display_configuration "$current_lid_state" "$send_notifications"
                change_pending=false
                monitor_connected=false  # Reset flag
            fi
        fi
    done
}

# ============================================================================
# Interactive Commands
# ============================================================================

cmd_status() {
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║         Hyprland Monitor Manager - Status                ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo ""
    
    # Load config to show settings
    load_machine_config >/dev/null 2>&1
    
    # Configuration info
    echo "⚡️  Configuration:"
    echo "  Hostname: $(hostname)"
    echo "  Internal Monitor: $INTERNAL_MONITOR"
    
    # Show current profile if exists
    local profile_dir="$HOME/.config/hypr/monitor-configs/profiles"
    if [ -d "$profile_dir" ]; then
        local current_profile=$(readlink "$profile_dir/.current" 2>/dev/null | xargs basename 2>/dev/null)
        if [ -n "$current_profile" ]; then
            echo "  Current Profile: ${current_profile%.conf} ✅"
        fi
    fi
    
    echo "  Known External Monitors: ${#MONITOR_CONFIGS[@]}"
    echo ""
    
    # Lid state
    local lid_state=$(get_lid_state)
    echo "🔒 Lid State: $lid_state"
    echo ""
    
    # Connected monitors
    echo "🖥️  Connected Monitors:"
    hyprctl monitors | grep -E "(Monitor|description:|at |scale:)" | while IFS= read -r line; do
        if [[ $line == Monitor* ]]; then
            echo "  ▸ $line"
        else
            echo "    $line"
        fi
    done
    echo ""
    
    # Daemon status
    if pgrep -f "hmonitor daemon" > /dev/null || pgrep -f "monitor-manager.sh daemon" > /dev/null; then
        local pid=$(pgrep -f "hmonitor daemon" || pgrep -f "monitor-manager.sh daemon")
        echo "✓ Daemon is running (PID: $pid)"
    else
        echo "✗ Daemon is not running"
    fi
    echo ""
}

cmd_toggle_internal() {
    # Load config to get INTERNAL_MONITOR
    load_machine_config >/dev/null 2>&1
    
    # Check dpms status (false=off, true=on)
    local dpms_status=$(hyprctl monitors -j | jq -r '.[] | select(.name == "'$INTERNAL_MONITOR'") | .dpmsStatus')
    
    if [ "$dpms_status" = "false" ] || [ -z "$dpms_status" ]; then
        # Screen is off or not found, turn it on
        log "Manual toggle: enabling internal display (dpms on)"
        hyprctl dispatch dpms on $INTERNAL_MONITOR >/dev/null 2>&1
        echo "✓ Internal display enabled"
    else
        # Screen is on, turn it off
        log "Manual toggle: disabling internal display (dpms off)"
        hyprctl dispatch dpms off $INTERNAL_MONITOR >/dev/null 2>&1
        echo "✓ Internal display disabled"
    fi
}

cmd_refresh() {
    log "Manual refresh triggered"
    
    # Load config first
    if ! load_machine_config; then
        echo "✗ Failed to load configuration"
        return 1
    fi
    
    local lid_state=$(get_lid_state)
    update_display_configuration "$lid_state"
    echo "✓ Display configuration refreshed"
}

cmd_logs() {
    local lines="${1:-20}"
    echo "Recent logs (last $lines lines):"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    tail -n "$lines" "$LOG_FILE" 2>/dev/null || echo "No logs found"
}

# ============================================================================
# Profile Management
# ============================================================================

PROFILE_DIR="$HOME/.config/hypr/monitor-configs/profiles"

cmd_profile() {
    local action="${1:-list}"
    local profile_name="$2"
    local hostname=$(hostname)
    local current_config="$HOME/.config/hypr/monitor-configs/$hostname.conf"
    
    # Ensure profile directory exists
    mkdir -p "$PROFILE_DIR"
    
    case "$action" in
        list)
            echo "📋 Available Profiles:"
            echo ""
            if [ -z "$(ls -A "$PROFILE_DIR" 2>/dev/null)" ]; then
                echo "  No profiles saved yet."
                echo ""
                echo "  Create a profile with: hmonitor profile save <name>"
            else
                local current_profile=$(readlink "$PROFILE_DIR/.current" 2>/dev/null | xargs basename 2>/dev/null)
                for profile in "$PROFILE_DIR"/*.conf; do
                    if [ -f "$profile" ]; then
                        local name=$(basename "$profile" .conf)
                        local date=$(stat -c %y "$profile" | cut -d' ' -f1)
                        if [ "$name" = "$current_profile" ]; then
                            echo "  ✅ $name (active) - saved on $date"
                        else
                            echo "  📄 $name - saved on $date"
                        fi
                    fi
                done
            fi
            echo ""
            ;;
        
        save)
            if [ -z "$profile_name" ]; then
                echo "❌ Error: Profile name required"
                echo "Usage: hmonitor profile save <name>"
                return 1
            fi
            
            if [ ! -f "$current_config" ]; then
                echo "❌ Error: No configuration file found at $current_config"
                echo "Run 'hmonitor wizard' first"
                return 1
            fi
            
            local profile_file="$PROFILE_DIR/$profile_name.conf"
            cp "$current_config" "$profile_file"
            ln -sf "$profile_file" "$PROFILE_DIR/.current"
            echo "✅ Profile '$profile_name' saved successfully"
            echo "   Location: $profile_file"
            ;;
        
        switch)
            # If no profile name provided, show interactive menu
            if [ -z "$profile_name" ]; then
                # Check if we have profiles
                if [ -z "$(ls -A "$PROFILE_DIR"/*.conf 2>/dev/null)" ]; then
                    echo "❌ No profiles available"
                    echo "Create a profile with: hmonitor profile save <name>"
                    return 1
                fi
                
                # Show interactive menu
                echo "📋 Quick Profile Switch"
                echo ""
                echo "Available Profiles:"
                
                local profiles=()
                local current_profile=$(readlink "$PROFILE_DIR/.current" 2>/dev/null | xargs basename 2>/dev/null)
                local i=1
                
                for profile in "$PROFILE_DIR"/*.conf; do
                    if [ -f "$profile" ]; then
                        local name=$(basename "$profile" .conf)
                        profiles+=("$name")
                        if [ "$name" = "$current_profile" ]; then
                            echo "  $i) $name (current) ✅"
                        else
                            echo "  $i) $name"
                        fi
                        i=$((i+1))
                    fi
                done
                
                echo ""
                echo -n "Select profile [1-${#profiles[@]}] or [q]uit: "
                read selection < /dev/tty
                
                if [[ "$selection" =~ ^[Qq]$ ]]; then
                    echo "Cancelled"
                    return 0
                fi
                
                if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt "${#profiles[@]}" ]; then
                    echo "❌ Invalid selection"
                    return 1
                fi
                
                profile_name="${profiles[$((selection-1))]}"
                echo ""
            fi
            
            local profile_file="$PROFILE_DIR/$profile_name.conf"
            if [ ! -f "$profile_file" ]; then
                echo "❌ Error: Profile '$profile_name' not found"
                echo ""
                echo "Available profiles:"
                cmd_profile list
                return 1
            fi
            
            # Backup current config
            if [ -f "$current_config" ]; then
                cp "$current_config" "$current_config.backup.$(date +%Y%m%d_%H%M%S)"
            fi
            
            # Copy profile to current config
            cp "$profile_file" "$current_config"
            ln -sf "$profile_file" "$PROFILE_DIR/.current"
            
            echo "✅ Switched to profile '$profile_name'"
            echo ""
            echo "Applying configuration..."
            cmd_refresh
            ;;
        
        delete)
            if [ -z "$profile_name" ]; then
                echo "❌ Error: Profile name required"
                echo "Usage: hmonitor profile delete <name>"
                return 1
            fi
            
            local profile_file="$PROFILE_DIR/$profile_name.conf"
            if [ ! -f "$profile_file" ]; then
                echo "❌ Error: Profile '$profile_name' not found"
                return 1
            fi
            
            rm "$profile_file"
            echo "✅ Profile '$profile_name' deleted"
            ;;
        
        current)
            local current_profile=$(readlink "$PROFILE_DIR/.current" 2>/dev/null | xargs basename 2>/dev/null)
            if [ -n "$current_profile" ]; then
                echo "Current profile: ${current_profile%.conf}"
            else
                echo "No active profile"
            fi
            ;;
        
        help)
            cat << EOF
Profile Management - Save and switch between monitor configurations

Usage: hmonitor profile <action> [name]

Actions:
  list              List all saved profiles
  save <name>       Save current configuration as a profile
  switch <name>     Switch to a saved profile
  delete <name>     Delete a saved profile
  current           Show currently active profile
  help              Show this help

Examples:
  hmonitor profile save office       # Save current setup as 'office'
  hmonitor profile save home         # Save current setup as 'home'
  hmonitor profile list              # List all profiles
  hmonitor profile switch office     # Switch to 'office' profile

Use Case:
  - Save different configurations for different locations (home/office)
  - Quickly switch between single/dual monitor setups
  - Backup configurations before experimenting
EOF
            ;;
        
        *)
            echo "❌ Error: Unknown action '$action'"
            echo ""
            cmd_profile help
            return 1
            ;;
    esac
}

cmd_doctor() {
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║    Hyprland Monitor Manager - Health Check            ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo ""
    
    local issues=0
    local warnings=0
    
    # Load config
    if ! load_machine_config; then
        echo "❌ Configuration file not found or invalid"
        echo "   Run: hmonitor wizard"
        return 1
    fi
    
    echo "━━━ System Check ━━━"
    echo ""
    
    # Check dependencies
    echo "📦 Checking dependencies:"
    local deps=("hyprctl" "jq" "systemd-inhibit" "notify-send")
    for dep in "${deps[@]}"; do
        if command -v "$dep" &> /dev/null; then
            echo "  ✅ $dep - installed"
        else
            echo "  ❌ $dep - MISSING"
            issues=$((issues + 1))
        fi
    done
    echo ""
    
    # Check Hyprland
    echo "🖥️  Checking Hyprland:"
    if pgrep -x Hyprland > /dev/null; then
        echo "  ✅ Hyprland is running"
        local hypr_version=$(hyprctl version | head -1)
        echo "     $hypr_version"
    else
        echo "  ❌ Hyprland is NOT running"
        issues=$((issues + 1))
    fi
    echo ""
    
    # Check configuration
    echo "⚙️  Checking configuration:"
    if [ -n "$INTERNAL_MONITOR" ]; then
        echo "  ✅ Internal monitor configured: $INTERNAL_MONITOR"
    else
        echo "  ❌ Internal monitor not configured"
        issues=$((issues + 1))
    fi
    
    if [ -f "$LID_STATE_FILE" ]; then
        echo "  ✅ Lid state file found: $LID_STATE_FILE"
        local lid_state=$(cat "$LID_STATE_FILE" | awk '{print $2}')
        echo "     Current state: $lid_state"
    else
        echo "  ⚠️  Lid state file not found: $LID_STATE_FILE"
        echo "     (This is normal for desktop machines)"
        warnings=$((warnings + 1))
    fi
    
    if [ ${#MONITOR_CONFIGS[@]} -gt 0 ]; then
        echo "  ✅ External monitors configured: ${#MONITOR_CONFIGS[@]}"
        for desc in "${!MONITOR_CONFIGS[@]}"; do
            echo "     • $desc"
        done
    else
        echo "  ⚠️  No external monitors configured"
        echo "     (Run wizard when external monitor is connected)"
        warnings=$((warnings + 1))
    fi
    echo ""
    
    # Check current monitors
    echo "🔍 Checking connected monitors:"
    local monitor_count=$(hyprctl monitors -j | jq '. | length')
    echo "  Connected: $monitor_count monitor(s)"
    
    while IFS='|' read -r name desc; do
        if [ -n "$name" ]; then
            local mon_info=$(hyprctl monitors -j | jq -r '.[] | select(.name == "'$name'") | "\(.width)x\(.height)@\(.refreshRate|floor)Hz scale=\(.scale)"')
            
            if [ "$name" = "$INTERNAL_MONITOR" ]; then
                echo "  ✅ $name (Internal)"
            else
                echo "  ✅ $name (External)"
                
                # Check if this monitor is configured
                local configured=false
                for desc_pattern in "${!MONITOR_CONFIGS[@]}"; do
                    if [[ "$desc" == *"$desc_pattern"* ]]; then
                        configured=true
                        break
                    fi
                done
                
                if [ "$configured" = false ]; then
                    echo "     ⚠️  Not configured in settings"
                    warnings=$((warnings + 1))
                fi
            fi
            echo "     $mon_info"
            echo "     $desc"
            
            # Check for common issues
            local refresh=$(hyprctl monitors -j | jq -r '.[] | select(.name == "'$name'") | .refreshRate | floor')
            local scale=$(hyprctl monitors -j | jq -r '.[] | select(.name == "'$name'") | .scale')
            
            if [ "$refresh" -lt 60 ]; then
                echo "     ⚠️  Low refresh rate (${refresh}Hz) - may cause flickering"
                warnings=$((warnings + 1))
            fi
            
            if [ "$name" != "$INTERNAL_MONITOR" ] && [ "${scale%.*}" -lt 2 ]; then
                local width=$(hyprctl monitors -j | jq -r '.[] | select(.name == "'$name'") | .width')
                if [ "$width" -ge 3840 ]; then
                    echo "     💡 Suggestion: Consider 2x scaling for 4K display"
                fi
            fi
        fi
    done < <(hyprctl monitors -j | jq -r '.[] | "\(.name)|\(.description)"')
    echo ""
    
    # Check daemon
    echo "🔄 Checking daemon:"
    if pgrep -f "monitor-manager.sh.*daemon" > /dev/null; then
        echo "  ✅ Daemon is running"
        local daemon_pid=$(pgrep -f "monitor-manager.sh.*daemon")
        echo "     PID: $daemon_pid"
    else
        echo "  ⚠️  Daemon is NOT running"
        echo "     Start with: hmonitor daemon"
        warnings=$((warnings + 1))
    fi
    echo ""
    
    # Check suspend inhibit
    echo "🔒 Checking suspend inhibit:"
    if systemd-inhibit --list | grep -q "monitor-manager"; then
        echo "  ✅ Suspend inhibit is active"
        echo "     (Laptop won't suspend when lid is closed with external monitor)"
    else
        echo "  ℹ️  Suspend inhibit not active"
        echo "     (This is normal when no external monitor is connected)"
    fi
    echo ""
    
    # Check logs
    echo "📝 Checking logs:"
    if [ -f "$LOG_FILE" ]; then
        local log_size=$(du -h "$LOG_FILE" | cut -f1)
        local log_lines=$(wc -l < "$LOG_FILE")
        echo "  ✅ Log file: $LOG_FILE"
        echo "     Size: $log_size, Lines: $log_lines"
        
        if [ "$log_lines" -gt 10000 ]; then
            echo "     ⚠️  Log file is large - consider rotating"
            warnings=$((warnings + 1))
        fi
    else
        echo "  ℹ️  No log file yet"
    fi
    echo ""
    
    # Summary
    echo "━━━ Health Check Summary ━━━"
    echo ""
    
    if [ $issues -eq 0 ] && [ $warnings -eq 0 ]; then
        echo "  🎉 Everything looks great!"
        echo "     Your monitor setup is working perfectly."
    elif [ $issues -eq 0 ]; then
        echo "  ✅ System is functional"
        echo "     Found $warnings warning(s) - see above for details"
    else
        echo "  ⚠️  Found $issues critical issue(s) and $warnings warning(s)"
        echo "     Please address the issues marked with ❌ above"
    fi
    echo ""
    
    return $issues
}

cmd_wizard() {
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║    Hyprland Monitor Manager - Configuration Wizard     ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo ""
    echo "This wizard will help you create a configuration file for this machine."
    echo ""
    
    local hostname=$(hostname)
    local config_dir="$HOME/.config/hypr/monitor-configs"
    local config_file="$config_dir/$hostname.conf"
    
    # Create config directory
    mkdir -p "$config_dir"
    
    # Step 1: System Detection (Internal Display & Lid State)
    echo "━━━ Step 1: System Detection ━━━"
    echo ""
    
    # Detect internal monitor
    local internal_monitor=$(hyprctl monitors -j | jq -r '.[] | select(.name | startswith("eDP")) | .name' | head -1)
    
    if [ -z "$internal_monitor" ]; then
        internal_monitor="eDP-1"
        echo "⚠️  Internal display: $internal_monitor (default)"
    else
        echo "✅ Internal display: $internal_monitor"
    fi
    
    # Get internal monitor details
    local internal_info=$(hyprctl monitors -j | jq -r '.[] | select(.name == "'$internal_monitor'") | "\(.width)x\(.height)@\(.refreshRate),\(.x)x\(.y),\(.scale)"')
    if [ -n "$internal_info" ]; then
        echo "   Settings: $internal_info"
    fi
    
    # Detect lid state file
    local lid_file=$(find /proc/acpi/button/lid -name state 2>/dev/null | head -1)
    
    if [ -z "$lid_file" ]; then
        lid_file="/proc/acpi/button/lid/LID/state"
        echo "⚠️  Lid state: $lid_file (default)"
    else
        local lid_state=$(cat "$lid_file" | awk '{print $2}')
        echo "✅ Lid state: $lid_state ($lid_file)"
    fi
    echo ""
    
    # Step 2: Detect external monitors
    echo "━━━ Step 2: External Displays ━━━"
    echo ""
    echo "Scanning for connected external displays..."
    echo ""
    
    local external_count=0
    local monitor_configs=""
    
    while IFS='|' read -r name desc; do
        # Check if this is truly an external monitor (not just another output of internal display)
        # External monitors typically use HDMI, DP, DisplayPort connectors
        # Internal monitors use eDP, LVDS, DSI connectors
        if [ "$name" != "$internal_monitor" ] && [ -n "$name" ] && \
           [[ "$name" =~ ^(HDMI|DP|DisplayPort) ]]; then
            external_count=$((external_count + 1))
            echo "🖥️  External Monitor #$external_count:"
            echo "   Name: $name"
            echo "   Description: $desc"
            
            # Get current settings
            local current_width=$(hyprctl monitors -j | jq -r '.[] | select(.name == "'$name'") | .width')
            local current_height=$(hyprctl monitors -j | jq -r '.[] | select(.name == "'$name'") | .height')
            local current_refresh=$(hyprctl monitors -j | jq -r '.[] | select(.name == "'$name'") | .refreshRate | floor')
            local current_x=$(hyprctl monitors -j | jq -r '.[] | select(.name == "'$name'") | .x')
            local current_y=$(hyprctl monitors -j | jq -r '.[] | select(.name == "'$name'") | .y')
            local current_scale=$(hyprctl monitors -j | jq -r '.[] | select(.name == "'$name'") | .scale')
            
            echo "   Current: ${current_width}x${current_height}@${current_refresh}, position ${current_x}x${current_y}, scale ${current_scale}"
            echo ""
            
            # Ask if user wants to customize
            echo -n "   Use current settings? (Y/n): "
            read use_current < /dev/tty
            echo ""
            
            local resolution="${current_width}x${current_height}@${current_refresh}"
            local position="${current_x}x${current_y}"
            local scale="$current_scale"
            
            if [[ "$use_current" =~ ^[Nn]$ ]]; then
                echo "   ━━━ Advanced Configuration ━━━"
                echo ""
                
                # Step 1: Resolution
                echo "   [1/3] Resolution:"
                echo "     1) ${current_width}x${current_height}@${current_refresh} (current)"
                echo "     2) 3840x2160@60 (4K)"
                echo "     3) 2560x1440@60 (2K)"
                echo "     4) 1920x1080@60 (Full HD)"
                echo "     5) Custom"
                echo -n "   Choose (1-5) [1]: "
                read res_choice < /dev/tty
                case "$res_choice" in
                    2) resolution="3840x2160@60" ;;
                    3) resolution="2560x1440@60" ;;
                    4) resolution="1920x1080@60" ;;
                    5) 
                        echo -n "   Enter resolution (WIDTHxHEIGHT@REFRESH): "
                        read resolution < /dev/tty
                        ;;
                    *) resolution="${current_width}x${current_height}@${current_refresh}" ;;
                esac
                echo ""
                
                # Step 2: Scale
                echo "   [2/3] Display Scaling:"
                echo "     1) 1.0 (no scaling)"
                echo "     2) 1.25"
                echo "     3) 1.5"
                echo "     4) 2.0 (HiDPI, recommended for 4K)"
                echo "     5) Custom"
                echo -n "   Choose (1-5) [${current_scale}]: "
                read scale_choice < /dev/tty
                case "$scale_choice" in
                    1) scale="1.0" ;;
                    2) scale="1.25" ;;
                    3) scale="1.5" ;;
                    4) scale="2.0" ;;
                    5) 
                        echo -n "   Enter scale: "
                        read scale < /dev/tty
                        ;;
                    *) scale="$current_scale" ;;
                esac
                echo ""
                
                # Step 3: Position
                # Get internal monitor position for reference
                local int_x=$(hyprctl monitors -j | jq -r '.[] | select(.name == "'$internal_monitor'") | .x')
                local int_y=$(hyprctl monitors -j | jq -r '.[] | select(.name == "'$internal_monitor'") | .y')
                local int_height_phys=$(hyprctl monitors -j | jq -r '.[] | select(.name == "'$internal_monitor'") | .height')
                local int_width_phys=$(hyprctl monitors -j | jq -r '.[] | select(.name == "'$internal_monitor'") | .width')
                local int_scale=$(hyprctl monitors -j | jq -r '.[] | select(.name == "'$internal_monitor'") | .scale')
                
                # Calculate logical dimensions (physical / scale)
                local int_height=$(awk "BEGIN {printf \"%.0f\", $int_height_phys / $int_scale}")
                local int_width=$(awk "BEGIN {printf \"%.0f\", $int_width_phys / $int_scale}")
                
                # Calculate external monitor logical dimensions based on chosen resolution and scale
                # Extract width and height from resolution string
                local ext_width=$(echo "$resolution" | cut -d'x' -f1)
                local ext_height=$(echo "$resolution" | cut -d'x' -f2 | cut -d'@' -f1)
                
                # Calculate logical dimensions for external monitor
                local ext_height_logical=$(awk "BEGIN {printf \"%.0f\", $ext_height / $scale}")
                local ext_width_logical=$(awk "BEGIN {printf \"%.0f\", $ext_width / $scale}")
                
                echo "   [3/3] Position (relative to internal display):"
                echo "     1) Above (recommended for most desks)"
                echo "     2) Below"
                echo "     3) Left"
                echo "     4) Right"
                echo "     5) Custom coordinates"
                echo -n "   Choose (1-5) [1]: "
                read pos_choice < /dev/tty
                case "$pos_choice" in
                    1) position="${int_x}x-${ext_height_logical}" ;;  # Above - use external monitor height
                    2) position="${int_x}x${int_height}" ;;   # Below - use internal monitor height
                    3) position="-${ext_width_logical}x${int_y}" ;;   # Left - use external monitor width
                    4) position="${int_width}x${int_y}" ;;    # Right - use internal monitor width
                    5) 
                        echo -n "   Enter position (XxY): "
                        read position < /dev/tty
                        ;;
                    *) position="${int_x}x-${ext_height_logical}" ;;  # Default: above
                esac
                echo ""
            fi
            
            # Build final config string
            local mon_info="${resolution},${position},${scale}"
            
            # Build config entry (will write directly to file later)
            # Use a generic location name for now
            local location="external$external_count"
            if [ -z "$monitor_configs" ]; then
                monitor_configs="$desc|$location|$mon_info"
            else
                monitor_configs="$monitor_configs
$desc|$location|$mon_info"
            fi
            
            echo "   ✅ Configured: $mon_info"
            echo ""
        fi
    done < <(hyprctl monitors -j | jq -r '.[] | "\(.name)|\(.description)"')
    
    if [ $external_count -eq 0 ]; then
        echo "⚠️  No external monitors detected."
        echo "   You can add them later by editing: $config_file"
        echo "   Or run this wizard again when monitors are connected."
        echo ""
    fi
    
    # Generate config file (silently, no separate step display)
    # Auto-backup existing config if it exists
    if [ -f "$config_file" ]; then
        local backup_file="$config_file.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$config_file" "$backup_file" 2>/dev/null
    fi
    
    # Write config file
    cat > "$config_file" << EOF
# Monitor configuration for $hostname
# Generated by hmonitor wizard on $(date)

# Internal display configuration
INTERNAL_MONITOR="$internal_monitor"
INTERNAL_CONFIG="$internal_info"

# Lid state file path
LID_STATE_FILE="$lid_file"

# External monitor configurations
# Format: MONITOR_CONFIGS["Monitor description keyword"]="location,resolution,position,scale"
EOF
    
    if [ -n "$monitor_configs" ]; then
        # Write each monitor config
        while IFS='|' read -r desc location info; do
            echo "MONITOR_CONFIGS[\"$desc\"]=\"$location,$info\"" >> "$config_file"
        done <<< "$monitor_configs"
    else
        echo "# Add your external monitors here:" >> "$config_file"
        echo '# MONITOR_CONFIGS["Dell U2720Q"]="work,3840x2160@60,0x-1080,2"' >> "$config_file"
    fi
    
    # Step 3: Auto-start daemon
    echo "━━━ Step 3: Starting Daemon ━━━"
    echo ""
    
    # Kill existing daemon if running
    if pgrep -f "hmonitor daemon" > /dev/null || pgrep -f "monitor-manager.sh daemon" > /dev/null; then
        local old_pid=$(pgrep -f "hmonitor daemon" || pgrep -f "monitor-manager.sh daemon")
        kill "$old_pid" 2>/dev/null
        echo "  Stopped existing daemon (PID: $old_pid)"
    fi
    
    # Start new daemon
    nohup hmonitor daemon > /tmp/monitor-manager-daemon.log 2>&1 &
    local daemon_pid=$!
    sleep 1
    
    if ps -p "$daemon_pid" > /dev/null 2>&1; then
        echo "  ✅ Daemon started (PID: $daemon_pid)"
    else
        echo "  ⚠️  Daemon failed to start. Check logs: hmonitor logs"
    fi
    
    # Apply configuration immediately
    echo "  🔄 Applying new configuration..."
    if load_machine_config >/dev/null 2>&1; then
        local lid_state=$(get_lid_state)
        update_display_configuration "$lid_state" "false" >/dev/null 2>&1
        echo "  ✅ Configuration applied"
    fi
    echo ""
    
    # Add to Hyprland autostart
    local hypr_conf="$HOME/.config/hypr/hyprland.conf"
    local autostart_conf="$HOME/.config/hypr/autostart.conf"
    local target_conf=""
    
    # Determine which config file to use
    if [ -f "$autostart_conf" ]; then
        target_conf="$autostart_conf"
    elif [ -f "$hypr_conf" ]; then
        target_conf="$hypr_conf"
    fi
    
    if [ -n "$target_conf" ]; then
        # Check if already configured
        if grep -q "hmonitor daemon" "$target_conf" 2>/dev/null; then
            echo "  ℹ️  Autostart already configured"
        else
            echo "" >> "$target_conf"
            echo "# Hyprland Monitor Manager - Auto-manage displays and lid" >> "$target_conf"
            echo "exec-once = hmonitor daemon" >> "$target_conf"
            echo "  ✅ Added to autostart: $target_conf"
        fi
    else
        echo "  ⚠️  Could not find hyprland.conf or autostart.conf"
        echo "     Please manually add: exec-once = hmonitor daemon"
    fi
    
    echo ""
    
    # Step 4: Ask to save profile (only if external monitors were configured)
    local saved_profiles=()
    if [ $external_count -gt 0 ]; then
        echo "━━━ Step 4: Save Profile (Optional) ━━━"
        echo ""
        echo "💡 Save this configuration as a profile for quick switching?"
        echo ""
        echo -n "Save as profile? (y/N): "
        read save_profile < /dev/tty
        echo ""
        
        if [[ "$save_profile" =~ ^[Yy]$ ]]; then
            echo -n "Enter profile name (e.g., office, home): "
            read profile_name < /dev/tty
            echo ""
            
            if [ -n "$profile_name" ]; then
                # Create profile directory
                local profile_dir="$HOME/.config/hypr/monitor-configs/profiles"
                mkdir -p "$profile_dir"
                
                # Save profile
                local profile_file="$profile_dir/$profile_name.conf"
                cp "$config_file" "$profile_file"
                ln -sf "$profile_file" "$profile_dir/.current"
                
                saved_profiles+=("$profile_name")
                echo "  ✅ Profile '$profile_name' saved"
                echo ""
            else
                echo "  ℹ️  Skipped - no profile name provided"
                echo ""
            fi
        else
            echo "  ℹ️  Skipped - you can save later with: hmonitor profile save <name>"
            echo ""
        fi
    fi
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "✅ Configuration completed successfully!"
    echo ""
    echo "📋 Configuration Summary:"
    echo ""
    
    # Internal monitor info
    echo "   💻 Internal Display:"
    echo "      Monitor: $internal_monitor"
    if [ -n "$internal_info" ]; then
        # Parse internal_info: "widthxheight@refresh,XxY,scale"
        local int_res=$(echo "$internal_info" | cut -d',' -f1)
        local int_pos=$(echo "$internal_info" | cut -d',' -f2)
        local int_scale=$(echo "$internal_info" | cut -d',' -f3)
        echo "      Resolution: $int_res"
        echo "      Position: $int_pos"
        echo "      Scale: $int_scale"
    fi
    echo ""
    
    # External monitor(s) info
    if [ $external_count -gt 0 ]; then
        echo "   🖥️  External Display(s):"
        local count=1
        while IFS='|' read -r desc location info; do
            # Parse info: "resolution,position,scale"
            local ext_res=$(echo "$info" | cut -d',' -f1)
            local ext_pos=$(echo "$info" | cut -d',' -f2)
            local ext_scale=$(echo "$info" | cut -d',' -f3)
            
            echo "      • Monitor #$count: $(echo "$desc" | cut -c1-50)..."
            echo "        Resolution: $ext_res"
            echo "        Position: $ext_pos"
            echo "        Scale: $ext_scale"
            count=$((count + 1))
        done <<< "$monitor_configs"
        echo ""
    else
        echo "   🖥️  External Display(s): None configured"
        echo ""
    fi
    
    # Profile and daemon status
    if [ ${#saved_profiles[@]} -gt 0 ]; then
        echo "   💾 Profile: ${saved_profiles[*]} ✅"
    fi
    echo "   🔄 Daemon: Running (auto-start enabled) ✅"
    echo ""
    
    if [ ${#saved_profiles[@]} -gt 0 ]; then
        echo "🎯 Auto-Switching:"
        echo "   Next time you connect this monitor, the daemon will"
        echo "   automatically switch to the '${saved_profiles[0]}' profile."
        echo ""
    elif [ $external_count -gt 0 ]; then
        echo "💡 Save Profile Later:"
        echo "   When you're satisfied with the setup, save it:"
        echo "   → hmonitor profile save <name>"
        echo ""
    fi
    
    echo "📚 Useful Commands:"
    echo "   • hmonitor profile save <name>  - Save current setup"
    echo "   • hmonitor profile list         - View all profiles"
    echo "   • hmonitor switch               - Switch between profiles"
    echo "   • hmonitor status               - Check system status"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

show_usage() {
    cat << EOF
Hyprland Monitor Manager - Integrated display and lid management

Usage: $0 [command]

Commands:
  wizard          Interactive configuration wizard (recommended for first-time setup)
  daemon          Start daemon in background (use --foreground to run in foreground)
  status          Show current monitor and lid status
  toggle          Toggle internal display on/off
  refresh         Apply configuration changes (after editing config file)
  switch          Quick profile switch (interactive menu)
  doctor          Run health check and diagnostics
  profile         Manage configuration profiles
  logs [N]        Show last N lines of logs (default: 20)
  help            Show this help message

Profile Commands:
  profile list              List all saved profiles
  profile save <name>       Save current configuration as a profile
  profile switch [name]     Switch to a saved profile (interactive if no name)
  profile delete <name>     Delete a saved profile
  profile current           Show currently active profile
  profile help              Show detailed profile help
  
Quick Commands:
  switch (sw)               Same as 'profile switch' (interactive menu)

Command Aliases:
  s = status, d = daemon, w = wizard, t = toggle, r = refresh
  doc = doctor, p = profile, l = logs, sw = switch

Quick Start:
  1. Run: hmonitor wizard       (creates configuration automatically)
  2. Then: hmonitor daemon      (starts automatic management)

Daemon mode will:
  • Automatically detect and configure external monitors
  • Disable internal display when lid is closed (with external monitor)
  • Enable internal display when lid is opened
  • React to monitor hotplug events
  • Automatically switch to saved profiles when monitors are detected
  • Run in background by default (use --foreground for debugging)

To start at boot, add to ~/.config/hypr/hyprland.conf:
  exec-once = hmonitor daemon

EOF
}

# ============================================================================
# Main Entry Point
# ============================================================================

# If no command is provided, show help instead of starting daemon
if [ $# -eq 0 ]; then
    show_usage
    exit 0
fi

case "$1" in
    wizard|w)
        cmd_wizard
        ;;
    daemon|d)
        # Check if --foreground flag is provided
        if [[ "$2" == "--foreground" ]] || [[ "$2" == "-f" ]]; then
            # Run in foreground (blocking mode) - useful for debugging or systemd
            daemon_mode
        else
            # Run in background by default - fork and exit parent
            echo "Starting monitor manager daemon in background..."
            
            # Fork to background using bash's & operator
            (
                # Redirect output to log file
                exec > /tmp/monitor-manager-daemon.log 2>&1
                daemon_mode
            ) &
            
            daemon_pid=$!
            sleep 1
            
            # Check if daemon started successfully
            if kill -0 "$daemon_pid" 2>/dev/null; then
                echo "✓ Daemon started successfully (PID: $daemon_pid)"
                echo "  View logs: hmonitor logs"
                echo "  Stop daemon: kill $daemon_pid"
            else
                echo "✗ Failed to start daemon"
                echo "  Check logs: tail /tmp/monitor-manager-daemon.log"
                exit 1
            fi
        fi
        ;;
    status|s)
        cmd_status
        ;;
    toggle|t)
        cmd_toggle_internal
        ;;
    refresh|r)
        cmd_refresh
        ;;
    doctor|doc)
        cmd_doctor
        ;;
    switch|sw)
        # Quick switch shortcut - same as profile switch without name
        cmd_profile switch
        ;;
    profile|p)
        shift
        cmd_profile "$@"
        ;;
    logs|l)
        cmd_logs "${2:-20}"
        ;;
    help|--help|-h)
        show_usage
        ;;
    *)
        echo "Error: Unknown command '$1'"
        echo ""
        show_usage
        exit 1
        ;;
esac
