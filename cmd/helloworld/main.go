package main

import (
	"fmt"

	"github.com/qingdev0/goal/internal/greeting"
)

func main() {
	message := greeting.GetMessage()
	fmt.Println(message)
}
