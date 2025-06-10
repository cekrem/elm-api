package main

import (
	"encoding/json"
	"fmt"
	"log"
	"os"

	"github.com/dop251/goja"
	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
)

type ElmRequest struct {
	Method string  `json:"method"`
	Path   string  `json:"path"`
	Body   *string `json:"body"`
}

type ElmResponse struct {
	StatusCode int     `json:"statusCode"`
	Body       *string `json:"body"`
}

type ElmHandler struct {
	vm      *goja.Runtime
	program *goja.Program
}

func NewElmHandler() (*ElmHandler, error) {
	// Read compiled Elm JavaScript
	elmJS, err := os.ReadFile("elm-handler.js")
	if err != nil {
		return nil, fmt.Errorf("failed to read elm-handler.js: %v", err)
	}

	// Create JavaScript runtime
	vm := goja.New()

	// Set up the scope that Elm expects - use the global object
	vm.Set("scope", vm.GlobalObject())

	// Compile the Elm JavaScript
	program, err := goja.Compile("elm-handler.js", string(elmJS), false)
	if err != nil {
		return nil, fmt.Errorf("failed to compile Elm JS: %v", err)
	}

	// Execute to initialize Elm app
	_, err = vm.RunProgram(program)
	if err != nil {
		return nil, fmt.Errorf("failed to initialize Elm app: %v", err)
	}

	return &ElmHandler{vm: vm, program: program}, nil
}

func (h *ElmHandler) HandleRequest(method, path string, body *string) (int, *string, error) {
	// Create request object
	req := ElmRequest{
		Method: method,
		Path:   path,
		Body:   body,
	}

	// Convert to JSON
	reqJSON, err := json.Marshal(req)
	if err != nil {
		return 500, nil, fmt.Errorf("failed to marshal request: %v", err)
	}

	// Call Elm function - access the handleRequestFromGo function
	elmVal := h.vm.Get("Elm")
	if elmVal == nil {
		return 500, nil, fmt.Errorf("`Elm` is nil")
	}

	goMainVal := elmVal.ToObject(h.vm).Get("GoMain")
	if goMainVal == nil {
		return 500, nil, fmt.Errorf("`GoMain` is nil")
	}

	handleFunc := goMainVal.ToObject(h.vm).Get("handleRequestFromGo")
	if handleFunc == nil {
		return 500, nil, fmt.Errorf("handleRequestFromGo is nil")
	}

	callable, ok := goja.AssertFunction(handleFunc)
	if !ok {
		return 500, nil, fmt.Errorf("handleRequestFromGo is not a function")
	}

	result, err := callable(goja.Undefined(), h.vm.ToValue(string(reqJSON)))
	if err != nil {
		return 500, nil, fmt.Errorf("failed to call Elm handler: %v", err)
	}

	// Parse result
	var response ElmResponse
	err = json.Unmarshal([]byte(result.String()), &response)
	if err != nil {
		return 500, nil, fmt.Errorf("failed to parse Elm response: %v", err)
	}

	return response.StatusCode, response.Body, nil
}

func main() {
	// Initialize Elm handler
	elmHandler, err := NewElmHandler()
	if err != nil {
		log.Fatal("Failed to initialize Elm handler:", err)
	}

	// Create Fiber app
	app := fiber.New(fiber.Config{
		ErrorHandler: func(c *fiber.Ctx, err error) error {
			return c.Status(500).JSON(fiber.Map{"error": err.Error()})
		},
	})

	// Add CORS middleware
	app.Use(cors.New())

	// Handle all routes
	app.All("*", func(c *fiber.Ctx) error {
		method := c.Method()
		path := c.Path()

		var body *string
		if len(c.Body()) > 0 {
			bodyStr := string(c.Body())
			body = &bodyStr
		}

		// Call Elm handler
		statusCode, responseBody, err := elmHandler.HandleRequest(method, path, body)
		if err != nil {
			return err
		}

		// Set response
		c.Status(statusCode)
		if responseBody != nil {
			c.Set("Content-Type", "application/json")
			return c.SendString(*responseBody)
		}

		return c.SendString("")
	})

	log.Println("Go+Elm API server starting on :3001")
	log.Fatal(app.Listen(":3001"))
}

