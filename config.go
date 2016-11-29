package cagrr

import (
	"io/ioutil"
	"path/filepath"

	"gopkg.in/yaml.v2"
)

// ReadConfiguration parses yaml configuration file
func ReadConfiguration(filename string) (Config, error) {
	var c Config
	filename, _ = filepath.Abs(filename)
	yamlFile, err := ioutil.ReadFile(filename)

	if err != nil {
		return c, err
	}

	err = yaml.Unmarshal(yamlFile, &c)
	if err != nil {
		return c, err
	}
	return c, nil
}
