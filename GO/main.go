package main

import (
	"C"
	"fmt"
)

func main() {}

//export PrintInt
func PrintInt(n int) {
	fmt.Println(n)
}

//go build -buildmode=c-archive foo.go

//gcc -pthread foo.c foo.a -o foo
