# Define the package target
package-extension:
	@echo "Packaging Artisan Tools Extension"
	npx vsce package
publish-extension:
	@echo "Publishing Artisan Tools Extension"
	npx vsce publish
optimize-animated-gifs:
	@echo "Optimizing files"
	@scripts/optimize-animated-gifs.sh
npm-audit:
	@echo "Checking npm dependencies"
	@scripts/npm-audit.sh

# Alias for the package-extension target
package: package-extension