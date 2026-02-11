#!/bin/bash
# =============================================================================
# CI-LOCAL: Universal CI Simulation for Any Project
# =============================================================================
# Detecta automáticamente: Java/Gradle, Java/Maven, Node, Python, Go, Rust
#
# Uso:
#   ./ci-local.sh              # CI completo
#   ./ci-local.sh quick        # Solo lint + compile
#   ./ci-local.sh shell        # Shell interactivo en entorno CI
#   ./ci-local.sh detect       # Mostrar stack detectado
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# =============================================================================
# DETECCIÓN DE STACK
# =============================================================================
detect_stack() {
    STACK_TYPE="unknown"
    BUILD_TOOL=""
    DOCKERFILE=""
    LINT_CMD=""
    COMPILE_CMD=""
    TEST_CMD=""
    JAVA_VERSION="21"

    # Java + Gradle
    if [[ -f "$PROJECT_DIR/build.gradle" || -f "$PROJECT_DIR/build.gradle.kts" ]]; then
        STACK_TYPE="java-gradle"
        BUILD_TOOL="gradle"
        DOCKERFILE="java.Dockerfile"
        LINT_CMD="./gradlew spotlessCheck --no-daemon"
        COMPILE_CMD="./gradlew classes testClasses --no-daemon"
        TEST_CMD="./gradlew test --no-daemon"

        # Detectar versión Java (compatible con macOS y Linux)
        if [[ -f "$PROJECT_DIR/build.gradle.kts" ]]; then
            JAVA_VERSION=$(grep -E 'languageVersion\s*=\s*JavaLanguageVersion\.of\(' "$PROJECT_DIR/build.gradle.kts" 2>/dev/null | grep -o '[0-9]\+' | head -1 || echo "21")
        elif [[ -f "$PROJECT_DIR/build.gradle" ]]; then
            JAVA_VERSION=$(grep -E 'sourceCompatibility\s*=' "$PROJECT_DIR/build.gradle" 2>/dev/null | grep -o '[0-9]\+' | head -1 || echo "21")
        fi
        [[ -z "$JAVA_VERSION" ]] && JAVA_VERSION="21"
        return
    fi

    # Java + Maven
    if [[ -f "$PROJECT_DIR/pom.xml" ]]; then
        STACK_TYPE="java-maven"
        BUILD_TOOL="maven"
        DOCKERFILE="java.Dockerfile"
        LINT_CMD="./mvnw spotless:check"
        COMPILE_CMD="./mvnw compile test-compile"
        TEST_CMD="./mvnw test"
        return
    fi

    # Node.js
    if [[ -f "$PROJECT_DIR/package.json" ]]; then
        STACK_TYPE="node"
        if [[ -f "$PROJECT_DIR/pnpm-lock.yaml" ]]; then
            BUILD_TOOL="pnpm"
        elif [[ -f "$PROJECT_DIR/yarn.lock" ]]; then
            BUILD_TOOL="yarn"
        else
            BUILD_TOOL="npm"
        fi
        DOCKERFILE="node.Dockerfile"
        LINT_CMD="$BUILD_TOOL run lint"
        COMPILE_CMD="$BUILD_TOOL run build"
        TEST_CMD="$BUILD_TOOL test"
        return
    fi

    # Python
    if [[ -f "$PROJECT_DIR/pyproject.toml" || -f "$PROJECT_DIR/setup.py" || -f "$PROJECT_DIR/requirements.txt" ]]; then
        STACK_TYPE="python"
        if [[ -f "$PROJECT_DIR/poetry.lock" ]]; then
            BUILD_TOOL="poetry"
        elif [[ -f "$PROJECT_DIR/Pipfile" ]]; then
            BUILD_TOOL="pipenv"
        else
            BUILD_TOOL="pip"
        fi
        DOCKERFILE="python.Dockerfile"
        LINT_CMD="ruff check . || pylint **/*.py"
        TEST_CMD="pytest"
        return
    fi

    # Go
    if [[ -f "$PROJECT_DIR/go.mod" ]]; then
        STACK_TYPE="go"
        BUILD_TOOL="go"
        DOCKERFILE="go.Dockerfile"
        LINT_CMD="golangci-lint run"
        COMPILE_CMD="go build ./..."
        TEST_CMD="go test ./..."
        return
    fi

    # Rust
    if [[ -f "$PROJECT_DIR/Cargo.toml" ]]; then
        STACK_TYPE="rust"
        BUILD_TOOL="cargo"
        DOCKERFILE="rust.Dockerfile"
        LINT_CMD="cargo clippy -- -D warnings"
        COMPILE_CMD="cargo build"
        TEST_CMD="cargo test"
        return
    fi
}

# =============================================================================
# DOCKER
# =============================================================================
get_image_name() {
    echo "ci-local-$STACK_TYPE"
}

create_dockerfile() {
    local docker_dir="$SCRIPT_DIR/docker"
    mkdir -p "$docker_dir"

    case "$STACK_TYPE" in
        java-gradle|java-maven)
            cat > "$docker_dir/$DOCKERFILE" << 'DOCKERFILE'
ARG JAVA_VERSION=21
FROM eclipse-temurin:${JAVA_VERSION}-jdk-noble
RUN apt-get update && apt-get install -y git curl unzip && rm -rf /var/lib/apt/lists/*
RUN useradd -m -s /bin/bash runner
USER runner
WORKDIR /home/runner/work
ENV GRADLE_USER_HOME=/home/runner/.gradle
ENTRYPOINT ["/bin/bash", "-c"]
DOCKERFILE
            ;;
        node)
            cat > "$docker_dir/$DOCKERFILE" << 'DOCKERFILE'
FROM node:22-slim
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*
RUN npm install -g pnpm
RUN useradd -m -s /bin/bash runner
USER runner
WORKDIR /home/runner/work
ENTRYPOINT ["/bin/bash", "-c"]
DOCKERFILE
            ;;
        python)
            cat > "$docker_dir/$DOCKERFILE" << 'DOCKERFILE'
FROM python:3.12-slim
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*
RUN pip install --no-cache-dir pytest ruff pylint poetry
RUN useradd -m -s /bin/bash runner
USER runner
WORKDIR /home/runner/work
ENTRYPOINT ["/bin/bash", "-c"]
DOCKERFILE
            ;;
        go)
            cat > "$docker_dir/$DOCKERFILE" << 'DOCKERFILE'
FROM golang:1.23-bookworm
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*
RUN go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
RUN useradd -m -s /bin/bash runner
USER runner
WORKDIR /home/runner/work
ENTRYPOINT ["/bin/bash", "-c"]
DOCKERFILE
            ;;
        rust)
            cat > "$docker_dir/$DOCKERFILE" << 'DOCKERFILE'
FROM rust:1.83-slim
RUN apt-get update && apt-get install -y git pkg-config libssl-dev && rm -rf /var/lib/apt/lists/*
RUN rustup component add clippy rustfmt
RUN useradd -m -s /bin/bash runner
USER runner
WORKDIR /home/runner/work
ENTRYPOINT ["/bin/bash", "-c"]
DOCKERFILE
            ;;
        *)
            cat > "$docker_dir/$DOCKERFILE" << 'DOCKERFILE'
FROM ubuntu:24.04
RUN apt-get update && apt-get install -y git curl && rm -rf /var/lib/apt/lists/*
RUN useradd -m -s /bin/bash runner
USER runner
WORKDIR /home/runner/work
ENTRYPOINT ["/bin/bash", "-c"]
DOCKERFILE
            ;;
    esac

    echo -e "${GREEN}Created $DOCKERFILE${NC}"
}

ensure_docker_image() {
    local image_name=$(get_image_name)
    local dockerfile="$SCRIPT_DIR/docker/$DOCKERFILE"

    if [[ ! -f "$dockerfile" ]]; then
        echo -e "${YELLOW}Creating Dockerfile for $STACK_TYPE...${NC}"
        create_dockerfile
    fi

    if [[ -z "$(docker images -q $image_name 2>/dev/null)" ]]; then
        echo -e "${YELLOW}Building CI image for $STACK_TYPE...${NC}"
        local build_args=""
        if [[ -n "$JAVA_VERSION" && "$STACK_TYPE" == java-* ]]; then
            build_args="--build-arg JAVA_VERSION=$JAVA_VERSION"
        fi
        docker build $build_args -f "$dockerfile" -t "$image_name" "$SCRIPT_DIR/docker"
    fi
}

run_in_ci() {
    local image_name=$(get_image_name)
    docker run --rm -it \
        -v "$PROJECT_DIR:/home/runner/work" \
        -e CI=true \
        -e GITHUB_ACTIONS=true \
        "$image_name" "$1"
}

# =============================================================================
# MAIN
# =============================================================================
echo -e "\n${YELLOW}=== CI-LOCAL ===${NC}"

detect_stack

if [[ "$STACK_TYPE" == "unknown" ]]; then
    echo -e "${RED}Could not detect project type!${NC}"
    echo -e "${YELLOW}Supported: Java/Gradle, Java/Maven, Node, Python, Go, Rust${NC}"
    exit 1
fi

echo -e "${GREEN}Detected: $STACK_TYPE ($BUILD_TOOL)${NC}"
if [[ "$STACK_TYPE" == java-* ]]; then
    echo -e "${GREEN}Java version: $JAVA_VERSION${NC}"
fi

MODE="${1:-full}"

case "$MODE" in
    detect)
        echo -e "\n${CYAN}Stack details:${NC}"
        echo "  Type: $STACK_TYPE"
        echo "  Build tool: $BUILD_TOOL"
        echo "  Dockerfile: $DOCKERFILE"
        echo "  Lint: $LINT_CMD"
        echo "  Compile: $COMPILE_CMD"
        echo "  Test: $TEST_CMD"
        exit 0
        ;;

    quick)
        ensure_docker_image
        echo -e "\n${YELLOW}Running quick check...${NC}"

        if [[ -n "$LINT_CMD" ]]; then
            echo -e "${CYAN}Lint: $LINT_CMD${NC}"
            run_in_ci "cd /home/runner/work && $LINT_CMD"
        fi
        if [[ -n "$COMPILE_CMD" ]]; then
            echo -e "${CYAN}Compile: $COMPILE_CMD${NC}"
            run_in_ci "cd /home/runner/work && $COMPILE_CMD"
        fi
        ;;

    shell)
        ensure_docker_image
        echo -e "\n${YELLOW}Opening shell in CI environment...${NC}"
        image_name=$(get_image_name)
        docker run --rm -it \
            -v "$PROJECT_DIR:/home/runner/work" \
            -e CI=true \
            "$image_name" "cd /home/runner/work && bash"
        ;;

    full|*)
        ensure_docker_image
        echo -e "\n${YELLOW}Running full CI simulation...${NC}"

        step=1
        total=0
        [[ -n "$LINT_CMD" ]] && ((total++))
        [[ -n "$COMPILE_CMD" ]] && ((total++))
        [[ -n "$TEST_CMD" ]] && ((total++))

        if [[ -n "$LINT_CMD" ]]; then
            echo -e "\n${YELLOW}Step $step/$total: Lint${NC}"
            echo -e "  ${CYAN}$LINT_CMD${NC}"
            run_in_ci "cd /home/runner/work && $LINT_CMD"
            ((step++))
        fi

        if [[ -n "$COMPILE_CMD" ]]; then
            echo -e "\n${YELLOW}Step $step/$total: Compile${NC}"
            echo -e "  ${CYAN}$COMPILE_CMD${NC}"
            run_in_ci "cd /home/runner/work && $COMPILE_CMD"
            ((step++))
        fi

        if [[ -n "$TEST_CMD" ]]; then
            echo -e "\n${YELLOW}Step $step/$total: Test${NC}"
            echo -e "  ${CYAN}$TEST_CMD${NC}"
            run_in_ci "cd /home/runner/work && $TEST_CMD"
        fi
        ;;
esac

echo -e "\n${GREEN}✓ CI Local completed successfully!${NC}"
echo -e "${GREEN}  Safe to push - CI should pass.${NC}\n"
