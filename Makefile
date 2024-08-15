# Define the package target
package-extension:
	@echo "Packaging Artisan Tools Extension"
	npx vsce package
optimize-animated-gifs:
	@echo "Optimizing files"
	./optimize-animated-gifs.sh

# Alias for the package-extension target
package: package-extension