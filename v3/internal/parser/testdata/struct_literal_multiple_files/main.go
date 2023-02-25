package main

import (
	_ "embed"
	"log"

	"github.com/ciderapp/wails/v3/pkg/application"
)

func main() {
	app := application.New(application.Options{
		Bind: []interface{}{
			&GreetService{},
			&OtherService{},
		},
	})

	app.NewWebviewWindow()

	err := app.Run()

	if err != nil {
		log.Fatal(err)
	}

}
