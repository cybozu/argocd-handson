package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
)

const version = "v1.0.0"

func handler(w http.ResponseWriter, req *http.Request) {
	message := os.Getenv("MESSAGE")
	if message == "" {
		message = "Hello"
	}
	log.Printf("%s %v", req.Method, req.URL)
	fmt.Fprintf(w, "%s (%s)\n", message, version)
}

func main() {
	log.Fatal(http.ListenAndServe(":8080", http.HandlerFunc(handler)))
}
