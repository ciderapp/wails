package main

import (
	"embed"
	_ "embed"
	"log"
	"math/rand"
	"strconv"

	"github.com/ciderapp/wails/v3/pkg/application"
)

//go:embed assets
var assets embed.FS

func main() {
	app := application.New(application.Options{
		Name:        "WebviewWindow Javascript Demo",
		Description: "A demo of the WebviewWindow API from Javascript",
		Icon:        nil,
		Mac: application.MacOptions{
			ApplicationShouldTerminateAfterLastWindowClosed: true,
		},
	})

	// Create a custom menu
	menu := app.NewMenu()
	menu.AddRole(application.AppMenu)

	windowCounter := 1

	newWindow := func() {
		app.NewWebviewWindowWithOptions(&application.WebviewWindowOptions{
			Assets: application.AssetOptions{
				FS: assets,
			},
		}).
			SetTitle("WebviewWindow "+strconv.Itoa(windowCounter)).
			SetPosition(rand.Intn(1000), rand.Intn(800)).
			Show()
		windowCounter++
	}

	// Let's make a "Demo" menu
	myMenu := menu.AddSubmenu("New")

	myMenu.Add("New WebviewWindow").
		SetAccelerator("CmdOrCtrl+N").
		OnClick(func(ctx *application.Context) {
			newWindow()
		})

	newWindow()

	app.SetMenu(menu)
	err := app.Run()

	if err != nil {
		log.Fatal(err)
	}

}
