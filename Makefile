VENV_DIR = /home/buildstream/.venv
WORKSPACE_DIR = /workspaces/workspace
SETTINGS_DIR = /workspaces/workspace/settings
BUILDSTREAM_DIR = $(WORKSPACE_DIR)/buildstream

all: venv settings

clean:
	rm -rf $(VENV_DIR)

settings: buildstream-settings
buildstream-settings: $(BUILDSTREAM_DIR)/.vscode/settings.json
venv: $(VENV_DIR)

$(VENV_DIR): $(BUILDSTREAM_DIR)/requirements/*
	python3.7 -m venv --prompt bst $@
	$@/bin/pip install \
		black \
		mypy \
		cython \
		-r$(BUILDSTREAM_DIR)/requirements/cov-requirements.in \
		-r$(BUILDSTREAM_DIR)/requirements/dev-requirements.in
	$@/bin/pip install -e $(BUILDSTREAM_DIR)

$(BUILDSTREAM_DIR)/.vscode/settings.json: $(SETTINGS_DIR)/buildstream-settings.json
	mkdir -p $(BUILDSTREAM_DIR)/.vscode
	cp $(SETTINGS_DIR)/buildstream-settings.json $@


.PHONY: all venv settings
