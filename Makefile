# Elm-Go API Build System

# Default target
all: build

# Build the complete application
build: elm-handler.js
	@echo "✅ Build complete! Run 'make run' to start the server."

# Compile Elm to JavaScript and add exports
elm-handler.js: src/GoMain.elm src/Handler.elm scripts/add-exports.sh
	@echo "🔨 Compiling Elm to JavaScript..."
	elm make src/GoMain.elm --output=elm-handler.js --optimize
	@echo "📦 Adding function exports..."
	@./scripts/add-exports.sh
	@echo "✅ Elm compilation and export complete!"

# Development server
run: build
	@echo "🚀 Starting Go+Elm API server..."
	go run main.go

# Development with auto-rebuild
dev: build
	@echo "🔄 Starting development server with auto-reload..."
	@echo "Note: You'll need to manually restart after Elm changes"
	air

# Clean build artifacts
clean:
	@echo "🧹 Cleaning build artifacts..."
	rm -f elm-handler.js
	rm -rf elm-stuff

# Install development dependencies
install:
	@echo "📦 Installing Go dependencies..."
	go mod tidy
	@echo "✅ Dependencies installed!"

# Test the API endpoints
test: build
	@echo "🧪 Testing API endpoints..."
	@echo "Starting server in background..."
	@go run main.go &
	@sleep 2
	@echo "\n🌐 Testing GET /"
	@curl -s http://localhost:3001/ | jq || echo "Failed"
	@echo "\n🏓 Testing GET /ping"
	@curl -s http://localhost:3001/ping | jq || echo "Failed"
	@echo "\n📢 Testing POST /echo"
	@curl -s -X POST http://localhost:3001/echo -d '{"test":"makefile"}' | jq || echo "Failed"
	@echo "\n🐌 Testing GET /slow"
	@curl -s http://localhost:3001/slow | jq || echo "Failed"
	@echo "\n✅ Tests complete!"
	@pkill -f "go run main.go" || true

# Help
help:
	@echo "🛠️  Elm-Go API Build Commands:"
	@echo ""
	@echo "  make build    - Compile Elm and prepare for Go"
	@echo "  make run      - Build and start the server"
	@echo "  make dev      - Development server (requires 'air')"
	@echo "  make test     - Run API tests"
	@echo "  make clean    - Remove build artifacts"
	@echo "  make install  - Install dependencies"
	@echo "  make help     - Show this help"
	@echo ""
	@echo "📁 Project structure:"
	@echo "  src/GoMain.elm    - Main Elm entry point"
	@echo "  src/Handler.elm   - Business logic"
	@echo "  main.go          - Go HTTP server"
	@echo "  elm-handler.js   - Compiled Elm (generated)"

# Declare phony targets
.PHONY: all build run dev clean install test help