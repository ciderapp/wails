package main

import (
	_ "embed"
	"log"

	"github.com/ciderapp/wails/v3/examples/binding/services"

	"github.com/ciderapp/wails/v3/pkg/application"
)

type localStruct struct{}

func main() {
	app := application.New(application.Options{
		Bind: []interface{}{
			&localStruct{},
			&services.GreetService{},
		},
	})

	app.NewWebviewWindow()

	err := app.Run()

	if err != nil {
		log.Fatal(err)
	}

}
