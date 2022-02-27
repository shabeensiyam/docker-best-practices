package main

import (
    "fmt"
    "time"
    "os/user"
    "os"
)

var logFile *os.File

func main () {
    var err error

    user, err := user.Current()
    if err != nil {
        panic(err)
    }

    logFile, err = os.OpenFile("/app/log/access.log", os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
    if err != nil {
        panic(err)
    } else {
            fmt.Println("access.log created successfully!")
    }
    defer logFile.Close()

    for {
        fmt.Println("user: " + user.Username + " id: " + user.Uid)
        time.Sleep(1 * time.Second)
    }
}
