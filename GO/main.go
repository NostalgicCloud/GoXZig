package main

import (
	"C"
	"bufio"
	"fmt"
	"net"
	"os"
	"strconv"
)

//export ServerInit
func ServerInit(port int) {
	listener = SetUpListener(port)

	go ListenForNewConnections(listener)
}

//export ServerClose
func ServerClose() {
	if listener != nil {
		listener.Close()
	}
	for _, conn := range connections {
		conn.conn.Close()
	}
	fmt.Println("Server closed")
}

//export BroadcastMessage
func BroadcastMessage(cMessage *C.char) {
	message := C.GoString(cMessage)
	SendMessageToAllButSelf(message, nil)
}
func BroadcastMessageIternal(message string) {
	SendMessageToAllButSelf(message, nil)
}

//export ReadInput
func ReadInput() { // Return C.int so it can be called from C
	input := bufio.NewScanner(os.Stdin)
	for {
		fmt.Print("Enter message (or 'exit' to quit): ")
		if !input.Scan() {
			fmt.Println("Error reading input")
			break
		}

		text := input.Text()
		if text == "exit" {
			ServerClose()
			break
		}
		BroadcastMessageIternal(text)
	}
	//return C.int(1) // Return success code
}

var connections []CloudConnection
var listener net.Listener

type CloudConnection struct {
	conn  net.Conn
	name  string
	index string
}

func main() {

	port := 8090
	ServerInit(port)
	defer ServerClose()
	// Listen on port 8080

	ReadInput()
}

func SetUpListener(port int) net.Listener {
	connections = make([]CloudConnection, 0)
	ln, err := net.Listen("tcp", ":"+strconv.Itoa(port))
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	fmt.Println("Server listening on port", strconv.Itoa(port))
	return ln
}

func RemoveConnection(removeConn CloudConnection) {
	for i, currConn := range connections {
		if removeConn.index == currConn.index {
			connections = append(connections[:i], connections[i+1:]...)
		}
	}
}

func ListenForNewConnections(ln net.Listener) {
	for {
		// Accept a connection
		conn, err := ln.Accept()
		if err != nil {
			fmt.Println(err)
			continue // Continue to the next connection attempt
		}
		connections = append(connections, CloudConnection{
			conn,
			"TESTCONN",
			conn.RemoteAddr().String(),
		})

		// Handle the connection in a goroutine
		go ListenForMessage(connections[len(connections)-1])
	}
}

func SendMessageToAllButSelf(message string, self net.Conn) {
	for _, conn := range connections {
		if self != nil {
			if conn.conn == self {
				continue
			}
		}
		SendMessage(conn.conn, message)
	}
}

func SendMessage(conn net.Conn, message string) {
	_, err := conn.Write([]byte(message))
	if err != nil {
		fmt.Println("Error writing:", err)
	}
}

func ListenForMessage(cloudConn CloudConnection) {
	defer cloudConn.conn.Close()
	buf := make([]byte, 1024)
	for {
		n, err := cloudConn.conn.Read(buf)
		if err != nil {
			fmt.Println("Error reading:", err)
			break
		}
		SendMessageToAllButSelf(string(buf[:n]), cloudConn.conn)
		// Print received data
		fmt.Printf("%s: %s", cloudConn.name, buf[:n])
	}
	RemoveConnection(cloudConn)
}
