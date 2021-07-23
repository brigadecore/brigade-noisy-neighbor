package os

import (
	"os"
	"strconv"
	"time"

	"github.com/pkg/errors"
)

func GetRequiredEnvVar(name string) (string, error) {
	val := os.Getenv(name)
	if val == "" {
		return "", errors.Errorf(
			"value not found for required environment variable %s",
			name,
		)
	}
	return val, nil
}

func GetBoolFromEnvVar(name string, defaultValue bool) (bool, error) {
	valStr := os.Getenv(name)
	if valStr == "" {
		return defaultValue, nil
	}
	val, err := strconv.ParseBool(valStr)
	if err != nil {
		return false, errors.Errorf(
			"value %q for environment variable %s was not parsable as a bool",
			valStr,
			name,
		)
	}
	return val, nil
}
func GetDurationFromEnvVar(
	name string,
	defaultValue time.Duration,
) (time.Duration, error) {
	valStr := os.Getenv(name)
	if valStr == "" {
		return defaultValue, nil
	}
	val, err := time.ParseDuration(valStr)
	if err != nil {
		return 0, errors.Errorf(
			"value %q for environment variable %s was not parsable as a duration",
			valStr,
			name,
		)
	}
	return val, nil
}
