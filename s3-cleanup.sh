BUCKET="BUCKET"
CUTOFF_DATE="2026-01-01"
LOG_FILE="s3_cleanup_$(date +%Y%m%d_%H%M%S).log"
DRY_RUN=true

echo "S3 Cleanup Script" | tee -a "$LOG_FILE"
echo "Bucket: $BUCKET" | tee -a "$LOG_FILE"
echo "Removing objects older than: $CUTOFF_DATE" | tee -a "$LOG_FILE"
echo "Dry run: $DRY_RUN" | tee -a "$LOG_FILE"
echo "Log file: $LOG_FILE" | tee -a "$LOG_FILE"
echo "----------------------------------------" | tee -a "$LOG_FILE"

TOTAL=0
DELETED=0
SKIPPED=0
ERRORS=0

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting scan..." | tee -a "$LOG_FILE"

aws s3api list-objects-v2 \
  --bucket "$BUCKET" \
  --output json \
  --query 'Contents[*].{Key: Key, LastModified: LastModified}' \
| jq -r '.[] | "\(.LastModified) \(.Key)"' \
| while IFS=' ' read -r last_modified key; do

  TOTAL=$((TOTAL + 1))

  object_date=$(echo "$last_modified" | cut -c1-10)

  if [[ "$object_date" < "$CUTOFF_DATE" ]]; then
    if [ "$DRY_RUN" = true ]; then
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] [DRY-RUN] Would delete: $key (LastModified: $last_modified)" | tee -a "$LOG_FILE"
    else
      if aws s3api delete-object --bucket "$BUCKET" --key "$key" 2>>"$LOG_FILE"; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [DELETED] $key (LastModified: $last_modified)" | tee -a "$LOG_FILE"
        DELETED=$((DELETED + 1))
      else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] Failed to delete: $key" | tee -a "$LOG_FILE"
        ERRORS=$((ERRORS + 1))
      fi
    fi
  else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [SKIPPED] $key (LastModified: $last_modified)" | tee -a "$LOG_FILE"
    SKIPPED=$((SKIPPED + 1))
  fi

done

echo "----------------------------------------" | tee -a "$LOG_FILE"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Scan complete." | tee -a "$LOG_FILE"
echo "Log saved to: $LOG_FILE"
