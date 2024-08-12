# make laravel-install project=<your-project-name> database=pgsql|sqlite|sqlsrv
laravel-install:
	@echo "\033[36mInstalling Laravel\033[0m"
	@scripts/laravel.install.sh --project $(project) --database $(database) --destination $(destination)
laravel-generate:
	@echo "\033[36mRunning Laravel Generator\033[0m"
	@scripts/laravel.generate.sh --project $(project) --destination $(destination)
laravel-serve:
	@echo "\033[36mServing Laravel on Port 8000\033[0m"
	@scripts/laravel.serve.sh --project $(project) --destination $(destination)