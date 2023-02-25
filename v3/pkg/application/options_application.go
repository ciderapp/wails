package application

import (
	"github.com/ciderapp/wails/v3/pkg/logger"
)

type Options struct {
	Name        string
	Description string
	Icon        []byte
	Mac         MacOptions
	Bind        []any
	Logger      struct {
		Silent        bool
		CustomLoggers []logger.Output
	}
}
