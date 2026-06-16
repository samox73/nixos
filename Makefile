HOST := $(shell hostname)
FLAKE := /home/samox/.config/nixos

.PHONY: switch boot test update update-commit gc clean help

# Rebuild and switch to the new configuration
switch:
	sudo nixos-rebuild switch --flake $(FLAKE)#$(HOST)

# Rebuild and set as boot default without switching
boot:
	sudo nixos-rebuild boot --flake $(FLAKE)#$(HOST)

# Build and test without making it permanent
test:
	sudo nixos-rebuild test --flake $(FLAKE)#$(HOST)

# Update all flake inputs
update:
	nix flake update --flake $(FLAKE)

# Update flake inputs and rebuild in one step
update-commit: update switch
	git add flake.lock && git commit -m "update flake inputs"

# Remove old generations (keeps last 5)
gc:
	sudo nix-collect-garbage --delete-older-than 30d
	sudo nixos-rebuild boot --flake $(FLAKE)#$(HOST)

# Hard GC: remove everything not reachable from current system
clean:
	sudo nix-collect-garbage -d

help:
	@echo "NixOS Makefile for host: $(HOST)"
	@echo ""
	@echo "  make switch         Rebuild and activate configuration"
	@echo "  make boot           Rebuild and set as next boot target"
	@echo "  make test           Rebuild and test (reverts on reboot)"
	@echo "  make update         Update all flake inputs"
	@echo "  make update-commit  Update inputs + switch + commit flake.lock"
	@echo "  make gc             Collect garbage older than 30 days"
	@echo "  make clean          Remove all old generations (aggressive)"
