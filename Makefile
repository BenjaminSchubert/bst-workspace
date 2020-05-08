VENV_DIR = /home/buildstream/venv
WORKSPACE_DIR = $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
SETTINGS_DIR = $(WORKSPACE_DIR)/settings
BUILDSTREAM_DIR = $(WORKSPACE_DIR)/buildstream
BST_PLUGINS_CONTAINER_DIR = $(WORKSPACE_DIR)/bst-plugins-container
BST_PLUGINS_EXPERIMENTAL_DIR = $(WORKSPACE_DIR)/bst-plugins-experimental

all: venv settings

clean:
	rm -rf $(VENV_DIR)

settings: buildstream-settings bst-plugins-container-settings bst-plugins-experimental-settings workspace-settings
buildstream-settings: $(BUILDSTREAM_DIR)/.vscode/settings.json
bst-plugins-container-settings: $(BST_PLUGINS_CONTAINER_DIR)/.vscode/settings.json
bst-plugins-experimental-settings: $(BST_PLUGINS_EXPERIMENTAL_DIR)/.vscode/settings.json
workspace-settings: $(WORKSPACE_DIR)/.vscode/settings.json
venv: $(VENV_DIR)

$(VENV_DIR): $(wildcard $(BUILDSTREAM_DIR)/requirements/*)
	python3.7 -m venv --prompt bst $@
	$@/bin/pip install \
		black \
		mypy \
		cython \
		-r$(BUILDSTREAM_DIR)/requirements/cov-requirements.in \
		-r$(BUILDSTREAM_DIR)/requirements/dev-requirements.in
	$@/bin/pip install -e $(BUILDSTREAM_DIR)
	$@/bin/pip install -e $(BST_PLUGINS_EXPERIMENTAL_DIR)[ostree,cargo,bazel,deb]
	$@/bin/pip install -e $(BST_PLUGINS_CONTAINER_DIR)

$(BUILDSTREAM_DIR)/.vscode/settings.json: $(SETTINGS_DIR)/buildstream-settings.json
	mkdir -p $(BUILDSTREAM_DIR)/.vscode
	cp $(SETTINGS_DIR)/buildstream-settings.json $@

$(BST_PLUGINS_EXPERIMENTAL_DIR)/.vscode/settings.json: $(SETTINGS_DIR)/bst-plugins-experimental-settings.json
	mkdir -p $(BST_PLUGINS_EXPERIMENTAL_DIR)/.vscode
	cp $(SETTINGS_DIR)/bst-plugins-experimental-settings.json $@

$(BST_PLUGINS_CONTAINER_DIR)/.vscode/settings.json: $(SETTINGS_DIR)/bst-plugins-container-settings.json
	mkdir -p $(BST_PLUGINS_CONTAINER_DIR)/.vscode
	cp $(SETTINGS_DIR)/bst-plugins-container-settings.json $@

$(WORKSPACE_DIR)/.vscode/settings.json: $(SETTINGS_DIR)/workspace-settings.json
	mkdir -p $(WORKSPACE_DIR)/.vscode
	cp $(SETTINGS_DIR)/workspace-settings.json $@

.PHONY: all venv settings buildstream-settings bst-plugins-experimental-settings
