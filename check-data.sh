#!/bin/bash
# Check snapshot and volume status

echo "=== Docker Volumes ==="
docker volume ls | grep base

echo ""
echo "=== Volume Inspection ==="
docker volume inspect base_execution_data --format '{{.Name}}: {{.Mountpoint}}' 2>/dev/null || echo "Volume base_execution_data not found"
docker volume inspect base_op_node_data --format '{{.Name}}: {{.Mountpoint}}' 2>/dev/null || echo "Volume base_op_node_data not found"

echo ""
echo "=== Checking for Snapshot Data ==="
if docker ps -a | grep -q base-execution; then
    echo "Checking chaindata in base-execution container..."
    docker exec base-execution du -sh /data/chaindata 2>/dev/null || echo "Container running but chaindata not found (still downloading?)"
else
    echo "Container not running - checking volume directly..."
    # Try to inspect volume size (requires root on host)
    docker run --rm -v base_execution_data:/data alpine du -sh /data 2>/dev/null || echo "Cannot check volume (needs container running)"
fi

echo ""
echo "=== Container Status ==="
docker-compose ps 2>/dev/null || echo "Stack not running"
