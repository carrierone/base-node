# Expected Container Logs

## First Start (Downloading Snapshot)

When you run `docker-compose logs -f base-execution` during first start:

```
========================================
Downloading Base snapshot from: https://mainnet-full-snapshots.base.org/mainnet-full-...tar.zst
This may take 30 minutes to 2 hours depending on network speed
========================================

[#1 SIZE:0B/123.4GiB(0%) CN:16 SPD:0Bs]
[#1 SIZE:512MiB/123.4GiB(0%) CN:16 SPD:45.2MiBs ETA:46m12s]
[#1 SIZE:1.5GiB/123.4GiB(1%) CN:16 SPD:52.3MiBs ETA:40m8s]
[#1 SIZE:3.2GiB/123.4GiB(2%) CN:16 SPD:48.7MiBs ETA:42m51s]
...

[PROGRESS SUMMARY]
Download: 123.4GiB
Connections: 16
Speed: 48.5MiBs (average)
Time: 45m32s

========================================
Download complete! Extracting snapshot...
This may take 10-20 minutes
========================================

[zstd progress output showing decompression]

========================================
Snapshot ready! Starting Nethermind...
========================================

Starting Nethermind...
[Nethermind startup logs...]
```

## Subsequent Starts (Existing Data)

When you run `docker-compose logs -f base-execution` on restart:

```
========================================
Snapshot already exists at /data/chaindata
Skipping download. Starting Nethermind...
========================================

Starting Nethermind...
[Nethermind startup logs...]
```

**Time to start:** ~5-10 seconds

## aria2c Progress Indicators

### Progress Bar Format
```
[#<gid> SIZE:<current>/<total>(<percentage>%) CN:<connections> SPD:<speed> ETA:<time>]
```

### Example Breakdown
```
[#1 SIZE:3.2GiB/123.4GiB(2%) CN:16 SPD:48.7MiBs ETA:42m51s]
 │   │                      │    │     │              └─ Estimated Time
 │   │                      │    │     └─ Download Speed
 │   │                      │    └─ Number of Active Connections
 │   │                      └─ Percentage Complete
 │   └─ Current Size / Total Size
 └─ GID (Group ID)
```

### Summary Updates

Every 10 seconds, you'll see a summary:

```
[NOTICE] Downloading 16 item(s)

*** Download Progress Summary as of <timestamp> ***
======================================================
GID|STAT|AVG Speed   |Path/URI
===+====+============+========================================
  1|  OK|    48.5MiB|/tmp/snap.zst

Status Legend: (OK):download completed.
```

## Monitoring Commands

### View logs in real-time
```bash
docker-compose logs -f base-execution
```

### View only last 100 lines
```bash
docker-compose logs --tail=100 base-execution
```

### Check if download is active
```bash
# View container stats (CPU, Memory, Network I/O)
docker stats base-execution

# You'll see network receive (RX) increasing rapidly during download
```

### Check disk usage during download
```bash
# Check /tmp (where snap.zst downloads)
docker exec base-execution df -h /tmp

# Check /data (where it extracts)
docker exec base-execution df -h /data
```

## Error Scenarios

### Download Failure
```
========================================
Error: Failed to download snapshot
Starting Nethermind without snapshot (will sync from genesis)...
========================================

Starting Nethermind...
[Nethermind will sync from block 0 - much slower]
```

### Extraction Failure
```
========================================
Download complete! Extracting snapshot...
========================================

[extraction errors...]

========================================
Error: Failed to extract snapshot
Starting Nethermind without snapshot (will sync from genesis)...
========================================
```

### Network Timeout
```
[#1 SIZE:10.2GiB/123.4GiB(8%) CN:8 SPD:0Bs]
[NOTICE] Download timeout. Retrying...
[#1 SIZE:10.2GiB/123.4GiB(8%) CN:16 SPD:35.2MiBs ETA:55m12s]
```

aria2c automatically retries on network interruptions.

## Portainer Log Viewing

In Portainer UI:

1. **Containers** → **base-execution**
2. Click **Logs** icon
3. Toggle **Auto-refresh logs** (updates every few seconds)
4. Scroll to see progress updates

## Tips

1. **First deployment:** Don't worry if download takes 1-2 hours - this is normal
2. **Progress stopped:** If `SPD:0Bs` for >5 minutes, may indicate network issue
3. **Container restart:** Container may restart after download completes - this is normal
4. **Disk space:** Monitor with `df -h` to ensure enough space (~500GB recommended)
5. **Speed optimization:** If download is slow (<10 MiB/s), check server network connection

## Success Indicators

You know the snapshot is ready when you see:
```
========================================
Snapshot ready! Starting Nethermind...
========================================
```

Then Nethermind logs should start appearing shortly after.
