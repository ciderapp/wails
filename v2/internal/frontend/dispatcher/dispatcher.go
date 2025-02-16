package dispatcher

import (
	"context"
	"github.com/ciderapp/wails/v2/internal/binding"
	"github.com/ciderapp/wails/v2/internal/frontend"
	"github.com/ciderapp/wails/v2/internal/logger"
	"github.com/pkg/errors"
)

type Dispatcher struct {
	log        *logger.Logger
	bindings   *binding.Bindings
	events     frontend.Events
	bindingsDB *binding.DB
	ctx        context.Context
}

func NewDispatcher(ctx context.Context, log *logger.Logger, bindings *binding.Bindings, events frontend.Events) *Dispatcher {
	return &Dispatcher{
		log:        log,
		bindings:   bindings,
		events:     events,
		bindingsDB: bindings.DB(),
		ctx:        ctx,
	}
}

func (d *Dispatcher) ProcessMessage(message string, sender frontend.Frontend) (string, error) {
	if message == "" {
		return "", errors.New("No message to process")
	}
	switch message[0] {
	case 'L':
		return d.processLogMessage(message)
	case 'E':
		return d.processEventMessage(message, sender)
	case 'C':
		return d.processCallMessage(message, sender)
	case 'c':
		return d.processSecureCallMessage(message, sender)
	case 'W':
		return d.processWindowMessage(message, sender)
	case 'B':
		return d.processBrowserMessage(message, sender)
	case 'Q':
		sender.Quit()
		return "", nil
	case 'S':
		sender.Show()
		return "", nil
	case 'H':
		sender.Hide()
		return "", nil
	default:
		return "", errors.New("Unknown message from front end: " + message)
	}
}
