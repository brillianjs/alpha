#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# BrillTunnel VPN - Docker Test Environment
# ═══════════════════════════════════════════════════════════════

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Detect docker compose command
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
elif docker compose version &> /dev/null; then
    DOCKER_COMPOSE="docker compose"
else
    echo -e "${RED}Error: Docker Compose not found!${NC}"
    echo "Please install Docker Desktop: https://www.docker.com/products/docker-desktop"
    exit 1
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo -e "${RED}Error: Docker is not running!${NC}"
    echo "Please start Docker Desktop first."
    exit 1
fi

echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}        🚀 BrillTunnel VPN - Docker Test Environment 🚀        ${CYAN}║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""

case "$1" in
    build)
        echo -e "${YELLOW}Building Docker image...${NC}"
        $DOCKER_COMPOSE build --no-cache
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Build completed!${NC}"
        else
            echo -e "${RED}❌ Build failed!${NC}"
            exit 1
        fi
        ;;
    start)
        echo -e "${YELLOW}Starting container...${NC}"
        $DOCKER_COMPOSE up -d
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Container started!${NC}"
            echo ""
            echo -e "${CYAN}To enter the container, run:${NC}"
            echo -e "  ${GREEN}./docker-test.sh shell${NC}"
        else
            echo -e "${RED}❌ Failed to start container!${NC}"
            exit 1
        fi
        ;;
    stop)
        echo -e "${YELLOW}Stopping container...${NC}"
        $DOCKER_COMPOSE down
        echo -e "${GREEN}✅ Container stopped!${NC}"
        ;;
    shell)
        echo -e "${YELLOW}Entering container shell...${NC}"
        docker exec -it brilltunnel-test /bin/bash
        ;;
    logs)
        $DOCKER_COMPOSE logs -f
        ;;
    menu)
        echo -e "${YELLOW}Running menu inside container...${NC}"
        docker exec -it brilltunnel-test /usr/local/sbin/menu
        ;;
    test-menu)
        echo -e "${YELLOW}Testing all menu scripts for syntax errors...${NC}"
        docker exec -it brilltunnel-test bash -c "
            echo '=== Testing Menu Files ==='
            for f in /usr/local/sbin/m-*; do
                if [ -f \"\$f\" ]; then
                    echo -n \"Checking: \$(basename \$f) ... \"
                    bash -n \"\$f\" 2>/dev/null && echo '✓ OK' || echo '✗ ERROR'
                fi
            done
            echo ''
            echo '=== Testing Main Menu ==='
            echo -n 'menu ... '
            bash -n /usr/local/sbin/menu 2>/dev/null && echo '✓ OK' || echo '✗ ERROR'
            echo -n 'menu-x ... '
            bash -n /usr/local/sbin/menu-x 2>/dev/null && echo '✓ OK' || echo '✗ ERROR'
        "
        ;;
    install)
        echo -e "${YELLOW}Running full installation inside container...${NC}"
        echo -e "${RED}⚠️  This will run premi.sh - make sure you know what you're doing!${NC}"
        read -p "Continue? (y/N): " confirm
        if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
            docker exec -it brilltunnel-test bash /root/brilltunnel/premi.sh
        else
            echo "Cancelled."
        fi
        ;;
    clean)
        echo -e "${YELLOW}Cleaning up...${NC}"
        $DOCKER_COMPOSE down -v --rmi all 2>/dev/null
        docker rmi brilltunnel-test 2>/dev/null
        echo -e "${GREEN}✅ Cleanup completed!${NC}"
        ;;
    status)
        echo -e "${YELLOW}Container status:${NC}"
        docker ps -a --filter "name=brilltunnel-test" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        ;;
    *)
        echo "Usage: $0 {build|start|stop|shell|logs|menu|test-menu|install|clean|status}"
        echo ""
        echo "Commands:"
        echo "  build      - Build Docker image"
        echo "  start      - Start container in background"
        echo "  stop       - Stop container"
        echo "  shell      - Enter container shell (bash)"
        echo "  logs       - View container logs"
        echo "  menu       - Run VPN menu inside container"
        echo "  test-menu  - Test all menu scripts for syntax errors"
        echo "  install    - Run full installation (premi.sh)"
        echo "  clean      - Remove container and image"
        echo "  status     - Check container status"
        ;;
esac
