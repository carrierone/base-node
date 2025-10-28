# Snapshot Download Behavior

## How It Works

The `snapshot-download.sh` script intelligently checks if blockchain data already exists before attempting to download.

### Detection Logic

```bash
if [ ! -d "$DATA_DIR/chaindata" ]; then
  # Download snapshot
else
  # Skip download
fi
```

The script checks for `/data/chaindata` directory which is created when the snapshot is extracted.

## Data Persistence

### Volume Configuration
```yaml
volumes:
  - base_execution_data:/data  # Named volume persists across restarts
```

Docker named volumes persist even when containers are stopped or removed (unless explicitly deleted with `-v` flag).

## Startup Scenarios

### Scenario 1: First Time Start (No Snapshot)

**Container logs will show:**
```
JWT secret generated for Nethermind
Downloading Base snapshot...
[aria2c download progress bars]
Snapshot ready.
Starting Nethermind...
```

**Time:** 30 minutes - 2 hours (depending on network speed)
**Download size:** ~100-150 GB compressed

### Scenario 2: Restart with Existing Data

**Container logs will show:**
```
JWT secret generated for Nethermind (if needed)
Snapshot exists, skipping download.
Starting Nethermind...
```

**Time:** 5-10 seconds
**Download size:** 0 bytes (uses existing data)

### Scenario 3: Container Recreated (Volume Kept)

```bash
docker-compose down
docker-compose up -d
```

**Result:** Same as Scenario 2 - NO re-download
**Reason:** Volume persists by default

### Scenario 4: Full Reset (Volume Deleted)

```bash
docker-compose down -v  # -v flag deletes volumes
docker-compose up -d
```

**Result:** Same as Scenario 1 - RE-downloads snapshot
**Reason:** Volume was explicitly deleted

## Monitoring Download Progress

### Check if snapshot is downloading
```bash
# View container logs
docker-compose logs -f base-execution

# Check network usage (if downloading)
docker stats base-execution

# Check disk space being used
docker exec base-execution du -sh /data
```

### Typical Download Progress
```
Downloading Base snapshot...
[#1 SIZE:2.5GiB/123.4GiB(2%) CN:16 DL:45MiB ETA:45m]
```

## Verifying Data Exists

### Quick Check
```bash
# Run the included helper script
./check-data.sh

# Or manually check
docker exec base-execution ls -lh /data/
```

### Expected Directory Structure (After Snapshot)
```
/data/
├── chaindata/          # Blockchain database
├── jwt.txt            # JWT secret for consensus
└── keystore/          # (may appear later)
```

### Empty /data (Before Snapshot)
```
/data/
└── jwt.txt            # Only JWT, no chaindata yet
```

## Forcing Re-download

If you need to re-download the snapshot (e.g., corrupted data):

```bash
# Stop container
docker-compose stop base-execution

# Delete the volume
docker volume rm base_execution_data

# Start again (will re-download)
docker-compose up -d base-execution
```

## Snapshot URL

The script automatically fetches the latest snapshot URL:
```bash
SNAPSHOT_URL="https://mainnet-full-snapshots.base.org/$(curl -s https://mainnet-full-snapshots.base.org/latest)"
```

This ensures you always get the most recent snapshot available.

## Network Interruption During Download

The script handles download failures gracefully:

```bash
aria2c -x16 -s16 -k1M "$SNAPSHOT_URL" -o snap.zst || {
    echo "Error: Failed to download snapshot"
    echo "Starting Nethermind without snapshot (will sync from genesis)..."
    exec nethermind "$@"
}
```

**Behavior:**
- If download fails → Nethermind starts anyway
- Node syncs from genesis (slower but works)
- Can manually stop container and restart to retry download

## Best Practices

1. **First deployment:** Let the snapshot download complete before considering the node "ready"
2. **Monitor:** Watch logs during first start to ensure download succeeds
3. **Disk space:** Ensure at least 500GB free space for Base node data
4. **Backup:** Consider backing up the volume after initial sync
5. **Updates:** Periodic fresh snapshots may improve sync performance

## Troubleshooting

### Container keeps restarting during download
- Normal behavior - snapshot download can take 1-2 hours
- Check logs: `docker-compose logs -f base-execution`

### "Snapshot exists" but node won't sync
- Data may be corrupted
- Delete volume and re-download: `docker volume rm base_execution_data`

### Download extremely slow
- Base's snapshot server may be under load
- Consider downloading snapshot manually and extracting to volume

### No space left on device
- Snapshot + extracted data requires ~300-500 GB
- Check: `df -h`
- Clean up: `docker system prune -a`
