#include "server.h"
#include <stdio.h>
#include <string.h>

//build: gcc -pthread .\test.c .\server.a -o out
int main() {
    // Start the server on port 8090
    ServerInit(8090);
    
    // Send a welcome message
    BroadcastMessage("Server is online!");
    
    // Process input until quit
    ReadInput();
    
    // Clean up
    ServerClose();
    
    return 0;
}