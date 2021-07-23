package main

import (
	"context"
	"log"
	"time"

	"github.com/brigadecore/brigade-noisy-neighbor/internal/version"
	"github.com/brigadecore/brigade/sdk/v2"
	"github.com/brigadecore/brigade/sdk/v2/core"
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

	apiClient := sdk.NewAPIClient(address, token, &opts)

	noiseFrequency, err := noiseFrequency()
	if err != nil {
		log.Fatal(err)
	}

	ticker := time.NewTicker(noiseFrequency)
	defer ticker.Stop()
	for range ticker.C {
		if _, err := apiClient.Core().Events().Create(
			context.Background(),
			core.Event{
				Source: "github.com/brigadecore/brigade-noisy-neighbor",
				Type:   "noise",
			},
		); err != nil {
			log.Println(err)
		}
	}

}
