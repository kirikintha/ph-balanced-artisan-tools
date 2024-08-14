# Define the package target
package-extension:
	@echo "Packaging Laravel Tools Extension"
	npx vsce package

# Alias for the package-extension target
package: package-extension