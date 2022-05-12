package main

import (
	"context"
	"log"
	"time"

	"github.com/brigadecore/brigade-foundations/version"
	"github.com/brigadecore/brigade/sdk/v3"
)

func main() {
	log.Printf(
		"Starting Brigade Noisy Neighbor -- version %s -- commit %s",
		version.Version(),
		version.Commit(),
	)

	address, token, opts, err := apiClientConfig()
	if err != nil {
		log.Fatal(err)
	}

	eventsClient := sdk.NewEventsClient(address, token, &opts)

	noiseFrequency, err := noiseFrequency()
	if err != nil {
		log.Fatal(err)
	}

	ticker := time.NewTicker(noiseFrequency)
	defer ticker.Stop()
	for range ticker.C {
		if _, err := eventsClient.Create(
			context.Background(),
			sdk.Event{
				Source: "brigade.sh/noisy-neighbor",
				Type:   "noise",
			},
			nil,
		); err != nil {
			log.Println(err)
		}
	}

}
